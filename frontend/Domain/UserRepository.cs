using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Providers.Entities;
using System.Web.Security;
using QProcess.Domain.Models;
using QProcess.Extensions;
using QProcess.Models;
using static DotNetOpenAuth.OpenId.Extensions.AttributeExchange.WellKnownAttributes;

namespace QProcess.Repositories
{
    public class UserRepository
    {
        public bool AuthenticateUser(string username, string password, out IUser user)
		{
			var isValid = false;

			using (var cmd = new CmdObj("QCheck_CheckPassword"))
			{
				cmd.Add("@login", SqlDbType.VarChar, username, ParameterDirection.Input, 50);
				cmd.Add("@Password", SqlDbType.VarChar, password, ParameterDirection.Input, 50);
				cmd.Add("@isValid", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();

				isValid = (bool)cmd["@isValid"];
			}

			if (isValid)
			{
				user = GetUser(username);
				return true;
			}
			else
			{
				user = null;
				return false;
			}
		}

		public IUser GetUser(string username)
        {
            var dbUser = new User { Username = username };

            using (var cmd = new CmdObj("QCheck2_GetUserInfo"))
            {
                cmd.Add("@loginID", SqlDbType.VarChar, username, ParameterDirection.Input, 50);
                cmd.Add("@ID", SqlDbType.Int, null, ParameterDirection.Output, 4);
                cmd.Add("@GroupID", SqlDbType.Int, null, ParameterDirection.Output, 4);
                cmd.Add("@Admin", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                cmd.Add("@DepartmentAdmin", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                cmd.Add("@Priorities", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                cmd.Add("@Email", SqlDbType.VarChar, null, ParameterDirection.Output, 50);
                cmd.ExecuteNonQueryWithOutput();

                //#warning add graceful way of handling DbNull in @ID here
                if (cmd["@ID"] != null && cmd["@ID"] != DBNull.Value)
                {
                    dbUser.Id = Convert.ToInt32(cmd["@ID"]);
                    dbUser.GroupId = Convert.ToInt32(cmd["@GroupID"]);
                    //dbUser.IsBetaUser = Convert.ToBoolean(cmd["@Beta"]);
                    dbUser.IsAdmin = Convert.ToBoolean(cmd["@Admin"]);
                    dbUser.IsDepartmentAdmin = Convert.ToBoolean(cmd["@DepartmentAdmin"]);
                    dbUser.UsesPriorities = Convert.ToBoolean(cmd["@Priorities"]);
                    dbUser.Email = (string)cmd["@Email"];
                    dbUser.MyTimeZone = UserTimeZone.GetUserTimeZone(dbUser.Id, System.Configuration.ConfigurationManager.AppSettings["SystemTimeZone"]);
                }
                else
                {
                    dbUser.Id = 0;
                    dbUser.GroupId = 0;
					dbUser.IsBetaUser = false;
                    dbUser.IsAdmin = false;
                    dbUser.IsDepartmentAdmin = false;
                    dbUser.UsesPriorities = false;
                    dbUser.Email = String.Empty;
                    dbUser.MyTimeZone = null;
                }
            }

            InitUser(dbUser);

            return dbUser;
        }

        public IUser GetUserByEmail(string email)
        {
            var dbUser = new User { Email = email };

            using (var cmd = new CmdObj("QCheck2_GetUserInfo_ByEmail"))
            {
                cmd.Add("@Email", SqlDbType.VarChar, email, ParameterDirection.Input, 100);
                cmd.Add("@LoginID", SqlDbType.VarChar, null, ParameterDirection.Output, 50);
                cmd.Add("@ID", SqlDbType.Int, null, ParameterDirection.Output, 4);
                cmd.Add("@GroupID", SqlDbType.Int, null, ParameterDirection.Output, 4);
                cmd.Add("@Admin", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                cmd.Add("@DepartmentAdmin", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                cmd.Add("@Priorities", SqlDbType.Bit, null, ParameterDirection.Output, 1);
                
                cmd.ExecuteNonQueryWithOutput();

                //#warning add graceful way of handling DbNull in @ID here
                if (cmd["@ID"] != null && cmd["@ID"] != DBNull.Value)
                {
                    dbUser.Id = Convert.ToInt32(cmd["@ID"]);
                    dbUser.GroupId = Convert.ToInt32(cmd["@GroupID"]);
                    dbUser.IsAdmin = Convert.ToBoolean(cmd["@Admin"]);
                    dbUser.IsDepartmentAdmin = Convert.ToBoolean(cmd["@DepartmentAdmin"]);
                    dbUser.UsesPriorities = Convert.ToBoolean(cmd["@Priorities"]);
                    dbUser.Username = (string)cmd["@LoginID"];
                    dbUser.MyTimeZone = UserTimeZone.GetUserTimeZone(dbUser.Id, System.Configuration.ConfigurationManager.AppSettings["SystemTimeZone"]);
                }
                else
                {
                    dbUser.Id = 0;
                    dbUser.GroupId = 0;
                    dbUser.IsAdmin = false;
                    dbUser.IsDepartmentAdmin = false;
                    dbUser.UsesPriorities = false;
                    dbUser.Email = String.Empty;
                    dbUser.MyTimeZone = null;
                }
            }

            InitUser(dbUser);

            return dbUser;
        }

        private void InitUser(User dbUser)
        {
            using (var cmd = new CmdObj("QStatus_InitUser"))
            {
                cmd.Add("@UserID", dbUser.Id);
                cmd.Add("@IsSupervisor", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@Font", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();

                dbUser.SupervisorStatus = Convert.ToInt32(cmd["@IsSupervisor"]);
                dbUser.Font = Convert.ToInt32(cmd["@Font"]);
            }

            using (var cmd = new CmdObj("QCheck_GetAppSettings"))
            {
                cmd.Add("@UserID", dbUser.Id);
                cmd.Add("@AppURL", SqlDbType.VarChar, null, ParameterDirection.Output, 50);
                cmd.ExecuteNonQueryWithOutput();

                dbUser.AppUrl = Convert.ToString(cmd["@AppURL"]);
            }

            using (var cmd = new CmdObj("QCheck_GetUserName"))
            {
                cmd.Add("@ID", dbUser.Id);
                cmd.Add("@UserName", SqlDbType.VarChar, ParameterDirection.Output, 100);
                cmd.ExecuteNonQueryWithOutput();

                dbUser.FullName = Convert.ToString(cmd["@UserName"]);
            }

            using (var cmd = new CmdObj("Grading_IsAdmin"))
            {
                cmd.Add("@UserID", dbUser.Id);
                cmd.Add("@IsAdmin", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                dbUser.IsGradingAdmin = Convert.ToBoolean(cmd["@IsAdmin"]);
            }

            using (var cmd = new CmdObj("Api_IsAdmin"))
            {
                cmd.Add("@UserID", dbUser.Id);
                //cmd.Add("@IsAdmin", SqlDbType.Bit, ParameterDirection.Output, 1);
                //cmd.ExecuteNonQueryWithOutput();
                bool result = Convert.ToBoolean(cmd.GetScalar());

                dbUser.IsApiAdmin = result;
            }

            using (var cmd = new CmdObj("QCheck_IsOverdueAdmin"))
            {
                cmd.Add("@UserID", dbUser.Id);
                cmd.Add("@IsAdmin", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                dbUser.IsOverdueAdmin = Convert.ToBoolean(cmd["@IsAdmin"]);
            }

            using (var cmd = new CmdObj("QStatus_SupervisorsByLogin"))
            {
                cmd.Add("@Login", dbUser.Username.BlankIfNull());
                var supervisors = cmd.GetDS().Tables[0];
                if (supervisors.Rows.Count > 0)
                    dbUser.SupervisorId = Convert.ToInt32(supervisors.Rows[0]["ID"]);

                dbUser.AllSupervisors = supervisors.Rows.OfType<DataRow>().Select(r => Convert.ToInt32(r["ID"])).ToArray();
            }

            using (var cmd = new CmdObj("Q_IsSupervisor"))
            {
                cmd.Add("@UserId", dbUser.Id);
                cmd.Add("@IsSupervisor", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                dbUser.IsSupervisor = Convert.ToBoolean(cmd["@IsSupervisor"]);
            }

            dbUser.ShowComments = GetPreference(dbUser.Id, "ShowComments") == "True";
        }

        public List<User> GetUsersBySupervisor(int userId, int includeIP = 0)
        {
            using (var cmd = new CmdObj("QStatus_GetSupervisedUsers"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@IncludeIP", includeIP);
                var users = cmd.GetDS();
                return users.Tables[0].AsEnumerable().Select(u => new User
                {
                    Id = (int)u["ID"],
                    FullName = (string)u["Name"]
                }).ToList();
            }
        }

        public string GetPreference(int userId, string preference, int reportId = 0)
		{
			using (var cmd = new CmdObj("QStatus_GetPreference"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@PreferenceType", preference);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@PreferenceValue", SqlDbType.VarChar, ParameterDirection.Output, 50);
				cmd.ExecuteNonQueryWithOutput();

				var val = cmd["@PreferenceValue"];
				return Convert.IsDBNull(val) ? null : Convert.ToString(val);
			}
		}

		public void AddPreference(int userId, string preferenceType, string preferenceValue, int reportId = 0)
		{
			using (var cmd = new CmdObj("QStatus_AddPreference"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@PreferenceType", preferenceType);
				cmd.Add("@PreferenceValue", preferenceValue);
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
		
		public Tuple<DateTime, DateTime> GetPreferredDateRange(int userId, DateTime? startDate = null)
		{
            UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;
            int plusDays = 7;
            int minusDays = -7;
            int plusDays2 = 0;
            int minusDays2 = 0;
            DateTime d = myTz.GetLocalTimeNow().Date;

            if (int.TryParse(GetPreference(userId, "FilterDays"), out plusDays2)) plusDays = plusDays2;
            int.TryParse(GetPreference(userId, "FilterDaysMinus"), out minusDays2);

            if (minusDays2 < minusDays) minusDays = minusDays2;

            return Tuple.Create(startDate.HasValue ? startDate.Value : d.AddDays(minusDays), d.AddDays(plusDays + 1).AddSeconds(-1));

		}

		public int GetPreferredRecurrence(int userId)
		{
			int recurrence = 0;
			int.TryParse(GetPreference(userId, "FilterTaskRecurrence"), out recurrence);
			return recurrence;
		}

		public int? GetLastReport(int userId)
		{
			var pref = GetPreference(userId, "LastReport");
			return String.IsNullOrWhiteSpace(pref) ? (int?)null : Convert.ToInt32(pref);
		}

        public void AddUser(string login, string name, string email, string password, bool admin, bool beta = false)
        {
            using (var cmd = new CmdObj("QCheck_AddUser"))
            {
                cmd.Add("@Login", login);
                cmd.Add("@Name", name);
                cmd.Add("@Email", email);
                cmd.Add("@Password", password);
                cmd.Add("@Admin", admin);
                cmd.Add("@Beta", beta);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

		public void UpdateUser(int id, string login, string name, string email, string password, bool admin, int? empId = null, bool beta = false)
		{
			using (var cmd = new CmdObj("QCheck_UpdateUser"))
			{
				cmd.Add("@ID", id);
				cmd.Add("@Login", login);
				cmd.Add("@Name", name);
				cmd.Add("@Email", email);
				cmd.Add("@Password", password);
				cmd.Add("@Admin", admin);
                cmd.Add("@Beta", beta);
                cmd.Add("@EmpId", empId);
                cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteUser(int id)
		{
			using (var cmd = new CmdObj("QCheck_DeleteUsers"))
			{
				cmd.Add("@ID", id);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public List<User> GetUsers()
		{
			using (var cmd = new CmdObj("QCheck_GetUsers"))
			{
				var users = cmd.GetDS();
				return users.Tables[0].AsEnumerable().Select(u => new User{
					Id = (int)u["ID"],
					ShortName = (string)u["ShortName"],
					FullName = (string)u["FullName"],
					Email = (string)u["Email"],
					Password = (string)u["Password"],
					IsAdmin = (bool)u["Admin"],
					IsDepartmentAdmin = (bool)u["DepartmentAdmin"],
					IsDeleted = (bool)u["IsDeleted"]
				}).ToList();
			}
		}

		public List<UserGroup> GetGroups()
		{
			using (var cmd = new CmdObj("QCheck_GetGroupsAll"))
			{
				var userGroups = cmd.GetDS();
				return userGroups.Tables[0].AsEnumerable().Select(ug => new UserGroup
					{
						Id = (int)ug["ID"],
						GroupName = (string)ug["FullName"],
						Owner = (string)ug["Owner"]
                    }).ToList();
			}
		}

        public List<UserGroup> GetSupervisedUsersByGroups(int supervisorId)
        {
            using (var cmd = new CmdObj("QCheck_GetSupervisedUsersByGroup"))
            {
                cmd.Add("@SupervisorID", supervisorId);
                var userGroups = cmd.GetDS();
                return userGroups.Tables[0].AsEnumerable().Select(ug => new UserGroup
                {
                    Id = (int)ug["ID"],
                    GroupName = (string)ug["GroupName"],
                }).ToList();
            }
        }

        public List<User> GetSupervisedUsersInGroups(int supervisorId, int groupId)
        {
            using (var cmd = new CmdObj("QCheck_GetSupervisedUsersInGroup"))
            {
                cmd.Add("@SupervisorID", supervisorId);
                cmd.Add("@GroupID", groupId);
                var userGroups = cmd.GetDS();
                return userGroups.Tables[0].AsEnumerable().Select(ug => new User
                {
                    Id = (int)ug["ID"],
                    FullName = (string)ug["FullName"],
                }).ToList();
            }
        }



        public List<UserGroup> GetMyGroups(int userId, int filterUserId)
		{
			using (var cmd = new CmdObj("QCheck_GetMyGroups"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@FilterUserID", filterUserId);
				var myGroups = cmd.GetDS();
				return myGroups.Tables[0].AsEnumerable().Select(mg => new UserGroup
					{
						Id = (int)mg["ID"],
						GroupName = (string)mg["Name"],
						Owner = (string)mg["owner"],
						IsMember = (int)mg["isMember"] == 1,
						IsOwner = (int)mg["isOwner"] == 1
					}).ToList();
			}
		}

        public List<UserGroup> GetGroupsIManageForUser(int userId, int supervisorId, string groupIds)
        {
            using (var cmd = new CmdObj("QCheck_MyGroupsForDashboard"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@SupervisorID", supervisorId);
                var myGroups = cmd.GetDS();
                return myGroups.Tables[0].AsEnumerable().Select(mg => new UserGroup
                {
                    Id = (int)mg["ID"],
                    GroupName = (string)mg["Name"],
                    Owner = (string)mg["owner"],
                    IsMember = (int)mg["isMember"] == 1,
                    IsOwner = (int)mg["isOwner"] == 1
                }).ToList();
            }
        }

        public string GetActiveChecklistsIManage(int userId)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder("");
            using (var cmd = new CmdObj("QCheck_GetActiveChecklistsIManage"))
            {
                cmd.Add("@UserID", userId);
                var ds = cmd.GetDS();
                foreach (DataRow r in ds.Tables[0].Rows)
                {
                    sb.Append(r[0].ToString() + ",");
                }
            }
            if (sb.Length > 0)
            {
                sb.Remove(sb.Length - 1, 1);
            }
            return sb.ToString();
        }

		public void AddGroup(int userId, string name)
		{
			using (var cmd = new CmdObj("QCheck_AddGroup"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Name", name);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteGroup(int id)
		{
			using (var cmd = new CmdObj("QCheck_DeleteGroup"))
			{
				cmd.Add("@ID", id);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public int GetGroupOwner(int groupId)
        {
            using (var cmd = new CmdObj("QCheck_GetGroupOwner"))
            {
                cmd.Add("@ID", groupId);
                return cmd.GetDS().Tables[0].Rows[0].Field<int>("Owner");
            }
        }

        public void ChangeGroupOwner(int groupId, int owner, int userId)
        {
            using (var cmd = new CmdObj("QCheck_GroupOwnerChange"))
            {
                cmd.Add("@GroupID", groupId);
                cmd.Add("@NewOwner", owner);
                cmd.Add("@UserID", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<User> GetUsersInGroup(int groupId)
		{
			using (var cmd = new CmdObj("QCheck_GetGroupMembers"))
			{
				cmd.Add("@ID", groupId);
				var groupUsers = cmd.GetDS();
				return groupUsers.Tables[0].AsEnumerable().Select(gu => new User
					{
						Id = (int)gu["ID"],
						FullName = (string)gu["FullName"],
						GroupId = (int)gu["GroupID"],
                        UserId = (int)gu["UserID"]
					}).ToList();
			}
		}

        public int GetGroupIDFromName(string groupName)
        {
			int groupID = 0;
            using (var cmd = new CmdObj("QCheck_GetGroupIDFromName"))
            {
                try
                {
                    cmd.Add("@fullname", groupName);
                    groupID = cmd.GetDS().Tables[0].Rows[0]["ID"].ToIntEx().Value;
                }
				catch {
					groupID = 0;
				}

            }
			return groupID; 
        }

        public List<User> GetGroupUsers(int groupId)
        {
            using (var cmd = new CmdObj("QCheck_GetGroupUsers"))
            {
                cmd.Add("@ID", groupId);
                var groupUsers = cmd.GetDS();
                return groupUsers.Tables[0].AsEnumerable().Select(gu => new User
                {
                    Id = (int)gu["ID"],
                    FullName = (string)gu["FullName"]
                }).ToList();
            }
        }

        public void RemoveUserFromGroup(int membershipId)
		{
			using (var cmd = new CmdObj("QCheck_DeleteGroupUser"))
			{
				cmd.Add("@ID", membershipId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public void RemoveUserFromGroupById(int userId, int groupId)
        {
            using (var cmd = new CmdObj("QCheck_DeleteGroupUserByUserId"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@GroupID", groupId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void AddUserToGroup(int userId, int groupId)
		{
			using (var cmd = new CmdObj("QCheck_AddGroupUser"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@GroupID", groupId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void SetPreferences(int userId, int assignee, int controller, int due, int report, int priority, int alert, int softDue, int eChecklist, bool weeklySummaryEmail = false)
		{
			using (var cmd = new CmdObj("QStatus_AutomationEmailPreferences_Set"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Assignee", assignee);
				cmd.Add("@Controller", controller);
				cmd.Add("@Due", due);
                cmd.Add("@Report", report == 0 ? (object)DBNull.Value : report);
                cmd.Add("@Priority", priority);
				cmd.Add("@Alert", alert);
				cmd.Add("@SoftDue", softDue);
				cmd.Add("@EChecklistPriority", eChecklist);
                cmd.Add("@WeeklySummaryEmail", weeklySummaryEmail);
                cmd.ExecuteNonQueryWithOutput();
			}
		}

		public Preferences GetPreferences(int userId)
		{
			using (var cmd = new CmdObj("QStatus_AutomationEmailPreferences_Get"))
			{
				cmd.Add("@UserID", userId);
				var p = cmd.GetDS().Tables[0].Rows[0];
				var pref = new Preferences
				{
					Assignee = (int)p["Assignee"],
					Controller = (int)p["Controller"],
					Due = (int)p["Due"],
                    ReportOrig = p["ReportOrig"] == DBNull.Value ? 0 : (int)p["ReportOrig"],
                    Priority = (int)p["Priority"],
					Alert = (int)p["Alert"],
					SoftDue = (int)p["SoftDue"],
					EChecklistPriority = (int)p["EChecklistPriority"]                    
				};
                
                if (p.Table.Columns.Contains("WeeklySummaryEmail"))
                    pref.WeeklySummaryEmail = (bool)p["WeeklySummaryEmail"];

                return pref;
			}
		}

        public void SetBulkImportPreferences(int userId, int assignee, int controller, int due, int report, int priority, int softDue)
        {
            using (var cmd = new CmdObj("QStatus_BulkImportPreferences_Set"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@Assignee", assignee);
                cmd.Add("@Controller", controller);
                cmd.Add("@Due", due);
                cmd.Add("@Report", report == 0 ? (object)DBNull.Value : report);
                cmd.Add("@Priority", priority);
                cmd.Add("@SoftDue", softDue);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public Preferences GetBulkImportPreferences(int userId)
        {
            using (var cmd = new CmdObj("QStatus_BulkImportPreferences_Get"))
            {
                cmd.Add("@UserID", userId);
                var p = cmd.GetDS().Tables[0].Rows[0];
                return new Preferences
                {
                    Assignee = (int)p["Assignee"],
                    Controller = (int)p["Controller"],
                    Due = (int)p["Due"],
                    ReportOrig = p["Report"] == DBNull.Value ? 0 : (int)p["Report"],
                    Priority = (int)p["Priority"],
                    SoftDue = (int)p["SoftDue"],
                    AssigneeName = (string)p["AssigneeName"],
                    ControllerName = (string)p["ControllerName"],
                    ReportName = (string)p["ReportName"],
                    SectionName = (string)p["SectionName"]
                };
            }
        }

        public void SaveInboxSorting(int userId, string sortBy, string sortOrder)
		{
			AddPreference(userId, "InboxSortBy", sortBy);
			AddPreference(userId, "InboxSortOrder", sortOrder);
		}

		public string GetInboxSortBy(int userId)
		{
			return GetPreference(userId, "InboxSortBy");
		}

		public string GetInboxSortOrder(int userId)
		{
			return GetPreference(userId, "InboxSortOrder");
		}

        public string GetUserName(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetUserName"))
            {
                cmd.Add("@ID", userId);
                cmd.Add("@UserName", SqlDbType.VarChar, ParameterDirection.Output, 100);
                cmd.ExecuteNonQueryWithOutput();

                return Convert.ToString(cmd["@UserName"]);
            }
        }

        public bool HasOldOverdueTasks(int userId)
        {
            using (var cmd = new CmdObj("QCheck_HasOldOverdue"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@HasOldOverdue", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                return Convert.ToBoolean(cmd["@HasOldOverdue"]);
            }
        }

        public string GetPrintBackgroundColor(int userId)//added by Venkat Kanakamedala
        {
            using (var cmd = new CmdObj("QCheck_GetPrintBackGroundColor"))
            {
                cmd.Add("@canPrintUserID", userId);
                cmd.Add("@BackgroundColor", SqlDbType.VarChar, ParameterDirection.Output, 100);
                cmd.ExecuteNonQueryWithOutput();

                return Convert.ToString(cmd["@BackgroundColor"]);
            }
        }
        public bool IsPrintButtonVisible(int userId)//added by Venkat Kanakamedala
        {
            using (var cmd = new CmdObj("QCheck_IsPrintButtonVisible"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@IsPrintButtonVisible", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                return Convert.ToBoolean(cmd["@IsPrintButtonVisible"]);
            }
        }
    }

    [Serializable]
    public class User : IUser
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; }
		public string FullName { get; set; }
		public string ShortName { get; set; }
		public string Email { get; set; }
		public string Password { get; set; }
		public int GroupId { get; set; }
        public string AppUrl { get; set; }
        public bool IsBetaUser { get; set; }
        public bool IsApiAdmin { get; set; }    
        public bool IsAdmin { get; set; }
        public bool IsDepartmentAdmin { get; set; }
        public bool IsGradingAdmin { get; set; }
		public bool IsOverdueAdmin { get; set; }
		public bool IsDeleted { get; set; }
		public bool IsSupervisor { get; set; }
	    public int SupervisorStatus { get; set; }
		public bool UsesPriorities { get; set; }
		public bool ShowComments { get; set; }
		public int Font { get; set; }
		public int SupervisorId { get; set; }
        public string SupervisorName { get; set; }
        public int[] AllSupervisors { get; set; }
        public int? EmpId { get; set; }
        public UserTimeZone MyTimeZone { get; set; }
    }

    [Serializable]
	public class UserGroup : IUserGroup
	{
		public int Id { get; set; }
		public string GroupName { get; set; }
		public string Owner { get; set; }
        public bool IsMember { get; set; }
		public bool IsOwner { get; set; }
	}

    [Serializable]
	public class Preferences : IPreferences
	{
		public int Assignee { get; set; }
		public int Controller { get; set; }
		public int Due { get; set; }
		public int ReportOrig { get; set; }
		public int Priority { get; set; }
		public int Alert { get; set; }
		public int SoftDue { get; set; }
		public int EChecklistPriority { get; set; }
        public bool WeeklySummaryEmail { get; set; }
        public string AssigneeName { get; set; }
        public string ControllerName { get; set; }
        public string ReportName { get; set; }
        public string SectionName { get; set; }

    }

}
/* Copyright © 2024 Renegade Swish, LLC */