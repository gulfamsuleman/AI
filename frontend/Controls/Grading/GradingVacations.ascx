<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingVacations.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingVacations" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Register TagPrefix="grading" TagName="GradingUsers" Src="~/Controls/Grading/GradingUsers.ascx" %>

<div id="vacation-panel">
	<span>Vacation Times:</span>
	<br/>
	<table id="vacation-table" class="<%= Vacations.Any() ? "" : "hidden" %> table table-condensed">
		<thead>
			<tr>
				<td></td>
				<% if (IsApproval || IsAdminDetails) { %>
					<td>User</td>
				<% } %>
				<td>Start</td>
				<td>End</td>
				<td>Status</td>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater1" DataSource=<%# Vacations %> runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<td>
							<input data-action="delete-vacation" type="button" class="fa btn <%# (string)Eval("Status") == "Approved" ? "hidden" : "" %>" value="&#xf00d"/>
							<% if (IsApproval || IsAdminDetails) { %>
								<button data-action="approve-vacation" <%# (string)Eval("Status") == "Approved" ? "class='hidden'" : "" %>>Approve</button>
							<% } %>
						</td>
						<% if (IsApproval || IsAdminDetails) { %>
							<td><%#Eval("FullName") %></td>
						<% } %>
						<td><%#Eval("StartDate") %></td>
						<td><%#Eval("EndDate") %></td>
						<td id="vacation-status"><%#Eval("Status") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
	<% if (!IsAdminDetails) { %>
		<span>
			<button data-action="add-vacation" class="btn btn-sm btn-default">Add Vacation</button>
			between
			<input id="vacation-start" data-role="datepicker" class="form-control input-sm"/>
			and
			<input id="vacation-end" data-role="datepicker" class="form-control input-sm"/>
		</span>
		<br/>
		<% if (IsApproval)
		   { %>
			<span>User: </span>
		<% } %>
		<grading:GradingUsers ID="GradingUsersControl" runat="server"/>
	<% } %>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/GradingVacations.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

