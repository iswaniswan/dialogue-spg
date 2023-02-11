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

function cekData(iproduct) {
    $.ajax({
        type: "post",
        data: {
            i_product: iproduct,
        },
        url: base_url + $("#path").val() + "/cek_data_eksis",
        dataType: "json",
        data: function(params) {
            var query = {
                i_product: iproduct,
            };
            return query;
        },
        processResults: function(data) {
            if (data === false) {
                swalInit("Maaf :(", "Barang sudah ada :(");
                statusCek = data;
            } else {
                statusCek = data;
            }

        },
    });
}

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val();
    $('.form-control-select2').select2({
        minimumResultsForSearch: Infinity
    });

    $("#icustomer").select2({
        placeholder: "Nama Toko",
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
                    //id_customer: $('#icustomer').val(),
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
    // .change(function() {
    //     cekData($(this).val());
    // });

    $(".select-search").select2();

    var getId = '';

    var statusCek;

    $('#iproduct').on('change', function() {
        var id = $('#iproduct').val();
        console.log(id);
        var kompeni = $(this).val();
        kompeni = kompeni.split(" - ");
        company = kompeni[1];
        $("#idcompany").val(company);
        $.ajax({
            url: base_url + controller + "/cek_data_eksis",
            data: { iproduct: id, icompany: company },
            dataType: 'json',
            type: 'POST',
            success: function(data) {
                if (data === false) {
                    swalInit("Maaf :(", "Barang sudah ada :(");
                    statusCek = data;
                } else {
                    statusCek = data;
                }
            },
        });

        //alert($('#idcompany').val());
    })





    $("#submit").on("click", function() {
        var form = $(".form-validation").valid();
        if (form) {
            if (statusCek === true) {
                sweetadd(controller);
            } else {
                swalInit("Maaf :(", "Barang yang dipilih sudah ada :(");
            }
        }
    });
});