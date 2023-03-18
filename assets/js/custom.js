/* ------------------------------------------------------------------------------
 *
 *  # Custom JS code
 *
 *  Place here all your custom js. Make sure it's loaded after app.js
 *
 * ---------------------------------------------------------------------------- */

/** Fixed Header In Menu */
/* var FixedSidebarCustomScroll = (function() {
    //
    // Setup module components
    //

    // Perfect scrollbar
    var _componentPerfectScrollbar = function() {
        if (typeof PerfectScrollbar == "undefined") {
            console.warn("Warning - perfect_scrollbar.min.js is not loaded.");
            return;
        }

        // Initialize
        var ps = new PerfectScrollbar(".sidebar-fixed .sidebar-content", {
            wheelSpeed: 2,
            wheelPropagation: true,
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentPerfectScrollbar();
        },
    };
})(); */

/* ------------------------------------------------------------------------------
 *
 *  # Form validation
 *
 *  Demo JS code for form_validation.html page
 *
 * ---------------------------------------------------------------------------- */

// Setup module
// ------------------------------

/** Validasi Form */
var FormValidation = (function() {
    //
    // Setup module components
    //

    // Uniform
    var _componentUniform = function() {
        if (!$().uniform) {
            /* console.warn('Warning - uniform.min.js is not loaded.'); */
            return;
        }

        // Initialize
        $(".form-input-styled").uniform({
            fileButtonClass: "action btn bg-blue",
        });
    };

    // Validation config
    var _componentValidation = function() {
        if (!$().validate) {
            /* console.warn('Warning - validate.min.js is not loaded.'); */
            return;
        }

        // Initialize
        var validator = $(".form-validation").validate({
            ignore: "input[type=hidden], .select2-search__field", // ignore hidden fields
            errorClass: "validation-invalid-label",
            successClass: "validation-valid-label",
            validClass: "validation-valid-label",
            /* Jika Error Tampilkan Error Class */
            highlight: function(element, errorClass) {
                $(element).removeClass(errorClass);
            },
            unhighlight: function(element, errorClass) {
                $(element).removeClass(errorClass);
            },
            /* Jika Sukses Tampilkan Sukses Class */
            /* success: function(label) {
                label.addClass('validation-valid-label').text('Success.'); // remove to hide Success message
            }, */

            // Different components require proper error label placement
            errorPlacement: function(error, element) {
                // Unstyled checkboxes, radios
                if (element.parents().hasClass("form-check")) {
                    error.appendTo(element.parents(".form-check").parent());
                }

                // Input with icons and Select2
                else if (
                    element.parents().hasClass("form-group-feedback") ||
                    element.hasClass("select2-hidden-accessible")
                ) {
                    error.appendTo(element.parent());
                }

                // Input group, styled file input
                else if (
                    element.parent().is(".uniform-uploader, .uniform-select") ||
                    element.parents().hasClass("input-group")
                ) {
                    error.appendTo(element.parent().parent());
                }

                // Other elements
                else {
                    error.insertAfter(element);
                }
            },
            rules: {
                password: {
                    minlength: 5,
                },
                repeat_password: {
                    equalTo: "#password",
                },
                email: {
                    email: true,
                },
                repeat_email: {
                    equalTo: "#email",
                },
                minimum_characters: {
                    minlength: 10,
                },
                maximum_characters: {
                    maxlength: 10,
                },
                minimum_number: {
                    min: 10,
                },
                maximum_number: {
                    max: 10,
                },
                number_range: {
                    range: [10, 20],
                },
                url: {
                    url: true,
                },
                /* 
                                date: {
                                    date: true,
                                },
                                date_iso: {
                                    dateISO: true,
                                }, */
                numbers: {
                    number: true,
                },
                digits: {
                    digits: true,
                },
                creditcard: {
                    creditcard: true,
                },
                basic_checkbox: {
                    minlength: 2,
                },
                styled_checkbox: {
                    minlength: 2,
                },
                switchery_group: {
                    minlength: 2,
                },
                switch_group: {
                    minlength: 2,
                },
            },
            messages: {
                custom: {
                    required: "This is a custom error message",
                },
                basic_checkbox: {
                    minlength: "Please select at least {0} checkboxes",
                },
                styled_checkbox: {
                    minlength: "Please select at least {0} checkboxes",
                },
                switchery_group: {
                    minlength: "Please select at least {0} switches",
                },
                switch_group: {
                    minlength: "Please select at least {0} switches",
                },
                agree: "Please accept our policy",
            },
        });

        // Reset form
        $("#reset").on("click", function() {
            validator.resetForm();
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentUniform();
            _componentValidation();
        },
    };
})();

/* var FloatingActionButton = (function() {
    //
    // Setup module components
    //

    // FAB
    var _componentFab = function() {

        // Add bottom spacing if reached bottom,
        // to avoid footer overlapping
        // -------------------------

        $(window).on("scroll", function() {
            if (
                $(window).scrollTop() + $(window).height() >
                $(document).height() - 40
            ) {
                $(".fab-menu-bottom-left, .fab-menu-bottom-right").addClass(
                    "reached-bottom"
                );
            } else {
                $(".fab-menu-bottom-left, .fab-menu-bottom-right").removeClass(
                    "reached-bottom"
                );
            }
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentFab();
        },
    };
})(); */

// Initialize module
// ------------------------------

document.addEventListener("DOMContentLoaded", function() {
    /* FixedSidebarCustomScroll.init(); */
    FormValidation.init();
    /* FloatingActionButton.init(); */
});

if (lang == 'indonesia') {
    var labeladd = 'Tambah';
    var labelupload = 'Unggah';
    var labelsearch = 'Cari';
    var labeltype = 'Ketik untuk Mencari..';
    var labelfirst = 'Pertama';
    var labellast = 'Terakhir';
    var labelnodata = 'Tidak ada data di tabel ini';
    var labelshow = 'Lihat';
    var labelinfo = 'Menampilkan _START_ sampai _END_ dari _TOTAL_ entri';
    var labelfilter = "(disaring dari _MAX_ total entri)";
} else {
    var labeladd = 'Add';
    var labelupload = 'Upload';
    var labelsearch = 'Search';
    var labeltype = 'Type to Search..';
    var labelfirst = 'First';
    var labellast = 'Last';
    var labelnodata = 'No data available in table';
    var labelshow = 'Show';
    var labelinfo = 'Showing _START_ to _END_ of _TOTAL_ entries';
    var labelfilter = "(filtered from _MAX_ total entries)";
}

/* ------------------------------------------------------------------------------
 *
 *  # Datatable
 *
 * ---------------------------------------------------------------------------- */
function datatable(link, column) {
    var t = $("#serverside").DataTable({
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

function datatableadd(link, column, linkadd, color) {
    var t = $("#serverside").DataTable({
        buttons: [{
            text: '<i class="icon-database-add"></i>&nbsp; ' + labeladd,
            className: "btn btn-outline bg-" +
                color +
                " text-" +
                color +
                " border-" +
                color +
                "",
            action: function(e, dt, node, config) {
                window.location.href = base_url + linkadd;
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
                    '">"' + labelnodata + '"</td></tr>'
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
            lengthMenu: "<span>" + labelshow + " :</span> _MENU_",
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

function datatabletransfer(link, column, linkdata, color) {
    var t = $("#serverside").DataTable({
        buttons: [{
            text: '<i class="icon-database-insert"></i>&nbsp; Transfer',
            className: "btn btn-outline bg-" +
                color +
                " text-" +
                color +
                " border-" +
                color +
                "",
            action: function(e, dt, node, config) {
                var swalInit = swal.mixin({
                    buttonsStyling: false,
                    confirmButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
                    cancelButtonClass: "btn btn-sm btn-outline bg-primary-800 text-primary-800 border-primary-800",
                    confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
                    cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
                });
                swalInit({
                    title: "Transfer Dari Perusahaan",
                    input: "select",
                    type: "question",
                    inputClass: "form-control form-control-sm select-single",
                    showCancelButton: true,
                    inputAttributes: {
                        "data-placeholder": "Select Company",
                    },
                    onOpen: function() {
                        $(".swal2-select.select-single").select2({
                            width: "100%",
                            allowClear: true,
                            ajax: {
                                url: base_url + linkdata + "/get_company",
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
                    },
                }).then(function(result) {
                    if (result.value) {
                        $.ajax({
                            type: "POST",
                            data: {
                                id: result.value,
                            },
                            url: base_url + linkdata + "/transfer",
                            dataType: "json",
                            beforeSend: function() {
                                $(".page-content").block({
                                    message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                                    centerX: false,
                                    centerY: false,
                                    overlayCSS: {
                                        backgroundColor: "#fff",
                                        opacity: 0.8,
                                        cursor: "wait",
                                    },
                                    css: {
                                        border: 0,
                                        padding: 0,
                                        backgroundColor: "none",
                                    },
                                });
                            },
                            success: function(data) {
                                if (data.sukses == true) {
                                    swalInit(
                                        "Success!",
                                        "Data successfully to assign:)",
                                        "success"
                                    ).then(function(result) {
                                        window.location = base_url + linkdata;
                                    });
                                } else {
                                    swalInit("Sorry :(", "Data failed to assign :(", "error");
                                }
                                $(".page-content").unblock();
                            },
                            error: function() {
                                swalInit("Sorry", "Data failed to assign :(", "error");
                                $(".page-content").unblock();
                            },
                        });
                    }
                });
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

function datatableupload(link, column, linkdata, color) {
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

/** Datatable Add With Parameter */
function datatableaddparams(link, column, linkadd, params, color) {
    var t = $("#serverside").DataTable({
        buttons: [{
            text: '<i class="icon-database-add"></i>&nbsp; ' + labeladd,
            className: "btn btn-outline bg-" +
                color +
                " text-" +
                color +
                " border-" +
                color +
                "",
            action: function(e, dt, node, config) {
                window.location.href = base_url + linkadd;
            },
        }, ],
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
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

/** Datatable Add With Parameter Group */
function datatableaddparamsgroup(link, column, linkadd, params) {
    var t = $("#serverside").DataTable({
        buttons: [{
            text: '<i class="icon-database-add"></i>&nbsp; ' + labeladd,
            className: "btn btn-outline bg-teal text-teal border-teal",
            action: function(e, dt, node, config) {
                window.location.href = base_url + linkadd;
            },
        }, ],
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
        lengthMenu: [
            [10, 25, 50, -1],
            [10, 25, 50, "All"],
        ],
        pageLength: 10,
        order: [
            [2, "desc"]
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
            {
                targets: [2],
                visible: false,
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
            var api = this.api();
            var rows = api.rows({
                page: "current"
            }).nodes();
            var last = null;

            // Grouod rows
            api
                .column(2, {
                    page: "current"
                })
                .data()
                .each(function(group, i) {
                    if (last !== group) {
                        $(rows)
                            .eq(i)
                            .before(
                                '<tr class="table-active table-border-double"><td colspan="' +
                                column +
                                '" class="font-weight-semibold">' +
                                group +
                                "</td></tr>"
                            );

                        last = group;
                    }
                });
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

/** Datatable With Parameter */
function datatableparams(link, column, params, col = 999, order = 0) {
    localStorage.clear();
    if (col == 999) {
        col = [0];
    } else {
        col = col;
    }
    if (order == 0) {
        order = [1, "asc"];
    } else {
        order = order;
    }
    var t = $("#serverside").DataTable({
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        // sScrollX: "100%",
        // bScrollCollapse: false,
        // autoWidth: false,
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
        lengthMenu: [
            [10, 25, 50, -1],
            [10, 25, 50, "All"],
        ],
        pageLength: 10,
        order: [
            order
        ],
        // columnDefs: [{
        //         targets: [column - 1],
        //         width: "5%",
        //         // orderable: false,
        //         /* className: "text-center", */
        //     },
        //     // {
        //     //     targets: [0],
        //     //     width: "3%",
        //     //     orderable: false,
        //     //     className: "text-right",
        //     // },
        //     {
        //         targets: col,
        //         className: "text-right",
        //     },
        // ],
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

/** Datatable With Parameter Group */
function datatableparamsgroup(link, column, params) {
    var t = $("#serverside").DataTable({
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
        lengthMenu: [
            [10, 25, 50, -1],
            [10, 25, 50, "All"],
        ],
        pageLength: 10,
        order: [
            [2, "desc"]
        ],
        columnDefs: [{
                targets: [column - 1],
                width: "3%",
                orderable: false,
                /* className: "text-center", */
            },
            {
                targets: [0],
                width: "3%",
                orderable: false,
                className: "text-right",
            },
            {
                targets: [2],
                visible: false,
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
            var api = this.api();
            var rows = api.rows({
                page: "current"
            }).nodes();
            var last = null;

            // Grouod rows
            api
                .column(2, {
                    page: "current"
                })
                .data()
                .each(function(group, i) {
                    if (last !== group) {
                        $(rows)
                            .eq(i)
                            .before(
                                '<tr class="table-active table-border-double"><td colspan="' +
                                column +
                                '" class="font-weight-semibold">' +
                                group +
                                "</td></tr>"
                            );

                        last = group;
                    }
                });

            // Initialize components
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

// Select2
var _componentSelect2 = function() {
    if (!$().select2) {
        console.warn("Warning - select2.min.js is not loaded.");
        return;
    }

    // Initialize
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });

    // Length menu styling
    $(".dataTables_length select").select2({
        minimumResultsForSearch: Infinity,
        dropdownAutoWidth: true,
        width: "auto",
    });
};

/** Datatable With Parameter */
function datatablelist(link, column, params) {
    var t = $("#serverside").DataTable({
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        //lengthMenu: [[10, 25, 100, -1], [10, 25, 100, "All"]],
        bScrollInfinite: true,
        bColumnCollapse: true,
        //paging: false,
        responsive: true,

        jQueryUI: false,
        sScrollX: "100%",
        bScrollCollapse: false,
        autoWidth: false,
        /* autoWidth: true, */
        sScrollY: "350px",
        /* ScrollX: true,
        fixedColumns: true, */
        order: [
            [1, "asc"]
        ],
        columnDefs: [{
                //targets: [column - 1],
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

/** Datatable With Parameter */
function datatableparamsexport(link, column, params) {
    var t = $("#serverside").DataTable({
        serverSide: true,
        processing: true,
        ajax: {
            url: base_url + link,
            data: params,
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
        lengthMenu: [
            [10, 25, 100, -1],
            [10, 25, 100, "All"],
        ],
        pageLength: 10,
        jQueryUI: false,
        sScrollX: "100%",
        bScrollCollapse: false,
        autoWidth: false,
        /* autoWidth: true,
        scrollX: true,
        fixedColumns: true, */
        order: [
            [1, "asc"]
        ],
        columnDefs: [{
                targets: [column - 1],
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
        buttons: {
            buttons: [{
                    extend: "copyHtml5",
                    className: "btn btn-outline bg-teal text-teal border-teal btn-sm legitRipple",
                    exportOptions: {
                        columns: ":not(:last-child)",
                    },
                },
                {
                    extend: "excelHtml5",
                    className: "btn btn-outline bg-teal text-teal border-teal btn-sm legitRipple",
                    exportOptions: {
                        columns: ":not(:last-child)",
                    },
                },
                {
                    extend: "csvHtml5",
                    className: "btn btn-outline bg-teal text-teal border-teal btn-sm legitRipple",
                    exportOptions: {
                        columns: ":not(:last-child)",
                    },
                },
                {
                    extend: "pdfHtml5",
                    className: "btn btn-outline bg-teal text-teal border-teal btn-sm legitRipple",
                    exportOptions: {
                        columns: ":not(:last-child)",
                    },
                },
            ],
        },

        pagingType: "full_numbers",
        dom: '<"datatable-header"fBl><"datatable-scroll"t><"datatable-footer"ip>',
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

/** SweetAlert Add Data */
function sweetadd(link) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be saved :)",
        type: "info",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: $("form").serialize(),
                url: base_url + link + "/save",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true && data.ada == false) {
                        swalInit("Success!", "Data saved successfully :)", "success").then(
                            function(result) {
                                window.location = base_url + link;
                            }
                        );
                    } else if (data.sukses == false && data.ada == true) {
                        swalInit("Sorry :(", "The data already exists :(", "error");
                    } else {
                        swalInit("Sorry :(", "Data failed to save :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to save :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/** SweetAlert Add Upload Data With Params */
function sweetaddupload(link, formData) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    $.ajax({
        type: "POST",
        enctype: "multipart/form-data",
        data: formData,
        url: base_url + link + "/prosesupload",
        dataType: "json",
        contentType: false,
        processData: false,
        cache: false,
        beforeSend: function() {
            $(".page-content").block({
                message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                centerX: false,
                centerY: false,
                overlayCSS: {
                    backgroundColor: "#fff",
                    opacity: 0.8,
                    cursor: "wait",
                },
                css: {
                    border: 0,
                    padding: 0,
                    backgroundColor: "none",
                },
            });
        },
        success: function(data) {
            if (data.sukses == true) {
                swalInit("Success!", "Data upload successfully :)", "success").then(
                    function(result) {
                        window.location = base_url + link + '/detailupload/' + data.id + '/' + data.filename;
                    }
                );
            } else {
                swalInit("Sorry :(", "Data failed to upload :(", "error");
            }
            $(".page-content").unblock();
        },
        error: function(data) {
            console.log(data);
            swalInit("Sorry", "dddddData failed to upload :(", "error");
            $(".page-content").unblock();
        },
    });
}

/** SweetAlert Add Upload Data With Params */
function sweetadduploads(link, formData) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    $.ajax({
        type: "POST",
        enctype: "multipart/form-data",
        data: formData,
        url: base_url + link + "/prosesupload",
        dataType: "json",
        contentType: false,
        processData: false,
        cache: false,
        beforeSend: function() {
            $(".page-content").block({
                message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                centerX: false,
                centerY: false,
                overlayCSS: {
                    backgroundColor: "#fff",
                    opacity: 0.8,
                    cursor: "wait",
                },
                css: {
                    border: 0,
                    padding: 0,
                    backgroundColor: "none",
                },
            });
        },
        success: function(data) {
            if (data.sukses == true) {
                swalInit("Success!", "Data upload successfully :)", "success").then(
                    function(result) {
                        window.location = base_url + link + '/detailupload/' + data.id + '/' + data.filename + '/' + data.periode;
                    }
                );
            } else {
                swalInit("Sorry :(", "Data failed to upload :(", "error");
            }
            $(".page-content").unblock();
        },
        error: function() {
            swalInit("Sorry", "Data failed to upload :(", "error");
            $(".page-content").unblock();
        },
    });
}

/** SweetAlert Add Data With Params */
function sweetaddparams(link, formData) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be saved :)",
        type: "info",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                /* data: $("form").serialize(), */
                enctype: "multipart/form-data",
                data: formData,
                url: base_url + link + "/save",
                dataType: "json",
                contentType: false,
                processData: false,
                cache: false,
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true && data.ada == false) {
                        swalInit("Success!", "Data saved successfully :)", "success").then(
                            function(result) {
                                window.location = base_url + link;
                            }
                        );
                    } else if (data.sukses == false && data.ada == true) {
                        swalInit("Sorry :(", "The data already exists :(", "error");
                    } else {
                        swalInit("Sorry :(", "Data failed to save :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to save :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/** SweetAlert Edit Data */

function sweetedit(link) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be update :)",
        type: "info",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: $("form").serialize(),
                url: base_url + link + "/update",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true && data.ada == false) {
                        swalInit("Success!", "Data update successfully :)", "success").then(
                            function(result) {
                                window.location = base_url + link;
                            }
                        );
                    } else if (data.sukses == false && data.ada == true) {
                        swalInit("Sorry :(", "The data already exists :(", "error");
                    } else {
                        swalInit("Sorry :(", "Data failed to update :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to update :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/** SweetAlert Add Data With Params */

function sweeteditparams(link, formData) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be update :)",
        type: "info",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                /* data: $("form").serialize(), */
                enctype: "multipart/form-data",
                data: formData,
                url: base_url + link + "/update",
                dataType: "json",
                contentType: false,
                processData: false,
                cache: false,
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true && data.ada == false) {
                        swalInit("Success!", "Data update successfully :)", "success").then(
                            function(result) {
                                window.location = base_url + link;
                            }
                        );
                    } else if (data.sukses == false && data.ada == true) {
                        swalInit("Sorry :(", "The data already exists :(", "error");
                    } else {
                        swalInit("Sorry :(", "Data failed to update :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to update :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/** Rubah Menjadi Huruf Kapital */
function gede(a) {
    var start = a.selectionStart,
        end = a.selectionEnd;
    a.value = a.value.toUpperCase();
    a.setSelectionRange(start, end);
}

/** Loading Page */
/* $(window).load(function() { */
$(document).ready(function() {
    // Animate loader off screen
    $(".loading").fadeOut("slow");
});

/** Update Status */
function changestatus(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn bg-teal",
        cancelButtonClass: "btn btn-primary",
    });

    $.ajax({
        type: "POST",
        data: {
            id: id,
        },
        url: base_url + link + "/changestatus",
        dataType: "json",
        beforeSend: function() {
            $(".page-content").block({
                message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                centerX: false,
                centerY: false,
                overlayCSS: {
                    backgroundColor: "#fff",
                    opacity: 0.8,
                    cursor: "wait",
                },
                css: {
                    border: 0,
                    padding: 0,
                    backgroundColor: "none",
                },
            });
        },
        success: function(data) {
            if (data.sukses == true) {
                swalInit("Success!", "Data update successfully :)", "success").then(
                    function(result) {
                        window.location = base_url + link;
                    }
                );
            } else {
                swalInit("Sorry :(", "Data failed to update :(", "error");
            }
            $(".page-content").unblock();
        },
        error: function() {
            swalInit("Sorry", "Data failed to update :(", "error");
            $(".page-content").unblock();
        },
    });
}

//delete
function sweetdelete(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be deleted :)",
        type: "error",
        showCancelButton: true,
        confirmButtonText: '<i class="icon-checkmark4"></i> Yes',
        cancelButtonText: '<i class="icon-cross2"></i> No',
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                },
                url: base_url + link + "/delete",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to delete:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to deleted :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to delete :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/* Cancel */
function sweetcancel(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be canceled :)",
        type: "error",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                },
                url: base_url + link + "/cancel",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to cancel:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to canceled :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to cancel :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/* Reject */
function sweetreject(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-danger-800 text-danger-800 border-danger-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Why this ticket not approved?",
        type: "error",
        input: "textarea",
        inputPlaceholder: "The reason is not approved ..",
        showCancelButton: true,
        inputClass: "form-control",
        inputValidator: function(value) {
            return !value && "You need to write something!";
        },
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                    text: result.value,
                },
                url: base_url + link + "/reject",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to reject:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to rejected :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to reject :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/* Approve */
function sweetapprove(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be approved :)",
        type: "question",
        /* input: "textarea",
        inputPlaceholder: "Note approved ..", */
        showCancelButton: true,
        buttonsStyling: false,
        /* inputClass: "form-control", */
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                    text: result.value,
                },
                url: base_url + link + "/approve",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to approve:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to approved :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to approve :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/* Approve */
function sweetapproveremark(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be approved :)",
        type: "question",
        input: "textarea",
        inputPlaceholder: "Note approved ..",
        showCancelButton: true,
        buttonsStyling: false,
        inputClass: "form-control",
    }).then((result) => {
        if (!result.dismiss) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                    text: result.value,
                },
                url: base_url + link + "/approve",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to approve:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to approved :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to approve :(", "error");
                    $(".page-content").unblock();
                },
            });
        } else if (result.dismiss) {
            return false;
        }
    });
}

/** SweetAlert Add Data Transfer */
function sweettransfer(link) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-blue-600 text-blue-600 border-blue-600",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be saved :)",
        type: "info",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: $("form").serialize(),
                url: base_url + link + "/transfer",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        centerX: false,
                        centerY: false,
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true && data.ada == false) {
                        swalInit("Success!", "Data saved successfully :)", "success").then(
                            function(result) {
                                window.location = base_url + link;
                            }
                        );
                    } else if (data.sukses == false && data.ada == true) {
                        swalInit("Sorry :(", "The data already exists :(", "error");
                    } else {
                        swalInit("Sorry :(", "Data failed to save :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to save :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

/* Resolve */
function sweetresolve(link, id) {
    var swalInit = swal.mixin({
        buttonsStyling: false,
        confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
        cancelButtonClass: "btn btn-sm btn-outline bg-primary-800 text-primary-800 border-primary-800",
        confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
        cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
    });
    swalInit({
        title: "Are you sure?",
        text: "This data will be resolved :)",
        type: "success",
        showCancelButton: true,
        buttonsStyling: false,
    }).then(function(result) {
        if (result.value) {
            $.ajax({
                type: "POST",
                data: {
                    id: id,
                },
                url: base_url + link + "/resolve",
                dataType: "json",
                beforeSend: function() {
                    $(".page-content").block({
                        message: '<div class="spinner-grow text-primary"></div><div class="spinner-grow text-success"></div><div class="spinner-grow text-teal"></div><div class="spinner-grow text-info"></div><div class="spinner-grow text-warning"></div><div class="spinner-grow text-orange"></div><div class="spinner-grow text-danger"></div><div class="spinner-grow text-secondary"></div><div class="spinner-grow text-dark"></div><div class="spinner-grow text-muted"></div><br><h1 class="text-muted d-block">P l e a s e &nbsp;&nbsp; W a i t</h1>',

                        centerX: false,
                        centerY: false,
                        /* message: '<img src="../assets/image/Preloader_2.gif" alt="loading" /><h1 class="text-muted d-block">L o a d i n g</h1>', */
                        overlayCSS: {
                            backgroundColor: "#fff",
                            opacity: 0.8,
                            cursor: "wait",
                        },
                        css: {
                            border: 0,
                            padding: 0,
                            backgroundColor: "none",
                        },
                    });
                },
                success: function(data) {
                    if (data.sukses == true) {
                        swalInit(
                            "Success!",
                            "Data successfully to resolve:)",
                            "success"
                        ).then(function(result) {
                            window.location = base_url + link;
                        });
                    } else {
                        swalInit("Sorry :(", "Data failed to resolved :(", "error");
                    }
                    $(".page-content").unblock();
                },
                error: function() {
                    swalInit("Sorry", "Data failed to resolve :(", "error");
                    $(".page-content").unblock();
                },
            });
        }
    });
}

// @param - timeStamp - Javascript Date object or date string
// @usage - timeSince(new Date().setFullYear(2019))
function timeSince(timeStamp) {
    if (!(timeStamp instanceof Date)) {
        timeStamp = new Date(timeStamp);
    }

    if (isNaN(timeStamp.getDate())) {
        return "Invalid date";
    }

    var now = new Date(),
        secondsPast = (now.getTime() - timeStamp.getTime()) / 1000;

    var formatDate = function(date, format, utc) {
        var MMMM = [
            "\x00",
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        ];
        var MMM = [
            "\x01",
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "Jun",
            "Jul",
            "Aug",
            "Sep",
            "Oct",
            "Nov",
            "Dec",
        ];
        var dddd = [
            "\x02",
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
        ];
        var ddd = ["\x03", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

        function ii(i, len) {
            var s = i + "";
            len = len || 2;
            while (s.length < len) s = "0" + s;
            return s;
        }

        var y = utc ? date.getUTCFullYear() : date.getFullYear();
        format = format.replace(/(^|[^\\])yyyy+/g, "$1" + y);
        format = format.replace(/(^|[^\\])yy/g, "$1" + y.toString().substr(2, 2));
        format = format.replace(/(^|[^\\])y/g, "$1" + y);

        var M = (utc ? date.getUTCMonth() : date.getMonth()) + 1;
        format = format.replace(/(^|[^\\])MMMM+/g, "$1" + MMMM[0]);
        format = format.replace(/(^|[^\\])MMM/g, "$1" + MMM[0]);
        format = format.replace(/(^|[^\\])MM/g, "$1" + ii(M));
        format = format.replace(/(^|[^\\])M/g, "$1" + M);

        var d = utc ? date.getUTCDate() : date.getDate();
        format = format.replace(/(^|[^\\])dddd+/g, "$1" + dddd[0]);
        format = format.replace(/(^|[^\\])ddd/g, "$1" + ddd[0]);
        format = format.replace(/(^|[^\\])dd/g, "$1" + ii(d));
        format = format.replace(/(^|[^\\])d/g, "$1" + d);

        var H = utc ? date.getUTCHours() : date.getHours();
        format = format.replace(/(^|[^\\])HH+/g, "$1" + ii(H));
        format = format.replace(/(^|[^\\])H/g, "$1" + H);

        var h = H > 12 ? H - 12 : H == 0 ? 12 : H;
        format = format.replace(/(^|[^\\])hh+/g, "$1" + ii(h));
        format = format.replace(/(^|[^\\])h/g, "$1" + h);

        var m = utc ? date.getUTCMinutes() : date.getMinutes();
        format = format.replace(/(^|[^\\])mm+/g, "$1" + ii(m));
        format = format.replace(/(^|[^\\])m/g, "$1" + m);

        var s = utc ? date.getUTCSeconds() : date.getSeconds();
        format = format.replace(/(^|[^\\])ss+/g, "$1" + ii(s));
        format = format.replace(/(^|[^\\])s/g, "$1" + s);

        var f = utc ? date.getUTCMilliseconds() : date.getMilliseconds();
        format = format.replace(/(^|[^\\])fff+/g, "$1" + ii(f, 3));
        f = Math.round(f / 10);
        format = format.replace(/(^|[^\\])ff/g, "$1" + ii(f));
        f = Math.round(f / 10);
        format = format.replace(/(^|[^\\])f/g, "$1" + f);

        var T = H < 12 ? " AM" : " PM";
        format = format.replace(/(^|[^\\])TT+/g, "$1" + T);
        format = format.replace(/(^|[^\\])T/g, "$1" + T.charAt(0));

        var t = T.toLowerCase();
        format = format.replace(/(^|[^\\])tt+/g, "$1" + t);
        format = format.replace(/(^|[^\\])t/g, "$1" + t.charAt(0));

        var tz = -date.getTimezoneOffset();
        var K = utc || !tz ? "Z" : tz > 0 ? "+" : "-";
        if (!utc) {
            tz = Math.abs(tz);
            var tzHrs = Math.floor(tz / 60);
            var tzMin = tz % 60;
            K += ii(tzHrs) + ":" + ii(tzMin);
        }
        format = format.replace(/(^|[^\\])K/g, "$1" + K);

        var day = (utc ? date.getUTCDay() : date.getDay()) + 1;
        format = format.replace(new RegExp(dddd[0], "g"), dddd[day]);
        format = format.replace(new RegExp(ddd[0], "g"), ddd[day]);

        format = format.replace(new RegExp(MMMM[0], "g"), MMMM[M]);
        format = format.replace(new RegExp(MMM[0], "g"), MMM[M]);

        format = format.replace(/\\(.)/g, "$1");

        return format;
    };

    if (secondsPast < 0) {
        // Future date
        return timeStamp;
    }
    if (secondsPast < 60) {
        // Less than a minute
        return parseInt(secondsPast) + " secs";
    }
    if (secondsPast < 3600) {
        // Less than an hour
        return parseInt(secondsPast / 60) + " mins";
    }
    if (secondsPast <= 86400) {
        // Less than a day
        return parseInt(secondsPast / 3600) + " hrs";
    }
    if (secondsPast <= 172800) {
        // Less than 2 days
        return "Yesderday at " + formatDate(timeStamp, " h:mmtt");
    }
    if (secondsPast > 172800) {
        // After two days
        var timeString;

        if (secondsPast <= 604800)
            timeString =
            formatDate(timeStamp, " dddd") +
            " at " +
            formatDate(timeStamp, " h:mmtt");
        // with in a week
        else if (now.getFullYear() > timeStamp.getFullYear())
            timeString = formatDate(timeStamp, "MMMM d, yyyy");
        // a year ago
        else if (now.getMonth() > timeStamp.getMonth())
            timeString = formatDate(timeStamp, "MMMM d");
        // months ago
        else
            timeString =
            formatDate(timeStamp, "MMMM d") +
            " at " +
            formatDate(timeStamp, "h:mmtt"); // with in a month

        return timeString;
    }
}

function set_company(id, name) {
    $.ajax({
        type: "POST",
        data: {
            id: id,
            name: name,
        },
        url: base_url + "auth/set_company",
        dataType: "html",
        success: function(data) {
            window.location = base_url;
        },
        error: function() {
            alert("Error :)");
        },
    });
}

function formatulang(a) {
    var s = a.replace(/\,/g, "");
    return s;
}

function formatcemua(input) {
    var num = input.toString();
    if (!isNaN(num)) {
        if (num.indexOf(".") > -1) {
            num = num.split(".");
            num[0] = num[0]
                .toString()
                .split("")
                .reverse()
                .join("")
                .replace(/(?=\d*\.?)(\d{3})/g, "$1,")
                .split("")
                .reverse()
                .join("")
                .replace(/^[\,]/, "");
            if (num[1].length > 2) {
                while (num[1].length > 2) {
                    num[1] = num[1].substring(0, num[1].length - 1);
                }
            }
            input = num[0];
        } else {
            input = num
                .toString()
                .split("")
                .reverse()
                .join("")
                .replace(/(?=\d*\.?)(\d{3})/g, "$1,")
                .split("")
                .reverse()
                .join("")
                .replace(/^[\,]/, "");
        }
    }
    return input;
}

function reformat(input) {
	var num = input.value.replace(/\,/g, "");
	if (!isNaN(num)) {
		if (num.indexOf(".") > -1) {
			num = num.split(".");
			num[0] = num[0]
				.toString()
				.split("")
				.reverse()
				.join("")
				.replace(/(?=\d*\.?)(\d{3})/g, "$1,")
				.split("")
				.reverse()
				.join("")
				.replace(/^[\,]/, "");
			if (num[1].length > 4) {
				alert("maksimum 4 desimal !!!");
				num[1] = num[1].substring(0, num[1].length - 1);
			}
			input.value = num[0] + "." + num[1];
		} else {
			input.value = num
				.toString()
				.split("")
				.reverse()
				.join("")
				.replace(/(?=\d*\.?)(\d{3})/g, "$1,")
				.split("")
				.reverse()
				.join("")
				.replace(/^[\,]/, "");
		}
	} else {
		alert("input harus numerik !!!");
		input.value = input.value.substring(0, input.value.length - 1);
	}
}