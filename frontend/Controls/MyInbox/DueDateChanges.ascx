<%@ Control Language="C#" AutoEventWireup="true" Codebehind="DueDateChanges.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_DueDateChanges" %>

<div id="due-date-changes-panel">
	<% if (DueDateChanges.Any()) { %>
		<table>
			<thead>
				<tr>
					<th>Task</th>
					<th>Old Due Date</th>
					<th>New Due Date</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("Description") %></td>
							<td><%#Eval("OldDueDate") %></td>
							<td><%#Eval("NewDueDate") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	<% } else { %>
		<p>No Due Date Changes</p>
	<% } %>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

