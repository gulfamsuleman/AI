<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Suggestion.aspx.cs" Inherits="QProcess.SuggestionPage" MasterPageFile="Site.master"%>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
	<link href="Content/Suggestion.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
	<script src="Scripts/Suggestion.js"></script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
	<div id="suggestion-panel">
		<h3>QCheck Suggestions</h3>
		<div>
			<input type="button" data-action="add" class="fa btn" value="&#xf067; Add Suggestion"/>
			<textarea data-role="add-suggestion" class="form-control"></textarea>
		</div>
		<div>
			<table id="suggestion-table" data-role="dragndrop-reorderable" class="table table-condensed">
				<thead>
					<tr>
						<th></th>
						<th>Suggestion</th>
						<th>Suggested By</th>
					</tr>
				</thead>
				<tbody>
					<asp:Repeater ID="Repeater1" DataSource=<%# Suggestions %> runat="server">
						<ItemTemplate>
							<tr data-id="<%#Eval("Id") %>" data-display="<%#Eval("DisplayOrder") %>" data-role="dragndrop-draggable">
								<td>
									<input type="button" data-action="delete" <%# IsAdmin ? "class='fa btn'" : "class='fa btn hidden'" %> value="&#xf00d;" />
									<input type="button" data-action="move-up" <%# (int)Eval("DisplayOrder") != LastSuggestion && IsAdmin ? "class='fa btn'" : "class='fa btn hidden'" %> value="&#xf062;" />
									<input type="button" data-action="move-down" <%# (int)Eval("DisplayOrder") > 0 && IsAdmin ? "class='fa btn'" : "class='fa btn hidden'" %> value="&#xf063;"/>
									<input type="button" data-role="dragndrop-dragpoint" <%# IsAdmin ? "class='fa btn'" : "class='fa btn hidden'" %> value="&#xf047;" />
								</td>
								<td><%# Eval("SuggestionText") %></td>
								<td><%# Eval("LoginName") %></td>
							</tr>
						</ItemTemplate>
					</asp:Repeater>
				</tbody>
			</table>
		</div>
		<input id="is-admin" type="hidden" value="<%= IsAdmin %>"/>
	</div>

	<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

