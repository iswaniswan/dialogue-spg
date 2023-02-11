<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mlaporanpenjualan extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom,$dto,$id_customer){
        $datatables = new Datatables(new CodeigniterAdapter);
        if ($this->fallcustomer == 'f') {
            $where = "
                AND b.id_customer IN (
                    SELECT 
                        id_customer
                    FROM 
                        tm_user_customer
                    WHERE 
                        id_user = '$this->id_user'
                )
            ";
        }else{
            $where = "";
        }

        if ($id_customer === "all") {

                $id_customer = 'NULL';
                $where = '';
                
        } elseif($id_customer != '') {
                $id_customer = $id_customer;    
                $where = "AND b.id_customer = '$id_customer'";

        }
        
        $datatables->query("SELECT 
        a.id_item ,
        e.e_customer_name ,
        b.d_document ,
        a.i_product ,
        a.e_product_name ,
        d.e_brand_name ,
        a.n_qty ,
        a.v_price ,
        a.v_diskon ,
        ROUND(((a.v_price * a.v_diskon) / 100),0) AS rp_diskon
        FROM tm_penjualan_item a
        INNER JOIN tm_penjualan b
        ON (b.id_document = a.id_document)
        INNER JOIN tr_product c 
        ON (c.i_company = a.i_company AND c.i_product = a.i_product)
        INNER JOIN tr_brand d 
        ON (d.id_brand = c.id_brand)
        INNER JOIN tr_customer e
        ON (e.id_customer = b.id_customer)
        WHERE 
        b.d_document BETWEEN '$dfrom' AND '$dto'
        $where
        ORDER BY b.d_entry desc
            ", FALSE);

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
    public function get_customer($cari)
    {
        if ($this->fallcustomer=='t') {
            $where = "";
        }else{
            $where = "
                AND id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        return $this->db->query("
            SELECT
                id_customer,
                e_customer_name
            FROM
                tr_customer
            WHERE
                (e_customer_name ILIKE '%$cari%')
                AND f_status = 't'
                $where
            ORDER BY
                e_customer_name ASC
        ", FALSE);
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


    /** Ambil Data Detail Product */
    public function get_detail_product($i_product,$i_brand)
    {
        return $this->db->query("SELECT
        initcap(a.e_product_name) AS e_product_name,
        a.id_brand,
        c.e_brand_name, 
        a.i_company,
        b.e_company_name,
        d.v_price
    FROM
        tr_product a
    INNER JOIN
        tr_company b ON (b.i_company = a.i_company)
    INNER JOIN
        tr_brand c ON (c.id_brand = a.id_brand)
    INNER JOIN
        tr_customer_price d ON (d.i_product = a.i_product)
    WHERE
        b.i_company = a.i_company
        AND a.i_product = '$i_product'
        AND a.id_brand = '$i_brand'
        ", FALSE);
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
        return $this->db->query("
        SELECT 
        DISTINCT a.*, d.e_customer_name FROM tm_penjualan a 
        LEFT JOIN tm_penjualan_item b ON (b.id_document = a.id_document) 
        LEFT JOIN tr_customer d ON (d.id_customer = a.id_customer) 
        WHERE a.id_document = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.id_brand,
                c.e_brand_name
            FROM
                tm_penjualan_item a
            INNER JOIN
                tr_product b ON
                (a.i_product = b.i_product AND b.i_company = a.i_company)
            INNER JOIN
                tr_brand c ON
                (c.id_brand = b.id_brand)
            WHERE
                a.id_document = '$id'
            ORDER BY 
                a.id_item
        ", FALSE);
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
        $this->db->where('id_document', $id);
        $this->db->update('tm_penjualan', $data);
    }

    /** Export Data */
    public function export_data($dfrom, $dto, $id)
    {

        if ($id === "all") {

                $id_customer = 'NULL';
                $where = '';
                
        } elseif($id != '') {
                $id_customer = $id;    
                $where = "AND b.id_customer = '$id_customer'";

        }


    $d_from         = date('Y-m-d',strtotime($dfrom));
    $d_to           = date('Y-m-d',strtotime($dto));

    $query = $this->db->query("SELECT 
    a.id_item ,
    b.d_document ,
    e.e_customer_name ,
    a.i_product ,
    a.e_product_name ,
    d.e_brand_name ,
    a.n_qty ,
    a.v_price ,
    a.v_diskon 
    FROM tm_penjualan_item a
    INNER JOIN tm_penjualan b
    ON (b.id_document = a.id_document)
    INNER JOIN tr_product c 
    ON (c.i_company = a.i_company AND c.i_product = a.i_product)
    INNER JOIN tr_brand d 
    ON (d.id_brand = c.id_brand)
    INNER JOIN tr_customer e
    ON (e.id_customer = b.id_customer)
    WHERE 
    b.d_document BETWEEN '$d_from' AND '$d_to'
    $where
    ORDER BY b.d_entry desc");

    return $query;
    }

}