<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ItemBase.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ItemBase" %>
<tr data-checklist-item-id="<%= Item.ItemId %>">
    
    <% 
        Guid guid = Guid.NewGuid();
        while(guid == Guid.Empty){
            guid = Guid.NewGuid(); 
        }
    %>
	<% if (Item.ItemTypeString == "Checkbox") { %>
		<td data-col="completed"><input id="<%: guid %>" name="<%: guid %>" type="checkbox" data-attr="completed" <%= Item.IsItemComplete ? "checked='checked'" : "" %> /></td>
		<td>
			<label for="<%: guid %>"><%= Item.Description %></label>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>" target="MoreInfo">(More Info)</a>
			<% } %>
		</td>
		<td><textarea data-attr="comments" class="form-control checklist-item-comment"><%=Item.Comments %></textarea></td>
		<td nowrap><span data-attr="completed-by"><%=Item.CompletedBy %></span></td>
		<td nowrap><span data-attr="completed-on"><%=Item.CompletedOn %></span></td>
	<% } else if (Item.ItemTypeString == "Heading") { %>
		<td colspan="5">
			<h3 class="heading"><%= Item.Description %></h3>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>" target="_blank">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Notes") { %>
		<td colspan="5">
			<span class="notes"><%= Item.Description %></span>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>" target="_blank">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Spacer") { %>
		<%--This is just an empty space, but it here for completeness--%>	
		<td colspan="5" style="min-height: 20px">
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>" target="_blank">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Sub Heading") { %>
		<td colspan="5">
			<b class="subheading"><%= Item.Description %></b>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>" target="_blank">(More Info)</a>
			<% } %>
		</td>
	<% } %>
</tr>
<!-- Copyright © 2024 Renegade Swish, LLC -->

