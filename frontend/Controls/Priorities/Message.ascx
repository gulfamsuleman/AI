<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Message.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_Message" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="message-panel">
	<span>Message To <%= RespondToName %></span>
	<br/>
	<% if (Reply) { %>		
		<span><%= Message.Message %></span>
		<input id="respond-to" type="hidden" value="<%= Message.MessageTo %>"/>
	<% } %>
	<textarea id="message-box" class="message-size"></textarea>
	<br/>
	<button data-role="send-message">
		<i class="fa fa-envelope"></i>
		<%= !Reply ? " Send Message" : " Reply" %>
	</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/Message.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

