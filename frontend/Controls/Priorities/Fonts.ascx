<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Fonts.ascx.cs" Inherits="QProcess.Controls.Controls_Fonts" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="fonts-panel">
	<div id="font-text" style="margin-bottom: 20px;">Font Size <span id="size"><%=FontSize %></span>pt</div>
	<button data-role="increase-font" class="btn btn-sm btn-default"><i class="fa fa-arrow-up"></i> Larger</button>
	<button data-role="decrease-font" class="btn btn-sm btn-default"><i class="fa fa-arrow-down"></i> Smaller</button>
	<button data-role="save-font" class="btn btn-sm btn-default"><i class="fa fa-save"></i> Save</button>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/PriorityFonts.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

