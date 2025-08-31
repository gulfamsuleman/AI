using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_AlertsRemindersPanel : System.Web.UI.UserControl
	{
		public int InstanceId { get; set; }
		public int ChangeId { get; set; }
		private List<InstanceAlertReminder> _myAlertsReminders { get; set; }
		public List<InstanceAlertReminder> MyAlertsReminders { get { return _myAlertsReminders ?? new List<InstanceAlertReminder>(); } set { _myAlertsReminders = value; } }
		protected Dictionary<double, string> TimeOptions = new Dictionary<double, string>();
		protected IEnumerable<NamedEntity> Assignees { get; set; }

		protected void Page_Load(object sender, EventArgs e)
		{
			if (Context.Request.Headers["X-InstanceId"] != null)
				InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
			MyAlertsReminders = new List<InstanceAlertReminder>();
			var newDateTime = new DateTime(1900, 1, 1, 0, 0, 0);
			for (var i = 0.0; i < 24; i += .5)
			{
				var tempTime = newDateTime.AddHours(i);
				TimeOptions.Add(i, tempTime.ToString("t"));
			}
			if (InstanceId != 0)
			{
				var checklistRepo = new ChecklistRepository();
				MyAlertsReminders = checklistRepo.GetInstanceAlertsReminders(InstanceId, ChangeId);
			}
			var selectListRepo = new SelectListRepository();
			Assignees = selectListRepo.GetGroups();
			DataBind();
		}
		public HtmlString SerializedAlerts()
		{
			var serializer = new JavaScriptSerializer();
			var toSerialize = MyAlertsReminders.Select(a => new { id = a.ID, type = a.AlertType, typeId = (int)a.AlertTypeEnum, alerteeId = a.AlerteeID, alertee = a.Alertee, daysBefore = a.DaysBefore, time = a.AlertTime, text = a.AlertText, existing = a.Existing }).ToList();
			return new HtmlString(serializer.Serialize(toSerialize));
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

