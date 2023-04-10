/* ------------------------------------------------------------------------------
 *
 *  # Login form with validation
 *
 *  Demo JS code for login_validation.html page
 *
 * ---------------------------------------------------------------------------- */

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });
    $(".select-search").select2();
    $("#id_brand").select2({
        placeholder: "Select Brand",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_brand",
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
    $("#submit").on("click", function() {
        var form = $(".form-validation").valid();
        if (form) {
            sweetadd(controller);
        }
    });    

    $("#id_product").select2({
        placeholder: "Cari Produk",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_all_product_list",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term
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

    $('#id_product').on('select2:select', function(e) {
        const data = e.params.data;
        const userdata = data.userdata;

        if (userdata?.id_brand !== undefined) {
            const idBrand = userdata.id_brand;
            const eBrandName = userdata.e_brand_name;
            
            var $option = $("<option selected></option>").val(idBrand).text(eBrandName);
            $('#id_brand').append($option).trigger('change');

        }
    });

});