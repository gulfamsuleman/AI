<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Users.aspx.cs" Inherits="QProcess.Users" MasterPageFile="Site.master"%>
<%@ Register Src="~/Controls/Shared/AddGroup.ascx" TagPrefix="uc1" TagName="AddGroup" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Users.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/CommonGroupFunctions.js"></script>
	<script src="Scripts/Users.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <br />
	<div id="users-panel">
		<div class="row">
			<div class="col-xs-6">
				<div class="row">
					<div class="col-xs-offset-3 col-xs-6">
						<div id="add-user-panel" class="panel panel-default">
							<div class="panel-heading">Users</div>
							<div class="panel-body">
								<div class="form-horizontal">
									<div class="form-group">
										<label for="login" class="col-xs-4 control-label">Login:</label>
										<div class="col-xs-8"><input id="login" type="text" class="input-sm"/></div>
									</div>
									<div class="form-group">
										<label for="name" class="col-xs-4 control-label">Name:</label>
										<div class="col-xs-8"><input id="name" type="text" class="input-sm"/></div>
									</div>
									<div class="form-group">
										<label for="email" class="col-xs-4 control-label">Email:</label>
										<div class="col-xs-8"><input id="email" type="email" class="input-sm"/></div>
									</div>
									<div class="form-group">
                                        <label for="admin" class="col-xs-4 control-label">Admin:</label>
										<div class="col-xs-8"><input id="admin" type="checkbox"/></div>
									</div>
                                    <hr />
									<div class="form-group text-center">
										<button data-role="add-user" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> Add User</button>
									</div>
								</div>
								
							</div>
						</div>
					</div>
				</div>
                <br />
                <div class="col-xs-offset-0 col-xs-12">
                    <table id="users-table" class="table table-condensed">
					    <tr>
						    <th style="min-width:50px;"></th>
						    <th>Login</th>
						    <th>Name</th>
						    <th>Email</th>
						    <th>Admin</th>
					    </tr>
					    <asp:Repeater ID="Repeater1" DataSource=<%# UserLines %> runat="server">
						    <ItemTemplate>
							    <tr data-id="<%#Eval("Id") %>">
								    <td data-role="actions">
									    <a data-role='delete-user'><img src="/Images/delete.gif" title="Remove" runat="server"/></a>
									    <a data-role='edit-user'><img src="/Images/edit.gif" title="Edit" runat="server"/></a>
								    </td>
								    <td data-role="login"><%#Eval("ShortName") %></td>
								    <td data-role="name"><%#Eval("FullName") %></td>
								    <td data-role="email"><%#Eval("Email") %></td>
								    <td data-role="admin"><input type="checkbox" <%#(bool)Eval("IsAdmin") ? "checked='checked'" : "" %> disabled/></td>
							    </tr>
						    </ItemTemplate>
					    </asp:Repeater>
				    </table>
                </div>
			</div>
			<div class="col-xs-6">
				<div class="row">
                    <div class="col-xs-offset-2 col-xs-6">
					    <uc1:AddGroup runat="server" ID="AddGroup" />
                    </div>
				</div>
				<br />
                
                <div class="col-xs-offset-1 col-xs-8">
				    <table id="user-groups-table" class="table table-condensed">
					    <tr>
						    <th></th>
						    <th>Group Name</th>
						    <th>Created By</th>
					    </tr>
					    <asp:Repeater ID="Repeater2" DataSource=<%# UserGroups %> runat="server">
						    <ItemTemplate>
							    <tr data-id="<%#Eval("Id") %>" data-edit="true">
								    <td data-role="actions">
									    <a data-role='delete-user-group'><img src="/Images/delete.gif" title="Remove" runat="server"/></a>
								    </td>
								    <td data-role="name"><a href="#" data-role="edit-user-group"><%#Eval("GroupName") %></a></td>
								    <td data-role="owner-<%#Eval("Id") %>"><%#Eval("Owner") %></td>
							    </tr>
						    </ItemTemplate>
					    </asp:Repeater>
				    </table>
                </div>
			</div>
		</div>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

