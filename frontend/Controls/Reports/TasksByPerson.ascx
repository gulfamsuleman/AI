<%@ Control Language="C#" AutoEventWireup="true" Codebehind="TasksByPerson.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_TasksByPerson" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="tasks-by-person-panel">
	<div class="filters-bar panel panel-default row">
		<div class="panel-body">
			<div class="filters-controls">
				<div class="form-inline">
					<div class="form-group">
						Show tasks assigned to: 
						<select data-role="user-selection" class="form-control input-sm">
							<asp:Repeater ID="Repeater1" runat="server">
								<ItemTemplate>
									<option value="<%#Eval("Id") %>" <%#Convert.ToInt32(Eval("Id")) == SelectedUserId ? "selected='selected'" : "" %>><%#Eval("Name") %></option>
								</ItemTemplate>
							</asp:Repeater>	
						</select>
					</div>
					<div class="form-group">
						Find tasks named: <input type="text" class="form-control input-sm" data-role="search-task" value="<%=Search %>"/>
						<button data-role="search-person" class="btn btn-sm btn-default">Search This Person's Tasks</button>
						<button data-role="search-everyone" class="btn btn-sm btn-default">Search Everyone's Tasks</button>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="row">
		<table class="table table-condensed q-table">
			<thead>
				<tr>
					<th>Task</th>
					<th>Due</th>
					<th>Completed</th>
					<th>Assignees</th>
					<th>Controllers</th>
					<th>Schedule</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("Task") %></td>
							<td nowrap><%#Eval("DueDateTime") %></td>
							<td nowrap><%#Eval("CompletedDateTime") %></td>
							<td><%#Eval("Assignees") %></td>
							<td><%#Eval("Controllers") %></td>
							<td><%#Eval("Schedule") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/ReportsTasksByPerson.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

