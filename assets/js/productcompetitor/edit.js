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

var _componentPickadate = function() {
    if (!$().pickadate) {
        console.warn("Warning - picker.js and/or picker.date.js is not loaded.");
        return;
    }

    // Accessibility labels
    var today = new Date();
    var _year = today.getFullYear();
    var _month = today.getMonth();
    var _date = today.getDate();

    var currentDate = [_year, _month, _date];

    const minDate = [_year, _month, 01];

    $(".date").pickadate({
        labelMonthNext: "Go to the next month",
        labelMonthPrev: "Go to the previous month",
        labelMonthSelect: "Pick a month from the dropdown",
        labelYearSelect: "Pick a year from the dropdown",
        selectMonths: true,
        selectYears: true,
        formatSubmit: "yyyy-mm-dd",
        format: "yyyy-mm-dd",
        min: minDate,
        max: currentDate,
    });
};

var countItems = 0;

function reIndexRowNumber() {
    let rows = document.querySelectorAll('spanx');
    
    for (i=0; i<rows.length; i++) {
        rows[i].innerHTML = i+1;
    }
}

var getCountItems = function() {
    let rows = document.querySelectorAll('.form-input-brand');
    console.log(rows.length);
    return rows.length ?? 0 ;
}

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

var controller = $("#path").val();

var Detail = $(function() {
    $("#addrow").on("click", function() {                
        let i = getCountItems() + 1;
        
        let newRow = $("<tr>");

        let cols = "";
        cols += `<td><spanx id="snum${i}">${i}</spanx></td>`;
        // cols += `<td>
        //             <select data-urut="${i}" class="form-control form-control-sm form-control-select2 form-input-customer" 
        //                 data-container-css-class="select-sm" 
        //                 name="items[${i}][id_customer]" 
        //                 id="id_customer${i}" required data-fouc>
        //             </select>
        //         </td>`;
        cols += `<td>
                    <input type="text" required class="form-control form-control-sm form-input-brand" 
                        placeholder="Nama Brand" id="e_brand_text${i}" name="items[${i}][e_brand_text]">
                </td>`;
        cols += `<td>
                    <div class="input-group">
                        <div class="input-group-prepend">
                            <span class="input-group-text">Rp.</span>
                        </div>
                        <input type="text" class="form-control form-input-price"
                                name="items[${i}][vprice]" id="vprice${i}" autocomplete="off" 
                                value="" required>
                    </div>
                </td>`;
        cols += `<td>
                    <input type="text" class="form-control form-control-sm form-input-date date"
                        name="items[${i}][d_berlaku]" id="d_berlaku${i}" required>
				</td>`;
        cols += `<td>
                <input type="text" class="form-control form-control-sm"
                    placeholder="Keterangan" id="e_remark${i}" name="items[${i}][e_remark]">
                </td>`;
        cols += `<td class="text-center" width="3%;">
                    <b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b>
                </td>`;

        newRow.append(cols);

        $("#table-competitor").append(newRow);

        $("#id_customer" + i).select2({
            placeholder: "Cari Customer",
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
        }).change(function(event) {

        });

        var rupiah = document.getElementById("vprice"+i);        
        rupiah.addEventListener("keyup", function(e) {
            rupiah.value = formatRupiah(this.value, "");
        }); 

        initInput(rupiah);

        _componentPickadate();

    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#table-competitor").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();  
        countItems--;
        console.log(countItems);
        reIndexRowNumber();
    });
});


document.addEventListener("DOMContentLoaded", function() {
    Detail.init();

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
        let rows = $("#table-competitor tbody tr").length;
        if (rows < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        let unique = true;
        let allBrandInput = $('.form-input-brand');
        let brands = [];
        allBrandInput.each(function() {

            const customer = $(this).closest('tr').find('.form-input-customer').val();
            const dValid = $(this).closest('tr').find('.form-input-date').val();
            const value = $(this).val();
            const customerBrand = `${customer}-${dValid}-${value}`;
            console.log(customerBrand);
            if (brands.includes(customerBrand)) {
                unique = false;
            }

            brands.push(customerBrand);
        })

        var valid = $('.form-validation').valid();
        if (valid & unique) {
            sweetedit(controller);
            return;
        }

        swalInit("Maaf :(", "Duplicate Brand", "error");
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
    // $('.x-editable').editable();
    
    let rupiahs = $(".form-input-price");
    rupiahs.each(function() {
        
        $(this).on("keyup", function(e) {
            let value = $(this).val();
            $(this).val(formatRupiah(value, ""));
        }); 
        
        $(this).on("onblur", function(e) {
            let value = 0;
            if ($(this).val() == "") {
                $(this).val() = value;
            } 
        });
        
        $(this).on("onfocus", function(e) {
            let value = "";
            if ($(this).val() == "0") {
                $(this).val() = value
            }
        });
    })

    _componentPickadate();

    // $('.ibtnDel').each(function() {
    //     $(this).click(function() {
    //         console.log(1234);
    //         reIndexRowNumber();
    //     })        
    // });

    setTimeout(function() {
        console.log('sekali');
        let rows = document.querySelectorAll('spanx');
        countItems = rows.length;
    }, 200)

});