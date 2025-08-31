<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="EmailComments.ascx.cs" Inherits="QProcess.Controls.Controls_MyStatus_EmailComments" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<% if (Mode == "comments")
    { %>
<span>
    <input id="all-comments" type="checkbox" checked="checked" />
    Send all available comments
</span>
<br />
<% } %>
<span <%if (Mode != "comments" && Mode != "all")
    { %>
    style="display: none;" <%} %>>Include Comments Since<br />
    <span style="line-height: 25px;">
        <input id="comments-date" type="text" data-role="datepicker" />
        <select id="comments-time">
            <option value="0">12:00 AM</option>
            <option value="1">1:00 AM</option>
            <option value="2">2:00 AM</option>
            <option value="3">3:00 AM</option>
            <option value="4">4:00 AM</option>
            <option value="5">5:00 AM</option>
            <option value="6">6:00 AM</option>
            <option value="7">7:00 AM</option>
            <option value="8">8:00 AM</option>
            <option value="9">9:00 AM</option>
            <option value="10">10:00 AM</option>
            <option value="11">11:00 AM</option>
            <option value="12">12:00 PM</option>
            <option value="13">1:00 PM</option>
            <option value="14">2:00 PM</option>
            <option value="15">3:00 PM</option>
            <option value="16">4:00 PM</option>
            <option value="17">5:00 PM</option>
            <option value="18">6:00 PM</option>
            <option value="19">7:00 PM</option>
            <option value="20">8:00 PM</option>
            <option value="21">9:00 PM</option>
            <option value="22">10:00 PM</option>
            <option value="23">11:00 PM</option>
        </select>
    </span>
</span>
<% if (Mode == "all")
    { %>
<br />
<span>
    <span class="email-item">
        <input type="checkbox" id="only-tasks-with-comments" />
        Only include tasks with comments
    </span>
    <br />
    <span class="email-item">
        <input type="checkbox" id="is-include-details" />
        Include details
    </span>
</span>
<% } %>
<div style="display: flex; flex-direction: row; align-items: baseline;">
    <h3>Recipients</h3>
    <button style="margin-left: 15px;" data-action="selectAll">Select All</button>
</div>
<div id="email-list">
    <% foreach (var emailItem in ReportEmails)
        {%>
    <span class="email-item">
        <label>
            <input type="checkbox" data-email="<%:emailItem.Email %>" data-id="<%:emailItem.ID %>" /><%: emailItem.FullName %></label></span>
    <%} %>
</div>
<% if (Mode == "comments")
    { %>
<div id="comments">
    <h3>Comments</h3>
    <div id="comments-section">
    </div>
</div>
<% } %>
<br />
<br />

