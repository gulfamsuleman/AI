<%@ Control Language="C#" AutoEventWireup="true" Codebehind="History.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_History" %>
<%@ Register TagPrefix="report" TagName="SortBy" Src="~/Controls/Reports/SortBy.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="history-panel">
	<div class="filters-bar panel panel-default row">
		<div class="panel-body">
			<div class="filters-controls">
				<div class="form-inline">
					<div class="form-group">
						<report:SortBy ID="SortByControl" runat="server"/>
					</div>
					<div class="form-group">
						Completed By:
						<select data-role="completed-by" class="form-control input-sm">
							<asp:Repeater ID="Repeater1" runat="server">
								<ItemTemplate>
									<option value="<%#Eval("Id") %>" <%#Convert.ToInt32(Eval("Id")) == SelectedMemberId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
								</ItemTemplate>
							</asp:Repeater>
						</select>
					</div>
					<div class="form-group">
						Starting:
			            <input id="start-date" class="form-control input-sm" data-role="datepicker" value="<%=StartDate.ToShortDateString() %>"/>
					</div>
					<div class="form-group">
						Ending:
			            <input id="end-date" class="form-control input-sm" data-role="datepicker" value="<%=EndDate.ToShortDateString() %>"/>
					</div>
					<button data-role="run-report" class="btn btn-sm btn-default">Run Report</button>
				</div>
			</div>
		</div>
	</div>
	<% if (Show) { %>
	<div class="row">
		<table id="history-table" class="table table-condensed q-table table-responsive">
			<thead>
				<tr>
					<th>Task</th>
					<th>Closed By</th>
					<th>Completed On</th>
                    <th>Marked N/A On</th>
					<th>Due Date</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr data-id="<%#Eval("Id") %>" data-type="<%#Eval("Type") %>" data-sort="<%#Eval("Sort") %>">
							<td><a href="../ManageSingleChecklist.aspx?taskStage=<%#Eval("Type") %>&taskId=<%#Eval("Id") %>" target="single-checklist"><%#Eval("Task") %></a></td>
							<td><%#Eval("CompletedBy") %></td>
							<td style="white-space: nowrap"><%# CompletedOn(Eval("CompletedOn"), Eval("IsNA")) %></td>
                            <td style="white-space: nowrap"><%# NAOn(Eval("CompletedOn"), Eval("IsNA")) %></td>
							<td style="white-space: nowrap"><%#Eval("DueDateTime") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	</div>
	<% } %>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/ReportsHistory.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

