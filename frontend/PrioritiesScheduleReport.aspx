<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrioritiesScheduleReport.aspx.cs" Inherits="QProcess.PrioritiesScheduleReport" MasterPageFile="PrioritiesScheduling.master" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    	<link rel="stylesheet" href="Content/datepicker.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/datepicker.css")).Ticks.ToString() %>"" />
    <style type="text/css">
 
         /*#reportCriteria { min-width: 900px; margin-top: 8px; }
         #reportCriteria table { width: 100%; }
         #reportCriteria table, #reportCriteria table td { border: 0px; }
         #reportCriteria table td { vertical-align: top; }
         #reportCriteria table fieldset { height: 100px; }
         #reportCriteria table fieldset div.space { margin-bottom: 2px; } 
         #reportCriteria table fieldset div span.note { font-size: 0.8em; } 
         #reportCriteria table fieldset div input[type='text'],
         #reportCriteria table fieldset div select { border: 1px solid #8c8c8c; }
         #reportCriteria table fieldset div input[type='text'] { width: 90px; }
         #reportCriteria table fieldset div select { width: 68%; }

         #reportCriteria th { background-color: #ffffff; }
         #reportCriteria table fieldset div span.label 
         { 
             display:inline-block; 
             font-size: 0.9em;
             margin-left: 2px;
             width: 130px;
         }
         #reportCriteria table input { margin-left: 0px; }*/
         #main { font-size: 11pt; font-family: Tahoma; overflow: auto; }
         h3 { margin: 0px; padding: 0px; }
         fieldset { border: 1px solid #4a5963; }
         #divLoading { font-size: 46pt; font-weight: bold; color: #777777; text-align: center; margin: 50px auto; display:none }

         #divDialog
         {
             display: none;
             z-index: 199;
         }
         
         #divDialog .panel
         {
             padding: 5px;
             border: 1px solid white;
             background-image: url(../images/content_bg.png);
             width: 700px;
         }
         
         #divDialog fieldset
         {
             font-size: 9pt;
             color: black;
             font-family: "Trebuchet MS";
             border: 1px solid #9c9c9c;
         }
         
         #divDialog fieldset span
         {
             display: inline-block;
             margin-top: 2px;
             margin-bottom: 1px;
         }
         
         #divDialog legend
         {
             font-size: 10pt;
         }
         
         #divDialog select
         {
             border: 1px solid #70808D;
             width: 100%;
             font-family: "Trebuchet MS";
             margin: 2px 0px;
         }
         
         #divDialog .footer
         {
             text-align: center;
             padding-top: 8px;
         }

      
         #tblScheduleReport thead th, #tblScheduleReport thead td, #tblScheduleReport tbody th {
             background-color: #b0c4de;
             padding: 2px 4px;
             font-weight: bold;
             text-align: center;
              width: 90pt;
         }
         #tblScheduleReport tbody td {
             text-align: right;
             padding: 2px 4px;
             background-color: #ffffff;
             vertical-align: top;
         }
         #tblScheduleReport tbody td.left { text-align: left; }
         #tblScheduleReport td.nobr {
             text-wrap: avoid;
             white-space: nowrap;
         }
         #tblScheduleReport th.thick, #tblScheduleReport td.thick {
             border-right: solid 3px #000000;
         }
         #tblScheduleReport input[type=text] {
             width:100%;
             border: 0;
             background-color: #f8e7dd;
         }
         #btnClearComments { display: none; }

  
    
    </style>
</asp:Content>
<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
 
    <script src="Scripts/json2.js"></script>
     <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script> 
    
 
	
    <script src="Scripts/jquery.lw-datepicker.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.lw-datepicker.js")).Ticks.ToString() %>"></script>
	
    <script type="text/javascript">
        $(document).ready(function () {
           // syncPost("GetPriorityListScheduleReport", JSON.stringify({ startDate: null,endDate:null }));
            // $("#tblScheduleReport").html(syncPostResult);
           
            // $("#txtStartDate").lwDatepicker().wrapper.addClass('lw-dp-opposite-vertical');
            $("#txtStartDate").lwDatepicker();
            $("#txtEndDate").lwDatepicker();
            $("#txtStartDate").val("01/01/1900");
            var currentDate = new Date("<%=QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString()%>");
           // currentDate.setDate(currentDate.getDate() - 1);
            var month = currentDate.getMonth() + 1;
            var day = currentDate.getDate();
            var year = currentDate.getFullYear();

            if (day < 10) {
                day = '0' + day;
            }
            if (month < 10) {
                month = '0' + month;
            }
            $("#txtEndDate").val(month + "/" + day + "/" + year);
            $.ajax({
                url: "/DataService.asmx/GetEmployeesForSupervisor",
                type: "POST",
                data: {},
                async: false,
                contentType: "application/json",
                success: function (data) {

                    $("#ddlPriorityEmployees").html(data.d);
                    $("#ddlPriorityEmployees").prepend("<option value=0>All</option>");

                }
            });
            GetScheduleReport();
        });
        function GetScheduleReport()
        {
            syncPost("GetPriorityListScheduleReport", JSON.stringify({ startDate: $("#txtStartDate").val(), endDate: $("#txtEndDate").val(), employee: $("#ddlPriorityEmployees option:selected").text() }));
            $("#tblScheduleReport").html(syncPostResult);


        }
       
    </script>
      	
</asp:Content>

  

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    
  <%-- <div style="margin-bottom:50px;">--%>
    <div>
   <fieldset >
       <legend style="width: 140px; color: black; margin-left: 10px;border:0px;">Report Criteria</legend>
   <div style="display:inline-block">
    <div class="space" style="float:left;">
       <label style="display:inline-block;width:80px;">Start Date</label>
      <input id="txtStartDate"  type="text" />
    </div>
    <div class="space" style="float:left;">
     <label style="display:inline-block;width:70px;margin-left:10px;">End Date</label>
     <input id="txtEndDate" type="text" />
    </div>
   <div class="space" style="float:left;">
    <label style="display:inline-block;width:70px;margin-left:10px;">Employee</label>
  
  <select id="ddlPriorityEmployees">
  </select>
 </div>
      <div class="space" style="float:left;margin-left:10px;">
     <input id="btnGo" style="width: 40px; height: 25px; text-align: center; vertical-align: top;"  type="button" value="Go" onclick="GetScheduleReport()" />
    </div>
 </div>
    <%-- <div style="margin-top:10px;">
    
     <input id="btnGo" type="button" value="Go" onclick="GetScheduleReport()" />
    </div>--%>
  </fieldset>
  </div>

    <div  id="reportCriteria">

    <table id="tblScheduleReport" style="width:100%;">


    </table>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

