<%@ Control Language="C#" AutoEventWireup="true" Codebehind="EditGroup.ascx.cs" Inherits="QProcess.Controls.Controls_Users_EditGroup" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="edit-group-panel">
	

	<% if (Editable) { %>
		<div id="ownermodule">
			<h2>Group Owner</h2>
			<select id="owner-list">
			<asp:repeater ID="Repeater3" DataSource=<%# OwnerList %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %> <%#(Owner == (int)Eval("Id")) ? "selected" : "" %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
			</select>
			<button data-role="edit-owner" class="btn btn-sm btn-default"><i class="fa"></i> Change Owner</button>
		</div>
		<div id="add-group-user">
			<h2>Members</h2>
			<select id="add-user-list">
				<asp:repeater ID="Repeater2" DataSource=<%# UsersList %> runat="server">
					<itemtemplate>
						<option value=<%#Eval("Id") %> <%#(bool)Eval("InGroup") ? "disabled" : "" %>><%#Eval("Name") %></option>
					</itemtemplate>
				</asp:repeater>
			</select>
			<button data-role="add-user-to-group" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> Add</button>
		</div>
	<% } %>
	<table id="users-in-group">
		<thead>
			<tr>
				<% if (Editable) { %>
					<th></th>
				<% } %>
				<th>Group Members</th>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater1" DataSource=<%# GroupUsers %> runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<% if (Editable) { %>
							<td data-role="actions">
                                <a data-role='remove-group-user'><img src="/Images/delete.gif" title="Remove"/></a>
							</td>
						<% } %>
						<td data-role="name"><%#Eval("FullName") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>	
		</tbody>
	</table>
	<input type="hidden" id="group-id" value="<%= GroupId %>"/>
	<input type="hidden" id="owner-id" value="<%= Owner %>"/>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/EditGroup.js"></script>	
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

