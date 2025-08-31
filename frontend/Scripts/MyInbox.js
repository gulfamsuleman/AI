var myInboxModule = (function () {
    var self = {};
    var toolbar = $("#toolbar");
    var throbber = $("#throbber");
    var mainContent = $("#main-content");
    var viewType = $("#view-type").val();
    var datepicker = $("input[data-role='datepicker']");
    self.preventOpenReport = false;

    $().ready(function () {
        $("a[data-role='excel-export']").click(exportFile);
        $(document).on("click", "i[data-role='fav-icon']", function (e) {
            if (isMobile) self.preventOpenReport = true;
            toggleFavorite(e);
        });
        $(document).on("click", "a[data-sort-by]", function (e) {
            sortInbox(e);
        });
        if (isMobile)
        {
            $(document).on("click", "tr[data-role='report-row'] td",
                function (e) {
                    if (self.preventOpenReport) {
                        self.preventOpenReport = false;
                        return;
                    }
                    openReport(e);
                });

            $("#changeReport .return").hide();
            $("#changeReport .emailComments").hide();
            $("#changeReport .markRead").hide();
        }
        else {
            $(document).on("click", "tr[data-role='report-row'] td:not(:first-child)",
                function (e) {
                    openReport(e);
                });
        }
        setSortArrow();

        resize();
        window.onresize = resize;

        var reportid = $("#ReportId").val();
        if (reportid > 0) {
            openReport(null);
        }

        $(window).on("online", function () { window.open("../SessionCheck.aspx", "_blank", "popup") });
    });

    function resize() {
        $("#site-main").height(($(window).height() - ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight()) - 24) + "px");
        $("nav.report-navbar-default").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight()) + "px");
    }

    function exportFile(e) {
        var options = {
            exportType: $("input[name='export-choice']:checked").val(),
            pageName: 'MyInboxExport.aspx'
        };

        var queryString = serialize(options);
        $('<iframe src=OfficeExportHandler.ashx?' + queryString + '/>').appendTo('body');
    }

    function toggleFavorite(e) {
        var icon = $(e.currentTarget);
        if (icon.hasClass("fa-star-o")) {
            icon.removeClass("fa-star-o");
            icon.addClass("fa-star");
        } else if (icon.hasClass("fa-star")) {
            icon.removeClass("fa-star");
            icon.addClass("fa-star-o");
        }
        var reportId = icon.closest("tr").data("report-id");
        toggleFavoriteAjax(reportId);
    }

    function toggleFavoriteAjax(reportId) {
        $.ajax({
            url: "../DataService.asmx/ToggleFavoriteReport",
            type: "POST",
            data: JSON.stringify({ reportId: reportId }),
            contentType: "application/json; charset=utf-8",
            success: function (data) {

            }
        });
    }

    function sortInbox(e) {
        var header = $(e.currentTarget);
        var sortBy = header.data("sort-by");
        var sortOrder;
        if (header.data("sort-order") == "" || header.data("sort-order") == "DESC")
            sortOrder = "ASC";
        else
            sortOrder = "DESC";
        viewType = $("#view-type").val();
        $.ajax({
            url: "../DataService.asmx/SaveInboxSorting",
            type: "POST",
            data: JSON.stringify({
                sortBy: sortBy,
                sortOrder: sortOrder
            }),
            contentType: "application/json; charset=utf-8",
            success: function (data) {
                self.loadReport(viewType);
            }
        });
    }

    function setSortArrow() {
        $("a[data-sort-order='ASC'] span[data-role='sort-icon']").html("<i class='fa fa-sort-desc'></i>");
        $("a[data-sort-order='DESC'] span[data-role='sort-icon']").html("<i class='fa fa-sort-asc'></i>");
    }

    self.loadReport = function (type) {
        var userName = $("#user-shortname").val();
        var params = {
            ViewType: type,
            UserName: userName,
            IsMobile: typeof slider !== 'undefined'
        };
        mainContent.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/MyInbox/InboxReportsView.ascx"), params, function () {
            setSortArrow();
        });
    };

    function checkReportControllerAsync(reportId) {
        return $.ajax({
            url: "../DataService.asmx/CheckReportController",
            type: "POST",
            data: JSON.stringify({ reportId: reportId }),
            contentType: "application/json; charset=utf-8"
        }).then(function (data) {
            return data.d;
        });
    }

    function checkSuperAsync(reportId) {
        return $.ajax({
            url: "../DataService.asmx/CheckSupervisor",
            type: "POST",
            data: JSON.stringify({ reportId: reportId }),
            contentType: "application/json; charset=utf-8"
        }).then(function (data) {
            return data.d;
        });
    }

    function openReport(e) {
        var reportid;
        if (e != null) {
            reportid = $(e.currentTarget).closest("tr").data("report-id");
        } else {
            reportid = $("#ReportId").val();
        }
        var taskId = $("#TaskId").val();

        var toolbarParams = {
            IsMyInboxStatus: true,
            IsMyInbox: true,
            ReportId: reportid
        };

        throbber.removeClass("hidden");
        toolbar.html("");
        mainContent.html("");
        toolbar.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/ReportToolbar.ascx"), toolbarParams, function () {
            reportToolbarModule.init();
        });

        $.when(
            checkReportControllerAsync(reportid),
            checkSuperAsync(reportid)
        ).done(function (isController, isSuper) {
            if (isController) {
                if (typeof slider !== 'undefined' || isMobile) {
                    window.location.assign("MobileMyStatus.aspx?" + window.location.href.slice(window.location.href.indexOf('?') + 1));
                } else {
                    window.location.assign("MyStatus.aspx?" + window.location.href.slice(window.location.href.indexOf('?') + 1));
                }
                return;
            }

            if (isSuper) {
                var reportParams = {
                    ReportId: reportid,
                    IsInbox: true
                };
                mainContent.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/StatusReport.ascx"), reportParams, function () {
                    throbber.addClass("hidden");
                    datepicker.val($("#last-viewed").val());
                    $("#lnkSearchPage").show();

                    $("table.status-table").each(function () {
                        var tbl = $(this);
                        if (tbl.find("td.completed-task").length > 0) {
                            tbl.find("input[data-role=take-control]").remove();
                        }
                    });

                    if (taskId > 0) {
                        $.find("tr[data-id=" + taskId + "] > td > a[data-action=add-comment]")[0].click();
                        $.find("tr[data-id=" + taskId + "]")[0].scrollIntoView();
                    }

                    syncPost("GetAssigneeVisibility", JSON.stringify({ reportID: reportid }));
                    if (syncPostResult) {
                        if (typeof slider === 'undefined')
                            window.reportToolbarModule.toggleAssignees(this, false);
                    }

                    if (isMobile) {
                        $("#changeReport .return").show();
                        $("#changeReport .emailComments").attr("data-id", reportid);
                        $("#changeReport .emailComments").show();
                        $("#changeReport .markRead").attr("data-id", reportid);
                        $("#changeReport .markRead").show();
                        $("#changeReport .changeReport").hide();
                    }
                });
                return;
            }            

            if (typeof slider !== 'undefined')
                window.location.assign("MobileInbox.aspx");
            else
                window.location.assign("MyInbox.aspx");            
        });
    }

    self.markReportAsRead = function (reportId) {
        $.ajax({
            url: "../DataService.asmx/MarkAsRead",
            type: "POST",
            data: JSON.stringify({ reportId: reportId }),
            contentType: "application/json; charset=utf-8",
            async: false,
            success: function (data) {
                if(!isMobile)
                    notifier.setMessage("Report Marked Read", "green", 2000);
            }
        });
    };

    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

