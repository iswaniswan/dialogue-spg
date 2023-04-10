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

class PengajuanIzin extends CI_Controller
{
	public $id_menu = '1002';

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
				'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/buttons.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/natural_sort.js',
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/index.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$data = [
			'dfrom' => $dfrom,
			'dto' => $dto
		];

		$this->logger->write('Membuka Menu '.$this->title);
		$this->template->load('main', $this->folder . '/index', $data);
	}

	/** List Data */
	public function serverside()
	{
		$dfrom = date('Y-m-d 00:00');
		$dto = date('Y-m-t 23:59');

		$dfrom_submit = $this->input->post('dfrom');
		$dto_submit = $this->input->post('dto');

		if ($dfrom_submit != null) {
			$dfrom = date('Y-m-d 00:00', strtotime($dfrom_submit));
		}

		if ($dto_submit != null) {
			$dto = date('Y-m-d 23:59', strtotime($dto_submit));
		}

		echo $this->mymodel->serverside($dfrom, $dto);
	}

	/** Redirect ke Form Tambah */
	public function add()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		// $data = check_role($this->id_menu, 1);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'global_assets/js/plugins/ui/moment/moment.min.js',
				'assets/js/' . $this->folder . '/add.js?v=1',
			)
		);
		$this->logger->write('Membuka Form Tambah '.$this->title);
		$this->template->load('main', $this->folder . '/add');
	}

	public function view()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
			// $data = check_role($this->id_menu, 1);
			// if (!$data) {
			// 	redirect(base_url(), 'refresh');
			// }

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js'
				)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

		$this->logger->write('Membuka Form View '.$this->title);
		$this->template->load('main', $this->folder . '/view', $data);
	}

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		// $data = check_role($this->id_menu, 1);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		$id_user = $this->input->post('id_user');
		if ($id_user == null) {
			$id_user = $this->session->userdata('id_user');
		}

		$id_jenis_izin = $this->input->post('id_jenis_izin');

		$d_pengajuan_mulai_tanggal = $this->input->post('d_pengajuan_mulai_tanggal');
		$d_pengajuan_mulai_pukul = $this->input->post('d_pengajuan_mulai_pukul');
		$d_pengajuan_mulai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_mulai_tanggal $d_pengajuan_mulai_pukul:00");		

		$d_pengajuan_selesai_tanggal = $this->input->post('d_pengajuan_selesai_tanggal');
		$d_pengajuan_selesai_pukul = $this->input->post('d_pengajuan_selesai_pukul');
		$d_pengajuan_selesai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_selesai_tanggal $d_pengajuan_selesai_pukul:00");		

		$e_remark = $this->input->post('e_remark');		

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();
		
		$this->mymodel->save(
			$id_user, 
			$id_jenis_izin, 
			$d_pengajuan_mulai=$d_pengajuan_mulai->format('Y-m-d H:i:s'),
			$d_pengajuan_selesai=$d_pengajuan_selesai->format('Y-m-d H:i:s'),
			$e_remark);

		$insert_id = $this->db->insert_id();

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $insert_id);

		$data['sukses'] = true;
		$data['ada'] = false;

		echo json_encode($data);
	}

	/** Redirect ke Form Edit */
	public function edit()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		// $data = check_role($this->id_menu, 3);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'global_assets/js/plugins/ui/moment/moment.min.js',
				'assets/js/' . $this->folder . '/edit.js?v=1',
			)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

		$this->logger->write('Membuka Form Edit '.$this->title);
		$this->template->load('main', $this->folder . '/edit', $data);
	}

	/** Update Data */
	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		// $data = check_role($this->id_menu, 3);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		$id = $this->input->post('id');
		$id_user = $this->input->post('id_user');
		if ($id_user == null) {
			$id_user = $this->session->userdata('id_user');
		}

		$id_jenis_izin = $this->input->post('id_jenis_izin');

		$d_pengajuan_mulai_tanggal = $this->input->post('d_pengajuan_mulai_tanggal');
		$d_pengajuan_mulai_pukul = $this->input->post('d_pengajuan_mulai_pukul');
		$d_pengajuan_mulai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_mulai_tanggal $d_pengajuan_mulai_pukul:00");		

		$d_pengajuan_selesai_tanggal = $this->input->post('d_pengajuan_selesai_tanggal');
		$d_pengajuan_selesai_pukul = $this->input->post('d_pengajuan_selesai_pukul');
		$d_pengajuan_selesai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_selesai_tanggal $d_pengajuan_selesai_pukul:00");		

		$e_remark = $this->input->post('e_remark');

		$e_remark = $this->input->post('e_remark');

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();               

		$this->mymodel->update(
			$id_user, 
			$id_jenis_izin, 
			$d_pengajuan_mulai=$d_pengajuan_mulai->format('Y-m-d H:i:s'),
			$d_pengajuan_selesai=$d_pengajuan_selesai->format('Y-m-d H:i:s'),
			$e_remark, 
			$id);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $id);

		$data['sukses'] = true;
		$data['ada'] = false;

		echo json_encode($data);
	}

	/** Update Status */
	public function changestatus()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$id 		= $this->input->post('id', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
			);
		} else {
			/** Jika Belum Ada Update Data */
			$this->db->trans_begin();
			$this->mymodel->changestatus($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update Status ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function get_list_jenis_izin()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_list_jenis_izin($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_izin_name),
			);
		}
		echo json_encode($filter);
	}

	public function approvement()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'assets/js/' . $this->folder . '/approve.js?v=1',
			)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

		$this->logger->write('Membuka Form Edit '.$this->title);
		$this->template->load('main', $this->folder . '/approve', $data);		
	}

	public function approve()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 5);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$id = $this->input->post('id', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
			);
		} else {
			/** Jika Belum Ada Update Data */
			$this->db->trans_begin();
			$this->mymodel->approve($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Approve ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function reject()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 5);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$id = $this->input->post('id', TRUE);
		$text = $this->input->post('text', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
			);
		} else {
			/** Jika Belum Ada Update Data */
			$this->db->trans_begin();
			$this->mymodel->reject($id, $text);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Reject ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function cancel()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		// $data = check_role($this->id_menu, 5);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }
		
		$id = $this->input->post('id');		

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();
		$this->mymodel->cancel($id);
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);	
			return;
		} 
		
		$this->db->trans_commit();
		$this->logger->write('Reject ' . $this->title . ' Id : ' . $id);
		$data['sukses'] = true;
		$data['ada'] = false;

		echo json_encode($data);
	}

	public function export_excel()
	{
		$_dfrom = $this->uri->segment(3);
		$_dto = $this->uri->segment(4);

		$dfrom = date('Y-m-d', strtotime($_dfrom));
		$dto = date('Y-m-d', strtotime($_dto));

		$query = $this->mymodel->export_excel($dfrom, $dto);

		$spreadsheet = new Spreadsheet;
		$sharedStyle1 = new Style();
		$sharedStyle2 = new Style();
		$sharedStyle3 = new Style();
		$conditional3 = new Conditional();
		$spreadsheet->getActiveSheet()->getStyle('B2')->getAlignment()->applyFromArray(
			[
				'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
				'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER, 'textRotation' => 0, 'wrapText' => TRUE
			]
		);

		$sharedStyle1->applyFromArray(
			[
				'alignment' => [
					'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
					'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
				],
				'borders' => [
					'bottom' => ['borderStyle' => Border::BORDER_THIN],
					'right' => ['borderStyle' => Border::BORDER_THIN],
				],
			]
		);

		$sharedStyle2->applyFromArray(
			[
				'font' => [
					'name'  => 'Arial',
					'bold'  => false,
					'italic' => false,
					'size'  => 10
				],
				'borders' => [
					'top'    => ['borderStyle' => Border::BORDER_THIN],
					'bottom' => ['borderStyle' => Border::BORDER_THIN],
					'left'   => ['borderStyle' => Border::BORDER_THIN],
					'right'  => ['borderStyle' => Border::BORDER_THIN]
				],
				'alignment' => [
					'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
				],
			]
		);
            
        $sharedStyle3->applyFromArray(
            [
                'alignment' => [
                'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
                'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
                ],
            ]
        );

        $spreadsheet->getDefaultStyle()
			->getFont()
			->setName('Calibri')
			->setSize(9);

        foreach(range('A','N') as $columnID) {
          $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A1', "Pengajuan Izin $_dfrom - $_dto");		
		$spreadsheet->getActiveSheet()->getRowDimension('1')->setRowHeight(32);

		$spreadsheet->getActiveSheet()->mergeCells("A1:H1");
		$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:H2');

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A2', 'No')
					->setCellValue('B2', 'Nama')
					->setCellValue('C2', 'Jenis Izin')
					->setCellValue('D2', 'Tanggal Mulai')
					->setCellValue('E2', 'Tanggal Akhir')
					->setCellValue('F2', 'Keterangan')
					->setCellValue('G2', 'Status')
					->setCellValue('H2', 'Keterangan Tolak');

		$kolom = 3;
		$nomor = 1;
		foreach($query->result() as $row) {

			$id_user = $row->id_user;
            $atasan = $this->mymodel->get_user_atasan($id_user);
            $nama_atasan = "";
            if ($atasan->row() != null) {
                $nama_atasan = $atasan->row()->e_nama;
            }

            $status = "Wait Approval $nama_atasan";

            if ($row->d_reject != '') {
                $status = 'Rejected';  
            }            

            if ($row->d_approve != '') {
                $status = 'Approve';
            }


            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->e_nama)
                        ->setCellValue('C' . $kolom, $row->e_izin_name)
                        ->setCellValue('D' . $kolom, $row->d_pengajuan_mulai)
						->setCellValue('E' . $kolom, $row->d_pengajuan_selesai)
                        ->setCellValue('F' . $kolom, $row->e_remark)
						->setCellValue('G' . $kolom, $status)
						->setCellValue('H' . $kolom, $row->e_remark_reject);

            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A'.$kolom.':H'.$kolom);

			$kolom++;
			$nomor++;
        }

		$spreadsheet->getActiveSheet()->setAutoFilter("A2:H$kolom");

        $writer = new Xls($spreadsheet);
        $nama_file = "Pengajuan Izin.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');
	}

}