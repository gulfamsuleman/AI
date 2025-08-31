<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Sections.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_Sections" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="sections-panel">
    <button data-role="add" class="btn btn-sm">Add</button><br />
    <table id="sections-table" data-role="dragndrop-reorderable" class="table table-condensed">
        <thead ondrop="headerDropPause(event)">
            <tr>
                <th></th>
                <th>Section</th>
            </tr>
        </thead>
        <tbody>
            <asp:Repeater ID="Repeater1" runat="server">
                <ItemTemplate>
                    <tr data-id="<%#Eval("Id") %>" data-name="<%#Eval("Name") %>">
                        <td data-item='actions'>
                            <input type='button' data-role='edit' class='fa btn' value='&#xf044;'>
                            <input type='button' data-role='delete' class='fa btn' value='&#xf00d;'>
                            <input type='button' data-role='dragndrop-dragpoint' class='fa btn' value='&#xf0b2;'>
                        </td>
                        <td data-item='name'><%#Eval("Name") %></td>
                    </tr>
                </ItemTemplate>
            </asp:Repeater>
        </tbody>
    </table>
    <p>Deleted Sections</p>
    <table id="deleted-sections-table" class="table table-condensed">
        <thead ondrop="headerDropPause(event)">
            <tr>
                <th></th>
                <th>Section</th>
            </tr>
        </thea>
        <tbody>
            <asp:Repeater ID="Repeater2" runat="server">
                <ItemTemplate>
                    <tr data-id="<%#Eval("Id") %>" data-name="<%#Eval("Name") %>">
                        <td data-item='actions'>
                            <input type='button' data-role='restore' class='fa btn' value='&#xf112;'>
                        </td>
                        <td data-item='name' class='strikethrough'><%#Eval("Name") %></td>
                    </tr>
                </ItemTemplate>
            </asp:Repeater>
        </tbody>
    </table>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="Scripts/StatusSections.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

