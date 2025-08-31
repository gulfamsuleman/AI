<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingReportsOnHold.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingReportsOnHold" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Register TagPrefix="grading" TagName="GradingUsers" Src="~/Controls/Grading/GradingUsers.ascx" %>

<div id="on-hold-panel">
	<span>Reports on hold:</span>
	<table id="report-table" class="<%= ReportsOnHold.Any() ? "" : "hidden" %> table table-condensed">
		<thead>
			<tr>
				<td></td>
				<td>Report</td>
				<td>User</td>
				<td>Start</td>
				<td>End</td>
				<td>Status</td>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater1" DataSource=<%# ReportsOnHold %> runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<% if (!IsAdminDetails) { %>
							<td>
								<input data-action="delete-report" type="button" class="fa btn" value="&#xf00d"/>
							</td>
						<% } %>
						<td><%#Eval("Report") %></td>
						<td><%#Eval("User") %></td>
						<td><%#Eval("StartDate") %></td>
						<td><%#Eval("EndDate") %></td>
						<td><%#Eval("Status") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
	<br/>
	<% if (!IsAdminDetails) { %>
		<label>Report:</label>
		<select id="select-report" class="form-control input-sm">
			<asp:Repeater ID="Repeater2" DataSource=<%# GradingReports %> runat="server">
				<ItemTemplate>
					<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
				</ItemTemplate>
			</asp:Repeater>
		</select>
		<br/>
		<label>User:</label>
		<grading:GradingUsers ID="GradingUsersControl" runat="server" />
		<br/>
		between
		<input id="report-start" data-role="datepicker" class="form-control input-sm"/>
		and
		<input id="report-end" data-role="datepicker" class="form-control input-sm"/>
		<br/>
		<button data-action="add-report" class="btn btn-default btn-sm">Add Report On Hold</button>
	<% } %>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/GradingReportsOnHold.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

