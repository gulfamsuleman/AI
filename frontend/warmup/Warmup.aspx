<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Warmup.aspx.cs" Inherits="SiteWarmup.Warmup" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>ASMX Service Warm-Up</title>
    <%-- Site must have JQuery and a common.js - reference correct path here --%>
    <script src="../Scripts/jquery-1.9.1.min.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-1.9.1.min.js")).Ticks.ToString() %>"></script>
    <script src="../Scripts/common.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("../Scripts/common.js")).Ticks.ToString() %>"></script>
    
    <script src="xml2json.min.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("xml2json.min.js")).Ticks.ToString() %>"></script>
    <script src="wsdl.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("wsdl.js")).Ticks.ToString() %>"></script>

    <script type="text/javascript">
        var serviceClassUris = [<%=ServiceClassUris%>];
        $(document).ready(function () {
            var loadws = (i) => {
                var uri = serviceClassUris[i];

                var ws = new wsdl(uri);
                ws.load().then(
                    function () {
                        const runop = (j) => {
                            var sm = ws.operations[j];

                            asyncPostEx(sm.name, "{}", function (msg) {
                                var tr = $("<tr>");
                                tr.append($("<td>").html(uri));
                                tr.append($("<td>").html(sm.name));
                                tr.append($("<td>").html(new Date().toLocaleString())); //harmless
                                tr.append($("<td>").html("200 - OK"));
                                $("table.mainTable").append(tr);
                            }, function (xhr) {
                                var tr = $("<tr>");
                                tr.append($("<td>").html(uri));
                                tr.append($("<td>").html(sm.name));
                                tr.append($("<td>").html(new Date().toLocaleString())); //harmless
                                tr.append($("<td>").html("" + xhr.status + " - " + xhr.statusText));
                                $("table.mainTable").append(tr);
                            }
                            );
                        };

                        for (let j = 0, p = Promise.resolve(); j < ws.operations.length; j++)
                            p = p.then(runop(j));
                    },
                    function (err) {
                        var tr = $("<tr>");
                        tr.append($("<td>").html(uri));
                        tr.append($("<td>"));
                        tr.append($("<td>").html(new Date().toLocaleString())); //harmless
                        if (err.statusText != undefined)
                            tr.append($("<td>").html("" + err.status + " - " + err.statusText));
                        else
                            tr.append($("<td>").html("" + err.stack.replace(/\n/gi, "<br/>")));
                        $("table.mainTable").append(tr);
                    });
            };

            for (let i = 0, p = Promise.resolve(); i < serviceClassUris.length; i++)
                p = p.then(loadws(i));

        });
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <table class="mainTable">
                <thead>
                    <tr>
                        <th>Service Class</th>
                        <th>Method Name</th>
                        <th>Run Completed</th>
                        <th>Result</th>
                    </tr>
                </thead>
                <tbody>

                </tbody>
            </table>
        </div>
    </form>
</body>
</html>

<!-- Copyright © 2024 Renegade Swish, LLC -->

