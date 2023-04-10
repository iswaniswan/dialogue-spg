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

class LaporanKehadiran extends CI_Controller
{ 
    public $id_menu = '1005';

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

        set_current_active_menu($this->title);
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
                'global_assets/js/plugins/ui/moment/moment.min.js',
				'assets/js/' . $this->folder . '/index.js?v=1',
			)
		);

        $dfrom = date('Y-m-01');
        $dto = date('Y-m-d');

		$data = [
            'dfrom' => $dfrom,
            'dto' => $dto,
        ];

		$this->logger->write('Membuka Menu ' . $this->title);
		$this->template->load('main', $this->folder . '/index', $data);
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
        $dfrom = $this->uri->segment(3);
        $dto = $this->uri->segment(4);
        $id_user = $this->uri->segment(5);

        if ($id_user == 'null') {
            $id_user = null;
        }        

        $title = "Laporan Kehadiran Pegawai";        
        
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

        $spreadsheet->setActiveSheetIndex(0)
                    ->setCellValue('A2', 'No')
                    ->setCellValue('B2', 'Nama');

        /** tanggal mulai dari abjad C atau chr 67 */
        /** abjad C adalah index ke - 2 */
        $idx = 2;
        $start_date = strtotime($dfrom); 
        $end_date = strtotime($dto);
        while ($start_date <= $end_date) {            
            $text_date = date('Y-m-d', $start_date);
            $cell = $this->columnFromIndex($idx) . '2';
            $spreadsheet->setActiveSheetIndex(0)->setCellValue($cell, $text_date);

            $start_date = strtotime("+1 day", $start_date);
            $idx++;
        }

        $column_total_hadir = $this->columnFromIndex($idx);
        $column_total_izin = $this->columnFromIndex($idx+1);
        $column_last = $this->columnFromIndex($idx+1);

        $spreadsheet->setActiveSheetIndex(0)
                    ->setCellValue("$column_total_hadir"."2", 'Total Hadir')
                    ->setCellValue("$column_total_izin"."2", 'Total Izin');
          
        $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, "A2:$column_last"."2");

        $kolom = 3;
        $nomor = 1;
        
        $all_user_kehadiran = $this->mymodel->get_all_user_kehadiran($id_user);
        
        foreach ($all_user_kehadiran->result() as $user) {            

            $idx = 2;
            $start_date = strtotime($dfrom); 
            $end_date = strtotime($dto);

            $total_hadir = 0;
            $total_izin = 0;

            
            while ($start_date <= $end_date) {    
                $text_date = date('Y-m-d', $start_date); 
                
                $inisial = '';
                if ($this->mymodel->is_hadir($user->id_user, $text_date)) {
                    $inisial = 'H';
                    $total_hadir++;
                }

                if ($this->mymodel->is_izin($user->id_user, $text_date, $is_approve=true)) {
                    $query_jenis_izin = $this->mymodel->get_user_jenis_izin($user->id_user, $text_date);    
                    $e_izin_name = $query_jenis_izin->row()->e_izin_name;
                    $inisial .= $this->get_inisial_keterangan($e_izin_name);
                    $total_izin++;
                }
                
                $cell = $this->columnFromIndex($idx) . "$kolom";
                $spreadsheet->setActiveSheetIndex(0)->setCellValue($cell, $inisial);

                $start_date = strtotime("+1 day", $start_date);
                $idx++;
            }            

            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue("A$kolom", $nomor)
                        ->setCellValue("B$kolom", $user->e_nama)
                        ->setCellValue($column_total_hadir . $kolom, $total_hadir)
                        ->setCellValue($column_total_izin . $kolom, $total_izin);

            $kolom++;
            $nomor++;
        }  
        
        $spreadsheet->getDefaultStyle()
            ->getFont()
            ->setName('Calibri')
            ->setSize(9);

        foreach(range('A',"$column_last") as $columnID) {
            $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }
        
        $spreadsheet->getActiveSheet()->setTitle('Rekap');

        $spreadsheet->setActiveSheetIndex(0)
                    ->setCellValue('A1', "$title");
        $spreadsheet->getActiveSheet()->mergeCells("A1:$column_last" ."1");
        $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, "A1:$column_last"."$kolom");

        /** re-set width column A */
        $spreadsheet->getActiveSheet()->getColumnDimension('A')->setAutoSize(false);
        $spreadsheet->getActiveSheet()->getColumnDimension('A')->setWidth(5);
        $spreadsheet->getActiveSheet()->getRowDimension('1')->setRowHeight(32);
        $spreadsheet->getActiveSheet()->getRowDimension('2')->setRowHeight(40);

        /** wrap text table header */
        $spreadsheet->getActiveSheet()->getStyle("A2:$column_last"."2")->getAlignment()->setWrapText(true); 

        /** buat informasi inisial */
        $info_rows = [
            '*Keterangan Huruf: ',
            'H = Hadir',
            'T = Terlambat',
            'C = Pulang Cepat',
            'S = Sakit',
            'A = Tidak masuk / Alpa',
        ];

        $kolom += 2;
        foreach($info_rows as $row) {
            $spreadsheet->setActiveSheetIndex(0)
                        ->setCellValue('A' . $kolom, $row);

            $kolom++;
        }


        /** SHEET 2, Laporan izin */
        $query_izin_kehadiran = $this->mymodel->get_izin_dan_kehadiran($dfrom, $dto, $id_user=null);
        $spreadsheet->createSheet();
        $spreadsheet->setActiveSheetIndex(1);
        $spreadsheet->getActiveSheet()->setTitle('Detail');

        $spreadsheet->setActiveSheetIndex(1)
                    ->setCellValue('A1', "Detail Rekap Kehadiran $dfrom - $dto");		
        $spreadsheet->getActiveSheet()->getRowDimension('1')->setRowHeight(32);

        $spreadsheet->getActiveSheet()->mergeCells("A1:G1");
        $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle1, 'A1:G2');

        $spreadsheet->setActiveSheetIndex(1)
                    ->setCellValue('A2', 'No')
                    ->setCellValue('B2', 'Nama')
                    ->setCellValue('C2', 'Jenis')
                    ->setCellValue('D2', 'Tanggal Mulai')
                    ->setCellValue('E2', 'Tanggal Akhir')
                    ->setCellValue('F2', 'Keterangan')
                    ->setCellValue('G2', 'Status');

        $kolom = 3;
        $nomor = 1;
        foreach($query_izin_kehadiran->result() as $row) {
  
            $id_user = $row->id_user;
            
            $jenis = "hadir";
            if ($row->e_izin_name != null) {
                $jenis = "izin $row->e_izin_name";
            }
            
            $status = '';
            if ($row->d_approve != null) {
                $status = 'Approve';
            }

            $spreadsheet->setActiveSheetIndex(1)
                        ->setCellValue('A' . $kolom, $nomor)
                        ->setCellValue('B' . $kolom, $row->e_nama)
                        ->setCellValue('C' . $kolom, $jenis)
                        ->setCellValue('D' . $kolom, $row->d_mulai)
                        ->setCellValue('E' . $kolom, $row->d_selesai)
                        ->setCellValue('F' . $kolom, $row->e_remark)
                        ->setCellValue('G' . $kolom, $status);

            $spreadsheet->getActiveSheet()->duplicateStyle($sharedStyle2, 'A'.$kolom.':G'.$kolom);

            $kolom++;
            $nomor++;
        }

        foreach(range('A','G') as $columnID) {
            $spreadsheet->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true);
        }

        $spreadsheet->getActiveSheet()->setAutoFilter("A2:G$kolom");

        /** END SHEET 2 */

        $spreadsheet->setActiveSheetIndex(0);
        
        $writer = new Xls($spreadsheet);
        $nama_file = "Laporan_kehadiran.xls";
        header('Content-Type: application/vnd.ms-excel');
        header('Content-Disposition: attachment;filename='.$nama_file.'');
        header('Cache-Control: max-age=0');
        ob_end_clean();
        ob_start();
        $writer->save('php://output');
	} 

    public function columnFromIndex($number){
        if($number === 0)
            return "A";
        $name='';
        while($number>0){
            $name=chr(65+$number%26).$name;
            $number=intval($number/26)-1;
            if($number === 0){
                $name="A".$name;
                break;
            }
        }
        return $name;
    }

    public function get_all_user_bawahan()
    {
        $filter = [];

		/** SEMUA */
		$filter[] = [
			'id' => 'null',
			'text' => 'SEMUA'
		];

		$cari	= str_replace("'", "", $this->input->get('q'));
		$data = $this->mymodel->get_all_user_bawahan($cari);
		foreach ($data->result() as $row) {
			$filter[] = array(
				'id'   => $row->id_user,
				'text' => strtoupper($row->e_nama),
			);
		}

		echo json_encode($filter);       
    }
    
    const TIDAK_MASUK = 'TIDAK MASUK';
    const TERLAMBAT = 'TERLAMBAT';
    const SAKIT = 'SAKIT';
    const PULANG_CEPAT = 'PULANG CEPAT';
    const HADIR = 'HADIR';

    public function get_inisial_keterangan($jenis)
    {           
        $text = 'ERROR'; 

        $jenis = strtoupper($jenis);
        if ($jenis == static::HADIR) {
            return 'H'; // HADIR
        }

        if ($jenis == static::TERLAMBAT) {
            return 'T';
        }

        if ($jenis == static::SAKIT) {
            return 'S';
        }

        if ($jenis == static::PULANG_CEPAT) {
            return 'C';
        }

        if ($jenis == static::TIDAK_MASUK) {
            return 'A'; // alpa
        }

        return $text;
    }
	
}