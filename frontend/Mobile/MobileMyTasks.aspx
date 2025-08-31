<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileMyTasks.aspx.cs" Inherits="QProcess.Mobile.MobileMyTasks" MasterPageFile="Mobile.master" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
    <style type="text/css">
    .callout {
        font-size: .92em;
        border: 1px solid #e4e7ea;
        border-radius: .25rem;
        margin: 1rem 0;
        padding: .75rem 1.25rem;
        position: relative;
        background-color: #fbfafa;
    }

    .fa-ban {
        color: red;
        margin-left: 5px;
        cursor: pointer;
    }
    .text-header {
        padding-top: 0;
    }
    .nav-scroller {
        height:26px;
    }
    #searchBarMobile {
        position: fixed;
        top: 45px;
        left: 0;
        z-index: 1100;
        width: 100%;
        background: #fff;
        border-bottom: 1px solid #eee;
    }
    #main {
        padding-top: 10px;
    }
    #recurrence {
        max-width: none;
        width: 100%;
        font-size: 0.95em;
        padding: 0.25rem 0.5rem;
    }
    #btn-search-tasks, #btn-get-extension {
        padding: 0.25rem 0.5rem;
        font-size: 0.95em;
        line-height: 1.5;
    }
    </style>
    <script type="text/javascript">
        var mobileTitle = "My Tasks";
    </script>
</asp:Content>

<asp:Content ID="nav" runat="server" ContentPlaceHolderID="navContent">
    <!-- Search Bar (initially hidden) -->
    <div id="searchBarMobile" style="display: none; padding: 4px 0; background: #fff; border-bottom: 1px solid #eee;">
        <div class="container-fluid">
            <div class="input-group">
                <input id="txtSearchInputMobile" type="text" class="form-control" placeholder="Start typing to search..." />
            </div>
            <div class="d-flex align-items-center justify-content-between" style="margin-top: 8px; min-height: 32px;">
                <div id="searchResultsMobile" class="flex-grow-1"></div>
                <div>
                    <button id="btnCloseSearchMobile" class="btn env-specific-btn btn-sm" type="button" title="Close Search">Close</button>
                    <button id="btnResetSearchMobile" class="btn env-specific-btn btn-sm" type="button" title="Reset Search">Reset</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Nav Scroller (always visible) -->
    <div class="nav-scroller bg-white box-shadow text-center text-header">
        <span class="xx-size">Tasks with due date between</span>
        <span class="xs-size">Tasks due between</span>
        <input type="text" class="date-filter" id="start-date" readonly="readonly" value="<%=StartDateString%>" />
        and
        <input type="text" class="date-filter" id="end-date" readonly="readonly" value="<%=EndDateString%>" />
    </div>
</asp:Content>


