// Setup module
// ------------------------------

document.addEventListener("DOMContentLoaded", function() {
    var controller = $("#path").val() + "/serverside";
    var link = $("#path").val();
    var column = 7;
    var id_menu = $("#id_menu").val();
    var color = $("#color").val();
    if (id_menu != "") {
        datatableupload(controller, column, link, color);
    } else {
        datatable(controller, column);
    }
});