<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="QGraphs.ascx.cs" Inherits="QProcess.Controls.Shared.QGraphs" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<link href="../Content/QGraphs.css" rel="stylesheet" />

<div id="main-container">
    <h4><%# GraphTitle %></h4>
    <div id="graphsBox" class="graph-container">
    </div>
</div>

<input type="hidden" id="numberOfGraphs" value="<%# GraphNumber %>" />
<input type="hidden" id="typeOfGraphs" value="<%# GraphType %>" />

<QPH:DOMInjector runat="server" InjectInto="ScriptContent" >
	<script src="../Scripts/QGraph.js"></script>
</QPH:DOMInjector>

