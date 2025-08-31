<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="CreatePriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_CreatePriorityList" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="create-priority-panel">
    <div class="form-inline">
        <label>List Name:</label>
        <input id="new-list" type="text" maxlength="100" class="form-control input-sm" />
    </div>
    <br />
    <br />
    <button data-role="create" class="btn btn-sm btn-default"><i class="fa fa-plus" style="color: green;"></i> Create</button>
    <button data-role="cancel" class="btn btn-sm btn-default"><i class="fa fa-reply" style="color: blue;"></i> Cancel</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="/Scripts/CreatePriorityList.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

