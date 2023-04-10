// Setup module
// ------------------------------

document.addEventListener("DOMContentLoaded", function () {
    var controller = $("#path").val();
    var urlEvents = controller + '/get_events';

    var calendarEl = document.getElementById('calendar');
    var calendar = new FullCalendar.Calendar(calendarEl, {
        buttonHtml: {
            prev: '<i class="icon-arrow-left16"></i>',
            next: '<i class="icon-arrow-right16"></i>'
        },
        initialView: 'dayGridMonth',
        initialDate: moment().valueOf(),
        headerToolbar: {
          left: 'prev,next today',
          center: 'title',
          right: 'dayGridMonth,timeGridWeek,timeGridDay'
        },
        events: urlEvents,
        eventClick: function(info) {
          console.log(info);

          const params = {
            title: 'KEHADIRAN',
            jenis: info.event.title,
            e_remark: info.event.extendedProps.e_remark,
            time_start: info.event.extendedProps.time_start,
            time_end: info.event.extendedProps.time_end,
            status: info.event.extendedProps.status,
            e_remark_reject: info.event.extendedProps.e_remark_reject
          }
          showEventModal(params);
          // alert('Event: ' + info.event.title);
          // alert('Coordinates: ' + info.jsEvent.pageX + ',' + info.jsEvent.pageY);
          // alert('View: ' + info.view.type);
      
          // change the border color just for fun
          // info.el.style.borderColor = 'red';
        }
      });
    
    calendar.render();    
});

function showEventModal(params) {
  console.log(params);
  let title = params.title;
  let jenis = params.jenis;
  let e_remark = params?.e_remark;
  let time_start = params?.time_start;
  let time_end = params?.time_end;
  let status = params?.status;
  let e_remark_reject = params?.e_remark_reject;

  let modal = $('#modal-event');  

  modal.on('show.bs.modal', function() {
    $('#modal-title').text(title);
    $('#modal-jenis').text(jenis);
    $('#modal-time_start_end').text(`Pukul ${time_start} - ${time_end}`)
    $('#modal-e_remark').text(e_remark);
    $('#modal-status').text(status);
    $('#modal-e_remark_reject').text(e_remark_reject);
  })

  modal.modal('show');
}