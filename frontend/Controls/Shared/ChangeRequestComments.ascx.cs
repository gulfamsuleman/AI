using QProcess.Configuration;
using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Tab;

namespace QProcess.Controls.Shared
{
    public partial class ChangeRequestComments : QProcessControl
    {
        public string ChangeRequestName{ get; set; }

        public string Recipient { get; set; }
        protected void Page_Load(object sender, EventArgs e)
        {
            ChangeRequestName = Convert.ToString(Context.Request.QueryString["crName"]);
            Recipient = Convert.ToString(Context.Request.QueryString["email"]);
        }

        public void SubmitComments()
        {
            var from = CurrentSession.QUser.FullName + "<" + CurrentSession.QUser.Email + ">";
            var subject = AppSettings.Get("AppName") + " Change Request Comments - " + ChangeRequestName;
        }
    }
}