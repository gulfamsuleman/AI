$().ready(function () {
	var dragTable = null;
	var dragRow = null;
	var hoverRow = null;
	var isDragging = false;
	var dragOffset = null;
	var scrollContainer = null;
	$(document.body).append("<div id='dragndrop-ghost'></div>");
	var ghost = $("#dragndrop-ghost").css("display", "hidden").css("position", "absolute");
	$(document).on('mousedown', "[data-role='dragndrop-dragpoint']", function (e) {
		if (e.button != 0)
			return;
		dragRow = $(e.target).closest("tr");
		dragTable = dragRow.closest("table[data-role='dragndrop-reorderable']");
		if (!dragRow || !dragTable)
			return;
		isDragging = true;
		document.dispatchEvent(new CustomEvent("dnd_DragStart", { detail: { draggedRow: dragRow, dragTable: dragTable } }));
		e.preventDefault();
		var rowOffset = $(dragRow).offset();
		dragOffset = [e.pageX - rowOffset.left, e.pageY - rowOffset.top];

		scrollContainer = $("#site-main");

	});
	$(document).mousemove(function (e) {
		if (isDragging) {
			if ($(ghost).not("visible")) {
				//make ghost visible only when the mouse is moved after mousedown
				$(ghost).empty()
					.append($(dragRow).clone())
					.show();
			}
			//$(ghost).offset({ top: e.pageY - dragOffset[1], left: e.pageX - dragOffset[0] });
			$(ghost).offset({ top: e.pageY, left: e.pageX });

			//set hover classes appropriately
			$(ghost).hide();
			var underElement = document.elementFromPoint(e.clientX, e.clientY);
			$(ghost).show();

			$(dragTable).find("tr").removeClass("dragndrop-hover");
			hoverRow = null;

			$(dragTable).find(underElement).closest("tr").each(function () {
				$(this).addClass("dragndrop-hover");
				$(".delete-row.dragndrop-hover td.recycle-small").css("background", "transparent url('/Images/recycle_full_sm.jpg') left center no-repeat;");
				$("td.recycle-small").not(".dragndrop-hover td").css("background", "transparent url('/Images/recycle_sm.jpg') left center no-repeat;");

				$(".delete-row.dragndrop-hover td.recycle-large").css("background", "transparent url('/Images/recycle_full.jpg') left center no-repeat;");
				$("td.recycle-large").not(".dragndrop-hover td").css("background", "transparent url('/Images/recycle.jpg') left center no-repeat;");

				hoverRow = this;
			});

			scrollIntoView(hoverRow, scrollContainer, e.clientY);
		}
	}).mouseup(function (e) {
		if (isDragging && e.button == 0) {
			if (hoverRow) {
				var elementDropped = new CustomEvent("dragndropElementDropped", { detail: { draggedRow: dragRow, dropTargetRow: hoverRow, dragTable: dragTable, dropId: $(e.target).attr("id") } });
				document.dispatchEvent(elementDropped);
				$(hoverRow).removeClass("dragndrop-hover");
				$(hoverRow).css("background-color", "");
				if ($(dragRow).prevAll().filter(hoverRow).length !== 0) {
					$(hoverRow).before($(dragRow));
				}
				else if ($(dragRow).nextAll().filter(hoverRow).length !== 0) {
					$(hoverRow).after($(dragRow));
				}
			}
			else {
				var elementDropped = new CustomEvent("dragndropElementCancel", { detail: { draggedRow: dragRow, dropTargetRow: hoverRow, dragTable: dragTable, dropId: $(e.target).attr("id") } });
				document.dispatchEvent(elementDropped);
			}
			$(ghost).hide();
			isDragging = false;
			dragRow = null;
			dragTable = null;
			hoverRow = null;
			dragOffset = null;
		}
	});
});

// Element is the row you are hovering over.  Container is #site-main, the div under the tabs.  ClientY is the mouse position relative to the window
function scrollIntoView(element, container, clientY) {
	var containerTop = $(container).scrollTop();
	var containerBottom = containerTop + $(container).height();
	if (element) { // If we're actually hovering over a row, scroll that row into view.  Element offset is relative to its parent priority list.  Need to also include that list's offset.
		var elemTop = element.offsetTop + $(element).closest("[data-table=user-table]").offsetTop;
		var elemBottom = elemTop + $(element).height();
		if (elemTop < containerTop) {
			$(container).scrollTop(elemTop);
		} else if (elemBottom > containerBottom) {
			$(container).scrollTop(elemBottom - $(container).height());
		}
	}
	else { // If we're not hovering over a row, do the best we can.  This happens if you go outside a priority list table.
		if (clientY > 200) {
			$(container).scrollTop(containerTop + 20);
		} else {
			if (containerTop != 0) {
				if (containerTop - 20 > 0) {
					$(container).scrollTop(containerTop - 20);
				} else {
					$(container).scrollTop(0);
				}
			}
		}
	}
}