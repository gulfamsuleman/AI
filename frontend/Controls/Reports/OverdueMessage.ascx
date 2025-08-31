<%@ Control Language="C#" AutoEventWireup="true" Codebehind="OverdueMessage.ascx.cs" Inherits="QProcess.Controls.Controls_Reports_OverdueMessage" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="message-panel" class="row">
	<div class="col-xs-12">
		<button type="button" class="close" data-dismiss='message-panel' aria-hidden="true">&times;</button>
	</div>
	<div class="col-md-4 col-xs-12">
		<span>Recipients (<a href="#" data-role="show-hide">Hide Unchecked Recipients</a>):</span>
		<ul>
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<div class="checkboxes">
						<label><input type="checkbox" value="<%#Eval("Id") %>" v-name="<%#Eval("Name") %>" checked="checked"/>&nbsp;<%#Eval("Name") %></label>
					</div>
				</ItemTemplate>
			</asp:Repeater>
		</ul>
	</div>
	<div class="col-md-8 col-xs-12">
		<textarea id="message-body" class="message-size form-control"></textarea>
		<button data-role="send-message" class="btn btn-sm btn-default">Send Message</button>
	</div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/OverdueMessage.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/OverdueMessage.js")).Ticks.ToString() %>"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

