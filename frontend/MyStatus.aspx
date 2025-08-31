<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="MyStatus.aspx.cs" Inherits="QProcess.MyStatus" MasterPageFile="Site.master"%>
<%@ Register TagPrefix="mystatus" TagName="ReportToolbar" Src="~/Controls/Shared/ReportToolbar.ascx" %>
<%@ Register TagPrefix="mystatus" TagName="Throbber" Src="~/Controls/Shared/Throbber.ascx" %>
<%@ Register TagPrefix="mystatus" TagName="Filters" Src="~/Controls/Shared/Filters.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/MyStatus.css?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/MyStatus.css")).Ticks.ToString() %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/json2.js"></script>
	<script src="Scripts/MyStatus.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/MyStatus.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/ReportToolbar.js?ver=5"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<mystatus:Filters runat="server"/>
	<mystatus:Throbber runat="server"/>
	<div id="status-report-container">
        <div id="toolbar">
		    <mystatus:ReportToolbar ID="ReportToolbar" runat="server"/>    
        <%
            var metaItems = new List<string>();
            if (!string.IsNullOrWhiteSpace(ControllersList))
                metaItems.Add("<span class='meta-row'><span class='meta-label'>Controllers:</span> <span class='meta-value'>" + ControllersList + "</span></span>");
            if (!string.IsNullOrWhiteSpace(SupervisorsList))
                metaItems.Add("<span class='meta-row'><span class='meta-label'>Supervisors:</span> <span class='meta-value'>" + SupervisorsList + "</span></span>");
            if (!string.IsNullOrWhiteSpace(InterestedPartiesList))
                metaItems.Add("<span class='meta-row'><span class='meta-label'>Interested Parties:</span> <span class='meta-value'>" + InterestedPartiesList + "</span></span>");
        %>
        <div id="report-meta" class="report-meta" style="display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 0;">
            <%= string.Join("<span class='meta-divider'>|</span>", metaItems) %>
        </div>
        </div>
        <div id="status-report">

        </div>
	</div>
	<input type="hidden" id="user-name" value="<%= CurrentSession.QUser.FullName %>" />
	<input type="hidden" id="user-id" value="<%= UserId %>" />
	<input type="hidden" id="report-id" value="<%= ReportId %>"/>
	<input type="hidden" id="task-id" value="<%= TaskId %>"/>
	<input type="hidden" id="is-archive" value="<%= IsArchive %>"/>
	<input type="hidden" id="tasks-controlled" value="<%= TasksIControl %>" />
    <iframe style="width:1024px;height:768px;z-index:20000;display:none" id="divPreview"></iframe>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

