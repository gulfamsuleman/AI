const data = [
    { year: 2010, count: 10 },
    { year: 2011, count: 20 },
    { year: 2012, count: 15 },
    { year: 2013, count: 25 },
    { year: 2014, count: 22 },
    { year: 2015, count: 30 },
    { year: 2016, count: 28 },
];

let numberOfGraphs = 0;
let graphType = '';

$().ready(function () {

    numberOfGraphs = $("#numberOfGraphs").val();
    graphType = $("#typeOfGraphs").val();

    let graphIterator = 0;
    while (graphIterator < numberOfGraphs) {

        let newCanvase = `<div class="canvas-container"><canvas id="graph-${graphIterator}"></canvas></div>`;
        $("#graphsBox").append(newCanvase);
        graphIterator++;
    }

    setupCanvases();

});

function setupCanvases() {

    let canvases = $("#graphsBox canvas");

    canvases.each(function (index) {
        new Chart($(this)[0], {
            type: graphType,
            data: {
                labels: data.map(row => row.year),
                datasets: [{
                    label: '# of Votes',
                    data: data.map(row => row.count),
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    });
}