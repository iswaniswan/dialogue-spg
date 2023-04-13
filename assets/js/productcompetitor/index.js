// Setup module
// ------------------------------

function _datatable(link, column, params) {
    var t = $("#serverside").DataTable({
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
                    '">' + labelnodata + '</td></tr>'
                );
                $("#serverside_processing").css("display", "none");
            },
        },
        jQueryUI: false,
        sScrollX: "100%",
        bScrollCollapse: false,
        jQueryUI: false,
        autoWidth: false,
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
        lengthMenu: [
            [10, 25, 50, -1],
            [10, 25, 50, "All"],
        ],
        pageLength: 10,
        order: [[6, "DESC"], [2, "ASC"]],
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
        dom: '<"datatable-header"fl><"datatable-scroll"t><"datatable-footer"ip>',
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
    var controller = $("#path").val() + "/serverside3";
    var link = $("#path").val();
    var linkadd = $("#path").val() + "/add";
    var column = 5;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();

    let params = {
        id_customer: $('#id_customer').val()
    }

    _datatable(controller, column, params);

    $("#id_customer").select2({
        placeholder: "Cari Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + $("#path").val() + "/get_customer",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                };
                return query;
            },
            processResults: function(data) {
                return {
                    results: data,
                };
            },
            cache: false,
        },
    });
});