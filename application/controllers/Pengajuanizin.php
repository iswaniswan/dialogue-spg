<?php
defined('BASEPATH') or exit('No direct script access allowed');

class PengajuanIzin extends CI_Controller
{
	public $id_menu = '1002';

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
				'assets/js/' . $this->folder . '/index.js?v=1',
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'global_assets/js/plugins/ui/moment/moment.min.js',
				'assets/js/' . $this->folder . '/add.js?v=1',
			)
		);
		$this->logger->write('Membuka Form Tambah '.$this->title);
		$this->template->load('main', $this->folder . '/add');
	}

	public function view()
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'assets/js/' . $this->folder . '/add.js?v=1',
			)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

		$this->logger->write('Membuka Form View '.$this->title);
		$this->template->load('main', $this->folder . '/view', $data);
	}

	/** Simpan Data */
	public function save()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$id_user = $this->input->post('id_user');
		if ($id_user == null) {
			$id_user = $this->session->userdata('id_user');
		}

		$id_jenis_izin = $this->input->post('id_jenis_izin');

		$d_pengajuan_mulai_tanggal = $this->input->post('d_pengajuan_mulai_tanggal');
		$d_pengajuan_mulai_pukul = $this->input->post('d_pengajuan_mulai_pukul');
		$d_pengajuan_mulai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_mulai_tanggal $d_pengajuan_mulai_pukul:00");		

		$d_pengajuan_selesai_tanggal = $this->input->post('d_pengajuan_selesai_tanggal');
		$d_pengajuan_selesai_pukul = $this->input->post('d_pengajuan_selesai_pukul');
		$d_pengajuan_selesai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_selesai_tanggal $d_pengajuan_selesai_pukul:00");		

		$e_remark = $this->input->post('e_remark');

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();

		// $this->mymodel->save($e_izin_name);
		$this->mymodel->insert_izin($id_user, $id_jenis_izin);

		$insert_id = $this->db->insert_id();

		$this->mymodel->insert_izin_item(
			$id_izin=$insert_id, 
			$d_pengajuan_mulai=$d_pengajuan_mulai->format('Y-m-d H:i:s'), 
			$d_pengajuan_selesai=$d_pengajuan_selesai->format('Y-m-d H:i:s'), 
			$e_remark
		);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $insert_id);

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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'assets/js/' . $this->folder . '/edit.js?v=1',
			)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

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

		$id = $this->input->post('id');
		$id_user = $this->input->post('id_user');
		if ($id_user == null) {
			$id_user = $this->session->userdata('id_user');
		}

		$id_jenis_izin = $this->input->post('id_jenis_izin');

		$d_pengajuan_mulai_tanggal = $this->input->post('d_pengajuan_mulai_tanggal');
		$d_pengajuan_mulai_pukul = $this->input->post('d_pengajuan_mulai_pukul');
		$d_pengajuan_mulai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_mulai_tanggal $d_pengajuan_mulai_pukul:00");		

		$d_pengajuan_selesai_tanggal = $this->input->post('d_pengajuan_selesai_tanggal');
		$d_pengajuan_selesai_pukul = $this->input->post('d_pengajuan_selesai_pukul');
		$d_pengajuan_selesai = date_create_from_format('Y-m-d H:i:s', "$d_pengajuan_selesai_tanggal $d_pengajuan_selesai_pukul:00");		

		$e_remark = $this->input->post('e_remark');

		$e_remark = $this->input->post('e_remark');

		$data = [
			'sukses' => false,
			'ada'	 => false,
		];

		$this->db->trans_begin();               

		$this->mymodel->update_izin($id_user, $id_jenis_izin, $id);

		$this->mymodel->delete_izin_item($id_izin=$id);

		$this->mymodel->insert_izin_item(
			$id_izin=$id, 
			$d_pengajuan_mulai=$d_pengajuan_mulai->format('Y-m-d H:i:s'), 
			$d_pengajuan_selesai=$d_pengajuan_selesai->format('Y-m-d H:i:s'), 
			$e_remark
		);

		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo json_encode($data);
			return;
		} 

		$this->db->trans_commit();
		$this->logger->write('Simpan Data ' . $this->title . ' : ' . $id);

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

	public function get_list_jenis_izin()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_list_jenis_izin($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_izin_name),
			);
		}
		echo json_encode($filter);
	}

	public function approvement()
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/pickers/anytime.min.js',
				'assets/js/' . $this->folder . '/approve.js?v=1',
			)
		);

		$id = $this->uri->segment(3);
		$id = decrypt_url($id);

		$data = [
			'data' => $this->mymodel->get_data($id)->row()
		];

		$this->logger->write('Membuka Form Edit '.$this->title);
		$this->template->load('main', $this->folder . '/approve', $data);		
	}

	public function approve()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 5);
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
			$this->mymodel->approve($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Approve ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function reject()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 5);
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
			$this->mymodel->reject($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Reject ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

}