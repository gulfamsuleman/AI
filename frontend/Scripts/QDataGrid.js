const tableData = [
    { year: 2010, count: 10, kpi: 15, avgCompletion: 6},
    { year: 2011, count: 20, kpi: 17, avgCompletion: 7 },
    { year: 2012, count: 15, kpi: 55, avgCompletion: 12 },
    { year: 2013, count: 25, kpi: 61, avgCompletion: 5 },
    { year: 2014, count: 22, kpi: 17, avgCompletion: 12 },
    { year: 2015, count: 30, kpi: 10, avgCompletion: 18 },
    { year: 2016, count: 28, kpi: 15, avgCompletion: 6 },
];

$().ready(function () {

    populateTable();
    function populateTable() {
        event.preventDefault();
        let userDataTable = '';
        userDataTable = `<div">
                             <label for="testDataTable"><b>Test Table</b></label>
                             <table id="testDataTable" class="display compact" style="width:100%"></table><br>
                         </div>`;


        $("#dataTest").html(userDataTable);

        var newTable = new DataTable("#testDataTable", {
            dom: 't',
            paging: false,
            lengthChange: false,
            searching: false,
            autoFill: false,
            columnDefs: [
                { targets: [0, 1, 2, 3], orderable: false },
            ],
            responsive: true,
            data: tableData,
            columns: [
                { title: "Year", data: 'year' },
                { title: "Count", data: 'count' },
                { title: "KPI", data: 'kpi' },
                { title: "Average Completion", data: 'avgCompletion' },

            ]
        });
    }
})
