<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingDeductions.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingDeductions" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="grading-deductions-panel">
	<table id="deductions-table" class="table table-condensed">
		<thead>
			<tr>
				<% if (IsAdminDetails) { %>
					<th>Excuse/Delete</th>
				<% } %>
				<th>Date</th>
				<th>Reason</th>
				<th>Points</th>
			</tr>
		</thead>
		<tbody>
			<asp:Repeater ID="Repeater1" DataSource=<%# Deductions %> runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>" <%#(bool)Eval("IsDeleted") ? "class='italic'" : "" %>>
						<% if (IsAdminDetails) { %>
							<td>
								<input type="button" data-action="delete-deduction" class="fa btn <%#(bool) Eval("IsDeleted") || (int)Eval("Id") == -1 ? "hidden" : "" %>" value="&#xf00d;"/>
								<input type="button" data-action="restore-deduction" class="fa btn <%#!(bool) Eval("IsDeleted") || (int)Eval("Id") == -1 ? "hidden" : "" %>" value="&#xf112;"/>
							</td>
						<% } %>
						<td><%#Eval("Date") %></td>
						<td><%#Eval("Reason") %></td>
						<td <%# GetPointColor((double)Eval("Points"), (int)Eval("Type")) %>>
							<%# GetPointValue((double)Eval("Points"), (int)Eval("Type")) %>
						</td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/GradingDeductions.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

