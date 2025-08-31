<%@ Control Language="C#" AutoEventWireup="true" Codebehind="InboxReportsView.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_InboxReportsView" %>
<%@ Register TagPrefix="myinbox" TagName="ReportList" Src="~/Controls/MyInbox/ReportList.ascx" %>
<%@ Register TagPrefix="mobilemyinbox" TagName="ReportList" Src="~/Controls/MyInbox/MobileReportList.ascx" %>
<div id="report-view">
	<% if (IsMobile) {%>
	<mobilemyinbox:ReportList ID="MobileUnreadReportListControl" runat="server"/>
	<mobilemyinbox:ReportList ID="MobileReadReportListControl" runat="server" />
	<% } else { %>
	<myinbox:ReportList ID="UnreadReportListControl" runat="server"/>
	<myinbox:ReportList ID="ReadReportListControl" runat="server" />
	<%} %>
	<input id="view-type" type="hidden" value="<%= ViewType %>"/>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

