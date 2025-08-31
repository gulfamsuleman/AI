<%@ Control Language="C#" AutoEventWireup="true" Codebehind="SetStatus.ascx.cs" Inherits="QProcess.Controls.Controls_TaskSummary_SetStatus" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="set-status-panel">
	<div class="form-inline">
		<span>Add: </span>
		<select id="report-dropdown" class="form-control input-sm">
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
				</ItemTemplate>
			</asp:Repeater>
		</select>
		<select id="section-dropdown" class="hidden form-control input-sm">
		
		</select>
		<button data-role="add-instance" class="hidden btn btn-sm btn-default">Go</button>
	</div>
	
	<table id="status-table" <%=!DataGridReports.Any() ? "class='hidden table table-condensed'" : "class='table table-condensed'" %>>
		<thead>
			<tr>
				<th></th>
				<th>Report</th>
				<th>Section</th>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater2" runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("ID") %>" data-report-id="<%#Eval("ReportID") %>">
						<td><a data-role="delete-instance"><img src="/Images/delete.gif" title="Remove" /></a></td>
						<td><%#Eval("Report") %></td>
						<td><%#Eval("TaskType") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
	<input id="instance-id"type="hidden" value="<%= InstanceId %>"/>
</div>

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/SetStatus.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

