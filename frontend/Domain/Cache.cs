using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Web;
using QProcess.Configuration;
using QProcess.Enums;
using QProcess.Extensions;
using QProcess.Repositories;
using static ReportLine;

namespace QProcess
{
    public class Cache
    {
        public static Cache CurrentCache { get { return new Cache(HttpContext.Current.Cache); } }
        private readonly System.Web.Caching.Cache _cache;
        private Dictionary<int, List<int>> _userReportList { get { return (Dictionary<int, List<int>>)_cache[USER_REPORT_LIST]; } }
        private Dictionary<int, List<int>> _reportUserList { get { return (Dictionary<int, List<int>>)_cache[REPORT_USER_LIST]; } }
        private const string USER_REPORT_LIST = "UserReportsList";
        private const string REPORT_USER_LIST = "ReportUsersList";
        
        public Cache(System.Web.Caching.Cache cache)
        {
            _cache = cache;
            if (_cache[USER_REPORT_LIST] == null)
            {
                // Create a dictionary for looking up all stored reports for a user based on userId
                _cache[USER_REPORT_LIST] = new Dictionary<int, List<int>>();
            }

            if (_cache[REPORT_USER_LIST] == null)
            {
                // Create a dictionary for looking up all reports associated with a user based on reportId
                _cache[REPORT_USER_LIST] = new Dictionary<int, List<int>>();
            }
        }

        public object this[int index]
        {
            get { return _cache[index.ToString(CultureInfo.InvariantCulture)]; }
        }

        public bool IsPrioritySetLocked(int setId)
        {
            return _cache[setId.ToString(CultureInfo.InvariantCulture)] != null;
        }

        public void LockPrioritySet(int setId, PriorityInfo setLockInfo, Session session)
        {
            int UserId;
            bool ShowComments;
            bool AllUsers = true;
            List<PriorityList> PriorityLists;
            PriorityInfo dependencySetLockInfo;
            PrioritiesRepository prioritiesRepo = new PrioritiesRepository();
            foreach (var dependency in setLockInfo.Dependencies.Where(dependency => !IsPrioritySetLocked(dependency)))
            {
                UserId = session.QUser.Id;
                ShowComments = session.QUser.ShowComments;
                dependencySetLockInfo = prioritiesRepo.GetPriorityInfo(dependency, session.QUser.Id, session.QUser.FullName, session.SessionId);
                if (dependencySetLockInfo.IsSingleUserList)
                {
                    PriorityLists = prioritiesRepo.GetPriorityListSet(UserId, dependency, ShowComments, null, AllUsers).ToList();
                    dependencySetLockInfo.PriorityLists = PriorityLists;
                    dependencySetLockInfo.LockedByUserId = UserId;
                    dependencySetLockInfo.LockedByUserName = session.QUser.FullName;
                    _cache.Insert(dependency.ToString(CultureInfo.InvariantCulture), dependencySetLockInfo, null, DateTime.UtcNow.AddMinutes(10), System.Web.Caching.Cache.NoSlidingExpiration);
                }
            }
            _cache.Insert(setId.ToString(CultureInfo.InvariantCulture), setLockInfo, null, DateTime.UtcNow.AddHours(1), System.Web.Caching.Cache.NoSlidingExpiration);
        }

        public void UnlockPrioritySet(int setId)
        {
            if (IsPrioritySetLocked(setId))
            {
                var info = (PriorityInfo)_cache[setId.ToString(CultureInfo.InvariantCulture)];
                foreach (var dependency in from dependency in info.Dependencies
                                           where IsPrioritySetLocked(dependency)
                                           let dep = (PriorityInfo)_cache[dependency.ToString(CultureInfo.InvariantCulture)]
                                           where dep.LockedByUserId == info.LockedByUserId
                                           select dependency)
                {
                    _cache.Remove(dependency.ToString(CultureInfo.InvariantCulture));
                }
                _cache.Remove(setId.ToString(CultureInfo.InvariantCulture));
            }

        }

        public void SendMessage(int messageTo, object message)
        {
            _cache.Insert("MessageTo" + messageTo.ToString(CultureInfo.InvariantCulture),
                          message, null, DateTime.UtcNow.AddHours(1), System.Web.Caching.Cache.NoSlidingExpiration);
        }

        public PriorityMessage GetMessagesByUserId(int userId)
        {
            return (PriorityMessage)_cache["MessageTo" + userId.ToString(CultureInfo.InvariantCulture)];
        }

