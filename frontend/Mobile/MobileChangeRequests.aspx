<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileChangeRequests.aspx.cs" Inherits="QProcess.Mobile.MobileChangeRequests" MasterPageFile="Mobile.master" %>

<%@ Register TagPrefix="shared" TagName="MobileChangeRequest" Src="~/Controls/Shared/MobileChangeRequest.ascx" %>

<asp:Content runat="server" ID="head" ContentPlaceHolderID="headContent">
    <%--<link href="/Content/MobileChangeRequests.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/MobileChangeRequests.css")).Ticks.ToString() %>" rel="stylesheet" />--%>
    <style type="text/css">
        .text-header {
            height: 10px;
        }

        .change-request-header {
    color: #333333;
    background: #F3F0DF;
    /*padding: 2px 10px;*/
    border: 1px solid #ADADAD;
    font-weight: bold;
}

        .collapsible-item .collapsed {
            display: none;
        }

        div.large-div, div.medium-div {
            width: 100%;
        }

        .change-request-titles {
            width: 100% !important;
        }

        #mobileTitle {
            padding: 3px 5px;
        }

        .centeredWide {
            margin-top: 16px;
        }

        .checklist-name table tbody tr {
            margin-bottom: 10px;
            display: block;
            padding: 1px;
        }

        #user-change-requests .checklist-name {
            width: auto !important;
        }

        .checklist-name table tbody tr td {
            display: block;
            /*width: 100% !important;*/
            border: 0 !important;
            padding: 5px;
        }

        #supervisor-change-requests .checklist-name {
            width: 100%;
        }

        .float-right {
            float: none !important;
        }

        .cr-header-actions {
            width: 100%;
            text-align: center;
        }

            .cr-header-actions > a {
                /*			color: #fff !important;
			background-color: #6c757d;
			border-color: #6c757d;*/
                padding: 5px 14px;
                margin-bottom: 10px;
                color: #fff !important;
                background-color: #28a745;
                border-color: #28a745;
                font-size: 13pt;
            }

        span.data-label {
            display: block !important;
            visibility: visible !important;
            font-weight: normal;
            color: #0071eb;
            font-size: 0.92em;
        }

        h4 {
            margin-top: 10px;
        }

        .change-request-header .fa {
            /*position: absolute;*/
            right: 28px;
            font-size: 16pt;
        }

        .change-request {
            padding: 0;
            margin: 3px 0;
        }

        h4 {
            margin-top: 10px;
            background-color: #ECE9D8;
            border: 1px solid #000;
            border-bottom: 1px solid #000;
            padding: 5px;
        }

        fa {
            float: left;
            margin-top: 4px;
        }

        .has-expand {
            display: block;
            margin-left: 25px;
        }

        .checklist-name table tbody tr td {
            display: inline !important;
            /* width: 100% !important; */
            border: 0 !important;
            padding: 5px;
        }

        .reply-comments {
            height: 100px;
            width: 100%;
        }

        /*.change-request-legend {
            width: 100%;
        }*/

        .change-request-legend {
    width: 100%;
    border: 1px solid black;
    top: 25%;
    background: aliceblue;
    padding: 0px 10px;
    margin-top: 5px;
}

    .change-request-legend p {
        margin-left: 20px;
    }

    .change-request-legend ul li {
        display: inline-block;
        margin-left: 15px;
    }

        #sliderPlaceholder {
            margin-top: 20px;
        }
    </style>
    <script type="text/javascript">
        var mobileTitle = "Change Requests";
    </script>
</asp:Content>

<asp:Content runat="server" ID="main" ContentPlaceHolderID="formContent">
    <div class="centeredWide">
        <div>
            Order By:
            <asp:DropDownList CssClass="form-control" ID="ddlSort" runat="server" AutoPostBack="true">
                <asp:ListItem Text="Date Change Was Requested" Value="0"></asp:ListItem>
                <asp:ListItem Text="Requestor Name" Value="1"></asp:ListItem>
                <asp:ListItem Text="New Deadline" Value="2"></asp:ListItem>
            </asp:DropDownList>
        </div>
        <div class="change-request-legend">
            <ul syle="font-size: 11pt !important" id="crLegend">
                <li>&bull;<span style="color: green; font-size: 14px; margin-left: 5px;"><b>[TC]Task Completed</b></span></li>
                <li>&bull;<span style="color: red;  font-size: 14px; margin-left: 5px;"><b>[LTE]Long Term Extension</b></span></li>
                <li>&bull;<span style="color: darkred; font-size: 14px; margin-left: 5px;"><b>[3XE]Extended > 3 Times</b></span></li>
                <li>&bull;<span style="color: darkmagenta; font-size: 11px; margin-left: 5px;"><b>[RDP]Requested Deadline Passed; Approving <%=NextOfficeDay.ToString("MM/dd") %></b></span></li>
            </ul>
        </div>
        <div>
            <h4><i id="userExpandAll" class="fa fa-plus-square-o"></i><span class="has-expand">Other People's Requests for Changes to Tasks I Control</span></h4>
        </div>
        <div id="user-change-requests" class="medium-div">
            <asp:Repeater runat="server" DataSource="<%# SupervisorChangeRequests %>" ID="userChangeRequestRepeater">
                <ItemTemplate>
                    <shared:MobileChangeRequest Repository="<%#ChangeRequestRepo%>" ChangeRequest="<%#GetDataItem() %>" runat="server" />
                </ItemTemplate>
            </asp:Repeater>
        </div>
        <div class="large-div">
            <h4><i id="supervisorExpandAll" class="fa fa-plus-square-o"></i><span class="has-expand">My Requests to Others</span></h4>
        </div>
        <div id="supervisor-change-requests" class="medium-div">
            <asp:Repeater runat="server" DataSource="<%#UserChangeRequests%>" ID="supervisorChangeRequestRepeater">
                <ItemTemplate>
                    <shared:MobileChangeRequest Repository="<%#ChangeRequestRepo%>" ChangeRequest="<%#GetDataItem() %>" runat="server" />
                </ItemTemplate>
            </asp:Repeater>
        </div>
        <div id="universal-extension-change-requests">
            <%--added by venkat 11/15/2017--%>
            <div class="large-div">
                <h4><i id="universalRequestsExpandAll"></i><span>Universal Extension Change Requests</span></h4>
            </div>

            <div style="margin-left: 245px;" id="univExtChangeRequestsdata">
            </div>


        </div>

    </div>
    <div data-role="email-area" class="hidden">
    </div>
    <input type="hidden" id="user-full-name" value="<%=CurrentSession.QUser.FullName%>" />
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="../Scripts/MobileChangeRequest.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("../Scripts/MobileChangeRequest.js")).Ticks.ToString() %>"></script>
  

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