<asp:Content ID="main" runat="server" ContentPlaceHolderID="mainContent">
    <div class="row align-items-center" style="margin-bottom: 8px;">
        <div class="col pr-1">
            <select id="recurrence" class="form-control form-control-sm">
                <option value="0">All</option>
                <option value="1">One Time</option>
                <option value="2">Recurring</option>
                <option value="3">Open</option>
            </select>
        </div>
        <div class="col-auto pl-1">
            <button id="btn-search-tasks" type="button" class="btn btn-secondary btn-sm" title="Search Tasks">
                <i class="fa fa-search"></i>
            </button>
            <button id="btn-get-extension" type="button" class="btn btn-secondary btn-sm">Get Task Extensions</button>
        </div>
    </div>
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script type="text/javascript">
        let mobileSearchTimeout = null;
        let mobileSearchVersion = 0; // Incremented for each search
        let lastProcessedVersion = 0; // Tracks the last version processed

        // Reset search (like desktop "Reset" button)
        $('#btnResetSearchMobile').on('click', function () {
            $('#txtSearchInputMobile').val('');
            $("#main .task-group").each(function () {
                removeMobileHighlighting(this);
            });
            $("#main .task-group").show();
            $('#searchResultsMobile').html('');
            bindTaskEvent();
        });

        $('#btnCloseSearchMobile').on('click', function () {
            $('#txtSearchInputMobile').val('');
            $("#main .task-group").each(function () {
                removeMobileHighlighting(this);
            });
            $("#main .task-group").show();
            $('#searchResultsMobile').html('');
            $('#searchBarMobile').slideUp(150);
            bindTaskEvent();
        });

        // Remove previous highlighting from all tasks
        function removeMobileHighlighting(node) {
            if (!node) return;
            var $node = $(node);
            // If original HTML is not stored, store it now
            if ($node.data('original-html') === undefined) {
                $node.data('original-html', $node.html());
            }
            // Always restore from the original
            $node.html($node.data('original-html'));
        }

        // Highlight search terms in a node
        function highlightMobileSearchResults(node, searchString) {
            searchString = (searchString || '').trim();
            if (!node || !searchString) return;
            removeMobileHighlighting(node);

            // Split the search string into keywords
            const keywords = searchString.split(' ').filter(Boolean);
            keywords.forEach(keyword => {
                if (!keyword) return;
                // Use a regex to find and wrap keywords
                $(node).find("*").addBack().contents().filter(function () {
                    return this.nodeType === 3 && this.nodeValue.toLowerCase().indexOf(keyword.toLowerCase()) !== -1;
                }).each(function () {
                    var regex = new RegExp('(' + keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
                    var html = this.nodeValue.replace(regex, '<span class="searchhighlight">$1</span>');
                    $(this).replaceWith(html);
                });
            });
        }

        // Main search function
        function mobileTaskSearch(criteria, version) {
            criteria = (criteria || '').trim();
            var $results = $('#searchResultsMobile');
            $results.html('<span>Searching...</span>');

            // Remove previous highlights and highlight current input
            $("#main .task-group:visible").each(function () {
                removeMobileHighlighting(this);
                highlightMobileSearchResults(this, criteria);
            });

            if (!criteria) {
                $("#main .task-group").show();
                $results.html('');
                bindTaskEvent();
                lastProcessedVersion = version;
                return;
            }

            $.ajax({
                url: "../DataService.asmx/SearchMyTask",
                type: "POST",
                data: JSON.stringify({
                    criteria: criteria,
                    logicAndOr: true,
                    includeTask: true,
                    includeItem: true,
                    includeComment: false,
                    fromDate: $("#start-date").val(),
                    toDate: $("#end-date").val()
                }),
                dataType: "json",
                contentType: "application/json",
                success: function (msg) {
                    // Only process if this is the latest search
                    if (version < mobileSearchVersion) return;
                    lastProcessedVersion = version;

                    var foundIds = msg.d || [];
                    var count = 0;

                    $("#main .task-group").each(function () {
                        var $task = $(this);
                        var checklistId = $task.attr("data-checklist-id");
                        if (foundIds.indexOf(checklistId) !== -1) {
                            $task.show();
                            count++;
                        } else {
                            $task.hide();
                        }
                    });

                    bindTaskEvent();

                    if (count === 0) {
                        $results.html('<span>No tasks found.</span>');
                    } else {
                        $results.html('<span>Found ' + count + ' task(s).</span>');
                    }
                },
                error: function () {
                    if (version < mobileSearchVersion) return;
                    $results.html('<span class="text-danger">Search failed. Please try again.</span>');
                }
            });
        }


        // Attach search event to input
        $('#txtSearchInputMobile').on('input', function () {
            var criteria = $(this).val().trim();
            clearTimeout(mobileSearchTimeout);
            mobileSearchTimeout = setTimeout(function () {
                mobileSearchVersion++;
                mobileTaskSearch(criteria, mobileSearchVersion);
            }, 400); // 400ms delay after last keystroke
        });


        $('<style>.searchhighlight { background-color: red; color: white; }</style>').appendTo('head');

        // Show the search bar above nav-scroller
        $('#btn-search-tasks').on('click', function () {
            logFeatureUsage('MyTasksSearch', 'mobile');
            $('#searchBarMobile').slideDown(150, function () {
                $('#txtSearchInputMobile').val('').focus();
                $('#searchResultsMobile').html('');
            });
        });

        // Hide the search bar
        $('#btnCloseSearchMobile').on('click', function () {
            $('#searchBarMobile').slideUp(150);
        });

        // Optional: Hide on ESC key
        $('#txtSearchInputMobile').on('keydown', function (e) {
            if (e.key === "Escape") {
                $('#searchBarMobile').slideUp(150);
            }
        });

        var checklistSaving = false;
        $(function () {
            $('#btn-get-extension').on('click', function () {
                slider.html(`
                <h2>Extend Deadline</h2>
                <div class="row">
                  <div class="col overdue-tasks"></div>
                </div>
                <div class="row">
                  <div class="col">
                    <span>Comments</span>
                    <textarea class="form-control" rows="5"></textarea>
                  </div>
                </div>
                <div class="row">
                  <div class="col text-center mt-3">
                    <button class="btn btn-primary">Send Extension Request</button>
                    <button class="btn btn-secondary">Cancel</button>
                  </div>
                </div>
                `);

                syncPost("GetOverdueTasksForQuickDeadlineExtension", "");
                slider.find(".overdue-tasks").html(syncPostResult);

                slider.find(".btn-secondary").on("click", function () {
                    slider.toggleClass('open');
                });
                slider.find(".btn-primary").on("click", function () {
                    syncPost("SendRequestsForOverdueTaskExtensions", JSON.stringify({ comment: slider.find("textarea").val() }));
                    if (syncPostSuccess) {
                        alert("Extension Requests Sent Successfully");
                        slider.toggleClass('open');
                    }
                });
                slider.toggleClass('open');
            });

            $('#btn-close-slider').on('click', function () {
                slider.toggleClass('open');
            });

            $('#start-date, #end-date').mobiscroll().date({
                theme: getMobileOperatingSystem(),
                display: 'modal',
                onSelect: function (e) {
                    refreshPage();
                }
            });
        });

        $().ready(function () {
            $("#recurrence").on("change", refreshPage);
            refreshPage();
        });
        function refreshPage() {
            Post("../Services/ControlService.asmx/Control_GET", JSON.stringify({ req: "MobileChecklistHeader" }), function (msg) {
                let ctl = msg.d;

                let req = {};
                req.StartDate = $("#start-date").val();
                req.EndDate = $("#end-date").val();
                req.Recurrence = $("#recurrence").val();
                Post("../Services/ControlService.asmx/Checklist_GET", JSON.stringify({ req }), function (iMsg) {
                    initialize(iMsg.d, ctl);
                });
            });
        }
        async function initialize(rsp, ctl) {
            let list = $("#main");
            list.find(".task-group").remove();

            for (let i = 0; i < rsp.length; i++) {
                let e = rsp[i];
                let div = $(ctl);

                div.data("data-record", e);
                div.attr("data-unique-id", e.UniqueId);
                div.find(".task-title")
                    .attr("title", e.Name)
                    .text(e.Name.length > 47 ? e.Name.substr(0, 47) + "..." : e.Name);

                list.append(div);
                await refreshChecklist(e.UniqueId, e);
            }
            bindTaskEvent();
        }

        function updateCompleteBtn(div) {
            let all = true;
            var chks = div.find(".task-item input[type=checkbox]");
            chks.each(function () {
                if ($(this).IsChecked() == false) {
                    all = false;
                    return false;
                }
            });

            if (!all && chks.length > 1)
                div.find(".close-complete").addClass("disabled");
            else
                div.find(".close-complete").removeClass("disabled");
        }

        function bindTaskEvent() {
            let list = $("#main");
            list.find(".close-reopen").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                reopenChecklist(grp.attr("data-unique-id"));
            });
            list.find(".close-complete").off().on("click", function () {
                if ($(this).hasClass("disabled")) {
                    return;
                }
                var grp = $(this).closest(".task-group");
                let myPromise = new Promise(function (resolve, reject) {
                    var items = [];
                    grp.find(".task-item.task-item-check").each(function () {
                        var item = {};
                        item.ActiveChecklistId = grp.attr("data-unique-id");
                        item.Comments = $(this).find("textarea").val();
                        item.IsCompleted = $(this).find("input[type=checkbox]").IsChecked();
                        item.ActiveChecklistItemId = $(this).attr("data-item-id");
                        items.push(item);
                    });

                    saveChecklistItems(items, grp, false, resolve, reject);
                })
                myPromise.then(function () {
                    completeChecklist(false, "", grp.attr("data-unique-id"));
                });
            });
            list.find(".task-summary").off().on("click", function () {
                let div = $(this).closest(".task-group");
                let btn = div.find(".btn-toggle");

                if (btn.hasClass("fa-minus-square-o")) {
                    btn.removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
                    div.find(".task-header, .task-item, .task-button").slideUp("fast");
                    return;
                }

                btn.removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
                if (div.data("data-loaded") != "true") {
                    Post("../Services/ControlService.asmx/ChecklistItem_GET", JSON.stringify({ uniqueId: div.attr("data-unique-id") }), function (iiMsg) {
                        let rsp = iiMsg.d;
                        let ctl = div.find(".task-item");

                        if (rsp != null && rsp.length > 0) {
                            for (let i = 0; i < rsp.length; i++) {
                                let c = ctl.clone();
                                let e = rsp[i];

                                switch (e.ItemTypeString) {
                                    case "Checkbox":
                                        c.addClass("task-item-check");
                                        c.attr("data-item-id", e.ItemId);
                                        c.find(".task-item-text").html(e.Description);
                                        if (e.Url && e.Url != "") {
                                            var link = $("<a>");
                                            link.attr("href", e.Url);
                                            link.text("(More Info)");
                                            var linkSpan = $("<span>");
                                            linkSpan.append("&nbsp;");
                                            linkSpan.append(link);
                                            c.find(".task-item-text").after(linkSpan);
                                        }
                                        c.find(".task-completed-by").text(e.CompletedBy ?? "");
                                        c.find(".task-completed-on").text(e.CompletedOnString ?? "");
                                        c.find("textarea").val(e.Comments);
                                        if (e.IsItemComplete) c.find("input[type=checkbox]").checked(true);
                                        ctl.after(c);
                                        break;
                                    case "Notes":
                                        c.addClass("task-item-note");
                                        c.attr("data-item-id", e.ItemId);
                                        c.find(".task-item-text").html(e.Description);
                                        if (e.Url && e.Url != "") {
                                            var link = $("<a>");
                                            link.attr("href", e.Url);
                                            link.text("(More Info)");
                                            var linkSpan = $("<span>");
                                            linkSpan.append("&nbsp;");
                                            linkSpan.append(link);
                                            c.find(".task-item-text").after(linkSpan);
                                        }
                                        c.find(".task-completed-by").closest("div").hide();
                                        c.find(".task-completed-on").closest("div").hide();
                                        c.find("textarea").remove();
                                        c.find("input[type=checkbox]").remove();
                                        ctl.after(c);
                                        break;
                                    case "Heading":
                                        c.addClass("task-item-heading");
                                        c.attr("data-item-id", e.ItemId);
                                        c.find(".task-item-text").html(e.Description);
                                        if (e.Url && e.Url != "") {
                                            var link = $("<a>");
                                            link.attr("href", e.Url);
                                            link.text("(More Info)");
                                            var linkSpan = $("<span>");
                                            linkSpan.append("&nbsp;");
                                            linkSpan.append(link);
                                            c.find(".task-item-text").after(linkSpan);
                                        }
                                        c.find(".task-completed-by").closest("div").remove();
                                        c.find(".task-completed-on").closest("div").remove();
                                        c.find("textarea").remove();
                                        c.find("input[type=checkbox]").remove();
                                        ctl.after(c);
                                        break;
                                    case "Sub Heading":
                                        c.addClass("task-item-subheading");
                                        c.attr("data-item-id", e.ItemId);
                                        c.find(".task-item-text").html(e.Description);
                                        if (e.Url && e.Url != "") {
                                            var link = $("<a>");
                                            link.attr("href", e.Url);
                                            link.text("(More Info)");
                                            var linkSpan = $("<span>");
                                            linkSpan.append("&nbsp;");
                                            linkSpan.append(link);
                                            c.find(".task-item-text").after(linkSpan);
                                        }
                                        c.find(".task-completed-by").closest("div").remove();
                                        c.find(".task-completed-on").closest("div").remove();
                                        c.find("textarea").remove();
                                        c.find("input[type=checkbox]").remove();
                                        ctl.after(c);
                                        break;
                                    case "Spacer":
                                        c.addClass("task-item-spacer");
                                        c.attr("data-item-id", e.ItemId);                                        
                                        c.find("input[type=checkbox]").closest("div").remove();
                                        ctl.after(c);
                                        break;
                            }
                            }
                        };

                        ctl.remove();

                        var chks = div.find(".task-item input[type=checkbox]");
                        
                        updateCompleteBtn(div);
                        chks.on("change", function () { updateCompleteBtn(div) });                        

                        div.find(".task-header, .task-item, .task-button").slideDown("fast");
                    });
                    div.data("data-loaded", "true");
                } else {
                    div.closest(".task-group").find(".task-header, .task-item, .task-button").slideDown("fast");
                }
            });
            list.find(".close-na").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                var items = [];
                grp.find(".task-item").each(function () {
                    var item = {};
                    item.ActiveChecklistId = grp.attr("data-unique-id");
                    item.Comments = "N/A";
                    item.IsCompleted = grp.find("input[type=checkbox]").IsChecked();
                    item.ActiveChecklistItemId = $(this).attr("data-item-id");
                    items.push(item);
                });
                saveChecklistItems(items, grp, true);
            });
            list.find(".close-save").off().on("click", function () {
                
                var grp = $(this).closest(".task-group");
                var items = [];
                grp.find(".task-item.task-item-check").each(function () {
                    var item = {};
                    item.ActiveChecklistId = grp.attr("data-unique-id");
                    item.Comments = $(this).find("textarea").val();
                    item.IsCompleted = $(this).find("input[type=checkbox]").IsChecked();
                    item.ActiveChecklistItemId = $(this).attr("data-item-id");
                    items.push(item);
                });
                saveChecklistItems(items, grp, false);
            });
            list.find(".btn-view-alert").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                viewAlert(grp.attr("data-unique-id"));
            });
            list.find(".btn-add-priority").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                addToPriority(grp.attr("data-unique-id"));
            });
            list.find(".btn-manage-task").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                window.location.href = "MobileManageTasks.aspx?checklistId=" + grp.attr("data-checklist-id");
            });
            list.find(".btn-change-deadline").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                changeDeadline(grp.attr("data-unique-id"), grp.attr("data-checklist-id"), grp.attr("data-task-stage"));
            });
            list.find(".btn-manage-nag").off().on("click", function () {
                var grp = $(this).closest(".task-group");
                showNag(grp.attr("data-checklist-id"));
            });
        }
        function completeChecklist(na, naReason, uniqueId) {
            $.ajax({
                url: "../DataService.asmx/CompleteChecklist",
                type: "POST",
                data: JSON.stringify({ na: na, naReason: naReason, uniqueId: uniqueId }),
                dataType: "json",
                contentType: "application/json",
                success: function (msg) {
                    //alert("Save successful");
                    refreshChecklist(uniqueId);
                },
                error: function (xhr, status, e) {
                    alert("Error saving");
                }
            });
        }
        function reopenChecklist(uniqueId) {
            $.ajax({
                url: "../DataService.asmx/ReOpenTask",
                type: "POST",
                data: JSON.stringify({ reportId: 0, taskId: uniqueId }),
                dataType: "json",
                contentType: "application/json",
                async: false,
                success: function (msg) {
                    //alert("Save successful");
                    refreshChecklist(uniqueId);
                },
                error: function (xhr, status, e) {
                    alert("Error saving");
                }
            });
        }
        function refreshChecklist(uniqueId, data) {
            let isSelfRefresh = false;
            let myPromise = new Promise(function (resolve, reject) {
                if (data == undefined || data == null) {
                    let req = {};
                    req.StartDate = $("#start-date").val();
                    req.EndDate = $("#end-date").val();
                    req.Recurrence = 0;
                    req.ActiveChecklistId = uniqueId;

                    $.ajax({
                        url: "../Services/ControlService.asmx/Checklist_GET",
                        type: "POST",
                        data: JSON.stringify({ req }),
                        dataType: "json",
                        contentType: "application/json",
                        success: function (msg) { resolve(msg.d[0]); },
                        error: function (msg) { reject(msg.d); }
                    });

                    isSelfRefresh = true;
                } else {
                    resolve(data);
                }
            });

            myPromise.then(function (value) {
                let div = $("div[data-unique-id='" + uniqueId + "']");
                let e = value;

                div.data("data-record", e);
                div.attr("data-unique-id", e.UniqueId);
                div.attr("data-task-stage", e.TaskStage);
                div.attr("data-checklist-id", e.ChecklistId);
                div.find(".task-title").attr("title", e.Name).text(e.Name.length > 47 ? e.Name.substr(0, 47) + "..." : e.Name);

                if (!e.ControllerPartOfAssignee)
                    div.find(".task-title").attr("style", "color:#ee9020");

                let right = div.find(".task-summary");
                if (e.PendingChange)
                    right.prepend(`<i class="fa fa-forward pending-indicator" title='A new deadline of ${e.NewDeadlineText} has been requested for this task'></i>`);

                if (e.IsRecurring)
                    right.prepend(`<i class="fa fa-refresh recurring-indicator"></i>`);

                div.find(".task-due-date").html(`<span class="${e.CompletionCssClass}">${e.CompletionString}</span> ${e.DisplayDate}`);

                if (e.TaskStage == 3) { //future
                    div.addClass("future");
                    div.find(".task-button").remove();
                }
                else if (e.CompletionCssClass == "completed") {
                    div.find(".task-summary").addClass("reopen");
                    div.find(".task-button").html(`
                        <span>
                             <a class="btn-task close-reopen"><i class="fa fa-reply"></i> Reopen</a>
                        </span>`);
                } else {
                    div.find(".task-summary").removeClass("reopen");
                    div.find(".task-button").html(`
                        <span>
                        <a class="btn-task close-save"><img src="../Images/save_sm.gif"> Save</a>
                        <a class="btn-task close-complete"><i class="fa fa-check-square-o"></i> Complete</a>
                        <a class="btn-task close-na"><i class="fa fa-ban"></i> N/A - Close Task</a>
                        </span>`);
                }

                div.find(".task-header .na-comment").remove();
                if (e.IsNA) {
                    div.find(".task-header").append(`
                            <div class="na-comment">
                                <span class="text-red-bold">This task has been marked as N/A.</span>
                            </div>
                            <div class="na-comment">
                                <span class="text-red-bold">REASON: ${e.NAReason}</span>
                            </div>`);
                }

                div.find(".task-controller").html(e.Controllers);
                div.find(".task-assigned").html(e.Assignees);
                div.find(".task-created").html(e.DisplayCreated);
                if (isSelfRefresh) {
                    updateCompleteBtn(div);
                    bindTaskEvent();
                }
            }, function (error) {
                alert(error);
            });

            return myPromise;
        }
        function saveChecklistItems(items, selectedTask, isNA, resolvePromise, rejectPromise) {
            $.ajax({
                url: "../DataService.asmx/SaveChecklistItems",
                type: "POST",
                data: JSON.stringify({ items: items }),
                dataType: "json",
                contentType: "application/json",
                success: function (msg) {
                    var rsp = msg.d;
                    for (var i = 0; i < rsp.length; i++) {
                        var e = rsp[i];
                        var item = selectedTask.find("div[data-item-id='" + e.ActiveChecklistItemId + "']");
                        item.find("input[type=checkbox]").prop("checked", e.IsCompleted);
                        item.find("textarea").val(e.Comments);
                        item.find(".task-completed-by").html(e.CompletedBy);
                        item.find(".task-completed-on").html(e.CompletedOn === null ? "" : e.CompletedOn);
                    }

                    if (isNA) {
                        selectedTask.find(".close-na").hide();

                        slider.html(`
                            <h2>Reason for N/A</h2>
                            <div class="row">
                              <div class="col">
                                <textarea class="form-control" rows="5"></textarea>
                              </div>
                            </div>
                            <div class="row">
                              <div class="col text-center mt-3">
                                <a class="btn-task close-na"><i class="fa fa-ban"></i> N/A - Close Task</a>
                              </div>
                            </div>`);

                        slider.find(".close-na").on("click", function () {
                            completeChecklist(true, slider.find("textarea").val(), selectedTask.attr("data-unique-id"));

                            slider.toggleClass('open');
                        });
                        slider.toggleClass('open');
                    } else {
                        updateCompleteBtn(selectedTask);
                    }

                    if (resolvePromise) resolvePromise();
                },
                error: function (xhr, status, e) {
                    alert("Error saving");
                    if (rejectPromise) rejectPromise();
                }
            });
        }
        function viewAlert(uniqueId) {
            $.post(
                '../JQueryHandler.ashx?ControlName=Controls/Shared/ViewAlerts.ascx',
                {
                    UniqueId: uniqueId,
                    TaskStage: "Current"
                }
            ).done(function (data) {
                slider.html(`
                            <h2>View Alerts</h2>
                            <div class="row">
                              <div class="col">${data}</div>
                            </div>
                            <div class="row">
                              <div class="col text-center mt-3">
                                <button class="btn btn-primary close-alert">Close Alert</button>
                              </div>
                            </div>`);

                slider.find(".close-alert").on("click", function () {
                    slider.toggleClass('open');
                });
                slider.toggleClass('open');
            });
        }
        function addToPriority(uniqueId) {
            Post("../DataService.asmx/AddPriorities", JSON.stringify({ taskId: uniqueId }), function (msg) {
                if (msg.d) {
                    alert("Task Added");
                }
            });
        }
        function changeDeadline(uniqueId, checklistId, taskStage) {
            slider.html(`<h2>Change Deadline</h2><p>Loading...please wait</p>`);
            slider.toggleClass('open');

            var req = {
                TaskStage: taskStage,
                ChecklistId: checklistId,
                TaskId: uniqueId
            };

            Post("../Services/ControlService.asmx/ChecklistAuth_GET", 
                JSON.stringify({ req }), function (msg) {
                    var rsp = msg.d;
                    var softDueDT = parseDateValue(rsp.ReminderDate);
                    var newDueDT = parseDateValue(rsp.DueDate);
                    slider.html(`
                        <h2 data-unique-id="${uniqueId}">Change Deadline</h2>
                        <div class="card mt-3 soft-due">
                          <div class="card-body">
                            <div class="row">
                                <div class="col">
                                    <h5 class="card-title">Soft Due</h5>
                                </div>
                                <div class="col text-right">
                                    <a href="#" class="card-link">Update</a>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col"><input type="text" class="due-date form-control" value="${softDueDT[0]}" /></div>
                                <div class="col"><select class="form-control">${listOfTime}</select></div>
                            </div>
                          </div>
                        </div>
                        <div class="card mt-3 request-due">
                          <div class="card-body">
                            <div class="row">
                                <div class="col text-center">
                                    <a href="#" class="card-link">Request New Due Date</a>
                                </div>
                            </div>
                          </div>
                        </div>
                        <div class="card mt-3 new-due">
                          <div class="card-body">
                            <div class="row">
                                <div class="col">
                                    <h5 class="card-title">New Due</h5>
                                </div>
                                <div class="col text-right">
                                    <a href="#" class="card-link">Update</a>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col"><input type="text" class="due-date form-control" value="${newDueDT[0]}" /></div>
                                <div class="col"><select class="form-control">${listOfTime}</select></div>
                            </div>
                            <div class="row mt-2 request-comment">
                                <div class="col">
                                    <span>Comment</span>
                                    <textarea class="form-control"></textarea>
                                </div>
                            </div>
                          </div>
                        </div>
                        <div class="row">
                            <div class="col text-center mt-3">
                                <button class="btn btn-danger delete-change-deadline">Delete</button>
                                <button class="btn btn-secondary close-change-deadline">Cancel</button>
                            </div>
                        </div>`);
                    slider.find(".soft-due select option").filter(function () { return $(this).text() == softDueDT[1]; }).prop("selected", true);
                    slider.find(".new-due select option").filter(function () { return $(this).text() == newDueDT[1]; }).prop("selected", true);
                    slider.find('.due-date').mobiscroll().date({
                        theme: getMobileOperatingSystem(),
                        display: 'modal'
                    });
                    slider.find(".soft-due .card-link").on("click", updateSoftDue);
                    slider.find(".new-due .card-link").on("click", updateNewDate);
                    slider.find(".close-change-deadline").on("click", function () {
                        slider.toggleClass('open');
                    });
                    if (rsp.Controller) {
                        slider.find(".request-due, .request-comment").hide();
                        slider.find(".delete-change-deadline").on("click", deleteChecklist);
                    } else {
                        slider.find(".new-due .card-link").text("Send Request");
                        slider.find(".new-due, .delete-change-deadline").hide();
                        slider.find(".request-due .card-link").on("click", function () {
                            slider.find(".request-due").hide();
                            slider.find(".new-due").show();
                        });
                        if (rsp.PendingChange) {
                            slider.find(".request-comment").after(`
                            <div class="form-group mt-1">
							    <i class="fa fa-warning" style="color: goldenrod; margin-right:5px"></i><label style="color:#d80d0d">Deadline Extension Pending!</label>
						    </div>`);
                        }
                    }
            });    
        }
        function updateSoftDue() {
            var card = slider.find(".soft-due");
            var selectedTime = card.find("select option:selected").val();
            var softDueDate = new Date(card.find(".due-date").val());
            softDueDate.setHours(selectedTime);
            if (isDecimal(selectedTime)) softDueDate.setMinutes(30);
            
            card = slider.find(".new-due");
            selectedTime = card.find("select option:selected").val();
            var dueDate = new Date(card.find(".due-date").val());
            dueDate.setHours(selectedTime);
            if (isDecimal(selectedTime)) dueDate.setMinutes(30);
            
            if (dueDate < softDueDate) {
                alert("Soft due date is after the normal due date. Please pick a date before the due date.");
            } else {
                $.ajax({
                    url: "../DataService.asmx/UpdateReminderDate",
                    type: "POST",
                    data: JSON.stringify({
                        taskId: slider.find("h2").attr("data-unique-id"),
                        dateTime: softDueDate
                    }),
                    contentType: "application/json",
                    success: function (data) {
                        refreshPage();
                        slider.toggleClass('open');
                    }
                });
            }
        }
        function updateNewDate() {
            var card = slider.find(".new-due");
            var selectedTime = card.find("select option:selected").val();
            var dueDate = new Date(card.find(".due-date").val());
            dueDate.setHours(selectedTime);
            if (isDecimal(selectedTime)) dueDate.setMinutes(30);
            
            $.ajax({
                url: "../DataService.asmx/UpdateDueDate",
                type: "POST",
                data: JSON.stringify({
                    taskId: slider.find("h2").attr("data-unique-id"),
                    dateTime: dueDate
                }),
                contentType: "application/json",
                success: function (data) {
                    refreshPage();
                    slider.toggleClass('open');
                }
            });
        }
        function deleteChecklist() {
            var choice = confirm("Are you sure you want to delete this task?");
            if (choice) {
                $.ajax({
                    url: "../DataService.asmx/DeleteActiveChecklist",
                    type: "POST",
                    data: JSON.stringify({
                        activeChecklistId: slider.find("h2").attr("data-unique-id")
                    }),
                    contentType: "application/json",
                    success: function (data) {
                        refreshPage();
                        slider.toggleClass('open');
                    },
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert(jqXHR.responseText);
                    }
                });
            }
        }
        function requestNewDueDate() {
            var card = slider.find(".new-due");
            var selectedTime = card.find("select option:selected").val();
            var dueDate = new Date(card.find(".due-date").val());
            dueDate.setHours(selectedTime);
            if (isDecimal(selectedTime)) dueDate.setMinutes(30);

            $.ajax({
                url: "../DataService.asmx/RequestDueDateChange",
                type: "POST",
                data: JSON.stringify({
                    taskId: slider.find("h2").attr("data-unique-id"),
                    newDueTime: dueDate,
                    comment: card.find("textarea").val()
                }),
                contentType: "application/json",
                success: function (data) {
                    refreshPage();
                    slider.toggleClass('open');
                },
                error: function (jqXHR, textStatus, errorThrown) {
                    alert(jqXHR.responseText);
                }
            });
        }
        function isDecimal(num) {
            if (parseFloat(parseInt(num)) === parseFloat(num)) {
                return false;
            }
            return true;
        }
        function parseDateValue(value) {
            var vals = value.split(" ");
            var date = "";
            var time = "";

            if (vals.length == 3) {
                date = vals[0];
                time = vals[1] + " " + vals[2];
            } else {
                date = vals[1];
                time = vals[2] + " " + vals[3];
            }

            return [date, time];
        }
        function showNag(checklistId) {
            slider.html(`
                <h2 data-checklist-id="${checklistId}">Nag Detail</h2>
                <div class="callout">
                    <h5>Message</h5>
                    <div class="row form-group">
                        <div class="col">
                            <span>Subject</span>
                            <input id="txtSubject" type="text" class="form-control" />
                        </div>
                    </div>
                    <div class="row form-group">
                        <div class="col">
                            <span>Body Text</span>
                            <textarea id="txtBodyText" class="form-control"></textarea>
                        </div>
                    </div>
                </div>

                <div class="callout">
                    <h5>Schedule</h5>
                    <div class="row form-group">
                        <div class="col form-inline">
                            <span class="mb-1">Type</span>
                            <div class="form-check">
                                <input id="rbInterval" checked="checked" type="radio" name="rbType" value="0" class="form-check-input" /> 
                                <label for="rbInterval" style="margin-right:50px">Interval</label>

                                <input id="rbSpecific" type="radio" name="rbType" value="1" class="form-check-input" />
                                <label for="rbSpecific">Specific Time</label>
                            </div>
                        </div>
                    </div>
                    <div class="row interval form-group">
                        <div class="col">
                            <span class="xx-size">Interval (must be multiple of 5-minute)</span>
                            <span class="xs-size">Interval (must be multiple of 5-min)</span>
                            <input id="txtInterval" type="number" class="form-control" />
                        </div>
                    </div>
                    <div class="row interval form-group">
                        <div class="col">
                            <span>Start Time Of Day</span>
                            <input id="txtStartTime" type="text" placeholder="08:00 AM" class="form-control" style="background-color:#fff" />
                        </div>
                    </div>
                    <div class="row interval form-group">
                        <div class="col">
                            <span>End Time Of Day</span>
                            <input id="txtEndTime" type="text" placeholder="06:00 PM" class="form-control" style="background-color:#fff" />
                        </div>
                    </div>
                    <div class="row specific form-group">
                        <div class="col">
                            <span>Time Of Day</span>
                            <input id="txtTime" type="text" placeholder="08:00 AM" class="form-control" style="background-color:#fff" />
                        </div>
                    </div>
                </div>

                <div class="callout">
                    <h5>Recipients</h5>
                    <div class="row form-group">
                        <div class="col-12">Email Address</div>
                        <div class="col-8">
                            <input id="txtEmail" type="text" class="form-control mr-2" />
                        </div>
                        <div class="col-4">
                            <input id="btnAdd" type="button" value="Add" class="btn btn-secondary btn-block" />
                        </div>
                    </div>
                    <div class="row">
                        <div class="col recipients"></div>
                    </div>
                </div>

                <div class="row form-group">
                    <div class="col text-center">
                        <input id="btnSave" type="button" value="Save" class="btn btn-primary" style="width:76px" />
                        <input id="btnDelete" type="button" value="Delete" class="btn btn-danger" />
                        <input id="btnCancel" type="button" value="Cancel" class="btn btn-secondary" />
                    </div>
                </div>`);
            slider.toggleClass('open');

            slider.find("div.specific").hide();
            $("#rbInterval").off().on("click", function () {
                slider.find("div.interval").show();
                slider.find("div.specific").hide();
            });
            $("#rbSpecific").off().on("click", function () {
                slider.find("div.interval").hide();
                slider.find("div.specific").show();
            });
            $("#btnDelete").off().on("click", function () {
                var req = {};
                req.ChecklistId = checklistId;
                req.IsActive = false;

                Post("../Services/ControlService.asmx/TaskNag_SET", JSON.stringify({ req }), function (msg) {
                    let rsp = msg.d;

                    if (rsp) {
                        slider.toggleClass('open');
                    } else {
                        alert("There was an error processing your request.");
                    }
                });
            });
            $("#btnAdd").off().on("click", function () {
                let div = slider.find("div.recipients");
                let recipient = $("#txtEmail").val().trim();

                if (recipient == "") {
                    alert("Email address cannot be blank.");
                    return;
                }

                div.append(`<div><label>${recipient}</label><i class="fa fa-ban"></i></div>`);
                div.find(".fa-ban").off().on("click", function () {
                    $(this).parent().remove();
                });
                $("#txtEmail").val("").focus();
            });
            $("#btnSave").off().on("click", function () {
                var req = {};
                req.ChecklistId = slider.find("h2").attr("data-checklist-id");
                req.Subject = $("#txtSubject").val();
                req.BodyText = $("#txtBodyText").val();
                req.ScheduleType = $("#rbSpecific").IsChecked();

                if (req.Subject == "") {
                    alert("Subject is required.");
                    return;
                }
                if (req.BodyText == "") {
                    alert("Body text is required.");
                    return;
                }

                if (req.ScheduleType) {
                    req.TimeOfDay = $("#txtTime").val().trim();

                    if (req.TimeOfDay == "") {
                        alert("Time of day is required.");
                        return;
                    }
                } else {
                    req.Interval = $("#txtInterval").val().trim();
                    req.StartTime = $("#txtStartTime").val().trim();
                    req.EndTime = $("#txtEndTime").val().trim();

                    if (req.Interval == "") {
                        alert("Interval is required.");
                        return;
                    }
                    if (req.Interval % 5 != 0) {
                        alert("Interval must be multiple of 5 minutes.");
                        return;
                    }
                    if (req.StartTime == "") {
                        alert("Start time is required.");
                        return;
                    }
                    if (req.EndTime == "") {
                        alert("End time is required.");
                        return;
                    }
                }

                req.Recipients = "";
                slider.find("div.recipients label").each(function () {
                    req.Recipients += $(this).text() + ";";
                });

                if (req.Recipients == "") {
                    alert("At least one recipient is required.");
                    return;
                }

                Post("../Services/ControlService.asmx/TaskNag_SET", JSON.stringify({ req }), function (msg) {
                    let rsp = msg.d;

                    if (rsp) {
                        slider.toggleClass('open');
                    } else {
                        alert("There was an error processing your request.");
                    }
                });
            });
            $("#btnCancel").off().on("click", function () { slider.toggleClass('open'); });
            $("#txtStartTime, #txtEndTime, #txtTime").off().mobiscroll().time({
                theme: getMobileOperatingSystem(),
                display: 'modal'
            });

            Post("../Services/ControlService.asmx/TaskNag_GET", JSON.stringify({ checklistId }), function (msg) {
                let rsp = msg.d;

                if (rsp == null) {
                    $("#btnDelete").hide();
                    return;
                }

                $("#txtSubject").val(rsp.Subject);
                $("#txtBodyText").val(rsp.BodyText);

                if (rsp.ScheduleType) {
                    $("#rbSpecific").prop("checked", true).click();
                    $("#txtTime").val(rsp.TimeOfDay);
                } else {
                    $("#rbInterval").prop("checked", true).click();
                    $("#txtInterval").val(rsp.Interval);
                    $("#txtStartTime").val(rsp.StartTime);
                    $("#txtEndTime").val(rsp.EndTime);
                }

                let vals = rsp.Recipients.split(";");
                let div = slider.find("div.recipients");
                for (let i = 0; i < vals.length; i++) {
                    if (vals[i].trim() != "") {
                        div.append(`<div><label>${vals[i]}</label><i class="fa fa-ban"></i></div>`);
                    }
                }

                div.find(".fa-ban").off().on("click", function () {
                    $(this).parent().remove();
                });
            });
        }

        var listOfTime = `
			<option value=0>12:00 AM</option>
			<option value=0.5>12:30 AM</option>
			<option value=1>1:00 AM</option>
			<option value=1.5>1:30 AM</option>
			<option value=2>2:00 AM</option>
			<option value=2.5>2:30 AM</option>
			<option value=3>3:00 AM</option>
			<option value=3.5>3:30 AM</option>
			<option value=4>4:00 AM</option>
			<option value=4.5>4:30 AM</option>
			<option value=5>5:00 AM</option>
			<option value=5.5>5:30 AM</option>
			<option value=6>6:00 AM</option>
			<option value=6.5>6:30 AM</option>
			<option value=7>7:00 AM</option>
			<option value=7.5>7:30 AM</option>
			<option value=8>8:00 AM</option>
			<option value=8.5>8:30 AM</option>
			<option value=9>9:00 AM</option>
			<option value=9.5>9:30 AM</option>
			<option value=10>10:00 AM</option>
			<option value=10.5>10:30 AM</option>
			<option value=11>11:00 AM</option>
			<option value=11.5>11:30 AM</option>
			<option value=12>12:00 PM</option>
			<option value=12.5>12:30 PM</option>
			<option value=13>1:00 PM</option>
			<option value=13.5>1:30 PM</option>
			<option value=14>2:00 PM</option>
			<option value=14.5>2:30 PM</option>
			<option value=15>3:00 PM</option>
			<option value=15.5>3:30 PM</option>
			<option value=16>4:00 PM</option>
			<option value=16.5>4:30 PM</option>
			<option value=17>5:00 PM</option>
			<option value=17.5>5:30 PM</option>
			<option value=18>6:00 PM</option>
			<option value=18.5>6:30 PM</option>
			<option value=19>7:00 PM</option>
			<option value=19.5>7:30 PM</option>
			<option value=20>8:00 PM</option>
			<option value=20.5>8:30 PM</option>
			<option value=21>9:00 PM</option>
			<option value=21.5>9:30 PM</option>
			<option value=22>10:00 PM</option>
			<option value=22.5>10:30 PM</option>
			<option value=23>11:00 PM</option>
			<option value=23.5>11:30 PM</option>
        `;
    </script>


    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

