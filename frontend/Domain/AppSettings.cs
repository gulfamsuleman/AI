using System;
using System.Linq;
using System.Web.Configuration;
using System.Collections.Generic;

namespace QProcess.Configuration
{
    public static class AppSettings
    {
        //Enumerates all available app settings (Environment or Config)
        public static IEnumerable<string> Keys => 
            Environment.GetEnvironmentVariables().Keys.OfType<string>()
            .Concat(
                WebConfigurationManager.AppSettings.AllKeys
            ).Distinct().OrderBy(s=>s);

        //More dynamic setup, can be used similar to either system these calls replace
        public static string Get(string key)
        {
            try
            {
                return Environment.GetEnvironmentVariable(key) 
                    ?? WebConfigurationManager.AppSettings[key];
            }
            catch
            {
                try
                {
                    return WebConfigurationManager.AppSettings[key];
                }
                catch {
                    return null;
                }
            }
        }

        private const string APP_NAME = "AppName";
        private const string FIRM_NAME = "Firm";
        private const string CONNECTION_STRING_KEY = "Database";
        private const string NO_CACHE_REPORTS = "NoCacheReports";
        private const string VISIBLE_COMMENTS_DAYS = "VisibleCommentsDays";
        private const string QPC_ADDRESS = "QPCAddress";
        private const string PRIORITIES_LINK = "PrioritiesLink";
        private const string FROM_ADDRESS = "FromAddress";
        private const string REDIRECT_URI = "RedirectUri"; 

        //Older existing property accessors; keeping them around but updating for maintainability
        public static string AppName => Get(APP_NAME); //{ get { return WebConfigurationManager.AppSettings[APP_NAME]; } }
        public static string Firm => Get(FIRM_NAME); // { get { return WebConfigurationManager.AppSettings[FIRM_NAME]; } }
        public static string ConnectionString => Get(CONNECTION_STRING_KEY); //{ get { return WebConfigurationManager.AppSettings[CONNECTION_STRING_KEY]; } }
        public static string NoCacheReports => Get(NO_CACHE_REPORTS); //{ get { return WebConfigurationManager.AppSettings[NO_CACHE_REPORTS]; } }
        public static string VisibleCommentsDays => Get(VISIBLE_COMMENTS_DAYS); //{ get { return WebConfigurationManager.AppSettings[VISIBLE_COMMENTS_DAYS]; } }
        public static string QPCAddress => Get(QPC_ADDRESS); //{ get { return WebConfigurationManager.AppSettings[QPC_ADDRESS]; } }
        public static string PrioritiesLink => Get(PRIORITIES_LINK); //{ get { return WebConfigurationManager.AppSettings[PRIORITIES_LINK]; } }
        public static string FromAddress => Get(FROM_ADDRESS); //{ get { return WebConfigurationManager.AppSettings[FROM_ADDRESS]; } }
        public static string SiteRoot => Get(REDIRECT_URI);
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

