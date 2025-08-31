using System;
using System.Collections.Generic;
using QProcess.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using QProcess;
using QProcess.Enums;
using QProcess.Repositories;
using DataAccessLayer;
using QProcess.Extensions;
using QProcess.Models;
using System.Data;
using DotNetOpenAuth;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using ProtoBuf.WellKnownTypes;
using System.Web.Providers.Entities;
using System.Security.Authentication;
using QProcess.Domain.SYSTEM;
using TimeZoneConverter;
using static SimpleJwt;
using System.Diagnostics.Eventing.Reader;
using QProcess.Domain;
using DocumentFormat.OpenXml.Spreadsheet;
using System.Configuration;
using System.Text;
using System.Data.SqlClient;
using DocumentFormat.OpenXml.InkML;

[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[ScriptService]
public class DataService : WebService
{
    private Session CurrentSession => QProcess.Session.CurrentSession;
    private Cache CurrentCache => Cache.CurrentCache;

    private bool IsAuthenticated { 
        get
        {
            if (HttpContext.Current.Request.IsAuthenticated) return true;

            HttpContext.Current.Response.StatusCode = 401;
            HttpContext.Current.Response.StatusDescription = "Session Not Authenticated";
            return false;
        } 
    }

    [WebMethod(true)]
    public bool KeepAlive()
    {
        if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
        {
            HttpContext.Current.Session.Abandon();
            HttpContext.Current.ApplicationInstance.CompleteRequest();
            return false;
        }
        else
        {
            HttpContext.Current.Session["LastBeat"] = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
            return true;
        }
    }

    [WebMethod(EnableSession = true)]
    public void UpdateLastPage(string page)
    {
        if (!KeepAlive()) return;

        if (page.Contains(".aspx") && !page.Contains("PrintStatusPage"))
        {
            var userRepo = new UserRepository();
            userRepo.AddPreference(CurrentSession.QUser.Id, "StartPage", page);
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(UseHttpGet = false, ResponseFormat = ResponseFormat.Json)]
    public int AddChecklistItem(int checklistId, int changeId, int itemTypeId, string text, string url)
    {
        if (!IsAuthenticated) return -1;

        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            return checklistRepo.AddChecklistItem(checklistId, itemTypeId, text, url, CurrentSession.QUser.Id);
        }
        else
        {
            return checklistRepo.ApprovalAddChecklistItem(checklistId, changeId, itemTypeId, text, url, CurrentSession.QUser.Id);
        }
    }

    [WebMethod(EnableSession = true)]
    public void MoveChecklistItem(int fromId, int toId, int changeId)
    {
        if (HttpContext.Current.Request.IsAuthenticated == false) throw new AuthenticationException("Request Not Authenticated");

        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.MoveChecklistItem(fromId, toId);
        }
        else
        {
            checklistRepo.ApprovalMoveChecklistItem(fromId, toId, changeId);
        }
    }

    [WebMethod(EnableSession = true)]
    public void UpdateChecklistItem(int itemId, int checklistId, int changeId, int itemTypeId, string text, string url)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.UpdateChecklistItem(itemId, checklistId, itemTypeId, text, url, CurrentSession.QUser.Id);
        }
        else
        {
            checklistRepo.ApprovalUpdateChecklistItem(itemId, checklistId, changeId, itemTypeId, text, url, CurrentSession.QUser.Id);
        }
    }

    [WebMethod(EnableSession = true)]
    public void DeleteChecklistItem(int checklistId, int itemId, int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.DeleteChecklistItem(itemId, CurrentSession.QUser.Id);
        }
        else
        {
            checklistRepo.ApprovalDeleteChecklistItem(itemId, CurrentSession.QUser.Id);
        }
    }

    [WebMethod(EnableSession = true)]
    public ChecklistItemResponseModel[] SaveChecklistItems(ChecklistItemCompletionModel[] items)
    {
        List<ChecklistItemResponseModel> responses = new List<ChecklistItemResponseModel>();
        var repo = new ChecklistRepository();
        foreach (var item in items)
        {
            var response = new ChecklistItemResponseModel
            {
                ActiveChecklistItemId = item.ActiveChecklistItemId,
                ActiveChecklistId = item.ActiveChecklistId,
                IsCompleted = item.IsCompleted,
                Comments = item.Comments
            };
            string completedBy, completedOn;
            repo.SaveChecklistItem(CurrentSession.QUser.Id, item.ActiveChecklistId, item.ActiveChecklistItemId, item.IsCompleted, item.Comments, out completedBy, out completedOn);
            response.CompletedBy = completedBy;
            response.CompletedOn = completedOn;
            responses.Add(response);
        }
        return responses.ToArray();
    }
    public class ChecklistItemCompletionModel
    {
        public int ActiveChecklistId { get; set; }
        public int ActiveChecklistItemId { get; set; }
        public bool IsCompleted { get; set; }
        public string Comments { get; set; }
    }
    public class ChecklistItemResponseModel : ChecklistItemCompletionModel
    {
        public string CompletedBy { get; set; }
        public string CompletedOn { get; set; }
    }

    [WebMethod(EnableSession = true)]
    public ChecklistCompletionResponseModel CompleteChecklist(int uniqueId, bool na, string naReason)
    {
        var repo = new ChecklistRepository();
        int upcomingDueTimeID = -1;
        int newActiveChecklistID = -1;
        repo.CompleteChecklist(CurrentSession.QUser.Id, uniqueId, na, naReason, out upcomingDueTimeID, out newActiveChecklistID);
        var response = new ChecklistCompletionResponseModel
        {
            CompletedUniqueID = uniqueId,
            UpcomingDueTimeID = upcomingDueTimeID,
            NewActiveChecklistID = newActiveChecklistID
        };
        return response;
    }

    public class ChecklistCompletionResponseModel
    {
        public int CompletedUniqueID { get; set; }
        public int UpcomingDueTimeID { get; set; }
        public int NewActiveChecklistID { get; set; }
    }

    [WebMethod(EnableSession = true)]
    public void CreateSimpleChecklist(NewChecklistInitializer model)
    {
        var repo = new ChecklistRepository();
        repo.CreateNewChecklist(CurrentSession.QUser.Id, model, false);
    }

    [WebMethod(EnableSession = true)]
    public NewTaskReturnValue CreateCustomizableChecklist(NewChecklistInitializer model)
    {
        var repo = new ChecklistRepository();
        return repo.CreateNewChecklist(CurrentSession.QUser.Id, model, true);
    }

    [WebMethod(EnableSession = true)]
    public void ClearActiveForInstance(int instanceId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ClearActive(instanceId);
    }

    [WebMethod(EnableSession = true)]
    public void UpdatePriority(int instanceId, int priority)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.UpdatePriority(instanceId, priority);
    }

    [WebMethod(EnableSession = true)]
    public void FinalizeCustomizableChecklist(int checklistId, int instanceId, DateTime? firstReminderDate)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.FinalizeCustomizableChecklist(checklistId, instanceId, firstReminderDate);
    }

    [WebMethod(EnableSession = true)]
    public void TakeControlOfChecklist(int activeChecklistId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.TakeControlOfChecklist(activeChecklistId, CurrentSession.QUser.GroupId);
    }

    [WebMethod(EnableSession = true)]
    public ResultAndTimestamp<int> StartChecklist(int instanceId, int upcomingId)
    {
        var repo = new ChecklistRepository();
        return ResultAndTimestamp.Create(
                repo.StartChecklist(instanceId, upcomingId),
                QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()
            );
    }

    [WebMethod(EnableSession = true)]
    public int CreateChecklistInstance(int checklistId)
    {
        var checklistRepo = new ChecklistRepository();
        return checklistRepo.CreateChecklistInstance(checklistId, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteChecklistInstance(int instanceId, int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.DeleteChecklistInstance(instanceId);
        }
        else
        {
            checklistRepo.ApprovalDeleteChecklistInstance(instanceId, changeId);
        }
    }

    [WebMethod(EnableSession = true)]
    public int CopyChecklistInstance(int instanceId, int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            return checklistRepo.CopyChecklistInstance(instanceId);
        }
        else
        {
            checklistRepo.ApprovalCopyChecklistInstance(instanceId, changeId);
            return 0;
        }
    }

    [WebMethod(EnableSession = true)]
    public void ActivateChecklistInstance(int instanceId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ActivateChecklistInstance(instanceId);
    }

    public class ComplexChecklistCreationModel
    {
    }

    private string GetFilepath(string filename)
    {
        if (!filename.Contains(@"C:\fakepath\"))
            return filename;
        var cleanedFileName = filename.Split(new[] { @"C:\fakepath\" }, StringSplitOptions.RemoveEmptyEntries).Last();
        var baseAttachmentDir = AppSettings.Get("BaseAttachmentDir");
        var directoryInfo = new DirectoryInfo(baseAttachmentDir);
        var files = directoryInfo.GetFiles(cleanedFileName, SearchOption.AllDirectories);
        return files.Any() ? files.First().FullName : filename;
    }

    [WebMethod(EnableSession = true)]
    public NamedEntityGroup[] GetReportsForInstance(int instanceId)
    {
        var repo = new SelectListRepository();
        return repo.GetReportsForInstance(CurrentSession.QUser.Id, instanceId).ToArray();
    }

    [WebMethod(EnableSession = true)]
    public NamedEntity[] GetTaskTypesForReport(int reportId)
    {
        var repo = new SelectListRepository();
        return repo.GetTaskTypesForReport(reportId, CurrentSession.QUser.Id).ToArray();
    }

    [WebMethod(EnableSession = true)]
    public void ApproveChangeRequest(int changeRequestId)
    {
        var repo = new ChangeRequestRepository();
        var userId = CurrentSession.QUser.Id;
        repo.ApproveRequest(changeRequestId, userId);
    }

    [WebMethod(EnableSession = true)]
    public void ChangeGroupOwner(int groupId, int owner)
    {
        var repo = new UserRepository();
        var userId = CurrentSession.QUser.Id;
        repo.ChangeGroupOwner(groupId, owner, userId);
    }

    [WebMethod(EnableSession = true)]
    public void DenyChangeRequest(int changeRequestId)
    {
        var repo = new ChangeRequestRepository();
        var userId = CurrentSession.QUser.Id;
        repo.DenyRequest(changeRequestId, userId);
    }
    [WebMethod]

    public void ApproveItem(int changeRequestItemId)
    {
        var repo = new ChangeRequestRepository();
        repo.ApproveItem(changeRequestItemId);
    }

    [WebMethod]
    public void DenyItem(int changeRequestItemId)
    {
        var repo = new ChangeRequestRepository();
        repo.DenyItem(changeRequestItemId);
    }

    // My Status
    // Manage Reports
    // Add Report
    [WebMethod(EnableSession = true)]
    public int AddReport()
    {
        var repo = new StatusReportRepository();
        return repo.AddReport(CurrentSession.QUser.GroupId);
    }

    // Save Report
    [WebMethod(EnableSession = true)]
    public void SaveReport(int reportId, string name)
    {
        var repo = new StatusReportRepository();
        repo.SaveReport(reportId, name);
    }

    // DeleteReport
    [WebMethod(EnableSession = true)]
    public void DeleteReport(int reportId)
    {
        var repo = new StatusReportRepository();
        repo.DeleteReport(reportId);
    }

    [WebMethod(EnableSession = true)]
    public List<Report> GetMyReportsList()
    {
        var repo = new StatusReportRepository();
        return repo.GetMyReportsList(CurrentSession.QUser.Id, false);
    }

    [WebMethod(EnableSession = true)]
    public List<Report> GetMySupervisedReportsList()
    {
        var repo = new MyInboxRepository();
        return repo.GetMySupervisedReportsList(CurrentSession.QUser.Id, false);
    }

    [WebMethod(EnableSession = true)]
    public List<Report> GetMyInterestedPartyReportsList()
    {
        var repo = new MyInboxRepository();
        return repo.GetMyInterestedPartyReportsList(CurrentSession.QUser.Id, false);
    }

    [WebMethod(EnableSession = true)]
    public string GetReportName(int reportId)
    {
        var repo = new StatusReportRepository();
        return repo.GetReportName(reportId, CurrentSession.QUser.Id);
    }

    //Assignees
    [WebMethod(EnableSession = true)]
    public int AddAssignee(int instanceId, int changeId, int groupId)
    {
        var repo = new ChecklistRepository();
        if (changeId <= 0)
        {
            return repo.AddAssignee(instanceId, groupId, CurrentSession.QUser.Id);
        }
        else
        {
            return repo.ApprovalAddAssignee(instanceId, changeId, groupId, CurrentSession.QUser.Id);
            // return 0;
        }
    }

    [WebMethod(EnableSession = true)]
    public void DeleteAssignee(int id, int changeId, bool existing)
    {
        var repo = new ChecklistRepository();
        if (changeId <= 0)
        {
            repo.DeleteAssignee(id);
        }
        else
        {
            repo.ApprovalDeleteAssignee(id, changeId, existing);
        }
    }

    [WebMethod(EnableSession = true)]
    public int GetAssigneeCount(int instanceId, int changeId)
    {
        var repo = new ChecklistRepository();
        var count = repo.GetAssigneeCount(instanceId, changeId);
        return count;
    }

    // Controllers
    [WebMethod(EnableSession = true)]
    public void AddController(int groupId, int reportId)
    {
        var repo = new SupervisorRepository();
        repo.AddController(reportId, groupId);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteController(int id)
    {
        var repo = new SupervisorRepository();
        repo.DeleteController(id);
    }

    [WebMethod(EnableSession = true)]
    public List<Controller> GetControllersList(int reportId)
    {
        var repo = new SupervisorRepository();
        return repo.GetControllersList(reportId);
    }

    // Supervisors
    [WebMethod(EnableSession = true)]
    public void AddSupervisor(int reportId, int groupId)
    {
        var repo = new SupervisorRepository();
        repo.AddSupervisor(reportId, groupId);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteSupervisor(int id)
    {
        var repo = new SupervisorRepository();
        repo.DeleteSupervisor(id);
    }

    [WebMethod(EnableSession = true)]
    public bool IsPersonalReportByReportID(int reportId)
    {
        var repo = new SupervisorRepository();
        return repo.IsPersonalReportByReportID(reportId);
    }

    [WebMethod(EnableSession = true)]
    public void ToggleInterestedParty(int id)
    {
        var repo = new SupervisorRepository();
        repo.ToggleInterestedParty(id);
    }

    [WebMethod(EnableSession = true)]
    public List<Supervisor> GetSupervisorsList(int reportId)
    {
        var repo = new SupervisorRepository();
        return repo.GetSupervisorsList(reportId);
    }

    // Sections
    [WebMethod(EnableSession = true)]
    public int AddSection(int reportId)
    {
        var repo = new StatusReportRepository();
        return repo.AddSection(reportId);
    }

    [WebMethod(EnableSession = true)]
    public void EditSection(int sectionId, string name)
    {
        var repo = new StatusReportRepository();
        repo.EditSection(sectionId, name);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteSection(int id)
    {
        var repo = new StatusReportRepository();
        repo.RestoreDeleteSection(id);
    }

    [WebMethod(EnableSession = true)]
    public void RestoreSection(int id)
    {
        var repo = new StatusReportRepository();
        repo.RestoreDeleteSection(id);
    }

    [WebMethod(EnableSession = true)]
    public void MoveSection(int fromId, int toId)
    {
        var repo = new StatusReportRepository();
        repo.MoveSection(fromId, toId);
    }

    // Attorney Client
    [WebMethod(EnableSession = true)]
    public void SetAttorneyClient(int reportId, bool isConfidential)
    {
        var repo = new StatusReportRepository();
        repo.SetAttorneyClient(reportId, isConfidential);
    }

    [WebMethod(EnableSession = true)]
    public bool GetAttorneyClient(int reportId)
    {
        var repo = new StatusReportRepository();
        return repo.GetAttorneyClient(reportId);
    }

    [WebMethod(EnableSession = true)]
    public string GetControllerUserIDsByReportID(int reportId)
    {
        var repo = new StatusReportRepository();
        return repo.GetControllerUserIDsByReportID(reportId);
    }

    // Supervised Reports
    [WebMethod(EnableSession = true)]
    public List<ReportHeader> GetReportListSupervised(bool interestedParty)
    {
        var repo = new StatusReportRepository();
        return repo.GetReportListSupervised(CurrentSession.QUser.Id, interestedParty);
    }


    // Supervised Reports
    [WebMethod(EnableSession = true)]
    public List<ReportHeaderSupervised> GetReportListSupervisedAndIP(int userID)
    {
        var repo = new StatusReportRepository();
        return repo.GetReportListSupervisedAndIP(userID);
    }

    [WebMethod(EnableSession = true)]
    public int AddExistingTaskToSectionOutput(int taskInstanceId, int sectionId)
    {
        var repo = new StatusReportRepository();
        return repo.AddExistingTaskToSectionOutput(taskInstanceId, sectionId);
    }

    [WebMethod(EnableSession = true)]
    public int AddExistingTaskToSection(int taskInstanceId, int sectionId)
    {
        var repo = new StatusReportRepository();
        return repo.AddExistingTaskToSection(taskInstanceId, sectionId);
    }

    // Timeline
    [WebMethod(EnableSession = true)]
    public List<Timeline> GetReportTimeline(int reportId)
    {
        var repo = new StatusReportRepository();
        return repo.GetReportTimeline(reportId, CurrentSession.QUser.Id);
    }

    // Complete Task
    [WebMethod(EnableSession = true)]
    public string CompleteTask(int userId, int taskId, int reportId = 0, bool na = false, string naReason = "")
    {
        var statusReportRepo = new StatusReportRepository();
        var checklistRepo = new ChecklistRepository();
        int upcomingDueTimeID;
        int newActiveChecklistID;
        bool isComplete = checklistRepo.CompleteChecklist(userId, taskId, na, naReason, out upcomingDueTimeID, out newActiveChecklistID);
        return statusReportRepo.CompleteTask(isComplete, taskId, userId, reportId);
    }

    // ReOpen Task
    [WebMethod(EnableSession = true)]
    public ResultAndTimestamp<string> ReOpenTask(int taskId, int reportId = 0)
    {
        var statusReportRepo = new StatusReportRepository();
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ReOpenChecklist(taskId);
        return ResultAndTimestamp.Create(statusReportRepo.ReOpenTask(taskId, reportId),
            QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow());
    }

    // Restore Task
    [WebMethod(EnableSession = true)]
    public void RestoreTask(int taskId)
    {
        var statusReportRepo = new StatusReportRepository();
        statusReportRepo.RestoreTask(taskId);
    }

    // Rename Checklist
    [WebMethod(EnableSession = true)]
    public void UpdateChecklistName(int checklistId, int changeId, string newName)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.UpdateChecklistName(checklistId, newName, CurrentSession.QUser.Id);
        }
        else
        {
            checklistRepo.ApprovalUpdateChecklistName(checklistId, changeId, newName, CurrentSession.QUser.Id);
        }
    }

    // Add Priorities
    [WebMethod(EnableSession = true)]
    public bool AddPriorities(int taskId)
    {
        var statusReportRepo = new StatusReportRepository();
        return statusReportRepo.AddPriorities(CurrentSession.QUser.Id, taskId);
    }

    // Copy Task
    [WebMethod(EnableSession = true)]
    public bool CopyTask(int taskId, int sectionId)
    {
        var statusReportRepo = new StatusReportRepository();
        return statusReportRepo.CopyTask(taskId, sectionId);
    }

    // Move Task
    [WebMethod(EnableSession = true)]
    public bool MoveTask(int taskId, int sectionId, int reportId)
    {
        var statusReportRepo = new StatusReportRepository();
        return statusReportRepo.MoveTask(taskId, sectionId, reportId);
    }

    [WebMethod(EnableSession = true)]
    public bool IsLastControllerByChecklistID(int taskId)
    {
        var repo = new StatusReportRepository();
        return repo.IsLastControllerByChecklistID(taskId);
    }

    // Add User
    [WebMethod(EnableSession = true)]
    public void AddUser(string login, string name, string email, string password, bool admin)
    {
        var userRepo = new UserRepository();
        userRepo.AddUser(login, name, email, password, admin);
    }

    // Update User
    [WebMethod(EnableSession = true)]
    public void UpdateUser(int id, string login, string name, string email, string password, bool admin)
    {
        var userRepo = new UserRepository();
        userRepo.UpdateUser(id, login, name, email, password, admin);
    }

    // Delete User
    [WebMethod(EnableSession = true)]
    public void DeleteUser(int id)
    {
        var userRepo = new UserRepository();
        userRepo.DeleteUser(id);
    }

    // Add Group
    [WebMethod(EnableSession = true)]
    public void AddGroup(string name)
    {
        var userRepo = new UserRepository();
        userRepo.AddGroup(CurrentSession.QUser.Id, name);
    }

    // Delete Group
    [WebMethod(EnableSession = true)]
    public void DeleteGroup(int id)
    {
        var userRepo = new UserRepository();
        userRepo.DeleteGroup(id);
    }

    // Add User To Group
    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.User> AddUserToGroup(int userId, int groupId)
    {
        var userRepo = new UserRepository();
        userRepo.AddUserToGroup(userId, groupId);
        return userRepo.GetUsersInGroup(groupId);
    }
    [WebMethod(EnableSession = true)]
    public List<Report> GetUserStatusReports(int userId)
    {
        var statusReportRepo = new StatusReportRepository();
        var result = statusReportRepo.GetMyReportsList(userId, true);
        return result;
    }

    [WebMethod(EnableSession = true)]
    public List<Report> GetUserStatusReportsWithCounts(int userId)
    {
        var statusReportRepo = new StatusReportRepository();
        var result = statusReportRepo.GetMyReportsListWithTaskCount(userId, true);
        return result;
    }

    [WebMethod(EnableSession = true)]
    public List<UserStats> GetUserKpis(int userId, int supervisorId = 0, int numberOfDays = 90)
    {
        var repo = new ChecklistRepository();
        return repo.GetUserStats(userId, supervisorId, numberOfDays);
    }
    
    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.User> GetUsersInGroup(int groupId)
    {
        var userRepo = new UserRepository();
        var result = userRepo.GetUsersInGroup(groupId);
        return result;
    }

    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.User> GetAllOtherUsers(List<int> supervisorIds)
    {
        var userRepo = new UserRepository();
        var results = new List<QProcess.Repositories.User>();
        var sortedResults = new List<QProcess.Repositories.User>();
        foreach (var supervisorId in supervisorIds)
        {
            var users = userRepo.GetUsersBySupervisor(supervisorId);
            results.AddRange(users);
        }
        sortedResults = results.OrderBy(x => x.FullName).Distinct().ToList();
        return sortedResults;
    }

    [WebMethod(EnableSession = true)]
    public List<UserStats> GetGroupUsersAndTasks(List<int> userIds, int supervisorId, int numberOfDays = 90)
    {
        var checklistRepo = new ChecklistRepository();
        var userIdsList = string.Join(",", userIds);
        var firm = ConfigurationManager.AppSettings["Firm"].ToString();
       if (firm == "PHI" ||  firm == "PFS") return checklistRepo.GetUserStatsSimple(userIdsList, true, numberOfDays);
        else return checklistRepo.GetUserStatsSimple(userIdsList, false, numberOfDays);
    }

    [WebMethod(EnableSession = true)]
    public object GetUserChecklistHisory(int userId, DateTime fromDate, DateTime toDate, string name = "")
    {

        var checklistRepo = new ChecklistRepository();
        var checklists = checklistRepo.GetSlimChecklists(userId, fromDate, toDate, 0, 0, 0)
            .Where(c => c.CompletedOn != null && c.CompletedOn <= toDate)
            .GroupBy(g => g.Name)
            .Select(g => g.OrderByDescending(r => r.DueDate).First());
        var pastDueChecklists = checklists.Where(c => c.CompletedOn < fromDate).ToList();
        var completedChecklists = checklists.Where(c => c.CompletedOn >= fromDate && c.CompletedOn <= toDate).ToList();

        var checklistResult = new
        {
            UserId = userId,
            ChecklistCount = checklists.Count(),
            CompletedChecklists = completedChecklists,
            PastDueChecklists = pastDueChecklists,
            PastDueChecklistCount = pastDueChecklists.Count(),
            OnTimeChecklistCount = completedChecklists.Count()
        };


        return checklistResult;
    }

    [WebMethod(EnableSession = true)]
    public object GetActiveUserChecklists(int userId)
    {
        var checklistRepo = new ChecklistRepository();
        var checklists = checklistRepo.GetSlimChecklists(userId, DateTime.UtcNow.AddMonths(-3), DateTime.UtcNow.AddMonths(6), 0, 0, 0)
            .Where(c => c.CompletedOn == null)
            .GroupBy(g => g.Name)
            .Select(g => g.OrderByDescending(r => r.DueDate).First());
        var activeChecklists = checklists.Where(c => c.DueDate >= DateTime.UtcNow).ToList();
        var pastDueChecklists = checklists.Where(c => c.DueDate < DateTime.UtcNow).ToList();

        var checklistResult = new
        {
            UserId = userId,
            ChecklistCount = checklists.Count(),
            ActiveChecklists = activeChecklists,
            PastDueChecklists = pastDueChecklists,
            PastDueChecklistCount = pastDueChecklists.Count(),
            OnTimeChecklistCount = activeChecklists.Count()
        };

        return checklistResult;
    }

    [WebMethod(EnableSession = true)]
    public string GetLastMetricsRun(string procedureName)
    {
        var repo = new ChecklistRepository();
        return repo.GetLastRunOfProcedure(procedureName);
    }

    [WebMethod(EnableSession = true)]
    public List<RedactedTasksList> GetRedactedTaskList(int userId, int supervisorId, bool isOwnDashboard = false)
    {
        var repo = new ChecklistRepository();
        return repo.GetRedactedTasksList(userId, supervisorId, isOwnDashboard);
    }

    [WebMethod(EnableSession = true)]
    public List<CommentHistoryList> GetCommentHistoryList(int checklistId)
    {
        var repo = new ChecklistRepository();
        return repo.GetCommentHistoryList(checklistId, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public List<DeadlineHistoryList> GetDeadlineHistoryList(int checklistId, int uniqueId)
    {
        var repo = new ChecklistRepository();
        return repo.GetDeadlineHistoryList(checklistId, uniqueId, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public List<ChangeHistoryList> GetChangeHistoryList(int checklistId)
    {
        var repo = new ChecklistRepository();
        return repo.GetChangeHistoryList(checklistId, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public string ReassignTasksToGroup(int groupId, string assignmentIds)
    {
        var assignmentIdArray = assignmentIds.Split(',');
        var repo = new ChecklistRepository();
        foreach (var assignment in assignmentIdArray)
        {
            repo.ReassignTaskToGroup(int.Parse(assignment), groupId);
        }
        return "Success";
    }

    // Remove User From Group
    [WebMethod(EnableSession = true)]
    public void RemoveUserFromGroup(int membershipId)
    {
        var userRepo = new UserRepository();
        userRepo.RemoveUserFromGroup(membershipId);
    }

    [WebMethod(EnableSession = true)]
    public void RemoveUserFromGroupByUserId(int userId, int groupId)
    {
        var userRepo = new UserRepository();
        userRepo.RemoveUserFromGroupById(userId, groupId);
    }

    // Get Group Tasks
    [WebMethod(EnableSession = true)]
    public List<TaskDetails> GetTasksControlledByGroup(int groupID, string loginName, bool newOnly, bool incompleteOnly)
    {
        var bulkRepo = new BulkAssignmentRepository();
        return bulkRepo.GetTasksControlledByGroup(groupID, loginName, newOnly, incompleteOnly);
    }

    // Get My Groups
    [WebMethod(EnableSession = true)]
    public List<UserGroup> GetMyGroups(int filterUserId)
    {
        var userRepo = new UserRepository();
        return userRepo.GetMyGroups(CurrentSession.QUser.Id, filterUserId);
    }

    // Get My Groups
    [WebMethod(EnableSession = true)]
    public List<UserGroup> GetAllGroupsIManageForUser(int userId, int supervisorId)
    {
        var userRepo = new UserRepository();
        var supervisorGroups = userRepo.GetMyGroups(userId, userId);
        //var groupIds = string.Join(",", supervisorGroups);
        return supervisorGroups;
    }

    // Get Groups
    [WebMethod(EnableSession = true)]
    public NamedEntity[] GetGroups()
    {
        var repo = new SelectListRepository();
        return repo.GetGroups();
    }

    [WebMethod(EnableSession = true)]
    public List<UserGroup> GetSupervisedGroups()
    {
        var repo = new UserRepository();
        var userFullName = CurrentSession.QUser.FullName;
        var test = repo.GetGroups().Where(g => g.Owner == userFullName).ToList();
        return test;
    }

    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.User> GetSupervisedUsers(int supervisorId)
    {
        var repo = new UserRepository();
        var supervisedUsers = repo.GetUsersBySupervisor(supervisorId);

        // If no supervised users, return the user
        if (supervisedUsers == null || supervisedUsers.Count == 0)
        {
            var self = repo.GetUsers().FirstOrDefault(u => u.Id == supervisorId);
            if (self != null)
                supervisedUsers = new List<QProcess.Repositories.User> { self };
        }

        return supervisedUsers;
    }

    // Set User's Employee ID
    [WebMethod(EnableSession = true)]
    public bool SetUserEmployeeId(string userName, int? empId)
    {
        try
        {
            var userRepo = new UserRepository();
            var user = userRepo.GetUser(userName ?? CurrentSession.QUser.Username);
            //If we're explicitly calling this method with a null empId, we must want to clear the value (-1).
            user.EmpId = empId ?? -1;
            userRepo.UpdateUser(user.Id, user.Username, user.FullName, user.Email, "", user.IsAdmin, user.EmpId);
            if (CurrentSession.QUser == null
                || (CurrentSession.QUser.Id == user.Id
                    && CurrentSession.QUser.EmpId != empId))
            {
                //User's probably setting themselves up for the first time;
                //force a refresh of current user
                HttpContext.Current.Session["CurrentUser"] = null;
                var sessionUser = QProcess.Session.CurrentSession.QUser;
            }
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    // Send Email
    public void SendEmail(string from, string to, string subject, string body)
    {
        using (var db = new DBCommand("QCheck_Sendmail"))
        {
            db.Add("@From", from);
            db.Add("@To", to);
            db.Add("@Subject", subject);
            db.Add("@Message", body);
            db.ExecuteNonQuery();
        }
        /*using (var mailClient = new SmtpClient(QProcess.Configuration.AppSettings.Get("SMTPServer"), Convert.ToInt32(QProcess.Configuration.AppSettings.Get("smtpport"))))
        {
            mailClient.EnableSsl = true;
            mailClient.UseDefaultCredentials = false;
            mailClient.Credentials = new NetworkCredential(QProcess.Configuration.AppSettings.Get("smtpuser"), QProcess.Configuration.AppSettings.Get("smtppass"));
            var toSend = new MailMessage(from, to)
            {
                Body = body,
                Subject = subject,
                IsBodyHtml = true
            };
            mailClient.Send(toSend);
        }*/
    }


    [WebMethod(EnableSession = true)]
    public void SendChangeRequestEmail(string to, string body, string checklistname)
    {
        var from = CurrentSession.QUser.FullName + "<" + CurrentSession.QUser.Email + ">";
        var subject = AppSettings.Get("AppName") + " Change Request Comments - " + checklistname;
        SendEmail(from, to, subject, body);
    }

    // Bulk Update
    [WebMethod(EnableSession = true)]
    public void BulkUpdateTasks(List<SubmittedBulkUpdate> updates)
    {
        var statusReportRepo = new StatusReportRepository();
        var checklistRepo = new ChecklistRepository();
        foreach (var update in updates)
        {
            if (update.UpdateDueDate)
            {
                checklistRepo.UpdateSoftDueDate(update.TaskId, update.DateTime);
            }
            if (update.UpdateComment && !String.IsNullOrWhiteSpace(update.Comment))
            {
                statusReportRepo.CreateNewComment(update.TaskId, CurrentSession.QUser.Id, update.Comment);
            }
        }
    }

    // Change Fonts
    [WebMethod(EnableSession = true)]
    public void ChangeFonts()
    {
        var statusReportRepo = new StatusReportRepository();
        statusReportRepo.ChangeFonts(CurrentSession.QUser.Id);
    }

    // Remove Task From Report
    [WebMethod(EnableSession = true)]
    public void RemoveTaskFromReport(int reportId, int activeChecklistId)
    {
        var statusReportRepo = new StatusReportRepository();
        statusReportRepo.RemoveTaskFromReport(CurrentSession.QUser.Id, reportId, activeChecklistId);
        Cache.CurrentCache.RefreshCachedStatusReportByReportId(reportId);
    }

    // Manage Single Checklist
    // Update Reminder Date
    [WebMethod(EnableSession = true)]
    public void UpdateReminderDate(int taskId, DateTime dateTime)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.UpdateReminderDate(taskId, dateTime);
    }

    // Update Due Date
    [WebMethod(EnableSession = true)]
    public void UpdateDueDate(int taskId, DateTime dateTime)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.UpdateDueDate(taskId, dateTime);
    }

    [WebMethod(EnableSession = true)]
    public void SaveSchedule(bool newTask, int instanceId, int frequencyType, int? frequencyInterval,
        int? frequencyRecurrence, double dueTime, string timeZone, DateTime firstDueDate,
        DateTime? firstSoftDue = null, DateTime? lastDueDate = null, int businessDayBehavior = 0,
        int? softDueOffsetDays = null, int? businessDayValue = null, int? changeId = 0)
    {
        if (frequencyType == 1 && firstSoftDue != null)
        {
            softDueOffsetDays = (firstDueDate - (DateTime)firstSoftDue).TotalDays.ToIntEx();
        }
        var checklistRepo = new ChecklistRepository();

        if ((changeId <= 0) || (changeId == null))
        {
            checklistRepo.SaveSchedule(newTask, instanceId, frequencyType, frequencyInterval, frequencyRecurrence,
                dueTime, firstDueDate, lastDueDate, businessDayBehavior, timeZone, true, softDueOffsetDays,
                businessDayValue);

            if (frequencyType == 1 && firstSoftDue != null)
            {
                checklistRepo.UpdateInstanceReminderDates(instanceId, (int)softDueOffsetDays);
            }
        }
        else
        {
            checklistRepo.ApprovalSaveSchedule(instanceId, frequencyType, frequencyInterval, frequencyRecurrence,
                dueTime, firstDueDate, lastDueDate, businessDayBehavior, timeZone, softDueOffsetDays, changeId);
        }
    }

    [WebMethod(EnableSession = true)]
    public void ActivateSchedule(int instanceId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ActivateSchedule(instanceId);
    }

    [WebMethod(EnableSession = true)]
    public int AddManagerToChecklist(int managerGroupId, int changeId, int checklistId)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            return checklistRepo.AddManagerToChecklist(managerGroupId, checklistId);
        }
        else
        {
            checklistRepo.ApprovalAddManagerToChecklist(managerGroupId, changeId, checklistId);
            return 0;
        }
    }

    [WebMethod(EnableSession = true)]
    public void DeleteManager(int id, int changeId, bool existing)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.DeleteManager(id);
        }
        else
        {
            checklistRepo.ApprovalDeleteManager(id, changeId, existing);
        }
    }

    [WebMethod(EnableSession = true)]
    public void ClearActiveChecklist(int instanceId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ClearActiveChecklist(instanceId);
    }

    [WebMethod(EnableSession = true)]
    public void MoveChecklistToFolder(int checklistId, int folderId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.MoveChecklistToFolder(checklistId, CurrentSession.QUser.Id, folderId);
    }

    [WebMethod(EnableSession = true)]
    public int AddSubFolder(int folderId)
    {
        var checklistRepo = new ChecklistRepository();
        return checklistRepo.AddSubFolder(CurrentSession.QUser.Id, folderId);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteFolder(int folderId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.DeleteFolder(folderId);
    }

    [WebMethod(EnableSession = true)]
    public void RenameFolder(int folderId, string name)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.RenameFolder(folderId, name);
    }

    [WebMethod(EnableSession = true)]
    public void MoveFolderToFolder(int folderId, int newParentId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.MoveFolderToFolder(folderId, newParentId);
    }

    [WebMethod(EnableSession = true)]
    public void ToggleTemplate(int checklistId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ToggleTemplate(checklistId);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteStatus(int id)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.DeleteStatus(id, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public int AddAlert(int id, int changeId, string alertType, int? nagBeforeDays = null, double? nagTime = null, int? alerteeGroupId = null, string alertText = null)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
            return checklistRepo.AddAlert(id, alertType, nagBeforeDays, nagTime, alerteeGroupId, alertText);
        else
        {
            checklistRepo.ApprovalAddAlert(id, changeId, alertType, nagBeforeDays, nagTime, alerteeGroupId, alertText);
            return 0;
        }
    }

    [WebMethod(EnableSession = true)]
    public void UpdateAlert(int id, int? nagBeforeDays = null, double? nagTime = null, int? alerteeGroupId = null, string alertText = null)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.UpdateAlert(id, nagBeforeDays, nagTime, alerteeGroupId, alertText);
    }

    [WebMethod(EnableSession = true)]
    public void DeleteAlert(int id, int changeId, bool existing)
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.DeleteAlert(id);
        }
        else
        {
            checklistRepo.ApprovalDeleteAlert(id, changeId, existing);
        }
    }

    [WebMethod(EnableSession = true)]
    public void SetFirstReminderDate(int instanceId, DateTime reminderDate)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.SetFirstReminderDate(instanceId, reminderDate);
    }

    // Delete Checklist
    [WebMethod(EnableSession = true)]
    public void DeleteChecklist(int checklistId, int changeId, string comment = "")
    {
        var checklistRepo = new ChecklistRepository();
        if (changeId <= 0)
        {
            checklistRepo.DeleteChecklist(checklistId);
        }
        else
        {
            checklistRepo.ApprovalDeleteChecklist(checklistId, changeId, comment);
        }
    }

    // Delete Active Checklist
    [WebMethod(true)]
    public void DeleteActiveChecklist(int activeChecklistId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.DeleteActiveChecklist(activeChecklistId);
    }

    [WebMethod(EnableSession = true)]
    public int CopyChecklist(int checklistId)
    {
        var checklistRepo = new ChecklistRepository();
        return checklistRepo.CopyChecklist(checklistId);
    }

    [WebMethod(EnableSession = true)]
    public NewCommentReturn SaveTaskUpdates(int taskId, string description, string comments, int? commentId, DateTime? dueDate,
        int? priority, DateTime? reminderDate, int[] newAssignees, string newAssigneesComments, bool isGeneralComment, bool isReply)
    {
        if (!KeepAlive()) return null;

        //this is an aggregation of the update and comment functions
        //it was needed in order to get all the saving done in a single ajax function for control flow on the page to work
        if (!isGeneralComment)
        {
            UpdateMyTask(taskId, description, dueDate, priority, reminderDate);
            if (newAssignees != null && newAssignees.Length > 0)
            {
                var checklsitRepo = new ChecklistRepository();
                checklsitRepo.UpdateAssigneesForTask(taskId, newAssignees, CurrentSession.QUser.Id, newAssigneesComments);
            }
        }
        // allow empty string to remove comment
        //BUG::if (string.IsNullOrEmpty(comments))
        //    return null;
        if (commentId.HasValue && commentId.Value != 0)
        {
            return isReply ? ReplyToComment(commentId.Value, comments, taskId) : EditComment(commentId.Value, comments, taskId);
        }
        return CreateNewComment(taskId, comments);
    }

    private void UpdateMyTask(int taskId, string description, DateTime? dueDate, int? priority, DateTime? reminderDate)
    {
        var repo = new StatusReportRepository();
        repo.UpdateMyTask(taskId, CurrentSession.QUser.Id, description, dueDate, priority, reminderDate);
    }

    [WebMethod(EnableSession = true)]
    public NewCommentReturn CreateNewComment(int taskId, string comments)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.CreateNewComment(taskId, CurrentSession.QUser.Id, comments);
    }

    [WebMethod(EnableSession = true)]
    public NewCommentReturn ReplyToComment(int commentId, string comments, int taskId)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.ReplyToComment(commentId, CurrentSession.QUser.Id, comments, taskId);
    }

    [WebMethod(EnableSession = true)]
    public NewCommentReturn EditComment(int commentId, string comments, int taskId)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.EditComment(commentId, comments, taskId);
    }

    // Request Due Date Change
    [WebMethod(EnableSession = true)]
    public void RequestDueDateChange(int taskId, DateTime newDueTime, string comment)
    {
        var checklistRepo = new ChecklistRepository();

        checklistRepo.RequestNewDueDate(taskId, newDueTime, CurrentSession.QUser.Id, comment, CurrentSession.UserTimeZone);
    }

    // Preferences
    // SetPreferences
    [WebMethod(EnableSession = true)]
    public void SetPreferences(int assignee, int controller, int due, int report, int priority, int alert, int softDue, int eChecklist, bool weeklySumEmail)
    {
        var userRepo = new UserRepository();
        userRepo.SetPreferences(CurrentSession.QUser.Id, assignee, controller, due, report, priority, alert, softDue, eChecklist, weeklySumEmail);
    }

    [WebMethod(EnableSession = true)]
    public void SetBulkImportPreferences(int bulkAssignee, int bulkController, int bulkDue, int bulkReport, int bulkPriority, int bulkSoftDue)
    {
        var userRepo = new UserRepository();
        userRepo.SetBulkImportPreferences(CurrentSession.QUser.Id, bulkAssignee, bulkController, bulkDue, bulkReport, bulkPriority, bulkSoftDue);
    }

    // Suggestions
    // Add Suggestion
    [WebMethod(EnableSession = true)]
    public List<Suggestion> AddSuggestion(string suggestion)
    {
        var suggestionRepo = new SuggestionRepository();
        suggestionRepo.AddSuggestion(suggestion, CurrentSession.QUser.Id);
        return suggestionRepo.GetSuggestions().ToList();
    }

    // Delete Suggestion
    [WebMethod(EnableSession = true)]
    public List<Suggestion> DeleteSuggestion(int suggestionId)
    {
        var suggestionRepo = new SuggestionRepository();
        suggestionRepo.DeleteSuggestion(suggestionId);
        return suggestionRepo.GetSuggestions().ToList();
    }

    // Move Suggestion
    [WebMethod(EnableSession = true)]
    public List<Suggestion> MoveSuggestion(int fromId, int toId)
    {
        var suggestionRepo = new SuggestionRepository();
        suggestionRepo.MoveSuggestion(fromId, toId);
        return suggestionRepo.GetSuggestions().ToList();
    }

    // Grading
    // Get Deductions
    [WebMethod(EnableSession = true)]
    public List<Deduction> GetDeductions(int userId, int periodId)
    {
        var gradingRepo = new GradingRepository();
        return gradingRepo.GetDeductions(userId, periodId, true).ToList();
    }

    // Add Adjustment
    [WebMethod(EnableSession = true)]
    public List<Deduction> AddAdjustment(int userId, string reason, int periodId, double points)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.AddAdjustment(userId, periodId, reason, points);
        return gradingRepo.GetDeductions(userId, periodId, true).ToList();
    }

    // Delete Deduction
    [WebMethod(EnableSession = true)]
    public List<Deduction> DeleteDeduction(int deductionId, int userId, string reason, int periodId)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.DeleteDeduction(deductionId, userId, reason);
        return gradingRepo.GetDeductions(userId, periodId, true).ToList();
    }

    // Restore Deduction
    [WebMethod(EnableSession = true)]
    public List<Deduction> RestoreDeduction(int deductionId, int userId, int periodId)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.RestoreDeduction(deductionId);
        return gradingRepo.GetDeductions(userId, periodId, true).ToList();
    }

    // Recalculate Deductions
    [WebMethod(EnableSession = true)]
    public List<Deduction> RecalculateDeductions(int periodId, int userId)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.RecalculateDeductions(periodId, userId);
        return gradingRepo.GetDeductions(userId, periodId, true).ToList();
    }

    // Get Vacations
    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.Vacation> GetVacations(int periodId, int userId = -1)
    {
        var gradingRepo = new GradingRepository();
        return gradingRepo.GetVacations(periodId, userId).ToList();
    }

    // Add Vacation
    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.Vacation> AddVacation(DateTime start, DateTime end, DateTime periodStart, DateTime periodEnd, int userId = -1)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.AddVacation(userId == -1 ? CurrentSession.QUser.Id : userId, start, end, userId != -1);
        return gradingRepo.GetVacations(periodStart, periodEnd, userId == CurrentSession.QUser.Id ? CurrentSession.QUser.Id : -1).ToList();
    }

    // Delete Vacation
    [WebMethod(EnableSession = true)]
    public List<QProcess.Repositories.Vacation> DeleteVacation(int vacationId, DateTime periodStart, DateTime periodEnd)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.DeleteVacation(vacationId);
        return gradingRepo.GetVacations(periodStart, periodEnd, CurrentSession.QUser.Id).ToList();
    }

    // Approve Vacation
    [WebMethod(EnableSession = true)]
    public void ApproveVacation(int vacationId)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.ApproveVacation(vacationId);
    }

    // Get Reports On Hold
    [WebMethod(EnableSession = true)]
    public List<ReportOnHold> GetReportsOnHold(int periodId, int userId = -1)
    {
        var gradingRepo = new GradingRepository();
        return gradingRepo.GetReportsOnHold(periodId, userId).ToList();
    }

    // Add Report On Hold
    [WebMethod(EnableSession = true)]
    public List<ReportOnHold> AddReportOnHold(int userId, int reportId, DateTime start, DateTime end, DateTime periodStart, DateTime periodEnd)
    {
        var gradingRepo = new GradingRepository();
        gradingRepo.AddReportOnHold(reportId, userId, start, end);
        return gradingRepo.GetReportsOnHold(periodStart, periodEnd, userId).ToList();
    }

    // Report Load Times
    // Save Report Load Time
    [WebMethod(EnableSession = true)]
    public void SaveReportLoadTime(string pageName, int serverLoadTime, int clientLoadTime, int reportId = -1, DateTime? lastViewed = null)
    {
        if (!KeepAlive()) return;

        var loadTimesRepo = new LoadTimesRepository();
        var browser = Context.Request.Browser.Browser + " " + Context.Request.Browser.MajorVersion + "." +
                      Context.Request.Browser.MinorVersion + " / " + Context.Request.Browser.Platform;
        if (Context.Request.Browser.AOL)
            browser += " (AOL)";
        loadTimesRepo.SaveReportLoadTime(CurrentSession.QUser.Id, pageName, serverLoadTime, clientLoadTime, browser, reportId, lastViewed);
    }

    // Linked Deadlines
    // Add Assignment
    [WebMethod(EnableSession = true)]
    public bool AddLinkedDeadline(int sourceActiveChecklist, int linkedActiveChecklist, int daysoffset)
    {
        var linkedRepo = new LinkedDeadlineRepository();
        return linkedRepo.AddLink(sourceActiveChecklist, linkedActiveChecklist, daysoffset, CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public List<LinkedDeadline> GetLinkedDeadlines()
    {
        return new LinkedDeadlineRepository().GetLinkedDeadlines(CurrentSession.QUser.Id).ToList();
    }

    [WebMethod(EnableSession = true)]
    public void DeleteLinkedDeadline(int ID)
    {
        new LinkedDeadlineRepository().DeleteLink(ID, CurrentSession.QUser.Id);
    }


    // Bulk Assignment
    // Add Assignment
    [WebMethod(EnableSession = true)]
    public void AddAssignment(List<int> assignmentIds, int assigneeGroupId, string comment)
    {
        var bulkAssignmentRepo = new BulkAssignmentRepository();
        foreach (var assignmentId in assignmentIds)
        {
            bulkAssignmentRepo.AddAssignment(assignmentId, assigneeGroupId, CurrentSession.QUser.Id, comment);
        }
    }

    // Remove Bulk Assignment
    [WebMethod(EnableSession = true)]
    public void RemoveBulkAssignment(List<int> assignmentIds, int assigneeGroupId, string comment)
    {
        var bulkAssignmentRepo = new BulkAssignmentRepository();
        foreach (var assignmentId in assignmentIds)
        {
            bulkAssignmentRepo.RemoveAssignment(assignmentId, assigneeGroupId, CurrentSession.QUser.Id, comment);
        }
    }

    // Remove Highlighting
    [WebMethod(EnableSession = true)]
    public void RemoveHighlighting()
    {
        var bulkAssignmentRepo = new BulkAssignmentRepository();
        bulkAssignmentRepo.RemoveHighlighting(CurrentSession.QUser.Id);
    }

    // Reassign page

    // Delete button
    // DeleteReport
    [WebMethod(EnableSession = true)]
    public void DeleteReportsByController(List<int> Ids)
    {
        var repo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            repo.DeleteReportByGroupReportID(id);
        }
    }

    // Delete task assignments
    [WebMethod(EnableSession = true)]
    public void DeleteTaskAssignments(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.DeleteInstanceByAssignment(id);
        }
    }

    // Remove button
    // Remove a Report Controller
    [WebMethod(EnableSession = true)]
    public void RemoveReportUser(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.RemoveReportUser(id);
        }
    }

    // Remove a Report Supervisor
    [WebMethod(EnableSession = true)]
    public void RemoveReportSupervisor(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.RemoveReportSupervisor(id);
        }
    }

    // Remove a task assignment
    [WebMethod(EnableSession = true)]
    public void RemoveTaskAssignment(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.RemoveAssignment(id);
        }
    }

    // Remove a task controller
    [WebMethod(EnableSession = true)]
    public void RemoveTaskController(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.RemoveController(id);
        }
    }

    // Remove a task alertee
    [WebMethod(EnableSession = true)]
    public void RemoveTaskAlertee(List<int> Ids)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.RemoveAlertee(id);
        }
    }

    //Reassign Button

    // Remove a Report Controller
    [WebMethod(EnableSession = true)]
    public void ReassignReportUser(List<int> Ids, int reassignedTo)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.ReassignReportUser(id, reassignedTo);
        }
    }

    // Remove a Report Supervisor
    [WebMethod(EnableSession = true)]
    public void ReassignReportSupervisor(List<int> Ids, int reassignedTo)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.ReassignReportSupervisor(id, reassignedTo);
        }
    }

    // Remove a task assignment
    [WebMethod(EnableSession = true)]
    public void ReassignTaskAssignment(List<int> Ids, int reassignedTo, bool status)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.ReassignAssignment(id, reassignedTo, status);
        }
    }

    // Remove a task controller
    [WebMethod(EnableSession = true)]
    public void ReassignTaskController(List<int> Ids, int reassignedTo)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.ReassignController(id, reassignedTo);
        }
    }

    // Remove a task alertee
    [WebMethod(EnableSession = true)]
    public void ReassignTaskAlertee(List<int> Ids, int reassignedTo)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var id in Ids)
        {
            bulkRepo.ReassignAlertee(id, reassignedTo);
        }
    }

    //Controllers Reassign Reassign Button

    // Remove a Task Controller
    [WebMethod(EnableSession = true)]
    public void ReassignTaskControllers(List<int> checklistIDs, List<int> AssignedIds)
    {
        var bulkRepo = new BulkAssignmentRepository();
        foreach (var checklistID in checklistIDs)
        {
            bulkRepo.ClearTaskControllers(checklistID);

            foreach (var assignedId in AssignedIds)
            {
                bulkRepo.AddCheckListManager(assignedId, checklistID);
            }
        }
    }

    // Task Summary
    // Add Instance Task Type
    [WebMethod(EnableSession = true)]
    public List<InstanceReportAssignment> AddInstanceTaskType(int instanceId, int taskType)
    {
        var taskSummaryRepo = new TaskSummaryRepository();
        taskSummaryRepo.AddInstanceTaskType(instanceId, taskType);
        var checklistRepo = new ChecklistRepository();
        return checklistRepo.GetInstanceReports(instanceId);
    }

    // Add Active Task Type
    [WebMethod(EnableSession = true)]
    public void AddActiveTaskType(int taskId, int taskType)
    {
        var taskSummaryRepo = new TaskSummaryRepository();
        taskSummaryRepo.AddActiveTaskType(taskId, taskType);
    }

    // Delete Instance Task Type
    [WebMethod(EnableSession = true)]
    public void DeleteInstanceTaskType(int instanceTaskTypeID)
    {
        var taskSummaryRepo = new TaskSummaryRepository();
        taskSummaryRepo.DeleteInstanceTaskType(instanceTaskTypeID, CurrentSession.QUser.Id);
    }

    // Priorities
    // Mark Set as Changed
    private void SetChanged(int setId, int listId)
    {
        try
        {
            ((PriorityInfo)CurrentCache[setId]).Changed = true;
            ((PriorityInfo)CurrentCache[setId]).Users.Single(u => u.ListId == listId).UserChanged = true;
        }
        catch (Exception)
        {
        }
    }

    // Update Font Preference
    [WebMethod(EnableSession = true)]
    public void UpdateFontPreference(string fontSize)
    {
        var userRepo = new UserRepository();
        userRepo.AddPreference(CurrentSession.QUser.Id, "PriorityFonts", fontSize);
    }

    [WebMethod(EnableSession = true)]
    public void UpdateColumnPreference(string columnSizes)
    {
        var userRepo = new UserRepository();
        userRepo.AddPreference(CurrentSession.QUser.Id, "ChangeRequestColumns", columnSizes);
    }
    // Show Comments
    [WebMethod(EnableSession = true)]
    public void ShowComments(bool showComments)
    {
        var userRepo = new UserRepository();
        userRepo.AddPreference(CurrentSession.QUser.Id, "ShowComments", showComments ? "True" : "False");
        CurrentSession.QUser.ShowComments = showComments;
    }

    // Clear Priorities List
    [WebMethod(EnableSession = true)]
    public void ClearPriorityList(int setId, int listId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.ClearPriorities(listId);
        SetChanged(setId, listId);
    }

    // Add Priority List (New Blank Set)
    [WebMethod(EnableSession = true)]
    public int AddPriorityList(string listName)
    {
        var prioritiesRepo = new PrioritiesRepository();
        return prioritiesRepo.AddPriorityList(CurrentSession.QUser.Id, listName);
    }

    // Create Priority List (Actual list, with Personal PL Set)
    [WebMethod(EnableSession = true)]
    public int CreatePriorityList(string listName)
    {
        var prioritiesRepo = new PrioritiesRepository();
        return prioritiesRepo.CreatePriorityList(CurrentSession.QUser.Id, listName);
    }

    // Set Priority List As Default
    [WebMethod(EnableSession = true)]
    public void SetDefaultPriorityList(int setId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.SetDefaultPriorityList(CurrentSession.QUser.Id, setId);
    }

    // Delete Priority List
    [WebMethod(EnableSession = true)]
    public void DeletePriorityList(int setId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.DeletePriorityList(setId);
    }

    // Add Priority List Users
    [WebMethod(EnableSession = true)]
    public void AddPriorityListUsers(int setId, string listIds)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.AddPriorityListUsers(setId, listIds);
    }

    // Add Priority Tasks
    [WebMethod(EnableSession = true)]
    public void AddPriorityTasks(int toListId, int setId, string activeChecklistIds)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.AddPriorityTasks(toListId, activeChecklistIds);
        SetChanged(setId, toListId);
    }

    // Add One Day Tasks
    [WebMethod(EnableSession = true)]
    public void AddOneDayTasks(int forUserId, int toListId, int setId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.AddUpcomingTasks(forUserId, toListId, 1);
        SetChanged(setId, toListId);
    }

    // Add Week Tasks
    [WebMethod(EnableSession = true)]
    public void AddWeekTasks(int forUserId, int toListId, int setId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.AddUpcomingTasks(forUserId, toListId, 7);
        SetChanged(setId, toListId);
    }

    // Exclude Tasks
    [WebMethod(EnableSession = true)]
    public void ExcludeTasks(int forUserId, string activeChecklistIds)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.ExcludeTasks(CurrentSession.QUser.Id, forUserId, activeChecklistIds);
    }

    // Unlock Priority List Set
    [WebMethod(EnableSession = true)]
    public void UnlockPriorityListSet(int setId)
    {
        CurrentCache.UnlockPrioritySet(setId);
    }

    // Get Status Report Link
    [WebMethod(EnableSession = true)]
    public string GetStatusReportLink(int reportUserId, int taskId = -1)
    {
        var prioritiesRepo = new PrioritiesRepository();
        return prioritiesRepo.PriorityRedirect(CurrentSession.QUser.Id, reportUserId, taskId);
    }

    // Move Priority Task
    [WebMethod(EnableSession = true)]
    public void MovePriorityTask(int taskId, int priority, int setId, int userId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.MovePriorityTask(taskId, priority);
        SetChanged(setId, userId);
    }

    // Remove Priority Task
    [WebMethod(EnableSession = true)]
    public void RemovePriorityTask(int taskId, int setId, int listId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.RemovePriorityTask(taskId);
        SetChanged(setId, listId);
    }

    [WebMethod(EnableSession = true)]
    public void SaveEntirePriorityOrder(List<TaskOrder> order, int setId, int userId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.SaveEntirePriorityOrder(order);
        SetChanged(setId, userId);
    }

    public class TaskOrder
    {
        public int TaskId { get; set; }
        public int DisplayOrder { get; set; }
    }

    // Move Priority User
    [WebMethod(EnableSession = true)]
    public void MovePriorityUser(int setId, int listId, int displayOrder)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.MovePriorityUser(setId, listId, displayOrder);
    }

    // Remove Priority User
    [WebMethod(EnableSession = true)]
    public void RemovePriorityUser(int setId, int listId)
    {
        var prioritiesRepo = new PrioritiesRepository();
        prioritiesRepo.RemovePriorityUser(setId, listId);
    }

    // Send Message
    [WebMethod(EnableSession = true)]
    public void SendMessage(string message, int messageTo)
    {
        var priorityMessage = new PriorityMessage
        {
            FromUserId = CurrentSession.QUser.Id,
            FromUserName = CurrentSession.QUser.FullName,
            Message = message,
            MessageTo = messageTo
        };
        CurrentCache.SendMessage(messageTo, priorityMessage);
    }

    [WebMethod(EnableSession = true)]
    public PriorityMessage CheckForMessages(int setId)
    {
        var lockInfo = (PriorityInfo)CurrentCache[setId];
        var priorityMessage = new PriorityMessage();
        if (CurrentCache.GetMessagesByUserId(CurrentSession.QUser.Id) != null)
            priorityMessage = CurrentCache.GetMessagesByUserId(CurrentSession.QUser.Id);
        if (lockInfo != null)
        {
            priorityMessage.Locked = true;
            priorityMessage.LockedByUserId = lockInfo.LockedByUserId;
        }
        else
        {
            priorityMessage.Locked = false;
        }

        return priorityMessage;
    }

    public class PrioritiesEmailResult
    {
        public int SetId { get; set; }
        public string EmailAddresses { get; set; }
        public string Subject { get; set; }
        public bool IncludeBody { get; set; }
        public string Body { get; set; }
        public DateTime CommentsSince { get; set; }
        public int UserId { get; set; }
        public bool SingleUserList { get; set; }
    }

    [WebMethod(EnableSession = true)]
    public PrioritiesEmailResult[] SessionEndingChangesEmail(int SetId, string Form)
    {
        PrioritiesEmailResult pe;
        List<PrioritiesEmailResult> l = new List<PrioritiesEmailResult>();
        var info = new PriorityInfo();
        bool changesToEmail = false;
        var usersChanged = new List<PrioritySetList>();
        if (CurrentCache.IsPrioritySetLocked(SetId))
        {
            info = (PriorityInfo)CurrentCache[SetId];
            foreach (var user in info.Users.Where(user => user.UserChanged))
            {
                // Don't e-mail the current user, they know what they changed
                if (user.UserId != QProcess.Session.CurrentSession.QUser.Id)
                {
                    changesToEmail = true;
                    usersChanged.Add(user);
                }
            }
        }

        if (changesToEmail)
        {
            if (info.OwnerEmail != QProcess.Session.CurrentSession.QUser.Email)
            {
                //CreatePrioritiesEmailRequest(SetId, info.OwnerEmail, "Today's Priorities: " + info.LabelName, false, "", QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date, info.OwnerId, false);
                pe = new PrioritiesEmailResult();
                pe.SetId = SetId;
                pe.EmailAddresses = info.OwnerEmail;
                pe.Subject = "Today's Priorities: " + info.LabelName;
                pe.IncludeBody = false;
                pe.Body = "";
                pe.CommentsSince = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date;
                pe.UserId = info.OwnerId;
                pe.SingleUserList = false;
                l.Add(pe);
            }
        }

        var prioritiesRepo = new PrioritiesRepository();

        foreach (var user in usersChanged.Where(user => CurrentSession.QUser.Id != user.UserId))//.Where(user => !addressesEmailed.Contains(user.Email)).Where(user => session.QUser.Id != user.UserId))
        {
            if (user.Email != QProcess.Session.CurrentSession.QUser.Email)
            {
                //CreatePrioritiesEmailRequest(SetId, user.Email, "Today's Priorities: " + user.FullName, false, "", QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date, user.UserId, true);
                pe = new PrioritiesEmailResult();
                pe.SetId = prioritiesRepo.GetPersonalSetID(user.UserId);
                pe.EmailAddresses = user.Email;
                pe.Subject = "Today's Priorities: " + user.FullName;
                pe.IncludeBody = false;
                pe.Body = "";
                pe.CommentsSince = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date;
                pe.UserId = user.UserId;
                pe.SingleUserList = true;
                if (pe.SetId > 0) // If for some reason there isn't a personal set for the user, don't include in the output or we'll have problems later.
                {
                    l.Add(pe);
                }
            }
        }

        return l.ToArray();
    }

    private void CreatePrioritiesEmailRequest(int setId, string emailAddresses, string subject, bool includeBody, string body, DateTime commentsSince, int userId, bool singleUserList)
    {
        try
        {
            var request = (HttpWebRequest)WebRequest.Create("http://" + Context.Request.Url.Authority + "/EmailHandler.ashx");
            request.Headers["X-SetId"] = setId.ToString();
            request.Headers["X-EmailAddresses"] = emailAddresses;
            request.Headers["X-Subject"] = subject;
            request.Headers["X-ShowBody"] = includeBody.ToString();
            request.Headers["X-Body"] = body;
            request.Headers["X-CommentsSince"] = commentsSince.ToString();
            if (singleUserList)
            {
                request.Headers["X-UserId"] = userId.ToString();
            }
            foreach (var datum in Context.Request.Form.AllKeys)
            {
                request.Headers["X-" + datum] = Context.Request.Form[datum];
            }
            CopyHeaders(Context.Request, request);
            request.UseDefaultCredentials = true;
            request.GetResponse();
        }
        catch (Exception e1)
        {
            var a = e1.Message;
        }
    }

    static void CopyHeaders(HttpRequest sourceRequest, HttpWebRequest targetRequest)
    {
        foreach (string key in sourceRequest.Headers)
        {
            var value = sourceRequest.Headers[key];
            object objectValue = value;
            var propName = key.Replace("-", string.Empty);
            switch (key)
            {
                case "Host":
                case "Content-Length":
                    // Do not propogate Host and Content-Length.
                    continue;
                case "Connection":
                    // Cannot set the following values ...
                    if (value == "Keep-Alive" || value == "Close")
                    {
                        continue;
                    }
                    break;
                case "If-Modified-Since":
                    objectValue = DateTime.Parse(value);
                    break;
            }
            var prop = targetRequest.GetType().GetProperty(propName, System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
            if (null != prop && prop.CanWrite)
            {
                prop.SetValue(targetRequest, objectValue, null);
            }
            else
            {
                targetRequest.Headers[key] = Convert.ToString(value);
            }
        }
    }

    // Reports
    // Send Overdue Email Messages
    [WebMethod(EnableSession = true)]
    public string SendOverdueEmailMessages(string recipientIds, string message)
    {
        var reportsRepo = new ReportsRepository();
        if (recipientIds.Length > 1000)
            return "Too Many Recipients";
        if (message.Length > 1000)
            return "Message is too long";
        return reportsRepo.SendOverdueMessageEmails(CurrentSession.QUser.Id, recipientIds, message) ? "Email Sent" : "There was a problem sending your e-mail.";
    }

    [WebMethod(EnableSession = true)]
    public List<ReportChecklistStatus> GetOverdueReportTasks(int userId, string sort, ReportType reportType)
    {
        var reportsRepo = new ReportsRepository();
        return QProcess.Session.CurrentSession.QUser.IsOverdueAdmin
            ? reportsRepo.GetOpenChecklist(QProcess.Session.CurrentSession.QUser.Id, sort, reportType).ToList()
            : reportsRepo.GetOpenChecklist(userId, sort, reportType).ToList();
    }

    [WebMethod(EnableSession = true)]
    public void ApproveRequest(int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.ApproveRequest(changeId, QProcess.Session.CurrentSession.QUser.Id);
    }

    [WebMethod(EnableSession = true)]
    public void RejectRequest(int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.RejectRequest(changeId, QProcess.Session.CurrentSession.QUser.Id);

    }

    [WebMethod(EnableSession = true)]
    public void SendRequest(int changeId, string comment = "")
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.SendRequest(changeId, comment);
    }

    [WebMethod(EnableSession = true)]
    public void CancelRequest(int changeId)
    {
        var checklistRepo = new ChecklistRepository();
        checklistRepo.CancelRequest(changeId);
    }

    [WebMethod(EnableSession = true)]
    public void SetColumnWidth(int reportId, int width)
    {
        var statusReportRepo = new StatusReportRepository();
        statusReportRepo.SetColumnWidth(CurrentSession.QUser.Id, reportId, width);
    }

    // My Inbox
    // Toggle Favorite Report
    [WebMethod(EnableSession = true)]
    public void ToggleFavoriteReport(int reportId)
    {
        var myInboxRepo = new MyInboxRepository();
        myInboxRepo.ToggleFavoriteReport(CurrentSession.QUser.Id, reportId);
    }

    // Set Supervisor Email Preference
    [WebMethod(EnableSession = true)]
    public void SetSupervisorEmailPreference(EmailPreferenceType type, bool sendEmail)
    {
        var myInboxRepo = new MyInboxRepository();
        myInboxRepo.SetSupervisorEmailPreference(CurrentSession.QUser.Id, type, sendEmail);
    }

    // Save Inbox Sorting
    [WebMethod(EnableSession = true)]
    public void SaveInboxSorting(string sortBy, string sortOrder)
    {
        var userRepo = new UserRepository();
        userRepo.SaveInboxSorting(CurrentSession.QUser.Id, sortBy, sortOrder);
    }

    // Mark As Read
    [WebMethod(EnableSession = true)]
    public void MarkAsRead(int reportId)
    {
        var myInboxRepo = new MyInboxRepository();
        myInboxRepo.MarkAsRead(reportId, CurrentSession.QUser.Id);
    }

    // Add Confidential Report
    [WebMethod(EnableSession = true)]
    public void AddConfidentialReport(int reportId)
    {
        var myInboxRepo = new MyInboxRepository();
        myInboxRepo.AddConfidentialReport(reportId);
    }

    // Remove Confidential Report
    [WebMethod(EnableSession = true)]
    public void RemoveConfidentialReport(int reportId)
    {
        var myInboxRepo = new MyInboxRepository();
        myInboxRepo.RemoveConfidentialReport(reportId);
    }

    // My Tasks
    // Update Preferred Ending Date
    [WebMethod(EnableSession = true)]
    public void UpdatePreferredEndingDate(DateTime endDate)
    {
        var userRepo = new UserRepository();
        TimeSpan diff = endDate - QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date;
        if (diff.TotalDays < 10 && diff.TotalDays >= 0)
            userRepo.AddPreference(CurrentSession.QUser.Id, "FilterDays", (Convert.ToInt32(diff.TotalDays)).ToString());
    }

    // Update Preferred Starting Date
    [WebMethod(EnableSession = true)]
    public void UpdatePreferredStartingDate(DateTime startDate)
    {
        var userRepo = new UserRepository();
        TimeSpan diff = startDate - QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date;
        if (diff.TotalDays > -10)
            userRepo.AddPreference(CurrentSession.QUser.Id, "FilterDaysMinus", (Convert.ToInt32(diff.TotalDays)).ToString());
    }

    [WebMethod(EnableSession = true)]
    public bool CheckSupervisor(int reportId)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.CheckSupervisor(CurrentSession.QUser.Id, reportId);
    }

    [WebMethod(EnableSession = true)]
    public bool CheckReportController(int reportId)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.CheckIsUser(CurrentSession.QUser.Id, reportId);
    }

    [WebMethod(EnableSession = true)]
    public bool InterestedPartyOnly(int reportId)
    {
        var inboxRepo = new MyInboxRepository();
        return inboxRepo.InterestedPartyOnly(reportId);
    }

    [WebMethod(EnableSession = true)]
    public int GetCommentColor(int reportId)
    {
        var statusRepo = new StatusReportRepository();
        return statusRepo.GetCommentColor(CurrentSession.QUser.Id, reportId);
    }

    // Update ManageTasks Search Term
    [WebMethod(EnableSession = true)]
    public void UpdateSearchTerm(string searchTerm)
    {
        var userRepo = new UserRepository();
        userRepo.AddPreference(CurrentSession.QUser.Id, "ControlSearch", searchTerm);
    }

    private int GetUserID()
    {
        var _session = HttpContext.Current.Session;
        var user = _session["CurrentUser"] as IUser;
        if (user == null)
            _session["CurrentUser"] = new UserRepository().GetUser(QProcess.Session.CurrentSession.QUser.Username.ToLower().Replace(AppSettings.Get("Domain") + "\\", ""));
        var iuser = _session["CurrentUser"] as IUser;
        return iuser.Id;
    }

    private string WrapCriteria(string criteria, string data)
    {
        if (criteria == "") return data;
        if (data == null) return "";

        foreach (string srch in criteria.Split(' '))
        {
            int idx = 0;
            while (idx != -1)
            {
                idx = data.IndexOf(srch, idx, StringComparison.CurrentCultureIgnoreCase);
                if (idx >= 0)
                {
                    // this is to fix the malform HTML bug when "b" is a criteria
                    if (srch.Trim().ToLower() == "b" && data.Length > idx + 1 && data.Substring(idx + 1, 1) == ">")
                    {
                        // ignore since this is the <b> or </b> tag
                        idx++;
                    }
                    else
                    {
                        data = data.Insert(idx, "<b>").Insert(idx + 3 + srch.Length, "</b>");
                        idx += 4 + srch.Length;
                    }
                }
            }
        }

        return data;
    }

    [WebMethod(enableSession: true)]
    public TaskSearchResult TaskSearch(string search, string timestamp)
    {
        var lst = new List<TaskSearchResult.TaskSearchItem>();

        using (var db = new DBCommand("QCheck_ActiveTaskSearch"))
        {
            var ds = db.Add("@Search", search).Add("@UserID", GetUserID()).ExecuteDataSet();
            foreach (DataRow row in ds.Tables[0].Rows)
            {
                lst.Add(new TaskSearchResult.TaskSearchItem()
                {
                    TaskName = row["Name"].ToBlank(),
                    Due = row["Due"].ToBlank(),
                    Completed = row["Completed"].ToBlank(),
                    Assignees = row["Assignees"].ToBlank(),
                    Controllers = row["Controllers"].ToBlank(),
                    Schedule = row["Schedule"].ToBlank(),
                    LastCompletedBy = row["LastCompletedBy"].ToBlank(),
                    LastCompletedDate = row["LastCompletedDate"].ToBlank()
                });
            }

            if (lst.Count > 0)
                return new TaskSearchResult() { Timestamp = timestamp, Data = lst.ToArray(), ActualCount = ds.Tables[1].Rows[0][0].ToIntEx().Value };
            else
                return new TaskSearchResult() { Timestamp = timestamp, Data = null, ActualCount = 0 };
        }
    }

    [WebMethod(EnableSession = true)]
    public bool OutprocessUser(int outprocessedUserId, int reassignedUserId)
    {
        try
        {
            using (var db = new DBCommand("QCheck_OutprocessAndReplaceUser"))
            {
                db.Add("@OutprocessUserId", outprocessedUserId)
                  .Add("@ReassignmentTargetUserId", reassignedUserId)
                  .ExecuteNonQuery();
            }

            return true;
        }
        catch (Exception /*ex*/)
        {
            //TODO: Need to implement a logger potentially
            //Console.WriteLine(ex.Message.ToString());

            return false;
        }
    }

    [WebMethod(enableSession: true)]
    public bool ToggleAssigneeVisibility(int reportID)
    {
        try
        {
            using (var db = new DBCommand("QStatus_ToggleAssigneeVisibility"))
            {
                db.Add("@UserID", GetUserID())
                  .Add("@ReportID", reportID)
                  .ExecuteNonQuery();
            }

            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    [WebMethod(enableSession: true)]
    public bool GetAssigneeVisibility(int reportID)
    {
        bool result = false;
        using (var db = new DBCommand("QStatus_GetAssigneeVisibility"))
        {
            db.Add("@UserID", GetUserID())
              .Add("@ReportID", reportID)
              .Add("@Visible", ParameterDirection.Output, DbType.Boolean, result)
              .ExecuteNonQuery();

            result = db.GetOutputParameter("@Visible").ToBoolEx().Value;
        }

        return result;
    }

    [WebMethod]
    public List<NamedEntity> GetOverdueRecipients(int userID, int controllerID)
    {
        var selectListRepo = new SelectListRepository();
        return selectListRepo.GetOverdueRecipients(userID, controllerID).ToList();
    }

    [WebMethod(EnableSession = true)]
    public bool DuplicateNameCheck(string name)
    {
        var checklistRepo = new ChecklistRepository();
        return checklistRepo.DuplicateNameCheck(name, CurrentSession.QUser.Id);
    }

    [WebMethod]
    public KeyValuePair<int, string>[] GetAllUsers()
    {
        var lst = new List<KeyValuePair<int, string>>();

        using (var db = new DBCommand("select ID, FullName from QCheck_Users with (nolock) order by FullName", CommandType.Text))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
                if (row["FullName"].ToBlank().Length > 1)
                    lst.Add(new KeyValuePair<int, string>(row["ID"].ToIntEx().Value, row["FullName"].ToBlank()));
        }

        return lst.ToArray();
    }

    [WebMethod(enableSession: true)]
    public List<string> GetSearchHistory(string criteria)
    {
        var lst = new List<string>();

        using (var db = new DBCommand("QCheck_GetSearchHistory"))
        {
            var ds = db.Add("@userId", GetUserID())
                       .Add("@criteria", criteria)
                       .ExecuteDataSet();

            foreach (DataRow row in ds.Tables[0].Rows)
                lst.Add(row[0].ToString());
        }

        if (lst.Count == 0)
            return null;
        else
            return lst;
    }

    [WebMethod(enableSession: true)]
    public List<string> SearchMyTask(string criteria,
    bool? logicAndOr, bool includeTask, bool includeItem,
    bool includeComment, string fromDate, string toDate)
    {
        var myTz = CurrentSession.QUser.MyTimeZone;

        var lst = new List<string>();

        using (var db = new DBCommand("QStatus_MyTaskSearch"))
        {
            if (!string.IsNullOrWhiteSpace(fromDate))
                db.Add("@fromDate", myTz.GetUtcTime(DateTime.Parse(fromDate)));

            if (!string.IsNullOrWhiteSpace(toDate))
                db.Add("@toDate", myTz.GetUtcTime(DateTime.Parse(toDate)));

            var ds = db.Add("@criteria", criteria)
                       .Add("@logicAndOr", logicAndOr)
                       .Add("@userId", GetUserID())
                       .Add("@includeTaskName", includeTask)
                       .Add("@includeItemText", includeItem)
                       .Add("@includeComment", includeComment)
                       .ExecuteDataSet();

            foreach (DataRow row in ds.Tables[0].Rows)
                lst.Add(row[0].ToString());
        }

        if (lst.Count == 0)
            return null;
        else
            return lst;
    }

    [WebMethod(enableSession: true)]
    public List<string> SearchCalendar(string criteria,
    bool? logicAndOr, bool includeTask, bool includeItem,
    bool includeComment, string fromDate, string toDate)
    {
        var myTz = CurrentSession.QUser.MyTimeZone;

        var lst = new List<string>();

        using (var db = new DBCommand("QStatus_MyTaskSearch"))
        {
            if (!string.IsNullOrWhiteSpace(fromDate))
            {
                db.Add("@fromDate", myTz.GetUtcTime(DateTime.Parse(fromDate)));
                db.Add("@toDate", myTz.GetUtcTime(DateTime.Parse(fromDate).AddDays(5)));
            }

            var ds = db.Add("@criteria", criteria)
                       .Add("@logicAndOr", logicAndOr)
                       .Add("@userId", GetUserID())
                       .Add("@includeTaskName", includeTask)
                       .Add("@includeItemText", includeItem)
                       .Add("@includeComment", includeComment)
                       .ExecuteDataSet();

            foreach (DataRow row in ds.Tables[0].Rows)
                lst.Add(row[0].ToString());
        }

        if (lst.Count == 0)
            return null;
        else
            return lst;
    }

    [WebMethod(enableSession: true)]
    public List<object> SearchMyStatus(string criteria,
        bool? logicAndOr, int reportId, bool includeTask, bool includeItem,
        bool includeComment, bool includeArchive, string fromDate, string toDate)
    {
        var myTz = CurrentSession.QUser.MyTimeZone;

        var lst = new List<object>();

        using (var db = new DBCommand("QStatus_MyStatusSearch")) //"QStatus_MyStatusSearch"
        {
            if (!string.IsNullOrWhiteSpace(fromDate))
                db.Add("@fromDate", myTz.GetUtcTime(DateTime.Parse(fromDate)));

            if (!string.IsNullOrWhiteSpace(toDate))
                db.Add("@toDate", myTz.GetUtcTime(DateTime.Parse(toDate)));

            DataSet ds;
            try
            {
                ds = db.Add("@criteria", criteria)
                        .Add("@logicAndOr", logicAndOr)
                        .Add("@reportId", reportId)
                        .Add("@userId", GetUserID())
                        .Add("@includeTaskName", includeTask)
                        .Add("@includeItemText", includeItem)
                        .Add("@includeComment", includeComment)
                        .Add("@includeArchive", includeArchive)
                        .ExecuteDataSet();
            }
            catch (SqlException ex)
            {
                //incomplete "advanced" 
                return null;
            }
            if (ds.Tables.Count > 0)
            {
                foreach (DataRow row in ds.Tables[0].Rows)
                    lst.Add(new { Id = row[0].ToString() });
            }

            if (ds.Tables.Count > 1)
            {
                foreach (DataRow row in ds.Tables[1].Rows)
                    lst.Add(new
                    {
                        Task = row["Task"].ToString(),
                        DueTime = CurrentSession.QUser.MyTimeZone.GetLocalTime(DateTime.Parse(row["DueTime"].ToBlank())).ToString("M/dd/yyyy"),
                        Assignees = row["Assignees"].ToString(),
                        Controllers = row["Controllers"].ToString(),
                        Comments = row["Comments"].ToString()
                    });
            }
        }

        if (lst.Count == 0)
            return null;
        else
            return lst;
    }

    [WebMethod(enableSession: true)]
    public SearchResult GlobalSearch(string userId, string criteria,
        bool? logicAndOr, int reportId, bool includeTask, bool includeItem, bool includeArchive,
        bool includeComment, string fromDate, string toDate, string timestamp)
    {

        DateTime parsedFromDate;
        DateTime parsedToDate;

        var myTz = CurrentSession.QUser.MyTimeZone;
        var lst = new List<SearchResult.ItemResult>();

        if (string.IsNullOrEmpty(userId))
            userId = CurrentSession.QUser.Id.ToString();

        using (var db = new DBCommand("QStatus_GlobalSearchNew"))
        {
            if (reportId != 0) db.Add("@reportId", reportId);

            if (DateTime.TryParse(fromDate, out parsedFromDate)) parsedFromDate = parsedFromDate.AddSeconds(-1);
            else parsedFromDate = DateTime.Now.AddYears(-3).AddSeconds(-1);

            if (DateTime.TryParse(toDate, out parsedToDate)) parsedToDate = parsedToDate.AddHours(24).AddSeconds(-1);
            else parsedToDate = DateTime.Now.AddYears(3).AddSeconds(-1);

            db.Add("@fromDate", parsedFromDate);
            db.Add("@toDate", parsedToDate);

            DataSet ds;
            try
            {
                ds = db.Add("@userIDs", userId)
                        .Add("@criteria", criteria)
                        .Add("@logicAndOr", logicAndOr)
                        .Add("@UserID", CurrentSession.QUser.Id)
                        .Add("@includeTaskName", includeTask)
                        .Add("@includeItemText", includeItem)
                        .Add("@includeComment", includeComment)
                        .Add("@includeArchive", includeArchive)
                        .ExecuteDataSet();
            }
            catch (SqlException ex)
            {
                //incomplete "advanced" 
                return new SearchResult() { Timestamp = timestamp, Data = null, Truncated = false };
            }

            foreach (DataRow row in ds.Tables[0].Rows)
            {
                lst.Add(new SearchResult.ItemResult()
                {
                    ChecklistId = row["ChecklistID"].ToIntEx().Value,
                    IsDeleted = row["IsDeleted"].ToBoolEx().Value,
                    IsArchived = row["Archived"].ToBoolEx().Value,
                    Name = row["Task"].ToBlank(),
                    Schedule = row["ScheduleString"].ToBlank(),
                    //Schedule = myTz.GetLocalTime(DateTime.Parse(row["DueDate"].ToBlank())).ToString(),
                    Completed = row["CompletedDate"].ToBlank(),
                    Controllers = row["Controllers"].ToBlank(),
                    StatusReport = row["StatusReport"].ToBlank(),
                    Assignees = row["Assignees"].ToBlank(),
                    Comment = row["Comments"].ToBlank(),
                    ItemText = row["ItemText"].ToBlank()
                });
            }

            if (lst.Count > 0)
                return new SearchResult() { Timestamp = timestamp, Data = lst.ToArray(), Truncated = ds.Tables[1].Rows[0][0].ToBoolEx().Value };
            else
                return new SearchResult() { Timestamp = timestamp, Data = null, Truncated = ds.Tables[1].Rows[0][0].ToBoolEx().Value };
        }
    }

    [WebMethod(enableSession: true)]
    public bool SaveSearchHistory(string criteria)
    {
        using (var db = new DBCommand("QStatus_SaveSearchHistory"))
        {
            var ds = db.Add("@criteria", criteria)
                       .Add("@UserID", GetUserID())
                       .ExecuteNonQuery();
        }

        return true;
    }

    [WebMethod]
    public KeyValuePair<int, string>[] GetAllCommentsByChecklist(int checklistId, string criteria)
    {
        var list = new List<KeyValuePair<int, string>>();

        using (var db = new DBCommand("QStatus_GetAllCommentsByChecklist"))
            foreach (DataRow row in db.Add("@checklistID", checklistId).ExecuteDataSet().Tables[0].Rows)
                list.Add(new KeyValuePair<int, string>(row["TabIn"].ToIntEx().Value, row["Comments"].ToBlank()));

        return list.ToArray();
    }

    [WebMethod]
    public KeyValuePair<bool, string>[] GetChecklistItems(int checklistId, string criteria)
    {
        var list = new List<KeyValuePair<bool, string>>();

        using (var db = new DBCommand("QStatus_GetChecklistItems"))
            foreach (DataRow row in db.Add("@checklistID", checklistId).ExecuteDataSet().Tables[0].Rows)
                list.Add(new KeyValuePair<bool, string>(row["IsDeleted"].ToBoolEx().Value, row["Text"].ToBlank()));

        return list.ToArray();
    }

    [WebMethod(enableSession: true)]
    public bool IsAdmin()
    {
        using (var db = new DBCommand("QStatus_IsAdmin"))
        {
            return db.Add("@userId", GetUserID()).ExecuteScalar().ToBoolEx().Value;
        }
    }

    [WebMethod(enableSession: true)]
    public string RequirePopup()
    {
        using (var db = new DBCommand("QCheck_CompletionPopup"))
        {
            return db.Add("@userId", GetUserID()).ExecuteScalar().ToBlank();
        }
    }


    [WebMethod(enableSession: true)]
    public void SetupTest(int testerGroupID, string testDate)
    {
        using (var db = new DBCommand("Util_SetupTest"))
        {
            db.Add("@TesterGroupID", testerGroupID);
            db.Add("@TestDate", testDate);
            db.ExecuteNonQuery();
        }
    }

    [WebMethod(enableSession: true)]
    public void CleanupTest(int testerGroupID, string testDate)
    {
        using (var db = new DBCommand("Util_CleanupTest"))
        {
            db.Add("@TesterGroupID", testerGroupID);
            db.Add("@TestDate", testDate);
            db.ExecuteNonQuery();
        }
    }

    [WebMethod(enableSession: true)]
    public string GradeTest(int testerGroupID, string testDate)
    {
        using (var db = new DBCommand("Util_GradeTest"))
        {
            db.Add("@TesterGroupID", testerGroupID);
            db.Add("@TestDate", testDate);
            return db.ExecuteScalar().ToDoubleEx().Value.ToString();
        }
    }

    [WebMethod(enableSession: true)]
    public string GradeTestFullReport(int testerGroupID, string testDate, bool recordScore)
    {
        var user = new UserRepository().GetUser(CurrentSession.QUser.Username);
        if (user.IsGradingAdmin)
        {
            using (var db = new DBCommand("Util_GradeTest_Breakdown"))
            {
                var ds = db.Add("@TesterGroupID", testerGroupID)
                    .Add("@TestDate", testDate)
                    .Add("@RecordScore", recordScore)
                    .ExecuteDataSet();

                string result = JsonConvert.SerializeObject(ds);

                return result;
            }
        }
        else
            return "";
    }

    [WebMethod(enableSession: true)]
    public string TestingHistoryReport()
    {
        var user = new UserRepository().GetUser(CurrentSession.QUser.Username);
        if (user.IsGradingAdmin)
        {
            using (var db = new DBCommand("Util_UserTestReport"))
            {
                var ds = db.ExecuteDataSet();
                string result = JsonConvert.SerializeObject(ds);
                return result;
            }
        }
        else
            return "";
    }

    [WebMethod(enableSession: true)]
    public string GetLastComment(int taskId, int userId)//added by venkat on 04/20/2017
    {
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        using (var db = new DBCommand("PriorityList_GetLastComment_UTC"))
        {
            //return db.Add("@taskId", taskId).Add("@userId",userId).Add("@StartTime", QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date).ExecuteScalar().ToString();
            return db
                .Add("@taskId", taskId)
                .Add("@userId", CurrentSession.QUser.Id)
                //get comments since midnight local time, expressed as UTC
                .Add("@StartTime", myTz.GetSystemTime(myTz.GetLocalTimeNow().Date))
                .ExecuteScalar()
                .ToBlank()
                .Replace("<br>", "\n");
        }
    }

    [WebMethod(EnableSession = true)]
    public NewCommentReturn CreateNewPriorityComment(int taskId, string comments, bool isNew = false)
    {
        var repo = new PrioritiesRepository();
        return repo.CreateNewPriorityComment(taskId, CurrentSession.QUser.Id, comments, isNew);
    }

    [WebMethod(true)]
    public void SetAlertException(int alertId, DateTime exceptionTime)
    {
        var userId = GetUserID();

        using (var db = new DBCommand("QCheck_SetAlertException"))
        {
            db.Add("@ActiveAlertID", alertId)
                .Add("@UserID", userId)
                .ExecuteNonQuery();
        }
    }

    [WebMethod(true)]
    public void ClearAlertException(int alertId, DateTime exceptionTime)
    {
        var userId = GetUserID();

        using (var db = new DBCommand("QCheck_ClearAlertException"))
        {
            db.Add("@ActiveAlertID", alertId)
                .Add("@UserID", userId)
                .ExecuteNonQuery();
        }
    }

    [WebMethod(true)]
    public void SetFilterMask(int filterMask)
    {
        Session["filterMask"] = filterMask <= 0 ? 103 : filterMask;
    }


    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> SavePrioritiesSchedule(string day, string time, string reportDay)
    {
        var userRepo = new UserRepository();
        int setId;
        int subOrdinateId;
        if (int.TryParse(userRepo.GetPreference(CurrentSession.QUser.Id, "LastPrioritySet"), out setId))
        {
            var prioritiesRepo = new PrioritiesRepository();
            subOrdinateId = prioritiesRepo.GetPriorityInfo(setId, CurrentSession.QUser.Id, CurrentSession.QUser.FullName, CurrentSession.SessionId).OwnerId;

            using (var db = new DBCommand("InsertPrioritySchedule"))
            {
                db.Add("@supervisorId", CurrentSession.QUser.Id);
                db.Add("@subOrdinateId", subOrdinateId);
                db.Add("@daysOfWeek", day);
                db.Add("@timesOfDay", DateTime.Parse(time).ToString("HH:mm"));
                db.Add("@reportDay", reportDay);
                db.ExecuteNonQuery();
            }
        }

        return GetPrioritiesListSchedule();
    }

    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> SaveEmployeePrioritiesSchedule(string day, string time, string reportDay, int employeeId)
    {
        var prioritiesRepo = new PrioritiesRepository();

        using (var db = new DBCommand("InsertPrioritySchedule"))
        {
            db.Add("@supervisorId", CurrentSession.QUser.Id);
            db.Add("@subOrdinateId", employeeId);
            db.Add("@daysOfWeek", day);
            db.Add("@timesOfDay", DateTime.Parse(time).ToString("HH:mm"));
            db.Add("@reportDay", reportDay);
            db.ExecuteNonQuery();
        }

        return GetPrioritiesListScheduleForEmployee(employeeId);
    }

    [WebMethod(EnableSession = true)]
    public string GetExistingTasks(string userId, string userName)
    {
        var checklistRepo = new ChecklistRepository();
        var tasks = checklistRepo.GetTasksIControlWithTimezones(int.Parse(userId)).ToList();
        tasks.ForEach(t =>
        {
            var newTz = TimeZoneInfo.FindSystemTimeZoneById(TZConvert.IanaToWindows(t.Timezone));
            var newOffset = newTz.GetUtcOffset(t.DueTime);
            t.DueTime = t.DueTime.AddHours(newOffset.TotalHours);
        });
        var items = JsonConvert.SerializeObject(tasks);


        return items;
    }

    [WebMethod(EnableSession = true)]
    public string ConvertTimezonesOfAllSelected(ConvertTimezoneRequest request)
    {
        var repo = new ChecklistRepository();

        //var newTz = TimeZoneInfo.FindSystemTimeZoneById(TZConvert.IanaToWindows(item.NewLocation));
        //var oldTz = TimeZoneInfo.FindSystemTimeZoneById(TZConvert.IanaToWindows(item.CurrentLocation));

        //var newOffset = newTz.GetUtcOffset(item.CurrentTimeStamp);
        //var oldOffset = oldTz.GetUtcOffset(item.CurrentTimeStamp);

        ////gotta go back in time (reverse the offset back to UTC)
        //var utcTimestamp = item.CurrentTimeStamp.AddHours(-newOffset.TotalHours);

        //var updatedLocalTimestamp = utcTimestamp.AddHours(oldOffset.TotalHours);

        ////How many hours different from UTC are we 
        //var newHoursMinutes = item.CurrentTimeStamp.Hour + (item.CurrentTimeStamp.Minute / 60.0f);

        repo.ConvertTimezonesOfAllSelectedTasks(request.InstanceId, request.NewLocation);
        return "";
    }

    [WebMethod(EnableSession = true)]
    public string GetAvailableTimezones()
    {
        var items = JsonConvert.SerializeObject(TimeZoneHelper.GetAllTimeZoneNames(true));

        return items;
    }


    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> GetPrioritiesListSchedule()
    {

        var priorityList = new List<PrioritySchedule>();
        var userRepo = new UserRepository();

        //using (var db = new DBCommand("QStatus_GetPriorityListSchedules"))
        using (var db = new DBCommand("GetPriorityListSchedules"))

        {
            int setId;
            var prioritiesRepo = new PrioritiesRepository();
            if (int.TryParse(userRepo.GetPreference(CurrentSession.QUser.Id, "LastPrioritySet"), out setId))
            {
                int subOrdinateId = prioritiesRepo.GetPriorityInfo(setId, CurrentSession.QUser.Id, CurrentSession.QUser.FullName, CurrentSession.SessionId, false).OwnerId;
                foreach (DataRow row in db.Add("@supervisorId", CurrentSession.QUser.Id).Add("@subOrdinateId", subOrdinateId).ExecuteDataSet().Tables[0].Rows)
                {
                    var schedule = new PrioritySchedule();
                    schedule.ScheduleID = Int32.Parse(row["ScheduleId"].ToString());
                    schedule.SupervisorID = Int32.Parse(row["SupervisorID"].ToString());
                    schedule.SubOrdinateId = Int32.Parse(row["EmployeeId"].ToString());
                    schedule.DaysOfWeek = GetWeekDay(row["DaysOfWeek"].ToString());
                    schedule.ReportDay = GetWeekDay(row["ReportDay"].ToString());
                    schedule.TimesOfDay = DateTime.Parse(row["TimesOfDay"].ToString()).ToString("hh:mm tt");

                    priorityList.Add(schedule);
                }
            }
        }

        return priorityList;
    }

    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> GetPrioritiesListScheduleForEmployee(int employeeId)
    {
        var priorityList = new List<PrioritySchedule>();
        var userRepo = new UserRepository();

        using (var db = new DBCommand("GetPriorityListSchedules"))

        {
            //int setId;
            var prioritiesRepo = new PrioritiesRepository();
            // if (int.TryParse(userRepo.GetPreference(session.QUser.Id, "LastPrioritySet"), out setId))
            {
                db.Add("@supervisorId", CurrentSession.QUser.Id)
                    .Add("@subOrdinateId", employeeId);

                foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
                {
                    var schedule = new PrioritySchedule();
                    schedule.ScheduleID = Int32.Parse(row["ScheduleId"].ToString());
                    schedule.SupervisorID = Int32.Parse(row["SupervisorID"].ToString());
                    schedule.SubOrdinateId = Int32.Parse(row["SubOrdinateID"].ToString());
                    schedule.DaysOfWeek = GetWeekDay(row["DaysOfWeek"].ToString());
                    schedule.ReportDay = GetWeekDay(row["ReportDay"].ToString());
                    schedule.TimesOfDay = DateTime.Parse(row["TimesOfDay"].ToString()).ToString("hh:mm tt");

                    priorityList.Add(schedule);
                }
            }
        }

        return priorityList;

    }

    public string GetWeekDay(string index)
    {
        string weekDay = string.Empty;

        switch (index)
        {
            case "1":
                weekDay = "Monday";
                break;
            case "2":
                weekDay = "Tuesday";
                break;
            case "3":
                weekDay = "Wednesday";
                break;
            case "4":
                weekDay = "Thursday";
                break;
            case "5":
                weekDay = "Friday";
                break;
            case "6":
                weekDay = "Saturday";
                break;
            case "7":
                weekDay = "Sunday";
                break;
            default:
                break;
        }

        return weekDay;
    }


    [WebMethod(EnableSession = true)]
    public string GetPriorityListScheduleReport(string startDate, string endDate, string employee)
    {

        var sb = new System.Text.StringBuilder();

        using (var db = new DBCommand("GetPriorityList_ScheduleReport").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate).Add("@supervisor", CurrentSession.QUser.Id).Add("@employee", employee))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["Employee"].ToString());

            foreach (var group in employeeGroups)
            {

                int lateCount = 0;
                foreach (var row in group.OrderByDescending(rec => DateTime.Parse(rec["ScheduledDate"].ToString())))
                {
                    string isLate = "No";
                    if ((String.IsNullOrEmpty(row["SentDate"].ToString()) && DateTime.Parse(row["ScheduledDate"].ToString()) < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) || (!String.IsNullOrEmpty(row["SentDate"].ToString()) && DateTime.Parse(row["SentDate"].ToString()) > DateTime.Parse(row["ScheduledDate"].ToString())))
                    {
                        if (String.IsNullOrEmpty(row["IsExcludedReason"].ToString()))
                        {
                            lateCount++;
                            isLate = "Yes";
                        }
                    }

                    sb.Append("<tr bgcolor='#ffffff'>");
                    //sb.Append("<td style='text-align:left;'>" + row["Supervisor"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + row["Employee"].ToString() + "</td>");
                    //sb.Append("<td style='text-align:left;'>" + row["ReportDate"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + row["ScheduledDate"].ToString() + (String.IsNullOrEmpty(row["IsExcludedReason"].ToString()) ? "" : "(" + row["IsExcludedReason"].ToString() + ")") + "</td>");
                    sb.Append("<td style='text-align:left;'>" + row["SentDate"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + isLate + "</td>");
                    sb.Append("</tr>");

                }

                sb.Append("<tr><td></td><td></td><td style='color:Red'><b>Total Late Count:" + lateCount + "</b></td></tr>");
            }
        }

        return sb.ToString();
    }



    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> DeletePrioritySchedule(int scheduleId, int employeeId)
    {

        using (var db = new DBCommand("DeletePrioritySchedule"))
        {
            db.Add("@scheduleId", scheduleId);

            db.ExecuteNonQuery();
        }
        return GetPrioritiesListScheduleForEmployee(employeeId);
        //return GetPrioritiesListSchedule();
    }


    [WebMethod(EnableSession = true)]
    public string GetSupervisorsPrioritySchedule(int employeeId)
    {

        var sb = new System.Text.StringBuilder();
        var prioritiesRepo = new PrioritiesRepository();

        employeeId = (employeeId == 0) ? employeeId : prioritiesRepo.GetPriorityInfo(0, employeeId, CurrentSession.QUser.FullName, CurrentSession.SessionId, false).OwnerId;

        using (var db = new DBCommand("GetSupervisorsPrioritySchedule")
            .Add("@supervisorId", CurrentSession.QUser.Id)
            .Add("@employeeId", employeeId))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left;'>Supervisor</th><th style='text-align:left;'>Employee</th><th style='text-align:left;'>Schedule Day</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left;'>Employee</th><th style='text-align:left;'>Schedule Day</th></tr>");
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                sb.Append("<tr bgcolor='#ffffff'>");
                // sb.Append("<td style='text-align:left;'>" + row["SupervisorName"].ToString() + "</td>");
                sb.Append("<td style='text-align:left;'>" + row["EmployeeName"].ToString() + "</td>");
                //sb.Append("<td style='text-align:left;'>" + GetWeekDay(row["ReportDay"].ToString()) + "</td>");
                sb.Append("<td style='text-align:left;'>" + GetWeekDay(row["DaysOfWeek"].ToString()) + " " + DateTime.Parse(row["TimesOfDay"].ToString()).ToString("hh:mm tt") + "</td>");
                sb.Append("</tr>");

            }
        }

        return sb.ToString();

    }

    [WebMethod(EnableSession = true)]
    public string GetEmployeePrioritySchedule()
    {
        var sb = new System.Text.StringBuilder();

        using (var db = new DBCommand("GetEmployeePrioritySchedule").Add("@employeeId", CurrentSession.QUser.Id))
        {
            if (db.ExecuteDataSet().Tables.Count > 0 && db.ExecuteDataSet().Tables[0].Rows.Count > 0)
            {
                sb.Append("<div style='width:200px;background-color:#b0c4de; text-align: center;'><b>Priority Schedule</b></div>");
                sb.Append("<table style='width:200px;'>");

                foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
                {
                    sb.Append("<tr bgcolor='#ffffff'>");

                    sb.Append("<td style='text-align:left;'>" + GetWeekDay(row["DaysOfWeek"].ToString()) + " " + DateTime.Parse(row["TimesOfDay"].ToString()).ToString("hh:mm tt") + "</td>");
                    sb.Append("</tr>");
                }
                sb.Append("</table>");
            }
        }

        return sb.ToString();
    }

    [WebMethod(EnableSession = true)]
    public string GetEmployeesForSupervisor()
    {
        var sb = new System.Text.StringBuilder();
        var supervisorRepo = new SupervisorRepository();

        var employeeList = supervisorRepo.GetSupervisedUsers(QProcess.Session.CurrentSession.QUser.Id);
        foreach (var item in employeeList)
            sb.Append("<option value=\"" + item.ID + "\">" + item.Name + "</option>");

        return sb.ToString();
    }

    public bool IsReportLate(string sentDate, string duedate, int reportsPerWeek)
    {
        bool isLate = false;
        if (reportsPerWeek != 1)
        {
            if (String.IsNullOrEmpty(sentDate) || (DateTime.Parse(sentDate) > DateTime.Parse(duedate)))
            {
                isLate = true;
            }
        }

        return isLate;
    }

    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> SaveSupervisorsPrioritiesReportSchedule(string day, string offsetDays)
    {
        using (var db = new DBCommand("InsertSupervisorsPrioritiesReportSchedule"))
        {
            db.Add("@userId", CurrentSession.QUser.Id);

            db.Add("@daysOfWeek", day);

            db.Add("offsetDays", offsetDays);
            db.ExecuteNonQuery();
        }

        return GetSupervisorPriorityReportSchedule();
    }

    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> GetSupervisorPriorityReportSchedule()
    {
        var priorityList = new List<PrioritySchedule>();


        using (var db = new DBCommand("GetSupervisorPriorityReportSchedule"))

        {

            {

                foreach (DataRow row in db.Add("@supervisorId", CurrentSession.QUser.Id).ExecuteDataSet().Tables[0].Rows)
                {
                    var schedule = new PrioritySchedule();
                    schedule.ScheduleID = Int32.Parse(row["ScheduleId"].ToString());
                    schedule.SupervisorID = Int32.Parse(row["SupervisorID"].ToString());

                    schedule.DaysOfWeek = GetWeekDay(row["DaysOfWeek"].ToString());
                    schedule.OffsetDays = Int32.Parse(row["DaysOffset"].ToString());


                    priorityList.Add(schedule);
                }
            }
        }

        return priorityList;

    }

    [WebMethod(EnableSession = true)]
    public List<PrioritySchedule> DeleteSupervisorPriorityReportSchedule(int scheduleId)
    {

        using (var db = new DBCommand("DeleteSupervisorPriorityReportSchedule"))
        {
            db.Add("@scheduleId", scheduleId);

            db.ExecuteNonQuery();
        }
        return GetSupervisorPriorityReportSchedule();
    }


    [WebMethod(EnableSession = true)]
    public string GetPriorityListScheduleReportAll(string timeSpan)
    {

        var sb = new System.Text.StringBuilder();
        string startDate = string.Empty;
        string endDate = string.Empty;
        if (timeSpan.Equals("Last 30 Days"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            startDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-30).Date.ToString();

        }
        else if (timeSpan.Equals("Last 365 Days"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            startDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-365).Date.ToString();

        }
        else if (timeSpan.Equals("YTD"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            int year = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Year;
            startDate = new DateTime(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Year, 1, 1).Date.ToString();

        }

        using (var db = new DBCommand("GetPriorityList_LateCount_Charge").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Employee</th><th style='text-align:left'># of Times Late " + timeSpan + "</th><th style='text-align:left'>Penalty Charged " + timeSpan + "</th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["Employee"].ToString());

            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {

                sb.Append("<tr bgcolor='#ffffff'>");
                sb.Append("<td style='text-align:left;'>" + row["FullName"] + "</td>");
                sb.Append("<td style='text-align:left;'>" + row["LateCount"] + "</td>");
                sb.Append("<td style='text-align:left;'>$" + row["LateCharge"] + "</td>");
                sb.Append("</tr>");
            }

        }


        return sb.ToString();

    }

    [WebMethod(EnableSession = true)]
    public void EmailPriorityListScheduleReportAll(string timeSpan)
    {
        var sb = new System.Text.StringBuilder();
        sb.Append("<html>");
        sb.Append("<body>");
        sb.Append("<table style='width:650px;'>");
        sb.Append(GetPriorityListScheduleReportAll(timeSpan));
        sb.Append("</table>");
        sb.Append("</body>");
        sb.Append("</html>");
        using (var db = new DBCommand("master.dbo.xp_smtp_sendmail").Add("@from", AppSettings.FromAddress).Add("@to", CurrentSession.QUser.Email).Add("@subject", AppSettings.AppName + "PriorityLateReport").Add("@message", sb.ToString())
                                   .Add("@type", "text/html"))
        {
            db.ExecuteNonQuery();

        }

    }

    [WebMethod(EnableSession = true)]
    public int GetRoleId()
    {
        int roleId = 0;

        var dt = new DBCommand("APP_SpecificPermissions_SELECT", AppSettings.Get("PermissionsDB").ToString())
                     .Add("@UserID", CurrentSession.QUser.Username)
                     .Add("@AppID", "Qprocess")
                     .Add("@permissionType", "late report")
                    .ExecuteDataSet().Tables[0];

        if (dt.Rows.Count == 1)
        {
            var row = dt.Rows[0];
            roleId = Int32.Parse(row["permissionValue"].ToString());
        }
        return roleId;
        //return 2;//this is just for testing.Don't put it in production
    }



    [WebMethod(EnableSession = true)]
    public string GetPriorityListScheduleReportExcuse(string startDate, string endDate)
    {

        var sb = new System.Text.StringBuilder();

        using (var db = new DBCommand("GetMisssedPriorityLists").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'></th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["Employee"].ToString());

            foreach (var group in employeeGroups)
            {

                // int lateCount = 0;
                foreach (var row in group.OrderByDescending(rec => DateTime.Parse(rec["LateDate"].ToString())))
                {
                    //string isLate = "No";
                    //if ((String.IsNullOrEmpty(row["SentDate"].ToString()) && DateTime.Parse(row["ScheduledDate"].ToString()) < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) || (!String.IsNullOrEmpty(row["SentDate"].ToString()) && DateTime.Parse(row["SentDate"].ToString()) > DateTime.Parse(row["ScheduledDate"].ToString())))
                    {
                        //if (String.IsNullOrEmpty(row["IsExcludedReason"].ToString()))
                        {
                            // lateCount++;
                            //isLate = "Yes";
                            sb.Append("<tr bgcolor='#ffffff'>");
                            //sb.Append("<td style='text-align:left;'>" + row["Supervisor"].ToString() + "</td>");
                            sb.Append("<td style='text-align:left;'>" + row["Employee"].ToString() + "</td>");
                            //sb.Append("<td style='text-align:left;'>" + row["ReportDate"].ToString() + "</td>");
                            sb.Append("<td style='text-align:left;'>" + DateTime.Parse(row["LateDate"].ToString()).ToShortDateString() + "</td>");
                            //sb.Append("<td style='text-align:left;'>" + row["SentDate"].ToString() + "</td>");
                            sb.Append("<td style='text-align:left;'><input type='button' onclick='ExcusePriorityLate(" + "\"" + row["Employee"].ToString() + "\"" + "," + "\"" + DateTime.Parse(row["LateDate"].ToString()).ToShortDateString() + "\"" + ")'" + " value='Excuse' /></td>");


                            sb.Append("</tr>");
                        }
                    }





                }


            }




        }

        return sb.ToString();

    }

    [WebMethod(EnableSession = true)]
    public void ExcusePriorityLate(string employee, string scheduledDate)
    {
        using (var db = new DBCommand("PriorityList_Exclude_Supervisor_Excuse_Insert"))
        {
            db.Add("@supervisorId", CurrentSession.QUser.Id);

            db.Add("@employee", employee);

            db.Add("@excludedDate", scheduledDate);
            db.ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public string GetOverdueTasksForQuickDeadlineExtension()
    {
        var sb = new System.Text.StringBuilder();
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;
        using (var db = new DBCommand("QCheck_GetOverdueTasks_Extension").Add("@userId", CurrentSession.QUser.Id))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                sb.Append("<div>Task: <b>" + row["Name"] + "</b></div>");
                sb.Append("<div>New Deadline: <b>" +
                        (row["NewDueTime"] != DBNull.Value
                        ? myTz.GetLocalTime(Convert.ToDateTime(row["NewDueTime"])).ToString("M/d/yyyy h:mm tt")
                        : "") + "</b></div>");
                sb.Append("<div style='padding-bottom:10px;'></div>");


            }
        }

        return sb.ToString();
    }

    [WebMethod(EnableSession = true)]
    public void SendRequestsForOverdueTaskExtensions(string comment)
    {
        if (comment.Trim().Length > 0)
        {
            comment = "[UNIVERSAL EXTENSION]--" + comment;
        }
        else
        {
            comment = "[UNIVERSAL EXTENSION]";
        }
        using (var db = new DBCommand("QCheck_RequestExtensionsForOverDueTasks").Add("@userId", CurrentSession.QUser.Id).Add("@comment", comment))
        {
            db.ExecuteNonQuery();
        }
    }



    [WebMethod(EnableSession = true)]
    public string GetUniversalExtensionChangeRequests()
    {
        var sb = new System.Text.StringBuilder();
        var changeRequestRepo = new ChangeRequestRepository();
        var supervisorChangeRequests = changeRequestRepo.GetSupervisorChangeRequestsForUniversalExtension(CurrentSession.QUser.Id).ToList();
        foreach (var changeRequest in supervisorChangeRequests)
        {

            changeRequest.ChangedItems = changeRequestRepo.GetChangedItems(changeRequest.ID).ToList();

        }

        var groupChangeRequests = supervisorChangeRequests.GroupBy(req => req.FullName);

        foreach (var group in groupChangeRequests)
        {
            string changeRequestIds = string.Empty;
            foreach (var changeRequest in group)
            {
                changeRequestIds += changeRequest.ID + ";";
            }
            sb.Append("<table class='dataUnivExt'>");
            sb.Append("<tr><td colspan='3' class='groupname'>" + group.ElementAt(0).FullName + "<input style='margin-left:10px;' class='btn btn-default btn-sm' type='button' value='Approve' onclick='ApproveChangeRequests(" + "\"" + changeRequestIds + "\"" + ")'" + "/>" +
                       "<input  style='margin-left:10px;' class='btn btn-default btn-sm' type='button' value='Deny'onclick='DenyChangeRequests(" + "\"" + changeRequestIds + "\"" + ")'" + "/>" + "</td></tr>");
            sb.Append("<tr><th class='dataUnivExt'>Date</th><th class='dataUnivExt' style='width:300px;'>Task</th><th class='dataUnivExt'>Request Type/Comments</th></tr>");
            foreach (var changeRequest in group)
            {
                var changeRequestText = "Change " + changeRequest.ChangedItems[0].ItemName.ToLower() + " from " + changeRequest.ChangedItems[0].Current + " to " + changeRequest.ChangedItems[0].Requested;
                sb.Append("<tr><td class='dataUnivExt'>" + changeRequest.RequestDate + "</td><td class='dataUnivExt'>" + changeRequest.ChecklistName + "</td><td class='dataUnivExt'>"
                           + changeRequestText + "<br>" + changeRequest.Comment + "</td></tr>");



            }
            sb.Append("</table>");

        }


        return sb.ToString();
    }


    [WebMethod(EnableSession = true)]
    public void ApproveUniversalExtensionRequests(string changeIds)
    {

        using (var db = new DBCommand("QCheck_Approval_UniversalExtension").Add("@Command", "Y").Add("@ChangeID", changeIds).Add("@ControllerEmail", CurrentSession.QUser.Email))
        {

            db.ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public void DenyUniversalExtensionRequests(string changeIds)
    {

        using (var db = new DBCommand("QCheck_Approval_UniversalExtension").Add("@Command", "N").Add("@ChangeID", changeIds).Add("@ControllerEmail", CurrentSession.QUser.Email))
        {

            db.ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public void AddTaskToPriorityList(int instanceId)
    {

        using (var cmd = new CmdObj("Qcheck_AddComplexTaskToPriorities"))
        {
            cmd.Add("@userID", CurrentSession.QUser.Id);
            cmd.Add("@instanceId", instanceId);
            cmd.ExecuteNonQueryWithOutput();
        }

    }

    [WebMethod(EnableSession = true)]
    public string GetOverdueTasksExcuse(string startDate, string endDate, string employee)
    {
        var sb = new System.Text.StringBuilder();
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        using (var db = new DBCommand("GetOverdueTasks_Report").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate).Add("@Assignee", employee))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left;width:20px;'>Employee</th><th style='text-align:left;width:230px;'>Overdue Task</th><th style='text-align:left;width:110px;'>Due Date</th><th style='text-align:left;width:110px;'>Completed Same Day</th><th></th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["AssigneeName"].ToString());

            foreach (var group in employeeGroups)
            {

                int lateCount = 0;
                foreach (var row in group.OrderByDescending(rec => DateTime.Parse(rec["DueDate"].ToString())))
                {
                    lateCount++;
                    sb.Append("<tr bgcolor='#ffffff'>");

                    sb.Append("<td style='text-align:left;'>" + row["AssigneeName"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + row["TaskName"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + myTz.GetLocalTime(Convert.ToDateTime(row["DueDate"])).ToString("M/d/yyyy h:mm tt") + "</td>");
                    sb.Append("<td style='text-align:left;'>" +
                        (row["CompletedDate"] != DBNull.Value
                        ? myTz.GetLocalTime(Convert.ToDateTime(row["CompletedDate"])).ToString("M/d/yyyy h:mm tt")
                        : "") + "</td>");
                    sb.Append("<td style='text-align:left;'><input type='button' onclick='ExcuseOverDueTask(" + "\"" + row["Id"].ToString() + "\"" + "," + "\"" + row["DueDate"].ToString() + "\"" + ")'" + " value='Excuse' /></td>");//added by venkat 04/18/2018
                    sb.Append("</tr>");

                }

                // sb.Append("<tr><td></td><td></td><td style='color:Red'><b>Total Late Count:" + lateCount + "</b></td><td></td></tr>");
            }



        }


        return sb.ToString();

    }

    [WebMethod(EnableSession = true)]
    public void ExcuseOverdueTask(int id, string dueDate)
    {
        using (var db = new DBCommand("Excuse_OverdueTask"))
        {
            db.Add("@Id", id);
            db.Add("@excusedBy", CurrentSession.QUser.Id);//added by venkat 02/23/2018
            db.Add("@DueDate", dueDate);


            db.ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public string GetAllActiveEmployees()
    {

        var sb = new System.Text.StringBuilder();
        var prioritiesRepo = new PrioritiesRepository();

        var employeeList = prioritiesRepo.GetPrioritySets(CurrentSession.QUser.Id, 0).ToList().Where(rec => rec.Name != CurrentSession.QUser.FullName);

        using (var db = new DBCommand("QCheck_GetActiveEmployees"))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                sb.Append("<option value=\"" + row["ID"] + "\">" + row["FullName"] + "</option>");

            }
        }


        return sb.ToString();

    }
    [WebMethod(EnableSession = true)]
    public string GetOverdueTaskChargesReport(string timeSpan)
    {
        var sb = new System.Text.StringBuilder();
        string startDate = string.Empty;
        string endDate = string.Empty;
        if (timeSpan.Equals("Last 30 Days"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            startDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-30).Date.ToString();

        }
        else if (timeSpan.Equals("Last 365 Days"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            startDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-365).Date.ToString();

        }
        else if (timeSpan.Equals("YTD"))
        {
            endDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            int year = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Year;
            startDate = new DateTime(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Year, 1, 1).Date.ToString();

        }

        using (var db = new DBCommand("GetOverdueTaskChargesReport").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Employee</th><th style='text-align:left'># of Times Overdue " + timeSpan + "</th><th style='text-align:left'>Penalty Charged " + timeSpan + "</th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["Employee"].ToString());

            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {

                sb.Append("<tr bgcolor='#ffffff'>");
                sb.Append("<td style='text-align:left;'>" + row["AssigneeName"] + "</td>");
                sb.Append("<td style='text-align:left;'>" + row["LateCount"] + "</td>");
                sb.Append("<td style='text-align:left;'>$" + row["LateCharge"] + "</td>");
                sb.Append("</tr>");
            }

        }


        return sb.ToString();

    }
    [WebMethod(EnableSession = true)]
    public string GetOverdueTasksReport(string startDate, string endDate, string employee)
    {
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        var sb = new System.Text.StringBuilder();

        using (var db = new DBCommand("GetOverdueTasks_Report").Add("@ReportStartDate", startDate).Add("@ReportEndDate", endDate).Add("@Assignee", employee))
        {
            //sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left'>Supervisor</th><th style='text-align:left'>Employee</th><th style='text-align:left'>Due Date</th><th style='text-align:left'>Sent Date</th><th style='text-align:left'>Is Late</th></tr>");
            sb.Append("<tr bgcolor='#b0c4de'><th style='text-align:left;width:20px;'>Employee</th><th style='text-align:left;width:230px;'>Overdue Task</th><th style='text-align:left;width:100px;'>Due Date</th><th style='text-align:left;width:100px;'>Completed Same Day</th></tr>");
            var employeeGroups = db.ExecuteDataSet().Tables[0].AsEnumerable().GroupBy(rec => rec["AssigneeName"].ToString());

            foreach (var group in employeeGroups)
            {

                int lateCount = 0;
                foreach (var row in group)
                {
                    lateCount++;
                    sb.Append("<tr bgcolor='#ffffff'>");

                    sb.Append("<td style='text-align:left;'>" + row["AssigneeName"].ToString() + "</td>");

                    sb.Append("<td style='text-align:left;'>" + row["TaskName"].ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" + myTz.GetLocalTime(Convert.ToDateTime(row["DueDate"])).ToString() + "</td>");
                    sb.Append("<td style='text-align:left;'>" +
                        (row["CompletedDate"] != DBNull.Value
                        ? myTz.GetLocalTime(Convert.ToDateTime(row["CompletedDate"])).ToString("M/d/yyyy h:mm tt")
                        : "") + "</td>");

                    sb.Append("</tr>");

                }

                sb.Append("<tr><td></td><td></td><td style='color:Red'><b>Total Late Count:" + lateCount + "</b></td><td></td></tr>");
            }



        }


        return sb.ToString();

    }

    // Update status report preference when creting complex task
    [WebMethod(EnableSession = true)]
    public void UpdateStatusReport(string statusReport, string statusReportSection)//added by venkat 06/15/2018
    {
        var userRepo = new UserRepository();
        userRepo.AddPreference(CurrentSession.QUser.Id, "StatusReport", statusReport);
        userRepo.AddPreference(CurrentSession.QUser.Id, "StatusReportSection", statusReportSection);
    }

    [WebMethod]
    public void ReAssignTasksWithQptPreferences(string activeChecklistId, string assigneeGroupId, string assignedById)
    {


        using (var cmd = new CmdObj("Util_ReAssignTaskWithQPTPrefs"))
        {
            cmd.Add("@ActiveChecklistId", activeChecklistId);
            cmd.Add("@AssigneeGroupId", assigneeGroupId);
            cmd.Add("@AssignedById", assignedById);
            cmd.ExecuteNonQueryWithOutput();
        }
    }

    [WebMethod(EnableSession = true)]
    public void TemporaryAssignment_Add(int ReplacingID, int TempGroupID, DateTime TempAssignmentStart, DateTime TempAssignmentEnd)
    {
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        using (var cmd = new DBCommand("QCheck_AssignmentsTemporary_Add"))
        {
            cmd.Add("@ReplacingID", ReplacingID);
            cmd.Add("@TempGroupID", TempGroupID);
            cmd.Add("@TempAssignmentStart", myTz.GetSystemTime(TempAssignmentStart));
            cmd.Add("@TempAssignmentEnd", myTz.GetSystemTime(TempAssignmentEnd));
            cmd.Add("@CreatedBy", CurrentSession.QUser.Id);
            cmd.ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public void TemporaryAssignment_AddBulk(List<int> replacingIDs, int tempGroupID, DateTime TempAssignmentStart, DateTime TempAssignmentEnd)
    {
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        TempAssignmentStart = TempAssignmentStart.AddHours(12).AddMinutes(35);
        TempAssignmentEnd = TempAssignmentEnd.AddHours(12).AddMinutes(40);
        foreach (var ReplacingID in replacingIDs)
        {
            using (var cmd = new DBCommand("QCheck_AssignmentsTemporary_Add"))
            {
                cmd.Add("@ReplacingID", ReplacingID);
                cmd.Add("@TempGroupID", tempGroupID);
                cmd.Add("@TempAssignmentStart", myTz.GetSystemTime(TempAssignmentStart));
                cmd.Add("@TempAssignmentEnd", myTz.GetSystemTime(TempAssignmentEnd));
                cmd.Add("@CreatedBy", CurrentSession.QUser.Id);
                cmd.ExecuteNonQuery();
            }
        }
    }

    [WebMethod(EnableSession = true)]
    public TemporaryAssignment[] TemporaryAssignment_GetList(DateTime TempAssignmentStart, DateTime TempAssignmentEnd, int AssignmentType, int? UserId = null)
    {
        List<TemporaryAssignment> responses = new List<TemporaryAssignment>();
        var myTz = QProcess.Session.CurrentSession.UserTimeZone;

        using (var db = new DBCommand("QCheck_AssignmentsTemporary_GetList")
            .Add("@UserID", UserId ?? CurrentSession.QUser.Id)
            .Add("@TempAssignmentStart", TempAssignmentStart)
            .Add("@TempAssignmentEnd", TempAssignmentEnd)
            .Add("@AssignmentType", AssignmentType))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                var response = new TemporaryAssignment();
                response.AssignmentID = row["AssignmentID"].ToIntEx().Value;
                response.TaskName = row["TaskName"].ToBlank();
                response.TempGroupName = row["TempGroup"].ToBlank();
                response.Assignees = row["Assignees"].ToBlank();
                response.TempAssignmentStart = myTz.GetLocalTime(Convert.ToDateTime(row["TempAssignmentStart"])).ToBlank();
                response.TempAssignmentEnd = myTz.GetLocalTime(Convert.ToDateTime(row["TempAssignmentEnd"])).ToBlank();
                responses.Add(response);
            }
        }
        return responses.ToArray();
    }

    [WebMethod(enableSession: true)]
    public string GetAllApiKeys()
    {
        var timeZone = CurrentSession.UserTimeZone;

        var ApiKeys = new List<ApiKey>();
        using (var db = new DBCommand("QCheck_RetrieveAPIKey"))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                var key = new ApiKey
                {
                    ID = (Guid)row["ID"],
                    Api_Key = row["Api_Key"].ToString(),
                    Requestor = row["Requestor"].ToString(),
                    Approver = row["Approver"].ToString(),
                    OnBehalfOf = row["OnBehalfOf"].ToString(),
                    Intent = row["Intent"].ToString(),
                    Issued = timeZone.GetLocalTime((DateTime)row["Issued"]),
                    Expires = timeZone.GetLocalTime((DateTime)row["Expires"]),
                    NotBefore = timeZone.GetLocalTime((DateTime)row["NotBefore"]),
                    IsRevoked = (bool)row["IsRevoked"]
                };

                ApiKeys.Add(key);
            }
            string result = JsonConvert.SerializeObject(ApiKeys);

            return result;
        }
    }

    [WebMethod(enableSession: true)]
    public string RevokeApiKey(Guid apiKey)
    {
        using (var cmd = new CmdObj("API_RevokeApiKey"))
        {
            cmd.Add("@KeyID", apiKey);
            cmd.ExecuteNonQueryWithOutput();
            return "Key has been revoked";

        }

    }

    [WebMethod(EnableSession = true)]
    public string GetAllSigningKeys()
    {
        var timeZone = CurrentSession.UserTimeZone;

        var ApiKeys = new List<ApiKey>();
        using (var db = new DBCommand("API_GetAllSigningKey"))
        {
            foreach (DataRow row in db.ExecuteDataSet().Tables[0].Rows)
            {
                var key = new ApiKey
                {
                    ID = (Guid)row["ID"],
                    Api_Key = row["Key"].ToString(),
                    AsOf = timeZone.GetLocalTime((DateTime)row["AsOf"]),
                    IsRevoked = (bool)row["IsRevoked"]
                };

                ApiKeys.Add(key);
            }
            string result = JsonConvert.SerializeObject(ApiKeys);
            return result;
        }

    }

    [WebMethod(enableSession: true)]
    public string RevokeSigningApiKey(Guid apiKey)
    {
        using (var cmd = new CmdObj("API_RevokeSigningApiKey"))
        {
            cmd.Add("@KeyID", apiKey);
            cmd.ExecuteNonQueryWithOutput();
            return "Key has been revoked";

        }

    }

    [WebMethod(EnableSession = true)]
    public int GetNotificationCount()
    {
        using (var db = new DBCommand("QCheck_Notification_GET"))
        {
            return (int)db.Add("@userId", GetUserID()).ExecuteScalar();
        }
    }

    [WebMethod(EnableSession = true)]
    public string GetNotification()
    {
        ClearNotification();

        var result = new StringBuilder();
        using (var db = new DBCommand("QCheck_Notification_GET"))
        {
            var dt = db.Add("@userId", GetUserID()).Add("@countOnly", false).ExecuteDataSet().Tables[0];
            foreach (DataRow row in dt.Rows)
                result.Append(row[0].ToString());
        }

        return result.ToString();
    }

    [WebMethod(EnableSession = true)]
    public string ClearNotification()
    {
        using (var db = new DBCommand("QCheck_Notification_SET"))
        {
            return (string)db.Add("@userId", GetUserID()).Add("@isClear", true).ExecuteScalar();
        }
    }

    [WebMethod(EnableSession = true)]
    public void ReadNotification(string id)
    {
        using (var db = new DBCommand("QCheck_Notification_SET"))
        {
            db.Add("@id", id).ExecuteNonQuery();
        }
    }

    [WebMethod(EnableSession = true)]
    public void DeleteNotification(string id)
    {
        using (var db = new DBCommand("QCheck_Notification_SET"))
        {
            db.Add("@id", id).Add("@isDeleted", true).ExecuteNonQuery();
        }
    }
}
public class ResultAndTimestamp<T>
{
    public T Result { get; set; }
    public DateTime Timestamp { get; set; }
    public string TimeString
    {
        get => Timestamp.ToString("MM/dd/yyyy h:mm:ss tt");
        set { Timestamp = DateTime.Parse(value); }
    }

    public ResultAndTimestamp() { }
}

public static class ResultAndTimestamp
{
    public static ResultAndTimestamp<T> Create<T>(T result, DateTime? timeStamp = null)
    {
        return new ResultAndTimestamp<T>
        {
            Result = result,
            Timestamp = timeStamp ?? DateTime.UtcNow
        };
    }
}

/* Copyright © 2024 Renegade Swish, LLC */

