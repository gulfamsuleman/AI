using System;
using DataAccessLayer;
using QProcess.Extensions;

namespace QProcess
{

    public partial class FromEmail_CompleteChecklist : System.Web.UI.Page
    {
        protected string message = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            int ac = Convert.ToInt32(Request["ac"]);
            int userID = Convert.ToInt32(Request["UserID"]);

            try
            {
                using (var db = new DBCommand("QCheck_AutoComplete"))
                {
                    db.Add("@ActiveChecklistID", ac)
                      .Add("@CompletedBy", userID)
                      .ExecuteNonQuery();
                }

                message = "Checklist Completed.<br><br>To return to e-mail press the 'D' key on your blackberry or press the Escape key twice.";
            }
            catch (Exception ex)
            {
                message = "Unable to complete the task.  " + ex.Message;
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

