<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="BulkAssignments.aspx.cs" Inherits="QProcess.BulkAssignments" MasterPageFile="Site.master"%>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/BulkAssignments.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/BulkAssignments.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/BulkAssignments.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="bulk-assignments-panel" class="bulk-assignments-panel">
		<h2>Bulk Add/Remove Assignments</h2>
		<span>
            <span class="leftLabel">
			    Add/Remove
            </span>
            <span>
                <select id="member-select" class="input-sm">
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
					</ItemTemplate>
				</asp:Repeater>
			    </select>

            </span>
			
			as an assignee for all selected tasks.
		</span>
		<br/>
		<span>
            <span class="leftLabel">Comment:</span>
			<span><input data-role="comment" type="text" class="form-control input-sm"/></span>
		</span>
		<br/>
        <span class="leftHighlights">
            <button data-action="add-assignment" class="btn btn-sm btn-default">Add Assignment</button>
		    <button data-action="remove-assignment" class="btn btn-sm btn-default">Remove Assignment</button>
        </span>
        <br/>
		<br/>
		<span class="bold leftHighlights">
			  Tasks highlighted in YELLOW are tasks you assigned to someone else using this tool.
		</span>
        <br />
        <span class="leftHighlights"> 
			<button data-action="clear-highlighting" class="btn btn-sm btn-default">Clear Highlighting</button>
        </span>
		<br/>
		<br/>
		<span class="bold">Tasks Assigned</span>
		<table id="bulk-assignments-table" class="table table-condensed">
			<thead>
				<tr>
					<th><input type="checkbox" data-action="check-all" /></th>
					<th>Task</th>
					<th>Assignees</th>
					<th>Controllers</th>
					<th>Report</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater2" runat="server">
					<ItemTemplate>
						<tr data-id="<%#Eval("Id") %>" <%#(bool)Eval("IsHighlighted") ? "class='highlight'" : "" %>>
							<td><input data-role="task" type="checkbox"/></td>
							<td><%#Eval("Name") %></td>
							<td><%#Eval("Assignees") %></td>
							<td><%#Eval("Controllers") %></td>
							<td><%#Eval("Alertees") %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