<button data-action="send-email">Go</button>
<%if (Inbox)
    { %>
<button data-action="send-email-all">Email, Mark Read, Go To Inbox</button>
<%} %>
<button data-action="prev-email">Preview</button>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script>
        $(function () {
            var sending = false;
            var userId = <%=UserId %>;
            var mode = "<%=Mode%>";
            var reportId = <%=ReportId%>;
            var rightNow = new Date("<%=QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString()%>");
            var emailAllCommentsSince = "<%=QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1 * Convert.ToInt32(QProcess.Configuration.AppSettings.Get("VisibleCommentsDays"))).ToShortDateString()%>";

            function reloadComments() {
                console.log("Reload Triggered");
                if ($("#all-comments").prop('checked')) {
                    $("#comments-section").html('');
                    return;
                }
                var params = {
                    UserId: userId,
                    Mode: mode,
                    ReportId: reportId,
                    StartTime: getStartTime()
                };
                console.log(params);
                $("#comments-section").load("JQueryHandler.ashx?ControlName=" + encodeURI("/Controls/MyStatus/CommentViewer.ascx"), params, function () {
                });
            }

            $(document).ready(function () {
                if (typeof slider !== 'undefined') {
                    $("#comments-date").val(formatDate(rightNow)).mobiscroll().date({
                        theme: getMobileOperatingSystem(),
                        display: 'modal'
                    });
                } else {
                    $("#comments-date").lwDatepicker();
                    $("#comments-date").data("lwDatepicker").setActiveDate(rightNow);

                    if (mode == "all")
                        $("#comments-date").data("lwDatepicker").setActiveDate(new Date(emailAllCommentsSince));
                }

                var hour = rightNow.getHours() - 1;
                if (hour == -1) hour = 23;
                if (mode == "todays-comments" || mode == "all") hour = 0;
                $("#comments-time").find("option[value='" + hour + "']").prop("selected", true);

                reloadComments();
                $("#comments-date").on('blur', function () { reloadComments(); });
                $("#comments-time").on('change', function () { reloadComments(); });
                $("#all-comments").on('change', function () { reloadComments(); });
            });

            function getStartTime() {
                var dateStartString = $("#comments-date").val();
                var hoursOffset = $("#comments-time").val();
                var dateStart = new Date(Date.parse(dateStartString));
                var newDateString = (dateStart.getMonth() + 1) + "/" + dateStart.getDate() + "/" + dateStart.getFullYear() + " " + hoursOffset + ":00";
                return newDateString;
            }

            function formatDate(date) {
                var newDateString = (date.getMonth() + 1) + "/" + date.getDate() + "/" + date.getFullYear();
                return newDateString;
            }

            $("button[data-action='send-email']").click(function () { sendEmailRequest(false); });
            $("button[data-action='send-email-all']").click(function () { sendEmailAll(); });
            $("button[data-action='prev-email']").click(function () { sendEmailRequest(true); });
            $("button[data-action='selectAll']").on('click', selectAll);

            function sendEmailAll() {
                sending = false
                sendEmailRequest(false);
                if (sending) {
                    if (window.myInboxModule)
                        window.myInboxModule.markReportAsRead($("#report-id").val());
                    window.location.assign("MyInbox.aspx");
                }
            }

            function selectAll() {
                $("#email-list .email-item input[data-email]").each(function () {
                    $(this).prop('checked', true);
                });
            }

            function sendEmailRequest(prev) {
                var preview = 0;
                if (prev == true) {
                    preview = 1;
                    //$("#email-list .email-item input[data-email]").eq(0).prop("checked", true);
                }

                var recipients = $("#email-list .email-item input[data-email]:checked");
                var comments = $("#comments-section .comment-item input[data-id]:checked");
                var onlyTasksWithComments = false;
                var isIncludeDetails = false;

                if (mode == "all") {
                    onlyTasksWithComments = $("#only-tasks-with-comments").is(":checked");
                    isIncludeDetails = $("#is-include-details").is(":checked");
                }

                if (recipients.length == 0 && preview == 0) {
                    //notifier.setMessage("You must select at least 1 recipient to use this feature.", "yellow", 5000);
                    alert("You must select at least 1 recipient");
                    return;
                }
                if (mode == "comments" && !$("#all-comments").prop('checked') && comments.length == 0) {
                    //notifier.setMessage("You must select at least 1 comment to send to use this feature.", "yellow", 5000);
                    alert("You must select at least 1 comment to send");
                    return;
                }
                var commentsDate = $("#comments-date").val();
                var commentsTime = $("#comments-time").val();
                var addresses = [];
                var recipientIds = [];
                recipients.each(function () {
                    recipientIds.push($(this).data("id"));
                    addresses.push($(this).data("email"));
                });
                var commentIds = [];
                comments.each(function () {
                    commentIds.push($(this).data("id"));
                });
                var isArchive = $("#IsArchive").val();
                sending = true;
                var singleCol = isMobile && prev && window.innerWidth < 800;

                $.ajax({
                    url: "/EmailHandler.ashx",
                    type: "POST",
                    async: false,
                    data: {
                        Form: "MyStatusEmailForm.aspx",
                        CommentIds: commentIds.join(),
                        RecipientIds: recipientIds.join(),
                        EmailAddresses: addresses.join(),
                        Subject: "QProcess Email",
                        Mode: mode,
                        ReportId: reportId,
                        IsArchive: isArchive,
                        CommentsDate: commentsDate,
                        CommentsTime: commentsTime,
                        Preview: preview,
                        OnlyTasksWithComments: onlyTasksWithComments,
                        IsIncludeDetails: isIncludeDetails,
                        SingleCol: singleCol
                    },
                    success: function (msg, textStatus, request) {
                        if (msg == "There are no comments to send") {
                            alert(msg);
                        } else {
                            if (preview == 1) {
                                if (typeof slider !== "undefined") {
                                    $("div.preview", slider).remove();
                                    slider.append("<div class='preview'>" + msg + "</div>");
                                }
                                else {
                                    $("#divPreview").show().center();
                                    if ($("#divPreview")[0].contentWindow != null) {
                                        var d = $("#divPreview")[0].contentWindow.document; // contentWindow works in IE7 and FF
                                        d.open(); d.close(); // must open and close document object to start using it!
                                    }
                                    // now start doing normal jQuery:
                                    $("body", d).append("<span onclick='window.parent.closePreview()' style='float:right; font-weight:bold;cursor:pointer;color:red'>Close Preview</span>" + msg).css("background-color", "white");
                                }
                            } else {
                                if (typeof slider !== "undefined") {
                                    slider.toggleClass('open');
                                } else {
                                    notifier.setMessage("Send Successful.", "green", 2000);
                                    window.modalModule.hide();
                                }
                            }
                        }
                    },
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert(textStatus + ": " + errorThrown);
                    }
                });
            }
        });

        jQuery.fn.center = function () {
            this.css("position", "absolute");
            this.css("top", Math.max(0, (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop()) + "px");
            this.css("left", Math.max(0, (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
            return this;
        }

        function closePreview() {
            $("#divPreview").hide();
        }
    </script>
</QPH:DOMInjector>
<!-- Copyright © 2024 Renegade Swish, LLC -->

