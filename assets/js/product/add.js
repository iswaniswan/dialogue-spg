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
    $("#i_brand").select2({
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

    $("#id_category").select2({
        placeholder: "Cari kategory",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_category",
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
    })
    .change(function() {
        $("#id_sub_category").val(null).trigger('change');
    });

    $("#id_sub_category").select2({
        placeholder: "Cari Sub kategori",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_sub_category",
            dataType: "json",
            delay: 250,
            data: function(params) {
                var query = {
                    q: params.term,
                    id_category: $('#id_category').val()
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
    })
    .change(function() {
        
    });
});