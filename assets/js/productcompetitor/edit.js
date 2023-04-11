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

    $("#id_customer").select2({
        placeholder: "Cari Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_customer",
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
    }).change(function() {
        $('#id_brand').val(null).trigger('change')
        $('#id_product').val(null).trigger('change')
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

    // $('#id_product').on('select2:select', function(e) {
    //     const data = e.params.data;
    //     const userdata = data.userdata;

    //     if (userdata?.id_brand !== undefined) {
    //         const idBrand = userdata.id_brand;
    //         const eBrandName = userdata.e_brand_name;
            
    //         var $option = $("<option selected></option>").val(idBrand).text(eBrandName);
    //         $('#id_brand').append($option).trigger('change');

    //     }
    // });

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
    }).change(function () {
        $('#id_product').val(null).trigger('change')
    });

    $("#submit").on("click", function() {
        var form = $('.form-validation').valid();
        if (form) {
            sweetedit(controller);
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
    $('.x-editable').editable();

    var rupiah = document.getElementById("vprice");
    rupiah.addEventListener("keyup", function(e) {
        // tambahkan 'Rp.' pada saat form di ketik
        // gunakan fungsi formatRupiah() untuk mengubah angka yang di ketik menjadi format angka
        rupiah.value = formatRupiah(this.value, "");
    });  
    
    function initInput(element) {
        element.onblur = function () {
            let value = 0;
            if (element.value == "") {
                element.value = value;
            } 
        }
        
        element.onfocus = function() {
            let value = "";
            if (element.value == "0") {
                element.value = value
            }
        }        
    }

    initInput(document.getElementById('vprice'));

    $('.month-picker').datepicker({
        format: "yyyy mm",
        viewMode: "months", 
        minViewMode: "months"
    }).change(function() {
        console.log($(this).val())
    });


});