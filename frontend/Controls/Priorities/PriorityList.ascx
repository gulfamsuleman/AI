<%@ Control Language="C#" AutoEventWireup="true" Codebehind="PriorityList.ascx.cs" Inherits="QProcess.Controls.Controls_Priorities_PriorityList" %>
<%@ Register TagPrefix="priority" TagName="PriorityLines" Src="~/Controls/Priorities/PriorityLines.ascx" %>
<%@ Register TagPrefix="priority" TagName="PriorityLinesEmail" Src="~/Controls/Priorities/PriorityLinesEmail.ascx" %>

<asp:Repeater ID="Repeater1" runat="server">
	<ItemTemplate>
		<tr data-id="<%#Eval("PrioritySet.Id") %>"
			data-user-id="<%#Eval("PrioritySetList.UserId") %>"
			data-list-id="<%#Eval("PrioritySetList.ListId") %>"
			data-display-order="<%#Eval("PrioritySetList.DisplayOrder") %>">
			<td>
				<h4 data-role="list-title" id="priority-lists-header">
					<span <%= !Info.IsSingleUserList ? "data-role='dragndrop-dragpoint'" : "" %> data-handle="move" class="hidden move-cursor"><i class="fa fa-arrows"></i></span>
					<span class="priority-list-title pointer-cursor"
						<%= !IsEmailing ? "contextmenu='priority-menu'" : "" %>>
						<% if (Info.IsSingleUserList) { %>
							<%#Eval("PrioritySet.Name") %>
						<% } else { %>							
							<%#Eval("PrioritySetList.DisplayName") %>
						<% } %>
					</span>
					<% if (IsMobile) { %>
						<img
							class="expandCollapseAllBtn expandCollapseAllIcon"
							src="/Images/plus.gif"
							alt="Expand task level comments"
							title="Expand/Collapse All Comments"
							style="width:23px;height:23px;cursor:pointer;vertical-align:middle;margin-left:10px;border-radius:4px;border:1px solid #ccc;background:#f8f9fa;"
						/>
					<% } %>
				</h4>
				<table cellspacing="0" cellpadding="0" style="border-collapse:collapse"
                    data-role="dragndrop-reorderable" 
					class="collapsible-item expanded table table-condensed"
					data-collapse-state="expanded" 
					data-table="task-table">
					<thead class="expanded">
                        <% if (!IsEmailing) { %>
						    <tr>
							    <th>Priority</th>
								<th style="position:relative;">
									<img
										class="expandCollapseAllBtn expandCollapseAllIcon"
										src="/Images/plus.gif"
										alt="Expand task level comments"
										aria-hidden="true"
										title="Expand/Collapse All Comments"
										style="width:19px;height:19px;cursor:pointer;position:absolute;left:3px;top:50%;transform:translateY(-50%);"
									/>
									<span style="margin-left:38px;">Task</span>
								</th>
							    <th>Status</th>
								<th>Due</th>
<%--									<button id="sort-asc-<%#Eval("PrioritySetList.ListId") %>" class="btn btn-sm btn-default" title="Sort Ascending">
										<i class="fa fa-arrow-up"></i>
									</button>
									<button id="sort-desc-<%#Eval("PrioritySetList.ListId") %>" class="btn btn-sm btn-default" title="Sort Descending">
										<i class="fa fa-arrow-down"></i>
									</button>	--%>							
						    </tr>
                        <% } else { %>
                            <tr style="background:#dcd9c8;padding:3.0pt 3.0pt 3.0pt 3.0pt">
							    <th style="border:1px solid black;font-size:10.0pt;color:black;width:1%;">Priority</th>
							    <th style="border:1px solid black;font-size:14.0pt;color:black;width:55%;">Task name - click "..." to comment</th>
								<% if(!Condensed) { %>
							    <th class="priorities-email-reply" style="border:1px solid black;font-size:14.0pt;color:black;width:35%;">"Reply" - must use "==" or hit enter key if your name is put in [brackets]</th>
								<% } %>
							    <th style="border:1px solid black;font-size:14.0pt;color:black;width:10%;">Due</th>
						    </tr>
                        <% } %>
					</thead>
					<tbody class="expanded">
						<% if (!IsEmailing) { %>
                            <priority:PriorityLines ID="PriorityLines1" PriorityLines=<%#Eval("PriorityLines") %> runat="server" />
							<tr data-id="-1" data-role="delete-row" class="hidden delete-row">
								<td colspan="4" class="recycle-small" style="line-height:50px;background:transparent url('/Images/recycle_sm.jpg') left center no-repeat;">&nbsp;</td>
							</tr>
						<% } else { %>
                            <priority:PriorityLinesEmail ID="PriorityLines2" Condensed=<%#Condensed %> PriorityLines=<%#Eval("PriorityLines") %> runat="server" />
                        <% } %>
					</tbody>
				</table>
			</td>
		</tr>
	</ItemTemplate>
</asp:Repeater>
<!-- Copyright © 2024 Renegade Swish, LLC -->

