<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="MobileReportList.ascx.cs" Inherits="QProcess.Controls.MyInbox.MobileReportList" %>

<div id="report-list">
	<h4 class="report-list-head"><%= Title %></h4>
	<table style="width:100%" class="table table-condensed table-bordered report-listing-table">
		<thead>
			<tr>
				<th>
					<a data-sort-by="fullname" <%= SortBy == "fullname" ? "data-sort-order='" + SortOrder + "'" : "data-sort-order=''" %>>
						Name 
						<span data-role="sort-icon"></span>
					</a>
				</th>
				<th>
					<a data-sort-by="LastReportDate" <%= SortBy == "LastReportDate" ? "data-sort-order='" + SortOrder + "'" : "data-sort-order=''" %>>
						Last Update
						<span data-role="sort-icon"></span>
					</a>
				</th>
				<th>
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
						<td title="<%#Eval("FullName") %>" colspan="3">
							<span class="report-name">
							<%#Convert.ToBoolean(Eval("IsFav")) 
								? "<i class='fa fa-star'  data-role='fav-icon'></i>"
								: "<i class='fa fa-star-o'  data-role='fav-icon'></i>"  %>
							<b><%#FormatReportName(Convert.ToString(Eval("FullName"))) %></b>
							</span>
						<br />
						   <i class="label">Last Update</i><br />
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("ddd.") %> 
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("MM/dd/yy") %> 
                           <%#(Convert.ToDateTime(Eval("LastReportDate"))).ToString("h:mmtt") %> 
                           <%#GetDaysAgo(Convert.ToDateTime(Eval("LastReportDate"))) %>
                        <br />
						   <i class="label">Last Read</i><br />
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("ddd.") %> 
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("MM/dd/yy") %> 
                           <%#(Convert.ToDateTime(Eval("LastViewed"))).ToString("h:mmtt") %> 
                           <%#GetDaysAgo(Convert.ToDateTime(Eval("LastViewed"))) %>
                        </td>
					</tr>
				</ItemTemplate>
			</asp:Repeater>
		</tbody>
	</table>	
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

