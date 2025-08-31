<%@ Control Language="C#" AutoEventWireup="true" Codebehind="BulkUpdate.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_BulkUpdate" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="bulk-update-panel">
	<div id="bulk-update-step-1">
		<p>Bulk Update Tasks with the following information</p>
		<label>
			<input type="checkbox" checked="checked" data-role="update-soft-due"/>
			 Update Soft Due: 
			<input data-role="datepicker"/>
		</label>
		<br/>
		<label>
			<input type="checkbox" checked="checked" data-role="add-comments"/>
			 Add Comments:
		</label>
		<textarea class="bulk-update-area" data-role="comment"></textarea>
		<button data-role="next-step">Next</button>
	</div>
	<div id="bulk-update-step-2" class="hidden">
		<p>Save to the following Tasks:</p>
		<label>
			<input type="checkbox" data-role="select-all-tasks"/>
			 All Tasks
		</label>
		<br/>
		<label>
			<input type="checkbox" data-role="select-due-tomorrow"/>
			 All Tasks Due Before Tomorrow
		</label>
		<table id="tasks">
			<thead>
				<tr>
					<th></th>
					<th>Section</th>
					<th>Task</th>
					<th>Soft Due</th>
				</tr>
			</thead>
			<tbody>
				<asp:Repeater ID="Repeater1" runat="server">
					<ItemTemplate>
						<tr>
							<td>
								<input type="checkbox"
									 data-role="task"
									 data-period="<%#Convert.ToDateTime(Eval("DueDate")) < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.AddDays(1) ? "past" : "future" %>"
									 value="<%#Eval("Id") %>"/>
							</td>
							<td><%#Eval("Section") %></td>
							<td><%#Eval("Name") %></td>
							<td><%#Convert.ToDateTime(Eval("DueDate")).ToShortDateString() %></td>
						</tr>
					</ItemTemplate>
				</asp:Repeater>
			</tbody>
		</table>
		<button data-role="save-update">Save</button>
	</div>
	<div id="bulk-update-step-3" class="hidden">
		<p>Please wait while updates are applied.</p>
	</div>
	<div id="bulk-update-step-4" class="hidden">
		<p>Updates Complete, please click <a href="#" onclick="window.location.reload();">here</a> to reload your status report with the updates.</p>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/StatusBulkUpdate.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

