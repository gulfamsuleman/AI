<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Groups.aspx.cs" Inherits="QProcess.Groups" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="uc1" TagName="AddGroup" Src="~/Controls/Shared/AddGroup.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Groups.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/CommonGroupFunctions.js"></script>
	<script src="Scripts/Groups.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <br />
	<div id="groups-panel">
		<uc1:AddGroup runat="server" ID="AddGroup" />
		<p>Show groups containing</p>
		<select id="display-user-list" class="form-control input-sm">
			<asp:repeater ID="Repeater2" DataSource=<%# UsersList %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
	</div>
	<table id="user-groups-table" class="table table-condensed">
		<thead>
			<tr>
			        <th></th>
				<th>Group Name</th>
				<th>Edit/View Members</th>
				<th>I'm in it</th>
				<th>I own it</th>
				<th>Owner</th>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater1" DataSource=<%# UserGroups %> runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>" data-edit="<%#(bool)Eval("IsOwner") %>">
						<td data-role="actions">
							<a data-role='delete-user-group' <%#(bool)Eval("IsOwner") ? "" : "style='display:none;'" %>><img src="/Images/delete.gif" title="Remove" runat="server"/></a>
						</td>
						<td data-role='name'><%#Eval("GroupName") %></td>
						<td><a href="#" data-role="edit-user-group"><%#(bool)Eval("IsOwner") ? "Edit" : "View" %></a></td>
						<td class="centerText"><%#(bool)Eval("IsMember") ? "<i class='fa fa-star'></i>" : "" %></td>
						<td class="centerText"><%#(bool)Eval("IsOwner") ? "<i class='fa fa-star'></i>" : "" %></td>
						<td><%#Eval("Owner") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
	<button id="hid-refresh" style="display:none;"></button>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


