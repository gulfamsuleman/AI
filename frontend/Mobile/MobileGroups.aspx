<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileGroups.aspx.cs" Inherits="QProcess.Mobile.MobileGroups" MasterPageFile="Mobile.master" %>
<%@ Register TagPrefix="uc1" TagName="AddGroup" Src="~/Controls/Shared/AddGroup.ascx" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
    <link href="../Content/Groups.css" rel="stylesheet" />
	<style type="text/css">
		.text-header {
			height: 10px;
		}
		#add-user-group-panel {
			border: 1px solid #ccc;
			border-radius: 5px;
			padding: 10px;
			margin-bottom: 10px;
		}
		#groups-panel {
			max-width: 100%;
			margin-top: 16px;
		}
		#users-in-group { width: 100%; }
		#edit-group-panel { margin-top: 20px; }
	</style>
    <script>
        var mobileTitle = "Groups";
    </script>    
</asp:Content>

<asp:Content ID="main" runat="server" ContentPlaceHolderID="mainContent">
	<div id="groups-panel">
		<uc1:AddGroup runat="server" ID="AddGroup" />
		<span>Show groups containing</span>
		<select id="display-user-list" class="form-control input-sm form-control">
			<asp:repeater ID="Repeater2" DataSource=<%# UsersList %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
	</div>
	<table id="user-groups-table" class="table table-condensed table-responsive">
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
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="../Scripts/CommonGroupFunctions.js"></script>
	<script src="../Scripts/Groups.js"></script>
	<script type="text/javascript">
        $("#add-user-group-panel input[type=text]").addClass("form-control");
        $("#add-user-group-panel button").addClass("btn");
    </script>

<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

