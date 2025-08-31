var refreshTimestamp = new Date();
var isMyTask = false;
var isCalendar = false;
var timeoutSearchRef = null;
var timeoutSearchPersistRef = null;
var searchInterval = 500;
var searchPersistentInterval = 2 * 1000; // in seconds

function autoSearchText() {
    submitSearch();
}

function autoSearchHistoryText() {
    let searchCriteria = $("#txtSearchInput").val().trim();
    if (searchCriteria == "") return;

    asyncPostEx("SaveSearchHistory", JSON.stringify({ criteria: searchCriteria }), function (msg) { });
    //populateRecentHistory();
}

function searchPage() {
    $("#txtSearchInput").val("");
    $("#dlgSearch").css("display", "flex");
    searchResize();
    $("#txtSearchInput").focus();
}

function closeSearch() {
    $("#txtSearchInput").val("");
    $('#dlgSearch .search-text').val("");
    $("#dlgSearch").hide();

    defaultResize();
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
    $("#searchResults").hide();

    if (isMyTask) {
        $("#divTaskList > div").removeClass("filter-hide");
    }
    else if (isCalendar) {
        $("#calendar .dayofweekDiv a").removeClass("filter-hide");
    } 
    else {
        $("#status-report tr.report-line-content").removeClass("filter-hide");
        $(".status-table").css("display", "").css("max-width", "100%");
        let tbl = $("#tblSearchArchiveResult");
        if (tbl.length > 0) tbl.remove();
    }

    $(".close-search").blur();
    removeHighlighting(document.body);
}

function submitRecent() {
    asyncPostEx("GetSearchHistory", JSON.stringify({ criteria: $("#txtSearchInput").val().trim() }), function (msg) {
        if (msg.d == null || msg.d.length == 0) {
            $("#dlgSearch #recentHistory").hide();
            return;
        }

        let ul = $("#dlgSearch #recentHistory ul");

        if ($(ul).find("li").length > 0) {
            ul.html("");
            for (let i = 0; i < msg.d.length; i++)
                ul.append(`<li>${msg.d[i]}</li>`);

            $("#dlgSearch #recentHistory").css("display", "flex");
            ul.find("li").on("click", function () {
                let criteria = $(this).text();
                $("#txtSearchInput").val(criteria);
                submitSearch();
            });
        } else
            submitSearch();
    });
}
function submitMyTask() {
    let recordCount = 0;
    let searchCriteria = $("#txtSearchInput").val().trim();

    // remove all filtering
    if (searchCriteria == "") {
        refreshSearch();
        return;
    }

    let logicAndOr = $("input[name=logicAndOr]:checked").prop("value");
    if (logicAndOr == "") logicAndOr = null;

    asyncPostEx("SearchMyTask", JSON.stringify({
        criteria: searchCriteria,
        logicAndOr: logicAndOr,
        includeTask: true,
        includeItem: true,
        includeComment: false,
        fromDate: $("#txtSearchFromDate").val().trim(),
        toDate: $("#txtSearchToDate").val().trim()
    }), function (msg) {
        //$("#txtSearchInput").blur();
        $("#searchProgress").hide();
        $("#recentHistory").hide();
        $("#txtSearchInput").blur();
        if (msg.d == null) {
            $("#divTaskList > div").addClass("filter-hide");
            displaySearchResults(recordCount, searchCriteria);
            $("#txtSearchInput").focus();
            return;
        }
        $("#divTaskList > div").each(function () {
            let found = false;
            for (let i = 0; i < msg.d.length; i++) {
                if (msg.d[i] == $(this).data("checklist-id")) {
                    found = true;
                    recordCount = recordCount + 1;
                    break;
                }
            }

            if (found) {
                $(this).removeClass("filter-hide");
                let text = $(this).text();
                $(this).contents().each(function () {
                    highlightSearchResults(this, searchCriteria);
                });
            }
            else
                $(this).addClass("filter-hide");
        });
        displaySearchResults(recordCount, searchCriteria);
        highlightSearchResults($("#divTaskList")[0], searchCriteria);
        $("#txtSearchInput").focus();
    });
}

