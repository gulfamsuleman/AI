<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Print.aspx.cs" Inherits="QProcess.Print"  %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
     <meta charset="utf-8" />
   
	<meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <title></title>
      <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
	<%--<link rel="stylesheet" href="Content/bootstrap.min.css" />--%>
	<%--<link rel="stylesheet" href="Content/bs-submenu.css" />--%>
	<link rel="stylesheet" href="Content/datepicker.css" />
    <%--<link rel="stylesheet" href="Content/font-awesome.css" />--%>
	<%--<link rel="stylesheet" href="Content/jquery.contextMenu.css" />--%>
    <%--<link rel="stylesheet" href="Content/jquery-impromptu.css" />--%>
    <%--<link rel="stylesheet" href="Content/Site.css?v=4" />--%>
	<script src="Scripts/jquery-1.9.1.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-1.9.1.min.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/bootstrap.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/bootstrap.min.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/bootstrap-hover-dropdown.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/bootstrap-hover-dropdown.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/jquery.lw-datepicker.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.lw-datepicker.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/jquery.contextMenu.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.contextMenu.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/jquery.highlight-3.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.highlight-3.js")).Ticks.ToString() %>"></script>
	<%--<script src="Scripts/main.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/main.js")).Ticks.ToString() %>"></script>--%>
	<script src="Scripts/utils.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/utils.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/dragndrop.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/dragndrop.js")).Ticks.ToString() %>"></script>
	<script src="Scripts/Footer.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/Footer.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/jquery-impromptu.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-impromptu.js")).Ticks.ToString() %>"></script>

    <script type="text/javascript">
        $(document).ready(function () {
            $("input[data-role='datepicker']").lwDatepicker();
            $('#task-assignee option').prop('selected', true);
			//ShowPrintPopUP();
        });
        //added by Venkat
        function ShowPrintPopUP() {
            var users = $('#task-assignee').val() != null ? $('#task-assignee').val().toString() : '';
			
			var params = [
				'toolbar=no',
				'status=no',
				'menubar=no',
				'scrollbars=yes',
				'resizable=yes',
				'height='+screen.height,
				'width='+screen.width,
				'fullscreen=yes' // only works in IE, but here for completeness
			].join(',');

			var popup = window.open('PrintTasks<%=(Firm == "TEB" ? "TEB" : "")%>.aspx?users=' + users + '&startDate=' + $('#startDate').val(), 'PrintTask', params); 
			popup.moveTo(0,0);
			
            //window.open("PrintTasks.aspx?users=" + users + "&startDate=" + $('#startDate').val(), "PrintTask", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=700,height=600");
            //window.open("PrintTasks.aspx?users=" + users + "&startDate=05/28/2016&endDate=05/29/2016", "PrintTask1", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=700,height=600");
            // window.open("PrintOutTest.aspx", "Print", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no");
        }
       
    </script>

 <style type="text/css">
  fieldset {
    margin-bottom: 10px;
    border: 1px solid #808080;
    font-family: CustomFont;
    font-size: 11pt;
    padding: 10px;
}

fieldset input, 
fieldset select,
div.tabContent input,
div.tabContent select {
    font-family: CustomFont;
    font-size: 11pt;
}

fieldset legend {
    background-color: #78a933;
    color: white;
    padding: 2px 8px;
}

fieldset span.label,
div.tabDiv span.label {
    display: block;
    font-family: CustomFont-Bold;
    font-size: 11pt;
    margin-bottom: 4px;
    color: #105584;
    font-weight:bold;
}

fieldset span.label > span,
div.tabDiv span.label > span {
    font-size: 10pt;
    color: #c45600;
}

fieldset > div,
div.tabDiv > div {
    display: inline-block;
    margin-right: 15px;
    vertical-align: top;
    /*margin-bottom: 15px;*/
}



    </style>
</head>
<body>
    <form id="form1" runat="server">
    <div style="width:600px;">
    <fieldset id="fldPreview" style="height:150px;">
        <legend>Filter Criteria</legend>
    <div id="divFromDate">
     <span class="label">From Date</span>
	 <input type="text" data-role="datepicker" id="startDate"   value="<%: QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString("M/d/yyyy") %>" />
    </div>
   <%-- <div id="divToDate">
     <span class="label">To Date</span>
	 <input type="text" data-role="datepicker" id="endDate"   value="<%: QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.AddDays(1).ToString("M/d/yyyy") %>" />
    </div>--%>
       <%-- <div id="divNames">
                <span class="label">Names</span>
                <select id="names" style="height:100px;" multiple="multiple">
               
                </select>
  
            </div>--%>

        <div class="col-xs-6">
             <span class="label">Names</span>
					<select id="task-assignee" class="form-control input-sm" multiple="multiple">
						<asp:repeater ID="rptAssignees" runat="server">
							<itemtemplate>
								<option value=<%#Eval("Id") %> <%# FullName == Eval("Name").ToString() ? "selected=\"selected\"" : "" %>><%#Eval("Name") %></option>
							</itemtemplate>
						</asp:repeater>
					</select>
				</div>
       <%-- <div>
           <span class="label">Tasks Assigned</span>
            <input type="checkbox" id="chkAssigned" />
        </div>
          <div>
           <span class="label">Tasks Controlled</span>
            <input type="checkbox" id="chkControlled" />
        </div>--%>
        <div style="margin-top:20px;">
            <input type="button" value="Submit" onclick="ShowPrintPopUP()" />
        </div>
      </fieldset>
    </div>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

