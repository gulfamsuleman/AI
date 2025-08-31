$().ready(function () {

    populateGroupsModal();

    
})

function AddUserToGroup(e) {
    let userId = $("#userId").val();
    let groupId = e.target.dataset.groupId;
    console.log(groupId);

    $.ajax({
        url: "../DataService.asmx/AddUserToGroup",
        type: "POST",
        data: JSON.stringify({ userId: userId, groupId: groupId }),
        contentType: "application/json",
        success: function (response) {
            alert("User successfully Added to Group!");
            populateGroupsModal();
        },
        error: function (error) {
            console.log(error)
        }
    });
}

function RemoveUserFromGroup(e) {
    let userId = $("#userId").val();
    let groupId = e.target.dataset.groupId;

    $.ajax({
        url: "../DataService.asmx/RemoveUserFromGroupByUserId",
        type: "POST",
        data: JSON.stringify({ userId: userId, groupId: groupId }),
        contentType: "application/json",
        success: function (response) {
            alert("User successfully removed from Group!");
            populateGroupsModal();
        },
        error: function (error) {
            console.log(error)
        }
    });
}

function MakeUserGroupOwner(e) {
    let userId = $("#userId").val();
    let groupId = e.target.dataset.groupId;

    alert("Doesn't exist yet.");
}
function populateGroupsModal() {

    let userId = $("#userId").val();
    let supervisorId = $("#supervisorId").val();
    $.ajax({
        url: "../DataService.asmx/GetAllGroupsIManageForUser",
        type: "POST",
        data: JSON.stringify({ userId: userId, supervisorId: supervisorId }),
        contentType: "application/json",
        success: function (response) {
            var tableData = response.d;
            var test = 0;

            let userDataTable = '';
            userDataTable = `<div style="text-align: center;">
                             <label for="userGroupsDataTable" style="font-size: 15pt"><b>Groups</b></label>
                             <table id="userGroupsDataTable" class="display compact" style="width:100%"></table><br>
                         </div>`;


            $("#modalGroupsTable").html(userDataTable);

            var newTable = new DataTable("#userGroupsDataTable", {
                dom: '<"top"B>ltp',
                pageLength: 8,
                paging: true,
                lengthChange: false,
                searching: false,
                autoFill: false,
                columnDefs: [
                    { targets: [0, 1, 2, 3], orderable: false },
                ],
                responsive: true,
                data: tableData,
                columns: [
                    { title: "Group", data: 'GroupName' },
                    {
                        title: "Is Member?", data: null,
                        render: function (data) {
                            if (data.IsMember)
                                return `<span><i class="gold-star fa fa-star"></i></span>`;
                            else
                                return `--`;
                        }
                    },
                    {
                        title: "Is Owner?", data: null,
                        render: function (data) {
                            if (data.IsOwner)
                                return `<span><i class="gold-star fa fa-star"></i></span>`;
                            else
                                return `--`;
                        }
                    },
                    { title: "Owner", data: 'Owner' },
                    {
                        title: "Actions",
                        data: null,
                        render: function (data) {
                            let returnObject = ""
                            if (!data.IsMember) returnObject = returnObject + `<button data-role="add-user" data-group-id="${data.Id}" class="conversion-btn">Add</button> `;
                            if (data.IsMember) returnObject = returnObject + `<button data-role="remove-user" data-group-id="${data.Id}" class="conversion-btn">Remove</button> `;
                            if (!data.IsOwner) returnObject = returnObject + `<button data-role="make-owner" data-group-id="${data.Id}" class="conversion-btn">Make Owner</button> `;
                            if (returnObject == "") returnObject = "--";
                            return returnObject;
                            
                        }
                    }

                ]
            });

            $("button[data-role='add-user']").on('click', AddUserToGroup);
            $("button[data-role='remove-user']").on('click', RemoveUserFromGroup);
            $("button[data-role='make-owner']").on('click', MakeUserGroupOwner);

            $('#userGroupsDataTable table td').each(function () {
                var fullText = $(this).text();  // Assuming the full text is the cell's text
                $(this).attr('title', fullText);
            });
        },
        error: function (error) {
            alert(`the following error occurred: ${error}`);
        }
    });

}