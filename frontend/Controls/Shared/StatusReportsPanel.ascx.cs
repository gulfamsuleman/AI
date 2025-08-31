using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_StatusReportsPanel : System.Web.UI.UserControl
	{
		public int InstanceId { get; set; }
		public int ChangeId { get; set; }
		public int UserId { get; set; }
		private List<InstanceReportAssignment> _myReports { get; set; }
		public List<InstanceReportAssignment> MyReports { get { return _myReports ?? new List<InstanceReportAssignment>(); } set { _myReports = value; } }
		public IEnumerable<NamedEntity> Folders { get; set; }
		public string StatusReport { get; set; }//added by venkat 06/14/2018
		public string StatusReportSection { get; set; }//added by venkat 06/14/2018
		protected void Page_Load(object sender, EventArgs e)
		{
			if (Context.Request.Headers["X-InstanceId"] != null)
				InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
			if (Context.Request.Headers["X-UserId"] != null)
				UserId = int.Parse(Context.Request.Headers["X-UserId"]);
			if (Context.Request.Headers["X-ChangeId"] != null)
				ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);
			MyReports = new List<InstanceReportAssignment>();
			var userRepo = new UserRepository();
			StatusReport = userRepo.GetPreference(UserId, "StatusReport");//added by venkat 06/14/2018
			StatusReportSection = userRepo.GetPreference(UserId, "StatusReportSection");//added by venkat 06/14/2018
			if (InstanceId != 0)
			{
				var checklistRepo = new ChecklistRepository();
				MyReports = checklistRepo.GetInstanceReports(InstanceId);
			}
			if (UserId != 0)
			{
				var selectListRepo = new SelectListRepository();
				Folders = selectListRepo.GetFolders(UserId);
			}
			DataBind();
		}

		public HtmlString SerializedReports()
		{
			var serializer = new JavaScriptSerializer();
			var toSerialize = MyReports.Select(r => new { id = r.ID, reportId = r.ReportID, reportName = r.Report, sectionName = r.TaskType }).ToList();
			return new HtmlString(serializer.Serialize(toSerialize));
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

