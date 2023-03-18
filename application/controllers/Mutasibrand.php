<?php
defined('BASEPATH') or exit('No direct script access allowed');

use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xls;
use PhpOffice\PhpSpreadsheet\Style\Border;
/* use PhpOffice\PhpSpreadsheet\Style\Fill; */
use PhpOffice\PhpSpreadsheet\Style\Style;
/* use PhpOffice\PhpSpreadsheet\Style\Alignment; */
use PhpOffice\PhpSpreadsheet\Style\Conditional;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\IOFactory;

class Mutasibrand extends CI_Controller
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
		 $idbrand = $this->input->post('idbrand', TRUE);
		// if ($idcustomer == null || $idcustomer = '') {
		// 	$idcustomer = 'all';
		// }

		$ecustomer = '';
		if ($idcustomer!='' && $idcustomer!='all') {
			$ecustomer = $this->db->query("SELECT e_customer_name FROM tr_customer WHERE id_customer = '$idcustomer'", FALSE)->row()->e_customer_name;
		}
		else {
			$ecustomer = '';
		}

		$datefrom 	= date('Y-m-d', strtotime($dfrom));
		$dateto 	= date('Y-m-d', strtotime($dto));

		$id_user = $this->id_user;

		if($id_user === '1'){
			$id_user = 'NULL';
		}


		if ($this->fallcustomer == 't') {
			$query2 = $this->db->query("select id_customer, e_customer_name from tr_customer;", FALSE);
		} else {
			$query2 = $this->db->query("SELECT id_customer, e_customer_name FROM tr_customer WHERE id_customer IN (SELECT id_customer FROM tm_user_customer WHERE id_user = '$this->id_user');", FALSE);
		}
		$data = array(
			'dfrom' 	=> $dfrom,
			'dto'		=> $dto,
			'idcustomer'=> $idcustomer,
			'idbrand'	=> $idbrand,
			'ecustomer'	=> $ecustomer,
			'company'	=> $this->mymodel->get_company(),
			'listcustomer'	=> $query2->result(),
			// 'listbrand'	=> $this->mymodel->get_brand($id_user)->result(),
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
		$id_customer 	= $this->input->post('idcustomer', TRUE);
		$id_brand 	= $this->input->post('idbrand', TRUE);

		// var_dump($id_customer);
		// die();
		// if($id_customer == null || $id_customer == ''){
		// 	$id_customer = 'null';
		// }
		echo $this->mymodel->serverside($dfrom, $dto, $id_customer, $id_brand);
	}

	/** Get Customer */
	public function get_customer()
	{
		$filter = [];
		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_customer($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id_customer,
				'text' => strtoupper($row->e_customer_name),
			);
		}
		echo json_encode($filter);
	}


	/** Get Customer */
	public function get_brand()
	{
		$filter = [];
		$filter[] = array(
			'id'   => 'all',
			'text' => "SEMUA",
		);
		$cari	= str_replace("'", "", $this->input->get('q'));
		/* if ($cari != '') { */
			$data = $this->mymodel->get_brand($cari);
			foreach ($data->result() as $row) {
				$filter[] = array(
					'id'   => $row->id_brand,
					'text' => strtoupper($row->e_brand_name),
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

	public function get_user_customer_brand()
	{
		$cari	= str_replace("'", "", $this->input->get('q'));
		$id_user = $this->session->userdata('id_user');
		$id_customer = $this->input->get('id_customer');
		
		$filter = [];		

		if ($id_customer == null) {
			return $filter;
		}

		$data = $this->mymodel->get_user_customer_brand($cari, $id_user, $id_customer);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id,
				'text' => strtoupper($row->e_brand_name),
			);
		}
		echo json_encode($filter);
	}

	public function export_excel()
	{
		$id = $this->uri->segment(3);
		$brand = $this->uri->segment(4);
		$dfrom = $this->uri->segment(5);
		$dto = $this->uri->segment(6);

		var_dump($dfrom.' '.$dto);

        $query = $this->mymodel->export_data($id,$brand,$dfrom,$dto);

        if ($query) {

            $spreadsheet = new Spreadsheet;
            $sharedStyle1 = new Style();
            $sharedStyle2 = new Style();
            $sharedStyle3 = new Style();
            $conditional3 = new Conditional();
            $spreadsheet->getActiveSheet()->getStyle('B2')->getAlignment()->applyFromArray(
                [
                    'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
                    'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER, 'textRotation' => 0, 'wrapText' => TRUE
                ]
            );

            $sharedStyle1->applyFromArray(
                [
                    'alignment' => [
                        'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
                        'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
                    ],
                    'borders' => [
                        'bottom' => ['borderStyle' => Border::BORDER_THIN],
                        'right' => ['borderStyle' => Border::BORDER_THIN],
                    ],
                ]
            );

            $sharedStyle2->applyFromArray(
                [
                    'font' => [
                        'name'  => 'Arial',
                        'bold'  => false,
                        'italic' => false,
                        'size'  => 10
                    ],
                    'borders' => [
                        'top'    => ['borderStyle' => Border::BORDER_THIN],
                        'bottom' => ['borderStyle' => Border::BORDER_THIN],
                        'left'   => ['borderStyle' => Border::BORDER_THIN],
                        'right'  => ['borderStyle' => Border::BORDER_THIN]
                    ],
                    'alignment' => [
                        'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
                    ],
                ]
            );

            
        $sharedStyle3->applyFromArray(
            [
                'alignment' => [
                'horizontal' => \PhpOffice\PhpSpreadsheet\Style\Alignment::HORIZONTAL_CENTER,
                'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
                ],
            ]
        );
        $spreadsheet->getDefaultStyle()
        ->getFont()
        ->setName('Calibri')
        ->setSize(9);
        foreach(range('A','N') as $columnID) {
          $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }
            $spreadsheet->setActiveSheetIndex(0)
                      ->setCellValue('A1', 'Mutasi Brand');
            $spreadsheet->getActiveSheet()->setTitle('Laporan');
            $spreadsheet->getActiveSheet()->mergeCells("A1:G1");
            $spreadsheet->setActiveSheetIndex(0)
                      ->setCellValue('A2', 'No')
                      ->setCellValue('B2', 'Toko')
                      ->setCellValue('C2', 'Kode')
                      ->setCellValue('D2', 'Barang')
                      ->setCellValue('E2', 'Brand')
                      ->setCellValue('F2', 'Saldo Awal')
                      ->setCellValue('G2', 'Pembelian')
                      ->setCellValue('H2', 'Retur')
                      ->setCellValue('I2', 'Penjualan')
					  ->setCellValue('J2', 'Adjustment')
                      ->setCellValue('K2', 'Saldo Akhir')
					  ->setCellValue('L2', 'Stock Opname')
					  ->setCellValue('M2', 'Selisih')
					  ->setCellValue('N2', 'Keterangan');
          
          $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A2:N2');

          $kolom = 3;
          $nomor = 1;
          foreach($query->result() as $row) {
            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->e_customer_name)
                        ->setCellValue('C' . $kolom, $row->i_product)
                        ->setCellValue('D' . $kolom, $row->e_product_name)
                        ->setCellValue('E' . $kolom, $row->e_brand_name)
                        ->setCellValue('F' . $kolom, $row->saldo_awal)
                        ->setCellValue('G' . $kolom, $row->pembelian)
                        ->setCellValue('H' . $kolom, $row->retur)
                        ->setCellValue('I' . $kolom, $row->penjualan)
						->setCellValue('J' . $kolom, $row->adjustment)
                        ->setCellValue('K' . $kolom, $row->saldo_akhir)
						->setCellValue('L' . $kolom, $row->stock_opname)
						->setCellValue('M' . $kolom, $row->selisih)
						->setCellValue('N' . $kolom, $row->keterangan);
            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A'.$kolom.':N'.$kolom);

                 $kolom++;
                 $nomor++;
        }
        $writer = new Xls($spreadsheet);
        $nama_file = "Mutasi Brand.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');
        }
	} 
}
