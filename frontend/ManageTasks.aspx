<%@ Page Title="" Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" CodeBehind="ManageTasks.aspx.cs" Inherits="QProcess.ManageTasks" %>

<asp:Content ContentPlaceHolderID="HeadContent" runat="Server">
    <link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet" />
    <link href="Content/ManageTasks.css?v=2024021601" rel="stylesheet" />
    <link href="Content/MyTasks.css?v=4" rel="stylesheet" />
    <link href="Content/jstree/style.css" rel="stylesheet" />
</asp:Content>

<asp:Content ContentPlaceHolderID="ScriptContent" runat="Server">
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
    <script src="Scripts/jstree.min.js"></script>
    <script src="Scripts/ManageTasks.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/ManageTasks.js")).Ticks.ToString() %>"></script>
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="Server">
    <div id="manageTaskDiv" class="row">
        <table class="standard">
            <tr>
                <td style="width: 20%; max-width: 450px">
                    <div class="row">
                        <div class="form-group manage-tasks-selector">
                            <label>Assigned To:</label><br />
                            <select data-role="task-group-select" class="input-sm">
                                <option value="0">All</option>
                                <asp:Repeater ID="Repeater1" DataSource="<%# Groups %>" runat="server">
                                    <ItemTemplate>
                                        <option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </select>
                        </div>
                        <div class="form-group manage-tasks-selector">
                            <label>Controlled By:</label><br />
                            <select data-role="task-manager-select" class="input-sm">
                                <option value="0">All</option>
                                <asp:Repeater ID="managerRepeater" DataSource="<%# Groups %>" runat="server">
                                    <ItemTemplate>
                                        <option value="<%#Eval("Id") %>"><%#Eval("Name") %></option>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </select>
                        </div>
                        <div class="form-group manage-tasks-selector">
                            <div class="form-inline" style="display: flex; align-items: center;">
                                <label>Search: </label>
                                <input type="text" data-role="task-search" value="<%=SearchTerm %>" class="form-control input-sm" />
                                <form id="exportForm" runat="server">
                                    <a style="margin-left: 10px;" ref="javascript:void(0);"
                                        onclick="document.getElementById('<%= exportTasksBtn.ClientID %>').click();"
                                        class="btn btn-sm btn-default">
                                        <img src="/Images/excel.gif" />
                                        Export
                                    </a>
                                    <asp:Button ID="exportTasksBtn" runat="server" OnClick="ExportTasks" Style="display: none;" />
                                </form>
                            </div>
                        </div>
                        <% if (CurrentSession.QUser.IsAdmin)
                            {%>
                        <div class="form-group manage-tasks-selector">
                            <div class="form-inline">
                                <label>Show Everything: </label>
                                <input type="checkbox" data-role="task-search-admin" class="form-control input-sm" />
                            </div>
                        </div>
                        <%}%>
                    </div>
                    <div class="row">
                        <span id="newFolder">Add Folder</span>
                        <div id="treePanel" class="col-xs-12">
                        </div>
                    </div>
                </td>
                <td style="width: 80%; padding-top: 5px;">
                    <div id="task-management-attach-point"></div>
                </td>
            </tr>
        </table>

        <div class="hidden">
            <input type="hidden" id="user-id" value="<%:UserId%>" />
            <input type="hidden" id="requested-checklist-id" value="<%= ChecklistId %>" />
            <input type="hidden" id="requested-change-id" value="<%= ChangeId %>" />
            <input type="hidden" id="search-term-entered" value="<%= NewSearchTerm %>" />
        </div>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

