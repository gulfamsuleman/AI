<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="GlobalSearch.aspx.cs" Inherits="QProcess.GlobalSearch" %>
<%@ Register TagPrefix="modal" TagName="Modal" Src="Controls/Shared/ModalFramework.ascx" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
    <title>Global Task Search</title>
    <link rel="stylesheet" href="Content/bootstrap.min.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/bootstrap.min.css")).Ticks.ToString() %>" />
    <link href="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="Content/<%=Firm %>/ColorScheme.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/{Firm}/ColorScheme.css")).Ticks.ToString() %>" />
    <link href="Content/globalSearch.css" rel="stylesheet" />
    <script src="Scripts/jquery-1.9.1.min.js"></script>
    <script src="Scripts/json2.js"></script>
    <link rel="stylesheet" href="Content/font-awesome.css" />
    <link rel="stylesheet" href="Content/datepicker.css" />
    <script src="Scripts/jquery.lw-datepicker.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.lw-datepicker.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/bootstrap.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/bootstrap.min.js")).Ticks.ToString() %>"></script>
    <script src="https://cdn.datatables.net/v/dt/dt-2.1.8/b-3.1.2/datatables.min.js"></script>
    <script src="Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/common.js")).Ticks.ToString() %>" type="text/javascript"></script>
    <script type="text/javascript">
        var refreshTimestamp = new Date();
        var hdrHeight = 132;
        var timeoutSearchRef = null;
        var timeoutSearchPersistRef = null;
        var searchInterval = 300;
        var searchPersistentInterval = 3 * 1000; // in seconds

        function autoSearchText() {
            submitSearch();
        }

        function autoSearchHistoryText() {
            let searchCriteria = $("#txtSearchInput").val().trim();
            if (searchCriteria == "") return;

            asyncPostEx("SaveSearchHistory", JSON.stringify({ criteria: searchCriteria }), function (msg) { });
            populateRecentHistory();
        }

        function populateRecentHistory() {
            asyncPostEx("GetSearchHistory", JSON.stringify({ criteria: $("#txtSearchInput").val().trim() }), function (msg) {
                if (msg.d !== null || (msg.d != null && msg.d.length > 0)) {
                    let searchHistoryParent = $("#recentHistory");
                    searchHistoryParent.empty();
                    let searchHistory = ``;
                    for (let i = 0; i < msg.d.length; i++) {
                        let e = msg.d[i];
                        searchHistory += `<option value="${e}">`;
                    }
                    searchHistoryParent.append(searchHistory);
                }
            });
        }

        function refreshSearch() {
            recordCount = 0;
            $("#chkIncludeArchive").prop("checked", false);
            $("#txtSearchInput").val("");
            $('#dlgSearch .search-text').val("");
            $("#txtSearchFromDate").val("");
            $("#txtSearchFromDate").data('lw-datepicker').setCurrentDate(new Date());
            $("#txtSearchToDate").val("");
            $("#txtSearchToDate").data('lw-datepicker').setCurrentDate(new Date());
            $("#searchProgress").hide();
            $("#divSearchResult").val("").hide();
            //$(".close-search").blur();
            removeHighlighting(document.body);
        }

        $().ready(function () {
            window.addEventListener('resize', function (event) { resizeSearchContent(); });
            asyncPostEx("IsAdmin", "", function (msg) {
                if (msg.d == true) {
                    $(".admin").show();
                    hdrHeight += 175;
                }
            });

            function filterDate(e) {

                let element = e.target;
                let timePeriod = $(element).data("role");
                let fromDate = $("#txtSearchFromDate");
                let toDate = $("#txtSearchToDate");
                let today = new Date();
                $(toDate).val(new Date(today.setDate(today.getDate() + 1)).toLocaleDateString("en-US"));

                switch (timePeriod.toLowerCase()) {
                    case "today":
                        $(fromDate).val(new Date().toLocaleDateString("en-US"));
                        break;
                    case "week":
                        var week = new Date();
                        week.setDate(week.getDate() - 7);
                        $(fromDate).val(week.toLocaleDateString("en-US"));
                        break;
                    case "month":
                        var month = new Date();
                        month.setDate(month.getDate() - 30);
                        $(fromDate).val(month.toLocaleDateString("en-US"));
                    default:
                        break;
                }

                submitSearch();
            }

            $("#btnToday").on("click", filterDate);
            $("#btnThisWeek").on("click", filterDate);
            $("#btnThisMonth").on("click", filterDate);


            $(window).click(function (event) {
                let div = $("#dlgSearch .bar-wrap");

                if (!div.is(":visible")) return;

                if ($(event.target).closest("#dlgSearch .bar-inactive").length) return;

                if (!$(event.target).closest("#dlgSearch .bar-wrap").length) div.hide();
            });
            $('#dlgSearch .date').lwDatepicker({ onChange: submitSearch });
            //$('#dlgSearch .bar-inactive input').on('click', function () {
            //    $('#dlgSearch .bar-wrap').show();
            //    submitRecent();
            //    $('#dlgSearch .bar input').focus();
            //});

            $("#recentHistory").on("click", function () {
                $("txtSearchInput").css("background-color", "white");
                populateRecentHistory();
            });

            $('#txtSearchInput').on('keyup', function (e) {
                populateRecentHistory();

                switch (e.key) {
                    case 'Escape':
                        e.preventDefault();
                        break;
                    case 'Enter':
                        e.preventDefault();
                        submitSearch();
                        break;
                    case 'ArrowUp':
                        e.preventDefault();
                        if ($("#dlgSearch #recentHistory").is(":visible")) {
                            let li = $("#dlgSearch #recentHistory li");
                            let active = $("#dlgSearch #recentHistory li.active");
                            if (active.length == 0) {
                                li.eq(li.length - 1).addClass("active");
                                $(this).val(li.eq(li.length - 1).text());
                            } else {
                                let idx = active.index() - 1;
                                if (idx < 0) idx = li.length - 1;
                                active.removeClass("active");
                                li.eq(idx).addClass("active");
                                $(this).val(li.eq(idx).text());
                            }
                        }
                        break;
                    case 'ArrowDown':
                        e.preventDefault();
                        if ($("#dlgSearch #recentHistory").is(":visible")) {
                            let li = $("#dlgSearch #recentHistory li");
                            let active = $("#dlgSearch #recentHistory li.active");
                            if (active.length == 0) {
                                li.eq(0).addClass("active");
                                $(this).val(li.eq(0).text());
                            } else {
                                let idx = active.index() + 1;
                                if (idx >= li.length) idx = 0;
                                active.removeClass("active");
                                li.eq(idx).addClass("active");
                                $(this).val(li.eq(idx).text());
                            }
                        }
                        break;
                    default:
                        // support auto search as you type
                        if (timeoutSearchRef != null) { clearTimeout(timeoutSearchRef); }
                        timeoutSearchRef = setTimeout(autoSearchText, searchInterval);

                        // support persisting search history after searchPersistentInterval (5 seconds)
                        if (timeoutSearchPersistRef != null) { clearTimeout(timeoutSearchPersistRef); }
                        timeoutSearchPersistRef = setTimeout(autoSearchHistoryText, searchPersistentInterval);
                        break;
                }
            });
            $("#chkIncludeTask, #chkIncludeItem, #chkIncludeComment, #chkIncludeAll, #chkIncludeArchive").on("click", function () { submitSearch(); });

            $("#divComment h2 > span").click(function () {
                $("#divComment").hide();
                hideOverlay();
                $("body").css("overflow-y", "auto");
            });
            $("#help").click(function () {
                var ele = $("div.help");
                if (ele.is(":visible"))
                    ele.hide();
                else
                    ele.show();
            });
            $("#ddlUsers").dblclick(addUser);
            $("#ddlUserSelected").dblclick(removeUser);
            $("#btnAdd").click(addUser);
            $("#btnRemove").click(removeUser);
            $("#btnGo").click(submitSearch);

            loadUsers();
        });

        function loadUsers() {
            asyncPostEx("GetAllUsers", "", function (msg) {
                var ddl = $("#ddlUsers");
                ddl.html("");
                $("#ddlUserSelected").html("");

                if (msg.d == null) return;
                for (var i = 0; i < msg.d.length; i++) {
                    ddl.append("<option value='" + msg.d[i].Key + "'>" + msg.d[i].Value + "</option>");
                }
            });
        }

        function addUser() {
            var ddl = $("#ddlUsers");
            if (ddl[0].selectedIndex < 0) {
                alert("Select a user to add.");
                return;
            }

            $('#ddlUsers option:selected').remove().appendTo('#ddlUserSelected');

            var my_options = $("#ddlUserSelected option");
            var selected = $("#ddlUserSelected").val();
            my_options.sort(function (a, b) {
                if (a.text > b.text) return 1;
                if (a.text < b.text) return -1;
                return 0
            })

            $("#ddlUserSelected").empty().append(my_options);
            $("#ddlUserSelected").val(selected);
        }

        function removeUser() {
            var ddl = $("#ddlUserSelected");
            if (ddl[0].selectedIndex < 0) {
                alert("Select a user to remove.");
                return;
            }

            $('#ddlUserSelected option:selected').remove().appendTo('#ddlUsers');

            var my_options = $("#ddlUsers option");
            var selected = $("#ddlUsers").val();
            my_options.sort(function (a, b) {
                if (a.text > b.text) return 1;
                if (a.text < b.text) return -1;
                return 0
            })

            $("#ddlUsers").empty().append(my_options);
            $("#ddlUsers").val(selected);
        }

        function showall(ctl, searchCriteria) {
            $("#divComment").show().center();
            showOverlay();
            $("#divComment label").text("All Comments");
            $("#divComment div.body").html("Loading comments...please wait");
            asyncPostEx("GetAllCommentsByChecklist", JSON.stringify({
                checklistId: $(ctl).closest("tr").attr("v"),
                criteria: $("#txtSearchInput").val().trim()
            }), function (msg) {
                var div = $("#divComment div.body");
                div.html("");
                if (msg.d == null) return;

                for (var i = 0; i < msg.d.length; i++) {
                    div.append("<div class='level" + msg.d[i].Key + "'>" + msg.d[i].Value + "</div>");
                }

                $("body").css("overflow-y", "hidden");
                highlightSearchResults($("#divComment div.body")[0], searchCriteria);
            });
        }

        function showitem(ctl, searchCriteria) {
            $("#divComment").show().center();
            showOverlay();
            $("#divComment label").text("Task Items");
            $("#divComment div.body").html("Loading item list...please wait");
            asyncPostEx("GetChecklistItems", JSON.stringify({
                checklistId: $(ctl).closest("tr").attr("v"),
                criteria: $("#txtSearchInput").val().trim()
            }), function (msg) {
                var div = $("#divComment div.body");
                div.html("<ul></ul>");
                div = $("#divComment div.body ul");
                if (msg.d == null) return;

                for (var i = 0; i < msg.d.length; i++) {
                    div.append("<li>" + msg.d[i].Value + "</li>");
                }

                $("body").css("overflow-y", "hidden");

                highlightSearchResults($("#divComment div.body")[0], searchCriteria);
            });

        }
        function isMobile() {
            return <%=(Request.QueryString["mobile"]=="true" ? "true" : "false")%>;
        }
        function submitSearch() {
            $("#searchProgress").show();
            $("#divSearchResult").html("").hide();
            $("div.msg").hide();

            refreshTimestamp = new Date(); //harmless; just a nonce

            var users = "";
            var opts = $("#ddlUserSelected option");
            if (opts.length > 0) {
                opts.each(function () { users += $(this).val() + ","; });
                users = users.substring(0, users.length - 1);
            }

            let searchCriteria = $("#txtSearchInput").val().trim();

            // remove all filtering
            if (searchCriteria == "") {
                $("#searchProgress").hide();
                return;
            }

            var logicAndOr = $("input[name=logicAndOr]:checked").prop("value");
            if (logicAndOr == "") logicAndOr = null;

            asyncPostEx("GlobalSearch", JSON.stringify({
                userId: users,
                criteria: searchCriteria,
                logicAndOr: logicAndOr,
                reportId: $("#ddlStatusReport").val(),
                includeTask: $("#chkIncludeTask").prop("checked"),
                includeItem: $("#chkIncludeItem").prop("checked"),
                includeComment: $("#chkIncludeComment").prop("checked"),
                includeArchive: $("#chkIncludeArchive").prop("checked"),
                fromDate: $("#txtSearchFromDate").val().trim(),
                toDate: $("#txtSearchToDate").val().trim(),
                timestamp: refreshTimestamp.getTime()
            }), function (msg) {
                if (msg.d.Data == null) {
                    $("#searchProgress").hide();
                    $("#divSearchResult").html("No results found");
                    return;
                }

                // prevent race condition
                if (refreshTimestamp.getTime() != msg.d.Timestamp) return;
                if (msg.d.Data.length == 0) return;
                if (msg.d.Truncated) {
                    $("div.msg").show();
                }
                resizeSearchContent();

                var tbl = "<table border='1' style='margin:0;'><tr>" +
                    "<th>Task Name</th>" +
                    "<th>Controllers</th>" +
                    "<th>Assignees</th>" +
                    "<th>Items</th>" +
                    "<th>Is Active?</th>" +
                    "<th nowrap>Last Completed</th>" +
                    "<th>Schedule</th>" +
                    "<th>Status Reports</th>" +
                    "<th>Comments</th></tr>";
                for (var i = 0; i < msg.d.Data.length; i++) {
                    var d = msg.d.Data[i];

                    tbl += "<tr v='" + d.ChecklistId + "'>";
                    tbl += "<td>" +
                        " <a class='btn btn-xs btn-default' title='History' data-action='view-history-global' data-checklist-id='" + d.ChecklistId + "' style='cursor: pointer; margin-right: 6px; color: deepskyblue !important;'>" +
                        "<i class='fa fa-history'></i>   " +
                        "</a>" +
                        (d.IsArchived || d.IsDeleted ? d.Name :
                            "<a href='/ManageTasks.aspx?checklistId=" + d.ChecklistId + "' target='_blank'>" + d.Name + "</a>") +
                        "</td>";
                    tbl += " <td>" + d.Controllers + "</td>";
                    tbl += " <td>" + d.Assignees + "</td>";
                    tbl += " <td>" + d.ItemText + (d.ItemText == "" ? "" : `<a href='javascript:void(0)' onclick='showitem(this, "${searchCriteria}")'>...</a>`) + "</td>";
                    tbl += " <td>" + (d.IsDeleted == false && d.IsArchived == false ? "Yes" : "No") + "</td>";
                    tbl += " <td nowrap>" + d.Completed + "</td>";
                    tbl += " <td>" + d.Schedule + "</td>";
                    tbl += " <td>" + d.StatusReport + "</td>";
                    tbl += " <td>" + d.Comment + (d.Comment == "" ? "" : `<a href='javascript:void(0)' onclick='showall(this, "${searchCriteria}")'>...</a>`) + "</td>";
                    tbl += "</tr>";
                }
                $("#searchProgress").hide();
                $("#divSearchResult").html(tbl + "</table>").show();

                highlightSearchResults($("table")[0], searchCriteria);
            });
        }

        $(document).ready(function () {
            $("body").on("click", "a[data-action='view-history-global']", function (e) {
                var checklistId = $(e.currentTarget).data("checklist-id");
                openHistory(checklistId);
            });
        });

        function submitRecent() {
            asyncPostEx("GetSearchHistory", JSON.stringify({ criteria: $("#txtSearchInput").val().trim() }), function (msg) {
                if (msg.d == null || msg.d.length == 0) {
                    $("#dlgSearch .recent-list").hide();
                    return;
                }

                let ul = $("#dlgSearch .recent-list ul");
                ul.html("");

                for (let i = 0; i < msg.d.length; i++)
                    ul.append(`<li>${msg.d[i]}</li>`);

                $("#dlgSearch .recent-list").css("display", "flex");
                ul.find("li").on("click", function () {
                    let criteria = $(this).text();
                    $("#dlgSearch .search-text-inactive, #txtSearchInput").val(criteria);
                    submitSearch();
                });
            });
        }
        function resizeSearchContent() {
            var height = 0;

            if (typeof window.innerWidth != 'undefined')
                height = window.innerHeight;
            else
                height = document.getElementsByTagName('body')[0].clientHeight;

            if ($("div.msg").is(":visible")) height -= 45;

            $("#divSearchResult").css("height", (height - hdrHeight) + "px");
        }

        function highlightSearchResults(node, searchString) {
            if (!node || !searchString) return;

            removeHighlighting(node);

            // Split the search string into keywords
            const keywords = searchString.replace(/["()]| and | or | not /gi, " ").split(' ').filter(Boolean);

            // Use regex to find and wrap keywords
            keywords.forEach(keyword => {
                const regex = new RegExp(`(${keyword})`, 'gi');
                wrapMatches(node, regex);
            });
        }

        function wrapMatches(node, regex) {
            if (isTreeNode(node)) {
                const walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT, null, false);
                let textNode;
                const matchingNodes = [];

                while (textNode = walker.nextNode()) {
                    if (!(textNode.parentNode.classList.contains("searchhighlight"))) {
                        if (regex.test(textNode.nodeValue)) {
                            matchingNodes.push(textNode);
                        }
                    }
                }

                matchingNodes.forEach(matchingNode => {
                    const fragment = document.createDocumentFragment();
                    const span = document.createElement('span');
                    span.innerHTML = matchingNode.nodeValue.replace(regex, '<span class="searchhighlight">$1</span>');
                    while (span.firstChild) {
                        fragment.appendChild(span.firstChild);
                    }

                    if (!(matchingNode.parentNode.hasAttribute('data-original-html'))) {
                        matchingNode.parentNode.setAttribute('data-original-html', matchingNode.nodeValue);
                    }
                    matchingNode.parentNode.replaceChild(fragment, matchingNode);
                });
            }
        }

        function checkNodeForClass(node, className) {
            // Ensure the node is defined and is an element node
            if (node && node.nodeType === Node.ELEMENT_NODE) {
                // Check if the element has the specified class
                return node.classList.contains(className);
            }
            return false; // Return false if the node is not an element or is undefined
        }

        function isTreeNode(variable) {
            return variable instanceof Node;
        }


        function removeHighlighting(node) {
            // Base case: If the node is an element and has the original HTML attribute, reset it
            if (node.nodeType === Node.ELEMENT_NODE && node.hasAttribute('data-original-html')) {
                node.innerHTML = node.getAttribute('data-original-html');
            }

            // Recursively reset each child node
            Array.from(node.childNodes).forEach(child => {
                removeHighlighting(child);
            });
        }
    </script>
    <style type="text/css">
        .matched-result {
            background-color: red;
            color: white;
        }

        #searchProgress {
            display: none;
        }

            #searchProgress img {
                vertical-align: middle;
            }

        #dlgSearch {
            display: flex;
            position: fixed;
            z-index: 1;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: rgba(0, 0, 0, 0.4);
            font-family: Verdana, Geneva, Tahoma, sans-serif;
        }

            #dlgSearch input, #dlgSearch select, #dlgSearch ul {
                font-size: 16px;
            }

            #dlgSearch .modal-content {
                width: 100%;
                border-radius: 0;
                background-color: #fff;
            }

                #dlgSearch .modal-content > .modal-body {
                    padding: 10px;
                }

            #dlgSearch .bar-wrap {
                z-index: 1;
                position: fixed;
                top: 10px;
                left: 0;
                padding: 0;
                width: 100%;
                display: none;
            }

            #dlgSearch .bar {
                padding: 15px;
                background: #fff;
                border-radius: 25px;
                margin-left: 10px;
                margin-right: 10px;
                box-shadow: 0 9px 8px -3px rgba(64, 60, 67, .24), 8px 0 8px -7px rgba(64, 60, 67, .24), -8px 0 8px -7px rgba(64, 60, 67, .24);
            }

            #dlgSearch .bar-inactive {
                padding: 15px;
                background: #FFFFFF;
                border-radius: 25px;
            }

            #dlgSearch ul {
                display: flex;
                flex-direction: column;
                min-width: 0;
                padding: 0;
                margin: 0;
                list-style: none;
            }

            #dlgSearch li {
                display: flex;
                flex-direction: column;
                min-width: 0;
                overflow: hidden;
                max-height: none;
                padding: 5px 10px;
                cursor: pointer;
                border-radius: 4px;
            }

                #dlgSearch li.active {
                    background-color: #eee;
                }

        #txtSearchInput {
            background-color: white !important;
            outline: none !important;
        }

            #txtSearchInput:focus {
                background-color: white !important;
                outline: none !important;
                height: 50px;
                box-shadow: 5px 5px 5px grey;
            }

            #txtSearchInput:active {
                background-color: white !important;
                outline: none !important;
                height: 50px;
                box-shadow: 5px 5px 5px grey;
            }

        #dlgSearch input:focus {
            outline: none;
        }

        /* Hide the default checkbox */
        #dlgSearch input[type="checkbox"] {
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            width: 16px;
            height: 16px;
            border: 2px solid #ccc;
            border-radius: 4px;
            cursor: pointer;
            position: relative;
        }

            /* Add a checkmark when checked */
            #dlgSearch input[type="checkbox"]:checked::after {
                content: "✔";
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -55%);
                font-size: 14px;
                color: white;
            }

        /* Hide the default radio button */
        #dlgSearch input[type="radio"] {
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            width: 16px;
            height: 16px;
            border: 2px solid #ccc;
            border-radius: 8px;
            cursor: pointer;
            position: relative;
        }

            /* Add a bullet when checked */
            #dlgSearch input[type="radio"]:checked::after {
                content: "•";
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -55%);
                font-size: 14px;
                color: white;
            }

        #dlgSearch .search-bar {
            display: flex;
        }

        #dlgSearch .recent-list {
            display: flex;
            border-top: 1px solid #ccc;
            padding-top: 10px;
            margin-top: 10px;
            display: none;
        }

        #dlgSearch .modal-head {
            padding: 10px;
            background: #EBEBEB;
            box-shadow: 0 1px 6px 0 rgba(32, 33, 36, 0.28);
        }

        #dlgSearch .search-criteria {
            display: inline-flex;
            justify-items: start;
            margin-top: 10px;
            align-items: center;
            flex-direction: row;
            justify-content: center;
            flex-wrap: wrap;
        }

            #dlgSearch .search-criteria input[type=checkbox] {
                margin-left: 10px;
                vertical-align: middle;
                margin-top: 0px;
            }

        #dlgSearch .inline {
            display: inline-block;
        }

        #dlgSearch .date {
            width: 110px;
            border: 0;
            border-bottom: 1px solid #ccc;
        }

        #dlgSearch table, #dlgSearch th, #dlgSearch td {
            border: 1px solid #c3bfb4;
        }

        #dlgSearch table {
            border-collapse: collapse;
            overflow-y: auto;
        }

        #dlgSearch th, #dlgSearch td {
            padding: 5px;
        }

        #dlgSearch th {
            background-color: #ece9d8;
            position: sticky;
            top: 0;
        }

            #dlgSearch th::before {
                position: absolute;
                content: '';
                top: -1px;
                left: -2px;
                width: calc( 100% + 2px);
                height: 1px;
                background-color: #c3bfb4;
            }

            #dlgSearch th::after {
                position: absolute;
                content: '';
                bottom: -1px;
                left: -2px;
                width: calc( 100% + 2px);
                height: 1px;
                background-color: #c3bfb4;
            }

        #dlgSearch td {
            background-color: #ffffed;
        }

        #dlgSearch b, #divSearchComment b {
            color: Red;
        }

        #dlgSearch a {
            color: blue;
            text-decoration: underline;
        }

        #dlgSearch div.inline label {
            display: inline-block;
        }

        .admin {
            display: none;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid #c3bfb4;
        }

        #txtSearchInput {
            background-color: white !important;
            outline: none !important;
        }

            #txtSearchInput:focus {
                background-color: white !important;
                outline: none !important;
                height: 50px;
                box-shadow: 5px 5px 5px grey;
            }

            #txtSearchInput:active {
                background-color: white !important;
                outline: none !important;
                height: 50px;
                box-shadow: 5px 5px 5px grey;
            }

        #dlgSearch input:focus {
            outline: none;
        }
    </style>
