<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ScheduleReports.aspx.cs" Inherits="QProcess.ScheduleReports" MasterPageFile="PrioritiesScheduling.master"%>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link href="Content/jquery.timepicker.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/jquery.timepicker.css")).Ticks.ToString() %>" rel="stylesheet"/>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
      <script src="Scripts/jquery.timepicker.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.timepicker.js")).Ticks.ToString() %>"></script>
      <script src="Scripts/ScheduleReports.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/ScheduleReports.js")).Ticks.ToString() %>"></script> 	
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
        <div>
            <div class="content" id="reportCriteria">
               
                  <%--  <tr>
                        <td>
                            <fieldset id="General">
                                <legend>General</legend>

                                <div class="space">
                                    <span class="label">Category</span>
                                    <input class="readonly" id="category"/>
                                </div>
                                <div class="space">
                                    <span class="label">Days Prior To Compare</span>
                                    <input id="daysPrior" type="text" class="readonly"/>
                                </div>
                                <div class="space">
                               
                                    <span class="label">Price Type Filter</span>
                                    <input id="priceFilter" type="text" class="readonly" />
                                </div>
                            </fieldset>
                        </td>
                        <td>
                            <fieldset id="SortOption">
                                <legend>Sort Option</legend>
                                <div>
                                    <input type="text" id="sort" class="readonly" />
                                </div>
                                <div>
                                    <div class="cover"></div>
                                    <input type="checkbox" id="currentOnly" disabled="disabled"  />
                                    <label>Current Positions Only</label>
                                </div>
                            </fieldset>
                        </td>
                    </tr>--%>
                  
                            <fieldset id="scheduleDays">
                               

                               <%-- <div><b>Select a Report Day</b></div>
                                 <div>
                                  <select id="ddlReportDays">
                                   <option value="7">Sunday</option>
                                   <option value="1">Monday</option>
                                   <option value="2">Tuesday</option>
                                   <option value="3">Wednesday</option>
                                   <option value="4">Thursday</option>
                                   <option value="5">Friday</option>
                                   <option value="6">Saturday</option>

                                  </select>
                                </div>--%>


                                <div><b>Select a Day</b></div>
                               <%-- <div class="space" style="float:left">
                                    <input type="checkbox" id="allDays" />
                                    <label>Every Weekday</label>
                                </div>
                                <div class="space inline-block" style="float:left">
                                    <input type="checkbox" id="Monday"  />
                                    <label>Monday</label>
                                </div>
                                <div class="space inline-block" style="float:left">
                                    <input type="checkbox" id="Tuesday" />
                                    <label>Tuesday</label>
                                </div>
                                <div class="space inline-block" style="float:left">
                                    <input type="checkbox" id="Wednesday" />
                                    <label>Wednesday</label>
                                </div>
                                <div class="space inline-block" style="float:left">
                                    <input type="checkbox" id="Thursday"  />
                                    <label>Thursday</label>
                                </div>
                                <div class="space inline-block" style="float:left">
                                    <input type="checkbox" id="Friday" />
                                    <label>Friday</label>
                                </div>--%>
                                <div>
                                  <select id="ddlDays">
                                   <option value="7">Sunday</option>
                                   <option value="1">Monday</option>
                                   <option value="2">Tuesday</option>
                                   <option value="3">Wednesday</option>
                                   <option value="4">Thursday</option>
                                   <option value="5">Friday</option>
                                   <option value="6">Saturday</option>

                                  </select>
                                </div>
                            </fieldset>
                       
                            <fieldset id="scheduleNoOfDays">
                                <div><b>Select Number Of Days</b></div>
                                <div class="space">
                                     <input type="text" id="txtNumberOfDays" style="width:100px;" />
                                </div>
                               
                            </fieldset>
                      

                <div id="topNav" style="line-height: 36px">
                  
                    <div>
                        <span class="btn btn-default btn-sm" id="btnSaveSchedule"><span>Save</span></span>
                        <%--<span class="btn btn-default btn-sm" onclick="window.close()"><span>Cancel</span></span>--%>
                    </div>
                </div>
                <div>
                    <table id="tblPriorityListSchedules" style="width:300px;margin-top:10px;">
                    <tbody>
                    

                    </tbody>


                    </table>

                </div>
            </div>
        </div>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

