<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Grading.aspx.cs" Inherits="QProcess.Grading" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="grading" TagName="GradingPeriods" Src="~/Controls/Grading/GradingPeriods.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingDeductions" Src="~/Controls/Grading/GradingDeductions.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingVacations" Src="~/Controls/Grading/GradingVacations.ascx" %>
<%@ Register TagPrefix="grading" TagName="GradingReportsOnHold" Src="~/Controls/Grading/GradingReportsOnHold.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Grading.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/Grading.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="grading-panel">
		<h2>Grading</h2>
		<br/>
		<% if (IsGradingAdmin) { %>
			<a href="GradingAdmin.aspx">Admin Page</a>
		<% } %>
		<br/>
		<grading:GradingPeriods ID="GradingPeriodsControl" runat="server"/>
		<grading:GradingDeductions ID="GradingDeductionsControl" runat="server"/>
		<hr/>
		<grading:GradingVacations ID="GradingVacationsControl" runat="server"/>
		<hr/>
		<grading:GradingReportsOnHold ID="GradingReportsOnHoldControl" runat="server"/>
		<input id="start-period" type="hidden" value="<%=PeriodDates.Item1 %>"/>
		<input id="end-period" type="hidden" value="<%=PeriodDates.Item2 %>"/>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


