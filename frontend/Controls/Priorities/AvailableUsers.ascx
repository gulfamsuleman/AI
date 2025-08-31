<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AvailableUsers.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_AvailableUsers" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="available-users-panel">
	<% if (AvailableUsers.Any()) { %>
		<table id="available-users-table" class="table table-condensed">
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<td><input type="checkbox"/></td>
						<td><%#Eval("Name") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</table>
		<button data-role="add-list-users" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> Add</button>
	<% } else { %>
		<p>No Available Names To Add</p>
	<% } %>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/AddPriorityListUsers.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

