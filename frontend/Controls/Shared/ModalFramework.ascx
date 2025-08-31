<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ModalFramework.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ModalFramework" %>

<div id="modal" class="modal fade">
	<div class="modal-dialog">
		<div class="modal-content">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
				<h4 class="modal-title"></h4>
			</div>
			<div class="modal-body"></div>
			<div class="modal-footer">
				<button id="modal-button" type="button" class="btn btn-primary"></button>
			</div>
		</div>
	</div>
</div>
<script src="Scripts/modal.js?<%# System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/modal.js")).Ticks.ToString() %>"></script>
<!-- Copyright © 2024 Renegade Swish, LLC -->

