<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AttorneyClient.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_AttorneyClient" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="attorney-client-panel">
	<div class="checkbox"><label><input type="checkbox" id="attorney-client-setter"/>Mark As Attorney Client Privileged.</label></div>
	<p class="text-danger">*Note, you must be a lawyer to use this.</p>
	<button data-role="save" class="btn btn-sm btn-default">Save</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/StatusAttorneyClient.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

