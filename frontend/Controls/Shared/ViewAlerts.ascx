<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ViewAlerts.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ViewAlerts" %>

<div id="view-alerts-panel">
	<% if (ViewAlerts.Any()) { %>
		<table id="alerts-table" class="alerts-table">
			<thead>
				<tr>
					<th>Time</th>
					<th>Alertee</th>
					<th>Type</th>
					<th>Sent</th>
				</tr>
			</thead>
			<tbody>
				<asp:repeater ID="Repeater1" DataSource=<%# ViewAlerts %> runat="server">
					<itemtemplate>
						<tr>	
							<td><%#Eval("AlertTimeText") %></td>
							<td><%#Eval("Alertee") %></td>
							<td><%#Eval("Type") %></td>
							<td><%#(bool)Eval("IsSent") ? "Yes" : "No" %></td>
						</tr>
					</itemtemplate>
				</asp:repeater>
			</tbody>
		</table>
	<% } else { %>
		<p>There are no alerts for this checklist.</p>
	<% } %>
</div>
<!-- Copyright � 2024 Renegade Swish, LLC -->

