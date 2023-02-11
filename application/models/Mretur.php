<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mretur extends CI_Model {

    /** List Datatable */
    public function serverside($dfrom,$dto){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT
                id_document,
                i_document,
                d_retur,
                e_remark,
                d_approve,
                f_status
            FROM
                tm_pembelian_retur
            WHERE 
                d_retur BETWEEn '$dfrom' 
                AND '$dto'
            ORDER BY 
                d_retur, i_document ASC
            ", FALSE);

        $datatables->edit('d_approve', function ($data) {
            $status = $data['f_status'];
            if ($status == 't') {
                if ($data['d_approve'] == '' || $data['d_approve'] == null) {
                    $status = 'Menunggu Approve';
                    $color  = 'warning';
                } else {
                    $status = 'Sudah di Approve';
                    $color  = 'info';
                }
            } else {
                $status = 'Dibatalkan';
                $color  = 'orange';
            }
            $data = "<span class='btn btn-sm badge rounded-round alpha-" . $color . " text-" . $color . "-800 border-" . $color . "-600 legitRipple'>" . $status . "</span>";
            return $data;
        });

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
            $ddocument  = $data['d_retur'];
            $month      = date('m', strtotime($ddocument));
            $bulan      = date('m');
            $batas      = date('Y-m-06');
            $tgl        = date('Y-m-d');
            $cek        = $bulan-$month;
            $approve         = trim($data['d_approve']);
            $status     = $data['f_status'];
            $data       = '';

            $level = $this->mymodel->cek_level($this->id_user)->row();
            $ilevel = $level->level;

            if (check_role($this->id_menu, 5) && $ilevel == '4' && $approve == '' && $status == 't') {
                $data      .= "<a href='".base_url().$this->folder.'/approvement/'.encrypt_url($id)."' title='Approve'><i class='icon-database-check text-light-800'></i></a> &nbsp;";
            }

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }

            if (check_role($this->id_menu, 3) && $status=='t' && $approve =='') {
                if($month == $bulan && $ddocument <= $batas && $tgl <= $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";
                }
                else if($cek == 1 && $tgl <= $batas){
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-1 text-".$this->color."-800'></i></a>";    
                }
                else if($ddocument > $batas){
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
        $query  = $this->db->query("SELECT
                max(substring(i_document, 10, 3)) AS max,
                substring('$thbl',3,4) AS thbl
            FROM
                tm_pembelian_retur
            WHERE 
                f_status = 't'
                AND substring(i_document, 5, 4) = substring('$thbl',3,4)
                AND to_char (d_entry, 'yyyy') >= '$tahun'
        ", false);
    
        if ($query->num_rows() > '0'){          
            foreach($query->result() as $row){
                $no = $row->max;
                $ym = $row->thbl;
            }
            if($no == ''){
                $no = 0;
            }
            
            $number = $no + 1;
            // var_dump($number);
            // die();
            settype($number,"string");
            $n = strlen($number);        
            while($n < 3){            
                $number = "0".$number;
                $n = strlen($number);
            }
            $number = "RTR-".$ym."-".$number;
            // var_dump($number);
            // die();
            return $number;    
        }else{      
            $number = "001";
            $nomer  = "RTR-".$thbl."-".$number;
            return $nomer;
        }
    }

    /** Ambil Data Customer */
    public function get_customer($cari)
    {
        if ($this->fallcustomer=='t') {
            $where = "";
        }else{
            $where = "AND id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        return $this->db->query("SELECT
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

    /** Ambil Data Company */
    public function get_company_data($cari)
    {
        if ($this->i_company=='all') {
            $where = "AND i_company IN (
                    SELECT 
                        i_company
                    FROM
                        tm_user_company
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }else{
            $where = "AND i_company = '$this->i_company' ";
        }
        return $this->db->query("SELECT
                i_company,
                e_company_name
            FROM
                tr_company
            WHERE
                (e_company_name ILIKE '%$cari%')
                AND f_status = 't'
                $where
            ORDER BY
                e_company_name ASC
        ", FALSE);
    }

    /** Ambil Data Alasan */
    public function get_alasan($cari)
    {
        return $this->db->query("SELECT
                i_alasan,
                initcap(e_alasan) AS e_alasan
            FROM
                tr_alasan_retur
            WHERE
                (e_alasan ILIKE '%$cari%')
                AND f_status = 't'
            ORDER BY
                e_alasan ASC
        ", FALSE);
    }

    /** Ambil Data Detail company */
    public function get_detail_company($id_customer)
    {
        return $this->db->query("SELECT
                initcap(e_customer_address) AS e_customer_address,
                initcap(e_customer_name) AS e_customer_name
            FROM
                tr_customer
            WHERE
                id_customer = '$id_customer'
        ", FALSE);
    }

    /** Ambil Data Product */
    public function get_product(/* $i_company,  */$cari)
    {
        return $this->db->query("SELECT 
        a.i_product,
        a.e_product_name,
        c.e_brand_name,
        a.id_brand
    FROM 
        tr_product a
    INNER JOIN tr_brand c ON
        (c.id_brand = a.id_brand)
    WHERE 
        (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%' OR e_brand_name ILIKE '%$cari%')
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
        return $this->db->query("SELECT 
                i_document
            FROM 
                tm_pembelian_retur
            WHERE 
                trim(upper(i_document)) = trim(upper('$idocument'))
                AND f_status = 't'
        ", FALSE);
    }

    /** Simpan Data */
    public function save($datafoto)
    {
        $query = $this->db->query("SELECT max(id_document)+1 AS id FROM tm_pembelian_retur", TRUE);
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

        $table = array(
            'id_document'               => $id,
            'i_document'                => $this->input->post('idocument', TRUE),
            'd_retur'                   => $ddocument,
            'id_customer'               => $this->input->post('idcustomer', TRUE),
            'e_remark'                  => $this->input->post('eremark', TRUE),
            'id_user'                   => $this->id_user,
        );
        $this->db->insert('tm_pembelian_retur', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $i = 0;
            foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                $iproduct = $this->input->post('i_product', TRUE)[$i];
                $product = explode(' - ',$iproduct);
                $i_product = $product[0];
                if ($datafoto == null) {
                    $datafoto = "NULL";
                } else {
                    $datafoto = $datafoto[$i];
                }
                $tabledetail = array(
                    'id_document'       => $id,
                    'i_company'         => $this->input->post('i_company', TRUE)[$i],
                    'i_product'         => $i_product,
                    'e_product_name'    => $this->input->post('e_product', TRUE)[$i],
                    'n_qty'             => str_replace(',','', $this->input->post('qty', TRUE)[$i]),
                    'i_alasan'          => $this->input->post('i_alasan', TRUE)[$i],
                    'i_document'        => $this->input->post('idocument', TRUE),
                    'foto'              => $datafoto
                );
                $this->db->insert('tm_pembelian_retur_item', $tabledetail);
                $i++;
            };
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT
                a.*, b.e_customer_name
            FROM
                tm_pembelian_retur a
            INNER JOIN 
                tr_customer b ON 
                (b.id_customer = a.id_customer)
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
                b.e_company_name,
                c.e_alasan,
                d.id_brand,
                e.e_brand_name
            FROM
                tm_pembelian_retur_item a
            INNER JOIN tr_product d ON
                (d.i_product = a.i_product AND d.i_company = a.i_company)
            INNER JOIN tr_brand e ON
                (e.id_brand = d.id_brand)
            INNER JOIN tr_company b ON 
                (b.i_company = a.i_company)
            INNER JOIN tr_alasan_retur c ON 
                (c.i_alasan = a.i_alasan)
            WHERE
                id_document = '$id'
            ORDER BY 
                id_item
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
    public function update($datafoto)
    {
        $id = $this->input->post('id', TRUE);

        $ddocument = ($this->input->post('ddocument', TRUE)!='') ? date('Y-m-d', strtotime($this->input->post('ddocument', TRUE))) : date('Y-m-d') ;

        $table = array(
            'i_document'                => $this->input->post('idocument', TRUE),
            'd_retur'                   => $ddocument,
            'id_customer'               => $this->input->post('idcustomer', TRUE),
            'e_remark'                  => $this->input->post('eremark', TRUE),
            'd_update'                  => current_datetime(),
            'id_user'                   => $this->id_user,
        );
        $this->db->where('id_document', $id);
        $this->db->update('tm_pembelian_retur', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            $this->db->where('id_document', $id);
            $this->db->delete('tm_pembelian_retur_item');
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
                    'i_alasan'          => $this->input->post('i_alasan', TRUE)[$i],
                    'foto'              => $datafoto[$i]
                );
                $this->db->insert('tm_pembelian_retur_item', $tabledetail);
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
        $this->db->update('tm_pembelian_retur', $data);
    }

    /** Cek Level */
    public function cek_level($id)
    {
        return $this->db->query("SELECT 
                i_level as level
            FROM 
                tm_user
            WHERE 
                id_user = $id 
                AND f_status = 't'
        ", FALSE);
    }

    /** Approve */
    public function approve($id)
    {

            $data = array(
                'd_approve' => date('Y-m-d'), 
            );
            $this->db->where('id_document', $id);
            $this->db->update('tm_pembelian_retur', $data);

    }
}

/* End of file Mmaster.php */
