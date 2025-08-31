<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChecklistHeader.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ChecklistHeader" %>

<div class="active-checklist collapsible-item row" data-collapse-state="collapsed" data-status=<%=CompletionCssClass %> data-role="checklist"
	data-unique-id="<%= Checklist.UniqueId %>" 
	data-task-stage="<%= Checklist.TaskStage %>" 
	data-checklist-id="<%= Checklist.ChecklistId %>">
	<div class="title-bar clear-fix" data-collapse-target="true">
		<div class="float-left" ">
			<i class="fa fa-plus-square-o" data-role="expand-indicator"></i>
            	<% if (!Checklist.ControllerPartOfAssignee.Value) { %>
			<span class="checklist-title" style="color:#ee9020" title="<%=Checklist.Name %>"><% if (Checklist.Name.Length > 47) { Response.Write(Checklist.Name.Substring(0, 47) + "..."); } else { Response.Write(Checklist.Name); }  %></span>
            <% } else {%>
            <span class="checklist-title" title="<%=Checklist.Name %>"><% if (Checklist.Name.Length > 47) { Response.Write(Checklist.Name.Substring(0, 47) + "..."); } else { Response.Write(Checklist.Name); }  %></span>
            <%} %>
             
		</div>
		<div>
			<span class="checklist-group"><%=CompletionString %></span>
			<span class="checklist-status"><%=DisplayDate %></span>
			<% if(Checklist.PendingChange) { %><i class="fa fa-forward pending-indicator" title='A new deadline of <%=(Checklist.NewDeadline?.ToShortDateString() + " " + Checklist.NewDeadline?.ToShortTimeString())%> has been requested for this task'></i><% } %>
			<% if(Checklist.IsRecurring) { %><i class="fa fa-refresh recurring-indicator"></i><% } %>
		</div>
	</div>
	<div data-role="checklist-body"></div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

