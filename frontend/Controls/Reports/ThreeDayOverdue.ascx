<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ThreeDayOverdue.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_ThreeDayOverdue" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<%@ Import Namespace="QProcess.Enums" %>
<%@ Import Namespace="QProcess.Extensions" %>

<div id="three-day-overdue-panel">
	<div class="filters-bar panel panel-default row">
		<div class="panel-body">
			<div class="filters-controls">
				<div class="form-inline">
					<div class="form-group">
						<select class="form-control input-sm" data-role="three-day-selection">
							<asp:Repeater ID="Repeater1" runat="server">
								<ItemTemplate>
									<option value="<%#Eval("Option") %>" 
										<%#(Convert.ToString(Eval("Option"))).FromString<ThreeDayDropdown>() == Selection ? "selected='selected'" : ""  %>>
										<%#Eval("Description") %>
									</option>
								</ItemTemplate>
							</asp:Repeater>
						</select>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="row">
		<table class="table table-condensed q-table">
			<thead>
				<tr>
					<th>Controller</th>
					<th>Tasks Overdue 3 Days</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("Person") %></td>
							<td><%#Eval("DaysOverdue") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
		<br/>
		<table class="table table-condensed q-table">
			<thead>
				<tr>
					<th>Controller</th>
					<th>Task</th>
					<th>Assignees</th>
					<th>Due</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater3" runat="server">
					<ItemTemplate>
						<tr>
							<td><%#Eval("Person") %></td>
							<td><%#Eval("Checklist") %></td>
							<td><%#Eval("Assignees") %></td>
							<td nowrap><%#Eval("DueDateTime") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>		
			</tbody>
		</table>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/ReportsThreeDayOverdue.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

