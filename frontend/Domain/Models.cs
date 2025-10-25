using System;
using QProcess.Domain.Models;
using QProcess.Repositories;

namespace QProcess.Models
{
    public interface IUser
    {
        int Id { get; }
        string Username { get; set; }
		string FullName { get; set; }
        int GroupId { get; set; }
        string AppUrl { get; set; }
        bool IsAdmin { get; set; }
        bool IsBetaUser { get; set; }
        bool IsDepartmentAdmin { get; set; }
        bool IsGradingAdmin { get; set; }
		bool IsApiAdmin { get; set; }
		bool IsOverdueAdmin { get; set; }
		bool IsSupervisor { get; set; }
        int SupervisorStatus { get; set; }
		bool UsesPriorities { get; set; }
		bool ShowComments { get; set; }
		int Font { get; set; }
        int SupervisorId { get; set; }
		int[] AllSupervisors { get; set; }
		string SupervisorName { get; set; }
        string Email { get; set; }
        int? EmpId { get; set; }
		UserTimeZone MyTimeZone { get; set; }
    }

	public interface IGroup
	{
		int Id { get; }
		string Name { get; set; }
		int OwnerId { get; set; }
		bool IsSingleMemberGroup { get; set; }
	}

	public interface IAssignment
	{
		int Id { get; }
		int InstanceId { get; set; }
		int GroupId { get; set; }
		DateTime DateAssigned { get; set; }
	}

	public interface IChecklistItem
	{
		int Id { get; }
		int ChecklistId { get; set; }
		int SequenceNum { get; set; }
		int ItemTypeId { get; set; }
		string Text { get; set; }
		string Url { get; set; }
	}

	public interface IChecklist
	{
		int Id { get; }
		string Name { get; set; }
		int OwnerId { get; set; }
		bool template { get; set; }
	}

	public interface IViewAlert
	{
		string Alertee { get; set; }
		DateTime AlertTime { get; set; }
		string AlertTimeText { get; set; }
		bool IsSent { get; set; }
		string Type { get; set; }
		int TypeId { get; set; }
	}

	public interface IUserGroup
	{
		int Id { get; set; }
		string GroupName { get; set; }
		string Owner { get; set; }
		bool IsMember { get; set; }
		bool IsOwner { get; set; }
	}

	public interface IPreferences
	{
		int Assignee { get; set; }
		int Controller { get; set; }
		int Due { get; set; }
		int ReportOrig { get; set; }
		int Priority { get; set; }
		int Alert { get; set; }
		int SoftDue { get; set; }
	}

	public interface ICalendarChecklist
	{
		bool Active { get; set; }
		int ChangeId { get; set; }
		int ChecklistId { get; set; }
		string ChecklistName { get; set; }
		DateTime DueTime { get; set; }
		int Id { get; set; }
		bool IsAssigned { get; set; }
		bool IsManager { get; set; }
		bool IsRecurring { get; set; }
		DateTime NewDeadline { get; set; }
		bool PendingChange { get; set; }
		DateTime ReminderDate { get; set; }
		TaskStage TaskStage { get; set; }
	}

	public interface ISuggestion
	{
		int Id { get; set; }
		string SuggestionText { get; set; }
		string LoginName { get; set; }
		int DisplayOrder { get; set; }
	}

	public interface IDeduction
	{
		int Id { get; set; }
		string Date { get; set; }
		string Reason { get; set; }
		double Points { get; set; }
		int Type { get; set; }
		bool IsDeleted { get; set; }
	}

	public interface IReportLoadTime
	{
		string User { get; set; }
		int UserId { get; set; }
		string PageName { get; set; }
		int ServerTime { get; set; }
		int ClientTime { get; set; }
		int TotalLoadTime { get; set; }
		DateTime DateTime { get; set; }
		string ReportName { get; set; }
		DateTime LastOpened { get; set; }
		string Browser { get; set; }
	}

    public interface IReportListing
    {
        int ReportID { get; set; }
        string ReportName { get; set; }
        string Controllers { get; set; }
        string SupervisorsIP { get; set; }
    }

	public interface ITaskDetails
	{
		int Id { get; set; }
		string Name { get; set; }
		string NextDue { get; set; }
		string LastCompleted { get; set; }
		string Assignees { get; set; }
		string Controllers { get; set; }
		string Alertees { get; set; }
		string Active { get; set; }
		bool IsHighlighted { get; set; }
	}

	public interface ITaskSummary
	{
		int InstanceId { get; set; }
		int? UpcomingId { get; set; }
		int HistoryType { get; set; }
		int? HistoryId { get; set; }
		string ChecklistName { get; set; }
		string Assignees { get; set; }
		string Controllers { get; set; }
		string Frequency { get; set; }
		DateTime? LastCompleted { get; set; }
		DateTime CurrentDueTime { get; set; }
		int ActiveId { get; set; }
		DateTime? NextDueDate { get; set; }
	}
}
/* Copyright � 2024 Renegade Swish, LLC */

