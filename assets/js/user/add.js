var Switch = (function() {
    // Bootstrap switch
    var _componentBootstrapSwitch = function() {
        if (!$().bootstrapSwitch) {
            console.warn("Warning - bootstrap_switch.min.js is not loaded.");
            return;
        }

        // Initialize
        $(".form-input-switch").bootstrapSwitch({
            onSwitchChange: function(state) {
                if ($(this).is(":checked")) {
                    $(".cover").attr("hidden", true);
                    $("#tablecover tr:gt(0)").remove();
                    $("#jml").val(0);
                } else {
                    $(".cover").attr("hidden", false);
                }
                if (state) {
                    $(this).valid(true);
                } else {
                    $(this).valid(false);
                }
            },
        });
    };

    //
    // Return objects assigned to module
    //

    return {
        init: function() {
            _componentBootstrapSwitch();
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
    var i = $("#jml").val();
    $("#addrow").on("click", function() {
        i++;
        var no = $("#tablecover tr").length;
        $("#jml").val(i);
        var newRow = $("<tr>");
        var cols = "";
        cols += `<td class="text-center"><spanx id="snum${i}">${no}</spanx></td>`;
        cols += `<td>
                    <select data-urut="${i}" class="form-control form-control-sm form-control-select2"
                            data-container-css-class="select-sm" 
                            name="i_customer[${i}][id]" 
                            id="i_customer${i}" 
                            data-fouc
                            required>
                    </select>
                </td>`;
        cols += `<td>
                    <select data-urut="${i}" class="form-control form-control-sm form-control-select2" 
                            data-container-css-class="select-sm" 
                            name="i_customer[${i}][i_brand][]" id="i_brand${i}"
                            multiple="true" 
                            data-fouc 
                            required>
                    </select>
                </td>`;
        cols += `<td><span id="address${i}"></span></td>`;
        cols += `<td><span id="owner${i}"></span></td>`;
        cols += `<td><span id="type${i}"></span></td>`;
        cols += `<td class="text-center"><b><i title="Hapus Baris" class="icon-cancel-circle2 text-danger ibtnDel"></i></b></td>`;
        newRow.append(cols);
        $("#tablecover").append(newRow);
        $("#i_customer" + i)
            .select2({
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
            })
            .change(function(event) {
                var z = $(this).data("urut");
                var ada = false;
                for (var x = 1; x <= $("#jml").val(); x++) {
                    if ($(this).val() != null) {
                        if ($(this).val() == $("#i_customer" + x).val() && z != x) {
                            swalInit("Maaf :(", "Pelanggan tersebut sudah ada :(", "error");
                            ada = true;
                            break;
                        }
                    }
                }
                if (!ada) {
                    $.ajax({
                        type: "POST",
                        url: base_url + controller + "/get_detail_customer",
                        data: {
                            i_customer: $(this).val(),
                        },
                        dataType: "json",
                        success: function(data) {
                            $("#address" + z).text(data["detail"][0]["e_customer_address"]);
                            $("#owner" + z).text(data["detail"][0]["e_customer_owner"]);
                            $("#type" + z).text(data["detail"][0]["e_type"]);
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

            /** cari brand */
            $("#i_brand" + i).select2({
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
    });

    /*----------  Hapus Baris Data Saudara  ----------*/

    $("#tablecover").on("click", ".ibtnDel", function(event) {
        $(this).closest("tr").remove();

        $("#jml").val(i);
        var obj = $("#tablecover tr:visible").find("spanx");
        $.each(obj, function(key, value) {
            id = value.id;
            $("#" + id).html(key + 1);
        });
    });
});

document.addEventListener("DOMContentLoaded", function() {
    Switch.init();
    Detail.init();
    $(".form-control-select2").select2({
        minimumResultsForSearch: Infinity,
    });

    $(".select-search").select2();

    $("#fpkp").on("change", function() {
        if ($(this).val() == "f") {
            $("#ecustomernpwp").attr("disabled", true);
            $("#eaddressnpwp").attr("disabled", true);
        } else {
            $("#ecustomernpwp").attr("disabled", false);
            $("#eaddressnpwp").attr("disabled", false);
        }
    });

    $("#submit").on("click", function() {
        let checkbox = $(".form-input-switch:checkbox:checked").length;
        let tabel = $("#tablecover tr").length;

        if (checkbox < 1 && tabel <= 1) {
            swalInit("Maaf :(", "Item Toko Harus Diisi! :(", "error");
            return false;
        }

        var form = $(".form-validation").valid();
        if (form) {
            sweetadd(controller);
        }
    });
});


$(document).ready(function() {
    $('#ilevel').change(function() {
        $('#id_atasan').val(null).trigger('change');
    })
    
    $('#id_atasan').select2({
        allowClear: true,
        ajax: {
            url: 'get_list_atasan',
            dataType: 'json',
            delay: 250,
            data: function (params) {
                var query = {
                    q: params.term,
                    i_level: $('#ilevel').val()
                }
                return query;
            },
            processResults: function (result) {
                return {
                    results: result
                };
            },
            cache: false
        }
    });

});