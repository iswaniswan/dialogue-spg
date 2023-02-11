function hetang() {
    var bruto = 0;
    var diskonrp = 0;
    var diskonpersen = 0;
    var dpp = 0;
    var ppn = 0;
    var netto = 0;
    for (var i = 1; i <= $("#jml").val(); i++) {
        if (typeof $("#i_product" + i).val() != "undefined") {
            if (!isNaN(parseFloat($("#qty" + i).val()))) {
                var qty = parseFloat($("#qty" + i).val());
            } else {
                var qty = 0;
            }
            var jumlah = formatulang($("#harga" + i).val()) * qty;
            if (!isNaN(parseFloat($("#diskon" + i).val()))) {
                var diskon = $("#diskon" + i).val();
            } else {
                var diskon = 0;
            }
            var ndiskon = parseFloat(jumlah * (diskon / 100));
            var vjumlah = jumlah;

            /*$('#vtotaldiskon'+i).val(vtotaldis);
            $('#vtotal'+i).val(formatcemua(jumlah));
            $('#vtotalnet'+i).val(formatcemua(vtotal));*/
            /* totaldis += vtotaldis;
            vjumlah += jumlah; */

            bruto += jumlah;
            diskonrp += ndiskon;
        }
    }
    diskonpersen = (diskonrp / bruto) * 100;
    dpp = bruto - diskonrp;
    ppn = dpp * 0.1;
    netto = Math.round(dpp + ppn);
    $("#sbruto").text(formatcemua(bruto));
    $("#bruto").val(bruto);
    $("#sdiskon").text(formatcemua(diskonrp));
    $("#diskon").val(diskonrp);
    $("#sdiskonpersen").text(formatcemua(diskonpersen));
    $("#diskonpersen").val(diskonpersen);
    $("#sdpp").text(formatcemua(dpp));
    $("#dpp").val(dpp);
    $("#sppn").text(formatcemua(ppn));
    $("#ppn").val(ppn);
    $("#snetto").text(formatcemua(netto));
    $("#netto").val(netto);
}

document.addEventListener("DOMContentLoaded", function() {
    hetang();
});