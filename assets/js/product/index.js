// Setup module
// ------------------------------

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val() + "/serverside";
    var link = $("#path").val();
    var linkadd = $("#path").val() + "/add";
    var column = 6;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    if (id_menu != "") {
        // datatabletransfer(controller, column, link, color);
        datatableadd(controller, column, linkadd, color);
    } else {
        datatable(controller, column);
    }
});