        public void CacheReport(int userId, int reportId, StatusReport report)
        {
            // check to see if the user is stored in the users list
            if (_userReportList.ContainsKey(userId))
            {
                // if we haven't looked at this report yet then clear out all other cached reports otherwise move forward
                if (!_userReportList[userId].Contains(reportId))
                {
                    RemoveAllReportsForUser(userId);
                    _userReportList[userId] = new List<int> { reportId };
                }
            }
            else
            {
                // user hasn't been stored, so insert new list with reportId
                _userReportList[userId] = new List<int> { reportId };
            }

            // check to see if the report has been cached before
            if (_reportUserList.ContainsKey(reportId))
            {
                // if the user hasn't looked at the report then add him to the list
                if (!_reportUserList[reportId].Contains(userId))
                    _reportUserList[reportId].Add(userId);
            }
            else
            {
                // report hasn't been stored, insert new list with userId
                _reportUserList[reportId] = new List<int> { userId };
            }
            var key = "Report_" + userId + "_" + reportId;
            _cache.Insert(key, report, null, System.Web.Caching.Cache.NoAbsoluteExpiration,
                      TimeSpan.FromMinutes(Convert.ToDouble(AppSettings.Get("CacheTimeout"))));
        }

        private void RemoveAllReportsForUser(int userId)
        {
            foreach (var reportId in _userReportList[userId])
            {
                var key = "Report_" + userId + "_" + reportId;
                _cache.Remove(key);
            }
        }

        public bool IsReportCacheable(int reportId)
        {
            if (!String.IsNullOrEmpty(AppSettings.NoCacheReports))
            {
                var noCacheReports = AppSettings.NoCacheReports.Split(new[] { ',' });
                return noCacheReports.All(report => report != reportId.ToString());
            }
            return true;
        }

        public void RefreshCachedStatusReportByReportId(Object stateInfo)
        {
            var reportId = (int)stateInfo;
            RefreshCachedStatusReport(reportId);
        }

        public void RefreshCachedStatusReportsByChecklistId(Object stateInfo)
        {
            var checklistId = (int)stateInfo;
            using (var cmd = new CmdObj("QCheck_GetChecklistTaskTypes"))
            {
                cmd.Add("@ChecklistId", checklistId);
                var reports = cmd.GetDS().Tables[0].AsEnumerable();
                RefreshCachedStatusReports(reports);
            }
        }

        public void RefreshCachedStatusReportsByTaskId(Object stateInfo)
        {
            var taskId = Math.Abs((int)stateInfo);
            using (var cmd = new CmdObj("QCheck_GetActiveChecklistTaskTypes"))
            {
                cmd.Add("@taskId", taskId);
                var reports = cmd.GetDS().Tables[0].AsEnumerable();
                RefreshCachedStatusReports(reports);
            }
        }

        public void RefreshCachedStatusReportBySectionId(Object stateInfo)
        {
            var sectionId = Math.Abs((int)stateInfo);
            using (var cmd = new CmdObj("QStatus2_GetReportIDBySectionID"))
            {
                cmd.Add("@SectionID", sectionId);
                var reportId = Convert.ToInt32(cmd.GetDS().Tables[0].AsEnumerable().First()["ReportID"]);
                RefreshCachedStatusReport(reportId);
            }
        }

        public void RefreshCachedStatusReportsByInstanceId(Object stateInfo)
        {
            var instanceId = (int)stateInfo;
            using (var cmd = new CmdObj("QCheck_GetInstanceTaskTypes"))
            {
                cmd.Add("@instanceId", instanceId);
                var reports = cmd.GetDS().Tables[0].AsEnumerable();
                RefreshCachedStatusReports(reports);
            }
        }

        private void RefreshCachedStatusReports(IEnumerable<DataRow> reports)
        {
            foreach (var report in reports)
            {
                var reportId = Convert.ToInt32(report["ReportID"]);
                RefreshCachedStatusReport(reportId);
            }
        }

        private void RefreshCachedStatusReport(int reportId)
        {
            if (_reportUserList.ContainsKey(reportId))
            {
                foreach (var userId in _reportUserList[reportId])
                {
                    var key = "Report_" + userId + "_" + reportId;
                    if (_cache[key] != null)
                    {
                        ((StatusReport)_cache[key]).ReportLines = GetReportFromDatabase(userId, reportId, false);
                    }
                }
            }
        }

