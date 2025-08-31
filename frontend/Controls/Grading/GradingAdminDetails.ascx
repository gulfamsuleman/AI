<%@ Control Language="C#" AutoEventWireup="true" Codebehind="GradingAdminDetails.ascx.cs" Inherits="QProcess.Controls.Controls_Grading_GradingAdminDetails" %>
<%@ Register TagPrefix="grading" TagName="GradingUsers" Src="~/Controls/Grading/GradingUsers.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingPeriods" Src="~/Controls/Grading/GradingPeriods.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingDeductions" Src="~/Controls/Grading/GradingDeductions.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingVacations" Src="~/Controls/Grading/GradingVacations.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingReportsOnHold" Src="~/Controls/Grading/GradingReportsOnHold.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="grading-admin-details-panel">
	<span>
		User: 
		<grading:GradingUsers ID="GradingUsersControl" runat="server"/>
	</span>
	<br/>
	<span>
		GradingPeriod: 
		<grading:GradingPeriods ID="GradingPeriodsControl" runat="server"/>
	</span>
	<br/>
	<button data-action="recalculate-deductions">Recalculate</button>
	<grading:GradingDeductions ID="GradingDeductionsControl" runat="server"/>
	<div id="adjustment-panel">
		<button data-action="add-adjustment" class="btn btn-sm btn-default">Add Adjustment</button>
		<br/>
		<span>
			Reason: 
			<input id="adjustment-reason" type="text" class="form-control input-sm"/>
		</span>
		<br/>
		<span>
			Amount: 
			<input id="adjustment-points" type="number" class="form-control input-sm"/>
		</span>
		<br/>
		<br/>
		<grading:GradingVacations ID="GradingVacationsControl" runat="server"/>
		<br/>
		<grading:GradingReportsOnHold ID="GradingReportsOnHoldControl" runat="server"/>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/GradingAdminDetails.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

