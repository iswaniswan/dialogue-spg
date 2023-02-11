<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Gantipassword extends CI_Controller
{
	public $id_menu = '104';

	public function __construct()
	{
		parent::__construct();
		cek_session();

		$this->color    = $this->session->color;
		$this->i_level    = $this->session->i_level;

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('m' . 'gantipassword', 'mymodel');
	}

    /** Default Controllers */
	public function index()
	{
		redirect(base_url(), 'refresh');
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

	/** Redirect ke Form Edit */
	public function edit()
	{

		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/forms/styling/switch.min.js',
				'assets/js/gantipassword/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
			'company' => $this->mymodel->get_company(decrypt_url($this->uri->segment(3))),
			'brand'   => $this->mymodel->get_brand_data(decrypt_url($this->uri->segment(3))),
			'level'   => $this->db->get_where('tr_level', ['f_status' => 't']),
		);
		$this->logger->write('Membuka Form Edit ' . 'user');
		$this->template->load('main', 'gantipassword' . '/edit', $data);
	}

	/** Update Data */
	public function update()
	{

		$this->form_validation->set_rules('iduser', 'iduser', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('username', 'username', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('passwordold', 'passwordold', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('password', 'password', 'trim|required|min_length[0]');
		$username = $this->input->post('username');
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
					$this->logger->write('Update Data ' . 'user' . ' : ' . $username);
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
				$this->logger->write('Update Status ' . 'User' . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}
}
