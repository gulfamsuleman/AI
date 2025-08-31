<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Overdue.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_Overdue" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Register TagPrefix="report" TagName="SortBy" Src="~/Controls/Reports/SortBy.ascx" %>

<div id="overdue-panel">
	<div class="filters-bar panel panel-default row">
		<div class="panel-body">
			<div class="filters-controls">
				<div class="form-inline filters">
					<div class="form-group" style="margin-right:30px;">
						<report:SortBy ID="SortByControl" runat="server" />
					</div>
					<% if (IsOverdueAdmin) { %>
						<div class="form-group" style="margin-right:30px;">
							Show Overdue For: 
							<select data-role="show-overdue" class="form-control input-sm">
								<asp:Repeater ID="Repeater1" runat="server">
									<itemtemplate>
										<option value="<%#Eval("Id") %>" <%#Convert.ToInt32(Eval("Id")) == UserId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
									</itemtemplate>
								</asp:Repeater>
							</select>
						</div>
					<% } %>
					<div id="assignedFilterDiv" style="margin-right:30px;">
						<div class="assigned-Filter">
							Show Only Tasks Assigned To: <select id="assigned-filter-list"></select>
						</div>
					</div>
					<a href="#" data-role="open-overdue-message" class="btn btn-sm btn-default">Send Message to Assignees</a>
				</div>
				<div id="message" class="hidden"></div>
				
			</div>
		</div>
	</div>
	<div class="row">
		<div id="overdue-alert" style="color:white;background-color:red;width:600px;font-size: 18pt;display:none;">You have tasks more than 7 days overdue.<br/>You must complete them or move the deadline now!</div>
		<table id="overdue-table" class="table table-condensed q-table table-responsive">
			<thead>
				<tr>
					<th>Task</th>
					<th>Assigned To</th>
					<th>Due Date</th>
					<th>Status Report / Section</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr data-id="<%#Eval("Id") %>" data-assignees="<%#Eval("AssigneeUserList") %>" <%#Convert.ToBoolean(Eval("IsOldOverdue")) ? "class=old-overdue" : "" %>>
							<td><a href="../ManageSingleChecklist.aspx?taskStage=1&taskId=<%#Eval("Id") %>" target="single-checklist"><%#Eval("Task") %></a></td>
							<td><%#Eval("AssignedTo") %></td>
							<td class="due" style="white-space: nowrap"><%#Eval("DueDateTime") %></td>
							<td><%#Eval("StatusReport") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/ReportsOverdue.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/ReportsOverdue.js")).Ticks.ToString() %>"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

