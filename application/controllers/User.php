<?php
defined('BASEPATH') or exit('No direct script access allowed');

class User extends CI_Controller
{
	public $id_menu = '104';

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
				'global_assets/js/plugins/forms/styling/switch.min.js',
				'assets/js/' . $this->folder . '/add.js',
			)
		);

		$level = $this->db->get_where('tr_level', ['f_status' => 't']);
		$company = $this->db->get_where('tr_company', ['f_status' => 't']);

		$data = array(
			'level'   => $level,
			'company' => $company,
		);

		$this->logger->write('Membuka Form Tambah ' . $this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		if ($cari != '') {
			$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id_customer,
					'text' => strtoupper($row->e_customer_name),
				);
			}
		} else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Cari Data Berdasarkan Nama',
			);
		}
		echo json_encode($filter);
	}

	/** Get Detail Customer */
	public function get_detail_customer()
	{
		header("Content-Type: application/json", true);
		$i_customer = $this->input->post('i_customer', TRUE);
		$query  = array(
			'detail' => $this->mymodel->get_detail_customer($i_customer)->result_array()
		);
		echo json_encode($query);
	}

	/** Data Brand */
	public function get_brand()
	{
		$filter = [];
		$data = $this->mymodel->get_brand(str_replace("'", "", $this->input->get('q')));
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => ucwords(strtolower($row->e_name)),
			);
		}
		echo json_encode($filter);
	}


	private function validate_form()
	{
		$this->form_validation->set_rules('username', 'username', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('password', 'password', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ename', 'ename', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ilevel', 'ilevel', 'trim|required|min_length[0]');
		//$this->form_validation->set_rules('icompany[]', 'icompany[]', 'trim|required|min_length[0]');
		// $this->form_validation->set_rules('i_brand[]', 'i_brand[]', 'trim|required|min_length[0]');

		return $this->form_validation->run();
	}

	private function is_user_already_exist($username)
	{
		$query = $this->mymodel->cek($username);
		return $query->num_rows() > 0;
	}

	/** Simpan Data */
	public function save()
	{
		$username = $this->input->post('username', TRUE);
		$password = $this->input->post( 'password', TRUE);
		$ename = $this->input->post('ename', TRUE);
		$ilevel = $this->input->post('ilevel', TRUE);
		$id_atasan = $this->input->post('id_atasan', TRUE);
		$i_customer = $this->input->post('i_customer', TRUE);
		$i_brand = $this->input->post( 'i_brand', TRUE);
		
		$fallcustomer = false;
		if ($this->input->post('fallcustomer') == 'on') {
			$fallcustomer = true;
		} 

		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$result = [
			'data' => [],
			'message' => 'invalidate form'
		];

		if ($this->validate_form()) {
			/** Jika Sudah Ada Jangan Disimpan */
			if ($this->is_user_already_exist($username)) {
				$result['message'] = 'User sudah ada';
			} else {
				$this->db->trans_begin();

				$params = [
					'username' => $username,
					'password' => $password,
					'ename' => $ename,
					'ilevel' => $ilevel,
					'id_atasan' => $id_atasan,
					'i_customer' => $i_customer,
					'i_brand' => $i_brand,
					'fallcustomer' => $fallcustomer
				];

				$this->mymodel->save($params);

				if ($this->db->trans_status() === FALSE) {
					$this->db->trans_rollback();
					$result = [
						'message' => $this->db->error()
					];
				} else {
					$this->db->trans_commit();
					$this->logger->write('Simpan Data ' . $this->title . ' : ' . $username);
					$result = [
						'sukses' => true,
						'ada' => false
					];
				}
			}
		} 

		echo json_encode($result);
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
				'global_assets/js/plugins/forms/styling/switch.min.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$list_team_leader = $this->db->get_where('tm_user', ['f_status' => 't', 'i_level' => '5']);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			// 'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
			'detail'  => $this->mymodel->get_data_customer_with_brand(decrypt_url($this->uri->segment(3))),
			'company' => $this->mymodel->get_company(decrypt_url($this->uri->segment(3))),
			// 'brand'   => $this->mymodel->get_brand_data(decrypt_url($this->uri->segment(3))),
			'level'   => $this->db->get_where('tr_level', ['f_status' => 't']),
			'list_brand' => $this->mymodel->get_brand(),
			'list_team_leader' => $list_team_leader
		);

		$this->logger->write('Membuka Form Edit ' . $this->title);
		$this->template->load('main', $this->folder . '/edit', $data);
	}

	/** Update Data */
	public function update_backup()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}
		$this->form_validation->set_rules('username', 'username', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('password', 'password', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ename', 'ename', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ilevel', 'ilevel', 'trim|required|min_length[0]');
		//$this->form_validation->set_rules('icompany[]', 'icompany[]', 'trim|required|min_length[0]');
		// $this->form_validation->set_rules('i_brand[]', 'i_brand[]', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			$username = $this->input->post('username', TRUE);
			$usernameold = $this->input->post('usernameold', TRUE);
			$cek = $this->mymodel->cek_edit($username,$usernameold);
			/** Jika Sudah Ada Jangan Disimpan */
			if ($cek->num_rows() > 0) {
				$data = array(
					'sukses' => false,
					'ada'	 => true,
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
					$this->logger->write('Update Data ' . $this->title . ' : ' . $username);
					$data = array(
						'sukses' => true,
						'ada'	 => false,
					);
				}
			}
		}
		echo json_encode($data);
	}


	public function update()
	{
		$id_user = $this->input->post('id_user');
		$username = $this->input->post('username', TRUE);
		$password = $this->input->post( 'password', TRUE);
		$ename = $this->input->post('ename', TRUE);
		$ilevel = $this->input->post('ilevel', TRUE);
		$id_atasan = $this->input->post('id_atasan', TRUE);
		$i_customer = $this->input->post('i_customer', TRUE);
		$i_brand = $this->input->post( 'i_brand', TRUE);
		
		$fallcustomer = false;
		if ($this->input->post('fallcustomer') == 'on') {
			$fallcustomer = true;
		} 

		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$result = [
			'data' => [],
			'message' => 'invalidate form'
		];

		if ($this->validate_form()) {
			/** Delete old data */
			$this->db->trans_begin();

			$params = [
				'id_user' => $id_user,
				'username' => $username,
				'password' => $password,
				'ename' => $ename,
				'ilevel' => $ilevel,
				'id_atasan' => $id_atasan,
				'i_customer' => $i_customer,
				'i_brand' => $i_brand,
				'fallcustomer' => $fallcustomer
			];

			$this->mymodel->update2($params);

			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$result = [
					'message' => $this->db->error()
				];
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update Data ' . $this->title . ' : ' . $username);
				$result = [
					'sukses' => true,
					'ada' => false
				];
			}
			
		} 

		echo json_encode($result);
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

	public function get_list_team_leader()
	{		
		$keyword = $this->input->get('q');

		$result = [];

		$query = $this->mymodel->get_list_team_leader(['keyword' => $keyword]);
		
		foreach ($query->result() as $row) {
			$result[] = [
				'id'   => $row->id_user,
				'text' => strtoupper($row->e_nama)
			];
		}

		echo json_encode($result);		
	}
}
