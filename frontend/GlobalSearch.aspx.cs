using System;
using System.Data;
using System.Data.Common;
using System.Text;
using DataAccessLayer;
using QProcess.Extensions;

namespace QProcess
{

    public partial class GlobalSearch : SessionPage
    {
        protected string options = "";
        protected void Page_Load(object sender, EventArgs e)
        {
            var sb = new StringBuilder(@"<option value=""0"">All Status Reports</option>");
            using (var db = new DBCommand("QStatus_GetReportList"))
            {
                var ds = db.Add("@UserID", QProcess.Session.CurrentSession.QUser.Id)
                    .ExecuteDataSet();

                foreach (DataRow row in ds.Tables[0].Rows) 
                {
                    sb.Append($@"<option value=""{row[0]}"">{row[1]}</option>");
                }
            }
            options = sb.ToString();
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

