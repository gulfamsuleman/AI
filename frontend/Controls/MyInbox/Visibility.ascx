<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Visibility.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_Visibility" %>

<div id="visibility-panel">
	<% if (Supervisors.Any()) { %>
		<table>
			<thead>
				<tr>
					<th>Supervisors</th>
				</tr>	
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("FullName") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>		
			</tbody>
		</table>
		<br/>
	<% } %>
	<% if (InterestedParties.Any()) { %>
		<table>
			<thead>
				<tr>
					<th>Interested Parties</th>
				</tr>	
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("FullName") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>		
			</tbody>
		</table>
		<br/>
	<% } %>
	<% if (Controllers.Any()) { %>
		<table>
			<thead>
				<tr>
					<th>Controllers</th>
				</tr>	
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater3" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("FullName") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>		
			</tbody>
		</table>
	<% } %>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

