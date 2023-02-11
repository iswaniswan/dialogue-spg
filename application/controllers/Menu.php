<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Menu extends CI_Controller
{
	public $id_menu = '802';

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

		$data = array(
			'power' => $this->db->get('tr_user_power'), 
		);
		$this->logger->write('Membuka Form Tambah '.$this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	/** Get Menu */
	public function get_menu()
    {
       	$filter = [];
		$filter[] = array(
			'id'   => 0,
			'text' => "# - Default",
		);
        $data = $this->mymodel->get_menu($this->input->get('q'));
        foreach ($data->result() as $row) {
            $filter[] = array(
                'id'   => $row->id_menu,
                'text' => $row->id_menu.' - '.$row->e_menu,
            );
        }
        echo json_encode($filter);
            
    }

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$this->form_validation->set_rules('idmenu', 'idmenu', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('iparent', 'iparent', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('emenu', 'emenu', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('nurut', 'nurut', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Cek Jika Nama Sudah Ada */
			$cek = $this->mymodel->cek($this->input->post('idmenu', TRUE));
			/** Jika Sudah Ada Jangan Disimpan */
			if ($cek->num_rows() > 0) {
				$data = array(
					'sukses' => false,
					'ada'	 => true,
				);
			} else {
				/** Jika Belum Ada Simpan Data */
				$this->db->trans_begin();
				$iparent = $this->input->post('iparent', TRUE);
				$idmenu = $this->input->post('idmenu', TRUE);
				$emenu = ucwords($this->input->post('emenu', TRUE));
				$nurut = $this->input->post('nurut', TRUE);
				$efolder = $this->input->post('efolder', TRUE);
				$icon = $this->input->post('icon', TRUE);
				$ipower = $this->input->post('ipower', TRUE);
				$this->mymodel->save($iparent,$idmenu,$emenu,$nurut,$efolder,$icon,$ipower);
				if ($this->db->trans_status() === FALSE) {
					$this->db->trans_rollback();
					$data = array(
						'sukses' => false,
						'ada'	 => false,
					);
				} else {
					$this->db->trans_commit();
					$this->logger->write('Simpan Data '.$this->title.' : '.$idmenu);
					$data = array(
						'sukses' => true,
						'ada'	 => false,
					);
				}
			}
		}
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
			'power'=> $this->mymodel->get_power(decrypt_url($this->uri->segment(3))),
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

		$this->form_validation->set_rules('idmenuold', 'idmenuold', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idmenu', 'idmenu', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('iparent', 'iparent', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('emenu', 'emenu', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('nurut', 'nurut', 'trim|required|min_length[0]');
		$iparent = $this->input->post('iparent', TRUE);
		$idmenu = $this->input->post('idmenu', TRUE);
		$idmenuold = $this->input->post('idmenuold', TRUE);
		$emenu = ucwords($this->input->post('emenu', TRUE));
		$nurut = $this->input->post('nurut', TRUE);
		$efolder = $this->input->post('efolder', TRUE);
		$icon = $this->input->post('icon', TRUE);
		$ipower = $this->input->post('ipower', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Cek Jika Nama Sudah Ada */
			$cek = $this->mymodel->cek_edit($idmenu,$idmenuold);
			/** Jika Sudah Ada Jangan Disimpan */
			if ($cek->num_rows() > 0) {
				$data = array(
					'sukses' => false,
					'ada'	 => true,
				);
			} else {
				/** Jika Belum Ada Update Data */
				$this->db->trans_begin();				
				$this->mymodel->update($iparent,$idmenu,$emenu,$nurut,$efolder,$icon,$idmenuold,$ipower);
				if ($this->db->trans_status() === FALSE) {
					$this->db->trans_rollback();
					$data = array(
						'sukses' => false,
						'ada'	 => false,
					);
				} else {
					$this->db->trans_commit();
					$this->logger->write('Update Data '.$this->title.' : '.$idmenu);
					$data = array(
						'sukses' => true,
						'ada'	 => false,
					);
				}
			}
		}
		echo json_encode($data);
	}
}