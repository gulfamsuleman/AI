<%@ Control Language="C#" AutoEventWireup="true" Codebehind="CommentViewer.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_CommentViewer" %>
<% foreach (var item in Comments){%>
	<h4><%:item.Key.Description %></h4>
	<% foreach (var comment in item.Value){%>
		<div class="comment-item">
				<label><input type="checkbox" data-id="<%:comment.Id%>"/><%:comment.Comments%></label>
		</div>
	<%}%>
<%}%>
<!-- Copyright © 2024 Renegade Swish, LLC -->

