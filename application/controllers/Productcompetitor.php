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
	
		return $this->index_v2();

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

	public function index_v2()
	{
		add_js(
			array(
				'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/buttons.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/natural_sort.js',
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/' . $this->folder . '/index.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$id_customer = $this->input->post('id_customer');

		$data = [];

		if ($id_customer != null) {
			$customer = $this->mymodel->get_customer('', $id_customer)->row();
			$data['customer'] = $customer;
		}

		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index_v2', $data);
	}

	/** List Data */
	public function serverside()
	{
		echo $this->mymodel->serverside();
	}

	/** List Data */
	public function serverside2()
	{
		echo $this->mymodel->serverside2();
	}

	/** List Data */
	public function serverside3()
	{
		$id_customer = $this->input->post('id_customer');

		echo $this->mymodel->serverside3($id_customer);
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
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
	public function __update()
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

	public function update()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 3);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}				

		$this->db->trans_begin();

		$id_product = $this->input->post('id_product');
		$id_customer = $this->input->post('id_customer');
		$items = $this->input->post('items');

		$this->mymodel->delete_product_competitor($id_product);

		foreach ($items as $item) {
			// $id_customer = $item['id_customer'];
			$e_brand_text = $item['e_brand_text'];
			
			$v_price = $item['vprice'];
			$v_price = str_replace(".", "", $v_price);
			$v_price = str_replace(",", "", $v_price);

			$d_berlaku = $item['d_berlaku'];
			$e_remark = $item['e_remark'];

			$this->mymodel->insert_update_product_competitor($id_customer, $id_product, $v_price, $e_remark, $e_brand_text, $d_berlaku);
		}
		
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
				'text' => $row->i_product . ' - ' . ucwords(strtolower($row->e_product_name)),
				'userdata' => [
					'id_brand' => $row->id_brand,
					'e_brand_name' => $row->e_brand_name
				]
			);
		}	

		echo json_encode($filter);
	}

	public function view_competitor()
	{
		$id_product = $this->input->get('id_product');
		$id_customer = $this->input->get('id_customer');

		if ($id_product == null or $id_customer == null) {
			return $this->index_v2();
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/bootstrap4-editable/bootstrap-editable.min.js',
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$customer = $this->mymodel->get_customer(null, $id_customer)->row();
		$product = $this->mymodel->get_product_customer_berjalan($id_product, $id_customer)->row();
		$all_competitor = $this->mymodel->get_product_competitor($id_product, $id_customer);

		$data = [
			'customer' => $customer,
			'product' => $product,
			'all_competitor' => $all_competitor,
		];

		$this->logger->write('Membuka Form View ' . $this->title);
		$this->template->load('main', $this->folder . '/view_competitor', $data);
	}

	public function edit_competitor()
	{
		$id_product = $this->input->get('id_product');
		$id_customer = $this->input->get('id_customer');

		if ($id_product == null or $id_customer == null) {
			return $this->index_v2();
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/bootstrap4-editable/bootstrap-editable.min.js',
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		
		$customer = $this->mymodel->get_customer(null, $id_customer)->row();
		$product = $this->mymodel->get_product_customer_berjalan($id_product, $id_customer)->row();
		$all_competitor = $this->mymodel->get_product_competitor($id_product, $id_customer);

		$data = [
			'customer' => $customer,
			'product' => $product,
			'all_competitor' => $all_competitor,
		];

		$this->logger->write('Membuka Form Edit ' . $this->title);
		$this->template->load('main', $this->folder . '/edit_competitor', $data);
	}

	public function report_competitor()
	{
		$id_product = $this->input->get('id_product');
		$id_customer = $this->input->get('id_customer');

		if ($id_product == null or $id_customer == null) {
			return $this->index_v2();
		}

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/bootstrap4-editable/bootstrap-editable.min.js',
				'assets/js/' . $this->folder . '/edit.js?v=' . strtotime(date('Y-m-d H:i:s')),
			)
		);

		$customer = $this->mymodel->get_customer(null, $id_customer)->row();
		$product = $this->mymodel->get_product_customer_berjalan($id_product, $id_customer)->row();
		$all_competitor = $this->mymodel->get_product_competitor_rekap($id_product, $id_customer);

		$data = [
			'customer' => $customer,
			'product' => $product,
			'all_competitor' => $all_competitor,
			'db' => $this->db
		];

		$this->logger->write('Membuka Form View ' . $this->title);
		$this->template->load('main', $this->folder . '/report_competitor', $data);
	}

}