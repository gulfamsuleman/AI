<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ItemBaseExport.cs" Inherits="QProcess.Controls.Controls_Shared_ItemBase" %>

	<% if (Item.ItemTypeString == "Checkbox") { %>
		<td style="border-width:3px;border-style:solid;font-weight:bold;width:20px;">
			<%= Item.IsItemComplete ? "X" : "" %>
		</td>
		<td align="Left" style="WIDTH:300px;">
			<span><%= Item.Description %></span>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>">(More Info)</a>
			<% } %>
		</td>
		<td style="width:100px;"><%=Item.Comments %></td>
		<td style="width:100px;"><%=Item.CompletedBy %></td>
		<td nowrap="nowrap" style="width:100px;"><%=Item.CompletedOn %></td>
	<% } else if (Item.ItemTypeString == "Heading") { %>
		<td colspan="5">
			<h3 class="heading"><%= Item.Description %></h3>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Notes") { %>
		<td colspan="5">
			<span class="notes"><%= Item.Description %></span>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Spacer") { %>
		<%--This is just an empty space, but it here for completeness--%>	
		<td class="spacer" colspan="5">
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>">(More Info)</a>
			<% } %>
		</td>
	<% } else if (Item.ItemTypeString == "Sub Heading") { %>
		<td colspan="5">
			<b class="subheading"><%= Item.Description %></b>
			<% if (!String.IsNullOrEmpty(Item.Url)) { %>
				<a href="<%=Item.Url %>">(More Info)</a>
			<% } %>
		</td>
	<% } %>
<!-- Copyright © 2024 Renegade Swish, LLC -->

