<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ComplexTask.ascx.cs" Inherits="QProcess.Controls.Controls_NewTask_ComplexTask" %>

<%@ Register Src="~/Controls/Shared/SchedulingPanel.ascx" TagPrefix="uc1" TagName="SchedulingPanel" %>
<%@ Register Src="~/Controls/Shared/AlertsRemindersPanel.ascx" TagPrefix="uc1" TagName="AlertsRemindersPanel" %>
<%@ Register Src="~/Controls/Shared/ControllersPanel.ascx" TagPrefix="uc1" TagName="ControllersPanel" %>
<%@ Register Src="~/Controls/Shared/AssignedToPanel.ascx" TagPrefix="uc1" TagName="AssignedToPanel" %>
<%@ Register Src="~/Controls/Shared/ChecklistItemsPanel.ascx" TagPrefix="uc1" TagName="ChecklistItemsPanel" %>
<%@ Register Src="~/Controls/Shared/StatusReportsPanel.ascx" TagPrefix="uc1" TagName="StatusReportsPanel" %>
  
<div class="row" style="margin-top:5px;">
	<div class="col-xs-6">
		<h4 class="task-name">Task Name: <span style="text-decoration:underline;"><%: ChecklistName %></span></h4>
    
	</div>
 
	<div class="col-xs-6 text-right">
		<input type="button" value="Save And Continue" data-role="continue" class="btn btn-submit-complex"/>
	</div>
</div>
<div class="row" data-instance-id="<%: InstanceId %>" data-checklist-id="<%: ChecklistId %>" data-change-id="-1">
	<div class="col-xs-5">
		<fieldset><legend>Scheduling</legend>
			<uc1:SchedulingPanel runat="server" ID="SchedulingPanel" InstanceId="<%# InstanceId %>" ChangeId="0" />
		</fieldset>
		<fieldset><legend>Alerts/Reminders</legend>
			<uc1:AlertsRemindersPanel runat="server" ID="AlertsRemindersPanel" InstanceId="<%# InstanceId %>" />
           
		</fieldset>
        <fieldset><legend>Priorities</legend> <%--added by venkat 06/15/2018--%>
      <label>
       <input type="checkbox" name="chkAddToPriorityListComplex" id="chkAddToPriorityListComplex"/>
          Add Task To Priority List
     </label>

        </fieldset>
       
	</div>
	<div class="col-xs-7">
		<fieldset><legend>Checklist Items</legend>
			<uc1:ChecklistItemsPanel runat="server" ID="ChecklistItemsPanel" ChecklistId="<%# ChecklistId %>" ChangeId="0" />
		</fieldset>
		<fieldset style="display:inline; width:33%"><legend>Controllers</legend>
			<uc1:ControllersPanel runat="server" id="ControllersPanel" ChecklistId="<%# ChecklistId %>" />
		</fieldset>
		<fieldset style="display:inline; width:33%"><legend>Assigned To</legend>
			<p>Who is assigned to complete the task?</p>
			<uc1:AssignedToPanel runat="server" id="AssignedToPanel" InstanceId="<%# InstanceId %>" ChangeId="0" />
		</fieldset>
		<fieldset style="display:inline; width:33%"><legend>Status Reports</legend>
			<p>Which status report(s) should this task go on?</p>
			<uc1:StatusReportsPanel runat="server" ID="StatusReportsPanel" InstanceId="<%# InstanceId %>" ChangeId="0" UserId="<%# UserId %>"/>
		</fieldset>
	</div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

