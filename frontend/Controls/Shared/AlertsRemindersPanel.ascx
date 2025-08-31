<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AlertsRemindersPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_AlertsRemindersPanel" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<div class="alerts-reminders-panel" data-status='<%=SerializedAlerts() %>'>
	<div class="form-inline">
		<div class="alert-type-panel">
			<p><button data-role="submit" class="btn btn-sm btn-default">Add</button>
			an Alert</p>
			<div class="row">
				<div class="col-xs-6">
					<div class="radio"><label><input type="radio" name="alert-type" value="8"/> Reminder to all assignees</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value="1"/> When task goes overdue</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value="2"/> Recurring after the overdue</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value="4"/> When schedule is edited</label></div>
				</div>
				<div class="col-xs-6">
					<div class="radio"><label><input type="radio" name="alert-type" value="9"/> Reminder to all assignees X hour(s) before due</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value ="7"/> When task is completed</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value ="3"/> When assignments are changed</label></div>
					<div class="radio"><label><input type="radio" name="alert-type" value="5"/> Custom alert</label></div>
				</div>
			</div>
			<p></p>
		</div>
		<div class="alerts-email-panel hidden">
			<input type="hidden" id="groupID" value="<%# QProcess.Session.CurrentSession.QUser.GroupId %>" />
			<p>Send Email To: 
                <select data-role="complex-select" class="form-control input-sm">
                    <asp:repeater ID="rptEmail" DataSource=<%# Assignees %> runat="server">
					    <itemtemplate>
						    <option value=<%#Eval("Id") %>><%#Eval("Name") %></option>
					    </itemtemplate>
				    </asp:repeater>
                </select>
			</p>
		</div>
		<div class="alerts-every-panel hidden">
			<p>Every <input type="text" class="input-sm" style="max-width:35px;"/> hours</p>
		</div>
        <div class="alerts-hours-before-panel hidden">
            <p><input type="text" data-role="datepicker" class="input-sm" maxlength="4" value="1" style="width:50px;"/> hour(s) before due</p>
        </div>
        <div class="alerts-days-before-panel hidden">
            <p><input type="text" data-role="datepicker" class="input-sm" maxlength="4" value="0" style="width:50px;"/> days before due</p>
        </div>
		<div class="alerts-time-panel hidden">
			<p>Alert Time: 
			<select data-role="complex-select" class="form-control input-sm">
				<asp:repeater ID="Repeater1" DataSource=<%# TimeOptions %> runat="server">
					<itemtemplate>
						<option value=<%#Eval("Key") %>><%#Eval("Value") %></option>
					</itemtemplate>
				</asp:repeater>
			</select></p>
		</div>
		<div class="alerts-text-panel hidden">
			<p>Text of the email: <textarea class="form-control input-sm" rows="6" style="width:100%;resize:vertical;"></textarea></p>
		</div>
		<div class="table-responsive">
			<table data-role="dragndrop-reorderable" class="alerts-table hidden table table-condensed table-listing">
				<thead><tr>
					<th> </th>
					<th>Type</th>
					<th>Alertee</th>
					<th>Days Before</th>
					<th>Time</th>
					<th>Custom Text</th>
				</tr></thead>
				<tbody></tbody>
			</table>
		</div>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/AlertsRemindersPanel.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

