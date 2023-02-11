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

class Saldo extends CI_Controller
{
	public $id_menu = '109';

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

		$this->color    	= $this->session->color;
		$this->fallcustomer = $this->session->F_allcustomer;
		$this->id_user    	= $this->session->id_user;
		$this->i_company 	= $this->session->i_company;
		$this->e_company_name 	= $this->session->e_company_name;
		$this->i_level = $this->session->i_level;

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('m' . $this->folder, 'mymodel');
	}

	/** Default Controllers */
	public function index()
	{
		add_js(
			array(
				'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/buttons.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/natural_sort.js',
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/index.js?v=1',
			)
		);
		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index');
	}

	/** List Data */
	public function serverside()
	{
		echo $this->mymodel->serverside();
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		// if ($cari != '') {
			$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => strtoupper($row->e_name),
				);
			}
		// } else {
		// 	$filter[] = array(
		// 		'id'   => null,
		// 		'text' => 'Cari Data Berdasarkan Nama',
		// 	);
		// }
		echo json_encode($filter);
	}
	

	/** Data Product */
	public function get_product()
	{
		$filter = [];
		$i_company = $this->input->get('i_company');
		$cari = str_replace("'", "", $this->input->get('q'));
		if ($cari != '') {
			$data = $this->mymodel->get_product($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id . ' - ' . $row->id_brand,
					'text' => $row->id . ' - ' . ucwords(strtolower($row->e_name)) . ' - ' . $row->e_brand_name,
				);
			}
		} else {
			$filter = [];
			$filter[] = array(
				'id'   => null,
				'text' => 'Pilih Perusahan / Cari Dengan Kode atau Nama Product',
			);
		}
		echo json_encode($filter);
	}

	public function get_detail_product()
	{
		header("Content-Type: application/json", true);
		$i_product = $this->input->post('i_product', TRUE);
		$i_brand = $this->input->post('i_brand', TRUE);
		/* $i_company = $this->input->post('i_company', TRUE); */
		$query  = array(
			'detail' => $this->mymodel->get_detail_product($i_product,$i_brand/* , $i_company */)->result_array()
		);
		echo json_encode($query);
	}

	/** Redirect ke Form Tambah */
	public function add()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
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
				'assets/js/' . $this->folder . '/add.js?v=1',
			)
		);

		$data = array(
			'company'	=> $this->mymodel->get_company_data(),
		);
		$this->logger->write('Membuka Form Tambah ' . $this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('periode', 'periode', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('icustomer', 'icustomer', 'trim|required|min_length[0]');
		$icustomer = $this->input->post('icustomer');
		$periode  = $this->input->post('periode');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan atau Update Data */
			$cek_data = $this->db->query("select * from tm_mutasi_saldoawal where id_customer = '$icustomer' and i_periode = '$periode'", FALSE);
			if ($cek_data->num_rows() > 0) {
				$data = array(
					'sukses' => false,
					'ada'	 => true,
				);
			} else {
				$this->db->trans_begin();
				$this->mymodel->save();
				if ($this->db->trans_status() === FALSE) {
					$this->db->trans_rollback();
					$data = array(
						'sukses' => false,
						'ada'	 => false,
					);
				} else {
					$this->db->trans_commit();
					$this->logger->write('Simpan Data ' . $this->title . ' : ' . $icustomer . '-' . $periode);
					$data = array(
						'sukses' => true,
						'ada'	 => false,
					);
				}				
			}
			
			
		}
		echo json_encode($data);
	}

	/** Redirect ke Form view */
	public function view()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 2);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				/* 'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/fixed_header.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/col_reorder.min.js', */
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/editdetail.js?v=1',
			)
		);

		$id = decrypt_url($this->uri->segment(3));
		$i_periode = decrypt_url($this->uri->segment(4));
		$id_customer = decrypt_url($this->uri->segment(5));
		if ($id_customer!='') {
			$e_customer_name = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$id_customer' ", FALSE)->row()->e_customer_name;
		}else{
			$e_customer_name = '';
		}
		$data = array(
			'data' 				=> $this->mymodel->getdata($id)->row(),
			'datadetail'		=> $this->mymodel->getdatadetail($id)->result_array(),
			'periode'			=> $i_periode,
			'id_customer'		=> $id_customer,
			'e_customer_name'	=> $e_customer_name,
		);
		$this->logger->write('Membuka Form Edit Detail' . $this->title);
		$this->template->load('main', $this->folder . '/view', $data);
	}

	/** Redirect ke Form Approvement */
	public function approvement()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 2);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/fixed_header.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/col_reorder.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/editdetail.js?v=1',
			)
		);

		$id = decrypt_url($this->uri->segment(3));
		$i_periode = decrypt_url($this->uri->segment(4));
		$id_customer = decrypt_url($this->uri->segment(5));
		if ($id_customer!='') {
			$e_customer_name = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$id_customer' ", FALSE)->row()->e_customer_name;
		}else{
			$e_customer_name = '';
		}
		$data = array(
			'data' 				=> $this->mymodel->getdata($id)->row(),
			'datadetail'		=> $this->mymodel->getdatadetail($id)->result_array(),
			'periode'			=> $i_periode,
			'id_customer'		=> $id_customer,
			'e_customer_name'	=> $e_customer_name,
		);
		$this->logger->write('Membuka Form Edit Detail' . $this->title);
		$this->template->load('main', $this->folder . '/approve', $data);
	}

	/** Redirect ke Form Edit */
	public function edit()
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
				/* 'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/fixed_header.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/col_reorder.min.js', */
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/editdetail.js?v=1',
			)
		);

		$id = decrypt_url($this->uri->segment(3));
		$i_periode = decrypt_url($this->uri->segment(4));
		$id_customer = decrypt_url($this->uri->segment(5));
		if ($id_customer!='') {
			$e_customer_name = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$id_customer' ", FALSE)->row()->e_customer_name;
		}else{
			$e_customer_name = '';
		}
		$data = array(
			'data' 				=> $this->mymodel->getdata($id)->row(),
			'datadetail'		=> $this->mymodel->getdatadetail($id)->result_array(),
			'periode'			=> $i_periode,
			'id_customer'		=> $id_customer,
			'e_customer_name'	=> $e_customer_name,
		);
		$this->logger->write('Membuka Form Edit Detail' . $this->title);
		$this->template->load('main', $this->folder . '/editdetail', $data);
	}

	/** Update Data */
	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('id_customer', 'id_customer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('i_periode', 'i_periode', 'trim|required|min_length[0]');

		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan atau Update Data */
			$this->db->trans_begin();
			$this->mymodel->update_detail();
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update Data ' . $this->title);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
		}
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

	/** Transfer Product */
	public function transfer()
	{
		/** Cek Hak Akses, Apakah User Bisa Input */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		// $this->form_validation->set_rules('icompany', 'icompany', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('id_customer', 'id_customer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('i_periode', 'i_periode', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Jika Belum Ada Update Data */
			$this->db->trans_begin();
			$this->mymodel->transfer();
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Tranfer Upload Data ' . $this->title);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
		}
		echo json_encode($data);
	}

	public function upload()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/uploaders/fileinput/fileinput.min.js',
				'assets/js/' . $this->folder . '/upload.js?v=1',
			)
		);

		$data = array(
			'company' => $this->db->get_where('tr_company', ['f_status' => 't']),
		);
		$this->logger->write('Membuka Form Upload ' . $this->title);
		$this->template->load('main', $this->folder . '/upload', $data);
	}


	public function export()
	{
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$i_periode = $this->uri->segment(4);

		$query = $this->mymodel->exportdata();

		if ($query->num_rows() > 0) {

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
			$h = 1;
			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue("A$h", '#ID_Perusahaan')
				->setCellValue("B$h", 'Nama Perusahaan')
				->setCellValue("C$h", 'Kode Barang')
				->setCellValue("D$h", 'Nama Barang')
				->setCellValue("E$h", 'Brand')
				->setCellValue("F$h", 'Qty');

			$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, "A$h:F$h");

			$kolom = 2;
			$nomor = 1;
			foreach ($query->result() as $row) {
				$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A' . $kolom, trim($row->i_company))
					->setCellValue('B' . $kolom, trim($row->e_company_name))
					->setCellValue('C' . $kolom, trim($row->i_product))
					->setCellValue('D' . $kolom, trim(ucwords(strtolower($row->e_product_name))))
					->setCellValue('E' . $kolom, $row->e_brand_name)
					->setCellValue('F' . $kolom, $row->n_saldo);
				$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A' . $kolom . ':F' . $kolom);

				$kolom++;
				$nomor++;
			}
			$writer = new Xls($spreadsheet);
			$nama_file = "Saldo_Awal_$i_periode.xls";
			header('Content-Type: application/vnd.ms-excel');
			header('Content-Disposition: attachment;filename=' . $nama_file . '');
			header('Cache-Control: max-age=0');
			$writer->save('php://output');
		}
	}

	public function prosesupload()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id_customer', 'id_customer', 'trim|required|min_length[0]');
		$id_customer = $this->input->post('id_customer', TRUE);
		$year = $this->input->post('year', TRUE);
		$month = $this->input->post('month', TRUE);
		$i_periode = $year.$month;

		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/* $filename    = "Saldo_Awal.xls";

			$config = array(
				'upload_path'   => "./upload/",
				'allowed_types' => "xls|xlsx|ods|csv",
				'file_name'     => $filename,
				'overwrite'     => true
			);

			$this->load->library('upload', $config);
			if ($this->upload->do_upload("userfile")) {
				$data = array('upload_data' => $this->upload->data());
				$this->logger->write('Upload Saldo Awal, Id Customer : ' . $id_customer);

				$data =  array(
					'sukses'    => true,
					'id'		=> encrypt_url($id_customer)
				);
			} else {
				$data =  array(
					'sukses' => false,
				);
			} */


			/* $filename 	= $_FILES['userfile']['name'];
			$upload_dir = ".upload";
			$tmp_file = $_FILES['userfile']['tmp_name'];
			$destination = "./upload/".$filename;
			if (file_exists($uploadedFile)) {
				echo "file uploaded to temp dir";
			} else {
				echo "file upload failed";
			}

			if (move_uploaded_file($uploadedFile, $destination)) {
				echo "upload complete";
			} else {
				echo "move_uploaded_file failed";
			} */

			$filename = $_FILES['userfile']['name'];
			$tmp_file = $_FILES['userfile']['tmp_name'];

			if (!empty($filename)) {
				$filename = str_replace(' ', '_', $filename);
				$exsten	  = explode('.', $filename)[1];

				if ($tmp_file != "") {
					$kop = "./upload/" . $filename;
					$pattern = "/^.*\.(" . $exsten . ")$/i";
					if (preg_match_all($pattern, $kop) >= 1) {
						if (move_uploaded_file($tmp_file, $kop)) {
							@chmod("./upload/" . $filename, 0777);
							$data =  array(
								'sukses'    => true,
								'id'		=> encrypt_url($id_customer),
								'filename'	=> $filename,
								'periode'	=> $i_periode
							);
						} else {
							$data =  array(
								'sukses' 	=> false,
								'id'		=> '',
								'filename'	=> '',
								'periode'	=> $i_periode
							);
						}
					} else {
						$data =  array(
							'sukses' 	=> false,
							'id'		=> '',
							'filename'	=> '',
							'periode'	=> $i_periode
						);
					}
				} else {
					$data =  array(
						'sukses' 	=> false,
						'id'		=> '',
						'filename'	=> '',
						'periode'	=> $i_periode
					);
				}
			}
		}
		echo json_encode($data);
	}

	/** Redirect ke Form Detail Upload */
	public function detailupload()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				/* 'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/fixed_header.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/col_reorder.min.js', */
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/uploaddetail.js?v=1',
			)
		);
		$id_customer = decrypt_url($this->uri->segment(3));
		$filename = $this->uri->segment(4);
		$periode = $this->uri->segment(5);

		if ($id_customer!='') {
			$e_customer_name = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$id_customer' ", FALSE)->row()->e_customer_name;
		}else{
			$e_customer_name = '';
		}

		/* $filename = "Product_Price_" . $i_company . ".xls"; */

		$inputFileName = './upload/' . $filename;
		$spreadsheet   = IOFactory::load($inputFileName);
		$worksheet     = $spreadsheet->getActiveSheet();
		$sheet         = $spreadsheet->getSheet(0);
		$hrow          = $sheet->getHighestDataRow('A');

		$array 		   = [];
		for ($n = 2; $n <= $hrow; $n++) {
			$i_company 	= $spreadsheet->getActiveSheet()->getCell('A' . $n)->getValue();
			$e_company 	= strtoupper($spreadsheet->getActiveSheet()->getCell('B' . $n)->getValue());
			$i_product 	= trim($spreadsheet->getActiveSheet()->getCell('C' . $n)->getValue());
			$e_product 	= ucwords(strtolower(trim($spreadsheet->getActiveSheet()->getCell('D' . $n)->getValue())));
			$brand   	= $spreadsheet->getActiveSheet()->getCell('E' . $n)->getValue();
			$qty   		= $spreadsheet->getActiveSheet()->getCell('F' . $n)->getValue();
			if ($qty > 0) {
				$cek_produk = $this->mymodel->cek_produk($i_product, $i_company);
				if ($i_product != '' && $cek_produk->num_rows() > 0) {
					$array[] = array(
						'i_company'  		=> $i_company,
						'e_company'  		=> $e_company,
						'i_product'  		=> $i_product,
						'e_product'  		=> $e_product,
						'brand'      		=> $brand,
						'qty'      	 		=> $qty,
					);
				} else {
					$array[] = array(
						'i_company'  		=> $i_company,
						'e_company'  		=> $e_company,
						'i_product'  		=> '',
						'e_product'  		=> '',
						'brand'      		=> $brand,
						'qty'      	 		=> 0,
					);
				}
			}
		}

		$data = array(
			'company' 	 		=> $this->db->get_where('tr_company', ['f_status' => 't']),
			'i_company'	 		=> $i_company,
			'datadetail' 		=> $array,
			'id_customer'		=> $id_customer,
			'e_customer_name' 	=> $e_customer_name,
			'periode'			=> $periode,
		);
		$this->logger->write('Membuka Form Detail Upload ' . $this->title);
		$this->template->load('main', $this->folder . '/uploaddetail', $data);
	}

	/** Cancel */
	public function cancel()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 4);
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
			$this->mymodel->cancel($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Cancel ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	/** Approve */
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
}
