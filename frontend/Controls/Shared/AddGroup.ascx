<%@ Control Language="C#" AutoEventWireup="true" Codebehind="AddGroup.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_AddGroup" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="add-user-group-panel" class="panel panel-default">
	<div class="panel-heading">Groups</div>
	<div class="panel-body">
		<div class="form-horizontal">
			<div class="form-group">
				<label for="group-name" class="col-xs-4 control-label">Name:</label>
				<div class="col-xs-8"><input id="group-name" type="text" class="input-sm" style="width: 100%;"/></div>
			</div>
            <hr />
			<div class="form-group text-center">
				<button data-role="add-user-group" class="btn btn-sm btn-default"><i class="fa fa-plus"></i> Add Group</button>
			</div>
		</div>
	</div>
</div>

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/AddGroup.js"></script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

