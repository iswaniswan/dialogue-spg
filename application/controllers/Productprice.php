<?php
defined('BASEPATH') or exit('No direct script access allowed');

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xls;
use PhpOffice\PhpSpreadsheet\Style\Border;
/* use PhpOffice\PhpSpreadsheet\Style\Fill; */
use PhpOffice\PhpSpreadsheet\Style\Style;
/* use PhpOffice\PhpSpreadsheet\Style\Alignment; */
use PhpOffice\PhpSpreadsheet\Style\Protection;
use PhpOffice\PhpSpreadsheet\Cell\DataValidation;
use PhpOffice\PhpSpreadsheet\Style\Conditional;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\IOFactory;

class Productprice extends CI_Controller
{
	public $id_menu = '107';

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
		$this->i_level = $this->session->i_level;

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('m' . $this->folder, 'mymodel');

		set_current_active_menu($this->title);
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
				'assets/js/' . $this->folder . '/index.js',
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

	/** Data Company */
	public function get_company($id)
	{
		$data=$this->mymodel->get_company($id)->row()->i_company;
		echo json_encode($data);

		/* 
		$filter = [];
		$data=$this->mymodel->get_company($id);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->i_company,
			);
		}
		echo json_encode($filter);
		*/
	}

	/** Data Customer */
	public function get_customer()
	{
		$filter = [];
		$cari   = str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => ucwords(strtolower($row->e_name)),
				);
			}
		echo json_encode($filter);
	}

	/** Data Product sesuai user cover */
	public function get_product()
	{
		$filter = [];
		$id_customer = $this->input->get('id_customer');
		if ($id_customer == null) {
			echo json_encode($filter);
			return;
		}

		$cari = str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_product($cari, $id_customer);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => $row->i_product . ' - ' . ucwords(strtolower($row->e_name)) . ' - ' . ucwords(strtolower($row->brand))
			);
		} 
		echo json_encode($filter);
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
				'assets/js/' . $this->folder . '/add.js?v=' . strtotime(date('Y-m-d H:i:s')),
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

		$id_product = $this->input->post('id_product');
		$id_customer = $this->input->post('id_customer');
		$e_periode_year = $this->input->post('e_periode_year');
		$e_periode_month = $this->input->post('e_periode_month');
		$e_periode = $e_periode_year . $e_periode_month;

		$is_customer_price_exist = $this->mymodel->is_customer_price_exist($id_product, $id_customer, $e_periode);
		if ($is_customer_price_exist) {
			$response = [
				'sukses' => false,
				'ada'	 => true
			];

			echo json_encode($response);
			return;
		}
		
		/** Simpan atau Update Data */
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
			$this->logger->write("Simpan Data $this->title, id_product:'$id_product' - id_customer:'$id_customer'");
			$data = array(
				'sukses' => true,
				'ada'	 => false,
			);
		}

		echo json_encode($data);
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
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$id = decrypt_url($this->uri->segment(3));
		$i_company = decrypt_url($this->uri->segment(4));
		$id_customer = decrypt_url($this->uri->segment(5));
		$data = array(
			'data' => $this->mymodel->getdata($id, $i_company, $id_customer)->row(),
			'icompany'	=> $i_company,
			'company'	=> $this->mymodel->get_company_data(),
		);
		$this->logger->write('Membuka Form Edit ' . $this->title);
		$this->template->load('main', $this->folder . '/edit', $data);
	}

	/** Update Data */
	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}
		
		$id = $this->input->post('id');

		/** Simpan atau Update Data */
		$this->db->trans_begin();
		$this->mymodel->update();
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			$this->db->trans_commit();
			$this->logger->write('Update Data ' . $this->title . ' : ' . $id);
			$data = array(
				'sukses' => true,
				'ada'	 => false,
			);
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
		// $data = check_role($this->id_menu, 1);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

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
				'assets/js/' . $this->folder . '/upload.js',
			)
		);

		$sql = "SELECT * 
				FROM tr_customer 
				WHERE id_customer IN (
										SELECT id_customer 
										FROM tm_user_customer 
										WHERE id_user = $this->id_user
									)";
		$query_customer = $this->db->query($sql);

		$data = array(
			'customer' => $query_customer,
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

		$id_customer = $this->uri->segment(3);
		$e_periode = $this->uri->segment(4);

		$customer = $this->mymodel->get_customer_by_id($id_customer)->row();
		// $query = $this->mymodel->exportdata();
		$query = $this->mymodel->export_data_by_user_cover($id_customer, $e_periode);

		if ($query) {

			$spreadsheet = new Spreadsheet;
			$sharedStyle1 = new Style();
			$sharedStyle2 = new Style();
			$sharedStyle3 = new Style();
			$styleHeader = new Style();
			$styleTitle = new Style();
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
						'top' => ['borderStyle' => Border::BORDER_THIN],
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

			$styleHeader->applyFromArray(
				[
					'font' => [
						'name'  => 'Arial',
						'bold'  => true,
						'italic' => false,
						'size'  => 11
					],
					'borders' => [
						'top'    => ['borderStyle' => Border::BORDER_THIN],
						'bottom' => ['borderStyle' => Border::BORDER_THIN],
						'left'   => ['borderStyle' => Border::BORDER_THIN],
						'right'  => ['borderStyle' => Border::BORDER_THIN]
					],
					'alignment' => [
						'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
						'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
					],
				]
			);

			$styleTitle->applyFromArray(
				[
					'font' => [
						'name'  => 'Arial',
						'bold'  => true,
						'italic' => false,
						'size'  => 11
					],
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
		
			$text_periode = $this->e_periode_to_text($e_periode);
			$title = $customer->e_customer_name . ", Periode: $text_periode";

			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue('B1', $id_customer)
				->setCellValue('B2', $e_periode)
				->setCellValue('C1', $title)
				->setCellValue('A3', 'No')
				->setCellValue('B3', 'ID Barang')
				->setCellValue('C3', 'Kode')
				->setCellValue('D3', 'Nama')
				->setCellValue('E3', 'Brand')
				->setCellValue('F3', 'Harga');

			$spreadsheet->getActiveSheet()->duplicateStyle($styleHeader, 'A3:F3');

			// styling header
			$spreadsheet->getActiveSheet()->mergeCells('C1:F1');
			$spreadsheet->getActiveSheet()->duplicateStyle($styleTitle, 'C1:F1');
			// styling header end

			$sheet = $spreadsheet->getActiveSheet();
			foreach ($sheet->getColumnIterator() as $column) {
				$sheet->getColumnDimension($column->getColumnIndex())->setAutoSize(true);
			}

			$kolom = 4;
			$nomor = 1;			
			foreach ($query->result() as $row) {
				$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A' . $kolom, $nomor)
					->setCellValue('B' . $kolom, $row->id)
					->setCellValue('C' . $kolom, $row->i_product)
					->setCellValue('D' . $kolom, $row->e_name)
					->setCellValue('E' . $kolom, $row->brand)
					->setCellValue('F' . $kolom, $row->v_price);
				$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A' . $kolom . ':F' . $kolom);

				$kolom++;
				$nomor++;
			}

			// hide kolom B, 
			$spreadsheet->getActiveSheet()->getColumnDimension('B')->setCollapsed(true);
			$spreadsheet->getActiveSheet()->getColumnDimension('B')->setVisible(false);

			$spreadsheet->getActiveSheet()->getColumnDimension('F')->setAutoSize(false);
			$spreadsheet->getActiveSheet()->getColumnDimension('F')->setWidth(20);
										
			$default_format_rupiah = '[$Rp-421]#,##0.00;[RED]([$Rp-421]#,##0.00)';
			$spreadsheet->getActiveSheet()
							->getStyle('F')
							->getNumberFormat()
							->setFormatCode($default_format_rupiah);

			// lock cells
			$spreadsheet->getActiveSheet()->getProtection()->setSheet(true);
			$spreadsheet->getActiveSheet()->getProtection()->setPassword('THEPASSWORD');
			$spreadsheet->getActiveSheet()->getStyle("F4:F5000")->getProtection()->setLocked(Protection::PROTECTION_UNPROTECTED);

			// input validation
			// $validation = $spreadsheet->getActiveSheet()->getCell("F4")->getDataValidation();
			// $validation->setType(DataValidation::TYPE_WHOLE);
			// $validation->setErrorStyle(DataValidation::STYLE_STOP);
			// $validation->setAllowBlank(true);
			// $validation->setShowInputMessage(true);
			// $validation->setShowErrorMessage(true);
			// $validation->setErrorTitle('Input error');
			// $validation->setError('Input is not allowed!');
			// $validation->setPromptTitle('Allowed input');
			// $validation->setPrompt("Only Number Value allowed");
			// $validation->setFormula1(1);
			// $validation->setFormula2(999999999999);
			// $spreadsheet->getActiveSheet()->setDataValidation("F4:F$kolom", $validation);

			// enable autofilter
			$spreadsheet->getActiveSheet()->setAutoFilter("A3:F$kolom");
			
			// setlocale(LC_ALL, "en_US.UTF-8");
			// $locale = 'us';
			// $validLocale = \PhpOffice\PhpSpreadsheet\Settings::setLocale($locale);
			// if (!$validLocale) {
			// 	echo 'Unable to set locale to ' . $locale . " - reverting to en_us" . PHP_EOL;
			// }

			// setlocale(LC_ALL, "id_ID.UTF-8");

			// \PhpOffice\PhpSpreadsheet\Shared\StringHelper::setDecimalSeparator('.');
			// \PhpOffice\PhpSpreadsheet\Shared\StringHelper::setThousandsSeparator(',');

			$writer = new Xls($spreadsheet);
			$nama_file = "Product_Price_$customer->e_customer_name"."_$e_periode.xls";

			header('Content-Type: application/vnd.ms-excel');
			header('Content-Disposition: attachment;filename=' . $nama_file . '');
			header('Cache-Control: max-age=0');
			$writer->save('php://output');
		}
	}

	public function prosesupload()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		// $data = check_role($this->id_menu, 1);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		$id_customer = $this->input->post('id_customer', TRUE);
		
		$filename    = "Product_Price_" . $id_customer . ".xls";

		$config = array(
			'upload_path'   => "./upload/",
			'allowed_types' => "xls|xlsx|ods|csv",
			'file_name'     => $filename,
			'overwrite'     => true
		);

		$this->load->library('upload', $config);
		if ($this->upload->do_upload("userfile")) {
			$data = array('upload_data' => $this->upload->data());
			$this->logger->write('Upload File Harga Barang, Id Customer : ' . $id_customer);

			$data =  array(
				'sukses'    => true,
				'id'		=> encrypt_url($id_customer)
			);
		} else {
			$error = array('error' => $this->upload->display_errors());
			$data =  array(
				'sukses' => false,
				'error'	 => $error
			);
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
				'assets/js/' . $this->folder . '/uploaddetail.js',
			)
		);

		$id_customer = decrypt_url($this->uri->segment(3));

		$filename = "Product_Price_" . $id_customer . ".xls";

		$inputFileName = './upload/' . $filename;
		$spreadsheet   = IOFactory::load($inputFileName);
		$worksheet     = $spreadsheet->getActiveSheet();
		$sheet         = $spreadsheet->getSheet(0);
		$hrow          = $sheet->getHighestDataRow('A');

		$array 		   = [];

		$_id_customer = $spreadsheet->getActiveSheet()->getCell('B1')->getValue();
		$_e_periode = $spreadsheet->getActiveSheet()->getCell('B2')->getValue();
		$e_periode_year = substr($_e_periode, 0, 4);
		$e_periode_month = substr($_e_periode, 4, 2);

		$customer = $this->mymodel->get_customer_by_id($id_customer)->row();

		if ($id_customer != $_id_customer) {
			$referrer = $_SERVER['HTTP_REFERER'];
			$button = "<a href='$referrer' class='btn btn-block btn-danger'>Kembali</a>";
			echo '<h1>Invalid Customer</h1>' . $button;
			die();
		}

		for ($n = 4; $n <= $hrow; $n++) {
			$id_product = $spreadsheet->getActiveSheet()->getCell('B' . $n)->getValue();
			$i_product = $spreadsheet->getActiveSheet()->getCell('C' . $n)->getValue();
			$e_product = $spreadsheet->getActiveSheet()->getCell('D' . $n)->getValue();
			$brand = $spreadsheet->getActiveSheet()->getCell('E' . $n)->getValue();
			$v_price = $spreadsheet->getActiveSheet()->getCell('F' . $n)->getValue();

			$array[] = array(
				'id_product' => $id_product,
				'i_product' => $i_product,
				'e_product' => $e_product,
				'brand' => $brand,
				'v_price' => $v_price,
			);
		}		

		$data = array(
			'id_customer' => $customer->id_customer,
			'e_periode_year' => $e_periode_year,
			'e_periode_month' => $e_periode_month,
			'e_customer_name' => $customer->e_customer_name,
			'datadetail' => $array,
		);
		
		$this->logger->write('Membuka Form Detail Upload ' . $this->title);
		$this->template->load('main', $this->folder . '/uploaddetail', $data);
	}

	public function cek_data_eksis(){
		$id_product = $this->input->post('id_product');
		$id_customer = $this->input->post('id_customer');

		$is_customer_price_exist = $this->mymodel->is_customer_price_exist($id_product, $id_customer);

		$status = true;
		if ($is_customer_price_exist) {
			$status = false;
		} 

		echo json_encode($status);
	}

	public function e_periode_to_text($e_periode)
	{
		$year = substr($e_periode, 0, 4);
		$month = substr($e_periode, 4, 2);
		// $months = getMonthShort();
		$months = getBulan();
		
		$text_month = $months[$month];
		return ucwords($text_month) . " $year";
	}
}
