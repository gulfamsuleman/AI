<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ReportList.ascx.cs" Inherits="QProcess.Controls.Controls_MyInbox_ReportList" %>

<div id="report-list">
	<h4 class="report-list-head"><%= Title %></h4>
	<table style="width:100%" class="table table-condensed table-bordered report-listing-table">
		<thead>
			<tr>
				<th style="width:3%;"></th>
				<th style="width:19%;">
					<a data-sort-by="fullname" <%= SortBy == "fullname" ? "data-sort-order='" + SortOrder + "'" : "data-sort-order=''" %>>
						Name 
						<span data-role="sort-icon"></span>
					</a>
				</th>
				<th style="width:39%;" colSpan=4>
					<a data-sort-by="LastReportDate" <%= SortBy == "LastReportDate" ? "data-sort-order='" + SortOrder + "'" : "data-sort-order=''" %>>
						Last Update
						<span data-role="sort-icon"></span>
					</a>
				</th>
				<th style="width:39%;" colSpan=4>
					<a data-sort-by="LastViewed" <%= SortBy == "LastViewed" ? "data-sort-order='" + SortOrder + "'" : "data-sort-order=''" %>>
						Last Read 
						<span data-role="sort-icon"></span>
				    </a>
				</th>
			</tr>
		</thead>	
		<tbody>
			<asp:Repeater ID="Repeater1" runat="server">
				<ItemTemplate>
					<tr data-role="report-row" data-report-id="<%#Eval("ReportId") %>" class="report-listing">
						<td style="width:3%;">
							<%#Convert.ToBoolean(Eval("IsFav")) 
								? "<i class='fa fa-star'  data-role='fav-icon'></i>"
								: "<i class='fa fa-star-o'  data-role='fav-icon'></i>"  %>
						</td>
						<td style="width:19%;" title="<%#Eval("FullName") %>"><%#FormatReportName(Convert.ToString(Eval("FullName"))) %></td>
						<td style="width:5%;">
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("ddd.") %> 
                        </td>
						<td style="width:10%;">
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("MM/dd/yy") %> 
                        </td>
						<td style="width:12%;">
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("h:mmtt") %> 
                        </td>
                        <td style="width:12%;">
                            <%#GetDaysAgo(Convert.ToDateTime(Eval("LastReportDate"))) %>
                        </td>

                        <td style="width:5%;">
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("ddd.") %> 
                        </td>
						<td style="width:10%;">
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("MM/dd/yy") %> 
                        </td>
						<td style="width:12%;">
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("h:mmtt") %> 
                        </td>
                        <td style="width:12%;">
                            <%#GetDaysAgo(Convert.ToDateTime(Eval("LastViewed"))) %>
                        </td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>	
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

