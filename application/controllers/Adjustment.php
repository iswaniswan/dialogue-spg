<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Adjustment extends CI_Controller
{
	public $id_menu = '11';

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
				'assets/js/' . $this->folder . '/index.js?v=' . strtotime(date('Y-m-d H:i:s')),
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
				'assets/js/' . $this->folder . '/add.js?v=' . strtotime(date('Y-m-d H:i:s')),
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
		$dfrom 	= $this->input->post('dfrom', TRUE);
		if ($dfrom == null || $dfrom == "") {
			$dfrom = date('01-m-Y');
		}
		$dto 	= $this->input->post('dto', TRUE);
		if ($dto == null || $dto == "") {
			$dto = date('d-m-Y');
		}

		//$tgl 			= $this->input->post('tgl', TRUE);
		$id_customer 			= $this->input->post('id_customer', TRUE);
		$query = array(
			'detail_product' => $this->mymodel->get_item($dfrom,$dto,$id_customer)->result(),
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

		$items = $this->input->post('items', TRUE);

		// default e_periode_valid_edit
        $e_periode_valid_edit = date('Ym', strtotime($d_document));

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		$this->mymodel->insert_adjustment($i_document, $d_document, $i_periode, $id_customer, $e_remark, null, $e_periode_valid_edit);

		$insert_id = $this->db->insert_id();

		foreach ($items as $item) {
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$e_remark = $item['e_remark'];
			$this->mymodel->insert_adjustment_item($id_adjustment=$insert_id, $id_product, $n_adjustment=$n_qty, $e_remark);
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
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
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

		$this->mymodel->update_adjustment($i_document, $d_document, $i_periode, $id_customer, $e_remark, $id);

		/** delete penjualan item */
		$this->mymodel->delete_adjustment_item_by_id_adjustment($id);

		foreach ($items as $item) {
			$id_stockopname = $id;
			$id_product = $item['id_product'];
			$n_qty = $item['qty'];
			$e_remark = $item['e_remark'];
			$this->mymodel->insert_adjustment_item($id_adjustment=$id, $id_product, $n_adjustment=$n_qty, $e_remark);
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

	/** Redirect ke Form Approvement */
	public function approvement()
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
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
		);
		$this->logger->write('Membuka Form Detail ' . $this->title);
		$this->template->load('main', $this->folder . '/approve', $data);
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
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
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
