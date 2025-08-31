<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ViewGroups.ascx.cs" Inherits="QProcess.Controls.Controls_Footer_ViewGroups" %>

<div id="view-groups">
	<div class="row">
		<asp:Repeater ID="Repeater1" DataSource=<%# MultiUserGroups %> runat="server">
			<ItemTemplate>
				<dl class="col-xs-3">
					<dt><%#Eval("Name") %></dt>
					<asp:Repeater ID="NestedRepeater" DataSource=<%#Eval("GroupMembers") %> runat="server">
						<ItemTemplate>
							<dd><%#Eval("FullName") %></dd>
						</ItemTemplate>
					</asp:Repeater>
				</dl>
			</ItemTemplate>
		</asp:Repeater>
	</div>
</div>
<!-- Copyright © 2024 Renegade Swish, LLC -->

