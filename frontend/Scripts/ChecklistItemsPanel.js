$(function () {
    $('input[type=file]').bootstrapFileInput();
    $('input[type=file]').on('change.bs.fileinput', function (e) {
        $('#link-url').val( $("input[data-item='url']", checklistItemsBox.container).val());
    });
});

var checklistItemsBox = (function () {
	var self = {};
	function addChecklistItemRow(checklistItem, isFirst, isLast) {
		var table = $("#checklist-items-table");
		var rowTemplate = "<tr data-role='dragndrop-draggable' data-status='" + JSON.stringify(checklistItem) + "'>" +
								"<td data-item='actions'>" +
                                    "<a data-role='edit'><img src='/Images/edit.gif' title='Edit'/></a> " +
                                    "<a data-role='delete'><img src='/Images/delete.gif' title='Remove'/></a> " +
									"{0} " +
									"{1} " +
									"<a data-role='dragndrop-dragpoint' title='Move'><i class='fa fa-arrows'></i></a> " +
								"</td>" +
								"<td data-item='type'>{2}</td>" +
								"<td data-item='text'>{3}</td>" +
								"<td data-item='url'>{4}</td>" +
							"</tr>";
		var moveUp = isFirst ? "<a data-role='move-up' class='hidden'><img src='/Images/collapse.gif'/></a>" : "<a data-role='move-up'><img src='/Images/collapse.gif'/></a>";
		var moveDown = isLast ? "<a data-role='move-down' class='hidden'><img src='/Images/expand.gif'/></a>" : "<a data-role='move-down'><img src='/Images/expand.gif'/></a>";
		var toAdd = format(rowTemplate, moveUp, moveDown, checklistItem.typeString, checklistItem.text, checklistItem.url);
		table.find("tbody").append(toAdd);
		if (table.hasClass("hidden"))
			table.removeClass("hidden");
		return toAdd;
	}
	function addChecklistItemAjax(checklistItem, checklistId, changeId) {
		var data = {};
		data.checklistId = checklistId;
		data.changeId = changeId;
		data.itemTypeId = checklistItem.type;
		data.text = checklistItem.text;
		data.url = checklistItem.url;
		$.ajax({
			url: "../DataService.asmx/AddChecklistItem",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8",
			success: function (response) {
				if (response.d != 0) {
			        checklistItem.id = response.d;
			        addChecklistItemRow(checklistItem);
					resetMoveButtons();
				}
			}
		});
	}
	function moveChecklistItemAjax(fromId, toId, changeId) {
		var data = {
			fromId: fromId,
			toId: toId,
            changeId: changeId
		};
		$.ajax({
			url: "../DataService.asmx/MoveChecklistItem",
			type: "POST",
			data: data,
			success: function() {
				resetMoveButtons();
			}
		});
	}
	function saveChecklistItemAjax(checklistItem, checklistId, changeId) {
		var data = {
			itemId: checklistItem.id,
			checklistId: checklistId,
            changeId: changeId,
			itemTypeId: checklistItem.type,
			text: checklistItem.text.replace("`", "'"),
			url: checklistItem.url.replace("`", "'")
		};
		$.ajax({
			url: "../DataService.asmx/UpdateChecklistItem",
			type: "POST",
			data: data,
			success: function() {
				resetMoveButtons();
			}
		});
	}
	function deleteChecklistItemAjax(checklistItem, checklistId, changeId) {
		var data = {
			checklistId: checklistId,
			itemId: checklistItem.id,
            changeId: changeId
		};
		$.ajax({
			url: "../DataService.asmx/DeleteChecklistItem",
			type: "POST",
			data: data
		});
	}

	function editChecklistItemRow(jqElem) {
		var container = $(self.container);
		var status = $(jqElem).data("status");
		var existingTypeSelect = $("select[data-set='item-types']", container);
		//var typeSelect = existingTypeSelect.clone();//commented by venkat 03/26/2018
		var typeSelect = existingTypeSelect.first().clone();//added by venkat 03/26/2018 to prevent duplicates in cloning
		$("option", typeSelect).attr("selected", false).filter(function () { return $(this).text() == $(jqElem).find("td[data-item='type']").html(); }).prop('selected', true);
		$(jqElem).find("td[data-item='actions'] a").remove();
		$(jqElem).find("td[data-item='actions']").append("<a data-role='save'><img src='/Images/save_sm.gif'/></a>");
		$(jqElem).find("td[data-item='type']").html("");
		$(jqElem).find("td[data-item='type']").append(typeSelect);
		$(jqElem).find("td[data-item='text']").html("<textarea rows='6' cols='60'>" + status.text + "</textarea>");
		$(jqElem).find("td[data-item='url']").html("");
		$(jqElem).find("td[data-item='url']").append("<input type='text' style='width:300px' value='" + status.url + "'>");
	}
	function saveChecklistItemRow(jqElem) {
		var status = $(jqElem).data("status");
		var deleteButton = "<a data-role='delete'><img src='/Images/delete.gif' title='Remove'/></a> ";
		var editButton = "<a data-role='edit'><img src='/Images/edit.gif' title='Edit'/></a> ";
		var moveUpButton = "<a data-role='move-up'><img src='/Images/collapse.gif' title='Move Up'/></a> ";
		var moveDownButton = "<a data-role='move-down'><img src='/Images/expand.gif' title='Move Down'/></a> ";
		var dragButton = "<a data-role='dragndrop-dragpoint' title='Move'><i class='fa fa-arrows'></i></a> ";
		$(jqElem).find("td[data-item='actions']").html(editButton + deleteButton + moveUpButton + moveDownButton + dragButton);
		status.type = $(jqElem).find("td[data-item='type'] select").val();
		status.typeString = $(jqElem).find("td[data-item='type'] select option:selected").text();
		$(jqElem).find("td[data-item='type']").html(status.typeString);
		status.text = $(jqElem).find("td[data-item='text'] textarea").val();
		$(jqElem).find("td[data-item='text']").html(status.text);
		status.url = $(jqElem).find("td[data-item='url'] input").val();
		$(jqElem).find("td[data-item='url']").html(status.url);
		$(jqElem).attr("data-status", JSON.stringify(status));
	}
	function removeChecklistItemRow(jqElem) {
		var table = $("#checklist-items-table");
		$(jqElem).remove();
		var rows = table.find("tbody tr");
		if (rows.length == 0) {
			if (!table.hasClass("hidden"))
				table.addClass("hidden");
		}
	}
	self.container = "#checklist-items-panel";
	self.createChecklistItem = function () {
		var container = $(self.container);
		var checklistItem = {};
		checklistItem.type = $("select[data-set='item-types']", container).val();
		 //checklistItem.typeString = $("select[data-set='item-types'] option:selected", container).text();
		checklistItem.typeString = $("select[data-set='item-types'] option:selected", container).first().text();//added by venkat 03/26/2018
		checklistItem.text = $("textarea[data-item='text']", container).val();
		checklistItem.url =  $('#link-url', container).val();
		//$("select[data-set='item-types']", container).val("");//commented by venkat 03/26/2018
		$("textarea[data-item='text']", container).val("");
		$('#link-url', container).val("");
		$(".file-input-name", container).remove();
		if(!!$(container).closest("[data-checklist-id]").length) {
		    var checklistId = $(container).closest("[data-checklist-id]").data("checklist-id");
		    var changeId = $(container).closest("[data-change-id]").data("change-id");
			addChecklistItemAjax(checklistItem, checklistId, changeId);
		}else {
			addChecklistItemRow(checklistItem);
		}
	};
	self.addChecklistItemRow = function(checklistItem) {
		addChecklistItemRow(checklistItem);
		resetMoveButtons();
	};
	self.deleteChecklistItem = function (e) {
	    if (window.confirm("Are you sure you want to delete this item?")) {
		if (!!$(self.container).closest("[data-checklist-id]").length) {
		    var checklistId = $(self.container).closest("[data-checklist-id]").data("checklist-id");
		    var changeId = $(self.container).closest("[data-change-id]").data("change-id");
			var checklistItem = $(e.target).closest("[data-status]").data("status");
			deleteChecklistItemAjax(checklistItem, checklistId, changeId);
		}
		removeChecklistItemRow($(e.target).closest("tr"));
		resetMoveButtons();
	    }
	};
	self.editChecklistItem = function (e) {
		editChecklistItemRow($(e.target).closest("tr"));
	};
	self.saveChecklistItem = function (e) {
		var checklistItemRow = $(e.target).closest("tr");
		saveChecklistItemRow(checklistItemRow);
		var checklistItem = checklistItemRow.data("status");
		if (!!$(self.container).closest("[data-checklist-id]").length) {
		    var checklistId = $(self.container).closest("[data-checklist-id]").data("checklist-id");
		    var changeId = $(self.container).closest("[data-change-id]").data("change-id");
			saveChecklistItemAjax(checklistItem, checklistId, changeId);
		}
	};
	self.moveChecklistItem = function (dragged, dropTarget) {
		var container = $(self.container);
		var draggedId = $(dragged).data("status").id;
		if ((!(typeof $(dropTarget).data("status") === 'undefined')) && ($(dropTarget).data("status") != null)) {
		    if ($(dropTarget).data("status").hasOwnProperty("id")) {
		        var droppedId = $(dropTarget).data("status").id;
		        var changeId = $(container).closest("[data-change-id]").data("change-id");
		        if (!!$(container).closest("[data-checklist-id]").length)
		            moveChecklistItemAjax(draggedId, droppedId, changeId);
		    }
		}
	};
	self.moveDownChecklistItem = function(e) {
		var row = $(e.currentTarget).closest("tr");
		var targetRow = row.next();
		row.insertAfter(targetRow);
		self.moveChecklistItem(row, targetRow);
	};

	self.moveUpChecklistItem = function(e) {
		var row = $(e.currentTarget).closest("tr");
		var targetRow = row.prev();
		row.insertBefore(targetRow);
		self.moveChecklistItem(row, targetRow);
	};
	
	function resetMoveButtons() {
		var rows = $("#checklist-items-table tbody tr");
		var firstRow = rows.first();
		firstRow.find("td a[data-role='move-up']").addClass("hidden");
		firstRow.find("td a[data-role='move-down']").removeClass("hidden");
		var lastRow = rows.last();
		lastRow.find("td a[data-role='move-up']").removeClass("hidden");
		lastRow.find("td a[data-role='move-down']").addClass("hidden");
		for (var i = 1; i < rows.length - 1; i++) {
			$(rows[i]).find("td a[data-role='move-up']").removeClass("hidden");
			$(rows[i]).find("td a[data-role='move-down']").removeClass("hidden");
		}
	}
	$().ready(function() {
		var container = $(self.container);
		$("button[data-role='add']", container).click(self.createChecklistItem);
		$("#checklist-items-table", container).on('click', "a[data-role='delete']", self.deleteChecklistItem);
		$("#checklist-items-table", container).on('click', "a[data-role='edit']", self.editChecklistItem);
		$("#checklist-items-table", container).on('click', "a[data-role='save']", self.saveChecklistItem);
		$("#checklist-items-table", container).on('click', "a[data-role='move-down']", self.moveDownChecklistItem);
		$("#checklist-items-table", container).on('click', "a[data-role='move-up']", self.moveUpChecklistItem);
		//get items from data status field and prepopulate
		if ($(container).data("status") && $(container).data("status").length > 0) {
			var data = $(container).data("status");
			for (var i = 0; i < data.length; i++) {
				var isFirst = i == 0;
				var isLast = i == data.length - 1;
				addChecklistItemRow(data[i], isFirst, isLast);
			}
		}
		$(document).on("dragndropElementDropped", function (e) {
			//if dragged and dropped elements are both members of this div, handle it
			var draggedElem = e.originalEvent.detail.draggedRow[0];
			var droppedElem = e.originalEvent.detail.dropTargetRow;
			if ($.contains($(self.container)[0], $(draggedElem)[0]) && $.contains($(self.container)[0], $(droppedElem)[0]))
				self.moveChecklistItem(draggedElem, droppedElem);
		});
	});
	return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

