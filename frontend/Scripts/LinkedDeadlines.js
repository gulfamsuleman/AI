var linkedDeadlinesModule = (function () {
	var self = {};
	var sourceList = $("#member-select");
	var linkedList = $("#link-select");
	var offset = $("#offset");
	var addButton = $("input[data-action='add-assignment']");


	$().ready(function () {
		addButton.click(addLink);
		popuplateLinksTable();
		resize();
		window.onresize = resize;
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}


	function addLink() {
		if (!(Number.isInteger(offset.val()))) {
			$.ajax({
				url: "/DataService.asmx/AddLinkedDeadline",
				type: "POST",
				data: JSON.stringify({
					sourceActiveChecklist: sourceList.find("option:selected").val(),
					linkedActiveChecklist: linkedList.find("option:selected").val(),
					daysoffset: parseInt(offset.val())
				}),
				contentType: "application/json",
				success: function (data) {
					if (data.d) {
						alert("link added successfully!");
						popuplateLinksTable();
					}
					else {
						alert("Unable to link these tasks, make sure a link does not already exist and that this link does not cause a circular reference.");
					}
				}
			});
		}
	}

	function popuplateLinksTable() {
		$.ajax({
			url: "/DataService.asmx/GetLinkedDeadlines",
			type: "POST",
			data: "",
			contentType: "application/json",
			success: function (data) {
				var table = $("#linked-deadlines-table tbody");
                table.empty();
				data.d.forEach(function (link) {
					var btn = "<input type='button' value='Del Link' class='btn btn-sm btn-default dellink' data-v='" + link.Id +"'/>";
					var row = $("<tr></tr>");
					row.append("<td>" + btn + "</td>");
					row.append($("<td></td>").text(link.SourceTaskName));
					row.append($("<td></td>").text(link.LinkedTaskName));
                    row.append($("<td></td>").text(link.DaysOffset));
                    table.append(row);
				});
				$(".dellink").click(
					function () {
						var id = $(this).data("v");
						delLink(id);
					}
				);
			}
		});
	}

	function delLink(i) {
		if (confirm("Are you sure you want to delete this link?")) {
            deleteProceed(i);
        }
	}

	function deleteProceed(i) {
		$.ajax({
			url: "/DataService.asmx/DeleteLinkedDeadline",
			type: "POST",
			data: JSON.stringify({
				ID: i
			}),
			contentType: "application/json",
			success: function (data) {
				popuplateLinksTable();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

