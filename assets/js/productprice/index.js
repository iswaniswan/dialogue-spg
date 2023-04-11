// Setup module
// ------------------------------

// custom upload function
function dataTableUpload(link, column, linkdata, color) {
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

document.addEventListener("DOMContentLoaded", function() {
    var e_periode = $('input[name="e_periode"]').val();
    e_periode = e_periode.replace(" ", "");
    
    var controller = $("#path").val() + "/serverside/" + e_periode;
    var link = $("#path").val();
    var linkadd = $("#path").val() + "/add";
    var column = 8;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    if (id_menu != "") {
        // datatableadd(controller, column, linkadd, color);
        dataTableUpload(controller, column, link, color);
    } else {
        datatable(controller, column);
    }

    $('.month-picker').datepicker({
        format: "yyyy mm",
        viewMode: "months", 
        minViewMode: "months"
    }).change(function() {
        console.log($(this).val())
    });
});