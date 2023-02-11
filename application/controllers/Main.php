<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Main extends CI_Controller
{
	
	public function __construct()
	{
		parent::__construct();
		cek_session();
		$this->folder 	 = 'dashboard';
		$this->id_user	 = $this->session->id_user;
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
		
		$this->template->load('main', $this->folder . '/index');
	}

	// public function cek_notif()
	// {
	// 	$querysaldo = $this->mymodel->get_notif_saldo();
	// 	$queryretur = $this->mymodel->get_notif_retur();
	// 	$queryadjust = $this->mymodel->get_notif_adjust();
	// }
}
