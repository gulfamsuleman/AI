<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeBehind="TestManagement.aspx.cs" Inherits="QProcess.TestManagement" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="Server">
    <link href="Content/TestManagement.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/buttons/3.0.2/css/buttons.dataTables.css" rel="stylesheet">
    <script src="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.js"></script>
    <script src="https://cdn.datatables.net/buttons/3.0.2/js/dataTables.buttons.js"></script>
    <script src="https://cdn.datatables.net/buttons/3.0.2/js/buttons.dataTables.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.30.1/moment.min.js"></script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ScriptContent" runat="Server">
<link href="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.css" rel="stylesheet">
<link href="https://cdn.datatables.net/2.0.8/css/dataTables.dataTables.css" rel="stylesheet">
<link href="https://cdn.datatables.net/buttons/3.0.2/css/buttons.dataTables.css" rel="stylesheet">
<script src="https://cdn.datatables.net/v/dt/jszip-3.10.1/dt-2.0.8/b-3.0.2/b-html5-3.0.2/r-3.0.2/datatables.min.js"></script>
<script src="https://cdn.datatables.net/buttons/3.0.2/js/dataTables.buttons.js"></script>
<script src="https://cdn.datatables.net/buttons/3.0.2/js/buttons.dataTables.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.30.1/moment.min.js"></script>
    <script src="Scripts/TestManagement.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/TestManagement.js")).Ticks.ToString() %>"></script>    
    <script type="text/javascript">
        var userIsGrader = <%=(MasterPage).QUser.IsGradingAdmin.ToString().ToLowerInvariant()%>;
        $(document).ready(function () {
            resize();
            window.onresize = resize;
        });

        //function resize() {
        //    $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        //    $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        //}
    </script>
</asp:Content>
<asp:Content ID="Content3" style="height: 100%; width: 100%;" ContentPlaceHolderID="MainContent" runat="Server">
    <div id="test-panel" class="test-panel">
        <h2><%= QProcess.Configuration.AppSettings.AppName%> Test Management</h2>
        <div>
            <%if ((MasterPage).QUser.IsGradingAdmin)
                { %>
            <span class="leftLabel">Choose Employee</span>
            <%
            }
            else
            { %>
            <span class="leftLabel">Employee:</span>
            <% 
            }%>
            <span>
                <select id="user-select" class="input-sm">
                    <asp:Repeater ID="Repeater1" runat="server">
                        <ItemTemplate>
                            <option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
                        </ItemTemplate>
                    </asp:Repeater>
                </select>
            </span>
        </div>
        <div>
            <span class="leftLabel">Test Date
            </span>
            <span>
                <input type="text" id="test-date" data-role="datepicker" />
            </span>
        </div>
        <div style="margin-left:auto; margin-right:auto;">
            <%--<button data-action="setup" class="btn btn-sm btn-default setuptest">Setup Test</button>--%>
            <button data-action="grade" class="btn btn-sm btn-default gradetest">Grade Test</button>            
            <button data-action="grade" class="btn btn-sm btn-default cleanuptest">Cleanup Test</button>
            <%if ((MasterPage).QUser.IsGradingAdmin)
            { 
                    %>
            <button data-action="grade" class="btn btn-sm btn-default viewBreakdown">View Breakdown</button>
            <button data-action="grade" class="btn btn-sm btn-default testHistory">User Test Report</button>
            <%
                }
             %>
        </div>
        <div id="result" style="padding: 20px;"></div>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

