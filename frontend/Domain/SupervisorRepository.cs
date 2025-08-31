using DotNetOpenAuth;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

namespace QProcess.Repositories
{
    public class SupervisorRepository
	{
		// Controllers
		public List<Controller> GetControllersList(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetReportUsers"))
			{
				cmd.Add("@ReportID", reportId);
				var results = cmd.GetDS();
				return results.Tables[0].AsEnumerable().Select(row => new Controller()
				{
					ID = (int)row["ID"],
					Name = (string)row["FullName"]
				}).ToList();
			}
		}
		
		public void AddController(int reportId, int groupId)
		{
			using (var cmd = new CmdObj("QStatus_AddReportUser"))
			{
				cmd.Add("@GroupId", groupId);
				cmd.Add("@ReportId", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteController(int delId)
		{
			using (var cmd = new CmdObj("QStatus_DeleteReportUser"))
			{
				cmd.Add("@ID", delId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		// Supervisors
		public List<Supervisor> GetSupervisorsList(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetSupervisors"))
			{
				cmd.Add("@ReportID", reportId);
				var results = cmd.GetDS();
				return results.Tables[0].AsEnumerable().Select(row => new Supervisor()
				{
					ID = (int)row["ID"],
					Name = (string)row["Supervisor"],
					IsInterestedParty = (bool)row["InterestedParty"],
					IsSupervisor = !(bool)row["InterestedParty"]
				}).ToList();
			}
		}

		public void AddSupervisor(int reportId, int supervisorGroupId)
		{
			using (var cmd = new CmdObj("QStatus_AddSupervisors"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@SupervisorGroupID", supervisorGroupId);
				cmd.Add("@Allow", 1);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteSupervisor(int id)
		{
			using (var cmd = new CmdObj("QStatus_DeleteSupervisor"))
			{
				cmd.Add("@ID", id);
				cmd.Add("@Allow", 1);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
        public bool IsPersonalReportByReportID(int reportId)
        {
            using (var cmd = new CmdObj("QStatus_IsPersonalReportByReportID"))
            {
                cmd.Add("@ReportID", reportId);
                cmd.Add("@isPersonalreport", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToBoolean(cmd["@isPersonalreport"]);
            }
        }

        public void ToggleInterestedParty(int id)
		{
			using (var cmd = new CmdObj("QStatus_ToggleInterestedParty"))
			{
				cmd.Add("@ID", id);
				cmd.Add("@Allow", 1);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        //Supervised Users
        public List<SupervisedUser> GetSupervisedUsers(int supervisorId, bool includeIP = false)
        {
            using (var cmd = new CmdObj("QStatus_GetSupervisedUsers"))
            {
                cmd.Add("@UserID", supervisorId);
				if(includeIP) cmd.Add("@IncludeIP", true);
                var results = cmd.GetDS();
				return results.Tables[0].AsEnumerable()
					.Select(row => new SupervisedUser()
					{
						ID = (int)row["ID"],
						Name = (string)row["Name"]
					})
					.ToList();
            }
        }
    }

	public class Controller
	{
		public int ID { get; set; }
		public string Name { get; set; }
	}

    public class SupervisedUser
    {
        public int ID { get; set; }
        public string Name { get; set; }
    }

    public class Supervisor
	{
		public int ID { get; set; }
		public string Name { get; set; }
		public bool IsSupervisor { get; set; }
		public bool IsInterestedParty { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

