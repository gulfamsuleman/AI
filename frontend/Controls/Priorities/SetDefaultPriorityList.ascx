<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="SetDefaultPriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_SetDefaultPriorityList" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="SetDefault-priority-panel">
    Set this list as your default? Links to "Add to Priorities" elsewhere in the site and in emails will act on this list.
    <br/>
    <br/>
	<button data-role="default" class="btn btn-sm btn-default"><i class="fa fa-check" style="color: green;"></i> Set Default</button>
    <button data-role="cancel" class="btn btn-sm btn-default"><i class="fa fa-reply" style="color: blue;"></i> Cancel</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="/Scripts/SetDefaultPriorityList.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

