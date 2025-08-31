<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChangeRequestDenyEmail.ascx.cs" Inherits="QProcess.Controls.Controls_ChangeRequests_ChangeRequestDenyEmail" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="changeRequestDeny">
	<textarea class="reply-comments"></textarea><br /><br />
	<input type="button" value="Send Reason Email" data-role="email" class="btn btn-default"/>&nbsp;&nbsp;&nbsp;
	<input type="button" value="No Email Needed" class="btn btn-default" onclick="window.modalModule.hide();"/>
    <input type="hidden" class="email-address" value="<%=Email %>" />
	<input type="hidden" class="request-id" value="<%=ChangeRequestID %>" />
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >	
	<script src="/Scripts/ChangeRequestDenyEmail.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

