<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Mutasi extends CI_Controller
{
	public $id_menu = '5';

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

		$this->color    	= $this->session->color;
		$this->id_user  	= $this->session->id_user;
		$this->i_company 	= $this->session->i_company;
		$this->fallcustomer = $this->session->F_allcustomer;
		$this->i_level = $this->session->i_level;

		$this->load->library('fungsi');

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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'assets/js/' . $this->folder . '/index.js',
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
		$idcustomer = $this->input->post('idcustomer', TRUE);
		if ($idcustomer == null || $idcustomer == "") {
			$idcustomer = 'all';
		}

		$ecustomer = 'SEMUA';
		if ($idcustomer!='all') {
			$ecustomer = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$idcustomer' ", FALSE)->row()->e_customer_name;
		}

		$datefrom 	= date('Y-m-d', strtotime($dfrom));
		$dateto 	= date('Y-m-d', strtotime($dto));

		$data = array(
			'dfrom' 	=> $dfrom,
			'dto'		=> $dto,
			'idcustomer'=> $idcustomer,
			'ecustomer'	=> $ecustomer,
			'company'	=> $this->mymodel->get_company(),
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
		$id_customer 	= $this->input->post('id_customer', TRUE);
		echo $this->mymodel->serverside($dfrom, $dto, $id_customer);
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$filter[] = array(
			'id'   => 'all',
			'text' => "SEMUA",
		);
		$cari	= str_replace("'", "", $this->input->get('q'));
		/* if ($cari != '') { */
			$data = $this->mymodel->get_customer($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id_customer,
					'text' => strtoupper($row->e_customer_name),
				);
			}
		/* } else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Cari Data Berdasarkan Nama',
			);
		} */
		echo json_encode($filter);
	}
}
