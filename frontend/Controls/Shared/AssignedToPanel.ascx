<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AssignedToPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_AssignedToPanel" %>
<div class="assigned-to-panel"data-status='<%=SerializedAssignments() %>' >
	<div class="form-inline">
		<button data-role="add" class="btn btn-sm btn-default">Add</button>
		<select data-role="complex-select" id="Select1" class="form-control input-sm">
			<asp:repeater ID="Repeater1" DataSource=<%# Assignees %> runat="server">
				<itemtemplate>
					<option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
				</itemtemplate>
			</asp:repeater>
		</select>
	</div>
	<table class="assignees-table hidden table table-condensed table-listing">
		<thead><tr>
			<th></th>
			<th>Assignee</th>
		</tr></thead>
		<tbody></tbody>
	</table>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/AssignedToPanel.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

