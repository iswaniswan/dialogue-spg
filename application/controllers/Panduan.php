<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Panduan extends CI_Controller
{
	public $id_menu = '7';

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

		set_current_active_menu($this->title);
	}

	/** Default Controllers */
	public function index()
	{
		add_js(
			array(
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
				'assets/js/' . $this->folder . '/index.js',
			)
		);
		$data = array(
			'datafile' => $this->mymodel->getdata(), 
		);
		$this->logger->write('Membuka Menu '.$this->title);
		$this->template->load('main', $this->folder . '/index', $data);
	}

	/** Delete File */
	public function deletefile()
	{
		/** Cek Hak Akses, Apakah User Bisa Hapus */
		$data = check_role($this->id_menu, 4);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('attachment', 'attachment', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('path', 'path', 'trim|required|min_length[0]');
		$id = $this->input->post('id', TRUE);	
		$attachment = $this->input->post('attachment', TRUE);	
		$path = $this->input->post('path', TRUE);	
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
			);
		} else {
			$this->db->trans_begin();
			$this->mymodel->deletefile($id,$attachment,$path);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Hapus File Attachment ' . $this->title . ' Id : ' . $id.' Nama File : '.$attachment);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}
}