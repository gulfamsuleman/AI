<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="OverdueTaskCharges.aspx.cs" Inherits="QProcess.OverdueTaskCharges" MasterPageFile="OverdueTasksChargeMonitor.master" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link rel="stylesheet" href="Content/datepicker.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/datepicker.css")).Ticks.ToString() %>"" />
    <style type="text/css">
        #main {
            font-size: 11pt;
            font-family: Tahoma;
            overflow: auto;
        }

        h3 {
            margin: 0px;
            padding: 0px;
        }

        fieldset {
            border: 1px solid #4a5963;
        }

        #divLoading {
            font-size: 46pt;
            font-weight: bold;
            color: #777777;
            text-align: center;
            margin: 50px auto;
            display: none
        }

        #divDialog {
            display: none;
            z-index: 199;
        }

            #divDialog .panel {
                padding: 5px;
                border: 1px solid white;
                background-image: url(../images/content_bg.png);
                width: 700px;
            }

            #divDialog fieldset {
                font-size: 9pt;
                color: black;
                font-family: "Trebuchet MS";
                border: 1px solid #9c9c9c;
            }

                #divDialog fieldset span {
                    display: inline-block;
                    margin-top: 2px;
                    margin-bottom: 1px;
                }

            #divDialog legend {
                font-size: 10pt;
            }

            #divDialog select {
                border: 1px solid #70808D;
                width: 100%;
                font-family: "Trebuchet MS";
                margin: 2px 0px;
            }

            #divDialog .footer {
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

            #tblScheduleReport tbody td.left {
                text-align: left;
            }

        #tblScheduleReport td.nobr {
            text-wrap: avoid;
            white-space: nowrap;
        }

        #tblScheduleReport th.thick, #tblScheduleReport td.thick {
            border-right: solid 3px #000000;
        }

        #tblScheduleReport input[type=text] {
            width: 100%;
            border: 0;
            background-color: #f8e7dd;
        }

        #btnClearComments {
            display: none;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
 
    <script src="Scripts/json2.js"></script>
    <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script> 
    
    <script src="Scripts/jquery.lw-datepicker.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.lw-datepicker.js")).Ticks.ToString() %>"></script>
	
    <script type="text/javascript">
        $(document).ready(function () {
            syncPost("GetRoleId", "");
            if (syncPostResult < 1 && !<%=QProcess.Session.CurrentSession.QUser.Username.ToLowerInvariant() == "kshannon" ? "true" : "false"%>) {
                $("#rptDiv").html("You are not authorized to view this report");
            }
            else {
                GetLateReport();
            }
        });
        function GetLateReport() {
            syncPost("GetOverdueTaskChargesReport", JSON.stringify({ timeSpan: $("#ddlTimeFrame option:selected").text() }));
            $("#tblScheduleReport").html(syncPostResult);
        }
        function EmailLateReport() {
            syncPost("EmailPriorityListScheduleReportAll", JSON.stringify({ timeSpan: $("#ddlTimeFrame option:selected").text() }));
            if (syncPostSuccess) {
                alert("Mail Sent Successfully");
            }
        }

    </script>
     	
</asp:Content>

  

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    
  <%-- <div style="margin-bottom:50px;">--%>
    <div id="rptDiv">
   <fieldset >
       <legend style="width: 140px; color: black; margin-left: 10px;border:0px;">Report Criteria</legend>
   <div style="display:inline-block">
  
    <div class="space" style="float:left;">
     <label style="display:inline-block;width:80px;margin-left:10px;">Time Span</label>
     <select id="ddlTimeFrame" onchange="GetLateReport()">
         <option value="1">Last 30 Days</option>
         <option value="2">Last 365 Days</option>
         <option value="3">YTD</option>
     </select>
    </div>
   <div style="margin-left: 10px; float: left;">
    
   <%--  <input id="btnGo" style="width: 40px; height: 25px; text-align: center; vertical-align: top;"  type="button" value="Go" onclick="GetLateReport()" />--%>
   <%--  <input id="btnEmail" style="width: 70px; height: 25px; text-align: center; vertical-align: top;"  type="button" value="Email" onclick="EmailLateReport()" />--%>
    </div>
 </div>
  
  </fieldset>
  </div>

    <div  id="reportCriteria">

    <table id="tblScheduleReport" style="width:100%;">


    </table>
    </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

