<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ConfidentialReports.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_ConfidentialReports" %>

<div id="confidential-report-panel">
	<button data-role="add-confidential">Add</button>
	<select id="confidential-report-select">
		<asp:Repeater ID="Repeater1" runat="server">
			<ItemTemplate>
				<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
			</ItemTemplate>
		</asp:Repeater>
	</select>
	<table id="confidential-report-table">
		<thead>
			<tr>
				<th></th>
				<th>Report</th>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater2" runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<td><a href='#' data-role='remove-confidential' title="Remove"><img src='/Images/delete.gif' /></a></td>
						<td><%#Eval("Name") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/InboxConfidentialReports.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

