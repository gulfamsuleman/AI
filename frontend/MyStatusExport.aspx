<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MyStatusExport.aspx.cs" Inherits="QProcess.MyStatusExport" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mystatus" TagName="ReportLineExport" Src="~/Controls/MyStatus/ReportLineExport.ascx" %>
<style>
	.boldtext{FONT-WEIGHT: bold; FONT-SIZE: 12px;FONT-FAMILY:tahoma, verdana;}
	.menubutton{width:100%;white-space:nowrap;CURSOR: hand;background-color:#fff; border-right:solid 1px #000; border-top:solid 1px #ccc; border-left:solid 1px #ccc; border-bottom: solid 1px #000;}
	.overduespan{BACKGROUND-COLOR:#ff1;}
	.borderStyle {border:solid 1px #000;}
	A:link, A:active, A:visited {text-decoration:none;color:#036;}A:hover {text-decoration:underline;}
	.confidentialTable {border-style:None;width:100%;border-collapse:collapse;}.confidentialRow{border:solid 1px #000;Background-color:red;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 25pt; COLOR: #000; TEXT-ALIGN: center}.textboxclass{FONT-SIZE: 14pt;color:red;FONT-FAMILY:Times New Roman;Font-Weight:normal;}
	.emailHeader {background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 25pt; COLOR: #000; TEXT-ALIGN: center }
	.emailSubHeader {COLOR: #000;text-decoration:underline;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 18pt; }
	.ebsel, .eb, .eb1, .assigneeColumn, .progressColumn {background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;}
	.ebchanged {color:#f00;background-color:#ffffed;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;}
	.ebWhite {FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;}
	.ebWhiteBig {FONT-FAMILY:Times New Roman;FONT-SIZE: 16pt;white-space:nowrap;}
	.emailButtons {background-color:#ffffed;FONT-FAMILY:Times New Roman;TEXT-ALIGN: center }
	.emailHeads, .emailHeads1, .assigneeColumnHeads, .progressColumnHeads {background-color:#ece9d8;FONT-FAMILY:Times New Roman;FONT-SIZE: 14pt;FONT-WEIGHT:BOLD;}
	.reportspacer{Height: 30px;}
	.reportender{BORDER-TOP: solid 2px #000; Height: 10px;}
	.sd0{ COLOR: red; }
	.sd1{ COLOR: blue; }
	.sd2{ COLOR: #800000; }
	.sd3{ COLOR: #008000; }
	.sd4{ COLOR: #660; }
	.sd50{ COLOR: #800080; }
	.p { COLOR: #000;}
</style>
<table cellspacing="0" cellpadding="5" border="0" style="border-style:None;width:100%;border-collapse:collapse;">
	<asp:Repeater ID="Repeater1" DataSource=<%# ReportLines %> runat="server">
		<ItemTemplate>
			<mystatus:ReportLineExport Line=<%#(StatusReportLine)GetDataItem()%> excludeGeneralComments=<%# excludeGeneralComments %> runat="server"></mystatus:ReportLineExport>
		</ItemTemplate>
	</asp:Repeater>
</table>
<!-- Copyright © 2024 Renegade Swish, LLC -->

