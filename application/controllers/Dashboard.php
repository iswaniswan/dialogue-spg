<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Dashboard extends CI_Controller
{

	public $id_menu = '0';

	public function __construct()
	{
		parent::__construct();
		cek_session();
		/** Cek Hak Akses, Apakah User Bisa Read */
		$data = check_role($this->id_menu, 2);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->id_user	 = $this->session->id_user;

		/** Deklarasi Nama Folder, Title dan Icon */
		$this->folder 	 = $data->e_folder;
		$this->subfolder = $data->e_sub_folder;
		$this->title	 = $data->e_menu;
		$this->icon		 = $data->icon;
		$this->control 	 = $data->e_folder;
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'global_assets/js/plugins/visualization/echarts/echarts.min.js',
				'assets/js/' . $this->folder . '/index.js',
			)
		);
		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index');
	}

	/** Chart History Tiket */
	public function history_chart()
	{
		$year = $this->input->get('year', TRUE);
		$data = [];
		$data = array(
			'bulan' 	=> $this->mymodel->get_bulan($year)->result(), 
			'company' 	=> $this->mymodel->get_company()->result(), 
			'query' 	=> $this->mymodel->get_chart_history($year)->result(),
		);
		echo json_encode($data);
	}
}
