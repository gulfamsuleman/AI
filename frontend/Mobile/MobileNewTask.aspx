<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileNewTask.aspx.cs" Inherits="QProcess.Mobile.MobileNewTask" MasterPageFile="Mobile.master" %>
<%@ Register Src="~/Controls/Shared/NewTask.ascx" TagPrefix="newtask" TagName="NewTask" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
    <style type="text/css">
		.text-header {
			height: 10px;
		}
		#simple-task-form {
			width: auto !important;
			height: auto !important;
			border: 0 !important;
			background: white !important; 
			margin-bottom: 6px !important;
		}
		input[data-role=datepicker] {
			border-radius: 5px;
			border: 1px solid #ccc;
			padding: 4px 8px;
			width: 100px;
		}
		#task-controller-select,
		#task-controller2-select {
			margin-bottom: 10px;
		}
		#task-controller-me {
			position: absolute;
			left: 100px;
			margin-top: -31px;
		}
		#simple-controller-panel { margin-top: -25px;}
		button.btn-submit-simple {
			border-radius: 5px;
			padding: 8px 16px !important;
			color: #fff !important;
			background-color: #28a745 !important;
			font-weight: normal !important;
			border: 0 !important;
		}
		.notice-text {
			background-color: #eee;
			border: 1px solid #ccc;
			padding: 5px;
			border-radius: 5px;
		}
		fieldset {
			border-radius: 5px;
			margin-top: 10px;
			width: 100% !important;
		}
		select[name=due-time] {
			width: 114px;
			display: inline-block;
		}
		textarea { margin-bottom: 10px; }
		select[data-set=sections] {
			border: 1px solid #ccc;
			padding: 4px 8px;
			border-radius: 5px;
			margin-right: 5px;
		}		
		select[data-set=folders] {
			margin-bottom: 5px;
		}	
		#complex-task-panel select[data-set=controllers],
		#complex-task-panel select[data-set=controllers-with-groups],
		#complex-task-panel select[data-set=item-types] {
			margin-top: 5px;
		}
		#complex-task-panel .btn {
			font-size: 12pt !important;
			border-radius: 5px !important;
			padding: 4px 8px !important;
		}
		#complex-task-panel .btn.btn-submit-complex {
			font-size: 20pt !important;
			padding: 20px !important;
		}
		#Select1 {
			margin: 5px 0;
		}
		#link-url {
			border: 1px solid #ccc;
			border-radius: 5px;
			margin-left: 5px;
		}
		#btn-search.btn {
			user-select: none;
			padding: 0.375rem 0.75rem;
			font-size: 1rem;
			line-height: 1.5;
			border-radius: 0.25rem;
			font-weight: 400;
		}
		/*main.container { overflow-x: scroll; }*/
	</style>
    <script>
		var mobileTitle = "New Task";
        var Firm = "<%=QProcess.Configuration.AppSettings.Get("Firm")%>";
        var svrTz = <%=TimeZoneInfo.Local.BaseUtcOffset.TotalMilliseconds + (TimeZoneInfo.Local.IsDaylightSavingTime(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) ? 3600000 : 0)%>;
        var clntTz = new Date().getTimezoneOffset() * 60 * -1000; //necessary; avoids incorrect epoch-based conversions
    </script>
</asp:Content>

<asp:Content ID="main" runat="server" ContentPlaceHolderID="mainContent">
	<newtask:NewTask ID="NewTaskControl" runat="server" />

	
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

