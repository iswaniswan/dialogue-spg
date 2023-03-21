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

class LaporanKategoripenjualan extends CI_Controller
{ 
    public $id_menu = '601';

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

		/** Load Model, Nama model harus sama dengan nama folder */
		$this->load->model('m' . $this->folder, 'mymodel');
	}

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
				'assets/js/' . $this->folder . '/index.js?v=1',
			)
		);

		// $data = array(
		// 	'data' => $this->mymodel->serverside()
		// );

		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index');
	}

    /** List Data */
	public function serverside()
	{
		echo $this->mymodel->serverside();
	}

	public function get_customer()
	{
		$filter = [];

		/** SEMUA */
		$filter[] = [
			'id' => 'null',
			'text' => 'SEMUA'
		];

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

    public function get_user_customer_brand()
	{
		$cari	= str_replace("'", "", $this->input->get('q'));
		$id_user = $this->session->userdata('id_user');
		$id_customer = $this->input->get('id_customer');
		
		$filter = [];			

		/** SEMUA */
		$filter[] = [
			'id' => 'null',
			'text' => 'SEMUA'
		];	

		if ($id_customer == null or $id_customer == 'null') {
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
        $id_customer = $this->uri->segment(3);
        $id_brand = $this->uri->segment(4);

        if ($id_customer == 'null') {
            $id_customer = null;
        }

        if ($id_brand == 'null') {
            $id_brand = null;
        }

        /** init date */
        $first_date = '2022-01-01';
        $dfrom = date('Y-m-d');
        $dto = date('Y-m-t', strtotime($dfrom));

        $last_date_before_from = strtotime('-1 day', strtotime($dfrom));
        $last_date_before_from = date('Y-m-d', $last_date_before_from);

        $title = "Laporan Kategori Penjualan";
        if ($id_customer != null) {
            $customer = $this->mymodel->get_customer("", $id_customer)->row();
            $title .= " - $customer->e_customer_name";
        }

        $query = $this->mymodel->calc_product_category($first_date, $last_date_before_from, $dfrom, $dto, $id_customer, $id_brand);
        
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

        foreach(range('A','I') as $columnID) {
          $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }
        
        $spreadsheet->setActiveSheetIndex(0)
                    ->setCellValue('A1', "$title");
        $spreadsheet->getActiveSheet()->setTitle('Laporan');
        $spreadsheet->getActiveSheet()->mergeCells("A1:J1");
        $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:J1');

        $spreadsheet->setActiveSheetIndex(0)
                    ->setCellValue('A2', 'No')
                    ->setCellValue('B2', 'Toko')
                    ->setCellValue('C2', 'Kode')
                    ->setCellValue('D2', 'Barang')
                    ->setCellValue('E2', 'Brand')
                    ->setCellValue('F2', 'Tanggal Terakhir')
                    ->setCellValue('G2', 'Keterangan Tanggal')
                    ->setCellValue('H2', 'Qty')
                    ->setCellValue('I2', 'Selisih (Hari)')
                    ->setCellValue('J2', 'Kategori');
          
        $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A2:J2');

        $kolom = 3;
        $nomor = 1;
        foreach($query->result() as $row) {
            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->customer)
                        ->setCellValue('C' . $kolom, $row->i_product)
                        ->setCellValue('D' . $kolom, $row->e_product_name)
                        ->setCellValue('E' . $kolom, $row->e_brand_name)
                        ->setCellValue('F' . $kolom, $row->tanggal)
                        ->setCellValue('G' . $kolom, $row->tanggal_keterangan)
                        ->setCellValue('H' . $kolom, $row->saldo_akhir)
                        ->setCellValue('I' . $kolom, $row->jarak)
                        ->setCellValue('J' . $kolom, $row->kategori);
            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, "A$kolom:J$kolom");

            $kolom++;
            $nomor++;
        }

        /** info */
        $info_rows = [
            '*Keterangan Kategori: ',
            'Fast Moving = Produk terjual dalam waktu <= 30 hari',
            'Medium = Produk terjual dalam rentang waktu 31 >= x <= 90 hari',
            'Slow Moving = Produk terjual dalam rentang waktu 91 >= x <= 180 hari',
            'STP = Produk terjual dalam waktu >= 181 hari',
        ];

        $kolom += 2;
        foreach($info_rows as $row) {
            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $row);

            $kolom++;
        }

        /** re-set width column A */
        $spreadsheet->getActiveSheet()->getColumnDimension('A')->setAutoSize(false);
        $spreadsheet->getActiveSheet()->getColumnDimension('A')->setWidth(5);

        $writer = new Xls($spreadsheet);
        $nama_file = "Laporan_kategori_penjualan.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');
	} 
	
}