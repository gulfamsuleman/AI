using System;
using System.Web;
using QProcess.Repositories;
using QProcess.Controls;
using QProcess.Extensions;
using Unity;
using QProcess.warmup;
using System.Linq;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;

namespace QProcess
{

    public partial class MyStatus : SessionPage, IProvideReportIdForLogging
	{
		public int ReportId { get; set; }
		public int TaskId { get; set; }
		protected int UserId { get; set; }
		protected bool IsArchive { get; set; }
		protected string TasksIControl { get; set; }
        public string ControllersList { get; set; }
        public string SupervisorsList { get; set; }
        public string InterestedPartiesList { get; set; }

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
            var requestBody = JsonConvert.SerializeObject(new { reportId = reportId });
            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri(HttpContext.Current.Request.Url.GetLeftPart(UriPartial.Authority));
                var content = new StringContent(requestBody, Encoding.UTF8, "application/json");
                var response = client.PostAsync(url, content).Result;
                var json = response.Content.ReadAsStringAsync().Result;
                // The result is { "d": [ ... ] }
                var wrapper = JsonConvert.DeserializeObject<Dictionary<string, List<SupervisorDto>>>(json);
                return wrapper["d"];
            }
        }

        public Controls_Shared_ReportToolbar ReportToolbar { get; set; }

		[Dependency]
		public StatusReportRepository statusRepo { get; set; }

        [Dependency]
        public UserRepository userRepo { get; set; }

        public MyStatus()
        {
            ReportToolbar = new Controls_Shared_ReportToolbar();            
        }
        protected void Page_Load(object sender, EventArgs e)
		{
            if (statusRepo == null) statusRepo = UnityConfig.Container.Resolve<StatusReportRepository>();
            if (userRepo == null) userRepo = UnityConfig.Container.Resolve<UserRepository>();

            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request))
                || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }

            IsArchive = Context.Request.Params["archive"] != null && Convert.ToInt32(Context.Request.Params["archive"]) == 1;
			UserId = CurrentSession.QUser.Id;
			SetReportId();
			SetTaskID();
			SetTasksIControl();
			ReportToolbar.ReportId = ReportId;
			ReportToolbar.IsMyStatus = true;

			if (Context.Request.Params["getAllComments"] != null)
				CurrentSession.GetAllCommentsFlag = Convert.ToBoolean(Context.Request.Params["getAllComments"]);

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

		protected void SetReportId()
		{
			//if specified in query and have permissions use
			//else use preference if set
			//else use default
			if (Context.Request.QueryString["ReportID"] != null)
			{
				var tempId = Convert.ToInt32(Context.Request.QueryString["ReportID"]);
				if (statusRepo.CheckIsUser(UserId, tempId))
					ReportId = tempId;
			}
			else
			{
				//if preference, use
				//else use default
				var lastReportPreferenceString = userRepo.GetPreference(UserId, "LastReport");
				int lastReport;
				ReportId = Int32.TryParse(lastReportPreferenceString, out lastReport) ? lastReport : statusRepo.GetDefaultReport(UserId);
			}
			userRepo.AddPreference(UserId, "LastReport", ReportId.ToString());
			userRepo.AddPreference(UserId, "LastPrintableReport", ReportId.ToString());
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
			TasksIControl = userRepo.GetActiveChecklistsIManage(UserId);
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