        public StatusReport GetReport(int userId, int reportId, bool isArchive, DateTime? lastViewedFilter = null, string timeZones = "")
        {
            var key = "Report_" + userId + "_" + reportId;
            // See if the report is already in the cache
            if (_cache[key] != null && !ReportIsDirty(reportId) && timeZones == "")
            {
                // If it is in the cache and is the same type as before, either archive or not then return
                if (((StatusReport)_cache[key]).IsArchive == isArchive)
                    return (StatusReport)_cache[key];
            }
            // else pull data from the database and send it back
            var report = new StatusReport
            {
                ReportLines = GetReportFromDatabase(userId, reportId, isArchive, lastViewedFilter, timeZones),
                IsArchive = isArchive,
                LastViewedFilter = lastViewedFilter
            };
            CacheReport(userId, reportId, report);
            return (StatusReport)_cache[key];
        }

        public StatusReport GetReportSlim(
            int userId, int reportId, bool isArchive, DateTime? lastViewedFilter = null, string timeZones = "")
        {
            return new StatusReport
            {
                ReportLines = GetReportFromDatabaseSlim(userId, reportId, isArchive, lastViewedFilter, timeZones: timeZones),
                IsArchive = isArchive,
                LastViewedFilter = lastViewedFilter
            };
        }

