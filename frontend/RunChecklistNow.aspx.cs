using System;
using System.Web;
using DataAccessLayer;
using QProcess.Extensions;
using QProcess.Configuration;

namespace QProcess
{

    public partial class RunChecklistNow : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            var _session = HttpContext.Current.Session;
            var user = _session["CurrentUser"] as Models.IUser;
            if (user == null)
                _session["CurrentUser"] = new Repositories.UserRepository().GetUser(QProcess.Session.CurrentSession.QUser.Username.ToLower().Replace(AppSettings.Get("Domain") + "\\", ""));
            var iuser = _session["CurrentUser"] as Models.IUser;

            using (var db = new DBCommand("QCheck_RunChecklistNow"))
            {
                db.Add("@ChecklistID", Request["i"])
                  .Add("@UserID", iuser.Id)
                  .Add("@ActiveChecklistID", System.Data.ParameterDirection.Output, System.Data.DbType.Int32)
                  .ExecuteNonQuery();

                Response.Redirect("ManageSingleChecklist.aspx?taskId=" + db.GetOutputParameter("@ActiveChecklistID").ToBlank() + "&taskStage=1&changeId=-1");
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

