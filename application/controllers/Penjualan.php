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

class Penjualan extends CI_Controller
{
	public $id_menu = '4';

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
		$this->id_user  	= $this->session->id_user;
		$this->i_company 	= $this->session->i_company;
		$this->fallcustomer = $this->session->F_allcustomer;
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/index.js',
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
			'dfrom' => $dfrom,
			'dto'	=> $dto,
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
            $number = $this->mymodel->runningnumber(date('ym', strtotime($tgl)),date('Y', strtotime($tgl)));
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
	public function get_detail_customer()
	{
		header("Content-Type: application/json", true);
		$id_customer = $this->input->post('id_customer', TRUE);
		$query  = $this->mymodel->get_detail_customer($id_customer)->row();
		echo json_encode($query);
	}

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
	/*
	public function get_detail_product()
	{
		header("Content-Type: application/json", true);
		$i_product = $this->input->post('i_product', TRUE);
		$i_brand = $this->input->post('i_brand', TRUE);
		//$id_customer = $this->input->post('id_customer', TRUE);
		$query  = array(
			'detail' => $this->mymodel->get_detail_product($i_product,$i_brand)->result_array()
		);
		echo json_encode($query);
	}
	*/

	public function get_product_price()
	{
		header("Content-Type: application/json", true);
		$id_product = $this->input->post('id_product', TRUE);
		$id_customer = $this->input->post('id_customer', TRUE);
		$query  = array(
			'detail' => $this->mymodel->get_product_price($id_product, $id_customer)->result_array()
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
				$dataheader = [];
				$dataitem 	= [];

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

		$i_document = $this->input->post('idocument');
		$d_document = $this->input->post('ddocument');
		$id_customer = $this->input->post('idcustomer');
		$nama = $this->input->post('nama');
		$e_remark = $this->input->post('eremark');
		$alamat = $this->input->post('alamat');
		$bruto = $this->input->post('grand_total');
		$bruto = str_replace(",", "", $bruto);

		$diskon = $this->input->post('diskon');
		$diskon_persen = $this->input->post('diskonpersen');
		
		$netto = $this->input->post('grand_akhir');
		$netto = str_replace(",", "", $netto);

		$items = $this->input->post('items');
		$id_user = $this->session->userdata('id_user');

		// default e_periode_valid_edit
        $e_periode_valid_edit = date('Ym', strtotime($d_document));

		$this->db->trans_begin();

		$this->mymodel->insert_penjualan(
			$id_customer, $i_document, $d_document, $e_customer_sell_name=$nama, $e_customer_sell_address=$alamat, 
			$v_gross=$bruto, $n_diskon=$diskon_persen, $v_diskon=$diskon, $v_dpp=null, $v_ppn=null, 
			$v_netto=$netto, $v_bayar=null, $e_remark, $id_user, $e_periode_valid_edit
		);

		$insert_id = $this->db->insert_id();

		foreach ($items as $item) {
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$v_diskon = $item['vdiskon'];
			$v_price = $item['harga'];
			$v_price = str_replace(",", "", $v_price);
			$e_remark = $item['enote'];
			$this->mymodel->insert_penjualan_item(
				$id_penjualan=$insert_id, $i_company=null, $id_product, $n_qty, $v_price, $v_diskon, $e_remark
			);
		}

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

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
		$this->form_validation->set_rules('idocument', 'idocument', 'trim|required|min_length[0]');
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

		$i_document = $this->input->post('idocument');
		$d_document = $this->input->post('ddocument');
		$id_customer = $this->input->post('idcustomer');
		$nama = $this->input->post('nama');
		$e_remark = $this->input->post('eremark');
		$alamat = $this->input->post('alamat');
		$bruto = $this->input->post('grand_total');
		$bruto = str_replace(",", "", $bruto);

		$diskon = $this->input->post('diskon');
		$diskon_persen = $this->input->post('diskonpersen');
		
		$netto = $this->input->post('grand_akhir');
		$netto = str_replace(",", "", $netto);

		$items = $this->input->post('items');
		$id_user = $this->session->userdata('id_user');

		$id = $this->input->post('id', TRUE);		
		/** Update Data */
		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		$this->mymodel->update_penjualan(
			$id_customer, $i_document, $d_document, $e_customer_sell_name=$nama, $e_customer_sell_address=$alamat, 
			$v_gross=$bruto, $n_diskon=$diskon_persen, $v_diskon=$diskon, $v_dpp=null, $v_ppn=null, 
			$v_netto=$netto, $v_bayar=null, $e_remark, $id_user, $id
		);

		/** delete penjualan item */
		$this->mymodel->delete_penjualan_item_by_id_penjualan($id_penjualan=$id);

		foreach ($items as $item) {
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$v_diskon = $item['vdiskon'];
			$v_price = $item['harga'];
			$v_price = str_replace(",", "", $v_price);
			$e_remark = $item['enote'];
			$this->mymodel->insert_penjualan_item(
				$id_penjualan=$id, $i_company=null, $id_product, $n_qty, $v_price, $v_diskon, $e_remark
			);
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

		// var_dump(decrypt_url($this->uri->segment(3)));
		// die();

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
					->setCellValue('A1', "Pengeluaran Produk $_dfrom - $_dto");		
		$spreadsheet->getActiveSheet()->mergeCells("A1:E1");
		$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:E1');

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A2', 'No')
					->setCellValue('B2', 'No Dokumen')
					->setCellValue('C2', 'Tgl Dokumen')
					->setCellValue('D2', 'Pelanggan')
					->setCellValue('E2', 'Keterangan');
          
		$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A2:E2');

		$kolom = 3;
		$nomor = 1;
		foreach($query->result() as $row) {
            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->i_document)
                        ->setCellValue('C' . $kolom, $row->d_document)
                        ->setCellValue('D' . $kolom, $row->e_customer_sell_name)
                        ->setCellValue('E' . $kolom, $row->e_remark);

            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A'.$kolom.':E'.$kolom);

			$kolom++;
			$nomor++;
        }

        $writer = new Xls($spreadsheet);
        $nama_file = "Pengeluaran Produk.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');

	}

	public function export_excel_detail()
	{
		$_dfrom = $this->uri->segment(3);
		$_dto = $this->uri->segment(4);

		$dfrom = date('Y-m-d', strtotime($_dfrom));
		$dto = date('Y-m-d', strtotime($_dto));

		$query = $this->mymodel->export_excel_detail($dfrom, $dto);

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

        foreach(range('A','Q') as $columnID) {
          $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A1', "Penjualan Produk $_dfrom - $_dto");		
		$spreadsheet->getActiveSheet()->getRowDimension('1')->setRowHeight(32);

		$spreadsheet->getActiveSheet()->mergeCells("A1:Q1");
		$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:Q1');

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('F2', "Barang")
					->setCellValue('M2', "Harga");		

		$spreadsheet->getActiveSheet()->mergeCells("F2:G2")
					->mergeCells("M2:P2")
					->mergeCells("A2:A3")
					->mergeCells("B2:B3")
					->mergeCells("C2:C3")
					->mergeCells("D2:D3")
					->mergeCells("E2:E3")
					->mergeCells("H2:H3")
					->mergeCells("I2:I3")
					->mergeCells("J2:J3")
					->mergeCells("K2:K3")
					->mergeCells("L2:L3")
					->mergeCells("Q2:Q3");

		$spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A2:Q3');

		$spreadsheet->setActiveSheetIndex(0)
					->setCellValue('A2', 'No')
					->setCellValue('B2', 'No Dokumen')
					->setCellValue('C2', 'Tgl Dokumen')
					->setCellValue('D2', 'Pelanggan')
					->setCellValue('E2', 'Toko')
					->setCellValue('F3', 'Kode')
					->setCellValue('G3', 'Nama')
					->setCellValue('H2', 'Brand')
					->setCellValue('I2', 'Kategori')
					->setCellValue('J2', 'Sub Kategori')
					->setCellValue('K2', 'Qty')
					->setCellValue('L2', 'Discount %')
					->setCellValue('M3', 'Satuan')
					->setCellValue('N3', 'Total')
					->setCellValue('O3', 'Diskon')
					->setCellValue('P3', 'Akhir')
					->setCellValue('Q2', 'Keterangan');
          
		$kolom = 4;
		$nomor = 1;
		foreach($query->result() as $row) {

			$total = $row->v_price * $row->n_qty;
			$discount = ($total * $row->v_diskon) / 100;
			$akhir =  $total - $discount; 

            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->i_document)
                        ->setCellValue('C' . $kolom, $row->d_document)
                        ->setCellValue('D' . $kolom, $row->e_customer_sell_name)
                        ->setCellValue('E' . $kolom, strtoupper($row->e_customer_name))
						->setCellValue('F' . $kolom, $row->i_product)
						->setCellValue('G' . $kolom, $row->e_product_name)	
						->setCellValue('H' . $kolom, $row->e_brand_name)
						->setCellValue('I' . $kolom, $row->e_category_name)
						->setCellValue('J' . $kolom, $row->e_sub_category_name)
						->setCellValue('K' . $kolom, $row->n_qty)
						->setCellValue('L' . $kolom, $row->v_diskon)
						->setCellValue('M' . $kolom, $row->v_price)
						->setCellValue('N' . $kolom, $total)
						->setCellValue('O' . $kolom, $discount)
						->setCellValue('P' . $kolom, $akhir)
						->setCellValue('Q' . $kolom, $row->e_remark);

            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A'.$kolom.':Q'.$kolom);

			$kolom++;
			$nomor++;
        }

		/** format currency */
		$format_code = '"Rp. "#,##0';
		$spreadsheet->getActiveSheet()
                ->getStyle('M4:P'.$kolom)
                ->getNumberFormat()
                ->setFormatCode($format_code);

        $writer = new Xls($spreadsheet);
        $nama_file = "Penjualan Produk.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');

	}

	public function get_e_periode_valid_edit()
	{
		$data = [];

		$id = $this->input->get('id');

		$query = $this->mymodel->getdata($id);
		if ($query->row() != null) {
			$e_periode = $query->row()->e_periode_valid_edit;			
			$data = date('Y-m-d', strtotime($e_periode.'01'));
		}

		echo json_encode($data);
	}
		
}