function submitCalendar() {
    let recordCount = 0;
    let searchCriteria = $("#txtSearchInput").val().trim();

    // remove all filtering
    if (searchCriteria == "") {
        refreshSearch();
        return;
    }

    let logicAndOr = $("input[name=logicAndOr]:checked").prop("value");
    if (logicAndOr == "") logicAndOr = null;

    asyncPostEx("SearchCalendar",
        JSON.stringify({
            criteria: searchCriteria,
            logicAndOr: logicAndOr,
            includeTask: true,
            includeItem: true,
            includeComment: false,
            fromDate: null,//$("#date-selection-calendar > input[data-role=calendar]").val().trim(),
            toDate: null //service method will calculate fromDate + 5
        }),
        function (msg) {
            $("#searchProgress").hide();
            $("#recentHistory").hide();
            $("#txtSearchInput").blur();
            if (msg.d == null) {
                $("#divTaskList > div").addClass("filter-hide");
                displaySearchResults(recordCount, searchCriteria);
                $("#txtSearchInput").focus();
                return;
            }
            $("#calendar .dayofweekDiv > a").each(function () {
                let found = false;
                for (let i = 0; i < msg.d.length; i++) {
                    if (msg.d[i] == $(this).data("id")) {
                        found = true;
                        recordCount = recordCount + 1;
                        break;
                    }
                }

                if (found) {
                    $(this).closest("div.dayofweekDiv").removeClass("filter-hide");
                    let text = $(this).text();
                    //highlightSearchResults(this, searchCriteria);                    
                }
                else
                    $(this).closest("div.dayofweekDiv").addClass("filter-hide");
            });
            displaySearchResults(recordCount, searchCriteria);
            highlightSearchResults($("#calendar .calendarBlock")[0], searchCriteria);
            highlightSearchResults($("#overdue-panel")[0], searchCriteria, false);
            $("#txtSearchInput").focus();
        });
}

function submitMyStatus() {

    let fromDate = $("#txtSearchFromDate").val().trim();
    if (fromDate !== "") fromDate = moment(fromDate);

    let toDate = $("#txtSearchToDate").val().trim();
    if (toDate !== "") toDate = moment(toDate);

    let recordCount = 0;
    let searchCriteria = $("#txtSearchInput").val().trim();

    let logicAndOr = $("input[name=logicAndOr]:checked").prop("value");
    if (logicAndOr == "") logicAndOr = null;

    // remove all filtering
    if (searchCriteria == "") {
        refreshSearch();
        return;
    }

    $("#searchResults").hide();

    asyncPostEx("SearchMyStatus", JSON.stringify({
        criteria: searchCriteria,
        reportId: $("#report-id").val(),
        logicAndOr: logicAndOr,
        includeTask: true,
        includeItem: false,
        includeComment: true,
        includeArchive: $("#chkIncludeArchive").prop("checked"),
        fromDate: $("#txtSearchFromDate").val().trim(),
        toDate: $("#txtSearchToDate").val().trim()
    }), function (msg) {
        if (searchCriteria == $("#txtSearchInput").val().trim()) {
            $("#recentHistory").hide();
            var cancelbutton = $('button[data-role="cancel-comment"]');
            if (cancelbutton.length) {
                cancelbutton.click();
            }

            $("#searchProgress").hide();
            $("#recentHistory").hide();
            $("#txtSearchInput").blur();
            if (msg.d == null) {
                $(".status-table:not(:first-child)").css("display", "none");
                $("#txtSearchInput").focus();
                return;
            }
            recordCount = msg.d.length;
            $("#status-report .status-table:not(:first-child) tr.report-line-content").each(function () {
                let found = false;
                let foundCounter = 0;
                for (let i = 0; i < msg.d.length; i++) {
                    let e = msg.d[i];
                    if (e.Id != undefined && e.Id == $(this).data("id")) {
                        found = true;
                        foundCounter++;
                        break;
                    }
                }
                if (found) {
                    $(this).removeClass("filter-hide");
                    $(this).parent().parent().addClass("filter-show");
                    $(this).parent().find(".report-header-column").removeClass("filter-hide");
                }
                else {
                    $(this).addClass("filter-hide");
                }

            });

            $(".status-table:not(:first-child)").each(function () {
                var showTable = $(this).hasClass("filter-show");
                if (!showTable)
                    $(this).hide();
                else {
                    $(this).css("display", "").css("max-width", "100%");
                    $(this).removeClass("filter-show");
                }

            });

            displaySearchResults(recordCount, searchCriteria);

            // check if archive result needs to be built
            let viewer = $("#status-report-viewer");
            let tbl = $("#tblSearchArchiveResult");
            let count = 0;
            if (tbl.length > 0) tbl.remove();

            tbl = `
        <table class="status-table" id="tblSearchArchiveResult">
            <thead>
            <tr>
                <td colspan="4" class="report-line-subheader noselect">
                <i class="fa fa-minus-square-o"></i>
                <a href="#" data-role="section-head">Archive Search Result</a>
                </td>
            </tr>
            </thead>
            <tbody>
            <tr class="report-line-content multiple-collapse-member report-header-column">
                <th class="report-line-headings report-line-border report-line-headings-task">Task</th>
                <th class="report-line-headings report-line-border report-line-headings-deadline">Due</th>
                <th class="report-line-headings report-line-border report-line-headings-assignees">Assignees/Controllers</th>
                <th class="report-line-headings report-line-border report-line-headings-progress">Progress</th>
            </tr>`;
            for (let i = 0; i < msg.d.length; i++) {
                let e = msg.d[i];
                if (e.Task != undefined) {
                    count += 1;
                    let img = e.Comments == "" ? "" : `<img class="collapse-mode" src="Images/plus.gif" alt="Expand task level comments">`;

                    tbl += `
                <tr class="report-line-content">
                    <td class="report-line-border">${e.Task}</td>
                    <td class="report-line-border">${e.DueTime}</td>
                    <td class="report-line-border report-line-assignees-content">${e.Assignees} / ${e.Controllers}</td>
                    <td class="report-line-border comments">${img}${e.Comments}</td>
                </tr>`;
                }
            }
            if (count > 0) {
                viewer.append(tbl + `
                <tr class="report-line-ender">
                  <td colspan="4"></td>
                </tr>
              </tbody>
            </table>`);
                tbl = $("#tblSearchArchiveResult");
                tbl.find(".comments > div").hide();
                tbl.find(".comments > img").on("click", function () {
                    if ($(this).hasClass("collapse-mode")) {
                        $(this).parent().find("div").show();
                        $(this).attr("src", "Images/minus.gif");
                        $(this).removeClass("collapse-mode").addClass("expand-mode");
                    } else {
                        $(this).parent().find("div").hide();
                        $(this).attr("src", "Images/plus.gif");
                        $(this).removeClass("expand-mode").addClass("collapse-mode");
                    }
                });
            }
            highlightSearchResults($("#status-report-viewer")[0], searchCriteria);
            $("#txtSearchInput").focus();
        }
        
    });
}
function submitSearch() {
    $("#searchProgress").show();
    if ($("#txtSearchInput").val().length > 0 ||
        ($("#txtSearchFromDate").length > 0 || $("#txtSearchFromDate").length > 0)) {

        if (isMyTask) {
            submitMyTask();
            displaySearchResults();
        }
        else if (isCalendar) {
            submitCalendar();
            displaySearchResults();
        } 
        else
            submitMyStatus();
    } else {
        refreshSearch();
        hideResults();
    }


}
function searchResize() {
    if (window.location.href.indexOf("MyStatus") >= 0 || window.location.href.indexOf("MyInbox") >= 0) {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#dlgSearch").outerHeight() - $("#site-footer").outerHeight() - 55) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + $("#dlgSearch").outerHeight()) + 35 + "px");
    }
    else {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#dlgSearch").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + $("#dlgSearch").outerHeight()) + "px");
    }
}
function defaultResize() {
    if (window.location.href.indexOf("MyStatus") >= 0 || window.location.href.indexOf("MyInbox") >= 0) {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 52) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + 35) + "px");
    } else {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }
}

