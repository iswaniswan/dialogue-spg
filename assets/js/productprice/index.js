// Setup module
// ------------------------------

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val() + "/serverside";
    var link = $("#path").val();
    var linkadd = $("#path").val() + "/add";
    var column = 8;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    if (id_menu != "") {
        datatableadd(controller, column, linkadd, color);
        //datatableupload(controller, column, link, color);
    } else {
        datatable(controller, column);
    }
});