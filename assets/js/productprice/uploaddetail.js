/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */
var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Yes',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> No',
});
document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });
    $("#icompany").on("change", function() {
        $('#iproduct').val('');
        $('#iproduct').html('');
    });
    $('#id_customer').select2();

    // $("#icustomer").select2({
    //     placeholder: "Select Customer",
    //     width: "100%",
    //     allowClear: true,
    //     ajax: {
    //         url: base_url + controller + "/get_customer",
    //         dataType: "json",
    //         delay: 250,
    //         data: function(params) {
    //             var query = {
    //                 q: params.term,
    //             };
    //             return query;
    //         },
    //         processResults: function(data) {
    //             return {
    //                 results: data,
    //             };
    //         },
    //         cache: false,
    //     },
    // });
    $("#iproduct").select2({
        placeholder: "Search Product",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_product",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                    i_company: $('#icompany').val(),
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
    $(".select-search").select2();
    $("#submit").on("click", function() {
        var product = [];
        $("#tabledetail tbody tr td .product").each(function() {
            product.push($(this).val());
        });
        let findDuplicates = arr => arr.filter((item, index) => arr.indexOf(item) != index);
        let sama = [...new Set(findDuplicates(product))];
        var form = $(".form-validation").valid();
        if (form) {
            if (sama.length > 0) {
                swalInit("Maaf :(", "Kode Barang Berikut Duplicat : " + sama, "error");
            } else {
                sweettransfer(controller);
            }
        }
    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tabledetail").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();
        var obj = $("#tabledetail tr:visible").find("spanx");
        $.each(obj, function(key, value) {
            id = value.id;
            $("#" + id).html(key + 1);
        });
    });


    /* // Setting datatable defaults
    $.extend($.fn.dataTable.defaults, {
        jQueryUI: false,
        sScrollX: "100%",
        bScrollCollapse: false,
        autoWidth: false,
        order: [
            [1, "asc"]
        ],
        columnDefs: [{
            targets: [0, 5],
            width: '5%',
            orderable: false,
        }, {
            targets: [1],
            width: '25%',
        }, {
            targets: [2],
            width: '15%',
        }, {
            targets: [3],
            width: '35%',
        }, {
            targets: [4],
            width: '15%',
        }, ],
        dom: '<"datatable-header"fl><"datatable-scroll-wrap"t><"datatable-footer"ip>',
        language: {
            search: '<span>Filter:</span> _INPUT_',
            searchPlaceholder: 'Type to filter...',
            lengthMenu: '<span>Show:</span> _MENU_',
            paginate: { 'first': 'First', 'last': 'Last', 'next': $('html').attr('dir') == 'rtl' ? '&larr;' : '&rarr;', 'previous': $('html').attr('dir') == 'rtl' ? '&rarr;' : '&larr;' }
        }
    });


    // Basic initialization
    var table_basic = $('.datatable-header-basic').DataTable({
        fixedHeader: true
    });

    // Toggle necessary body and navbar classes
    $('body').children('.navbar').first().addClass('fixed-top');
    $('body').addClass('navbar-top');

    // Add offset to all
    table_basic.fixedHeader.headerOffset($('.fixed-top').height());
    table_footer.fixedHeader.headerOffset($('.fixed-top').height());
    table_reorder.fixedHeader.headerOffset($('.fixed-top').height());
    table_offset.fixedHeader.headerOffset($('.fixed-top').height()); */
});