var statusSections = (function() {
	var self = {};
	var sectionsPanel = $("#sections-panel");
	var sectionsTable = $("#sections-table");
	var sectionsDeletedTable = $("#deleted-sections-table");
	var modal = null;
	
	$().ready(function () {
		$("button[data-role='add']").click(sectionsPanel, function () { self.createSection(); });
		sectionsTable.on("click", "input[data-role='edit']", function (e) { self.editSection(e); });
		sectionsTable.on("click", "input[data-role='save']", function (e) { self.saveSection(e); });
		sectionsTable.on("click", "input[data-role='delete']", function (e) { self.deleteSection(e); });
		sectionsDeletedTable.on("click", "input[data-role='restore']", function (e) { self.restoreSection(e); });
		$(document).on("dragndropElementDropped", function (e) { self.moveSection(e); });
		modal = window.modalModule;
	});

	// Add Section
	self.createSection = function () {
		var tableRow = addSectionTableRow(0, "New Section");
		addSectionAjax(tableRow);
	};

	self.addSectionTableRow = function (sectionId, name) {
		addSectionTableRow(sectionId, name);
	};

	function addSectionTableRow(sectionId, name) {
		var rowTemplate =
			"<tr data-id='{0}' data-name='{1}'>" +
				"<td data-item='actions'>" +
					"<input type='button' data-role='edit' class='fa btn' value='&#xf044;'> " +
					"<input type='button' data-role='delete' class='fa btn' value='&#xf00d;'> " +
					"<input type='button' data-role='dragndrop-dragpoint' class='fa btn' value='&#xf0b2;'>" +
				"</td>" +
				"<td data-item='name'>{2}</td>" +
			"</tr>";
		var newElem = $(format(rowTemplate, sectionId, name, name));
		sectionsTable.find("tbody").append(newElem);
		sectionsTable.removeClass("hidden");
		return newElem;
	}
	
	function addSectionAjax(section) {
		$.ajax({
			url: "/DataService.asmx/AddSection",
			type: "POST",
			data: JSON.stringify({ reportId: statusReportModule.reportId }),
			contentType: "application/json",
			success: function (response) {
				section.data("id", response.d);
				modal.onHide(function () { location.reload(); });
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	
	// Delete Section
	self.deleteSection = function (e) {
		removeSectionsTableRow($(e.target).closest("tr"));
	};

	function removeSectionsTableRow(section) {
		hideTableIfNoRows(sectionsTable);
		deleteSectionAjax(section.data("id"));
		addDeletedSectionTableRow(section.data("id"), section.data("name"));
		section.remove();
	}
	
	self.addDeletedSectionTableRow = function (section) {
		addDeletedSectionTableRow(section);
	};

	function addDeletedSectionTableRow(sectionId, name) {
		var rowTemplate =
			"<tr data-id='{0}' data-name='{1}'>" +
				"<td data-item='actions'>" +
					"<input type='button' data-role='restore' class='fa btn' value='&#xf112;'>" +
				"</td>" +
				"<td data-item='name' class='strikethrough'>{2}</td>" +
			"</tr>";
		var newElem = $(format(rowTemplate, sectionId, name, name));
		sectionsDeletedTable.find("tbody").append(newElem);
		sectionsDeletedTable.removeClass("hidden");
		return newElem;
	}
	
	function deleteSectionAjax(sectionId) {
		$.ajax({
			url: "/DataService.asmx/DeleteSection",
			type: "POST",
			data: JSON.stringify({ id: sectionId }),
			contentType: "application/json",
			success: function (response) {
				modal.onHide(function () { location.reload(); });
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}

	// Edit Section
	self.editSection = function (e) {
		editSectionTableRow($(e.target).closest("tr"));
	};

	function editSectionTableRow(section) {
		$("td[data-item='actions'] input", section).remove();
		$("td[data-item='actions']", section).append("<input type='button' data-role='save' class='fa btn' value ='&#xf0c7;'>");
		$("td[data-item = 'name']", section).html("<input type='text' value='" + $("td[data-item = 'name']", section).html() + "' />");
	}
	
	// Save Section
	self.saveSection = function (e) {
		saveSectionTableRow($(e.target).closest("tr"));
	};

	function saveSectionTableRow(section) {
		var editButton = "<input type='button' data-role='edit' class='fa btn' value='&#xf044;'> ";
		var deleteButton = "<input type='button' data-role='delete' class='fa btn' value='&#xf00d;'> ";
		var moveButton = "<input type='button' data-role='dragndrop-dragpoint' class='fa btn' value='&#xf0b2;'>";
		$("td[data-item = 'actions']", section).html(editButton + deleteButton + moveButton);
		section.data("name", $("td[data-item = 'name'] input", section).val());
		$("td[data-item = 'name']", section).html(section.data("name"));
		saveSectionAjax(section.data("id"), section.data("name"));
	}
	
	function saveSectionAjax(sectionId, name) {
		$.ajax({
			url: "/DataService.asmx/EditSection",
			type: "POST",
			data: JSON.stringify({
				sectionId: sectionId,
				name: name
			}),
			contentType: "application/json",
			success: function (response) {
				modal.onHide(function () { location.reload(); });
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	
	// Restore Section
	self.restoreSection = function (e) {
		removeDeletedSectionsTableRow($(e.target).closest("tr"));
	};

	function removeDeletedSectionsTableRow(section) {
		hideTableIfNoRows(sectionsDeletedTable);
		restoreSectionAjax(section.data("id"));
		addSectionTableRow(section.data("id"), section.data("name"));
		section.remove();
	}
	
	function restoreSectionAjax(sectionId) {
		$.ajax({
			url: "/DataService.asmx/RestoreSection",
			type: "POST",
			data: JSON.stringify({ id: sectionId }),
			contentType: "application/json",
			success: function (response) {
				modal.onHide(function () { location.reload(); });
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	
	// Move Section
	self.moveSection = function (e) {
	    moveSectionAjax(
			e.originalEvent.detail.draggedRow,
			$(e.originalEvent.detail.dropTargetRow)
		);
	};

	function moveSectionAjax(fromSection, toSection) {
		$.ajax({
			url: "/DataService.asmx/MoveSection",
			type: "POST",
			data: JSON.stringify({
				fromId: fromSection.data("id"),
				toId: toSection.data("id")
			}),
			contentType: "application/json",
			success: function (response) {
				modal.onHide(function () { location.reload(); });
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	
	// Util
	function hideTableIfNoRows(table) {
		var rows = table.find("tbody tr");
		if (rows.length == 0) {
			table.addClass("hidden");
		}
	}
	self.headerDropPause = function (e) {
		e.preventDefault();
	};
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

