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

class So extends CI_Controller
{
	public $id_menu = '9';

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
		$this->id_user  = $this->session->id_user;
		$this->fallcustomer = $this->session->F_allcustomer;
		$this->i_company = $this->session->i_company;
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/index.js?v=1',
			)
		);

		$dfrom 	= $this->input->post('dfrom', TRUE);
		if ($dfrom == null || $dfrom == "") {
			$dfrom = date('01-m-Y');
		}
		$dto 	= $this->input->post('dto', TRUE);
		if ($dto == null || $dto == "") {
			$dto = date('d-m-Y');
		}

		$datefrom 	= date('Y-m-d', strtotime($dfrom));
		$dateto 	= date('Y-m-d', strtotime($dto));

		$data = array(
			'dfrom' => $datefrom,
			'dto'	=> $dateto,
		);

		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index', $data);
	}

	/** List Data */
	public function serverside()
	{
		$dfrom 	= $this->input->post('dfrom', TRUE);
		if ($dfrom == null || $dfrom == "") {
			$dfrom = date('Y-m-01');
		} else {
			$dfrom = date('Y-m-d', strtotime($dfrom));
		}
		$dto 	= $this->input->post('dto', TRUE);
		if ($dto == null || $dto == "") {
			$dto = date('Y-m-d');
		} else {
			$dto = date('Y-m-d', strtotime($dto));
		}
		
		echo $this->mymodel->serverside($dfrom, $dto);
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
				'assets/js/' . $this->folder . '/add.js',
			)
		);

		$data = array(
			'number'  => $this->mymodel->runningnumber(date('ym'), date('Y')),
			'periode' => $this->mymodel->getperiode()->row(),
		);
		$this->logger->write('Membuka Form Tambah ' . $this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	/** Get Nomor Dokument */
	public function number()
	{
		$number = "";
		$tgl 	= $this->input->post('tgl', TRUE);
		if ($tgl != '') {
			$number = $this->mymodel->runningnumber(date('ym', strtotime($tgl)), date('Y', strtotime($tgl)));
		}
		echo json_encode($number);
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_customer($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id_customer,
				'text' => strtoupper($row->e_customer_name),
			);
		}
		echo json_encode($filter);
	}

	/** Get Detail Customer */
	/* public function get_detail_customer()
	{
		header("Content-Type: application/json", true);
		$id_customer = $this->input->post('id_customer', TRUE);
		$query  = $this->mymodel->get_detail_customer($id_customer)->row();
		echo json_encode($query);
	} */

	/** Get Product */
	public function get_product()
	{
		$filter = [];
		$i_company = $this->input->get('i_company');
		$cari = str_replace("'", "", $this->input->get('q'));
		$id_customer = $this->input->get('id_customer');
		
		$data = $this->mymodel->get_product($cari, $id_customer);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => $row->i_product . ' - ' . ucwords(strtolower($row->e_name)) . ' - ' . $row->brand,
			);
		}

		echo json_encode($filter);
	}

	/** Get Detail Product */
	public function get_detail_product()
	{
		header("Content-Type: application/json", true);
		$i_product = $this->input->post('i_product', TRUE);
		$i_brand = $this->input->post('i_brand', TRUE);
		/* $i_company = $this->input->post('i_company', TRUE); */
		$query  = array(
			'detail' => $this->mymodel->get_detail_product($i_product, $i_brand)->result_array()
		);
		echo json_encode($query);
	}

	/** Get Item */
	public function get_item()
	{
		header("Content-Type: application/json", true);
		$tgl 			= $this->input->post('tgl', TRUE);
		$query = array(
			'detail_product' => $this->mymodel->get_item($tgl)->result(),
		);
		echo json_encode($query);
	}

	/** Simpan Data */
	public function __save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('idcustomer', 'idcustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idocument', 'idocuument', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ddocument', 'ddocument', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan Data */
			$idocument = $this->input->post('idocument', TRUE);
			$cek = $this->mymodel->cek($idocument);
			/** Jika Sudah Ada Jangan Disimpan */
			if ($cek->num_rows() > 0) {
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
					$this->logger->write('Simpan Data ' . $this->title . ' : ' . $idocument);
					$data = array(
						'sukses' => true,
						'ada'	 => false,
					);
				}
			}
		}
		echo json_encode($data);
	}

	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		/** Simpan Data */
		$id_customer = $this->input->post('idcustomer', TRUE);
		// $i_document = $this->input->post('idocument', TRUE);
		$i_document = $this->mymodel->generate_nomor_dokumen($id_customer);
		$d_document = $this->input->post('ddocument', TRUE);
		$e_remark = $this->input->post('eremark', TRUE);

		$i_periode = date('Ym');
		if ($this->input->post('ddocument', TRUE) != '') {
			$i_periode =  date('Ym', strtotime($d_document));
		}

		$items = $this->input->post('items', TRUE);

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		$this->mymodel->insert_stockopname($i_document, $d_document, $id_customer, $i_periode, $e_remark);

		$insert_id = $this->db->insert_id();

		foreach ($items as $item) {
			$id_stockopname = $insert_id;
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$this->mymodel->insert_stockopname_item($id_stockopname, $id_product, $n_qty);
		}

		// $this->mymodel->save();
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $i_document);

		$data['sukses'] = true;
		$data['ada'] = false;

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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
		);
		$this->logger->write('Membuka Form Edit ' . $this->title);
		$this->template->load('main', $this->folder . '/edit', $data);
	}

	/** Update Data */
	public function __update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}
		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idcustomer', 'idcustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idocument', 'idocuument', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ddocument', 'ddocument', 'trim|required|min_length[0]');
		$id = $this->input->post('id', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Update Data */
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
				$this->logger->write('Update Data ' . $this->title . ' ID : ' . $id);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
		}
		echo json_encode($data);
	}

	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$i_document = $this->input->post('idocument', TRUE);
		$d_document = $this->input->post('ddocument', TRUE);
		$id_customer = $this->input->post('idcustomer', TRUE);
		$e_remark = $this->input->post('eremark', TRUE);

		$i_periode = date('Ym');
		if ($this->input->post('ddocument', TRUE) != '') {
			$i_periode =  date('Ym', strtotime($d_document));
		}

		$items = $this->input->post('items', TRUE);

		$id = $this->input->post('id', TRUE);		
		/** Update Data */
		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		$this->mymodel->update_stockopname($i_document, $d_document, $id_customer, $i_periode, $e_remark, $id);

		/** delete penjualan item */
		$this->mymodel->delete_stockopname_item_by_id_stockopname($id_stockopname=$id);

		foreach ($items as $item) {
			$id_stockopname = $id;
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$this->mymodel->insert_stockopname_item($id_stockopname, $id_product, $n_qty);
		}

		// $this->mymodel->update();

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;	
		} 

		$this->db->trans_commit();
		$this->logger->write('Update Data ' . $this->title . ' ID : ' . $id);		
		$data['sukses'] = true;
		$data['ada'] = false;		

		echo json_encode($data);
	}



	/** Redirect ke Form View */
	public function view()
	{
		/** Cek Hak Akses, Apakah User Bisa View */
		$data = check_role($this->id_menu, 2);
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
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
		);
		$this->logger->write('Membuka Form Detail ' . $this->title);
		$this->template->load('main', $this->folder . '/view', $data);
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
		$id 		= $this->input->post('id', TRUE);
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

	/** Transfer Product */
	public function transfer()
	{
		/** Cek Hak Akses, Apakah User Bisa Input */
		// $data = check_role($this->id_menu, 1);
		// if (!$data) {
		// 	redirect(base_url(), 'refresh');
		// }

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$id_customer = $this->input->post('id_customer', TRUE);
		$items = $this->input->post('items');
		/** generate header */
		// $i_document = $this->mymodel->runningnumber(date('Ym'), date('Y'));
		$i_document = $this->mymodel->generate_nomor_dokumen($id_customer);
		$d_document = date('Y-m-d');
		$i_periode = date('Ym');
		$e_remark = '';

		$this->db->trans_begin();

		$this->mymodel->insert_stockopname($i_document, $d_document, $id_customer, $i_periode, $e_remark);

		$insert_id = $this->db->insert_id();

		foreach ($items as $item) {
			$id_stockopname = $insert_id;
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$this->mymodel->insert_stockopname_item($id_stockopname, $id_product, $n_qty);
		}

		// $this->mymodel->save();
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Tranfer Upload Data ' . $this->title);

		$data['sukses'] = true;
		$data['ada'] = false;

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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/uploaders/fileinput/fileinput.min.js',
				'assets/js/' . $this->folder . '/upload.js?v=1',
			)
		);

		$sql = "SELECT * 
				FROM tr_customer 
				WHERE id_customer IN (
										SELECT id_customer 
										FROM tm_user_customer 
										WHERE id_user = $this->id_user
									)
				ORDER BY e_customer_name ASC";
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
		$customer = $this->mymodel->get_customer_by_id($id_customer)->row();
		// $query = $this->mymodel->exportdata();
		$query = $this->mymodel->export_data_by_user_cover($id_customer);

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
			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue('B1', $id_customer)
				->setCellValue('C1', $customer->e_customer_name)
				->setCellValue('A3', 'No')
				->setCellValue('B3', 'ID Barang')
				->setCellValue('C3', 'Kode')
				->setCellValue('D3', 'Nama')
				->setCellValue('E3', 'Brand')
				->setCellValue('F3', 'Quantity');

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
					->setCellValue('D' . $kolom, $row->e_product_name)
					->setCellValue('E' . $kolom, $row->e_brand_name)
					->setCellValue('F' . $kolom, $row->n_qty);
				$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A' . $kolom . ':F' . $kolom);

				$kolom++;
				$nomor++;
			}

			// hide kolom B, 
			$spreadsheet->getActiveSheet()->getColumnDimension('B')->setCollapsed(true);
			$spreadsheet->getActiveSheet()->getColumnDimension('B')->setVisible(false);

			$spreadsheet->getActiveSheet()->getColumnDimension('F')->setAutoSize(false);
			$spreadsheet->getActiveSheet()->getColumnDimension('F')->setWidth(20);
			
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
			$nama_file = "Stock_opname_" . $customer->e_customer_name . ".xls";

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
		
		$filename = "Stock_Opname_" . $id_customer . ".xls";

		$config = array(
			'upload_path'   => "./upload/",
			'allowed_types' => "xls|xlsx|ods|csv",
			'file_name'     => $filename,
			'overwrite'     => true
		);

		$this->load->library('upload', $config);
		if ($this->upload->do_upload("userfile")) {
			$data = array('upload_data' => $this->upload->data());
			$this->logger->write('Upload File Stock Opname, Id Customer : ' . $id_customer);

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

		$filename = "Stock_Opname_" . $id_customer . ".xls";

		$inputFileName = './upload/' . $filename;
		$spreadsheet   = IOFactory::load($inputFileName);
		$worksheet     = $spreadsheet->getActiveSheet();
		$sheet         = $spreadsheet->getSheet(0);
		$hrow          = $sheet->getHighestDataRow('A');

		$array 		   = [];

		$_id_customer = $spreadsheet->getActiveSheet()->getCell('B1')->getValue();
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
			$qty = $spreadsheet->getActiveSheet()->getCell('F' . $n)->getValue();

			$array[] = array(
				'id_product' => $id_product,
				'i_product' => $i_product,
				'e_product' => $e_product,
				'brand' => $brand,
				'qty' => $qty,
			);
		}		

		$data = array(
			'id_customer' => $customer->id_customer,
			'e_customer_name' => $customer->e_customer_name,
			'datadetail' => $array,
		);
		
		$this->logger->write('Membuka Form Detail Upload ' . $this->title);
		$this->template->load('main', $this->folder . '/uploaddetail', $data);
	}
}
