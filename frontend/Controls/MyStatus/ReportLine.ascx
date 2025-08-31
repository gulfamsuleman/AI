<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportLine.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_ReportLine" %>
<%@ Import Namespace="QProcess.Configuration" %>
<%@ Import Namespace="QProcess.Enums" %>
<%@ Register TagPrefix="shared" TagName="CommentList" Src="~/Controls/Shared/CommentList.ascx" %>

<% if (Line.LineType == ReportLine.Type.Header){ %>
	<table id="statusReportHeader" class="status-table">
		<tr class="report-line-header report-line-border">
			<td colspan="7"><%= Line.Description %></td>
		</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Subheader){ %>
	<table class="status-table collapsible-item" data-collapse-state="expanded">
		<thead>
			<tr>
				<td colspan="7" class="report-line-subheader noselect <%=Line.NativeType.HasValue && Line.NativeType.Value==2 ? "completed-task" : ""%>" data-section="<%= Line.SectionID %>" 
					<%= Line.Description != "General Comments" && !Line.Description.Contains("Completed") ? "contextmenu='subheader-menu'" : "" %>>
					<i class='fa fa-minus-square-o' data-collapse-target="true" data-role='expand-indicator'></i>
					<a href="#" data-role="section-head" <%=Line.NativeType.HasValue && Line.NativeType.Value==0 ? " data-action=\"new-task\"" : ""%> data-id="<%= Line.SectionID %>"><%= Line.Description %></a></td>
			</tr>
		</thead>
		<tbody class="expanded">
<% } %>

<%else if (Line.LineType == ReportLine.Type.Headings) { %>
	<tr class="report-line-content multiple-collapse-member report-header-column">
		<th class="report-line-headings report-line-border report-line-headings-action"></th>
		<th class="report-line-headings report-line-border report-line-headings-priority"></th>
		<th class="report-line-headings report-line-border report-line-headings-task" style="width:<%:TaskWidth.ToString()%>%;">Task</th>
		<th class="report-line-headings report-line-border report-line-headings-deadline">Due</th>
		<th class="report-line-headings report-line-border report-line-headings-assignees hidden">Assignees/Controllers</th>
		<th class="report-line-headings report-line-border report-line-headings-progress" style="width:<%:(80-TaskWidth).ToString()%>%;">Progress</th>
	</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Spacer){ %>
	<tr class="report-line-spacer">
		<td colspan="7"></td>
	</tr>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Ender){ %>
		<tr class="report-line-ender">
			<td colspan="7"></td>
		</tr>
		</tbody>
	</table>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Comments){ %>
<% } %>

<%else if (Line.LineType == ReportLine.Type.Task && Line.MyTaskType == TaskType.GeneralComment){ %>
	<tr class="report-line-content multiple-collapse-member"
		data-id="<%= Line.ID %>"
		data-general="true">
		<td colspan="7" class ="report-line-task-general-comment report-line-border" data-role="comments">
			<% if (Line.Comments != null 
					&& !QProcess.Session.CurrentSession.GetAllCommentsFlag 
					&& Line.Comments.Any(c => c.Date < LastViewed.AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)))) { %>
				<a data-role="expand-general"><img src="/Images/plus.gif" alt="Expand general comments"/></a>			
				<%--<a data-action="injection-point"></a><a data-action="add-comment">...</a>--%>
			<% } //else {%>
			<shared:CommentList LastViewed=<%#LastViewed %> Comments=<%# Line.Comments %> runat="server" />
			<% //} %>
		</td>
	</tr>
<% } %>

