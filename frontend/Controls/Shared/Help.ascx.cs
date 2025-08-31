using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Controls.Shared
{
    public partial class Help : System.Web.UI.UserControl
    {
        internal NameValueCollection AppSettings => ConfigurationManager.AppSettings;
        public string TaskEmail => AppSettings["QPTAddress"];
        public string GradingEmail => AppSettings["GradingAddress"];

        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

