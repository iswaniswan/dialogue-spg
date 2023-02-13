<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Customer extends CI_Controller
{
	public $id_menu = '103';

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
			'type' => $this->db->get_where('tr_type_customer', ['f_status' => 't']),
		);
		$this->logger->write('Membuka Form Tambah ' . $this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	/** Get Company */
	public function get_company()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_company($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->i_company,
				'text' => $row->e_company_name,
			);
		}
		echo json_encode($filter);
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$id		= $this->input->get('id');
		$cari	= str_replace("'", "", $this->input->get('q'));
		if ($id != '' || $id != null) {
			if ($cari != '') {
				$data = $this->mymodel->get_customer($id, $cari);
				foreach ($data->result() as $row) {
					$filter[] = array(
						'id'   => $row->i_customer,
						'text' => strtoupper($row->e_customer_name),
					);
				}
			} else {
				$filter[] = array(
					'id'   => null,
					'text' => 'Cari Data Berdasarkan Kodelang atau Nama',
				);
			}
		} else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Pilih Perusahaan Terlebih Dahulu!',
			);
		}
		echo json_encode($filter);
	}

	/** Get Detail Customer */
	public function get_detail_customer()
	{
		header("Content-Type: application/json", true);
		$i_customer = $this->input->post('i_customer', TRUE);
		$i_company  = $this->input->post('i_company', TRUE);
		$query  = array(
			'detail' => $this->mymodel->get_detail_customer($i_customer, $i_company)->result_array()
		);
		echo json_encode($query);
	}

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('itype', 'itype', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ecustomer', 'ecustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('eaddress', 'eaddress', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan Data */
			$this->db->trans_begin();
			$itype = $this->input->post('itype', TRUE);
			$fpkp = $this->input->post('fpkp', TRUE);
			$ecustomer = ucwords(trim($this->input->post('ecustomer', TRUE)));
			$ecustomernpwp = $this->input->post('ecustomernpwp', TRUE);
			$eaddress = $this->input->post('eaddress', TRUE);
			$eaddressnpwp = $this->input->post('eaddressnpwp', TRUE);
			$eowner = $this->input->post('eowner', TRUE);
			$ephone = $this->input->post('ephone', TRUE);
			$latitude = $this->input->post('latitude', TRUE);
			$longitude = $this->input->post('longitude', TRUE);

			$this->mymodel->save($itype, $fpkp, $ecustomer, $ecustomernpwp, $eaddress, $eaddressnpwp, $eowner, $ephone, $latitude, $longitude);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Simpan Data ' . $this->title . ' : ' . $ecustomer);
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

		$data = array(
			'data' 	 => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail' => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
			'type'   => $this->db->get_where('tr_type_customer', ['f_status' => 't']),
		);
		$this->logger->write('Membuka Form Edit ' . $this->title);
		$this->template->load('main', $this->folder . '/edit', $data);
	}

	/** Redirect ke Form Edit */
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
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	 => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail' => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
			'type'   => $this->db->get_where('tr_type_customer', ['f_status' => 't']),
			// 'brand' => $this->mymodel->get_data_brand(decrypt_url($this->uri->segment(3)))
		);
		$this->logger->write('Membuka Form View ' . $this->title);
		$this->template->load('main', $this->folder . '/view', $data);
	}

	/** Update Data */
	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}
		$this->form_validation->set_rules('itype', 'itype', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ecustomer', 'ecustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('eaddress', 'eaddress', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Update Data */
			$this->db->trans_begin();
			$idcustomer = $this->input->post('idcustomer', TRUE);
			$itype = $this->input->post('itype', TRUE);
			$fpkp = $this->input->post('fpkp', TRUE);
			$ecustomer = ucwords(trim($this->input->post('ecustomer', TRUE)));
			$ecustomernpwp = $this->input->post('ecustomernpwp', TRUE);
			$eaddress = $this->input->post('eaddress', TRUE);
			$eaddressnpwp = $this->input->post('eaddressnpwp', TRUE);
			$eowner = $this->input->post('eowner', TRUE);
			$ephone = $this->input->post('ephone', TRUE);
			$latitude = $this->input->post('latitude', TRUE);
			$longitude = $this->input->post('longitude', TRUE);

			$this->mymodel->update($itype, $fpkp, $ecustomer, $ecustomernpwp, $eaddress, $eaddressnpwp, $eowner, $ephone, $idcustomer, $latitude, $longitude);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update Data ' . $this->title . ' : ' . $ecustomer);
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
		$id = $this->input->post('id', TRUE);
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
}
