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
		if ($cari != '') {
			$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => ucwords(strtolower($row->e_name)),
				);
			}
		} else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Cari Dengan Nama',
			);
		}
		echo json_encode($filter);
	}

	/** Data Product */
	public function get_product()
	{
		$filter = [];
		//$toko = $this->input->get('id_customer');
		$cari = str_replace("'", "", $this->input->get('q'));
		if ($cari != '') {
			$data = $this->mymodel->get_product($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id . ' - ' . $row->idcompany,
					'text' => $row->id . ' - ' . ucwords(strtolower($row->e_name)) . ' - ' . ucwords(strtolower($row->brand)) . ' - ' . ucwords(strtolower($row->company)),
				);
			}
		} else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Pilih Perusahan / Cari Dengan Kode atau Nama Product',
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
				'assets/js/' . $this->folder . '/add.js',
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
		$this->form_validation->set_rules('icustomer', 'icustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('vprice', 'vprice', 'trim|required');
		$iproduct = $this->input->post('iproduct');
		$iproduct = explode('-',$iproduct);
		$iproduct = $iproduct[0];
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
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
				$this->logger->write('Simpan Data ' . $this->title . ' : ' . $iproduct);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
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

		$this->form_validation->set_rules('icompany', 'icompany', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('iproduct', 'iproduct', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('icustomer', 'icustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('vprice', 'vprice', 'trim|required');
		$iproduct = $this->input->post('iproduct');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
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
				$this->logger->write('Update Data ' . $this->title . ' : ' . $iproduct);
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

		$this->form_validation->set_rules('icustomer', 'icustomer', 'trim|required|min_length[0]');
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
				'assets/js/' . $this->folder . '/upload.js',
			)
		);

		$data = array(
			'customer' => $this->db->query("SELECT * FROM tr_customer WHERE id_customer IN (SELECT id_customer FROM tm_user_customer WHERE id_user = $this->id_user)"),
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

		$icustomer = $this->uri->segment(3);
		$query = $this->mymodel->exportdata();

		if ($query) {

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
			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue('A1', 'No')
				->setCellValue('B1', 'Kode Barang')
				->setCellValue('C1', 'Nama Barang')
				->setCellValue('D1', 'Harga Barang');

			$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:D1');

			$sheet = $spreadsheet->getActiveSheet();
			foreach ($sheet->getColumnIterator() as $column) {
				$sheet->getColumnDimension($column->getColumnIndex())->setAutoSize(true);
			}

			$kolom = 2;
			$nomor = 1;
			$nol = 0;
			foreach ($query->result() as $row) {
				$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A' . $kolom, $nomor)
					->setCellValue('B' . $kolom, $row->i_product)
					->setCellValue('C' . $kolom, $row->e_product_name)
					->setCellValue('D' . $kolom, $row->v_price);
				$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A' . $kolom . ':D' . $kolom);

				$kolom++;
				$nomor++;
			}
			$writer = new Xls($spreadsheet);
			$nama_file = "Product_Price_" . $icustomer . ".xls";
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

		$this->form_validation->set_rules('i_customer', 'i_customer', 'trim|required|min_length[0]');
		$i_customer	= $this->input->post('i_customer', TRUE);

		
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
		
			$filename    = "Product_Price_" . $i_customer . ".xls";

			$config = array(
				'upload_path'   => "./upload/",
				'allowed_types' => "xls|xlsx|ods|csv",
				'file_name'     => $filename,
				'overwrite'     => true
			);

			$this->load->library('upload', $config);
			if ($this->upload->do_upload("userfile")) {
				$data = array('upload_data' => $this->upload->data());
				$this->logger->write('Upload File Harga Barang, Id Customer : ' . $i_customer);

				$data =  array(
					'sukses'    => true,
					'id'		=> encrypt_url($i_customer)
				);
			} else {
				$error = array('error' => $this->upload->display_errors());
				$data =  array(
					'sukses' => false,
					'error'	 => $error
				);
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
				'assets/js/' . $this->folder . '/uploaddetail.js',
			)
		);
		$icustomer = decrypt_url($this->uri->segment(3));

		$filename = "Product_Price_" . $icustomer . ".xls";

		$inputFileName = './upload/' . $filename;
		$spreadsheet   = IOFactory::load($inputFileName);
		$worksheet     = $spreadsheet->getActiveSheet();
		$sheet         = $spreadsheet->getSheet(0);
		$hrow          = $sheet->getHighestDataRow('A');

		$array 		   = [];
		for ($n = 2; $n <= $hrow; $n++) {
			$e_customer 	= strtoupper($spreadsheet->getActiveSheet()->getCell('A' . $n)->getValue());
			$i_customer 	= $this->mymodel->get_customer_id($e_customer);
			$i_product 		= trim($spreadsheet->getActiveSheet()->getCell('B' . $n)->getValue());
			$i_company 		= $this->mymodel->get_company($i_product)->row();
			$i_company 	    = $i_company->i_company;
			$e_product 		= ucwords(strtolower(trim($spreadsheet->getActiveSheet()->getCell('C' . $n)->getValue())));
			$v_harga   		= $spreadsheet->getActiveSheet()->getCell('D' . $n)->getValue();
			$cek_produk 	= $this->mymodel->cek_produk($i_product, $i_company);
			if ($i_product !='' && $cek_produk->num_rows() > 0) {
				$array[] = array(
					'e_customer'	  => $e_customer,
					'i_company'		  => $i_company,
					'i_product'		  => $i_product,
					'e_product'       => $e_product,
					'v_harga'         => $v_harga,
				);
			}else{
				$array[] = array(
					'e_customer'	  => $e_customer,
					'i_company'		  => '',
					'i_product'		  => '',
					'e_product'       => '',
					'v_harga'         => '',
				);
			}
		}

		$ecustomer = $this->db->get_where('tr_customer', ['id_customer' => $icustomer])->row();
		//$ecustomer = $ecustomer->row();
		$ecustomer = $ecustomer->e_customer_name;

		$data = array(
			'icustomer'	 => $icustomer,
			'ecustomer' => $ecustomer,
			'datadetail' => $array,
		);
		$this->logger->write('Membuka Form Detail Upload ' . $this->title);
		$this->template->load('main', $this->folder . '/uploaddetail', $data);
	}

	public function cek_data_eksis(){
		$iproduct = $this->input->post('iproduct');
		$icompany = $this->input->post('icompany');

		$query = $this->mymodel->cek_produk_eksis($iproduct,$icompany);
		if ($query->num_rows() > 0) {
			$status = false;
		} else {
			$status = true;
		}
		echo json_encode($status);
	}
}
