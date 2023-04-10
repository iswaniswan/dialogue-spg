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

function cekData(params) {
    $.ajax({
        type: "post",
        data: {
            i_product: iproduct,
        },
        url: base_url + $("#path").val() + "/cek_data_eksis",
        dataType: "json",
        data: function(params) {
            var query = {
                id_product: params?.id_product,
                id_customer: params?.id_customer
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

    $("#id_customer").select2({
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
    // .change(function() {
    //     cekData($(this).val());
    // });

    $(".select-search").select2();

    var getId = '';

    var statusCek;    

    $("#submit").on("click", function() {
        var form = $(".form-validation").valid();
        if (form) {
            sweetadd(controller);
        }
    });
});


/* Fungsi formatRupiah */
function formatRupiah(angka, prefix) {
    var number_string = angka.replace(/[^,\d]/g, "").toString(),
      split = number_string.split(","),
      sisa = split[0].length % 3,
      rupiah = split[0].substr(0, sisa),
      ribuan = split[0].substr(sisa).match(/\d{3}/gi);
  
    // tambahkan titik jika yang di input sudah menjadi angka ribuan
    if (ribuan) {
      separator = sisa ? "." : "";
      rupiah += separator + ribuan.join(".");
    }
  
    rupiah = split[1] != undefined ? rupiah + "," + split[1] : rupiah;
    return rupiah;
}


$(document).ready(function() {
    var rupiah = document.getElementById("vprice");
    rupiah.addEventListener("keyup", function(e) {
        // tambahkan 'Rp.' pada saat form di ketik
        // gunakan fungsi formatRupiah() untuk mengubah angka yang di ketik menjadi format angka
        rupiah.value = formatRupiah(this.value, "");
    });

    $('#id_customer').on('change', function() {
        $('#id_product').val('');
        $('#id_product').trigger('change.select2');
    });

    var today = new Date();
    var date =
        today.getFullYear() +
        "," +
        (today.getMonth() + 1) +
        "," +
        today.getDate();
    // $(".date").pickadate({
    //     labelMonthNext: "Go to the next month",
    //     labelMonthPrev: "Go to the previous month",
    //     labelMonthSelect: "Pick a month from the dropdown",
    //     labelYearSelect: "Pick a year from the dropdown",
    //     selectMonths: true,
    //     selectYears: true,
    //     formatSubmit: "yyyy-mm",
    //     format: "yyyy-mm",
    //     min: [2021, 1, 1],
    //     max: [date],
    // });
    
    $('.date').pickadate({
        today: 'Ok',
        format: 'yyyy-mm',
        min: new Date(),
        formatSubmit: 'yyyy-mm-dd',
        hiddenPrefix: 'prefix__',
        hiddenSuffix: '__suffix',
        selectYears: true,
        selectMonths: true,
    })

    $('.picker__select--month').change(function() {
        console.log($(this).val());
    })

})  

