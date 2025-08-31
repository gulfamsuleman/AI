<%@ Page Title="" Language="C#" MasterPageFile="~/Mobile/Mobile.Master" AutoEventWireup="true" CodeBehind="MobileHelp.aspx.cs" Inherits="QProcess.Mobile.MobileHelp" %>

<%@ Register Src="~/Controls/Shared/Help.ascx" TagPrefix="help" TagName="Help" %>

<asp:Content ID="Content1" ContentPlaceHolderID="headContent" runat="server">
    
    <script type="text/javascript">
        mobileTitle = "Help";
    </script>    
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="sliderContent" runat="server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="navContent" runat="server">
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="mainContent" runat="server">
    <help:Help runat="server" ID="HelpContent" />
</asp:Content>
<asp:Content ID="Content5" ContentPlaceHolderID="formContent" runat="server">
</asp:Content>
<asp:Content ID="Content6" ContentPlaceHolderID="scriptContent" runat="server">
    <style>
        .text-header { height: 10px; }

        main img {
            max-width: 95%;
        }

        a.back-to-top:hover{
            color:white;
        }
    </style>
    
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

