using QProcess.Domain.Models;
using QProcess.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using static DataService;

namespace QProcess.Repositories
{
    public class PrioritiesRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        public string PriorityRedirect(int userId, int reportUserId, int taskId = -1)
        {
            using (var cmd = new CmdObj("PriorityListSet_Redirect"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportUserID", reportUserId);
                if (taskId > 0)
                    cmd.Add("@TaskID", taskId);
                var priorities = cmd.GetDS();

                var reportId = Convert.ToInt32(priorities.Tables[0].Rows[0]["ReportID"]);
                var controller = Convert.ToBoolean(priorities.Tables[0].Rows[0]["Controller"]);

                if (reportId == 0)
                    return "Not Accessible";
                string url;
                if (controller)
                    url = "MyStatus.aspx?reportId=" + reportId;
                else
                    url = "MyInbox.aspx?reportId=" + reportId;
                if (taskId > 0)
                    url += "&taskId=" + taskId;
                return url;
            }
        }

        public IEnumerable<PrioritySetList> GetPrioritySetLists(int setId)
        {
            using (var cmd = new CmdObj("PriorityListSet_GetUsers"))
            {
                cmd.Add("@SetID", setId);
                var users = cmd.GetDS();
                return users.Tables[0].AsEnumerable().Select(u => new PrioritySetList
                {
                    UserId = Convert.ToInt32(u["userid"]),
                    ListId = Convert.ToInt32(u["listid"]),
                    FullName = Convert.ToString(u["fullname"]),
                    ListName = Convert.ToString(u["listname"]),
                    DisplayOrder = Convert.ToInt32(u["displayorder"]),
                    Email = Convert.ToString(u["email"])
                });
            }
        }

