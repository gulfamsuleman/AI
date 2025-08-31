using QProcess.Configuration;
using System.Web.UI;

namespace QProcess.Controls
{
    public class QProcessControl : UserControl
    {
        public string Firm { get { return AppSettings.Get("Firm"); } }

        public QProcessMasterPage MasterPage => Page.Master as QProcessMasterPage;

        protected Session CurrentSession => QProcess.Session.CurrentSession;
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

