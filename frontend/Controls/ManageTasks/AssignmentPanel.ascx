<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AssignmentPanel.ascx.cs" Inherits="QProcess.Controls.Controls_ManageTasks_AssignmentPanel" %>
<%@ Register Src="~/Controls/Shared/AssignedToPanel.ascx" TagPrefix="uc1" TagName="AssignedToPanel" %>
<%@ Register Src="~/Controls/Shared/StatusReportsPanel.ascx" TagPrefix="uc1" TagName="StatusReportsPanel" %>
<%@ Register Src="~/Controls/Shared/SchedulingPanel.ascx" TagPrefix="uc1" TagName="SchedulingPanel" %>
<%@ Register Src="~/Controls/Shared/AlertsRemindersPanel.ascx" TagPrefix="uc1" TagName="AlertsRemindersPanel" %>
<%@ Register Src="~/Controls/ManageTasks/WorkingOnNow.ascx" TagPrefix="uc1" TagName="WorkingOnNow" %>

<div class='mtform-assignments panel panel-default collapsible-item' data-collapse-state='collapsed' data-num='<%:AssignmentNumber %>' data-instance-id="<%:InstanceId %>">
	<div class='panel-heading' data-collapse-target='true'>
		<span class='actions'>
            <i class='fa fa-plus-square-o' data-role='expand-indicator'></i>
            <a data-role="delete"><img id="Img1" src="/Images/delete.gif" title="Remove" runat="server" style="margin-top:-3px;" /></a>
            <a data-role="copy"><img id="Img2" src="/Images/copy.gif" title="Copy" runat="server" style="margin-top:-3px;" /></a>
		</span>
		<h3 class='panel-title'>Assignment #<span data-role="instance-number"><%:AssignmentNumber %></span></h3>
	</div>
	<div class='panel-body collapsed'>
		<div class="assignment-wrapper">
			<div class="row">
				<div class="col-xs-4">
					<uc1:WorkingOnNow InstanceId="<%# InstanceId %>" ChangeId="<%# ChangeId %>" runat="server"></uc1:WorkingOnNow>
				</div>
				<div class="col-xs-4">
					<fieldset><legend>Who Is This Assigned To?</legend>
						<uc1:AssignedToPanel runat="server" InstanceId="<%#InstanceId %>" ID="AssignedToPanel" />
					</fieldset>
				</div>
				<div class="col-xs-4">
					<fieldset><legend>What Status Reports Should It Go On?</legend>
						<uc1:StatusReportsPanel runat="server" InstanceId="<%#InstanceId %>" UserId="<%#UserId %>" ID="StatusReportsPanel" />
					</fieldset>
				</div>
			</div>
			<div class="row">
				<div class="col-xs-6">
					<fieldset><legend>Scheduling</legend>
						<uc1:SchedulingPanel runat="server" InstanceId="<%#InstanceId %>" ChangeId="<%# ChangeId %>" ID="SchedulingPanel" />
					</fieldset>
				</div>
				<div class="col-xs-6">
					<fieldset><legend>Alerts/Reminders</legend>
						<uc1:AlertsRemindersPanel runat="server" InstanceId="<%#InstanceId %>" ID="AlertsRemindersPanel"  ChangeId="<%# ChangeId %>"/>
					</fieldset>
				</div>
			</div>
		</div>
	</div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

