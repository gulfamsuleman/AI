<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DetailedUserGrid.ascx.cs" Inherits="QProcess.Controls.Shared.DetailedUserGrid" %>

<%@ Register TagPrefix="qgraph" TagName="Graph" Src="~/Controls/Shared/QGraphs.ascx" %>
<%@ Register TagPrefix="qgrid" TagName="Grid" Src="~/Controls/Shared/QDataGrid.ascx" %>

<link href="Content/DetailedUserGrid.css" rel="stylesheet" />

<div id="dashContainer">
    <qgraph:Graph ID="GraphTest" runat="server" />
    <qgrid:Grid ID="DataGridTest" runat="server" />
    <qgraph:Graph ID="GraphTest2" runat="server" />
    <qgrid:Grid ID="DataGridTest2" runat="server" />
</div>

<qph:dominjector runat="server" injectinto="ScriptContent">
    <script src="../Scripts/DetailedUserGrid.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/DetailedUserGrid.js")).Ticks.ToString() %>"></script>
</qph:dominjector>
