<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ResizeReport.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_ResizeReport" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>


<link href="Content/ReportResize.css" rel="stylesheet" />

<div data-role="page" id="resizepage" >

    Task Width:

    <div role="main" class="ui-content">
        <div id="sliderContainer" >
            <input type="range" name="theSlider" id="theSlider" min="10" max="30" value="<%:Width %>" />
        </div>
    </div>
	NOTE: This adjusts the width of the "Task" column only!
	<br /><br />
    <input type="button" class="btn btn-default btn-sm" data-role="save-width" value="save" />
    <input type="hidden" id="resizeReportId" value="<%:SelectedReportId %>" />

		
 </div>

    
<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="Scripts/ReportResize.js"></script>
</QPH:DOMInjector>
  
<!-- Copyright © 2024 Renegade Swish, LLC -->

