<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Dashboard.aspx.cs" Inherits="QProcess.Dashboard" MasterPageFile="~/Site.master" %>


<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link href="Content/Dashboard.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Content/Dashboard.css")).Ticks.ToString() %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/Dashboard.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("/Scripts/Dashboard.js")).Ticks.ToString() %>"></script>
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <div id="controls-container">
    </div>
    <div id="dashContainer">
        <div class="graph-container">
            <div class="progress-label" id="activeProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <label id="activeLabel" for="activeEmployeeTasks" class="graph-label" style="display: none;">Active Tasks<span style="font-size: 12px;"><i>* Click label to hide/unhide metric.</i></span></label>
            <canvas id="activeEmployeeTasks" class="base-graph" data-graph-type="bar"></canvas>
        </div>
        <div class="graph-container">
            <div class="progress-label" id="historyProgress">
                <img src="images/searching.gif" />
                Loading...please wait
            </div>
            <label id="historyLabel" for="taskHistory" class="graph-label" style="display: none;">Task Completion History (Over 30 Days)<span style="font-size: 12px; float: right;"><i>* Click label to hide/unhide metric.</i></span></label>
            <canvas id="taskHistory" class="base-graph" data-graph-type="bar"></canvas>
        </div>
    </div>

    <div id="filterDialog" style="display: none;" class="filter-hidden" role="main">
        <div id="filterHeader" class="filter-header">
            <span onclick="openFilters()" class="float-right"><i class="fa fa-close"></i></span>
            <div id="filterTitle" class="dialog-title">
                <h3>Please select any of the following filters</h3>
            </div>
            <div id="filtercontrols" class="filter-controls">
                <div style="display: flex; flex-direction: column; align-items: flex-start;">
                    <div>
                        <label class="filter-item" for="supervisedGroupsSelect">By Group:</label>
                        <select class="filter-item" id="supervisedGroupsSelect">
                            <option value="0">--</option>
                            <asp:Repeater ID="SupervisedGroupsRepeater" runat="server">
                                <ItemTemplate>
                                    <option value="<%#Eval("Id") %>"><%#Eval("GroupName") %></option>
                                </ItemTemplate>
                            </asp:Repeater>
                        </select>
                    </div>
                    <div style="display: flex; align-items: center;">
                        <span id="directSupervised" style="margin-right: 5px;"><b>Directly Supervised</b></span>
                        <input type="checkbox" name="slider" value="allEmployees" id="slider" checked />
                        <%--<div class="filter-item" style="width: 55px;" id="slider"></div>--%>
                        <span style="margin-left: 5px;" id="allEmployees">All</span>
                    </div>
                </div>
                <button class="env-specific-btn filter-item" id="selectAllUsers">Toggle All</button>
                <button class="env-specific-btn filter-item" id="runSearch">Run Search</button>
            </div>
        </div>
        <hr>
        <div id="filterContent" class="filter-content">
            <div id="user-container">
                <div style="margin-left: 15px;" id="userCheckBoxes"></div>
                <hr />
                <div style="margin-left: 15px;" id="allUserCheckBoxes"></div>
            </div>
        </div>
    </div>
    <input type="hidden" id="supervisorId" value="<%= SupervisorID %>" />
    <input type="hidden" id="systemFirm" value="<%= Firm %>" />
    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>
