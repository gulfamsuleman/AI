<%@ Control Language="C#" AutoEventWireup="true" Codebehind="PriorityLines.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_PriorityLines" %>
<%@ Register TagPrefix="priority" TagName="PriorityComments" Src="~/Controls/Priorities/Comments.ascx" %>

<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<tr class="webview"
			data-id="<%#Eval("Id") %>"
			data-user="<%#Eval("UserId") %>"
			data-list="<%#Eval("ListId") %>"
			data-priority="<%#Eval("Priority") %>"
			data-active-checklist-id="<%#Eval("ActiveChecklistId") %>"
			<%#completedStyle(Convert.ToInt32(Eval("Priority"))) %>>
			<td class="priority-col" style="width:60px;">
				<span class="hidden data-label">Priority</span>
				<span class="nbr"><%# priorityString(Convert.ToInt32(Eval("Priority"))) %></span>
				<span class="draggable" <%= !IsSingleUserList ? "data-role='dragndrop-dragpoint'" : "" %>></span>
			</td>
			<td style="width:700px;">
				<span class="hidden data-label">Task</span>
				<span class="expand-collapse-placeholder"></span>
				<a style="display:inline;" href="#" onclick="return prioritiesModule.openWindow(<%#Eval("ActiveChecklistId") %>, 'Current')">
					<%#completedPrefix(Convert.ToInt32(Eval("Priority"))) %><%#Eval("Name") %>
				</a>
				<priority:PriorityComments Comments=<%#Eval("Comments") %> runat="server" />
			</td>
			<td style="width:60px;"><span class="hidden data-label">Status</span><a class="pointer-cursor" data-role="status-link">...</a></td>
			<td style="width:80px;" data-column="due">
				<span class="hidden data-label">Due</span><%#Eval("DueDate", "{0:MM/dd/yyyy}") %>
			</td>
		</tr>
	</ItemTemplate>
</asp:Repeater>
<!-- Copyright © 2024 Renegade Swish, LLC -->

