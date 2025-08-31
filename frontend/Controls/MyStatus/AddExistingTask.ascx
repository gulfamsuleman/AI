<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AddExistingTask.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_AddExistingTask" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="available-tasks-panel">
	<% if (ExistingTasks.Any()) { %>
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
            <select id="ddFilter">
                <option value="" selected>Assigned to Anyone</option>
                <asp:Repeater ID="AssigneesRepeater" runat="server">
					<ItemTemplate>
						<option value="<%#Eval("Name") %>"><%#Eval("Name") %></option>
					</ItemTemplate>
				</asp:Repeater>
            </select>
		</div>
		<div style="overflow: auto; margin-bottom: 20px;" id="available-tasks">
		<table id="available-tasks-table" class="table table-condensed">
			<asp:Repeater ID="ExistingTasksRepeater" runat="server">
				<ItemTemplate>
					<tr data-instance-id="<%#Eval("ID") %>">
						<td class="active-checkbox"><input type="checkbox"/></td>
						<td class="checklist-name"><%#Eval("Name") %></td>
						<td><%#Convert.ToDateTime(Eval("DueDate")).ToShortDateString() %></td>
                        <td><%#Eval("Assignees") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</table>
		</div>
		<button data-role="add-checked" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> All Checked</button>
		<button data-role="add-due-today" class="btn btn-sm btn-default"><i class="fa fa-check"></i> Due Today</button>
		<button data-role="add-due-week" class="btn btn-sm btn-default"><i class="fa fa-check"></i> Due This Week</button>
	<% } else { %>
		<div>No Available Tasks to Add</div>
		<br/>
	<% } %>
	<input id="selected-section-id" type="hidden" value="<%=SelectedSectionId %>"/>
	<script>var reportId = <%=ReportId%>;</script>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >	
    <script src="../Scripts/date.js"></script>
	<script src="../Scripts/StatusAddExistingTasks.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

