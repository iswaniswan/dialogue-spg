<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Retur extends CI_Controller
{
	public $id_menu = '3';

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
		$this->fallcustomer = $this->session->F_allcustomer;
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
				'global_assets/js/plugins/uploaders/fileinput/fileinput.min.js',
				'assets/js/' . $this->folder . '/add.js',
			)
		);

		$data = array(
			'number'  => $this->mymodel->runningnumber(date('Ym'), date('Y')),
		);

		$this->logger->write('Membuka Form Tambah ' . $this->title);
		$this->template->load('main', $this->folder . '/add', $data);
	}

	public function detailupload()
	{
		redirect(base_url().'retur', 'refresh');
	}

	/** Get Nomor Dokument */
	public function number()
	{
		$number = "";
		$tgl 	= $this->input->post('tgl', TRUE);
		if ($tgl != '') {
			$number = $this->mymodel->runningnumber(date('Ym'), date('Y'));
		}
		echo json_encode($number);
	}

	/** Get Company */
	public function get_company()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data 	= $this->mymodel->get_company_data($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->i_company,
				'text' => strtoupper($row->e_company_name),
			);
		}
		echo json_encode($filter);
	}

	/** Get Alasan */
	public function get_alasan()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data 	= $this->mymodel->get_alasan($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->i_alasan,
				'text' => $row->e_alasan,
			);
		}
		echo json_encode($filter);
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
		$id_customer = $this->input->post('id_customer', TRUE);
		$query  = $this->mymodel->get_detail_customer($id_customer)->row();
		echo json_encode($query);
	}

	/** Get Product */
	public function get_product()
	{
		$filter = [];
		/* $i_company = $this->input->get('i_company'); */
		$cari	= str_replace("'", "", $this->input->get('q'));
		/* if ($i_company != '') { */
			if ($cari != '') {
				$data = $this->mymodel->get_product(/* $i_company,  */$cari);
				foreach ($data->result() as $row) {
					$filter[] = array(
						'id'   => $row->i_product . ' - ' . $row->id_brand,
						'text' => $row->i_product . ' - ' . $row->e_product_name . ' - ' . $row->e_brand_name,
					);
				}
			} else {
				$filter[] = array(
					'id'   => null,
					'text' => 'Cari Berdasarkan Kode / Nama Barang!',
				);
			}
		/* } else {
			$filter[] = array(
				'id'   => null,
				'text' => 'Perusahaan Harus Dipilih!',
			);
		} */
		echo json_encode($filter);
	}

	/** Get Detail Product */
	public function get_detail_product()
	{
		header("Content-Type: application/json", true);
		$i_product = $this->input->post('i_product', TRUE);
		$i_brand = $this->input->post('i_brand', TRUE);
		/* $i_company = $this->input->post('i_company', TRUE); */
		$query  = array(
			'detail' => $this->mymodel->get_detail_product($i_product, $i_brand)->result_array()
		);
		echo json_encode($query);
	}

	/** Simpan Data */
	public function prosesupload()
	{
		/** Cek Hak Akses, Apakah User Bisa Create */
		$data = check_role($this->id_menu, 1);
		if (!$data) {
			redirect(base_url(), 'refresh');
		}
		
		$this->form_validation->set_rules('idcustomer', 'idcustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idocument', 'idocuument', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ddocument', 'ddocument', 'trim|required|min_length[0]');

		/** upload */

        $datafoto = [];
        $idocument = $this->input->post('idocument', TRUE);
        $jml = $this->input->post('jml', TRUE);
        for($i=0;$i<$jml;$i++){

            $_FILES['file']['name'] = $_FILES['foto']['name'][$i];
            $_FILES['file']['type'] = $_FILES['foto']['type'][$i]; 
            $_FILES['file']['tmp_name'] = $_FILES['foto']['tmp_name'][$i];
            $_FILES['file']['error'] = $_FILES['foto']['error'][$i];
            $_FILES['file']['size'] = $_FILES['foto']['size'][$i];

            $name       = $_FILES['file']['name'];
            $ext = pathinfo($name, PATHINFO_EXTENSION);
            $cek = $i + 1;
            $filename    = "foto-" . $idocument. "-" . $cek .".".$ext;

            $config = array(
                'upload_path'   => "./upload/images/",
                'allowed_types' => 'jpg|jpeg|png|gif',
                'file_name'     => $filename
            );

            
            $this->load->library('upload', $config);
            $this->upload->initialize($config);
            $upload = $this->upload->do_upload('file');
            if ($upload) {
				$dataupload = $this->upload->data();
                //var_dump("berhasil upload ".$filename);
                $datafoto[] = $filename;
            } else {
                $error = array('error' => $this->upload->display_errors());
                //var_dump($error);
            }
            
        }

        /** upload end */   

		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Simpan Data */
			$idocument  = $this->input->post('idocument', TRUE);
			$idcustomer = $this->input->post('idcustomer', TRUE);
			$cek = $this->mymodel->cek($idocument);
			/** Jika Sudah Ada Jangan Disimpan */
			if ($cek->num_rows() > 0) {
				$data = array(
					'sukses' => false,
					'ada'	 => true,
				);
			} else {

				$this->db->trans_begin();
				$this->mymodel->save($datafoto);
				if ($this->db->trans_status() === FALSE) {
					$this->db->trans_rollback();
					$data = array(
						'sukses' => false,
						'ada'	 => false,
					);
				} else {
					$this->db->trans_commit();
					$this->logger->write('Simpan Data ' . $this->title . ' : ' . $idocument);
					$data = array(
						'sukses' 		=> true,
						'ada'	 		=> false,
						'filename' 		=> $idocument,
						'id'	 		=> $idocument
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
				'global_assets/js/plugins/pickers/pickadate/picker.js',
				'global_assets/js/plugins/pickers/pickadate/picker.date.js',
				'global_assets/js/plugins/uploaders/fileinput/fileinput.min.js',
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
		);
		$this->logger->write('Membuka Form Edit ' . $this->title);
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
		$this->form_validation->set_rules('id', 'id', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idcustomer', 'idcustomer', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('idocument', 'idocuument', 'trim|required|min_length[0]');
		$this->form_validation->set_rules('ddocument', 'ddocument', 'trim|required|min_length[0]');

		/** upload */
		
			$datafoto = [];
			$idocument = $this->input->post('idocument', TRUE);
			$jml = $this->input->post('jml');
			
			for($i=0;$i<$jml;$i++){
				$n = $i +1;
				$foto = $this->input->post('fotolama'.$n, TRUE);


				if(isset($_FILES['foto'.$n]) && !empty($_FILES['foto'.$n]['name'])){
					
					$_FILES['file']['name'] = $_FILES['foto'.$n]['name'];
					$_FILES['file']['type'] = $_FILES['foto'.$n]['type']; 
					$_FILES['file']['tmp_name'] = $_FILES['foto'.$n]['tmp_name'];
					$_FILES['file']['error'] = $_FILES['foto'.$n]['error'];
					$_FILES['file']['size'] = $_FILES['foto'.$n]['size'];
		
					$name       = $_FILES['file']['name'];
					$ext = pathinfo($name, PATHINFO_EXTENSION);
					$cek = $i + 1;
					$filename    = "foto-" . $idocument. "-" . $cek .".".$ext;
					$hapus = "foto-" . $idocument. "-" . $cek;

					if(file_exists("./upload/images/".$hapus.".png")) {
						unlink("./upload/images/".$hapus.".png");
				   }else if(file_exists("./upload/images/".$hapus.".jpg")) {
						unlink("./upload/images/".$hapus.".jpg");
				   }

					if($foto[$i] = $filename){
						$overwrite = true;
					}
					else{
						$overwrite = false;
					}
					
			
					$config = array(
						'upload_path'   => "./upload/images/",
						'allowed_types' => 'jpg|jpeg|png|gif',
						'file_name'     => $filename,
						'overwrite'		=> $overwrite
					);
								
					$this->load->library('upload', $config);
					$this->upload->initialize($config);
					$upload = $this->upload->do_upload('file');
					if ($upload) {
						$dataupload = $this->upload->data();
						//var_dump("berhasil upload ".$filename);
						$datafoto[] = $filename;
					} else {
						$error = array('error' => $this->upload->display_errors());
						//var_dump($error);
					}
					
				}else{					  
					$datafoto[] = $foto;	
				}
			}
			
        /** upload end */   

		$id = $this->input->post('id', TRUE);
		if ($this->form_validation->run() == false) {
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			/** Update Data */
			$this->db->trans_begin();
			$this->mymodel->update($datafoto);
			if ($this->db->trans_status() === FALSE) {
				$this->db->trans_rollback();
				$data = array(
					'sukses' => false,
					'ada'	 => false,
				);
			} else {
				$this->db->trans_commit();
				$this->logger->write('Update Data ' . $this->title . ' ID : ' . $id);
				$data = array(
					'sukses' 	=> true,
					'ada'	 	=> false,
					'filename' 	=> $idocument,
					'id'	 	=> $idocument
				);
			}
		}
		echo json_encode($data);
	}

	/** Redirect ke Form Approvement */
	public function approvement()
	{
		/** Cek Hak Akses, Apakah User Bisa View */
		$data = check_role($this->id_menu, 2);
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
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
		);
		$this->logger->write('Membuka Form Detail ' . $this->title);
		$this->template->load('main', $this->folder . '/approve', $data);
	}

	/** Redirect ke Form View */
	public function view()
	{
		/** Cek Hak Akses, Apakah User Bisa View */
		$data = check_role($this->id_menu, 2);
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
				'assets/js/' . $this->folder . '/edit.js',
			)
		);

		$data = array(
			'data' 	  => $this->mymodel->getdata(decrypt_url($this->uri->segment(3)))->row(),
			'detail'  => $this->mymodel->getdatadetail(decrypt_url($this->uri->segment(3))),
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

	/** Approve */
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

	/** Hapus Foto */
	public function hapusfoto()
	{	
		$alamat = "upload/images/";
		$foto = $this->input->post('foto');
		$hapus = FCPATH.$alamat.$foto;
		if(file_exists($hapus)) {
			unlink($hapus);
	   }
		
	}
}
