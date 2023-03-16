<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpenjualan extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom,$dto){
        $datatables = new Datatables(new CodeigniterAdapter);            

        $sql = "SELECT
                    a.id,
                    i_document,
                    d_document,
                    e_customer_sell_name,
                    e_remark,
                    f_status
                FROM tm_penjualan a
                INNER JOIN tm_user_customer tuc ON tuc.id_user = '$this->id_user' AND tuc.id_customer = a.id_customer
                WHERE d_document BETWEEn '$dfrom' AND '$dto'                 
                ORDER BY d_document, i_document ASC";

        // var_dump($sql);

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $id = $data['id'];
            if ($data['f_status']=='t') {
                $status = 'Aktif';
                $color  = 'success';
            }else{
                $status = 'Batal';
                $color  = 'danger';
            }
            $data = "<button class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple'>".$status."</button>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $id         = trim($data['id']);
            $ddocument  = $data['d_document'];
            $month      = date('m', strtotime($ddocument));
            $bulan      = date('m');
            $batas      = date('Y-m-05');
            $tgl        = date('Y-m-d');
            $cek        = $bulan-$month;
            $status     = $data['f_status'];
            $data       = '';

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }

            if (check_role($this->id_menu, 3) && $status=='t' ) {
                //Cek Tanggal 1 - 5 di bulan yang sama
                if($month == $bulan && $ddocument <= $batas && $tgl <= $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";
                }
                //Cek tanggal dokumen > tanggal 5 bulan sekarang
                else if($ddocument > $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";    
                }
                //Cek jarak bulan sebelumnya tidak lebih dari 1 bulan dan tanggal sekarang < tanggal 5
                else if($cek == 1 && $tgl <= $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";    
                }
            }        
            
            if (check_role($this->id_menu, 4) && $status=='t') {
                if($month == $bulan && $ddocument <= $batas && $tgl <= $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
                else if($ddocument > $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
                else if($cek == 1 && $tgl <= $batas){
                $data      .= "<a href='#' onclick='sweetcancel(\"".$this->folder."\",\"".$id."\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 ml-1'></i></a>";
                }
            }
            return $data;
        });
        return $datatables->generate();
    }

    /** Running Number Dokumen */

    public function runningnumber($thbl,$tahun)
    {
        $query  = $this->db->query("
            SELECT
                max(substring(i_document, 10, 6)) AS max
            FROM
                tm_penjualan
            WHERE 
                f_status = 't'
                AND substring(i_document, 5, 2) = substring('$thbl',1,2)
                AND to_char (d_document, 'yyyy') >= '$tahun'
        ", false);
        if ($query->num_rows() > 0){          
            foreach($query->result() as $row){
                $no = $row->max;
            }
            $number = $no + 1;
            settype($number,"string");
            $n = strlen($number);        
            while($n < 6){            
                $number = "0".$number;
                $n = strlen($number);
            }
            $number = "BON-".$thbl."-".$number;
            return $number;    
        }else{      
            $number = "000001";
            $nomer  = "BON-".$thbl."-".$number;
            return $nomer;
        }
    }

    /** Ambil Data Customer */
    public function get_customer($cari='')
    {
        $limit = " LIMIT 5";
        if ($cari != '') {
            $limit = '';
        }

        $user_cover = "SELECT id_customer FROM tm_user_customer
                        WHERE id_user = '$this->id_user'";

        $sql = "SELECT
                    id_customer,
                    e_customer_name 
                FROM tr_customer
                WHERE (e_customer_name ILIKE '%$cari%')
                    AND f_status = 't'
                    AND id_customer IN ($user_cover)
                ORDER BY e_customer_name ASC
                $limit ";

        return $this->db->query($sql, FALSE);
    }

    /** Ambil Data Detail Customer */
    public function get_detail_customer($id_customer)
    {
        return $this->db->query("
            SELECT
                initcap(e_customer_address) AS e_customer_address,
                initcap(e_customer_name) AS e_customer_name
            FROM
                tr_customer
            WHERE
                id_customer = '$id_customer'
        ", FALSE);
    }

    /** Ambil Data Product */
    /*
    public function get_product($cari)
    {
        return $this->db->query("
        SELECT 
            a.i_product AS id,
            a.e_product_name AS e_name,
            c.e_brand_name,
            a.id_brand
        FROM 
            tr_product a
        INNER JOIN tr_brand c ON
            (c.id_brand = a.id_brand)
        WHERE 
            (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
            AND a.f_status = 't'
            AND a.id_brand IN (SELECT id_brand FROM tm_user_brand WHERE id_user = $this->id_user)
        ORDER BY 3,1
        ", FALSE);
    }
    */

    /** Get Data Product sesuai user cover */
    public function get_product($cari='', $id_customer, $all=false)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = 'LIMIT 5';
        if (($cari != '') or ($all)) {
            $limit = "";
        }

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        $sql = "SELECT a.id,
                i_product,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
                AND a.f_status = 't'
                AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4,1
            $limit";

        // var_dump($sql); die();

        return $this->db->query($sql, FALSE);
    }


    /** Ambil Data Detail Product */
    /*
    public function get_detail_product($i_product,$i_brand)
    {
        return $this->db->query("SELECT
        initcap(a.e_product_name) AS e_product_name,
        a.id_brand,
        c.e_brand_name, 
        a.i_company,
        b.e_company_name,
        coalesce(d.v_price,0) as v_price
    FROM
        tr_product a
    INNER JOIN
        tr_company b ON (b.i_company = a.i_company)
    INNER JOIN
        tr_brand c ON (c.id_brand = a.id_brand)
    LEFT JOIN
        tr_customer_price d ON (d.i_product = a.i_product)
    WHERE
        b.i_company = a.i_company
        AND a.i_product = '$i_product'
        AND a.id_brand = '$i_brand'
        ", FALSE);
    }
    */
    
    public function get_detail_product($id_product, $id_customer)
    {
        $sql = "SELECT
                    initcap(a.e_product_name) AS e_product_name,
                    a.id_brand,
                    c.e_brand_name, 
                    a.i_company,
                    b.e_company_name,
                    coalesce(d.v_price,0) as v_price
                FROM tr_product a
                INNER JOIN tr_company b ON (b.i_company = a.i_company)
                INNER JOIN tr_brand c ON (c.id_brand = a.id_brand)
                LEFT JOIN tr_customer_price d ON (d.i_product = a.i_product)
                WHERE b.i_company = a.i_company";

        return $this->db->query($sql, FALSE);
    }

    public function get_product_price($id_product, $id_customer)
    {
        $sql = "SELECT * FROM tr_customer_price 
                WHERE id_product = '$id_product' AND id_customer = '$id_customer'";

        return $this->db->query($sql);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($idocument)
    {
        return $this->db->query("
            SELECT 
                i_document
            FROM 
                tm_penjualan
            WHERE 
                trim(upper(i_document)) = trim(upper('$idocument'))
                AND f_status = 't'
        ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {

        $query = $this->db->query("SELECT max(id_document)+1 AS id FROM tm_penjualan", TRUE);
		if ($query->num_rows() > 0) {
			$id = $query->row()->id;
			if ($id == null) {
				$id = 1;
			} else {
				$id = $id;
			}
		} else {
			$id = 1;
		}

        $ddocument = ($this->input->post('ddocument', TRUE)!='') ? date('Y-m-d', strtotime($this->input->post('ddocument', TRUE))) : date('Y-m-d') ;
        $iduser = $this->id_user[0];

        $custname = $this->input->post('nama', TRUE);
        $custaddr = $this->input->post('alamat', TRUE);
        $eremark = $this->input->post('eremark', TRUE);

        if($custname ==''){
            $custname = "-";
        }
        if($custaddr ==''){
            $custaddr = "-";
        }
        if($eremark ==''){
            $eremark = "-";
        }

        $table = array(
            'id_document'               => $id,
            'id_customer'               => $this->input->post('idcustomer', TRUE),
            'i_document'                => $this->input->post('idocument', TRUE),
            'd_document'                => $ddocument,
            'e_customer_sell_name'      => ucwords(strtolower($custname)),
            'e_customer_sell_address'   => $custaddr,
            'v_gross'                   => str_replace(',','', $this->input->post('bruto', TRUE)),
            'n_diskon'                  => str_replace(',','', $this->input->post('diskonpersen', TRUE)),
            'v_diskon'                  => str_replace(',','', $this->input->post('diskon', TRUE)),
            'v_dpp'                     => str_replace(',','', $this->input->post('dpp', TRUE)),
            'v_ppn'                     => str_replace(',','', $this->input->post('ppn', TRUE)),
            'v_netto'                   => str_replace(',','', $this->input->post('netto', TRUE)),
            'v_bayar'                   => str_replace(',','', $this->input->post('netto', TRUE)),
            'e_remark'                  => $eremark,
            'id_user'                   => $iduser,
        );
        $this->db->insert('tm_penjualan', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $i_product = $product[0];
                $tabledetail = array(
                    'id_document'       => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $i_product,
                    'e_product_name'    => $this->input->post('e_product', TRUE)[$i],
                    'n_qty'             => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                    'v_price'           => str_replace(',','', $this->input->post('harga', TRUE)[$i]),
                    'v_diskon'          => str_replace(',','', $this->input->post('vdiskon', TRUE)[$i]),
                    'e_remark'          => $this->input->post('enote', TRUE)[$i],
                );
                $this->db->insert('tm_penjualan_item', $tabledetail);
                $i++;
            };
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        $sql = "SELECT DISTINCT a.*, d.e_customer_name 
                FROM tm_penjualan a 
                LEFT JOIN tm_penjualan_item b ON (b.id_penjualan = a.id) 
                LEFT JOIN tr_customer d ON (d.id_customer = a.id_customer) 
                WHERE a.id = '$id'";
        
        // var_dump($sql);

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        $sql = "SELECT a.*,
                    b.id_brand,
                    c.e_brand_name,
                    b.i_product,
                    b.e_product_name
                FROM tm_penjualan_item a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_brand c ON (c.id_brand = b.id_brand)
                WHERE a.id_penjualan = '$id'
                ORDER BY a.id";
        // var_dump($sql);

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Company Edit */
    public function get_company($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.selek
            FROM
                tr_company a
            LEFT JOIN (
                SELECT
                    i_company,
                    'selected' AS selek
                FROM
                    tm_user_company
                WHERE
                    id_user = '$id'
            ) b ON
            (
                b.i_company = a.i_company
            )
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('id', TRUE);

        $ddocument = ($this->input->post('ddocument', TRUE)!='') ? date('Y-m-d', strtotime($this->input->post('ddocument', TRUE))) : date('Y-m-d') ;

        $custname = $this->input->post('nama', TRUE);
        $custaddr = $this->input->post('alamat', TRUE);
        $eremark = $this->input->post('eremark', TRUE);

        if($custname ==''){
            $custname = "-";
        }
        if($custaddr ==''){
            $custaddr = "-";
        }
        if($eremark ==''){
            $eremark = "-";
        }

        $table = array(
            'i_document'                => $this->input->post('idocument', TRUE),
            'd_document'                => $ddocument,
            'id_customer'               => $this->input->post('idcustomer', TRUE),
            'e_customer_sell_name'      => ucwords(strtolower($custname)),
            'e_customer_sell_address'   => $custaddr,
            'v_gross'                   => str_replace(',','', $this->input->post('bruto', TRUE)),
            'n_diskon'                  => str_replace(',','', $this->input->post('diskonpersen', TRUE)),
            'v_diskon'                  => str_replace(',','', $this->input->post('diskon', TRUE)),
            'v_dpp'                     => str_replace(',','', $this->input->post('dpp', TRUE)),
            'v_ppn'                     => str_replace(',','', $this->input->post('ppn', TRUE)),
            'v_netto'                   => str_replace(',','', $this->input->post('netto', TRUE)),
            'v_bayar'                   => str_replace(',','', $this->input->post('netto', TRUE)),
            'e_remark'                  => $eremark,
            'd_update'                  => current_datetime(),
        );
        $this->db->where('id_document', $id);
        $this->db->update('tm_penjualan', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $this->db->where('id_document', $id);
            $this->db->delete('tm_penjualan_item');
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $i_product = $product[0];
                $tabledetail = array(
                    'id_document'       => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $i_product,
                    'e_product_name'    => $this->input->post('e_product', TRUE)[$i],
                    'n_qty'             => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                    'v_price'           => str_replace(',','', $this->input->post('harga', TRUE)[$i]),
                    'v_diskon'          => str_replace(',','', $this->input->post('vdiskon', TRUE)[$i]),
                    'e_remark'          => $this->input->post('enote', TRUE)[$i],
                );
                $this->db->insert('tm_penjualan_item', $tabledetail);
                $i++;
            };
        };
    }

    public function cancel($id)
    {
        $data = array(
            'f_status' => false, 
        );
        $this->db->where('id', $id);
        $this->db->update('tm_penjualan', $data);
    }

    public function insert_penjualan(
        $id_customer, $i_document, $d_document, $e_customer_sell_name, $e_customer_sell_address, 
        $v_gross, $n_diskon, $v_diskon, $v_dpp, $v_ppn, $v_netto, $v_bayar, $e_remark, $id_user
    )
    {
        $data = [
            'id_customer' => $id_customer, 
            'i_document' => $i_document, 
            'd_document' => $d_document, 
            'e_customer_sell_name' => $e_customer_sell_name, 
            'e_customer_sell_address' => $e_customer_sell_address, 
            'v_gross' => $v_gross, 
            'n_diskon' => $n_diskon, 
            'v_diskon' => $v_diskon, 
            'v_dpp' => $v_dpp, 
            'v_ppn' => $v_ppn,
            'v_netto' => $v_netto,
            'v_bayar' => $v_bayar,
            'e_remark' => $e_remark,
            'id_user' => $id_user
        ];

        $this->db->insert('tm_penjualan', $data);
    }

    public function update_penjualan(
        $id_customer, $i_document, $d_document, $e_customer_sell_name, $e_customer_sell_address, 
        $v_gross, $n_diskon, $v_diskon, $v_dpp, $v_ppn, $v_netto, $v_bayar, $e_remark, $id_user, $id
    )
    {
        $data = [
            'id_customer' => $id_customer, 
            'i_document' => $i_document, 
            'd_document' => $d_document, 
            'e_customer_sell_name' => $e_customer_sell_name, 
            'e_customer_sell_address' => $e_customer_sell_address, 
            'v_gross' => $v_gross, 
            'n_diskon' => $n_diskon, 
            'v_diskon' => $v_diskon, 
            'v_dpp' => $v_dpp, 
            'v_ppn' => $v_ppn,
            'v_netto' => $v_netto,
            'v_bayar' => $v_bayar,
            'e_remark' => $e_remark,
            'id_user' => $id_user,
            'd_update' => date('Y-m-d H:i:s')
        ];

        $this->db->where('id', $id);
        $this->db->update('tm_penjualan', $data);
    }

    public function insert_penjualan_item($id_penjualan, $i_company=null, $id_product, $n_qty, $v_price, $v_diskon, $e_remark)
    {
        $data = [
            'id_penjualan' => $id_penjualan,
            'i_company' => $i_company,
            'id_product' => $id_product,
            'n_qty' => $n_qty,
            'v_price' => $v_price,
            'v_diskon' => $v_diskon,
            'e_remark' => $e_remark
        ];

        $this->db->insert('tm_penjualan_item', $data);        
    }

    public function delete_penjualan_item_by_id_penjualan($id_penjualan)
    {
        $this->db->where('id_penjualan', $id_penjualan);
        $this->db->delete('tm_penjualan_item');
    }
}

/* End of file Mmaster.php */