        private IEnumerable<StatusReportLine> GetReportFromDatabase(
            int userId, int reportId, bool isArchive, DateTime? lastViewedFilter = null, string timeZones = "")
        {
            DataSet ds = isArchive 
                ? GetArchiveData(reportId, userId, timeZones:timeZones) 
                : GetReportData(userId, reportId, lastViewedFilter, timeZones: timeZones);

            int seed = Convert.ToInt32(ds.Tables[2].Rows[0][0]);
            DataSet commentDs = GetCommentData(seed, reportId, userId);

            var myTz = QProcess.Session.CurrentSession.UserTimeZone;

            var comments = commentDs.Tables[0].AsEnumerable().Select(r => new
            {
                TaskId = Convert.ToInt32(r["TaskID"]),
                DisplayOrder = Convert.ToInt32(r["DisplayOrder"]),
                Comment = new StatusReportLine.Comment
                {
                    Id = Convert.ToInt32(r["ID"]),
                    UserId = Convert.ToInt32(r["UserID"]),
                    Text = Convert.ToString(r["Comments"]),
                    Date = myTz.GetLocalTime(Convert.ToDateTime(r["CommentDt"])),
                    Initials = Convert.ToString(r["Initials"]),
                    FullName = Convert.ToString(r["FullName"]),
                    TabIn = Convert.ToInt32(r["TabIn"]),
                    Color = Convert.ToInt32(r["colornum"])
                }
            }).OrderBy(c => c.DisplayOrder)
                  .GroupBy(c => c.TaskId)
                  .ToDictionary(g => g.Key, g => g.Select(c => c.Comment).ToList());

            List<ItemDetails> itemDetails = GetTaskItemDetailsByStatusReportID(reportId);

            var lines = ds.Tables[0].AsEnumerable().Select(r =>
            {
                var line = new StatusReportLine();
                var lineTypeKey = Convert.ToString(r["Type"]);
                line.LineType = ReportLine.Type.All.ContainsKey(lineTypeKey)
                                    ? ReportLine.Type.All[lineTypeKey]
                                    : ReportLine.Type.Task;
                line.MyTaskType = line.LineType != ReportLine.Type.Task
                                      ? TaskType.None
                                      : (TaskType)Convert.ToInt32(r["NativeType"]);

                line.ID = r.GetConvertedNullableValue("ID", Convert.ToInt32);
                line.Description = Convert.ToString(r["Description"]);
                var dueDate = r.GetConvertedNullableValue("DueDate", Convert.ToDateTime);
                line.DueDate = dueDate != null ? myTz.GetLocalTime(dueDate.Value) : (DateTime?)null;
                var reminderDate = r.GetConvertedNullableValue("ReminderDate", Convert.ToDateTime);
                line.ReminderDate = reminderDate != null ? myTz.GetLocalTime(reminderDate.Value) : (DateTime?)null;
                var sortDate = r.GetConvertedNullableValue("SortDate", Convert.ToDateTime);
                line.SortDate = sortDate != null ? myTz.GetLocalTime(sortDate.Value) : (DateTime?)null; line.Priority = r.GetConvertedNullableValue("Priority", Convert.ToInt32);
                line.AssignedTo = Convert.ToString(r["AssignedTo"]);
                line.Controllers = Convert.ToString(r["Controllers"]);
                line.SectionID = Convert.ToString(r["TaskType"]);
                line.NativeType = RideTheLightning.GetConvertedNullableValue(r, "NativeType", Convert.ToInt32);

                var detailsForTask = itemDetails
                    .Where(x => x.Id == (line.ID ?? 0))
                    .Select(x => new TaskDetailItem
                    {
                        ItemName = x.ItemName,
                        ItemType = x.ItemType,
                        IsCompleted = x.IsCompleted
                    })
                    .ToList();

                line.TaskDetails = detailsForTask;

                line.HasRelatedComments = TaskHasRelatedComments(line.ID ?? 0, userId);
                var commentTaskId = r.GetConvertedNullableValue("Comments", Convert.ToInt32);
                if (commentTaskId.HasValue && comments.ContainsKey(commentTaskId.Value))
                    line.Comments = comments[commentTaskId.Value];
                line.IsDaily = (r["IsDaily"] == DBNull.Value) ? false : Convert.ToBoolean(r["IsDaily"]);
                line.IsRecurring = (r["IsRecurring"] == DBNull.Value) ? false : Convert.ToBoolean(r["IsRecurring"]);//added by Venkat for testing
                return line;
            }).ToList();

            return lines;
        }
        private IEnumerable<StatusReportLine> GetReportFromDatabaseSlim(
            int userId, int reportId, bool isArchive, DateTime? lastViewedFilter = null, string timeZones = "")
        {
            DataSet ds = isArchive 
                ? GetArchiveData(reportId, userId, timeZones: timeZones) 
                : GetReportData(userId, reportId, lastViewedFilter, timeZones: timeZones);

            int seed = Convert.ToInt32(ds.Tables[2].Rows[0][0]);
            DataSet commentDs = GetCommentData(seed, reportId, userId);

            var myTz = QProcess.Session.CurrentSession.UserTimeZone;

            var comments = commentDs.Tables[0].AsEnumerable().Select(r => new
            {
                TaskId = Convert.ToInt32(r["TaskID"]),
                DisplayOrder = Convert.ToInt32(r["DisplayOrder"]),
                Comment = new StatusReportLine.Comment
                {
                    Id = Convert.ToInt32(r["ID"]),
                    UserId = Convert.ToInt32(r["UserID"]),
                    Date = myTz.GetLocalTime(Convert.ToDateTime(r["CommentDt"])),
                    //The DB is auditing the comment reads anyway, might as well actually show the user the comment
                    Text = Convert.ToString(r["Comments"]),
                    Initials = Convert.ToString(r["Initials"]),
                    FullName = Convert.ToString(r["FullName"]),
                    TabIn = Convert.ToInt32(r["TabIn"]),
                    Color = Convert.ToInt32(r["colornum"])
                }
            }).OrderBy(c => c.DisplayOrder)
                  .GroupBy(c => c.TaskId)
                  .ToDictionary(g => g.Key, g => g.Select(c => c.Comment).ToList());

            List<ItemDetails> itemDetails = GetTaskItemDetailsByStatusReportID(reportId);

            var lines = ds.Tables[0].AsEnumerable().Select(r =>
            {
                var line = new StatusReportLine();
                var lineTypeKey = Convert.ToString(r["Type"]);
                line.LineType = ReportLine.Type.All.ContainsKey(lineTypeKey)
                                    ? ReportLine.Type.All[lineTypeKey]
                                    : ReportLine.Type.Task;
                line.MyTaskType = line.LineType != ReportLine.Type.Task
                                      ? TaskType.None
                                      : (TaskType)Convert.ToInt32(r["NativeType"]);

                line.ID = r.GetConvertedNullableValue("ID", Convert.ToInt32);
                line.Description = Convert.ToString(r["Description"]);
                var dueDate = r.GetConvertedNullableValue("DueDate", Convert.ToDateTime);
                line.DueDate = dueDate != null ? myTz.GetLocalTime(dueDate.Value) : (DateTime?)null;
                var reminderDate = r.GetConvertedNullableValue("ReminderDate", Convert.ToDateTime);
                line.ReminderDate = reminderDate != null ? myTz.GetLocalTime(reminderDate.Value) : (DateTime?)null;
                var sortDate = r.GetConvertedNullableValue("SortDate", Convert.ToDateTime);
                line.SortDate = sortDate != null? myTz.GetLocalTime(sortDate.Value) : (DateTime?)null;
                line.Priority = r.GetConvertedNullableValue("Priority", Convert.ToInt32);
                line.AssignedTo = Convert.ToString(r["AssignedTo"]);
                line.Controllers = Convert.ToString(r["Controllers"]);
                line.SectionID = Convert.ToString(r["TaskType"]);
                line.NativeType = RideTheLightning.GetConvertedNullableValue(r, "NativeType", Convert.ToInt32);

                var detailsForTask = itemDetails
                    .Where(x => x.Id == (line.ID ?? 0))
                    .Select(x => new TaskDetailItem
                    {
                        ItemName = x.ItemName,
                        ItemType = x.ItemType,
                        IsCompleted = x.IsCompleted
                    })
                    .ToList();

                line.TaskDetails = detailsForTask;

                line.HasRelatedComments = TaskHasRelatedComments(line.ID ?? 0, userId);
                var commentTaskId = r.GetConvertedNullableValue("Comments", Convert.ToInt32);
                if (commentTaskId.HasValue && comments.ContainsKey(commentTaskId.Value))
                    line.Comments = comments[commentTaskId.Value];
                line.IsDaily = (r["IsDaily"] == DBNull.Value) ? false : Convert.ToBoolean(r["IsDaily"]);
                line.IsRecurring = (r["IsRecurring"] == DBNull.Value) ? false : Convert.ToBoolean(r["IsRecurring"]);//added by Venkat for testing
                return line;
            }).ToList();

            return lines;
        }

