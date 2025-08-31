function DoPreview(crId, checklistId, title) {
    window.modalModule.init({
        titleText: "Preview",
        controlName: 'Controls/Shared/ChecklistPreview.ascx',
        remoteParams: { checklistId: checklistId, changeId: crId }
    });
}
var modal = null;
var slider = null;
var rowSlider = null;
var currentRowSize = null;
var dialog = null;
var commentEmail = null;
var commentTaskName = null;
var emailComments = null;
var clamped = false;

$().ready(function () {
    var isResizing = false,
        lastDownX = 0,
        lastDownY = 0,
        handle = null,
        nextElement = null,
        prevElement = null,
        startWidth = 0,
        startHeight = 0,
        rightSiblingStartWidth = 0,
        nextSiblingStartHeight = 0,
        column,
        nextColumn,
        row,
        nextRow,
        rightSibling = null;

    var startFontSize = $("#font-size").val() == '' ? "14" : $("#font-size").val();
    var startRowSize = $("#row-height").val() == '' ? "1" : $("#row-height").val();
    currentRowSize = startRowSize;

    let allTableDivs = $("div[data-role='wrap']");

    var columnWidths = $("#change-request-columns").val().split(",");

    var superVisorHeaderRows = $("#supervisor-table .header-row th");
    var userHeaderRows = $("#user-table .header-row th");

    adjustFontSize(startFontSize);
    adjustRowSize(startRowSize);

    superVisorHeaderRows.each(function (index, element) {
        $(this).width(columnWidths[index]);
    });

    userHeaderRows.each(function (index, element) {
        $(this).width(columnWidths[index]);
    });

    $(".header-table th").mousedown(function (e) {
        var element = $(e.target);

        if (e.offsetX > element.width() - 10) {
            isResizing = true;
            lastDownX = e.clientX;
            handle = element;
            rightSibling = element.next();
            startWidth = $(handle).width();
            rightSiblingStartWidth = rightSibling.width();
            column = handle.index();
            nextColumn = rightSibling.index();

            minWidth = parseInt(handle.css('min-width'), 10);
            maxWidth = parseInt(handle.css('max-width'), 10);

            $("#supervisor-table").addClass("no-select");
            $("#user-table").addClass("no-select");
        }
    });

    $(document).mousemove(function (e) {
        if (isResizing) {
            var headerChangeWidth = e.clientX - lastDownX;
            var newWidth = startWidth + headerChangeWidth;
            var newRightWidth = rightSiblingStartWidth - headerChangeWidth;
            if (newWidth > 0 && newRightWidth > 0) {
                $(".header-row").each(function () {
                    $(this).find("th").eq(column).width(newWidth);
                    $(this).find("th").eq(nextColumn).width(rightSiblingStartWidth - headerChangeWidth);
                });
                
            }
        }
    });

    $(document).mouseup(function () {
        if (isResizing) {
            isResizing = false;
            $("#supervisor-table").removeClass("no-select");
            $("#user-table").removeClass("no-select");

            let columnSizes = "";

            $(".header-table tr:first th").each(function (index, element) {
                columnSizes += `${$(element).width()},`;
            })
            updateUserPreference(columnSizes, "ChangeRequestColumns");
            wrapElements();
        }

    });

    dialog = $("#commentDialog").dialog({
        autoOpen: false,
        height: 240,
        width: 500,
        resizable: false,
        draggable: false,
        modal: true,
        closeOnEscape: false
    });



    slider = $("#slider").slider({
        min: 8,
        max: 20,
        value: startFontSize,
        step: 1,
        slide: function (event, ui) {
            adjustFontSize(ui.value);
        },
        stop: function (event, ui) {
            setTimeout(function () {
                updateUserPreference(ui.value, "ChangeRequestFonts");
            }, 500);
        }
    });

    rowSlider = $("#row-slider").slider({
        min: 1,
        max: 2,
        value: startRowSize,
        step: 1,
        slide: function (event, ui) {
            adjustRowSize(ui.value);
        },
        stop: function (event, ui) {
            setTimeout(function () {
                currentRowSize = ui.value;
                updateUserPreference(ui.value, "ChangeRequestRowHeight");
            }, 500);
        }
    });

    function adjustFontSize(fontSize) {
        $("#supervisor-table, #user-table").each(function (index, element) {
            $(element).css("height", fontSize + "px");
            $(element).find(".change-request-header, .cr-actions-nowrap a").css("font-size", fontSize + "px");
            $(element).find("[data-role='quick-comments']").css("width", fontSize + "px");
        });
        wrapElements();
    }

    function adjustRowSize(rowSize) {
        var targets = $(".change-request-header:not(:first-child)");
        targets.each(function (index, element) {
            let baseHeight = 20;
            $(element).height(baseHeight * (rowSize * .75));
            if (rowSize > 1) {
                clamped = true;
                toggleCss($(element), true);
            }
            else {
                clamped = false;
                toggleCss($(element), false)
            }
        });
       wrapElements();
    }

    function toggleCss(element, state) {
        if (state) {
            $(element).find("div[data-role='wrap'] span").css("white-space", "normal");
            $(element).find("div[data-role='wrap']").addClass("line-clamping-2");
            $(element).find("div[data-role='wrap']").css("text-overflow", "ellipsis");
            //$(element).find("div[data-entry='comments'] span:nth-child(2)").css("white-space", "normal");
            //$(element).find("div[data-entry='comments']").addClass("line-clamping-2");
        }
        else {
            $(element).find("div[data-role='wrap'] span").css("white-space", "nowrap");
            $(element).find("div[data-role='wrap']").removeClass("line-clamping-2");
            //$(element).find("div[data-entry='comments'] span:nth-child(2)").css("white-space", "nowrap");
            //$(element).find("div[data-entry='comments']").removeClass("line-clamping-2");
        }
    }

    modal = window.modalModule;

    var emailArea = $("div[data-role='email-area']");
    $("#supervisor-change-requests a[data-role='cancel']").css("display", "none");

    function hasOverflow(element) {
        const el = $(element);

        if (el.get(0).scrollWidth > el.innerWidth() || (el.hasClass("line-clamping-2") && (el.get(0).scrollHeight > el.innerHeight()))) {
            return true;
        }
        return false;
    }

    function wrapElements() {
        allTableDivs.each(function (index, element) {
            let anchor = $("<a>").attr("href", "javascript:;").attr("data-action", "toggleWrap").attr("onclick", "toggleText(event)");
            if (hasOverflow(element)) {
                if (!($(element).parent().is('a'))) {
                    $(element).wrap(anchor);
                }

            } else {

                if ($(element).parent().is('a')) {
                    $(element).unwrap();
                }
            }

        });
    }

    wrapElements();

    $("#userExpandAll").click(function (e) {
        if ($("#userExpandAll").hasClass("fa-plus-square-o")) {
            $("#user-change-requests i.fa-plus-square-o.proxy-expand").each(function (i, e) {
                e.click();
            });
            $("#userExpandAll").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
        } else {
            $("#user-change-requests i.fa-minus-square-o.proxy-expand").each(function (i, e) {
                e.click();
            });
            $("#userExpandAll").removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
        }

    });
    $(".proxy-expand").click(function (e) {
        let element = e.target;
        let requestId = $(element).data("request-id");
        if ($(element).hasClass("fa-plus-square-o")) {
            $(element).removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
        } else {
            $(element).removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
        }
        $(".proxy-target[data-request-id='" + requestId + "']").click();
    })

    $("#supervisorExpandAll").click(function (e) {
        if ($("#supervisorExpandAll").hasClass("fa-plus-square-o")) {
            $("#supervisor-change-requests i.fa-plus-square-o.proxy-expand").each(function (i, e) {
                e.click();
            });
            $("#supervisorExpandAll").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
        } else {
            $("#supervisor-change-requests i.fa-minus-square-o.proxy-expand").each(function (i, e) {
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

        if (typeof slider === 'undefined')
            window.location = "MobileManageTasks.aspx?checklistId=" + checklistId + "&changeId=" + changeId;
        else
            window.location = "ManageTasks.aspx?checklistId=" + checklistId + "&changeId=" + changeId;
    });

    $("[data-role='quick-comments']").click(function (e) {
        e.preventDefault();

        var changeRequest = $(e.target);
        commentTaskName = changeRequest.data("request-checklist-name");
        commentEmail = changeRequest.data("email");
        $("#commentDialog").dialog("open");
    })

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
        $("tr.change-request-line").each(function () {
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

        window.modalModule.init({
            titleText: "Reason",
            controlName: "Controls/ChangeRequests/ChangeRequestDenyEmail.ascx",
            remoteParams: {
                Email: email,
                ChangeRequestID: crId
            }
        });
        $.ajax({
            url: "../DataService.asmx/DenyChangeRequest",
            type: "POST",
            data: { changeRequestId: crId }
        }).fail(function () {
            notifier.setMessage("An error occurred during denial.", "red", 2500);
        });
        $("tr.change-request-line").each(function () {
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
        $("tr.change-request-line").each(function () {
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

function toggleText(event) {
    let element = event.target;
    if (currentRowSize > 1 && $(element).parent().hasClass("line-clamping-2")) {
        $(element).parent().removeClass("line-clamping-2");
        $(element).css('white-space', 'normal');
    }
    else if (currentRowSize > 1 && !$(element).parent().hasClass("line-clamping-2")) {
        $(element).parent().addClass("line-clamping-2");
    }
    else {

        if ($(element).css('white-space') == "nowrap") {
            $(element).css('white-space', 'normal');
        }
        else {
            $(element).css('white-space', 'nowrap');
        }
    } 
    
}

function updateUserPreference(selectedValue, selectedField) {
    $.ajax({
        url: "/DataService.asmx/UpdateUserPreference",
        type: "POST",
        data: JSON.stringify({ value: selectedValue, field: selectedField }),
        contentType: "application/json",
        success: function (data) {
        }
    });
}
function getColumnWidths(row) {
    let totalWidth = 0;
    Array.from(row).map(c => totalWidth += c.offsetWidth);
    return totalWidth;
}

function sendRequestEmail() {

    $.ajax({
        url: "../DataService.asmx/SendChangeRequestEmail",
        type: "POST",
        data: {
            to: commentEmail,
            checklistname: commentTaskName,
            body: $("#quickComments").val()
        },
        success: function (data) {
            $("#commentDialog").dialog("close");
            notifier.setMessage("Email Sent.", "green", 1000);
            commentEmail = '';
            commentTaskName = '';
            emailComments = '';
            $("#quickComments").val("");
            commentEmail = '';
            commentTaskName = '';
            emailComments = '';

        },
        error: function (request, status, error) {
            alert(request.responseText);
            $("#quickComments").val("");
        }
    }).done(function () {
        $("#quickComments").val("");
        notifier.setMessage("Email Sent.", "green", 1000);
        $("#commentDialog").dialog("close");
    });

};

function closeCommentModal() {
    $("#commentDialog").dialog("close");

};


/* Copyright © 2024 Renegade Swish, LLC */

