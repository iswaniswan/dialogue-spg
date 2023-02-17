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
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Ya',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> Tidak',
});

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });
    $(".select").select2({
        minimumResultsForSearch: Infinity,
    });

    $("#icustomer").select2({
        placeholder: "Select Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_customer",
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
    $("#id_product").select2({
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
                    id_customer: $('#id_customer').val(),
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
                sweetedit(controller);
            }
        }
    });

    /*---------- Tambah Baris -------------*/

    var i = $("#jml").val();
    var n = 0;
    for (n; n <= i; n++) {
        $("#i_product" + n).select2({
            placeholder: "Cari Product",
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + controller + "/get_product",
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
        }).change(function(event) {
            var z = $(this).data("urut");
            var ada = false;
            for (var x = 1; x <= $("#jml").val(); x++) {
                if ($(this).val() != null) {
                    var product = $(this).val();
                    var productx = $("#i_product" + x).val();
                    console.log(product + " - " + productx);
                    if ((product == productx) && (z != x)) {
                        swalInit("Maaf :(", "Kode Barang tersebut sudah ada :(", "error");
                        ada = true;
                        break;
                    }
                }
            }
            if (!ada) {
                var product = $(this).val();
                produk = product.split(" - ");
                product = produk[0];
                brand = produk[1];
                $.ajax({
                    type: "POST",
                    url: base_url + controller + "/get_detail_product",
                    data: {
                        i_product: product,
                        i_brand: brand,
                        i_company: $('#i_company' + z).val(),
                    },
                    dataType: "json",
                    success: function(data) {
                        $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                        $("#e_company_name" + z).val(data["detail"][0]["e_company_name"]);
                        $("#i_company" + z).val(data["detail"][0]["i_company"]);
                        $("#qty" + z).focus();
                    },
                    error: function() {
                        swalInit(
                            "Maaf :(",
                            "Ada kesalahan saat mengambil data :(",
                            "error"
                        );
                    },
                });
            } else {
                $(this).val("");
                $(this).html("");
            }
        });
    }

    $("#addrow").on("click", function() {
        i++;
        var no = $("#tabledetail tbody tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no + 1}</spanx></td>`;
        cols += `<td>
                    <select data-urut="${i}" 
                        class="form-control form-control-sm form-control-select2" 
                        data-container-css-class="select-sm" 
                        name="items[${i}][id_product]"
                        id="id_product${i}" 
                        data-fouc required>
                    </select>
                </td>`;
        cols += `<td>
                    <input type="text" 
                        class="form-control form-control-sm" 
                        id="e_brand_name${i}" 
                        placeholder="Brand" 
                        name="items[${i}][e_brand]"
                        readonly>
                </td>`;
        cols += `<td>                    
                    <input type="number" required class="form-control form-control-sm" min="1" id="qty${i}" placeholder="Qty" name="items[${i}][qty]">
                </td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tabledetail").append(newRow);
        $("#id_product" + i).select2({
            placeholder: "Cari Product",
            width: "100%",
            allowClear: true,
            ajax: {
                url: base_url + controller + "/get_product",
                dataType: "json",
                delay: 250,
                data: function(params) {
                    var query = {
                        q: params.term,
                        id_customer: $('#id_customer').val()
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
        }).change(function(event) {
            var z = $(this).data("urut");
            var ada = false;
            for (var x = 1; x <= $("#jml").val(); x++) {
                if ($(this).val() != null) {
                    var product = $(this).val();
                    var productx = $("#id_product" + x).val();
                    console.log(product + " - " + productx);
                    if ((product == productx) && (z != x)) {
                        swalInit("Maaf :(", "Kode Barang tersebut sudah ada :(", "error");
                        ada = true;
                        break;
                    }
                }
            }
            if (!ada) {
                let id_product = $(this).val();
                $.ajax({
                    type: "POST",
                    url: base_url + controller + "/get_detail_product",
                    data: {
                        id_product: id_product,
                    },
                    dataType: "json",
                    success: function(data) {
                        $("#e_product" + z).val(data["detail"][0]["e_product_name"]);
                        $("#e_brand_name" + z).val(data["detail"][0]["e_brand_name"]);
                        $("#qty" + z).focus();
                    },
                    error: function() {
                        swalInit(
                            "Maaf :(",
                            "Ada kesalahan saat mengambil data :(",
                            "error"
                        );
                    },
                });
            } else {
                $(this).val("");
                $(this).html("");
            }
        });
    });


    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tabledetail").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();
        $("#jml").val(i);
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