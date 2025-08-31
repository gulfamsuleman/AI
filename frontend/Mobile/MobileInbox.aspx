<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileInbox.aspx.cs" Inherits="QProcess.Mobile.MobileInbox" MasterPageFile="Mobile.master" %>

<%@ Register TagPrefix="myinbox" TagName="ReportsView" Src="~/Controls/MyInbox/InboxReportsView.ascx" %>
<%@ Register TagPrefix="mystatus" TagName="Filters" Src="~/Controls/Shared/Filters.ascx" %>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="/Scripts/MobileInbox.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath($"/Scripts/MobileInbox.js")).Ticks.ToString() %>"></script>
    <script type="text/javascript">
        var modal = window.modalModule;
        //var reportId = $("#ReportId").val();
        //// Email Comments
        //$("#emailComments").on("click", mobileInboxModule.showEmailCommentsPanel);


        //function emailComments() {
        //    var reportid = $("#report-id").val();

        //    var inbox = false;
        //    if (window.myInboxModule) { inbox = true; }
        //    var params = {
        //        mode: "comments",
        //        ReportId: reportid,
        //        isUrgent: false,
        //        inbox: inbox
        //    };
        //    openEmailModal(params, "Email Comments");
        //}

        //function openEmailModal(params, title) {
        //    modal.init({
        //        titleText: title,
        //        controlName: "Controls/MyStatus/EmailComments.ascx",
        //        remoteParams: params
        //    });
        //}

        //$(document).ready(function () {
        //    $(document).on("click", "a[data-action='email-comments']", function () {
        //        emailComments();
        //    });
        //});

        $(function () {
            'use strict'

            $("#emailComments").on("click", function () {
                var reportId = $(this).attr("data-id");
                if (!reportId) return;
                mobileInboxModule.showEmailCommentsPanel(reportId);
                //$(this).hide();
                //$("#changeReport .return").click();
            });

            $("#changeReport .return").on("click", function () {
                var viewType = $("#view-type").val();
                myInboxModule.loadReport(viewType);
                $(this).hide();
                $("#changeReport .markRead").hide();
                $("#changeReport .emailComments").hide();
                $("#changeReport .changeReport").show();
            });
            $("#changeReport .markRead").on("click", function () {
                var reportId = $(this).attr("data-id");
                if (!reportId) return;
                myInboxModule.markReportAsRead(reportId);
                $(this).hide();
                $("#changeReport .return").click();
            });
            $("#changeReport .changeReport").on("click", function () { $("#ddlReportHeader").click(); });
            $('#ddlReportHeader').mobiscroll().select({
                theme: getMobileOperatingSystem(),
                display: 'modal'
            });
            $("#ddlReportHeader").on("change", function (e) {
                var opt = $(this);
                if (opt.val() == "0") return;

                myInboxModule.loadReport(opt.val());
            });
            $(".fa-address-book").on("click", function () {
                $(".buttons").toggleClass("hidden");
                slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
                slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/MyInbox/ManageEmails.ascx"), {}, function () {
                    slider.prepend("<h3>Manage Email Settings</h3><hr>");
                    slider.append(`
                <div class="row">
                    <div class="col text-center mt-3">
                    <button class="btn btn-secondary close-button">Close Window</button>
                    </div>
                </div>`);
                    slider.find(".close-button").on("click", function () {
                        slider.toggleClass('open');
                    });
                });
                slider.toggleClass('open');
            });
        });
    </script>
    <script src="../Scripts/MyInbox.js?ver=2024042401"></script>
