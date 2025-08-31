using QProcess.Extensions;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Error
{
    public partial class ErrorPage : Page
    {
        public Exception LastError { get; private set; }
        public int StatusCode { get; set; }

        public NameValueCollection AppSettings => ConfigurationManager.AppSettings;
        public string Firm => AppSettings["Firm"];
        public string AppName => AppSettings["AppName"];

        protected void Page_Load(object sender, EventArgs e)
        {
            LastError = (Session["LastError"] as Exception) ?? Server.GetLastError();
            StatusCode = Request.QueryString["status"].ToIntEx()
                ?? (LastError as HttpException)?.GetHttpCode()
                ?? 500;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

