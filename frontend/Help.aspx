<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Help.aspx.cs" Inherits="QProcess.Help" MasterPageFile="Site.master"%>

<%@ Register Src="~/Controls/Shared/Help.ascx" TagPrefix="help" TagName="Help" %>


<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Help.css?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/Help.css")).Ticks.ToString() %>" rel="stylesheet" />

	<style>
		div.glossary{
			max-width:100%;
		}
	</style>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script type="text/javascript">
        $(document).ready(function () {
            resize();
            window.onresize = resize;
        });

        function resize() {
            $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
            $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        }
    </script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <help:Help runat="server" id="HelpContent" />

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>