</asp:Content>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
    <link href="../Content/MyInbox.css?v=2" rel="stylesheet" />
    <style type="text/css">
        #main {
            padding-top: 16px;
        }

        #ddlReportHeader_dummy {
            display: none;
        }

        .hidden {
            display: none;
            visibility: hidden;
        }

        .fa-address-book {
            position: absolute;
            right: 10px;
            padding: 5px;
            padding-top: 0;
            font-size: 16pt;
            margin-right: 6px;
        }

        i.label {
            font-size: 12pt;
            font-weight: bold;
            color: #5b5b5b;
        }

        span.report-name {
            font-size: 16pt;
        }

        #changeReport span {
            margin-right: 10px;
        }
    </style>
    <style type="text/css">
        #main {
            padding-top: 16px;
            margin-top: 56px;
        }

        .card-body {
            background-color: #fff;
        }

        .card-header {
            font-size: 15pt;
        }

        .collapsible-item .collapsed {
            display: none;
        }

        #task-container > .col-xs-12 {
            width: 100%;
        }

        #task-container {
            /*            border: 1px solid #ccc;
            border-radius: 5px;*/
            margin: -8px;
        }

        .recurring-indicator {
            position: absolute;
            right: 24px;
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

        a[data-role='dragndrop-dragpoint'] {
            display: none;
        }

        .panel-body input, .panel-body textarea, .panel-body select {
            margin-top: 3px;
            margin-bottom: 3px;
        }

        .panel-body fieldset {
            padding: 16px;
        }

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
            margin-left: auto;
        }

        #checklist-items-panel button[data-action='preview'] {
            display: none;
        }

        .weekly-recurring-panel .row,
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

        a {
            color: #003366;
        }

        table {
            display: table !important;
        }

            table tr {
                display: block !important;
            }

                table tr.report-header-column {
                    display: none !important;
                }

                table tr.report-line-border {
                    border-color: #b2b26f;
                }

                table tr.report-line-content {
                    border-radius: 5px;
                    margin-bottom: 10px;
                    padding: 1px;
                    border: 1px solid #b2b26f;
                }

        tr.report-line-header {
            border-radius: 5px;
        }

        table tr.report-line-ender {
            display: none !important;
        }

        table tr td {
            display: block;
        }

        table.status-table tbody td {
            border: 0 !important;
        }

        td.report-line-subheader {
            font-size: 16pt;
            text-decoration: none !important;
        }

        .na-row {
            display: none;
        }

        span.data-label {
            display: block !important;
            visibility: visible !important;
            font-weight: bold;
        }

        span.overduespan {
            display: inline-block;
        }

        div[data-role=comment-buttons] > div {
            width: 67% !important;
            display: block !important;
            margin-left: auto;
            margin-right: auto;
        }

            div[data-role=comment-buttons] > div > button {
                width: 100% !important;
                margin: 4px 0;
                padding: 10px 0px;
                font-size: 14pt;
            }

                div[data-role=comment-buttons] > div > button[data-role=save] {
                    color: #fff;
                    background-color: #28a745;
                    border-color: #28a745;
                }

                div[data-role=comment-buttons] > div > button[data-role=response-requested] {
                    color: #fff;
                    background-color: #dc3545;
                    border-color: #dc3545;
                }

                div[data-role=comment-buttons] > div > button[data-role=cancel-comment] {
                    color: #fff;
                    background-color: #6c757d;
                    border-color: #6c757d;
                }

                div[data-role=comment-buttons] > div > button[data-role=add-link] {
                    color: #fff;
                    background-color: #17a2b8;
                    border-color: #17a2b8;
                }

        td.report-line-task-general-comment {
            height: auto !important;
        }

        tbody tr td[data-role=priority],
        tbody tr td[data-role=action] {
            background-color: #ece9d8;
        }

        table.status-table td[data-role=priority] {
            display: inline-block !important;
            position: relative;
            top: -58px;
            float: right;
            background-color: transparent;
        }

            table.status-table td[data-role=priority] input {
                padding: 0;
            }

        #ddlReportHeader {
            margin-bottom: 10px;
            border-color: #b2b26f;
            background-color: #ffffed;
        }

        #navSlideLayer div.preview {
            width: 100% !important;
            overflow-x: auto;
            overflow-y: auto;
        }

            #navSlideLayer div.preview table {
                width: 100% !important;
            }

                #navSlideLayer div.preview table tr {
                    display: table-row !important;
                }

                #navSlideLayer div.preview table td {
                    display: table-cell !important;
                }

        body {
            overflow-x: unset;
        }

        .nav-scroller {
            position: sticky;
            top: 40px;
        }
        /*        table.status-table.collapsible-item
        {
            border-radius: 5px;
            border: 1px solid #003366;
            padding: 1px;
            border-collapse: separate;
            margin-top: 16px;
            background-color: #0033660f;
        }
        table.status-table.collapsible-item tr:nth-last-child(2) {
            margin-bottom: 0;
        }
        td.report-line-subheader {
            padding-top: 0;
        }*/
    </style>

    <script>
        var mobileTitle = "Inbox";
    </script>
</asp:Content>

<asp:Content ID="nav" runat="server" ContentPlaceHolderID="navContent">
    <%--<i class="fa fa-address-book"></i>--%>
    <div class="nav-scroller bg-white box-shadow text-center text-header">
        <div id="changeReport" style="font-size: 13pt">
            <span class="return"><i class="fa fa-undo"></i>
                Back</span>
            <span class="markRead" data-id=""><i class="fa fa-eye"></i>
                Mark Read</span>

            <span id="emailComments" class="emailComments" title="Email All Comments I Added in the Last Hour" data-id=""><i class="fa fa-envelope"></i>
                Email Comments</span>

            <span class="changeReport"><i class="fa fa-sitemap"></i>
                Change Inbox</span>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="mainContent">
    <select id="ddlReportHeader" class="form-control" style="display: none">
        <option value="1">Supervisor</option>
        <option value="2">Interested Party</option>
        <option value="4">My Favorites</option>
    </select>
    <mystatus:Filters runat="server" />
    <input type="hidden" id="ReportId" value="<%=ReportId %>" />
    <input type="hidden" id="TaskId" value="<%=TaskId %>" />
    <div id="my-inbox-panel">
        <div id="main-content">
            <myinbox:ReportsView ID="ReportsView" IsMobile="true" runat="server" />
        </div>
    </div>
    <input type="hidden" id="user-name" value="<%= QProcess.Session.CurrentSession.QUser.FullName %>" />
    <input type="hidden" id="user-shortname" value="<%= QProcess.Session.CurrentSession.QUser.Username %>" />


    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