        public IEnumerable<NamedPriorityEntity> GetPrioritySets(int userId, int isPerson = -1)
        {
            using (var cmd = new CmdObj("PriorityList_GetSets"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@IsPerson", isPerson);
                var groups = cmd.GetDS();
                return groups.Tables[0].AsEnumerable().Select(g => new NamedPriorityEntity
                {
                    Id = Convert.ToInt32(g["ID"]),
                    Name = Convert.ToString(g["Name"]),
                    LastPrioritySet = Convert.ToInt32(g["LastPrioritySet"])
                });
            }
        }

        public IEnumerable<PriorityComment> GetPriorityComments(int setId, int userId, DateTime? startTime = null, bool everyone = false)
        {
            //user working in their local time, comment timestamps are UTC
            //Default value = midnight user-local in UTC (e.g. midnight CST => 6 AM UTC)
            startTime = (startTime.HasValue && startTime.Value.Date > DateTime.Parse("1/1/1900"))
                    ? myTz.GetSystemTime(startTime.Value)
                    : myTz.GetSystemTime(myTz.GetLocalTimeNow().Date);

            using (var cmd = new CmdObj("PriorityListSet_GetComments_UTC"))
            {
                cmd.Add("@SetID", setId);
                cmd.Add("@UserID", userId);
                cmd.Add("@StartTime", startTime);
                cmd.Add("@AllUsers", everyone ? 1 : 0);
                var comments = cmd.GetDS();
                return comments.Tables[0].AsEnumerable().Select(c => new PriorityComment
                {
                    Id = Convert.ToInt32(c["id"]),
                    UserId = Convert.ToInt32(c["userid"]),
                    ListId = Convert.ToInt32(c["listid"]),
                    ActiveChecklistId = Convert.ToInt32(c["activechecklistid"]),
                    Comment = Convert.ToString(c["comments"]),
                    IsHidden = Convert.ToBoolean(c["IsHidden"]),
                    TabIn = Convert.ToInt32(c["TabIn"]),
                    CommentId = Convert.ToInt32(c["CommentId"]),
                    CommentUserId = Convert.ToInt32(c["CommentUserId"]),
                    CommentDate = (DateTime)c["CommentDt"],
                    Color = Convert.ToInt32(c["ColorNum"])
                });
            }
        }

        public IEnumerable<PriorityEmail> GetPrioritySetEmailAddresses(int setId, int userId)
        {
            using (var cmd = new CmdObj("PriorityListSet_GetEmails"))
            {
                cmd.Add("@SetID", setId);
                cmd.Add("@UserID", userId);
                var emails = cmd.GetDS();
                return emails.Tables[0].AsEnumerable().Select(e => new PriorityEmail
                {
                    FullName = Convert.ToString(e["fullname"]),
                    Email = Convert.ToString(e["email"]),
                    LoggedInUser = Convert.ToBoolean(e["LoggedInUser"])
                });
            }
        }

        public IEnumerable<PriorityEmail> GetPriorityAllUserEmails()
        {
            using (var cmd = new CmdObj("QCheck_GetGroups"))
            {
                var emails = cmd.GetDS();
                return emails.Tables[0].AsEnumerable().Select(e => new PriorityEmail
                {
                    FullName = Convert.ToString(e["fullname"]),
                    Email = Convert.ToString(e["email"])
                });
            }
        }

        public PriorityInfo GetPriorityInfo(int setId, int userId, string userName, string sessionId, bool persistPrioritySet = true)
        {
            using (var cmd = new CmdObj("PriorityListSet_GetInfo"))
            {
                cmd.Add("@setId", setId);
                cmd.Add("@userId", userId);
                cmd.Add("@persistPrioritySet", persistPrioritySet);
                var data = cmd.GetDS();

                var depArray = Convert.ToString(data.Tables[1].Rows[0]["Dependencies"])
                    .Split(new[] { "*" }, StringSplitOptions.RemoveEmptyEntries);
                return new PriorityInfo
                {
                    Created = myTz.GetLocalTimeNow(),
                    LastChecked = myTz.GetLocalTimeNow(),
                    Changed = false,
                    LockedByUserId = userId,
                    LockedByUserName = userName,
                    SetId = setId,
                    SessionId = sessionId,
                    OwnerName = Convert.ToString(data.Tables[0].Rows[0]["fullname"]),
                    OwnerId = Convert.ToInt32(data.Tables[0].Rows[0]["userID"]),
                    OwnerEmail = Convert.ToString(data.Tables[0].Rows[0]["email"]),
                    LabelName = Convert.ToString(data.Tables[0].Rows[0]["name"]),
                    IsSingleUserList = Convert.ToBoolean(data.Tables[1].Rows[0]["IsSingleUserList"]),
                    IsDefaultList = Convert.ToBoolean(data.Tables[1].Rows[0]["IsDefaultList"]),
                    IsSupervisor = Convert.ToBoolean(data.Tables[1].Rows[0]["IsSupervisor"]),
                    IsMyList = Convert.ToBoolean(data.Tables[1].Rows[0]["IsMyList"]),
                    Dependencies = depArray.Select(x => Convert.ToInt32(x)).ToList(),
                    Users = GetPrioritySetLists(setId).ToList()
                };
            }
        }

        public IEnumerable<PriorityLine> GetPriorityList(int listId, List<PriorityComment> comments)
        {
            using (var cmd = new CmdObj("PriorityList_Get"))
            {
                cmd.Add("@ListID", listId);
                var priorities = cmd.GetDS();
                return priorities.Tables[0].AsEnumerable().Select(p => new PriorityLine
                {
                    Id = Convert.ToInt32(p["ID"]),
                    Priority = Convert.ToInt32(p["Priority"]),
                    ActiveChecklistId = Convert.ToInt32(p["ActiveChecklistID"]),
                    Name = Convert.ToString(p["Name"]),
                    DueDate = myTz.GetLocalTime(Convert.ToDateTime(p["due"])),
                    UserId = Convert.ToInt32(p["UserId"]),
                    ListId = Convert.ToInt32(p["ListId"]),
                    DueTime = myTz.GetLocalTime(Convert.ToDateTime(p["duetime"])),
                    Comments = comments.Where(c => c.Id == Convert.ToInt32(p["ID"])).ToList()
                });
            }
        }

        public IEnumerable<PriorityLine> GetPriorityList(int listId)
        {
            using (var cmd = new CmdObj("PriorityList_Get"))
            {
                cmd.Add("@ListID", listId);
                var priorities = cmd.GetDS();
                return priorities.Tables[0].AsEnumerable().Select(p => new PriorityLine
                {
                    Id = Convert.ToInt32(p["ID"]),
                    Priority = Convert.ToInt32(p["Priority"]),
                    ActiveChecklistId = Convert.ToInt32(p["ActiveChecklistID"]),
                    Name = Convert.ToString(p["Name"]),
                    DueDate = myTz.GetLocalTime(Convert.ToDateTime(p["due"])),
                    UserId = Convert.ToInt32(p["UserId"]),
                    DueTime = myTz.GetLocalTime(Convert.ToDateTime(p["duetime"]))
                });
            }
        }

        public IEnumerable<PriorityList> GetPriorityListSet(int userId, int setId, bool showComments, DateTime? commentsSince = null, bool everyone = false)
        {
            var priorityLists = new List<PriorityList>();
            var comments = GetPriorityComments(setId, userId, commentsSince, everyone).ToList();
            var set = GetPrioritySets(userId).Where(g => g.Id == setId).ToList().FirstOrDefault();
            var setLists = new List<PrioritySetList>();
            if (set != null)
            {
                setLists.AddRange(GetPrioritySetLists(set.Id));
                priorityLists.AddRange(
                    setLists.Select(setList =>
                        new PriorityList(set,
                            GetPriorityList(setList.ListId, 
                                    comments.Where(c => c.ListId == setList.ListId).ToList())
                                .ToList(),
                                setList)));
            }
            return priorityLists;
        }

        public void AddPriorityListUsers(int setId, string listIds)
        {
            using (var cmd = new CmdObj("PriorityListSet_AddUsers"))
            {
                cmd.Add("@SetID", setId);
                cmd.Add("@ListIDs", listIds);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public int AddPriorityList(int userId, string name)
        {
            using (var cmd = new CmdObj("PriorityListSet_Add"))
            {
                cmd.Add("@UserID", SqlDbType.Int, userId, ParameterDirection.Input, 4);
                cmd.Add("@Name", SqlDbType.VarChar, name, ParameterDirection.Input, 100);
                cmd.Add("@SetID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@SetID"]);
            }
        }

        public void AddPriorityTasks(int listId, string activeChecklistIds)
        {
            using (var cmd = new CmdObj("PriorityList_AddTasks"))
            {
                cmd.Add("@ListID", listId);
                cmd.Add("@ActiveChecklistIDs", activeChecklistIds);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void AddUpcomingTasks(int userId, int listId, int days)
        {
            using (var cmd = new CmdObj("PriorityList_AddDefault"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ListID", listId);
                cmd.Add("@Days", days);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ClearPriorities(int listId)
        {
            using (var cmd = new CmdObj("PriorityList_Clear"))
            {
                cmd.Add("@ListID", listId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public int CreatePriorityList(int userId, string name)
        {
            using (var cmd = new CmdObj("PriorityList_CreateUpdate"))
            {
                cmd.Add("@UserID", SqlDbType.Int, userId, ParameterDirection.Input, 4);
                cmd.Add("@Name", SqlDbType.VarChar, name, ParameterDirection.Input, 100);
                cmd.Add("@IsDefaultList", SqlDbType.Bit, false, ParameterDirection.Input, 1);
                var result = cmd.GetDS();
                return Convert.ToInt32(result.Tables[0].Rows[0]["ListID"]);
            }
        }

        public void SetDefaultPriorityList(int userId, int setId)
        {
            using (var cmd = new CmdObj("PriorityList_SetDefault"))
            {
                cmd.Add("@SetID", SqlDbType.Int, setId, ParameterDirection.Input, 4);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeletePriorityList(int setId)
        {
            using (var cmd = new CmdObj("PriorityListSet_Delete"))
            {
                cmd.Add("@SetID", setId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public IEnumerable<PriorityTask> GetAvailableTasks(int targetUserId, int targetListId, int fromUserId, string sort = "")
        {
            using (var cmd = new CmdObj("PriorityList_GetAvailableTasks"))
            {
                cmd.Add("@UserID", targetUserId);
                cmd.Add("@ListID", targetListId);
                cmd.Add("@SourceUserID", fromUserId);
                var tasks = cmd.GetDS();

                if (sort == "name") // Ignores duetime as that is the default sorting
                    tasks.Tables[0].DefaultView.Sort = "name";
                var sortedTasks = tasks.Tables[0].DefaultView.ToTable();
                return sortedTasks.AsEnumerable().Select(t => new PriorityTask
                {
                    ActiveChecklistId = Convert.ToInt32(t["activechecklistid"]),
                    Name = Convert.ToString(t["name"]),
                    DueDate = myTz.GetLocalTime(Convert.ToDateTime(t["duetime"])),
                    DueTime = myTz.GetLocalTime(Convert.ToDateTime(t["Column1"]))
                });
            }
        }

        public void ExcludeTasks(int userId, int forUserId, string activeChecklistIDs)
        {
            using (var cmd = new CmdObj("PriorityList_ExcludeTasks"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ForUserID", forUserId);
                cmd.Add("@ActiveChecklistIDs", activeChecklistIDs);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void MovePriorityTask(int taskId, int priority)
        {
            using (var cmd = new CmdObj("PriorityList_MoveTask"))
            {
                cmd.Add("@ID", taskId);
                cmd.Add("@Priority", priority);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemovePriorityTask(int taskId)
        {
            using (var cmd = new CmdObj("PriorityList_RemoveTask"))
            {
                cmd.Add("@ID", taskId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void SaveEntirePriorityOrder(List<TaskOrder> order)
        {
            var taskOrderCsv = string.Join(",", order.Select(o => $"{o.TaskId}|{o.DisplayOrder}"));

            using (var cmd = new CmdObj("PriorityList_SaveEntirePriorityOrder"))
            {
                cmd.Add("@TaskOrderCsv", taskOrderCsv);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void MovePriorityUser(int setId, int listId, int displayOrder)
        {
            using (var cmd = new CmdObj("PriorityListSet_MoveUser"))
            {
                cmd.Add("@SetID", setId);
                cmd.Add("@ListID", listId);
                cmd.Add("@DisplayOrder", displayOrder);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemovePriorityUser(int setId, int listId)
        {
            using (var cmd = new CmdObj("PriorityListSet_RemoveUser"))
            {
                cmd.Add("@SetID", setId);
                cmd.Add("@ListID", listId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public int GetPersonalSetID(int userId)
        {
            int setId = -1;
            using (var cmd = new CmdObj("PriorityListSet_GetPersonalByUser"))
            {
                cmd.Add("@UserID", userId);
                var ds = cmd.GetDS();
                if (ds.Tables.Count > 0)
                {
                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        setId = int.Parse(ds.Tables[0].Rows[0]["ID"].ToString());
                    }
                }
            }
            return setId;
        }
        public NewCommentReturn CreateNewPriorityComment(int taskId, int userId, string comments, bool isNew = false)
        {
            using (var cmd = new CmdObj("QStatus_CreateNewPriorityComment"))
            {
                cmd.Add("@TaskID", taskId);
                cmd.Add("@UserID", userId);
                cmd.Add("@Comments", ParseComment(comments));
                cmd.Add("@StartTime", myTz.GetSystemTime(myTz.GetLocalTimeNow().Date));
                cmd.Add("@IsNew", isNew ? 1 : 0);

                // Add output parameters
                cmd.Add("@NewID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@CommentsInitials", SqlDbType.VarChar, ParameterDirection.Output, 100);
                cmd.Add("@FullName", SqlDbType.VarChar, ParameterDirection.Output, 50);

                cmd.ExecuteNonQueryWithOutput();

                return new NewCommentReturn
                {
                    Id = Convert.ToInt32(cmd["@NewID"]),
                    Initials = Convert.ToString(cmd["@CommentsInitials"]),
                    FullName = Convert.ToString(cmd["@FullName"]),
                    Indentaion = 0
                };
            }
        }

        private string ParseComment(string s)
        {
            s = s.Replace("\n", "<br>");
            s = ParseLinks(s);
            return s;
        }

        private string ParseLinks(string t)
        {
            string keepEnd;
            string keepStart;
            string linkPart;

            while (t.Contains("[link]") && t.Contains("[/link]"))
            {
                keepEnd = t.Substring(t.IndexOf("[/link]") + 7);
                keepStart = t.Substring(0, t.IndexOf("[link]"));
                linkPart = t.Substring(t.IndexOf("[link]") + 6, (t.IndexOf("[/link]") - (t.IndexOf("[link]") + 6)));
                t = keepStart + "<!--a1--><a href='" + linkPart + "' target='_new' onclick='event.cancelBubble=true;'><!--/a1-->" + linkPart + "<!--a2--></a><!--/a2-->" + keepEnd;
            }

            return t;
        }
    }

    [Serializable]
    public class NamedPriorityEntity : NamedEntity
    {
        public int LastPrioritySet { get; set; }
    }

    [Serializable]
    public class PrioritySetList
    {
        public int UserId { get; set; }
        public int ListId { get; set; }
        public string FullName { get; set; }
        public string ListName { get; set; }
        public string DisplayName { get { return FullName == ListName ? ListName : $"{ListName} ({FullName})"; } set { } }
        public int DisplayOrder { get; set; }
        public string Email { get; set; }
        public bool UserHasComments { get; set; }
        public bool UserChanged { get; set; }
    }

    [Serializable]
    public class PriorityComment
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ListId { get; set; }
        public int ActiveChecklistId { get; set; }
        public string Comment { get; set; }
        public string FullName { get; set; }
        public string Initials { get; set; }
        public bool IsHidden { get; set; }
        public int TabIn { get; set; }
        public int CommentId { get; set; }
        public int CommentUserId { get; set; }
        public int Color { get; set; }
        public DateTime CommentDate { get; set; }

    }

    [Serializable]
    public class PriorityEmail
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public bool LoggedInUser { get; set; }
    }

    [Serializable]
    public class PriorityInfo
    {
        public DateTime Created { get; set; }
        public DateTime LastChecked { get; set; }
        public bool Changed { get; set; }
        public int LockedByUserId { get; set; }
        public string LockedByUserName { get; set; }
        public string OwnerName { get; set; }
        public int OwnerId { get; set; }
        public string OwnerEmail { get; set; }
        public int SetId { get; set; }
        public string SessionId { get; set; }
        public string LabelName { get; set; }
        public bool IsSingleUserList { get; set; }
        public bool IsDefaultList { get; set; }
        public bool IsSupervisor { get; set; }
        public bool IsMyList { get; set; }
        public List<int> Dependencies { get; set; }
        public List<PriorityList> PriorityLists { get; set; }
        public List<PrioritySetList> Users { get; set; }
    }

    [Serializable]
    public class PriorityLine
    {
        public PriorityLine()
        {
            Comments = new List<PriorityComment>();
        }
        public int Id { get; set; }
        public int Priority { get; set; }
        public int ActiveChecklistId { get; set; }
        public string Name { get; set; }
        public DateTime DueDate { get; set; }
        public int UserId { get; set; }
        public int ListId { get; set; }
        public DateTime DueTime { get; set; }
        public List<PriorityComment> Comments { get; set; }
    }

    [Serializable]
    public class PriorityList
    {
        public PriorityList()
        {
            PriorityLines = new List<PriorityLine>();
        }
        public PriorityList(NamedPriorityEntity set, IEnumerable<PriorityLine> lines, PrioritySetList setList)
        {
            PrioritySet = set;
            PriorityLines = new List<PriorityLine>(lines);
            PrioritySetList = setList;
        }
        public NamedPriorityEntity PrioritySet { get; set; }
        public List<PriorityLine> PriorityLines { get; set; }
        public PrioritySetList PrioritySetList { get; set; }
    }

    [Serializable]
    public class PriorityTask
    {
        public int ActiveChecklistId { get; set; }
        public string Name { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime DueTime { get; set; }
    }

    [Serializable]
    public class PriorityMessage
    {
        public int FromUserId { get; set; }
        public string FromUserName { get; set; }
        public string Message { get; set; }
        public int MessageTo { get; set; }
        public bool Locked { get; set; }
        public int LockedByUserId { get; set; }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

