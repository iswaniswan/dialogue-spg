<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpurchase extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom,$dto){

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
        /*

        if ($this->i_company=='1') {
            $and = "
                AND b.i_company IN (
                SELECT 
                    i_company
                FROM 
                    tm_user_company
                WHERE 
                    id_user = '$this->id_user'
            )
            ";
        }else{
            $and = "
                AND b.i_company = '$this->i_company'
            ";
        }*/
        $datatables->query("SELECT
                DISTINCT id_document,
                e_company_name,
                i_document,
                d_receive,
                c.e_customer_name,
                a.e_remark, 
                a.f_status
            FROM
                tm_pembelian a
            INNER JOIN tr_customer_item b ON
                (
                    b.id_item = a.id_item
                )
            INNER JOIN tr_customer c ON
                (
                    c.id_customer = b.id_customer
                ) 
            INNER JOIN tr_company d ON
                (
                    d.i_company = b.i_company
                ) 
            WHERE 
                d_receive BETWEEn '$dfrom' 
                AND '$dto' 
                $where
            ORDER BY d_receive, i_document ASC
            ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_document'];
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
            $id         = trim($data['id_document']);
            $ddocument  = $data['d_receive'];
            $month      = date('m', strtotime($ddocument));
            $bulan      = date('m');
            $batas      = date('Y-m-06');
            $tgl        = date('Y-m-d');
            $cek        = $bulan-$month;
            $status     = $data['f_status'];
            $data       = '';

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }

            if (check_role($this->id_menu, 3) && $status=='t') {
                if($month == $bulan && $ddocument <= $batas && $tgl <= $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";
                }
                else if($ddocument > $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";    
                }
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
                max(substring(i_document, 9, 6)) AS max
            FROM
                tm_pembelian
            WHERE 
                f_status = 't'
                AND substring(i_document, 4, 2) = substring('$thbl',1,2)
                AND to_char (d_receive, 'yyyy') >= '$tahun'
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
            $number = "SJ-".$thbl."-".$number;
            return $number;    
        }else{      
            $number = "000001";
            $nomer  = "SJ-".$thbl."-".$number;
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
                    a.id_customer AS id,
                    a.e_customer_name AS e_name
                FROM 
                    tr_customer a 
                WHERE 
                    (a.e_customer_name ILIKE '%$cari%')
                    AND f_status = 't'
                    $where
                ORDER BY 2
        ", FALSE);
    }

    public function get_customer_item($cari)
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
                    a.id_customer AS id,
                    a.e_customer_name AS e_name
                FROM 
                    tr_customer_item a
                WHERE
                    (a.e_customer_name ILIKE '%$cari%')
                    AND f_status = 't'
                    $where
                ORDER BY 2
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
        b.e_company_name
    FROM
        tr_product a
    INNER JOIN
        tr_company b ON (b.i_company = a.i_company)
    INNER JOIN
        tr_brand c ON (c.id_brand = a.id_brand)
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
        $query = $this->db->query("SELECT max(id_document)+1 AS id FROM tm_pembelian", TRUE);
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

        $idcust = $this->input->post('idcustomer', TRUE);
        $idcomp = $this->input->post('customeritem', TRUE);
        $queryitem = $this->db->query("SELECT id_item FROM tr_customer_item WHERE id_customer = $idcust AND i_company = $idcomp", TRUE);
		if ($queryitem->num_rows() > 0) {
			$iditem = $queryitem->row()->id_item;
			if ($iditem == null) {
				$iditem = 1;
			} else {
				$iditem = $iditem;
			}
		} else {
			$iditem = 1;
		}

        $dreceive = ($this->input->post('dreceive', TRUE)!='') ? date('Y-m-d', strtotime($this->input->post('dreceive', TRUE))) : date('Y-m-d') ;

        $table = array(
            'id_document' => $id,
            'id_item'     => $iditem,  
            'i_document'  => $this->input->post('idocument', TRUE),
            'd_receive'   => $dreceive,
            'e_remark'    => $this->input->post('eremark', TRUE),
        );
        $this->db->insert('tm_pembelian', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $iproduk = $product[0];
                $tabledetail = array(
                    'id_document'       => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $iproduk,
                    'e_product_name'    => $this->input->post('e_product', TRUE)[$i],
                    'n_qty'             => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                    'v_price'           => null,
                    'e_remark'          => $this->input->post('enote', TRUE)[$i],
                );
                $this->db->insert('tm_pembelian_item', $tabledetail);
                $i++;
            };
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.id_item as item ,
                b.e_customer_name ,
                c.id_customer as idcust ,
                c.e_customer_name as customer,
                b.i_company,
                (SELECT DISTINCT e_company_name from tr_company WHERE i_company = b.i_company) as company
            FROM
                tm_pembelian a
            INNER JOIN 
                tr_customer_item b ON 
                (b.id_item = a.id_item)
            INNER JOIN
                tr_customer c ON
                (b.id_customer = c.id_customer)
            WHERE 
                id_document = '$id'
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
                tm_pembelian_item a
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

    /** Get Data Company Edit */
    public function get_companyy($cari,$id)
    {
        return $this->db->query("
            SELECT
                a.i_company as id,
                a.e_company_name as e_name,
                b.selek
            FROM
                tr_company a
            INNER JOIN tr_customer_item c ON
                (c.id_customer = '$id' AND c.i_company = a.i_company)
            LEFT JOIN (
                SELECT
                    i_company,
                    'selected' AS selek
                FROM
                    tm_user_company
                WHERE
                    id_user = '$this->id_user'
            ) b ON
            (
                b.i_company = a.i_company
            )
            WHERE
                (
                    a.e_company_name ILIKE '%$cari%'
                    AND a.f_status = 't'
                )
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('id', TRUE);

        $idcust = $this->input->post('idcustomer', TRUE);
        $idcomp = $this->input->post('customeritem', TRUE);

        $queryitem = $this->db->query("SELECT id_item FROM tr_customer_item WHERE id_customer = $idcust AND i_company = $idcomp", TRUE);
		if ($queryitem->num_rows() > 0) {
			$iditem = $queryitem->row()->id_item;
			if ($iditem == null) {
				$iditem = 1;
			} else {
				$iditem = $iditem;
			}
		} else {
			$iditem = 1;
		}

        $dreceive = ($this->input->post('dreceive', TRUE)!='') ? date('Y-m-d', strtotime($this->input->post('dreceive', TRUE))) : date('Y-m-d') ;

        $table = array(
            'i_document'  => $this->input->post('idocument', TRUE),
            'd_receive'   => $dreceive,
            'id_item'     => $iditem,
            'e_remark'    => $this->input->post('eremark', TRUE),
            'd_update'    => current_datetime(),
        );
        $this->db->where('id_document', $id);
        $this->db->update('tm_pembelian', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $this->db->where('id_document', $id);
            $this->db->delete('tm_pembelian_item');
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $iproduk = $product[0];
                $tabledetail = array(
                    'id_document'       => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $iproduk,
                    'e_product_name'    => $this->input->post('e_product', TRUE)[$i],
                    'n_qty'             => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                    'v_price'           => null,
                    'e_remark'          => $this->input->post('enote', TRUE)[$i],
                );
                $this->db->insert('tm_pembelian_item', $tabledetail);
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
        $this->db->update('tm_pembelian', $data);
    }

    public function delete($id)
    {
        $this->db->where('id_document', $id);
        $this->db->delete('tm_pembelian_item');
        $this->db->where('id_document', $id);
        $this->db->delete('tm_pembelian');
    }
}

/* End of file Mmaster.php */
