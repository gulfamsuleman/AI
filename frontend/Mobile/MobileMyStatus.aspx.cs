using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileMyStatus : SessionPage
    {
        public int ReportId { get; set; }
        public int TaskId { get; set; }
        protected int UserId { get; set; }
        protected bool IsArchive { get; set; }
        protected string TasksIControl { get; set; }
        public string ControllersList { get; set; }
        public string SupervisorsList { get; set; }
        public string InterestedPartiesList { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            IsArchive = Context.Request.Params["archive"] != null && Convert.ToInt32(Context.Request.Params["archive"]) == 1;
            UserId = CurrentSession.QUser.Id;
            SetReportId();
            SetTaskID();
            SetTasksIControl();

            if (Context.Request.Params["getAllComments"] != null)
                CurrentSession.GetAllCommentsFlag = Convert.ToBoolean(Context.Request.Params["getAllComments"]);
        }

        protected void SetReportId()
        {
            var statusRepo = new StatusReportRepository();
            var userRepo = new UserRepository();

            if (Context.Request.QueryString["ReportID"] != null)
            {
                var tempId = Convert.ToInt32(Context.Request.QueryString["ReportID"]);
                if (statusRepo.CheckIsUser(UserId, tempId))
                    ReportId = tempId;
            }
            else
            {
                var lastReportPreferenceString = userRepo.GetPreference(UserId, "LastReport");
                int lastReport;
                ReportId = Int32.TryParse(lastReportPreferenceString, out lastReport) ? lastReport : statusRepo.GetDefaultReport(UserId);
            }
            userRepo.AddPreference(UserId, "LastReport", ReportId.ToString());
            userRepo.AddPreference(UserId, "LastPrintableReport", ReportId.ToString());

            var controllerIdsCsv = statusRepo.GetControllerUserIDsByReportID(ReportId);
            var controllerNames = new List<string>();

            if (!string.IsNullOrWhiteSpace(controllerIdsCsv))
            {
                var controllerIds = controllerIdsCsv
                    .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(id => id.Trim())
                    .Where(id => int.TryParse(id, out _))
                    .Select(id => int.Parse(id))
                    .ToList();

                foreach (var id in controllerIds)
                {
                    var name = userRepo.GetUserName(id);
                    if (!string.IsNullOrWhiteSpace(name))
                        controllerNames.Add(name);
                }
            }

            ControllersList = string.Join(", ", controllerNames);

            var supervisorsList = GetSupervisorsListFromWebService(ReportId);

            SupervisorsList = string.Join(", ", supervisorsList.Where(x => x.IsSupervisor).Select(x => x.Name));
            InterestedPartiesList = string.Join(", ", supervisorsList.Where(x => x.IsInterestedParty).Select(x => x.Name));
        }

        protected void SetTaskID()
        {
            if (Context.Request.QueryString["TaskID"] != null)
            {
                TaskId = Convert.ToInt32(Context.Request.QueryString["TaskId"]);
            }
        }

        protected void SetTasksIControl()
        {
            var userRepo = new UserRepository();
            TasksIControl = userRepo.GetActiveChecklistsIManage(UserId);
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
        public class SupervisorDto
        {
            public int ID { get; set; }
            public string Name { get; set; }
            public bool IsSupervisor { get; set; }
            public bool IsInterestedParty { get; set; }
        }

        private static List<SupervisorDto> GetSupervisorsListFromWebService(int reportId)
        {
            var url = "/DataService.asmx/GetSupervisorsList";
            var requestBody = Newtonsoft.Json.JsonConvert.SerializeObject(new { reportId = reportId });
            using (var client = new System.Net.Http.HttpClient())
            {
                client.BaseAddress = new Uri(HttpContext.Current.Request.Url.GetLeftPart(UriPartial.Authority));
                var content = new System.Net.Http.StringContent(requestBody, Encoding.UTF8, "application/json");
                var response = client.PostAsync(url, content).Result;
                var json = response.Content.ReadAsStringAsync().Result;
                var wrapper = Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, List<SupervisorDto>>>(json);
                return wrapper["d"];
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

