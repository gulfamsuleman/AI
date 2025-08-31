<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="NewTask.aspx.cs" Inherits="QProcess.NewTask" MasterPageFile="Site.master" %>

<%@ Register Src="~/Controls/Shared/NewTask.ascx" TagPrefix="newtask" TagName="NewTask" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script type="text/javascript">
        function TaskTemplate_Change(ctl) {
            if ($(ctl).val() == "0") {
                $("#simple-controller-panel, #task-complexity-type").show();
            } else {
                $("#simple-controller-panel, #task-complexity-type").hide();
            }
        }
    </script>
</asp:Content>

<asp:Content ID="NewTaskContent" runat="server" ContentPlaceHolderID="MainContent">
    <newtask:NewTask ID="NewTaskControl" runat="server" />

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

