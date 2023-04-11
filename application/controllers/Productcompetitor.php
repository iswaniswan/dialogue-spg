<?php
defined('BASEPATH') or exit('No direct script access allowed');

class ProductCompetitor extends CI_Controller
{
	public $id_menu = '113';

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
		$this->i_company= $this->session->i_company;
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
	public function get_company()
	{
		$filter = [];
		$data = $this->mymodel->get_company(str_replace("'", "", $this->input->get('q')));
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => ucwords(strtolower($row->e_name)),
			);
		}
		echo json_encode($filter);
	}

	/** Data Brand */
	public function get_brand()
	{
		$filter = [];
		$cari = str_replace("'", "", $this->input->get('q'));
		$id_customer = $this->input->get('id_customer');
		
		if ($id_customer != null) {

			$id_user_customer = $this->mymodel->get_id_user_customer($id_customer);

			$data = $this->mymodel->get_brand($cari, $id_user_customer);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => ucwords(strtolower($row->e_name)),
				);
			}
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
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/datepicker/js/bootstrap-datepicker.js',
				'assets/js/' . $this->folder . '/add.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$data = array(
			'company' => $this->mymodel->get_company_data(),
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

		$i_product = $this->input->post('iproduct', TRUE);
		/** Cek Jika Nama Sudah Ada */
		$is_product_exist = $this->mymodel->is_product_exist($i_product);

		/** Jika Sudah Ada Jangan Disimpan */
		if ($is_product_exist) {
			$response = [
				'sukses' => false,
				'ada'	 => true
			];

			echo json_encode($response);
			return;
		} 

		/** Jika Belum Ada Simpan Data */
		$this->db->trans_begin();
		$this->mymodel->save();
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			$response =[
				'sukses' => false,
				'ada'	 => false,
			];

			echo json_encode($response);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $i_product);
		$response =[
			'sukses' => true,
			'ada'	 => false,
		];
		
		echo json_encode($response);
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
				'global_assets/js/bootstrap4-editable/bootstrap-editable.min.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$id = decrypt_url($this->uri->segment(3));
		$i_company = decrypt_url($this->uri->segment(4));

		/** testing */
		$all_customer_price = $this->mymodel->get_all_customer_price()->result();

		$data = array(
			'data' 		=> $this->mymodel->getdata($id,$i_company)->row(),
			'company'	=> $this->mymodel->get_company_data(),
			'all_customer_price' => $all_customer_price,
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

		/** Jika Sudah Ada Jangan Disimpan */
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
			$this->logger->write('Update Data ' . $this->title);
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
		$data = check_role($this->id_menu, 1);
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
			$this->mymodel->transfer($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Tranfer Data ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function update_editable()
	{
		$id = $this->input->post('pk');
		$value = $this->input->post('value');

		$data = [
			'id' => $id,
			'value' => $value
		];

		$this->mymodel->update_editable($data);

	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$cari   = str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => strtoupper($row->e_name),
				);
			}
		echo json_encode($filter);
	}

	public function get_category()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		
		$this->load->model('Mcategory');
		$data = $this->Mcategory->get_category($cari);
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
		$cari	= str_replace("'", "", $this->input->get('q'));

		if ($id_category != null) {

			$this->load->model('Msubcategory');
			$data = $this->Msubcategory->get_sub_category($id_category, $cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id,
					'text' => strtoupper($row->e_sub_category_name),
				);
			}
		}	

		echo json_encode($filter);
	}

	public function get_product()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$id_customer = $this->input->get('id_customer');
		$id_brand = $this->input->get('id_brand');
		
		$data = $this->mymodel->get_product($cari, $id_customer, $id_brand);

		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_product_name),
				'userdata' => [
					'id_brand' => $row->id_brand,
					'e_brand_name' => $row->e_brand_name
				]
			);
		}	

		echo json_encode($filter);
	}
}