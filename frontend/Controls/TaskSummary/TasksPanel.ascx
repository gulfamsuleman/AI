<%@ Control Language="C#" AutoEventWireup="true" Codebehind="TasksPanel.ascx.cs" Inherits="QProcess.Controls.Controls_TaskSummary_TasksPanel" %>

<thead>
	<tr>
		<th></th>
		<th>Task</th>
		<th>Deadline</th>
		<th>Assigned To</th>
		<th>Controllers</th>
		<th>Frequency</th>
		<th>Last Completed</th>
		<th>Next Due</th>
	</tr>
</thead>
<tbody>
<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<tr data-instance-id="<%#Eval("InstanceId") %>"
			data-upcoming-id="<%#Eval("UpcomingId") %>"
			data-active-id="<%#Eval("ActiveId") %>"
			data-history-id="<%#Eval("HistoryId") %>"
			data-history-type="<%#Eval("HistoryType") %>"
			data-drop-from-id="<%#Eval("InstanceId") %>"
			data-drop-type="1">
			<td><i class="fa fa-arrows" data-role="open-status" data-is-dragpoint=""><i></td>
			<td>
				<a href="#" title="View/Update Current Checklist" data-role="open-current">
					<%#Eval("ChecklistName") %>
				</a>
			</td>
			<td>
				<span <%# ((int)Eval("HistoryType") == 1 && (DateTime)Eval("CurrentDueTime") < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) ? "class='highlight'" : ""  %>>
					<%#((DateTime)Eval("CurrentDueTime")).ToString("G") %>
				</span>
			</td>
			<td><%#Eval("Assignees") %></td>
			<td><%#Eval("Controllers") %></td>
			<td><%#Eval("Frequency") %></td>
			<td>
				<a href="#" title="View/Update Last Completed Checklist" data-role="open-last">
					<%#((DateTime?)Eval("LastCompleted")).HasValue ? ((DateTime?)Eval("LastCompleted")).Value.ToString("G") : "" %>
				</a>
			</td>
			<td>
				<a href="#" title="View Next Scheduled Checklist" data-role="open-next">
					<%#((DateTime?)Eval("NextDueDate")).HasValue ? ((DateTime?)Eval("NextDueDate")).Value.ToString("G") : "" %>
				</a>
			</td>
		</tr>
	</ItemTemplate>
</asp:Repeater>
</tbody>
<!-- Copyright © 2024 Renegade Swish, LLC -->

