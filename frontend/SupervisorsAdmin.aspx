<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="SupervisorsAdmin.aspx.cs" Inherits="QProcess.SupervisorsAdmin" MasterPageFile="BlankMaster.master" %>
<%@ Register TagPrefix="sa" TagName="Supervisors" Src="~/Controls/Shared/Supervisors.ascx" %>
<%@ Register TagPrefix="sa" TagName="Controllers" Src="~/Controls/Shared/Controllers.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/SupervisorsAdmin.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/SupervisorsAdmin.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="fullpage" style="height:95vh;overflow-y:scroll;">
		<div id="supervisor-admin-panel">
			<div class="panel-body">
				<div class="form-inline">
					<label class="control-label">Reports: </label>
					<select id="report-select" class="form-control input-sm">
						<asp:Repeater ID="Repeater1" DataSource=<%#Reports %> runat="server">
							<ItemTemplate>
								<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
							</ItemTemplate>
						</asp:Repeater>
					</select>
					<label class="control-label">People: </label>
					<select id="people-select" class="form-control input-sm">
						<asp:Repeater ID="Repeater2" DataSource=<%#People %> runat="server">
							<ItemTemplate>
								<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
							</ItemTemplate>
						</asp:Repeater>
					</select>
				</div>
				<hr/>
				<div id="throbber" class="throbber hidden">
					<img src="/Images/loading.gif"/>
					<span>Loading...</span>	
				</div>
				<div id="hideable-area" class="hidden">
				
					<div class="panel panel-default">
						<div class="panel-heading">
							Supervisors and Interested Parties
						</div>
						<div class="panel-body supervisor-body"><sa:Supervisors ID="Supervisors" runat="server"/></div>
					</div>
					<br />
					<div class="panel panel-default">
						<div class="panel-heading">
							Controllers
						</div>
						<div class="panel-body controller-body"><sa:Controllers ID="Controllers" runat="server"/></div>
					</div>

					<input id="supervisors-admin" type="hidden" value="<%=true %>"/>
				</div>
			
				<div id="people-hideable-area" class="hidden">
					<div class="panel panel-default">
						<div class="panel-heading">
							Reports Supervised (/IP) By <span id="people-name"></span>
						</div>
						<div class="panel-body people-body">
							<table id="people-table" class="table table-condensed">
								<thead><tr>
									<th></th>
									<th>Group</th>
									<th>Report Name</th>
									<th class="text-center">Interested Party</th>
									<th class="text-center">Supervisor</th>
								</tr></thead>
								<tbody></tbody>
							</table>

						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

