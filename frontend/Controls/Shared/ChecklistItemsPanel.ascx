<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ChecklistItemsPanel.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ChecklistItemsPanel" %>
<div id="checklist-items-panel" class="clear-fix" data-status='<%=SerializedItems()%>'>

    <div style="display: flex; flex-direction:column;" class="form-inline">
        <div style="width: fit-content;">
            <button data-role="add" class="btn btn-sm btn-default">Add</button>
            <select data-role="complex-select" data-set="item-types" class="form-control input-sm">
                <asp:Repeater ID="Repeater1" DataSource="<%# ItemTypes %>" runat="server">
                    <ItemTemplate>
                        <option value='<%#Eval("Id") %>'><%#Eval("Name") %></option>
                    </ItemTemplate>
                </asp:Repeater>
            </select>
        </div>
        <div>
            Text:
            <textarea data-item="text" class="form-control input-sm" style="resize: none;" rows="6" cols="60"></textarea>
        </div>
        <div>
            Link URL:
            <input type="text" id="link-url" />
            <input type="file" data-item="url" data-filename-placement="outside" class="btn-sm" style="max-width: 150px;" />
        </div>
    </div>
    <br />
    <table id="checklist-items-table" data-role="dragndrop-reorderable" class="table table-condensed hidden table-listing table-responsive">
        <thead>
            <tr>
                <th></th>
                <th>Item Type</th>
                <th>Text</th>
                <th>URL</th>
            </tr>
        </thead>
        <tbody></tbody>
    </table>
    <br />
    <button data-action="preview" class="btn btn-sm btn-default">Preview</button>
</div>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="../Scripts/bootstrap.file-input.js"></script>
    <script src="../Scripts/ChecklistItemsPanel.js?1"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

