var countItems = 0;

function reIndexRowNumber() {
    let rows = document.querySelectorAll('spanx');
    
    for (i=0; i<rows.length; i++) {
        rows[i].outerHTML = i+1;
    }
}

var Plugin = (function() {
    var _componentPickadate = function() {
        if (!$().pickadate) {
            console.warn("Warning - picker.js and/or picker.date.js is not loaded.");
            return;
        }

        // Accessibility labels
        var today = new Date();
        var date =
            today.getFullYear() +
            "," +
            (today.getMonth() + 1) +
            "," +
            today.getDate();
        $(".date").pickadate({
            labelMonthNext: "Go to the next month",
            labelMonthPrev: "Go to the previous month",
            labelMonthSelect: "Pick a month from the dropdown",
            labelYearSelect: "Pick a year from the dropdown",
            selectMonths: true,
            selectYears: true,
            formatSubmit: "yyyy-mm-dd",
            format: "yyyy-mm-dd",
            min: [2021, 1, 1],
            max: [date],
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentPickadate();
        },
    };
})();

var swalInit = swal.mixin({
    buttonsStyling: false,
    confirmButtonClass: "btn btn-sm btn-outline bg-success-800 text-success-800 border-success-800",
    cancelButtonClass: "btn btn-sm btn-outline bg-slate-800 text-slate-800 border-slate-800",
    confirmButtonText: '<i class="icon-thumbs-up3"></i> Ya',
    cancelButtonText: '<i class="icon-thumbs-down3"></i> Tidak',
});

var controller = $("#path").val();
var Detail = $(function() {    
    $("#addrow").on("click", function() {                
        const i = countItems++;
        
        let newRow = $("<tr>");

        let cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${i+1}</spanx></td>`;
        cols += `<td>
                    <select data-urut="${i}" class="form-control form-control-sm form-control-select2 form-input-product" 
                        data-container-css-class="select-sm" 
                        name="items[${i}][id_product]" 
                        id="id_product${i}" required data-fouc>
                    </select>
                </td>`;
        cols += `<td>
                    <input type="number" required class="form-control form-control-sm" min="1" 
                        placeholder="Qty"
                        id="qty${i}" 
                        name="items[${i}][qty]">
                </td>`;
        cols += `<td>
                    <div class="input-group">
                        <div class="input-group-prepend">
                            <span class="input-group-text">Rp.</span>
                        </div>
                        <input type="text" class="form-control"
                                name="items[${i}][price]" id="price${i}" autocomplete="off" 
                                value="" required>
                    </div>
                </td>`;
        cols += `<td>
                    <div class="input-group">
                        <div class="input-group-prepend">
                            <span class="input-group-text">Rp.</span>
                        </div>
                        <input type="text" class="form-control form-control-sm form-input-total"
                            name="items[${i}][total]"
                            id="total${i}" readonly>
                    </div>					
				</td>`;
        cols += `<td class="text-center" width="3%;">
                    <b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b>
                </td>`;

        newRow.append(cols);

        $("#tablecover").append(newRow);

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
        }).change(function(event) {
            let isDuplicate = false;
            let products = [];
            $(".form-input-product").each(function() {
                const idProduct = $(this).val();
                if (products.includes(idProduct)) {
                    isDuplicate = true;
                }
                products.push($(this).val());
            });

            if (isDuplicate) {
                $(this).val("");
                $(this).html("");
                swalInit("Maaf :(", "Kode Barang tersebut sudah ada :(", "error");
            }
        });

        let elementQty = document.getElementById("qty"+i);
        elementQty.addEventListener("keyup", function(e) {
            calculateTotal(i);
            calculateGrandTotal();
        })

        elementQty.addEventListener("change", function(e) {
            calculateTotal(i);
            calculateGrandTotal();
        })

        let elementPrice = document.getElementById("price"+i);
        elementPrice.addEventListener("keyup", function(e) {
            elementPrice.value = formatRupiah(this.value, "");
            calculateTotal(i);
            calculateGrandTotal();
        });   

        buildElementGrandTotalHarga($('#tablecover'));
    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tablecover").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();  
        countItems--;
        reIndexRowNumber();
    });
});

// function hetang() {
//     var bruto = 0;
//     var diskonrp = 0;
//     var diskonpersen = 0;
//     var dpp = 0;
//     var ppn = 0;
//     var netto = 0;
//     for (var i = 1; i <= $("#jml").val(); i++) {
//         if (typeof $("#i_product" + i).val() != "undefined") {
//             if (!isNaN(parseFloat($("#qty" + i).val()))) {
//                 var qty = parseFloat($("#qty" + i).val());
//             } else {
//                 var qty = 0;
//             }
//             var jumlah = formatulang($("#harga" + i).val()) * qty;
//             if (!isNaN(parseFloat($("#diskon" + i).val()))) {
//                 var diskon = $("#diskon" + i).val();
//             } else {
//                 var diskon = 0;
//             }
//             var ndiskon = parseFloat(jumlah * (diskon / 100));
//             var vjumlah = jumlah;

//             /*$('#vtotaldiskon'+i).val(vtotaldis);
//             $('#vtotal'+i).val(formatcemua(jumlah));
//             $('#vtotalnet'+i).val(formatcemua(vtotal));*/
//             /* totaldis += vtotaldis;
//             vjumlah += jumlah; */

//             bruto += jumlah;
//             diskonrp += ndiskon;
//         }
//     }
//     diskonpersen = (diskonrp / bruto) * 100;
//     dpp = bruto - diskonrp;
//     ppn = dpp * 0.1;
//     netto = Math.round(dpp + ppn);
//     $("#sbruto").text(formatcemua(bruto));
//     $("#bruto").val(bruto);
//     $("#sdiskon").text(formatcemua(diskonrp));
//     $("#diskon").val(diskonrp);
//     $("#sdiskonpersen").text(formatcemua(diskonpersen));
//     $("#diskonpersen").val(diskonpersen);
//     $("#sdpp").text(formatcemua(dpp));
//     $("#dpp").val(dpp);
//     $("#sppn").text(formatcemua(ppn));
//     $("#ppn").val(ppn);
//     $("#snetto").text(formatcemua(netto));
//     $("#netto").val(netto);
// }


function calculateTotal(index) {
    let qty = document.getElementById('qty'+index).value;
    let price = document.getElementById('price'+index).value;

    if (qty == undefined || isNaN(qty) || parseInt(qty) <= 0 || qty == '') {
        qty = 1;
    }

    if (price == undefined || isNaN(price) || parseInt(price) <= 0 || price == '') {
        price = '0';
    }

    price = price.replace(".", "");
    price = parseInt(price);
    let total = price * qty;    

    document.getElementById('total'+index).value = formatRupiah(total.toString());
}

function calculateGrandTotal()
{
    let items = document.querySelectorAll('.form-input-total');
    let grandTotal = 0;
    for (i=0; i<items.length; i++) {
        let total = items[i].value.toString();
        if (total == '') {
            total = '0';
        }
        total = total.replace(".", "");
        total = total.replace(",", ".");
        grandTotal += parseFloat(total);
    }
    document.getElementById('grand_total_price').value = formatRupiah(grandTotal.toString());
}

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


const trGrandTotalHarga = `<tr style="border-top: 1px solid #ddd" id="tr_grand_total_price">
                            <td colspan="4">Grand Total Harga</td>
                            <td>
                                <div class="input-group">
                                    <div class="input-group-prepend">
                                        <span class="input-group-text">Rp.</span>
                                    </div>
                                    <input type="text" class="form-control"
                                            id="grand_total_price" value="0" readonly>
                                </div>
                            </td>
                            <td></td>
                        </tr>`;

function buildElementGrandTotalHarga(table) {
    $('#tr_grand_total_price').remove();
    table.append(trGrandTotalHarga);
    calculateGrandTotal();
}

function number() {
    $.ajax({
        type: "post",
        data: {
            tgl: $("#ddocument").val(),
        },
        url: base_url + controller + "/number",
        dataType: "json",
        success: function(data) {
            $("#idocument").val(data);
        },
        error: function() {
            swalInit("Maaf :(", "Ada kesalahan :(", "error");
        },
    });
}

document.addEventListener("DOMContentLoaded", function() {
    Plugin.init();
    Detail.init();
    number();
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
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

    $("#customeritem").select2({
        placeholder: "Cari Customer",
        width: "100%",
        allowClear: true,
        ajax: {
            url: base_url + controller + "/get_company",
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

    $("#ddocument").on("change", function() {
        number();
    });

    $("#submit").on("click", function() {
        let tabel = $("#tablecover tbody tr").length;
        let ada = false;

        if (tabel < 1) {
            swalInit("Maaf :(", "Isi item product minimal 1! :(", "error");
            return false;
        }

        $("#tablecover tbody tr td .harga").each(function() {
            if ($(this).val() <= 0) {
                ada = true;
            }
        });

        var form = $(".form-validation").valid();
        if (form) {
            if (!ada) {
                sweetadd(controller);
            } else {
                swalInit("Maaf :(", "Harga harus lebih besar dari 0 :(", "error");
            }
        }
    });
});