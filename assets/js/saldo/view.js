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
                sweetedit(controller);
            }
        }
    });

    /*---------- Tambah Baris -------------*/

});