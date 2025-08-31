using System;
using System.Data;
using System.Data.SqlClient;
using QProcess.Configuration;

namespace QProcess
{
    public class CmdObj : IDisposable
    {
        private SqlCommand command;

        public CmdObj(string proceedureName)
            : this(new SqlConnection(AppSettings.ConnectionString), proceedureName) { }

        public CmdObj(string proceedureName, int timeout)
            : this(new SqlConnection(AppSettings.ConnectionString), proceedureName, timeout) { }

        public CmdObj(SqlConnection connection, string proceedureName)
            : this(connection, proceedureName, 30) { }

        private CmdObj(SqlConnection connection, string proceedureName, int timeout)
        {
            command = connection.CreateCommand();
            command.CommandText = proceedureName;
            command.CommandType = CommandType.StoredProcedure;
            command.CommandTimeout = timeout;
        }

        public void Add(string name, SqlDbType type, object value, ParameterDirection direction, int size)
        {
            command.Parameters.Add(name, type, size).Direction = direction;
            command.Parameters[name].Value = value;
        }

        public void Add(string name, SqlDbType type, ParameterDirection direction, int size)
        {
            command.Parameters.Add(name, type, size).Direction = direction;
        }

        public void Add(string name, object value)
        {
            command.Parameters.Add(new SqlParameter(name, value));
        }

        public void Reset(string name, object value)
        {
            command.Parameters[name].Value = value;
        }

        public void Clear()
        {
            command.Parameters.Clear();
        }

        public void ExecuteNonQueryWithOutput()
        {
            command.Connection.Open();
            try
            {
                command.ExecuteNonQuery();
            }
            finally
            {
                command.Connection.Close();
            }
        }

        public void BuildList()
        {
            throw new NotImplementedException();
        }

        public object GetScalar() 
        {
            command.Connection.Open();
            try
            {
                return command.ExecuteScalar();
            }
            finally
            {
                command.Connection.Close();
            }
        }
        public DataSet GetDS()
        {
            command.Connection.Open();
            try
            {
                DataSet dataSet = new DataSet();
                var dataAdapter = new SqlDataAdapter(command);
                dataAdapter.Fill(dataSet);
                return dataSet;
            }
            finally
            {
                command.Connection.Close();
            }
        }

        public object this[string name]
        {
            get
            {
				if (command.Parameters.Contains(name))
				{
					if (Convert.IsDBNull(command.Parameters[name].Value))
						return null;
					else
						return command.Parameters[name].Value;
				}
				else
					return null;
            }
            set
            {
                if (command.Parameters.Contains(name))
                    command.Parameters[name].Value = value;
                else
                    command.Parameters.Add(new SqlParameter(name, value));
            }
        }

        public void Dispose()
        {
            command.Connection.Dispose();
            command.Dispose();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

