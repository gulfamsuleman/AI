using System;
using System.Web;
using System.Data;

namespace QProcess
{

    public partial class QProcess_AJAX : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            switch (Request["action"].ToLower())
            {

                case "addexistingtaskredirect":
                    int instanceId = int.Parse(HttpContext.Current.Request["instanceId"]);
                    int reportId = int.Parse(HttpContext.Current.Request["reportId"]);
                    int sectionId = int.Parse(HttpContext.Current.Request["section"]);
                    int acId;

                    AddExisting(instanceId, sectionId, out acId);

                    Response.Redirect("MyStatus.aspx?reportID=" + reportId.ToString() + "&taskID=" + acId.ToString());
                    break;
            }
        }

        private void AddExisting(int instID, int tt, out int acId)
        {
            using (var cmd = new CmdObj("QCheck_AddInstanceTaskTypeOutput"))
            {
                cmd.Add("@InstanceID", instID);
                cmd.Add("@TaskType", tt);
                cmd.Add("@acId", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                acId = int.Parse(cmd["@acId"].ToString());
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

