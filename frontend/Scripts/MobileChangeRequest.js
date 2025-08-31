function DoPreview(crId, checklistId, title) {
    window.modalModule.init({
        titleText: "Preview",
        controlName: 'Controls/Shared/ChecklistPreview.ascx',
        remoteParams: { checklistId: checklistId, changeId: crId }
    });
}
var modal = null;
$().ready(function () {

    
    modal = window.modalModule;
    var emailArea = $("div[data-role='email-area']");
    $("#user-change-requests a[data-role='cancel']").css("display", "none");

    $("#userExpandAll").click(function (e) {
        if ($("#userExpandAll").hasClass("fa-plus-square-o")) {
            $("#user-change-requests i.fa-plus-square-o").each(function (i, e) {
                e.click();
            });
            $("#userExpandAll").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
        } else {
            $("#user-change-requests i.fa-minus-square-o").each(function (i, e) {
                e.click();
            });
            $("#userExpandAll").removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
        }

    });

    $("#supervisorExpandAll").click(function (e) {
        if ($("#supervisorExpandAll").hasClass("fa-plus-square-o")) {
            $("#supervisor-change-requests i.fa-plus-square-o").each(function (i, e) {
                e.click();
            });
            $("#supervisorExpandAll").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
        } else {
            $("#supervisor-change-requests i.fa-minus-square-o").each(function (i, e) {
                e.click();
            });
            $("#supervisorExpandAll").removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
        }

    });

    $(".reply-link").click(function (e) {
        $(e.target).closest(".change-request-body").find(".reply-section").first().css("display", "table-cell");
        $(e.target).hide();
    });

    $(".reply-cancel").click(function (e) {
        $(e.target).closest(".change-request-body").find(".reply-section").first().css("display", "none");
        $(e.target).closest(".change-request-body").find(".reply-link").first().show();
    });

    $(".reply-section input[data-role='email']").click(function (e) {
        var changeRequest = $(e.target).closest("div.change-request");
        var requestId = changeRequest.data("request-id");
        var checklistname = changeRequest.find("div.checklist-name td.cr-header-task").text();
        var email = changeRequest.find("input.email-address").val();
        var comments = changeRequest.find("textarea").val();
        var myname = $("#user-full-name").val();
        //move the contents to the email area
        emailArea.html(changeRequest.html());

        emailArea.prepend("<div>" + myname + "'s comments: " + comments + "</div><br/>");

        $("a", emailArea).remove();
        $("textarea", emailArea).remove();
        $("input", emailArea).remove();
        $("i.fa", emailArea).remove();

        //harmless "new Date()" - query string nonce
        $.get("../Content/" + "ChangeRequestEmail.css?v=" + new Date().toISOString(), function (css) {
            $('<style type="text/css"></style>')
                .html(css)
                .prependTo(emailArea);

            //Outlook will eventually "forget" these elements are hidden (replies/forwards)
            $(emailArea).find("[style*='display: none']").closest(".sectionWithHeader").remove();
            $(emailArea).find("[style*='display: none']").remove();

            var body = emailArea.html();
            emailArea.html("");

            $.ajax({
                url: "../DataService.asmx/SendChangeRequestEmail",
                type: "POST",
                data: {
                    to: email,
                    checklistname: checklistname,
                    body: body
                },
                success: function () {
                    alert("Email Sent.");
                },
                error: function (request, status, error) {
                    alert(request.responseText);
                }
            }).done(function () {
                $("textarea", changeRequest).val("");
                notifier.setMessage("Email Sent.", "green", 1000);
            });
        });
    })


    $(".change-request a[data-role='change-view']").click(function (e) {
        var crItem = $(e.target).closest(".change-request");
        var changeId = crItem.attr("data-request-id");
        var checklistId = crItem.attr("data-request-checklist-id");

        if (typeof slider !== 'undefined')
            window.location = "MobileManageTasks.aspx?checklistId=" + checklistId + "&changeId=" + changeId;
        else
            window.location = "ManageTasks.aspx?checklistId=" + checklistId + "&changeId=" + changeId;
    });



    $("table tbody tr td [data-role='approval-indicator']").click(function (e) {
        var clickItem = $(e.target);
        var rowItem = clickItem.closest("tr");
        var status = rowItem.data("status");
        var crItemID = status.CRItemId;
        if (status.Approved) {
            status.Approved = false;
            if (clickItem.hasClass("fa-check")) {
                $.ajax({
                    url: "../DataService.asmx/DenyItem",
                    type: "POST",
                    data: { changeRequestItemId: crItemID },
                    error: function (request, status, error) {
                        alert(request.responseText);
                    }
                }).done(function () {
                    clickItem.removeClass("fa-check");
                    clickItem.addClass("fa-times");
                }).fail(function () {
                    notifier.setMessage("An error occured when denying this change item.", "red", 2500);
                });
            } else {
                console.warn("An error occurred on the page.");
            }
        } else if (!status.Approved) {
            status.Approved = true;
            if (clickItem.hasClass("fa-times")) {
                $.ajax({
                    url: "../DataService.asmx/ApproveItem",
                    type: "POST",
                    data: { changeRequestItemId: crItemID }
                }).done(function () {
                    clickItem.removeClass("fa-times");
                    clickItem.addClass("fa-check");
                }).fail(function () {
                    notifier.setMessage("An error occured during approval.", "red", 2500);
                });
            } else {
                console.warn("An error occurred on the page.");
            }
        } else {
            console.warn("An error occurred on the page.");
        }
        rowItem.attr("data-status", JSON.stringify(status));
    });

    $(".change-request-header a[data-role='approve']").click(function (e) {
        var changeRequest = $(e.target).closest(".change-request");
        var crId = changeRequest.data("request-id");
        var checklistID = changeRequest.data("request-checklist-id");

        $.ajax({
            url: "../DataService.asmx/ApproveChangeRequest",
            type: "POST",
            data: { changeRequestId: crId }
        }).fail(function () {
            notifier.setMessage("An error occured during approval.", "red", 2500);
        });
        $("div.change-request").each(function () {
            if (($(this).data("request-checklist-id") == checklistID) && ($(this).data("request-id") <= crId)) {
                $(this).hide();
            }
        });
    });

    $(".change-request-header a[data-role='deny']").click(function (e) {
        var changeRequest = $(e.target).closest(".change-request");
        var crId = changeRequest.data("request-id");
        var checklistID = changeRequest.data("request-checklist-id");
        var email = changeRequest.data("email");

        //showDenyPanel(email, crId);
        $.ajax({
            url: "../DataService.asmx/DenyChangeRequest",
            type: "POST",
            data: { changeRequestId: crId }
        }).fail(function () {
            notifier.setMessage("An error occurred during denial.", "red", 2500);
        });
        $("div.change-request").each(function () {
            if (($(this).data("request-checklist-id") == checklistID) && ($(this).data("request-id") <= crId)) {
                $(this).hide();
            }
        });
    });

    $(".changes-table").each(function () {
        if ($(this).has("tbody tr").length == 0) {
            $(this).hide();
        }
    });

    $(".additions-table").each(function () {
        if ($(this).has("tbody tr").length == 0) {
            $(this).hide();
        }
    });

    $(".removals-table").each(function () {
        if ($(this).has("tbody tr").length == 0) {
            $(this).hide();
        }
    });

    $(".previous-table").each(function () {
        if ($(this).has("tbody tr").length == 0) {
            $(this).hide();
            $(this).closest(".sectionWithHeader").hide();
        }
    });

    resize();
    window.onresize = resize;

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }

    GetUniversalExtensionChangeRequests();//added by venkat 11/16/2017
});

