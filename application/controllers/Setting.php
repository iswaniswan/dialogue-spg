<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Setting extends CI_Controller
{
	public $id_menu = '803';

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

	public function index()
	{
		add_js(
			array(
				'global_assets/js/plugins/tables/datatables/datatables.min.js',
				'global_assets/js/plugins/tables/datatables/extensions/natural_sort.js',
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/setting/index.js',
			)
		);
		$this->logger->write('Membuka Menu ' . $this->folder);
		$this->template->load('main', $this->folder . '/index');
	}

	public function serverside()
	{
		echo $this->mymodel->serverside();
	}

	public function update()
	{
		$id = decrypt_url($this->uri->segment(3));
		add_js(
			array(
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/setting/update.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
			)
		);

		$data = array(
			'cekdata'	=> $this->mymodel->cek_data($id)->result(),
			'userpower' => $this->mymodel->userpower()->result(),
			'level'		=> $id,
			'elevel'	=> $this->mymodel->cek_level($id)->row(),
		);
		$this->logger->write('Membuka Menu Update ' . $this->folder);
		$this->template->load('main', $this->folder . '/update', $data);
	}

	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('jml', 'jml', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ilevel', 'ilevel', 'trim|required|min_length[0]');

		$jml   		= $this->input->post("jml", TRUE);
		$ilevel   	= $this->input->post("ilevel", TRUE);

		for ($i = 1; $i <= $jml; $i++) {
			$this->form_validation->set_rules('idmenu' . $i, 'idmenu' . $i, 'trim|required|min_length[0]');
		}
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			$power = $this->mymodel->userpower();
			if ($power->num_rows() > 0) {
				foreach ($power->result() as $key) {
					for ($i = 1; $i <= $jml; $i++) {
						$i_menu  = $this->input->post('idmenu' . $i, TRUE);

						/*Get post nama userpower dari view sesuai nama yang ada didatabase*/
						$cek     = $this->input->post(strtolower($key->e_name) . $i, TRUE);
						if ($cek == 'on') {
							$this->mymodel->insertdetail($i_menu, $key->id, $ilevel);
						} else {
							$this->mymodel->deletedetail($i_menu, $key->id, $ilevel);
						}
					}
				}
			}
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update ' . $this->folder);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
		}
		echo json_encode($data);
	}

	public function view()
	{
		$id = decrypt_url($this->uri->segment(3));
		add_js(
			array(
				'global_assets/js/plugins/forms/selects/select2.min.js',
				'assets/js/setting/update.js',
				'global_assets/js/plugins/forms/styling/uniform.min.js',
				'global_assets/js/plugins/forms/validation/validate.min.js',
				'global_assets/js/plugins/notifications/sweet_alert.min.js',
			)
		);

		$data = array(
			'cekdata'	=> $this->mymodel->cek_data($id)->result(),
			'userpower' => $this->mymodel->userpower()->result(),
			'level'		=> $id,
			'elevel'	=> $this->mymodel->cek_level($id)->row(),
		);
		$this->logger->write('Membuka Menu View ' . $this->folder);
		$this->template->load('main', $this->folder . '/view', $data);
	}
}
