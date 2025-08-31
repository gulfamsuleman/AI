<%@ Control Language="C#" AutoEventWireup="true" Codebehind="CopyTask.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_CopyTask" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="copy-task-panel">
	<select id="Select1">
		<asp:repeater ID="Repeater1" DataSource=<%# MySections %> runat="server">
			<itemtemplate>
				<option value=<%#Eval("ID") %> data-report="<%#Eval("ReportId") %>"><%#Eval("Name") %></option>
			</itemtemplate>
		</asp:repeater>
	</select>
	<button data-role="go">Go</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/StatusCopyTask.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

