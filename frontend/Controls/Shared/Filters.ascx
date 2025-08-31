<%@ Control Language="C#" AutoEventWireup="true" Codebehind="Filters.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_Filters" %>

<div id="expand-collapse" style="display:none;float:left" class="hidden">
	<a data-role="collapse-all"><img src="/Images/minus.gif" runat="server"/></a>
	<a data-role="expand-all"><img src="/Images/plus.gif" runat="server"/></a>
	
</div>
<div id="all-comments-flag" style="display:none;float:right" class="hidden">
	<a data-role="comments-false"><img src="/Images/minus.gif" runat="server"/></a>
	<a data-role="comments-true"><img src="/Images/plus.gif" runat="server"/></a>
</div>
<div id="filters" class="text-center form-inline hidden">
	<label data-role="user-highlighting">Highlight user text entered since <input type="text" data-role="datepicker" class="form-control input-sm highlight-picker"></label><br/>
	<label data-role="hide-comments"><input type="checkbox" data-action="hide-tasks"> Hide tasks without comments due after <input type="text" data-role="datepicker" class="input-sm hide-comments-picker" style="width:100px;"></label><br/>
	<label data-role="assigned-task">Show Tasks Assigned To
		<select class="form-control input-sm">
			<option value="0">All</option>
			<asp:Repeater ID="AssignmentGroupsRepeater" runat="server" DataSource="<%#AssignmentGroups %>">
				<ItemTemplate>
					<option value="<%#DataBinder.Eval(Container,"DataItem.Id") %>"><%#DataBinder.Eval(Container,"DataItem.Name") %></option>
				</ItemTemplate>
			</asp:Repeater>
		</select>
	</label>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