</head>
<body>
    <div id="overlay"></div>
    <form id="Form1" method="post" runat="server" onsubmit="return false"></form>
    <div id="dlgSearch">
        <div class="modal-content">
            <div class="modal-head">
                <div style="display: flex;">
                    <input id="txtSearchInput"
                        autocomplete="off"
                        list="recentHistory"
                        placeholder="Start typing to search..."
                        class="search-text-inactive"
                        style="border: 0; flex: 1 1 100%; border-radius: 50px; height: 40px; padding: 0 10px" />
                    <datalist id="recentHistory">
                    </datalist>
                </div>
                <div class="search-criteria">
                    <div id="leftActions" class="inline">
                        Search in: 
                        <input checked="checked" type="checkbox" id="chkIncludeTask" />
                        <label for="chkIncludeTask">Task Name</label>
                        <input checked="checked" type="checkbox" id="chkIncludeItem" />
                        <label for="chkIncludeItem">Item Text</label>
                        <input checked="checked" type="checkbox" id="chkIncludeComment" />
                        <label for="chkIncludeComment">Comments</label>
                    </div>

                    <div id="centerActions" class="inline" style="margin-left: 25px; margin-top: 0">
                        From:
                        <input type="text" class="date" id="txtSearchFromDate" />
                        to
                        <input type="text" class="date" id="txtSearchToDate" />
                        Or:
                        <button data-role="today" class="btn env-specific-btn" style="margin-left: 10px;" id="btnToday">Today</button>
                        <button data-role="week" class="btn env-specific-btn" id="btnThisWeek">Week</button>
                        <button data-role="month" class="btn env-specific-btn" id="btnThisMonth">Month</button>
                    </div>

                    <div id="rightActions" class="inline" style="margin-left: 25px;">
                        <input name="logicAndOr" checked="checked" type="radio" id="chkIncludeAll" value="true" />
                        <label for="chkIncludeAll">Must match all words</label>
                        <input name="logicAndOr" type="radio" id="chkIncludeAny" value="false" />
                        <label for="chkIncludeAny">Can match any word</label>
                        <input name="logicAndOr" type="radio" id="chkAdvanced" value="" />
                        <label for="chkAdvanced">Advanced matching</label>
                        
                        <input type="checkbox" id="chkIncludeArchive" />
                        <label for="chkIncludeArchive">Include archive</label>
                        <button onclick="refreshSearch();"
                            class="btn env-specific-btn close-search"
                            style="cursor: pointer; margin-left: 10px;">
                            Reset</button>
                    </div>

                    <div class="admin">
                        <div class="inline">
                            <label style="display: block">Available Users</label>
                            <select id="ddlUsers" size="6" multiple="multiple"></select>
                        </div>
                        <div class="inline middle">
                            <input id="btnAdd" type="button" value=">>" /><br />
                            <input id="btnRemove" type="button" value="<<" />
                        </div>
                        <div class="inline">
                            <label style="display: block">Selected Users</label>
                            <select id="ddlUserSelected" size="6" multiple="multiple"></select>
                        </div>
                        <div class="inline" style="margin-left: 10px;">
                            <label style="display: block">Status Report</label>
                            <select id="ddlStatusReport" style="width: 610px;"><%=options%></select>
                        </div>
                    </div>
                </div>
                <%--<div class="bar-wrap">
                    <div class="bar">
                        <div class="search-bar">
                            <input class="search-text" style="border:0;flex: 1 1 100%;padding:0 10px;" />
                        </div>
                        <div class="recent-list">
                            <ul></ul>
                        </div>
                    </div>
                </div>--%>
            </div>
            <div class="modal-body">
                <div id="searchProgress">
                    <img src="images/searching.gif" />
                    Searching...please wait
                </div>
                <div class="msg" style="padding-left: 0;">Your search returned a large number of results. Only the first 200 records are shown.</div>
                <div id="divSearchResult" style="display: none; border: 1px solid #ece9d8; position: relative; overflow-y: auto; margin-top: 4px;"></div>
            </div>
        </div>
    </div>

    <div id="divComment">
        <h2>
            <label>All Comments</label>
            <span class="close">X</span></h2>
        <div class="body">
        </div>
    </div>
	<modal:Modal runat="server" ID="ModalFramework" />
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

