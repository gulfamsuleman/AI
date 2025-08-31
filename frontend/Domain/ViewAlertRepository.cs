using System;
using System.Collections.Generic;
using System.Data;
using QProcess.Models;

namespace QProcess.Repositories
{
	public class ViewAlertRepository
	{
		public IEnumerable<ViewAlert> GetAlertTimes(int activeChecklistId, TaskStage taskStage)
		{
			using (var cmd = new CmdObj("QStatus2_GetAlertTimes"))
			{
				cmd.Add("@ActiveChecklistID", activeChecklistId);
				cmd.Add("@IsCurrent", taskStage == TaskStage.Current);
				cmd.Add("@IsArchived", taskStage == TaskStage.Archived);
				var alerts = cmd.GetDS();
				return alerts.Tables[0].AsEnumerable().Select(a => new ViewAlert
					{
						Alertee = (string)a["alertee"],
                        AlertTime = (DBNull.Value != a["alerttime"]) ? (DateTime)a["alerttime"] : new DateTime(1900, 1, 1),
						AlertTimeText = (DBNull.Value != a["alerttime"]) ? (string)a["alerttimetext"] : "",
						IsSent = (int)a["issent"] == 1,
						Type = (string)a["type"],
						TypeId = (int)a["typeid"]
					});
			}
		}
	}

	public class ViewAlert : IViewAlert
	{
		public string Alertee { get; set; }
		public DateTime AlertTime { get; set; }
		public string AlertTimeText { get; set; }
		public bool IsSent { get; set; }
		public string Type { get; set; }
		public int TypeId { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

