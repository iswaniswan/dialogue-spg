// Setup module
// ------------------------------

// custom upload function
function dataTableUpload(link, column, linkdata, color, params) {
    var t = $("#serverside").DataTable({
        buttons: [{
            text: '<i class="icon-database-upload"></i>&nbsp; ' + labelupload,
            className: "btn btn-outline bg-" +
                color +
                " text-" +
                color +
                " border-" +
                color +
                "",
            action: function(e, dt, node, config) {
                window.location.href = base_url + linkdata + '/upload';
            },
        }, {
            text: '<i class="icon-database-add"></i>&nbsp; ' + labeladd,
            className: "btn btn-outline bg-" +
                color +
                " text-" +
                color +
                " border-" +
                color +
                "",
            action: function(e, dt, node, config) {
                window.location.href = base_url + linkdata + '/add';
            },
        }, ],
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            type: "post",
            data: params,
            error: function(data, err) {
                $(".serverside-error").html("");
                $("#serverside tbody").empty();
                $("#serverside").append(
                    '<tr><td class="text-center" colspan="' +
                    column +
                    '">No data available in table</td></tr>'
                );
                $("#serverside_processing").css("display", "none");
            },
        },
        jQueryUI: false,
        sScrollX: "100%",
        bScrollCollapse: false,
        autoWidth: false,
        /* autoWidth: true, */
        /* scrollX: true, */
        /* fixedColumns: true, */
        lengthMenu: [
            [10, 25, 50, -1],
            [10, 25, 50, "All"],
        ],
        pageLength: 10,
        order: [
            [1, "asc"]
        ],
        columnDefs: [{
                targets: [0, column - 1],
                width: "5%",
                orderable: false,
                /* className: "text-center", */
            },
            {
                targets: [0],
                width: "3%",
                className: "text-right",
            },
        ],
        pagingType: "full_numbers",
        dom: '<"datatable-header"fBl><"datatable-scroll-wrap"t><"datatable-footer"ip>',
        language: {
            infoPostFix: "",
            search: "<span>" + labelsearch + " :</span> _INPUT_",
            searchPlaceholder: labeltype,
            info: labelinfo,
            infoFiltered: labelfilter,
            lengthMenu: "<span>" + labelshow + " : </span> _MENU_",
            url: "",
            paginate: {
                first: labelfirst,
                last: labellast,
                next: $("html").attr("dir") == "rtl" ? "&larr;" : "&rarr;",
                previous: $("html").attr("dir") == "rtl" ? "&rarr;" : "&larr;",
            },
        },
        bStateSave: true,
        fnStateSave: function(oSettings, oData) {
            localStorage.setItem("offersDataTables", JSON.stringify(oData));
        },
        fnStateLoad: function(oSettings) {
            return JSON.parse(localStorage.getItem("offersDataTables"));
        },
        drawCallback: function(settings) {
            _componentSelect2();
        },
    });
    t.on("draw.dt", function() {
        var info = t.page.info();
        t.column(0, {
                search: "applied",
                order: "applied",
                page: "applied"
            })
            .nodes()
            .each(function(cell, i) {
                cell.innerHTML = i + 1 + info.start;
            });
    });
    $("div.dataTables_filter input", t.table().container()).focus();
}

var Kalender = (function() {
    // Pickadate picker
    var _componentPickadate = function() {
        if (!$().pickadate) {
            console.warn("Warning - picker.js and/or picker.date.js is not loaded.");
            return;
        }

        // Accessibility labels
        var today = new Date();
        var date =
            today.getFullYear() +
            "," +
            (today.getMonth() + 1) +
            "," +
            today.getDate();
        $(".date").pickadate({
            labelMonthNext: "Go to the next month",
            labelMonthPrev: "Go to the previous month",
            labelMonthSelect: "Pick a month from the dropdown",
            labelYearSelect: "Pick a year from the dropdown",
            selectMonths: true,
            selectYears: true,
            formatSubmit: "yyyy-mm-dd",
            format: "dd-mm-yyyy",
            min: [2021, 1, 1],
            max: [date],
        });
    };
    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentPickadate();
        },
    };
})();

document.addEventListener("DOMContentLoaded", function() {
    Kalender.init();
    var controller = $("#path").val() + "/serverside";
    var link = $("#path").val();
    var linkadd = $("#path").val() + "/add";
    var params = {
        dfrom: $("#dfrom").val(),
        dto: $("#dto").val(),
    };
    var column = 6;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    // if (id_menu != "") {
    //     datatableaddparams(controller, column, linkadd, params, color);
    // } else {
    //     datatableparams(controller, column);
    // }
    if (id_menu != "") {
        dataTableUpload(controller, column, link, color, params);
    } else {
        datatable(controller, column);
    }
});