<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Subcategory extends CI_Controller
{
	public $id_menu = '112';

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
		$this->logger->write('Membuka Menu '.$this->title);
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
		$this->logger->write('Membuka Form Tambah '.$this->title);
		$this->template->load('main', $this->folder . '/add');
	}

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$id_category = $this->input->post('id_category');
		$e_sub_category_name = $this->input->post('e_sub_category_name');

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		$this->mymodel->save($id_category, $e_sub_category_name);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $e_sub_category_name);

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
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(), 
		);
		$this->logger->write('Membuka Form Edit '.$this->title);
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

		$id = $this->input->post('id', TRUE);
		$id_category = $this->input->post('id_category', TRUE);
		$e_sub_category_name = ucwords($this->input->post('e_sub_category_name', TRUE));
		
		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();               

		$this->mymodel->update($id_category, $e_sub_category_name, $id);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $e_sub_category_name);

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

	public function get_category()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_category($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_category_name),
			);
		}
		echo json_encode($filter);
	}

	public function get_sub_category()
	{
		$filter = [];
		$id_category = $this->input->get('id_category');
		$cari = str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_sub_category($id_category, $cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_category_name),
			);
		}
		echo json_encode($filter);
	}
}