<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChangeRequestItemAddition.ascx.cs" Inherits="QProcess.Controls.Controls_ChangeRequests_ChangeRequestItemAddition" %>
<tr data-status='{"CRItemId":"<%:ChangeRequestItem.CRItemID%>","Approved":<%=ChangeRequestItem.Approved.ToString().ToLower() %>}'>
	<td><%=ChangeRequestItem.ItemName %></td>
	<td><%=ChangeRequestItem.Requested %></td>
	<%if(IncludeApprovalIndicator) { %>
        <%if (ChangeRequestItem.Approved){ %>
	        <td><i class="fa fa-check" data-role="approval-indicator"/></td>
        <%}
          else 
         { %>
	        <td><i class="fa fa-times" data-role="approval-indicator"/></td>
	<%   }
      } %>
</tr>
<!-- Copyright © 2024 Renegade Swish, LLC -->

