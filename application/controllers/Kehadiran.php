<?php
defined('BASEPATH') or exit('No direct script access allowed');

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xls;
use PhpOffice\PhpSpreadsheet\Style\Border;
/* use PhpOffice\PhpSpreadsheet\Style\Fill; */
use PhpOffice\PhpSpreadsheet\Style\Style;
/* use PhpOffice\PhpSpreadsheet\Style\Alignment; */
use PhpOffice\PhpSpreadsheet\Style\Conditional;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\IOFactory;

class Kehadiran extends CI_Controller
{
	public $id_menu = '1004';

	const TIDAK_MASUK = 2;
	const SAKIT = 5;
	const TERLAMBAT = 1;
	const PULANG_CEPAT = 4;

	public function __construct()
	{
		parent::__construct();
		cek_session();

		/** Cek Hak Akses, Apakah User Bisa Read */
		$data = check_role($this->id_menu, 2);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		/** Deklarasi Nama Folder, Title dan Icon */
		$this->folder 	= $data->e_folder;
		$this->title	= $data->e_menu;
		$this->icon		= $data->icon;

		$this->color    = $this->session->color;
		$this->i_level    = $this->session->i_level;

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('m' . $this->folder, 'mymodel');

		set_current_active_menu($this->title);
	}

	/** Default Controllers */
	public function index()
	{
		$dfrom = date('Y-m-01');
		$dto = date('Y-m-t');

		$dfrom_submit = $this->input->post('dfrom_submit');
		$dto_submit = $this->input->post('dto_submit');

		if ($dfrom_submit != null) {
			$dfrom = $dfrom_submit;
		}

		if ($dto_submit != null) {
			$dto = $dto_submit;
		}
		
		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/fullcalendar-6.1.5/index.global.min.js',
				'global_assets/js/plugins/ui/moment/moment.min.js',
				'assets/js/' . $this->folder . '/index.js?v=1',
			)
		);

		$data = [
			'dfrom' => $dfrom,
			'dto' => $dto
		];

		$this->logger->write('Membuka Menu '.$this->title);
		$this->template->load('main', $this->folder . '/index', $data);
	}

	public function get_event_colors()
	{
		$TIDAK_MASUK = '#6a737b';
		$SAKIT = '#ff6908';
		$TERLAMBAT = '#6b0f24';
		$PULANG_CEPAT = '#97824b';
		$LIBUR = '#ff0000';

		$colors = [
			static::TIDAK_MASUK => $TIDAK_MASUK,
			static::SAKIT => $SAKIT,
			static::TERLAMBAT => $TERLAMBAT,
			static::PULANG_CEPAT => $PULANG_CEPAT,
		];

		return $colors;
	}
	
	public function get_events()
	{
		$events = [];

		$colors = $this->get_event_colors();
		$id_user = $this->session->userdata('id_user');

		$all_events = $this->mymodel->get_all_izin($id_user);

		foreach ($all_events->result() as $event) {

			$start = date('Y-m-d', strtotime($event->d_pengajuan_mulai));
			$end = date('Y-m-d', strtotime($event->d_pengajuan_selesai));

			$time_start = date('H:i', strtotime($event->d_pengajuan_mulai));
			$time_end = date('H:i', strtotime($event->d_pengajuan_selesai));

			$color = @$colors[$event->id_jenis_izin] ?? '#000'; 

			$status = 'Reject';
			$e_remark_reject = $event->e_remark_reject;
			if ($event->d_approve != null) {
				$status = 'Approve';
			}

			$_events = [
				'title' => $event->e_izin_name,
				'start' => $start,
				'end' => $end,
				'e_remark' => $event->e_remark,
				'time_start' => $time_start,
				'time_end' => $time_end,
				'color' => $color,
				'status' => $status,
				'e_remark_reject' => $e_remark_reject
			];

			$events[] = $_events;
		}

		/** data kehadiran */
		$all_hadir = $this->mymodel->get_kehadiran_per_user($id_user);
		foreach ($all_hadir->result() as $hadir) {

			$time_start = date('H:i', strtotime($hadir->d_datang));
			$time_end = date('H:i', strtotime($hadir->d_pulang));

			$_events = [
				'title' => 'Hadir',
				'start' => $hadir->d_hadir,
				'end' => $hadir->d_hadir,
				'e_remark' => null,
				'time_start' => $time_start,
				'time_end' => $time_end,
				'color' => '#2baf2b',
				'status' => 'HADIR',
				'e_remark_reject' => null
			];

			$events[] = $_events;
		}

		echo json_encode($events);
	}

}