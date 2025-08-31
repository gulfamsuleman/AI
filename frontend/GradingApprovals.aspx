<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="true" CodeBehind="GradingApprovals.aspx.cs" Inherits="QProcess.GradingApprovals" MasterPageFile="Site.master" %>
<%@ Register TagPrefix="grading" TagName="GradingPeriods" Src="~/Controls/Grading/GradingPeriods.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingVacations" Src="~/Controls/Grading/GradingVacations.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingReportsOnHold" Src="~/Controls/Grading/GradingReportsOnHold.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/GradingApprovals.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/GradingApprovals.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="grading-approval-panel">
		<h2>Approvals</h2>
		<br />
		<a href="GradingAdmin.aspx">Admin Page</a>
		<br/>
		<span>
			GradingPeriod: 
			<grading:GradingPeriods ID="GradingPeriodsControl" runat="server"/>
		</span>
		<br/>
		<br/>
		<div class="row">
			<div class="col-xs-6">
				<grading:GradingVacations ID="GradingVacationsControl" runat="server"/>
			</div>
			<div class="col-xs-6">
				<grading:GradingReportsOnHold ID="GradingReportsOnHoldControl" runat="server"/>
			</div>
		</div>
	</div>
	<input id="start-period" type="hidden" value="<%=PeriodDates.Item1 %>"/>
	<input id="end-period" type="hidden" value="<%=PeriodDates.Item2 %>"/>
	<input id="is-approval" type="hidden" value="<%=IsApproval %>"/>

<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


