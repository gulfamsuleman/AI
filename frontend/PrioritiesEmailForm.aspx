<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrioritiesEmailForm.aspx.cs" Inherits="QProcess.PrioritiesEmailForm" ViewStateMode="Enabled" EnableViewState="true" %>
<%@ Register TagPrefix="priority" TagName="PriorityList" Src="~/Controls/Priorities/PriorityList.ascx" %>

<style>
	a{color: #003366; text-decoration: none;}
	.hidden{display: none;}
	.condensed .priorities-email-reply, .condensed .priorities-email-status { display:none; }
	.noshow, .noshow A:link, .noshow A:active, .noshow A:visited { font-size:1pt; color: White; display: none; }
    <% if (Mobile) { %>
    TD, TH, A{font-size:14pt;}
    .boldtext { font-weight: bold; font-size: 12px; font-family: tahoma, verdana; }
    .menubutton { width: 100%; white-space: nowrap; cursor: hand; background-color: #fff; border-right: solid 1px #000; border-top: solid 1px #ccc; border-left: solid 1px #ccc; border-bottom: solid 1px #000; }
    .overduespan { background-color: #ff1; }
    .borderStyle { border: solid 1px #000; }
    A:link, A:active, A:visited { text-decoration: none; color: #036; }
    A:hover { text-decoration: underline; }
    .confidentialTable { border-style: None; width: 100%; border-collapse: collapse; }
    .confidentialRow { border: solid 1px #000; background-color: red; font-family: Times New Roman; font-weight: bold; font-size: 25pt; color: #000; text-align: center; }
    .textboxclass { font-size: 14pt; color: red; font-family: Times New Roman; font-weight: normal; }
    .emailHeader { background-color: #ece9d8; font-family: Times New Roman; font-weight: bold; font-size: 25pt; color: #000; text-align: center; }
    .emailSubHeader { color: #000; text-decoration: underline; font-family: Times New Roman; font-weight: bold; font-size: 18pt; }
    .ebsel, .eb, .eb1, .assigneeColumn, .progressColumn { background-color: #ffffed; font-family: Times New Roman; font-size: 14pt; }
    .ebchanged { color: #f00; background-color: #ffffed; font-family: Times New Roman; font-size: 14pt; }
    .ebWhite { font-family: Times New Roman; font-size: 14pt; }
    .ebWhiteBig { font-family: Times New Roman; font-size: 16pt; white-space: nowrap; }
    .emailButtons { background-color: #ffffed; font-family: Times New Roman; text-align: center; }
    .emailHeads, .emailHeads1, .assigneeColumnHeads, .progressColumnHeads { background-color: #ece9d8; font-family: Times New Roman; font-size: 18pt; font-weight: BOLD; }
    .reportspacer { height: 30px; }
    .reportender { border-top: solid 2px #000; height: 10px; }
    .sd0 { color: red; }
    .sd1 { color: blue; }
    .sd2 { color: #800000; }
    .sd3 { color: #008000; }
    .sd4 { color: #660; }
    .sd50 { color: #800080; }
    .p { color: #000; }
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

<div>
	<div class="comment" style="color: red;font-size: 14pt;"><%= Body %></div>
	<br/>
	<a href="<%= PrioritiesAppUrl %>" style="font-size:14.0pt"><%= (Info != null) ? Info.LabelName : "" %></a>
	<br/>
    <% if (Mobile) { %>
        <table class="gridArea" cellspacing="0" cellpadding="4" rules="all" border="1" style="border-collapse:collapse; width: 100%">
            <tbody>
                <tr align="Center" class="nodrag nodrop" valign="Middle" style="color: black; background-color: rgb(220, 217, 200);">
                    <td>Priorities</td>
                </tr>
                <% foreach (var line in PriorityLists[0].PriorityLines) { %>
                <tr style="background-color: rgb(255, 255, 237);" nowrap="nowrap">
                    <td>
                        <div class="task"><%=line.Name %></div>
                        <div class="taskinfo">Due: <%=line.DueDate.ToShortDateString() %></div>
                        <div class="CommentDiv">
                            <div style="color: red;">
                                <% foreach (var cmt in line.Comments) { %>
                                <%=cmt.Comment %><br />
                                <% } %>
                            </div>
							<div class="CommentReply" id="acid:<%=line.Id %>">
								<span class="replyicon">?</span>
							</div>
                        </div>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
	<% } else if (SendSideBySide) { %>
		<table>
			<tr>
				<td>
					<h2>Before</h2>
					<table class="condensed">
						<priority:PriorityList ID="BeforePriorityListControl" Condensed="true" IsEmailing="true" runat="server" />	
					</table>
				</td>
				<td>
					<h2>After</h2>
					<table>
						<priority:PriorityList ID="AfterPriorityListControl" Condensed="false" IsEmailing="true" runat="server" />
					</table>
				</td>
			</tr>
		</table>
	<% } else { %>
		<table id="prioritytable">
			<priority:PriorityList ID="PriorityListControl" IsEmailing="true" runat="server" />
		</table>
	<% } %>
	<div class="noshow" id="ToList"><%=PriorityLists[0].PrioritySetList.Email.Replace("@","$") %></div>
    <div class="noshow" id="PriorityUserID"><%=PriorityUser.Id %></div>
	<div class="noshow" id="Username"><%=PriorityUser.Username %></div>
    <div class="noshow" id="SetID"><%=SetId.ToString() %></div>
    <div class="noshow" id="GeneralComment"><%=Body %></div>
    <div class="noshow" id="CommentsSince"><%=CommentsSince.ToShortDateString() %></div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

