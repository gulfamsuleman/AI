<%@ Control Language="C#" AutoEventWireup="true" Codebehind="StatusTaskLine.ascx.cs" Inherits="QProcess.Controls.Controls_TaskSummary_StatusTaskLine" %>
<%@ Import Namespace="QProcess.Enums" %>

<% if (Line.LineType == ReportLine.Type.Header){ %>
	<tr class="report-line-header report-line-border">
		<td colspan="9"><%= Line.Description %></td>
	</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Subheader){ %>
	<tr <%= Line.MyTaskType == TaskType.Normal ? string.Format("data-drop-sid=\"{0}\"", Line.ID) : "" %>>
		<td colspan="9" class="report-line-subheader"><%= Line.Description %></td>
	</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Headings){ %>
	<tr class="report-line-content multiple-collapse-member" <%= Line.MyTaskType == TaskType.Normal ? string.Format("data-drop-sid=\"{0}\"", Line.ID) : "" %>>
		<th class ="report-line-headings report-line-border report-line-headings-action"></th>
		<th class ="report-line-headings report-line-border report-line-headings-priority"></th>
		<th class ="report-line-headings report-line-border report-line-headings-task">Task</th>
		<th class ="report-line-headings report-line-border report-line-headings-deadline">Deadline</th>
		<th class ="report-line-headings report-line-border report-line-headings-assignees">Assigned To</th>
		<th class ="report-line-headings report-line-border report-line-headings-controllers">Controllers</th>
		<th class ="report-line-headings report-line-border report-line-headings-frequency">Frequency</th>
		<th class ="report-line-headings report-line-border report-line-headings-last-completed">Last Completed</th>
		<th class ="report-line-headings report-line-border report-line-headings-next-due-time">Next Due Time</th>
	</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Spacer){ %>
	<tr class="report-line-spacer">
		<td colspan="9"></td>
	</tr>
<% } %>

<%else if(Line.LineType == ReportLine.Type.Task) { %>
	<tr class="report-line-content" 
		data-instance-id="<%#Eval("InstanceId") %>"
		data-active-id="<%= Line.ID %>" 
		data-upcoming-id="<%#Eval("UpcomingId") %>"
		data-history-id="<%#Eval("HistoryId") %>"
		data-history-type="<%#Eval("HistoryType") %>"
		<%= Line.MyTaskType != TaskType.Completed && Line.SectionId.HasValue ? string.Format("data-drop-sid=\"{0}\"", Line.SectionId.Value) : "" %>
		<%= Line.MyTaskType != TaskType.Completed && Line.CommentsId.HasValue ? string.Format("data-drop-from-id=\"{0}\"", Line.CommentsId.Value) : "" %>
		<%= Line.MyTaskType != TaskType.Completed && Line.CommentsId.HasValue ? "data-drop-type=\"2\"" : "" %>
		>
	<%if (Line.MyTaskType == TaskType.Deleted){ %>
		<td class="report-line-border"></td>
	<% } else { /* LineType = Task, MyTaskType = Normal || Completed */%> 
		<td class="report-line-border"><i class="fa fa-arrows" data-role="open-status" <%= Line.MyTaskType != TaskType.Completed && Line.CommentsId.HasValue ? "data-is-dragpoint=\"\"" : "" %>></i></td>
	<% } %>		
		<td class="report-line-border"><%= Line.Priority.HasValue ? Line.Priority.Value.ToString() : "" %></td>
		<td class="report-line-border">
			<a href="#" title="View/Update Current Checklist" data-role="open-current">
				<%= Line.Description %>
			</a>
		</td>
		<td class="report-line-border">
			<span <%=Line.HistoryType == 2 && Line.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() ? "class='highlight'" : "" %>>
				<%= Line.DueDate.HasValue ? Line.DueDate.Value.ToString("G") : "" %>
			</span>
		</td>
		<td class="report-line-border"><%= Line.AssignedTo %></td>
		<td class="report-line-border"><%= Line.Controllers %></td>
		<td class="report-line-border"><%= Line.Frequency %></td>
		<td class="report-line-border">
			<a href="#" title="View/Update Last Completed Checklist" data-role="open-last">
				<%= Line.LastCompleted.HasValue ? Line.LastCompleted.Value.ToString("G") : "" %>
			</a>
		</td>
		<td class="report-line-border">
			<a href="#" title="View Next Scheduled Checklist" data-role="open-next">
				<%= Line.NextDueDate.HasValue ? Line.NextDueDate.Value.ToString("G") : "" %>
			</a>
		</td>
	</tr>
<% } %>
<!-- Copyright © 2024 Renegade Swish, LLC -->

