using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using QProcess.Domain.SYSTEM;
using QProcess.Extensions;
using QProcess.Models;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_SchedulingPanel : System.Web.UI.UserControl
	{
		public int InstanceId { get; set; }
		public int ChangeId { get; set; }
		protected Dictionary<double, string> TimeOptions = new Dictionary<double, string>();
        protected Dictionary<string, string> TimeZoneOptions = new Dictionary<string, string>();
        private InstanceSchedule _mySchedule;
		public InstanceSchedule MySchedule
		{
			get { return _mySchedule ?? new InstanceSchedule(); }
			set { _mySchedule = value; }
		}
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		public Controls_Shared_SchedulingPanel()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
		}

		protected IUser User => new Session(this.Session).QUser;

		protected void Page_Load(object sender, EventArgs e)
		{
			if (Context.Request.Headers["X-InstanceId"] != null)
				InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
			if (Context.Request.Headers["X-ChangeId"] != null)
				ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);

			ConstructTimeOptions();
			Repeater1.DataBind();
			Repeater2.DataBind();
			if (InstanceId > 0)
			{
				var checklistRepo = new ChecklistRepository();
				if (ChangeId <= 0)
					MySchedule = checklistRepo.GetScheduleForInstance(InstanceId);
				else
					MySchedule = checklistRepo.ApprovalGetScheduleForInstance(InstanceId, ChangeId);

				if (MySchedule.TimeZone.IsNullOrBlank())
					MySchedule.TimeZone = QProcess.Session.CurrentSession.UserTimeZone.TimeZoneName;
			}
			DataBind();
		}
		private void ConstructTimeOptions()
		{
			var newDateTime = new DateTime(1900, 1, 1, 0, 0, 0);
			for (var i = 0.0; i < 24; i += .5)
			{
				var tempTime = newDateTime.AddHours(i);
				TimeOptions.Add(i, tempTime.ToString("t"));
			}

			TimeZoneOptions = TimeZoneHelper.GetAllTimeZoneNames(true).ToDictionary(s => s, s => s);
		}
		public HtmlString SerializedSchedule()
		{
			var serializer = new JavaScriptSerializer();
			var toSerialize = new
			{
				id = MySchedule.ID,
				firstDueDate = MySchedule.FirstDueDate,//.ToString("yyyy-MM-dd"),
				firstSoftDue = MySchedule.FirstDueDate.AddDays(-1 * (MySchedule.SoftDueOffsetDays ?? 0)),//.ToString("yyyy-MM-dd"),
				lastDueDate = MySchedule.LastDueDate,//?.ToString("yyyy-MM-dd"),
				frequencyType = MySchedule.FrequencyType,
				frequencyInterval = MySchedule.FrequencyInterval,
				frequencyRecurrence = MySchedule.FrequencyRecurrance,
				dueTime = MySchedule.DueTime,
				businessDayBehavior = MySchedule.BusinessDayBehavior,
				softDueOffsetDays = MySchedule.SoftDueOffsetDays ?? 0,
				businessDayValue = MySchedule.BusinessDayValue,
				localNow = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString(),
                timeZone = MySchedule.TimeZone ?? QProcess.Session.CurrentSession.UserTimeZone.TimeZoneName,
            };
			return new HtmlString(serializer.Serialize(toSerialize));
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

