using System;
using QProcess.Extensions;
using System.Data;

namespace QProcess
{

    public partial class FromEmail_Complete : System.Web.UI.Page
    {
        protected string success = "false";
        protected int ac = 0;
        protected int na = 0;
        protected string nareason = "";
        protected string message = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                ac = Convert.ToInt32(Request["ac"]);
                int.TryParse(Request["na"], out na);
                nareason = Request["nareason"];
                int userID = Convert.ToInt32(Request["UserID"]);
                string name = "";

                using (var db = new CmdObj("QCheck_AutoComplete"))
                {
                    db.Add("@ActiveChecklistID", ac);
                    db.Add("@CompletedBy", userID);
                    db.Add("@IsNA", Convert.ToBoolean(na));
                    db.Add("@NAReason", nareason);
                    db.ExecuteNonQueryWithOutput();
                }

                using (var db = new CmdObj("QCheck_ActiveChecklistName"))
                {
                    db.Add("@ActiveChecklistID", SqlDbType.Int, ac, ParameterDirection.Input, 4);
                    db.Add("@ChecklistName", SqlDbType.VarChar, ParameterDirection.Output, 500);
                    db.ExecuteNonQueryWithOutput();

                    name = (String)db["@ChecklistName"].ToBlank();
                }

                if (Request["mobile"] == "1")
                    if (Request["na"] == "1")
                        message = "<span style='font-size:48pt;'>The task \"" + name + "\" has been closed as N/A.</span>";
                    else
                        message = "<span style='font-size:48pt;'>The task \"" + name + "\" has been completed.</span>";
                else
                    if (Request["na"] == "1")
                    message = "The task \"" + name + "\" has been closed as N/A.";
                else
                    message = "The task \"" + name + "\" has been completed.";

                success = "true";
            }
            catch (Exception)
            {
                if (Request["mobile"] == "1")
                {
                    Response.Redirect(Configuration.AppSettings.Get("MobileURL") + "/?ac=" + ac.ToString());
                }
                else
                {
                    Response.Redirect("../MyTasks.aspx?ac=" + ac.ToString());
                }
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

