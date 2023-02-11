<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Pembelian extends CI_Controller
{
	public $id_menu = '2';

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

		$this->color   		= $this->session->color;
		$this->fallcustomer = $this->session->F_allcustomer;
		$this->id_user  	= $this->session->id_user;
		$this->i_company 	= $this->session->i_company;
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

		$datefrom 	= date('Y-m-d', strtotime($dfrom));
		$dateto 	= date('Y-m-d', strtotime($dto));

		$data = array(
			'dfrom' => $dfrom,
			'dto'	=> $dto,
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
		echo $this->mymodel->serverside($dfrom, $dto);
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
				'assets/js/' . $this->folder . '/add.js',
			)
		);

		$data = array(
			'company'	=> $this->mymodel->get_company_data(),
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

		$this->form_validation->set_rules('icompany', 'icompany', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('dfrom', 'dfrom', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('dto', 'dto', 'trim|required|min_length[0]');
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan Data */
			$this->db->trans_begin();
			$this->mymodel->save();
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Simpan Data ' . $this->title);
				$data = array(
					'sukses' => true,
					'ada'	 => false,
				);
			}
		}
		echo json_encode($data);
	}

	/** View */
	public function view()
	{
		/** Cek Hak Akses, Apakah User Bisa Lihat */
		$data = check_role($this->id_menu, 2);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}

		$id = decrypt_url($this->uri->segment(3));

		$data = array(
			'data' 	  => $this->mymodel->get_data($id)->row(),
			'detail'  => $this->db->get_where('tm_pembelian_item',['id_document'=>$id]),
		);
		$this->logger->write('Membuka Form Detail ' . $this->title);
		$this->template->load('main', $this->folder . '/view', $data);
	}

	/** Cancel */
	public function cancel()
	{
		/** Cek Hak Akses, Apakah User Bisa Edit */
		$data = check_role($this->id_menu, 4);
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
			$this->mymodel->cancel($id);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Cancel ' . $this->title . ' Id : ' . $id);
				$data = array(
					'sukses' => true,
				);
			}
		}
		echo json_encode($data);
	}

	public function CurlDataPembelian()
	{
		/** Simpan Data */
		$this->db->trans_begin();
		$this->mymodel->trasferdata();
		if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			echo "Gagal";
		} else {
			$this->db->trans_commit();
			$this->logger->write('Simpan Transfer Data Pembelian ' . $this->title);
			echo '<div class="card-body">
			<p class="mb-3">Examples of <code>rounded</code> alerts. By default, all alerts have <code>3px</code> border radius. You can increase it by adding <code>.alert-rounded</code> class to any type of alert: basic, bordered, styled with arrows and solid. This class also increases side padding and border widths in alerts for better appearance. The main benefit of rounded alerts - they dont look like any element on the page.</p>

			<div class="row">
				<div class="col-lg-6">
					<p class="font-weight-semibold">Primary alert</p>
					<div class="alert alert-primary alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Morning!</span> Were glad to see you again and wish you a nice day.
					</div>

					<p class="font-weight-semibold">Danger alert</p>
					<div class="alert alert-danger alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Oh snap!</span> Change a few things up and try submitting again.
					</div>

					<p class="font-weight-semibold">Success alert</p>
					<div class="alert bg-success text-white alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Well done!</span> You successfully read this important alert message.
					</div>
				</div>

				<div class="col-lg-6">
					<p class="font-weight-semibold">Warning alert</p>
					<div class="alert alert-warning alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Warning!</span> Better check yourself, youre not looking too good.
					</div>

					<p class="font-weight-semibold">Info alert</p>
					<div class="alert alert-info alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Heads up!</span> This alert needs your attention, but its not super important.
					</div>

					<p class="font-weight-semibold">Custom color</p>
					<div class="alert bg-teal text-white alert-rounded alert-dismissible">
						<button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
						<span class="font-weight-semibold">Surprise!</span> This is a super-duper nice looking alert with custom color.
					</div>
				</div>
			</div>
		</div>';
		}
	}
}
