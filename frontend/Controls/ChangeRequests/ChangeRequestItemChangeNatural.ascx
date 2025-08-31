<%@ Control Language="C#" AutoEventWireup="true" Codebehind="ChangeRequestItemChangeNatural.ascx.cs" Inherits="QProcess.Controls.ChangeRequestItemChangeNatural" %>
<tr data-status='{"CRItemId":"<%:ChangeRequestItem.CRItemID%>","Approved":<%=ChangeRequestItem.Approved.ToString().ToLower() %>}'>
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