function populateRecentHistory() {
    asyncPostEx("GetSearchHistory", JSON.stringify({ criteria: $("#txtSearchInput").val().trim() }), function (msg) {
        if (msg.d == null || msg.d.length == 0) {
            return;
        }
        else { 
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

function displaySearchResults(recordCount, criteria) {
    if (recordCount === undefined)
        recordCount = 0;

    $("#searchResults").html(`<span><i><b>SEARCH FILTER ACTIVE.</b> Search criteria: <b>${criteria}</b>. Tasks Found: <b>${recordCount}</b> (includes recurring and completed)</i></span>`);
    $("#searchResults").show();   
}

function hideResults() {
    $("#searchResults").hide();
}

function highlightSearchResults(node, searchString, remove) {
    //remove old highlighting by default unless specifically told not to
    remove = remove === false ? false : true;

    if (!node || !searchString) return;

    if(remove) removeHighlighting(document.body);

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

/*
function removeHighlighting(node) {
    const spans = node.querySelectorAll('span.searchhighlight');
    spans.forEach(span => {
        span.outerHTML = span.innerHTML; // Replace the span with its contents
    });
}
*/
/*
function removeHighlighting(node) {
    // Base case: If the node itself is a highlight span, process it
    if (node.nodeType === Node.ELEMENT_NODE && node.classList.contains('searchhighlight')) {
        // Create a temporary container to store the node's children
        const fragment = document.createDocumentFragment();

        // Move all children of the node to the fragment
        while (node.firstChild) {
            fragment.appendChild(node.firstChild);
        }

        // Replace the node with its children
        node.parentNode.replaceChild(fragment, node);

        // Continue processing the children of the fragment
        Array.from(fragment.childNodes).forEach(child => {
            removeHighlighting(child);
        });
    } else {
        
        // Recursive case: Process each child node
        Array.from(node.childNodes).forEach(child => {
            removeHighlighting(child);
        });
    }
}*/