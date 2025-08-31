<%@ Control Language="C#" AutoEventWireup="true" Codebehind="DeletePriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_DeletePriorityList" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="delete-priority-panel">
	Are you sure you want to delete this list?
	<br/>
	<br/>
	<button data-role="delete" class="btn btn-sm btn-default"><i class="fa fa-times" style="color:red;"></i> Delete</button>
	<button data-role="cancel" class="btn btn-sm btn-default"><i class="fa fa-reply" style="color:green;"></i> Cancel</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="/Scripts/DeletePriorityList.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

