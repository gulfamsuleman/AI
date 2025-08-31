<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileManageTasks.aspx.cs" Inherits="QProcess.Mobile.MobileManageTasks" MasterPageFile="Mobile.master" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
	<link href="/Content/jstree/mobileStyle.css" rel="stylesheet" />

    <style type="text/css">
        .card-body { background-color: #fff; }
        .card-header { font-size: 15pt; }
        .collapsible-item .collapsed { display: none; }
        #task-container > .col-xs-12 { width: 100%; }
        #task-container { 
            margin: -8px;
        }
        .view-controls {
            position: absolute;
            right: 18px;
            top: 12px;
        }
        .panel-heading {
            background-color: #ebebeb;
            padding: 8px;
            border-radius: 5px;
        }
        .panel-heading .actions {
            float: right;
        }
        .panel-heading h3 {
            margin-right: 50px;
            font-size: 16pt;
        }
        .main-heading .actions {
            margin-right: 40px;
        }
        .panel-default {
            border: 1px solid #ccc;
            margin-top: 10px;
            border-radius: 5px;
        }
        .panel-default .panel-body {
            padding: 8px;
        }
        .hidden {
            display: none;
            visibility: hidden;
        }
        a[data-role='dragndrop-dragpoint'] {
            display: none;
        }
        .panel-body input, .panel-body textarea, .panel-body select {
            margin-top: 3px;
            margin-bottom: 3px;
        }
        .panel-body fieldset { padding: 16px; }
        #name-panel input {
            margin-right: 40px;
        }
        #name-panel i {
            font-size: 20pt;
            position: absolute;
            right: 30px;
        }
        #controllers-panel button {
            position: absolute;
            margin-top: -24px;
        }
        #controllers-panel select {
            margin-left: 50px;
        }
        #checklist-items-panel select {
            width: 85%;
            min-width: 140px;
            margin-left: auto;
        }
        #checklist-items-panel button[data-action='preview'] {
            display: none;
        }
        .weekly-recurring-panel .row,
        .yearly-recurring-panel .row,
        .alert-type-panel .row {
            margin: 0;
        }
        .assignment-wrapper #Select1 { 
            width: 85%;
            margin-left: auto;
        }
        @media (min-width: 321px) {
            .alerts-reminders-panel div.table-responsive {
                width: 335px;
            }
        }
        @media (max-width: 320px) {
            #checklist-items-panel select {
                width: 80%;
            }
            .alerts-reminders-panel div.table-responsive {
                width: 260px;
            }
            .assignment-wrapper #Select1 { 
                width: 80%;
            }
        }
        
        .text-header {
            height: 10px;
        }
        .btn.btn-sm.btn-default {
            color: #333;
            background-color: #fff;
            border-color: #000;
            font-weight: bold;
            padding: 5px 10px;
            font-size: 12px;
            line-height: 1.5;
            border-radius: 3px;
            display: inline-block;
            margin-bottom: 0;
            text-align: center;
            vertical-align: middle;
            border: 1px solid #000;
            white-space: nowrap;
            user-select: none;
            transition: background 0.2s, color 0.2s, border-color 0.2s;
        }
        .btn.btn-sm.btn-default:hover,
        .btn.btn-sm.btn-default:focus,
        .btn.btn-sm.btn-default:active {
            background-color: #ebebeb;
            color: #333;
            border-color: #adadad;
            text-decoration: none;
        }

        .search-row {
            display: flex;
            align-items: center;
        }
        .search-row .form-control {
            flex: 1 1 auto;
        }
        .search-row .btn {
            margin-left: 5px;
        }
    </style>    
	<script src="../Scripts/jstree.min.js"></script>
    <script>
        var mobileTitle = "Manage Tasks";

        var queryChecklistId = "<%=Request.QueryString["checklistid"]%>";
        var clientLoadBegin = new Date(); //harmless; used for a timespan calc for performance
        var Firm = "<%=QProcess.Configuration.AppSettings.Get("Firm")%>";
        var svrTz = <%=TimeZoneInfo.Local.BaseUtcOffset.TotalMilliseconds + (TimeZoneInfo.Local.IsDaylightSavingTime(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) ? 3600000 : 0)%>;
        var clntTz = new Date().getTimezoneOffset() * 60 * -1000; //Necessary new Date(); this avoids an automatic (and wrong) conversion b/w server and client TZ
    </script>
</asp:Content>

<asp:Content ID="slider" runat="server" ContentPlaceHolderID="sliderContent">
    <div id="task-management-attach-point"></div>
    <div class="text-center mt-3">
        <button id="btnCloseWindow" class="btn btn-secondary">Close Window</button>
    </div>
</asp:Content>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="mainContent">
    <form id="exportForm" method="post" action="MobileManageTasksExport.aspx" style="display:none;">
        <input type="hidden" name="group" id="exportGroup" />
        <input type="hidden" name="manager" id="exportManager" />
        <input type="hidden" name="search" id="exportSearch" />
    </form>
    <div class="row mt-2">
        <div class="col">
            <span>Assigned To</span>
            <select data-role="task-group-select" id="task-group" class="form-control my-2 my-sm-0">
                <option value="0">All</option>
            </select>
        </div>
    </div>
    <div class="row">
        <div class="col">
            <span>Controlled By</span>
            <select data-role="task-manager-select" id="task-manager" class="form-control my-2 my-sm-0">
                <option value="0">All</option>
            </select>
        </div>
    </div>
    <div class="row">
        <div class="col">
            <span>Search</span>
            <div class="search-row d-flex align-items-center" style="gap: 5px;">
                <input data-role="task-search" type="text" class="form-control flex-grow-1" id="task-search" />
                <button type="button" id="exportTasksBtn" class="btn btn-sm btn-default ms-1">
                    <img src="/Images/excel.gif" />
                    Export
                </button> 
            </div>
        </div>
    </div>
    <div class="row mt-3 pt-3 border-top border-gray">
		<span id="newFolder">Add Folder</span>
        <% if (QProcess.Session.CurrentSession.QUser.IsAdmin){%>
        <div class="form-check" style="display:inline-block;margin-left:auto;">
            <input id="show-everything" data-role="task-search-admin" type="checkbox" class="form-check-input" />
            <label for="show-everything" style="padding-right: 16px;">Show Everything</label>
        </div>
        <%}%>
        <div id="treePanel" class="col"></div>
    </div>
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script type="text/javascript">
        function loadGroup() {
            Post("../Services/ControlService.asmx/Group_GET", "", function (msg) {
                let rsp = msg.d;
                let ddl = $("#task-manager, #task-group");

                for (let i = 0; i < rsp.length; i++) {
                    ddl.append(`<option value="${rsp[i].Id}">${rsp[i].Name}</option>`);
                }
            });
        }

        $().ready(function () {
            loadGroup();
            $("#btnCloseWindow").on("click", function () {
                slider.toggleClass('open');
            });
        });

        $('#exportTasksBtn').on('click', function () {
            $('#exportGroup').val($('#task-group').val());
            $('#exportManager').val($('#task-manager').val());
            $('#exportSearch').val($('#task-search').val());

            $('#exportForm').submit();
        });
    </script>
    <script src="../Scripts/ManageTasks.js"></script>

    
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

