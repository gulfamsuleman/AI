using System;
using System.Collections.Generic;
using System.Linq;
using System.Data;

namespace QProcess.Repositories
{
	public class SelectListRepository
	{
		public NamedEntity[] GetItemTypes()
		{
			return GetDisplayableEntities("QCheck_GetItemTypes", "ID", "Name", null);
		}

		public NamedEntity[] GetTaskTypesForReport(int reportId, int userId)
		{
			return GetDisplayableEntities("QStatus_GetTaskTypes", 
				"ValStr", 
				"KeyStr", 
				new Dictionary<string, object> { 
					{ "@ReportID", reportId },
					{ "@UserId", userId }
				});
		}

		public NamedEntityGroup[] GetReportsForInstance(int userId, int instanceId)
		{
			using (var cmd = new CmdObj("QCheck_GetInstanceReports"))
			{
				cmd.Add("@InstanceID", instanceId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
                return cmd.GetDS().Tables[0].AsEnumerable()
                    .GroupBy(r => Convert.ToString(r["RptGroup"]))
                    .Select(g => new NamedEntityGroup
                    {
                        Name = g.Key,
                        Entities = g.Select(r => new NamedEntity
                        {
                            Id = Convert.ToInt32(r["ID"]),
                            Name = Convert.ToString(r["Name"])
                        })
                        .ToArray()
                    })
                    .ToArray();
			}
        }

        public NamedEntity[] GetTaskTemplates(int userId, bool isAdmin)
        {
            return GetDisplayableEntities("QCheck_GetMyChecklistsByFolder", "Id", "Name", new Dictionary<string, object> {
                { "@UserID", userId },
                { "@memberGroupId", 0 },
                { "@managerGroupId", 0 },
                { "@isAdmin", isAdmin },
                { "@search", "" },
                { "@templateOnly", true }
            });
        }

        public NamedEntity[] GetGroups()
		{
			return GetDisplayableEntities("QCheck_GetGroups", "ID", "FullName", null);
		}

		public NamedEntity[] GetMultiUserGroups()
		{
			return GetDisplayableEntities("QCheck_GetMultiUserGroups", "ID", "Name", null);
		}

		public NamedEntity[] GetFolders(int userId)
		{
			return GetDisplayableEntities("QCheck_GetFolders", "ID", "FolderName", new Dictionary<string, object> { { "@UserID", userId } });
		}

		public NamedEntity[] GetAllSupervisors()
		{
			return GetDisplayableEntities("Q_GetAllSupervisors", "ID", "Name", null);
		}

		public NamedEntity[] GetUsers(int userId, bool isAdmin)
		{
			return GetDisplayableEntities("QCheck_GetMembers", "ID", "FullName",
			                              new Dictionary<string, object> {{"@login", userId}, {"@isAdmin", isAdmin}});
		}

        public NamedEntity[] GetSupervisedGroups(string loginName, bool peopleOnly)
        {
            return GetDisplayableEntities("QStatus_GroupsSupervisedByLogin", "ID", "name",
                                          new Dictionary<string, object> { { "@login", loginName }, { "@PeopleOnly", peopleOnly } });
        }

		public NamedEntity[] GetGradingUserReports(int userId)
		{
			return GetDisplayableEntities("Grading_Daily_GetUserReports", "reportID", "name",
											new Dictionary<string, object> {{"@UserID", userId}});
		}

		public NamedEntity[] GetGradingPeriods()
		{
			return GetDisplayableEntities("Grading_Daily_GetGradingPeriods", "ID", "Column1", null);
		}

		public NamedEntity[] GetMySectionsCondensed(int userId)
		{
			return GetDisplayableEntities("QStatus_MySections_Condensed", "ID", "Column1",
											new Dictionary<string, object> { {"@UserID", userId} });
		}

		public NamedEntity[] GetReports()
		{
			return GetDisplayableEntities("QStatus_GetReports", "ID", "Description", null);
		}

		public NamedEntity[] GetReportsNoSupervisors()
		{
			return GetDisplayableEntities("QStatus_GetReports_NoSupervisors", "ID", "Description", null);
		}

		public NamedEntity[] GetAvailableUsers(int userId, int setId)
		{
			return GetDisplayableEntities("PriorityListSet_GetAvailableUsers", "id", "fullname",
			                              new Dictionary<string, object> {{"@SetID", setId}, {"@UserID", userId}});
		}

		public NamedEntity[] GetOverdueRecipients(int userId, int controllerID)
		{
			return GetDisplayableEntities("QCheck_MessageToOverdues_RecipientList", "AssigneeID", "FullName",
			                              new Dictionary<string, object> {{"@UserID", userId}, {"@ControllerID", controllerID}});
		}

		public NamedEntity[] GetReportsUserList()
		{
			return GetDisplayableEntities("QCheck_GetUserList", "ID", "fullname", null);
		}

        public NamedEntity[] GetPrintUserList(int userId)//added by Venkat Kanakamedala
        {
            return GetDisplayableEntities("QCheck_GetPrintUserList", "ID", "fullname", new Dictionary<string, object> { { "@UserID", userId } });
        }

        public NamedEntity[] GetConfidentialReports()
		{
			return GetDisplayableEntities("QStatus_GetDontEmailReports", "ID", "Description", null);
		}

		private NamedEntity[] GetDisplayableEntities(string storedProceedure, string idColumn, string nameColumn, IDictionary<string, object> parameters)
		{
			using (var cmd = new CmdObj(storedProceedure))
			{
				if (parameters != null && parameters.Any())
					foreach (var param in parameters)
						cmd.Add(param.Key, param.Value);

				var ds = cmd.GetDS();
				return ds.Tables[0].AsEnumerable()
                    .Select(r => new NamedEntity { Id = Convert.ToInt32(r[idColumn]), Name = Convert.ToString(r[nameColumn]) })
                    .ToArray();
			}
		}
	}

    [Serializable]
    public class NamedEntity
	{
		public int Id { get; set; }
		public string Name { get; set; }
	}

    [Serializable]
    public class NamedEntityGroup
	{
		public string Name { get; set; }
		public NamedEntity[] Entities { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

