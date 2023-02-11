<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Madjustment extends CI_Model
{

    /** List Datatable */
    public function serverside($dfrom, $dto)
    {
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT
                id_adjustment,
                i_adjustment,
                i_periode,
                to_char(d_adjustment, 'DD FMMonth YYYY') AS d_adjust,
                d_adjustment,
                b.e_customer_name,
                e_remark,
                a.d_approve,
                a.f_status
            FROM
                tm_adjustment a, tr_customer b
            WHERE 
                a.id_customer = b.id_customer
                AND d_adjustment BETWEEN '$dfrom' 
                AND '$dto'
            ORDER BY 
                d_adjustment, i_adjustment ASC
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
            $id         = $data['id_adjustment'];
            if ($data['f_status'] == 't') {
                $status = 'Aktif';
                $color  = 'success';
            } else {
                $status = 'Batal';
                $color  = 'danger';
            }
            $data = "<button class='btn btn-sm badge rounded-round alpha-" . $color . " text-" . $color . "-800 border-" . $color . "-600 legitRipple'>" . $status . "</button>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $id         = trim($data['id_adjustment']);
            $ddocument  = $data['d_adjustment'];
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

            if ($ilevel == '4' AND $approve == '') {
                $data      .= "<a href='".base_url().$this->folder.'/approvement/'.encrypt_url($id)."' title='Approve'><i class='icon-database-check text-light-800'></i></a> &nbsp;";
            }

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }

            if (check_role($this->id_menu, 3) && $status == 't' && $approve== '') {
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

            if (check_role($this->id_menu, 4) && $status == 't' && $approve== '') {
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
        $datatables->hide('d_adjustment');
        return $datatables->generate();
    }

    /** Running Number Dokumen */

    public function runningnumber($thbl, $tahun)
    {
        $query  = $this->db->query("SELECT
                max(substring(i_adjustment, 9, 3)) AS max
            FROM
                tm_adjustment
            WHERE 
                f_status = 't'
                AND substring(i_adjustment, 4, 2) = substring('$thbl',1,2)
                AND to_char (d_adjustment, 'yyyy') >= '$tahun'
        ", false);
        if ($query->num_rows() > 0) {
            foreach ($query->result() as $row) {
                $no = $row->max;
            }
            $number = $no + 1;
            settype($number, "string");
            $n = strlen($number);
            while ($n < 3) {
                $number = "0" . $number;
                $n = strlen($number);
            }
            $number = "AD-" . $thbl . "-" . $number;
            return $number;
        } else {
            $number = "001";
            $nomer  = "AD-" . $thbl . "-" . $number;
            return $nomer;
        }
    }

    /** Ambil Data Customer */
    public function get_customer($cari)
    {
        if ($this->fallcustomer == 't') {
            $where = "";
        } else {
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

    /** Ambil Data Product */
    public function get_product(/* $i_company,  */$cari)
    {
        return $this->db->query("SELECT 
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
    public function get_detail_product($i_product, $i_brand)
    {
        return $this->db->query("SELECT
                initcap(a.e_product_name) AS e_product_name,
                a.id_brand,
                b.e_brand_name
            FROM
                tr_product a, tr_brand b
            WHERE
                a.id_brand = '$i_brand'
                AND
                b.id_brand = a.id_brand
                AND i_product = '$i_product'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($iadjustment)
    {
        $id_customer = $this->input->post('idcustomer', TRUE);
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');
        return $this->db->query("SELECT 
                i_adjustment
            FROM 
                tm_adjustment
            WHERE 
                id_customer = '$id_customer'
                AND i_periode = '$i_periode'
        ", FALSE);
    } 
    
    /** Ambil Data Detail Product */
    public function get_item($dfrom, $dto, $id_customer)
    {
        $dfrom 	= date('Y-m-d', strtotime($dfrom));
		$dto 	= date('Y-m-d', strtotime($dto));

        if(!$id_customer){
            $id_customer = 'null';
        }

        $id = $this->id_user;

        $d_jangka_from  = date('Y-m', strtotime($dfrom)) . '-01';
        $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($dfrom)));

        if ($d_jangka_from == $dfrom) {
            $d_jangka_from = '9999-01-01';
            $d_jangka_to   = '9999-01-31';
        }
        return $this->db->query("SELECT
            a.id_customer,
            i.i_company,
            b.i_product,
            d.e_product_name,
            b.id_brand,
            e.e_brand_name,
            0 AS pembelian,
            0 AS retur,
            0 AS penjualan,
            (b.n_adjustment ::DECIMAL) AS adjustment,
            0 AS stock_opname
        FROM
            tm_adjustment a
        INNER JOIN tm_adjustment_item b ON
            (b.id_adjustment = a.id_adjustment)
        INNER JOIN tr_product d ON 
            (d.i_product = b.i_product)
        INNER JOIN tr_brand e ON 
            (e.id_brand = b.id_brand)
        INNER JOIN tm_penjualan h ON
            (h.id_customer = a.id_customer AND h.id_user = COALESCE($id,h.id_user))
        INNER JOIN tm_penjualan_item i ON
            (i.id_document = h.id_document)
        WHERE
            a.f_status = 't'
            AND d.i_company = i.i_company 
            AND a.id_customer = COALESCE($id_customer,a.id_customer)
            AND a.d_adjustment BETWEEN '$dfrom' AND '$dto'
        GROUP BY
            3,2,1,4,5,6,10
                ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {
        $query = $this->db->query("SELECT max(id_adjustment)+1 AS id FROM tm_adjustment", TRUE);
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

        $dadjustment = ($this->input->post('ddocument', TRUE) != '') ? date('Y-m-d', strtotime($this->input->post('ddocument', TRUE))) : date('Y-m-d');
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');

        $table = array(
            'id_adjustment' => $id,
            'i_adjustment'  => $this->input->post('idocument', TRUE),
            'd_adjustment'  => $dadjustment,
            'i_periode'      => $i_periode,
            'id_customer'    => $this->input->post('idcustomer', TRUE),
            'e_remark'       => $this->input->post('eremark', TRUE),
        );
        $this->db->insert('tm_adjustment', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            if (is_array($this->input->post('i_product[]', TRUE)) || is_object($this->input->post('i_product[]', TRUE))) {
                $i = 0;
                foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                    $iproduct = $this->input->post('i_product', TRUE)[$i];
                    $product = explode(' - ',$iproduct);
                    $i_product = $product[0];
                    if ($i_product != '' || $i_product != null) {
                        $tabledetail = array(
                            'id_adjustment'     => $id,
                            'id_brand'          => $this->input->post('id_brand', TRUE)[$i],
                            'i_product'         => $i_product,
                            'n_adjustment'      => str_replace(',', '', $this->input->post('qty', TRUE)[$i]),
                            'e_remark'          => $this->input->post('e_remark', TRUE)[$i],
                        );
                        $this->db->insert('tm_adjustment_item', $tabledetail);
                    }
                    $i++;
                };
            }
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("SELECT
                a.*, b.e_customer_name
            FROM
                tm_adjustment a
            INNER JOIN 
                tr_customer b ON 
                (b.id_customer = a.id_customer)
            WHERE 
                id_adjustment = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("SELECT
                a.*,
                b.e_brand_name,
                c.e_product_name
            FROM
                tm_adjustment_item a
            INNER JOIN tr_brand b ON 
                (b.id_brand = a.id_brand)
            INNER JOIN tr_product c ON 
                (c.i_product = a.i_product AND a.id_brand = c.id_brand)
            WHERE
                id_adjustment = '$id'
            ORDER BY 
                a.id
        ", FALSE);
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

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('id', TRUE);

        $dadjustment = ($this->input->post('dadjustment', TRUE) != '') ? date('Y-m-d', strtotime($this->input->post('dadjustment', TRUE))) : date('Y-m-d');
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');

        $table = array(
            'i_adjustment'  => $this->input->post('idocument', TRUE),
            'd_adjustment'  => $dadjustment,
            'i_periode'      => $i_periode,
            'id_customer'    => $this->input->post('idcustomer', TRUE),
            'e_remark'       => $this->input->post('eremark', TRUE),
            'd_update'       => current_datetime(),
        );
        $this->db->where('id_adjustment', $id);
        $this->db->update('tm_adjustment', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            if (is_array($this->input->post('i_product[]', TRUE)) || is_object($this->input->post('i_product[]', TRUE))) {
                $this->db->where('id_adjustment', $id);
                $this->db->delete('tm_adjustment_item');
                $i = 0;
                foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                    $iproduct = $this->input->post('i_product', TRUE)[$i];
                    $product = explode(' - ',$iproduct);
                    $i_product = $product[0];
                    if ($i_product != '' || $i_product != null) {
                        $tabledetail = array(
                            'id_adjustment'    => $id,
                            'id_brand'         => $this->input->post('id_brand', TRUE)[$i],
                            'i_product'        => $i_product,
                            'n_adjustment'     => str_replace(',', '', $this->input->post('qty', TRUE)[$i]),
                            'e_remark'         => $this->input->post('e_remark', TRUE)[$i],
                        );
                        $this->db->insert('tm_adjustment_item', $tabledetail);
                    }
                    $i++;
                };
            }
        };
    }

    public function cancel($id)
    {
        $data = array(
            'f_status' => false,
        );
        $this->db->where('id_adjustment', $id);
        $this->db->update('tm_adjustment', $data);
    }

    /** Get Data Periode */
    public function getperiode()
    {
        return $this->db->query("SELECT
                max(i_periode) AS i_periode
                FROM tm_adjustment 
        ", FALSE);
    }

    /** Approve */
    public function approve($id)
    {
            $table = array(
                'd_approve' => date('Y-m-d'), 
            );
            $this->db->where('id_adjustment', $id);
            $this->db->update('tm_adjustment', $table);
   
    }

    public function delete($id)
    {
        $this->db->where('id_adjustment', $id);
        $this->db->delete('tm_adjustment_item');
        $this->db->where('id_adjustment', $id);
        $this->db->delete('tm_adjustment');
    }

}

/* End of file Mmaster.php */
