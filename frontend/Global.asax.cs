using QProcess.Configuration;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Runtime;
using System.Threading.Tasks;
using System.Web;
using DataAccessLayer;
using QProcess.Extensions;
using System.Data;
using System.Configuration;
using System.Text.RegularExpressions;

namespace QProcess
{
    public class Global : HttpApplication
    {
        void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
            if (ConfigurationManager.AppSettings["RunSqlScripts"].ToLowerInvariant() == "true")
                RunSqlScripts();
        }

        void Application_End(object sender, EventArgs e)
        {
            //  Code that runs on application shutdown
        }

        void Application_Error(object sender, EventArgs e)
        {
            // Code that runs when an unhandled error occurs            
            Exception ex = HttpContext.Current.Server.GetLastError();
            //Session["LastError"] = ex;
            Log.Write(ex.ToString());
            //Response.Write("An error occured with your session");
            //HttpContext.Current.Server.ClearError();
        }

        protected void Session_Start(object sender, EventArgs e)
        {

        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {

        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e)
        {

        }

        protected void Session_End(object sender, EventArgs e)
        {

        }

        #region Run SQL Scripts
        /* Runs all SQL Scripts in SQL folder that are pending publish. */
        static void RunSqlScripts()
        {
            string sqlDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SQL");
            string sourceFilePath = string.Empty;
            string targetFolderPath = string.Empty;
            string connectionString = AppSettings.Get("Database");
            string script = string.Empty;
            string fileName = string.Empty;
            string tableName = "SqlScriptAudit";
            string columnName = "FileName";
            string successFlagColumn = "IsSuccess";

            List<string> previouslyRunScripts = GetColumnValuesWithFlag(tableName, columnName, successFlagColumn);

            foreach (string file in Directory.GetFiles(sqlDirectory, "*.sql"))
            {
                script = File.ReadAllText(file);
                fileName = GetFileNameFromPath(file);
                sourceFilePath = Path.Combine(sqlDirectory, fileName);
                targetFolderPath = Path.Combine(sqlDirectory, "_Archived");

                // Only run scripts that have never been run before
                if (!previouslyRunScripts.Contains(fileName))
                {
                    // Skip SQL scripts containing DROP statement.
                    if (!ContainsIllegalStatement(script))
                    {
                        ExecuteSqlScript(fileName, connectionString, script);
                    }
                    else
                    {
                        LogFailedSqlScript(fileName, "Illegal statement detected (i.e. DROP).", connectionString);
                    }
                }
                else
                {
                    LogFailedSqlScript(fileName, "Script has already run.", connectionString);
                }

                // File moved to _Archived folder, regardless of success
                MoveFileToFolder(file, targetFolderPath);
            }
        }

        static void SendEmail(string connectionString, string from, string to, string subject, string body, string fromName = null)
        {
            try
            {
                using (var db = new DBCommand("QCheck_Sendmail", connectionString))
                {
                    if (from != null)
                    {
                        db.Add("@From", from);
                    }
                    db.Add("@To", to);
                    db.Add("@Subject", subject);
                    db.Add("@Message", body);
                    if (fromName != null)
                    {
                        db.Add("@From_Name", fromName);
                    }
                    db.ExecuteNonQuery();
                }
            }
            catch (SqlException ex)
            {
                Log.Write("Error: (" + ex.Message.ToString() + ") in Global.asax.cs\\RunSqlScripts");
            }
        }

        // Check if SQL script contains the "DROP" statement (ignore case)
        static bool ContainsIllegalStatement(string sqlContent)
        {
            var retVal = false;

            retVal = retVal || Regex.IsMatch(sqlContent.ToLowerInvariant(), "drop(?! table #)");

            return retVal;
        }

        // When there is a failure, still need entry in [SqlScriptAudit] denoting error
        static void LogFailedSqlScript(string fileName, string errorMessage, string connectionString)
        {
            try
            {
                errorMessage = errorMessage.Replace("'", "''").Replace(";", string.Empty);

                SendEmail(connectionString, null, AppSettings.Get("DeveloperEmail"), "SQL Script Audit Failure", errorMessage, AppSettings.Get("AppName"));

                SqlScriptAudit_Add(connectionString, fileName, false, errorMessage);
            }
            catch (SqlException ex)
            {
                Log.Write("Failed inserting row in [SqlScriptAudit] with filename: '" + fileName + "', exception: '" + ex.Message.ToString() + "', in Global.asax.cs\\LogFailedSqlScript");
            }
        }

        // Split on 'GO' as the GO command is not a valid SQL command in the context of executing SQL queries from C#
        static void ExecuteSqlScript(string fileName, string connectionString, string script)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();
                    string[] commands = script.Split(new[] { "GO" }, StringSplitOptions.RemoveEmptyEntries);

                    foreach (string command in commands)
                    {
                        if (!string.IsNullOrWhiteSpace(command))
                        {
                            using (SqlCommand sqlCommand = new SqlCommand(command, connection))
                            {
                                sqlCommand.ExecuteNonQuery();
                            }
                        }
                    }
                    SqlScriptAudit_Add(connectionString, fileName, true, null);
                }
                catch (SqlException ex)
                {
                    LogFailedSqlScript(fileName, ex.Message.ToString(), connectionString);
                }
            }
        }

        static string GetFileNameFromPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                Log.Write("Path (" + nameof(path) + ") cannot be null or empty in Global.asax.cs\\GetFileNameFromPath");
            }

            return Path.GetFileName(path);
        }

        static void MoveFileToFolder(string sourceFilePath, string targetFolderPath)
        {
            if (!File.Exists(sourceFilePath))
            {
                Log.Write("Source file (" + sourceFilePath + ") not found in Global.asax.cs\\MoveFileToFolder");
            }

            if (!Directory.Exists(targetFolderPath))
            {
                Directory.CreateDirectory(targetFolderPath);
            }

            // Define the destination file path
            string fileName = Path.GetFileName(sourceFilePath);
            string destinationFilePath = Path.Combine(targetFolderPath, fileName);

            // Move the file
            File.Move(sourceFilePath, destinationFilePath);
        }

        /* Pass in: [TableName], [ColumnName], [FlagColumnName] (you need true)
         * Receive: List<string> of results in [ColumnName] column */
        private static List<string> GetColumnValuesWithFlag(string tableName, string columnName, string flagColumn)
        {
            List<string> values = new List<string>();

            // Validation against SQL injection
            if (!IsValidString(tableName) || !IsValidString(columnName) || !IsValidString(flagColumn))
            {
                Log.Write("Invalid table, column, or flag column name in Global.asax.cs\\GetColumnValuesWithFlag");
            }
            else
            {
                string query = $"SELECT {columnName} FROM {tableName} WHERE {flagColumn} = 1;";

                using (var connection = new SqlConnection(AppSettings.Get("Database")))
                {
                    connection.Open();

                    using (var command = new SqlCommand(query, connection))
                    {
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                values.Add(reader[columnName].ToString());
                            }
                        }
                    }
                }
            }
            return values;
        }

        // Verify string only contains letters, numbers, and underscores.
        private static bool IsValidString(string rawString)
        {
            return !string.IsNullOrWhiteSpace(rawString) && System.Text.RegularExpressions.Regex.IsMatch(rawString, @"^[a-zA-Z0-9_]+$");
        }

        // Add row into [SqlScriptAudit] whether it failed or succeeded
        static void SqlScriptAudit_Add(string connectionString, string fileName, bool isSuccess, string error)
        {
            string storedProcedureName = "SqlScriptAudit_Add";

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                using (SqlCommand command = new SqlCommand(storedProcedureName, connection))
                {
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(new SqlParameter("@FileName", SqlDbType.VarChar, 255)).Value = fileName;
                    command.Parameters.Add(new SqlParameter("@IsSuccess", SqlDbType.Bit)).Value = isSuccess == true ? 1 : 0;
                    command.Parameters.Add(new SqlParameter("@Error", SqlDbType.VarChar, 8000)).Value = error ?? (object)DBNull.Value;

                    try
                    {
                        connection.Open();
                        command.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                }
            }
        }

        #endregion Run SQL Scripts
    }
}
/* Copyright � 2024 Renegade Swish, LLC */

