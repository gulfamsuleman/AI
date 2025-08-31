<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DashboardDetailedView.aspx.cs" Inherits="QProcess.DashboardDetailedView" MasterPageFile="~/Site.master" %>

<%@ Register TagPrefix="qgraph" TagName="Graph" Src="~/Controls/Shared/QGraphs.ascx" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link href="Content/DashboardDetailedView.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Content/DashboardDetailedView.css")).Ticks.ToString() %>" rel="stylesheet" />
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css">
    <link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet">
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
    <script src="/Scripts/jquery-ui-1.13.2.min.js?2<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/jquery-ui-1.13.2.min.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/DashboardDetailedView.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/DashboardDetailedView.js")).Ticks.ToString() %>"></script>
    <script src="https://cdn.datatables.net/buttons/2.3.1/js/dataTables.buttons.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.3.1/js/buttons.html5.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/2.3.1/js/buttons.print.min.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">

    <% if (!IsOwnDashboard || IsSupervisor) { %>
        <a href="Dashboard.aspx" class="btn btn-link">Return to Dashboard</a>
    <% } %>
    <h4><%= LabelText %></h4>
    <div id="detailContainer">
        <div id="kpiContainer" class="graph-container">
            <div class="date-actions">
                <button data-role="date-range-change" data-value="30" style="margin: 5px;" class="conversion-btn">Over 30 Days</button>
                <button data-role="date-range-change" data-value="60" style="margin: 5px;" class="conversion-btn">Over 60 Days</button>
                <button data-role="date-range-change" data-value="90" style="margin: 5px;" class="conversion-btn">Over 90 Days</button>
                <button data-role="date-range-change" data-value="180" style="margin: 5px;" class="conversion-btn">Over 180 Days</button>
                <span style="margin-left: 15px" id="kpiLabel"><em>*Current Range: <b>30 days</b></em></span>
            </div>
            <div id="kpiProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <div id="graphsContainer">
                <div class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="activeGraph"></canvas>
                    <span id="activeTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
                <div class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="statusReportsGraph"></canvas>
                    <span id="overdueTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
                <div class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="supervisorGraph"></canvas>
                    <span id="supervisorTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
                <div class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="commentsGraph"></canvas>
                    <span id="commentsTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
                <div class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="prioritiesGraph"></canvas>
                    <span id="prioritiesTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
                <div id="finesDiv" class="base-graph">
                    <span class="b-top"></span>
                    <canvas id="finesGraph"></canvas>
                    <span id="finesTool" class="graph-tooltip">?</span>
                    <span class="b-bottom"></span>
                </div>
            </div>
        </div>
        <div class="table-container">
            <div id="statusProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <div id="statusReports"></div>
        </div>
        <div class="table-container">
            <div id="assignmentsProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <div id="assignmentsTable"></div>
        </div>
        <div class="table-container">
            <div id="groupsProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <div id="groupsTable"></div>
        </div>
    </div>

    <input type="hidden" id="userId" value="<%= UserID %>" />
    <input type="hidden" id="supervisorId" value="<%= SupervisorID %>" />
    <input type="hidden" id="systemFirm" value="<%= Firm %>" />
    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>