        private List<ItemDetails> GetTaskItemDetailsByStatusReportID(int reportID)
        {
            using (var cmd = new CmdObj("QStatus_GetTaskItemDetailsByStatusReportID"))
            {
                var taskStatusResult = new List<ItemDetails>();
                cmd.Add("@ReportID", reportID);

                var ds = cmd.GetDS();
                if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    taskStatusResult.AddRange(
                        ds.Tables[0].AsEnumerable().Select(row => new ItemDetails
                        {
                            Id = row["ActiveChecklistID"] != DBNull.Value ? Convert.ToInt32(row["ActiveChecklistID"]) : 0,
                            ItemName = row["ItemName"] as string,
                            ItemType = row["ItemType"] as string,
                            CompletedBy = row["CompletedBy"] as string,
                            //Assignee = row["Assignees"] as string,
                            //Controller = row["Controllers"] as string,
                            IsCompleted = row["IsCompleted"] != DBNull.Value && Convert.ToBoolean(row["IsCompleted"])
                        })
                    );
                }
                return taskStatusResult;
            }
        }

        private bool TaskHasRelatedComments(int taskId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetRelatedComments"))
            {
                cmd.Add("@TaskId", taskId);
                cmd.Add("@UserId", userId);
                cmd.Add("@OnlyCount", true);

                return cmd.GetScalar().ToIntEx().Value > 0;
            }
        }

        private DataSet GetReportData(int userId, int reportId, DateTime? lastViewed, string timeZones = "")
        {
            try
            {

            using (var cmd = new CmdObj("QStatus_GetReport"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                if (lastViewed.HasValue)
                    cmd.Add("@deletedDate", lastViewed.Value);
                if (timeZones != null)
                    cmd.Add("@TimeZones", timeZones);
                return cmd.GetDS();
            }

            }
            catch (SqlException e) {
                var message = e.Message;
                return null;
            }
            catch(Exception e)
            {
                var message = e.Message;
                return null;
            }
        }

        private DataSet GetArchiveData(int reportId, int userId, string timeZones = "")
        {
            using (var cmd = new CmdObj("QStatus_GetArchive", 300))
            {
                cmd.Add("@ReportID", reportId);
                cmd.Add("@UserId", userId);
                if (timeZones != null)
                    cmd.Add("@TimeZones", timeZones);
                return cmd.GetDS();
            }
        }

        private DataSet GetCommentData(int seed, int reportId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetCommentsAll"))
            {
                cmd.Add("@Seed", seed);
                cmd.Add("@ReportID", reportId);
                cmd.Add("@UserId", userId);
                return cmd.GetDS();
            }
        }

        private bool ReportIsDirty(int reportId)
        {
            using (var cmd = new CmdObj("QStatus_NeedsRefresh_ResetDirty"))
            {
                cmd.Add("@ReportID", reportId);
                cmd.Add("@NeedsRefresh", SqlDbType.Bit, 0, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                if (cmd["@NeedsRefresh"] == null)
                    return false;

                return bool.Parse(cmd["@NeedsRefresh"].ToString());
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

