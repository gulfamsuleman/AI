<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileTimezoneConversion.aspx.cs" Inherits="QProcess.Mobile.MobileTimezoneConversion" MasterPageFile="Mobile.Master" %>

<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="QProcess.Extensions" %>

<asp:Content runat="server" ID="head" ContentPlaceHolderID="headContent">
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css">
    <link rel="stylesheet" href="https://cdn.datatables.net/responsive/3.0.3/css/responsive.dataTables.css">
    <link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet">
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/responsive/3.0.3/js/dataTables.responsive.js"></script>
    <script src="/Scripts/jquery-ui-1.13.2.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-ui-1.13.2.min.js")).Ticks.ToString() %>"></script>
    <link href="/Content/MobileTimezoneConversion.css?<%=Utils.AppendAutoVersion($"/Content/MobileTimezoneConversion.css")%>" rel="stylesheet" />
    <script type="text/javascript" src="/Scripts/TimezoneConversion.js?v=<%=Utils.AppendAutoVersion($"/Scripts/TimezoneConversion.js")%>"></script>
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script type="text/javascript">
        var mobileTitle = "TZ Conv.";
    </script>
</asp:Content>

<asp:Content runat="server" ID="main" ContentPlaceHolderID="mainContent">
    <div id="progress-dialog">
        <div id="progressTitle">Converting Timezones. Please Wait...</div>
        <div id="progressBar"></div>
    </div>
    <div id="existingTaskContainer" class="table-container">
    </div>
    <input type="hidden" id="userId" value="<%= UserId %>" />
    <input type="hidden" id="userName" value="<%= UserName %>" />
    
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

