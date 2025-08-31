using System.Linq;
using System;
using System.Web;
using System.Configuration;

namespace QProcess.Extensions
{

    /// <summary>
    /// Summary description for ExtensionMethods
    /// </summary>
    public static class ExtensionMethods
    {
        #region Data Access Extensions

        /// <summary>
        /// Allow for dasiy chain adding parameters and execute in one statement on DbCommand class
        /// </summary>
        /// <param name="sql">self reference</param>
        /// <param name="paramName">SQL Parameter to add</param>
        /// <param name="objValue">SQL Value to add</param>
        /// <returns>Return back the same DbCommand object to chain up more function call</returns>
        public static DataAccessLayer.DBCommand Add(this DataAccessLayer.DBCommand sql, string paramName, object objValue)
        {
            sql.AddParameter(paramName, objValue);
            return sql;
        }

        public static DataAccessLayer.DBCommand Update(this DataAccessLayer.DBCommand sql, string paramName, object objValue)
        {
            sql.UpdateParameter(paramName, objValue);
            return sql;
        }

        public static DataAccessLayer.DBCommand Add(this DataAccessLayer.DBCommand sql, string paramName,
            System.Data.ParameterDirection direction, System.Data.DbType type, object objValue = null)
        {
            sql.AddParameter(paramName, direction, type, objValue);
            return sql;
        }

        public static DataAccessLayer.DBCommand Add(this DataAccessLayer.DBCommand sql,
            DataAccessLayer.DBCommand dbCommand, string paramName, string outputParamName,
            System.Data.ParameterDirection direction = System.Data.ParameterDirection.Input)
        {
            sql.AddParameter(dbCommand, paramName, outputParamName, direction);
            return sql;
        }

        #endregion

        #region String/Collection Helpers
        public static bool IsIn<T>(this T input, params T[] toMatch)
        {
            return toMatch.Contains(input);
        }

        public static bool StartsWithAny(this string input, params string[] toMatch)
        {
            return toMatch.Any(m => input.StartsWith(m));
        }

        public static bool ContainsAny(this string input, params string[] toMatch)
        {
            return toMatch.Any(m => input.Contains(m));
        }

        public static bool IsNullOrBlank(this string value)
        {
            return String.IsNullOrWhiteSpace(value);
        }

        public static bool IsNullOrBlankOr(this string value, params string[] placeholders)
        {
            return String.IsNullOrWhiteSpace(value) || placeholders.Contains(value);
        }

        public static string NullIfBlank(this string value)
        {
            return String.IsNullOrWhiteSpace(value) ? null : value;
        }

        public static string BlankIfNull(this string value)
        {
            return String.IsNullOrWhiteSpace(value) ? "" : value;
        }

        public static bool IsMobileBrowser(this HttpRequest request)
        {
            var userAgent = request.ServerVariables["HTTP_USER_AGENT"].ToLower();
            return userAgent.ContainsAny("iphone", "ipad", "ipod", "android")
                && ConfigurationManager.AppSettings["ShowMobileLink"].ToLowerInvariant() != "false";
        }

        public static void RedirectToMobile(this HttpResponse response, Uri requestUri)
        {
            var path = requestUri.LocalPath;
            var lastSlash = path.LastIndexOf('/');
            path = path.Substring(0, lastSlash) + "/mobile/Mobile" + path.Substring(lastSlash+1, path.Length-1);

            response.Redirect(new UriBuilder(requestUri.Scheme, requestUri.Host, requestUri.Port, path, requestUri.Query).Uri.ToString());
        }
        #endregion

        #region Conversion Helper Functions

        //public static string HtmlLineBreak(this object value)
        //{
        //    return System.Text.RegularExpressions.Regex.Replace(value.ToString(), @"\r\n?|\n", "<br/>");
        //}

        //public static short? ToShortEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    return Convert.ToInt16(value);
        //}

        //public static int? ToIntEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    return Convert.ToInt32(value);
        //}

        //public static long? ToLngEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    return Convert.ToInt64(value);
        //}

        //public static double? ToDoubleEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    try
        //    {
        //        return Convert.ToDouble(value);
        //    }
        //    catch (Exception)
        //    {
        //        return null;
        //    }
        //}

        //public static double ToDouble(this object value)
        //{
        //    if (value == DBNull.Value) return 0.0;
        //    if (value == null) return 0.0;

        //    try
        //    {
        //        return Convert.ToDouble(value);
        //    }
        //    catch (Exception)
        //    {
        //        return 0.0;
        //    }
        //}

        //public static decimal? ToDecimalEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    try
        //    {
        //        return Convert.ToDecimal(value);
        //    }
        //    catch (Exception)
        //    {
        //        return null;
        //    }
        //}

        //public static bool? ToBoolEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    return Convert.ToBoolean(value);
        //}

        //public static bool ToBool(this object value)
        //{
        //    if (value == DBNull.Value) return false;
        //    if (value == null) return false;

        //    return Convert.ToBoolean(value);
        //}

        //public static DateTime? ToDateTimeEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;
        //    if (value.ToBlank() == "") return null;

        //    return Convert.ToDateTime(value);
        //}

        //public static string ToShortDateFormatEx(this object value)
        //{
        //    if (value == DBNull.Value) return "";
        //    if (value == null) return "";

        //    return Convert.ToDateTime(value).ToString("MM/dd/yyyy");
        //}

        //public static string ToStringEx(this object value)
        //{
        //    if (value == DBNull.Value) return null;
        //    if (value == null) return null;

        //    return Convert.ToString(value);
        //}

        //public static string ToBlank(this object value)
        //{
        //    if (value == DBNull.Value) return "";
        //    if (value == null) return "";

        //    return value.ToString();
        //}

        //public static string ToBlankHtml(this object value)
        //{
        //    if (value == DBNull.Value) return "&nbsp;";
        //    if (value == null) return "&nbsp;";

        //    return value.ToString();
        //}

        //public static string ToFixed(this object value, int numDigitAfterDecimal)
        //{
        //    if (value == DBNull.Value) value = 0.0;
        //    if (value == null) value = 0.0;

        //    return Microsoft.VisualBasic.Strings.FormatNumber(value, numDigitAfterDecimal, Microsoft.VisualBasic.TriState.True);
        //}

        //public static string ToFixedNoRounding(this object value, int numDigitAfterDecimal)
        //{
        //    if (value == DBNull.Value) value = 0.0;
        //    if (value == null) value = 0.0;

        //    string tmp = value.ToString();
        //    if (tmp.IndexOf('.') >= 0)
        //    {
        //        tmp = tmp.Substring(0, tmp.IndexOf('.') + numDigitAfterDecimal + 1);
        //    }

        //    return tmp.ToFixed(numDigitAfterDecimal);
        //} 

        //public static bool IsDate(this object value)
        //{
        //    return Microsoft.VisualBasic.Information.IsDate(value);
        //}

        #endregion
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

