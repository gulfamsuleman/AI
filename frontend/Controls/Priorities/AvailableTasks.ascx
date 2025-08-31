<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AvailableTasks.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_AvailableTasks" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="available-tasks-panel">
	<% if (AvailableTasks.Any()) { %>
		<div class="search-bar form-inline" style="margin-bottom: 15px;">
			<div class="form-group">
				<input id="search-box" type="text" class="form-control input-sm"/>
			    <button data-role="search" class="btn btn-sm btn-default">Search</button>
			</div>
			<span>Sort:</span>
			<span class="radio">
				<label>
					<input type="radio" name="order" value="duetime" <%= Sort == "duetime" ? "checked='checked'" : "" %> />
					Due Date
				</label>
			</span>
			<span class="radio">
				<label>
					<input type="radio" name="order" value="name" <%= Sort == "name" ? "checked='checked'" : "" %> />
					Task Name
				</label>
			</span>
		</div>
		<div style="max-height: 700px; overflow: auto; margin-bottom: 20px;" id="available-tasks">
		<table id="available-tasks-table" class="table table-condensed">
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<tr data-active-checklist-id="<%#Eval("ActiveChecklistId") %>">
						<td class="active-checkbox"><input type="checkbox"/></td>
						<td class="checklist-name"><%#Eval("Name") %></td>
						<td><%#Convert.ToDateTime(Eval("DueDate")).ToShortDateString() %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</table>
		</div>
		<button data-role="add-checked" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> All Checked</button>
		<button data-role="add-due-today" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> All Due Today</button>
		<button data-role="add-due-week" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> All Due This Week</button>
		<button data-role="exclude" class="btn btn-sm btn-default"><i class="fa fa-times"></i> Exclude</button>
	<% } else { %>
		<div>No Available Tasks to Add</div>
		<br/>
	<% } %>
	<input id="for-user-id" type="hidden" value="<%=ForUserId %>"/>
	<input id="for-list-id" type="hidden" value="<%=ForListId %>"/>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/AddPriorityListTasks.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