<%else if(Line.LineType == ReportLine.Type.Task) { %>
	<tr class="report-line-content multiple-collapse-member" 
		data-state="view"
		data-id="<%= Line.ID %>" 
		data-priority=<%= Line.Priority.HasValue ? Line.Priority.Value.ToString() : "" %>
		data-due-date=<%= Line.DueDate.HasValue ? Line.DueDate.Value.ToShortDateString() : "" %> 
		<%= Line.ReminderDate.HasValue ? "data-soft-due="+"'"+Line.ReminderDate.Value.ToShortDateString()+"'": "" %>>
	<%if (Line.MyTaskType == TaskType.Deleted){ %>
		<td class="report-line-border" data-role="action"><span class="hidden data-label">Action</span><a data-role="restore-task" title="Restore Task"><img src="/Images/reopen_sm.gif" /></a></td>
	<% } else if (Line.MyTaskType == TaskType.Completed){ %>
		<td class="report-line-border" data-role="action"><span class="hidden data-label">Action</span><a data-role="reopen-task" title="Reopen Task"><img src="/Images/reopen_sm.gif" /></a></td>
	<% } else { /*LineType = Task, MyTaskType = Normal*/%> 
		<td class="report-line-border" nowrap data-role="action"><span class="hidden data-label">Action</span>
            <a data-role="complete-task" title="Complete Task"><img src="/Images/complete.gif" /></a>
            <a data-role="na" title="N/A - Close Task"><i class="fa" style="color:#FF2551" >n/a</i></a><br />
            <div class="na-row">
                <textarea class="na-reason" placeholder="Reason for N/A" rows="5"></textarea><br />
                <a data-role="na-submit" class="btn btn-default"><i class="fa fa-ban" style="color:#FF2551" ></i> N/A - Close Task</a>
            </div>
		</td>
	<% } %>
		<td class="report-line-border" data-action="add-comment" data-role="priority" style="min-width: 50px;"><span class="hidden data-label">Priority</span><%= Line.Priority.HasValue ? Line.Priority.Value.ToString() : "" %></td>
		<td class="report-line-border" data-role="task-name" contextmenu="task-menu"><span class="hidden data-label">Task</span>
            <a href="#" data-action="single-checklist">
                <%= Line.Description %>
            </a>
            <% if(Line.IsRecurring) { %><i class="fa fa-refresh recurring-indicator"></i><% } %> <%--added by venkat--%>
			<input type="text" style="display:none;" value="<%= Line.Description %>" />
            <input type="hidden" class="is-daily" value="<%=Line.IsDaily %>" />
		</td>
		<td class="report-line-border" data-role="due-date"><span class="hidden data-label">Due</span>
			<%if(Line.ReminderDate.HasValue){%>
				<span class="reminderspan" data-action="add-comment"><%=Line.ReminderDate.Value.ToShortDateString()%></span>
			<%}%>
			<span<%= (Line.DueDate.HasValue && Line.DueDate.Value.Date <= QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow() && Line.MyTaskType != TaskType.Completed && Line.MyTaskType != TaskType.Deleted) ? " class=\"overduespan\"" : "" %> data-action="add-comment"><%= Line.DueDate.HasValue ? Line.DueDate.Value.ToShortDateString() : "" %></span>
		</td>
		<td class="report-line-border report-line-assignees-content hidden" data-role="assignees"><span class="hidden data-label">Assignees/Controllers</span>
           <span data-role="assignees-span"><%= Line.AssignedTo %> / <span data-role="controllers-span"><%=Line.Controllers %></span>
                     <%if (!(Line.Controllers.Contains(QProcess.Session.CurrentSession.QUser.FullName))){ %>
                        <%= TakeControlButton()%>
                       <%} %>
           </span>
			
		</td>
		<td class="report-line-border" data-role="comments" ><span class="hidden data-label">Progress</span>
			<% if (Line.HasRelatedComments) { %>
				<a href="#" onclick="ShowRelatedComments(<%# Line.ID %>);">Related Comments</a><br />
			<% } %>
			<% if (Line.Comments != null && !QProcess.Session.CurrentSession.GetAllCommentsFlag && Line.Comments.Any(c => c.Date < LastViewed.AddDays(-1*Convert.ToInt32(AppSettings.VisibleCommentsDays)))) { %>
				<a data-role="expand-task"><img src="/Images/plus.gif" alt="Expand task level comments"/></a>
			<% } %>
			<shared:CommentList LastViewed=<%#LastViewed %> Comments=<%# Line.Comments %> runat="server" />
		</td>
	</tr>
<% } %>
<!-- Copyright © 2024 Renegade Swish, LLC -->

