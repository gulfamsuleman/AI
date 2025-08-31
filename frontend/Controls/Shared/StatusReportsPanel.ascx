<%@ Control Language="C#" AutoEventWireup="true" Codebehind="StatusReportsPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_StatusReportsPanel" %>
<div class="status-reports-panel" data-status ='<%=SerializedReports() %>'>
	<div class="report-div form-inline">
		<select data-role="complex-select" data-set="folders" class="form-control input-sm">
			<asp:Repeater  DataSource="<%#Folders %>" runat="server">
				<ItemTemplate>
					<option value="<%#Eval("Id") %>"><%#Eval("Name")%></option>
				</ItemTemplate>
			</asp:Repeater>
		</select>
	</div>
	<div class="report-selection-div hidden form-inline">
		<select data-role="complex-select" data-set="sections" class="form-inline"></select>
		<button data-role="add" class="btn btn-sm btn-default">Add</button>
	</div>
	<table class="status-reports-table hidden table table-condensed table-listing">
		<thead><tr>
			<th></th>
			<th>Report</th>
			<th>Section</th>
		</tr></thead>
		<tbody></tbody>
	</table>
    <input id="hidStatusReport" type="hidden" value="<%=StatusReport %>" /> <%--added by venkat 06/14/2018--%>
    <input id="hidStatusReportSection" type="hidden" value="<%=StatusReportSection %>" /> <%--added by venkat 06/14/2018--%>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/StatusReportsPanel.js?v=10"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

