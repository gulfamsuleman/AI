<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MyStatusEmailForm.aspx.cs" Inherits="QProcess.MyStatusEmailForm" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mystatus" TagName="ReportLineEmail" Src="~/Controls/MyStatus/ReportLineEmail.ascx" %>

<style>
	.boldtext{FONT-WEIGHT: bold; FONT-SIZE: 12px;FONT-FAMILY:tahoma, verdana;}
	.menubutton{width:100%;white-space:nowrap;CURSOR: pointer;background-color:#fff; border-right:solid 1px #000; border-top:solid 1px #ccc; border-left:solid 1px #ccc; border-bottom: solid 1px #000;}
	.overduespan{BACKGROUND-COLOR:#ff1;}
	.borderStyle {border:solid 1px #000;}
	A:link, A:active, A:visited {text-decoration:none;color:#036;}A:hover {text-decoration:underline;}
	.confidentialTable {border-style:None;width:100%;border-collapse:collapse;}
    .confidentialRow{border:solid 1px #000;Background-color:red;FONT-FAMILY:Times New Roman;FONT-WEIGHT: bold; FONT-SIZE: 25pt; COLOR: #000; TEXT-ALIGN: center}
    .textboxclass{FONT-SIZE: 14pt;color:red;FONT-FAMILY:Times New Roman;Font-Weight:normal;}
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
	.noshow, .noshow A:link, .noshow A:active, .noshow A:visited { font-size:1pt; color: White; }
    	#attorney-client-message {background-color: #ff0000;text-align: center;max-width:1000px;width:1000px;display:block;}

	<%# WidthCSS %>

    <% if (Mobile) { %>
    TD, TH, A{font-size:14pt;}
    .cmr2 { background-color: #ffffed; }
    .cmr2 td { padding-left: 20px; background-color: #ffffed; }
    .date { white-space: nowrap; }
    .task { font-size: 16pt; font-weight: bold; color: #036;}
    .taskinfo { margin-left: 40px; margin-top: 5px; font-weight: normal; font-size: 12pt; }
    .comments { padding-left: 20px; }
    .reply { padding-left: 20px; background-color: #ffffed; font-family: Times New Roman; font-size: 14pt; }
    .replyicon { padding-right: 0px; font-size: 15pt; background-color: #ffffed; }
    .CommentDiv { width: 100%; height: 100%; font-size: 14pt; background-color: #ffffed; }
    .CommentReply { width: 100%; height: 100%; font-size: 14pt; background-color: #ffffed; }
    @media only screen and (max-device-width: 480px) { }
    <% } %>
</style>
<a href="<%: AppUrl %>" style="margin-bottom: 12pt; font-size: 14pt;">Status Reports</a>


<table cellspacing="0" cellpadding="5" border="0" style="border-style:None;width:1000px;border-collapse:collapse;">
<% if(IsAttorneyClient) { %>
	<tr><td colspan=6><div id="attorney-client-message">ATTORNEY CLIENT PRIVILEGED</div></td></tr>
<%}%>
	<asp:Repeater ID="Repeater1" DataSource=<%# ReportLines %> runat="server">
		<ItemTemplate>
			<mystatus:ReportLineEmail Line=<%#(StatusReportLine)GetDataItem()%> ReportId="<%# ReportId %>" AppUrl="<%# AppUrl %>" IsArchive="<%# IsArchive %>" IsMobile="<%# Mobile%>" CommentsSince="<%# CommentsSince %>" OnlyTasksWithComments="<%# OnlyTasksWithComments %>" IsIncludeDetails="<%# IsIncludeDetails %>" runat="server"></mystatus:ReportLineEmail>
		</ItemTemplate>
	</asp:Repeater>
<% if(!Mobile) { %>
	<tr><td colspan="6">To view a mobile-friendly version of this e-mail, reply to this e-mail with "iphone" or "xxx" at the top of the message.</td></tr>
	<tr>
		<%-- below small transparent images are to force widths in outlook.  Outlook does not respect min width --%>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg=="  width="25"/></td>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg=="  width="250"/></td>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg=="  width="70"/></td>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg=="  width="130"/></td>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg=="  width="400"/></td>
		<td><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABkAAAABCAIAAACkDpLCAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAARSURBVBhXY/z//z8DVQADAwDdugL/ctfYrAAAAABJRU5ErkJggg==" width="125"/></td>
	</tr>
<% } %>
</table>
<div class="noshow" id="Mode"><%=Mode %></div>
<div class="noshow" id="ToList"><%=ToList.Replace("@","$").Replace("<", "&lt;").Replace(">", "&gt;") %></div>
<div class="noshow" id="LoginName"><%=ReportUsername %></div>
<div class="noshow" id="CommentsSince"><%=CommentsSince.ToString() %></div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

