<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MyTasksExport.aspx.cs" Inherits="QProcess.MyTasksExport" %>
<%@ Register TagPrefix="mytasks" TagName="ChecklistExport" Src="~/Controls/Shared/ChecklistExport.ascx" %>
<html>
	<head>
		<title>My Checklists</title>
			<style>
				BODY { FONT-WEIGHT: normal; FONT-SIZE: 15px; WORD-SPACING: normal; TEXT-TRANSFORM: none; FONT-FAMILY: Verdana, Helvetica, sans-serif; LETTER-SPACING: normal; BACKGROUND-COLOR: #ffffff; TEXT-DECORATION: none }
				TD { FONT-SIZE: 11px }
				.due { FONT-WEIGHT: bold; FONT-SIZE: 11px }
				A { TEXT-DECORATION: none }
				.spacer { HEIGHT: 25px; BACKGROUND-COLOR: #ffffff }
				.SubHeadCompleted { BORDER-RIGHT: #000000 1px solid; BORDER-TOP: #000000 1px solid; FONT-WEIGHT: bold; BORDER-LEFT: #000000 1px solid; CURSOR: hand; COLOR: #000000; BORDER-BOTTOM: #000000 1px solid; BACKGROUND-COLOR: #99cc66; TEXT-ALIGN: center }
				.SubHeadOverdue { BORDER-RIGHT: #000000 1px solid; BORDER-TOP: #000000 1px solid; FONT-WEIGHT: bold; BORDER-LEFT: #000000 1px solid; CURSOR: hand; COLOR: #000000; BORDER-BOTTOM: #000000 1px solid; BACKGROUND-COLOR: #ff6666; TEXT-ALIGN: center }
				.SubHeadOpen { BORDER-RIGHT: #000000 1px solid; BORDER-TOP: #000000 1px solid; FONT-WEIGHT: bold; FONT-SIZE: 17px; BORDER-LEFT: #000000 1px solid; CURSOR: hand; COLOR: #ffffff; BORDER-BOTTOM: #000000 1px solid; BACKGROUND-COLOR: #003366; TEXT-ALIGN: center }
				.SubHeadFuture { BORDER-RIGHT: #000000 1px solid; BORDER-TOP: #000000 1px solid; FONT-WEIGHT: bold; BORDER-LEFT: #000000 1px solid; CURSOR: hand; COLOR: #000000; BORDER-BOTTOM: #000000 1px solid; BACKGROUND-COLOR: #336699; TEXT-ALIGN: center }
				.SubHead2Completed { COLOR: #aaaaaa; TEXT-DECORATION: underline }
				.SubHead2InComplete { TEXT-DECORATION: underline }
				.CheckListCompleted td { COLOR: #aaaaaa; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListInComplete td { BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListCompleted .heading { FONT-WEIGHT: bold; FONT-SIZE: larger; COLOR: #aaaaaa; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListInComplete .heading { FONT-WEIGHT: bold; FONT-SIZE: larger; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListCompleted .subheading { FONT-WEIGHT: bold; COLOR: #aaaaaa; FONT-STYLE: italic; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListInComplete .subheading { FONT-WEIGHT: bold; FONT-STYLE: italic; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListCompleted .notes { COLOR: #aaaaaa; FONT-STYLE: italic; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.CheckListInComplete .notes { FONT-STYLE: italic; BACKGROUND-COLOR: #ffff99; TEXT-ALIGN: left }
				.checkbox { BACKGROUND-COLOR: #ffff99 }
				.overdue { COLOR: red }
			</style>
	</head>
	<body MS_POSITIONING="GridLayout">
		<asp:repeater id="taskExportRepeater" runat="server">
			<itemtemplate>
				<mytasks:ChecklistExport Checklist=<%#GetDataItem()%> runat="server" />
			</itemtemplate>
		</asp:repeater>
	</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

