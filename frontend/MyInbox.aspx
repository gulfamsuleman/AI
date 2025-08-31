<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="MyInbox.aspx.cs" Inherits="QProcess.MyInbox" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="myinbox" TagName="ReportToolbar" Src="~/Controls/Shared/ReportToolbar.ascx" %>
<%@ Register TagPrefix="myinbox" TagName="ReportsView" Src="~/Controls/MyInbox/InboxReportsView.ascx" %>
<%@ Register TagPrefix="myinbox" TagName="Throbber" Src="~/Controls/Shared/Throbber.ascx" %>
<%@ Register TagPrefix="mystatus" TagName="Filters" Src="~/Controls/Shared/Filters.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/MyInbox.css?v=<%=System.IO.File.GetLastWriteTime(Server.MapPath($"Content/MyInbox.css"))%>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/json2.js"></script>
     <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script> 
	<script src="Scripts/MyInbox.js?ver=2025072501"></script>
<script src="Scripts/ReportToolbar.js?ver=<%=System.IO.File.GetLastWriteTime(Server.MapPath($"Scripts/ReportToolbar.js"))%>"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<mystatus:Filters runat="server"/>
	<input type="hidden" id="ReportId" value="<%=ReportId %>" />
	<input type="hidden" id="TaskId" value="<%=TaskId %>" />
	<div id="my-inbox-panel">
		<div id="toolbar">
			<myinbox:ReportToolbar ID="ReportToolbar" runat="server"/>	
		</div>
		<myinbox:Throbber runat="server" />
		<div id="main-content">
			<myinbox:ReportsView ID="ReportsView" runat="server"/>
		</div>
	</div>
	<input type="hidden" id="user-name" value="<%= QProcess.Session.CurrentSession.QUser.FullName %>" />
	<input type="hidden" id="user-shortname" value="<%= QProcess.Session.CurrentSession.QUser.Username %>" />

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

