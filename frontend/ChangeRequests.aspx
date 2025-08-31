<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ChangeRequests.aspx.cs" Inherits="QProcess.ChangeRequests" MasterPageFile="Site.master" %>

<%@ Register TagPrefix="mytasks" TagName="ChangeRequest" Src="~/Controls/ChangeRequests/ChangeRequest.ascx" %>

<asp:Content runat="server" ID="Content1" ContentPlaceHolderID="HeadContent">
    <link href="Content/ChangeRequests.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/ChangeRequests.css")).Ticks.ToString() %>" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script>
    <script src="Scripts/ChangeRequests.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/ChangeRequests.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content runat="server" ID="Content3" ContentPlaceHolderID="MainContent">
    <form runat="server" style="width: auto; overflow-x: revert;">
        <div class="change-request-section-container">
            <div class="sort-and-legend large-div">
                <div>
                    Order By:
                    <asp:DropDownList ID="ddlSort" runat="server" AutoPostBack="true">
                        <asp:ListItem Text="Date Change Was Requested" Value="0"></asp:ListItem>
                        <asp:ListItem Text="Requestor Name" Value="1"></asp:ListItem>
                        <asp:ListItem Text="New Deadline" Value="2"></asp:ListItem>
                    </asp:DropDownList>
                    <div style="display: grid; grid-auto-flow: column; justify-content: center; align-items: center;" id="slider-container">
                        <div id="slider-label">Font Size:</div>
                        <div style="margin-left: 10px; width: 150px;" id="slider"></div>
                        <div style="margin-left: 10px;" id="row-slider-label">Row Height:</div>
                        <div style="width: 50px; margin-left: 15px; margin-right: 15px;" id="row-slider"></div>
                    </div>
                </div>

                <div class="change-request-legend">
                    <ul syle="font-size: 11pt !important" id="crLegend">
                        <li>&bull;<span style="color: green; font-size: 13px; margin-left: 5px;"><b>[TC]Task Completed</b></span></li>
                        <li>&bull;<span style="color: red; font-size: 13px; margin-left: 5px;"><b>[LTE]Long Term Extension</b></span></li>
                        <li>&bull;<span style="color: darkred; font-size: 13px; margin-left: 5px;"><b>[3XE]Extended > 3 Times</b></span></li>
                        <li>&bull;<span style="color: darkmagenta; font-size: 13px; margin-left: 5px;"><b>[RDP]Requested Deadline Passed; Approving <%=NextOfficeDay.ToString("MM/dd") %></b></span></li>
                    </ul>
                </div>
            </div>
            <div class="centeredWide">

                <div class="large-div">
                    <div class="table-header">
                        <h4><i id="supervisorExpandAll" class="fa fa-plus-square-o"></i>Other People's Requests for Changes to Tasks I Control:</h4>
                        <span><em>*Columns can be resized by dragging headers left or right.</em></span>
                    </div>
                </div>
            <div id="supervisor-change-requests" class="large-div">
                <% if (SupervisorChangeRequests.Count > 0)
                    { %>
                <table id="supervisor-table" style="table-layout: fixed; white-space: nowrap;" data-role="parent-table" class="header-table checklist-name ">
                    <tr class="header-row change-request-header">
                        <th class="resizable" style="width: 115px; padding-left: 20px; border-right: 1px solid black;">Date</th>
                        <th class="resizable" style="width: 176px; padding-left: 5px; border-right: 1px solid black;">Requestor</th>
                        <th class="resizable" style="width: 726px; padding-left: 5px; border-right: 1px solid black;">Task</th>
                        <th class="resizable" style="width: 222px; padding-left: 5px; border-right: 1px solid black;">Request Type / Comments</th>
                        <th style="width: 218px; padding-left: 12px;">Actions</th>
                    </tr>

                    <asp:Repeater runat="server" DataSource="<%# SupervisorChangeRequests %>" ID="supervisorChangeRequestRepeater">
                        <ItemTemplate>
                            <mytasks:ChangeRequest data-role="change-request-table" Repository="<%#ChangeRequestRepo%>" ChangeRequest="<%#GetDataItem() %>" runat="server" />
                        </ItemTemplate>
                    </asp:Repeater>
                </table>
                <% } %>
            </div>
            <div class="large-div">
                <div class="table-header">
                    <h4><i id="userExpandAll" class="fa fa-plus-square-o"></i>My Requests to Others:</h4>
                    <span><em>*Columns can be resized by dragging headers left or right.</em></span>
                </div>
            </div>
            <div id="user-change-requests" class="large-div">
                <% if (UserChangeRequests.Count > 0)
                    { %>
                <table id="user-table" style="table-layout: fixed; white-space: nowrap;" data-role="parent-table" class="header-table checklist-name">
                    <tr class="header-row change-request-header" colspan="5">
                        <th class="resizable" style="width: 115px; padding-left: 20px; border-right: 1px solid black;">Date</th>
                        <th class="resizable" style="width: 176px; padding-left: 5px; border-right: 1px solid black;">Requestor</th>
                        <th class="resizable" style="width: 726px; padding-left: 5px; border-right: 1px solid black;">Task</th>
                        <th class="resizable" style="width: 222px; padding-left: 5px; border-right: 1px solid black;">Request Type / Comments</th>
                        <th style="width: 218px; padding-left: 12px;">Actions</th>
                    </tr>

                    <asp:Repeater runat="server" DataSource="<%#UserChangeRequests%>" ID="userChangeRequestRepeater">
                        <ItemTemplate>
                            <mytasks:ChangeRequest data-role="change-request-table" Repository="<%#ChangeRequestRepo%>" ChangeRequest="<%#GetDataItem() %>" runat="server" />
                        </ItemTemplate>
                    </asp:Repeater>
                </table>
                <% } %>
            </div>
            <div id="universal-extension-change-requests">
                <%--added by venkat 11/15/2017--%>
                <div class="large-div">
                    <h4><i id="universalRequestsExpandAll"></i>Universal Extension Change Requests:</h4>
                </div>

                <div style="margin-left: 245px;" id="univExtChangeRequestsdata">
                </div>


            </div>

        </div>
        </div>
    </form>
    <div data-role="email-area" class="hidden">
    </div>
    <input type="hidden" id="user-full-name" value="<%=CurrentSession.QUser.FullName%>" />
    <input id="font-size" type="hidden" value="<%= ChangeRequestFont %>" />
    <input id="row-height" type="hidden" value="<%= ChangeRequestRowHeight %>" />
    <input id="change-request-columns" type="hidden" value="<%= ChangeRequestColumns %>" />

    <div id="commentDialog" title="Email Comments">
        <div style="display: flex; flex-direction: column; align-items: center;">
            <textarea rows="5" cols="50" id="quickComments" placeholder="Enter comments here..." style="resize: none;"></textarea>
            <div style="margin-top: 10px;">
                <button class="btn btn-default" onclick="sendRequestEmail()">Send Reply Email</button>
                <button class="btn btn-default" onclick="closeCommentModal()">Close</button>
            </div>
        </div>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