$(".change-request-header a[data-role='cancel']").click(function (e) {
    var changeRequest = $(e.target).closest(".change-request");
    var checklistID = changeRequest.data("request-checklist-id");
    var crId = changeRequest.data("request-id");
   
    var result = confirm("This will cancel this change request. Are you sure you want to proceed?");
    if (result) {
        $.ajax({
            url: "/DataService.asmx/CancelRequest",
            type: "POST",
            data: { ChangeId: crId }
        }).fail(function () {
            notifier.setMessage("An error occurred during cancellation.", "red", 2500);
        });
        $("div.change-request").each(function () {
            if (($(this).data("request-checklist-id") == checklistID) && ($(this).data("request-id") <= crId)) {
                $(this).hide();
            }
        });
    }
});


function GetUniversalExtensionChangeRequests() {

    syncPost("GetUniversalExtensionChangeRequests", "");//added by venkat 11/16/2017
    $("#univExtChangeRequestsdata").html(syncPostResult)

}

function openFontModal() {
    modal.init({
        controlName: "Controls/Priorities/Fonts.ascx",
        titleText: "Fonts",
        remoteParams: { FontSize: $("#font-size").val() }
    });
}

function ApproveChangeRequests(changeRequestids) {
    syncPost("ApproveUniversalExtensionRequests", JSON.stringify({ changeIds: changeRequestids }));
    GetUniversalExtensionChangeRequests();
    // alert(changeRequestids);

}

function DenyChangeRequests(changeRequestids) {
    syncPost("DenyUniversalExtensionRequests", JSON.stringify({ changeIds: changeRequestids }));
    GetUniversalExtensionChangeRequests();

}

function expandCallback(t) {
    $(t).find(".reply-comments").focus();
}

function showDenyPanel(email, crId) {
    if (typeof slider !== 'undefined') {
        slider.toggleClass('open');
    }

    var htmlToAppend = `<h2 style="padding-top:5px;">(Optional) Please provide reason here:</h2><div id='sliderPlaceholder'</div>`;

    slider.html(htmlToAppend);

    var remoteParams = { Email: email, ChangeRequestID: crId };
    $("#sliderPlaceholder").empty();
    $("#sliderPlaceholder").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/ChangeRequests/ChangeRequestDenyEmail.ascx"), remoteParams,
        function () {
            $("#sliderPlaceholder", slider).html($("#sliderPlaceholder", slider));
            var div = $("#sliderPlaceholder", slider).closest("div");
            var sendEmail = div.find("input[type='button']")[0];
            $(sendEmail).removeClass("btn-default").addClass("btn-secondary");
            var noEmailNeeded = div.find("input[type='button']")[1];
            $(noEmailNeeded).removeClass("btn-default").addClass("btn-secondary");
            $(noEmailNeeded).off();
            $(noEmailNeeded).on("click", closeSlider);
            $(sendEmail).on("mouseup", closeSlider);
            div.css({ 'display': 'flex', 'justify-content': 'space-evenly', 'margin-bottom': '6px' });
        });
}
 function closeSlider() {
    slider.toggleClass('open');
}


/* Copyright © 2024 Renegade Swish, LLC */

