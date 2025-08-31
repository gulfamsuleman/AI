<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Automations.aspx.cs" Inherits="QProcess.Automations" MasterPageFile="Site.master"%>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<style>
		#linked-deadlines-table > thead > tr > th{
		border:solid 1px #000000;
		vertical-align:top;
		background-color:#ece9d8;
	}
	td,th{
		padding:3px;
		border:solid 1px #000000;
	}
	table{
		border-collapse:collapse;
	}
	</style>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/LinkedDeadlines.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/LinkedDeadlines.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="linked-panel" class="linked-panel">
		<h3>Add/Remove Linked Deadlines</h3>
		<span>
			<div id="instructions">
				Linked deadlines will automatically associate the deadlines of two tasks.  When the source task's deadline changes, the linked task's deadline will be offset based on the days specified.  
				When the source task is completed, the deadline of the target task will be updated to based on the completion date of the source task.
				<hr />
			</div>
			
            <span class="leftLabel" style="width:130px;display:inline-block;">
			    Source task:
            </span>
            <span>
                <select id="member-select" class="input-sm">
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
					</ItemTemplate>
				</asp:Repeater>
			    </select>

            </span><br />
			 <span class="leftLabel" style="width:130px;display:inline-block">
				Linked task:
			 </span>
			 <span>
				 <select id="link-select" class="input-sm">
					<asp:Repeater ID="Repeater2" runat="server">
						<ItemTemplate>
							<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
						</ItemTemplate>
					</asp:Repeater>
					</select>

			 </span>
			<div>
				 <span class="leftLabel" style="width:130px;display:inline-block">
					Days Offset:
				 </span>
				 <span>
					 <input type="number" value="30" id="offset" min="1" max="1000"/>
				 </span>
			</div>
			 <div>
				 <input type="button" value="Add Link" data-action="add-assignment" class="btn btn-sm btn-default"/>
			 </div>
			<hr />
		</span>
	</div>
	<div id="existing-linked-panel" class="existing-linked-panel">
		<h3>Active Links</h3>
		<table id="linked-deadlines-table">
			<thead>
                <tr>
                    <th>Actions</th>
                    <th>Source Task</th>
                    <th>Linked Task</th>
                    <th>Days Offset</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
		</table>
	</div>
	<div style="border: 1px lightgray dotted; margin-top: 15px;">
		<h3>Bulk Task Upload</h3>
		<h4>Click the button below if you would like to import a list of tasks in a .csv file.</h4>
		<a href="BulkTaskUpload.aspx" class="btn btn-sm btn-default">Bulk Task Upload</a>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


