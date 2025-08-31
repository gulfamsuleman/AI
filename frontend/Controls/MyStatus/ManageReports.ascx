<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ManageReports.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_ManageReports" %>
<div id="reports-panel">
	<div style="background-color:yellow; border:1px solid black; padding: 5px; margin: 10px;">
		Deleting a status report removes it for <b>EVERYONE</b>, not just you.  If you want to stop seeing a report that others use:
		<ol>
			<li>Close this window</li>
			<li>Change to the status report you want to remove yourself from</li>
			<li>Click Report -> Controllers at the top of the page</li>
			<li>Click the red X by your name</li>
		</ol>
	</div>
	<button data-role="add" class="btn btn-sm btn-default">Add</button>
	<table id="reports-table" class="table table-condensed">
		<thead>
			<tr>
				<th></th>
				<th>Report</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td height="20" colspan="2">
					&nbsp;
				</td>
			</tr>
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<tr data-id="<%#Eval("Id") %>">
						<td data-item='actions'>
							<a data-role='edit'><img src='/Images/edit.gif' title="Edit" /></a>
							<a data-role='delete'><img src='/Images/delete.gif' title="Remove" /></a>
						</td>
						<td data-item="name"><%#Eval("Name") %></td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/StatusManageReports.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

