<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mso extends CI_Model
{

    /** List Datatable */
    public function serverside($dfrom, $dto)
    {
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT
                id_stockopname,
                i_stockopname,
                i_periode,
                to_char(d_stockopname, 'DD FMMonth YYYY') AS d_so,
                d_stockopname,
                b.e_customer_name,
                e_remark,
                a.f_status
            FROM
                tm_stockopname a, tr_customer b
            WHERE 
                a.id_customer = b.id_customer
                AND d_stockopname BETWEEN '$dfrom' 
                AND '$dto'
            ORDER BY 
                d_stockopname, i_stockopname ASC
            ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_stockopname'];
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
            $id         = trim($data['id_stockopname']);
            $ddocument  = $data['d_stockopname'];
            $month      = date('m', strtotime($ddocument));
            $bulan      = date('m');
            $batas      = date('Y-m-t');
            $tgl        = date('Y-m-d');
            $cek        = $bulan-$month;
            $status     = $data['f_status'];
            $data       = '';

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }

            if (check_role($this->id_menu, 3) && $status == 't') {
                
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

            if (check_role($this->id_menu, 4) && $status == 't') {
                
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
        $datatables->hide('d_stockopname');
        return $datatables->generate();
    }

    /** Running Number Dokumen */

    public function runningnumber($thbl, $tahun)
    {
        $query  = $this->db->query("SELECT
                max(substring(i_stockopname, 9, 3)) AS max
            FROM
                tm_stockopname
            WHERE 
                f_status = 't'
                AND substring(i_stockopname, 4, 2) = substring('$thbl',1,2)
                AND to_char (d_stockopname, 'yyyy') >= '$tahun'
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
            $number = "SO-" . $thbl . "-" . $number;
            return $number;
        } else {
            $number = "001";
            $nomer  = "SO-" . $thbl . "-" . $number;
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
    public function get_product($cari)
    {
        return $this->db->query(" SELECT 
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
    public function cek($istockopname)
    {
        $id_customer = $this->input->post('idcustomer', TRUE);
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');
        return $this->db->query("SELECT 
                i_stockopname
            FROM 
                tm_stockopname
            WHERE 
                id_customer = '$id_customer'
                AND i_periode = '$i_periode'
        ", FALSE);
    } 
    
    /** Ambil Data Detail Product */
    public function get_item($tgl)
    {
        $dfrom = date('Y-m-01', strtotime($tgl));
        $dto = date('Y-m-t', strtotime($tgl));
        return $this->db->query("SELECT DISTINCT 
                i_product,
                initcap(e_product_name) AS e_product_name,
                b.e_company_name,
                a.i_company,
                0 AS n_stockopname
            FROM
                f_mutasi_saldo('$dfrom','$dto','9999-09-09','9999-09-09') a
            INNER JOIN tr_company b ON (b.i_company = a.i_company)
            ORDER BY 1
        ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {
        $query = $this->db->query("SELECT max(id_stockopname)+1 AS id FROM tm_stockopname", TRUE);
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

        $dstockopname = ($this->input->post('ddocument', TRUE) != '') ? date('Y-m-d', strtotime($this->input->post('ddocument', TRUE))) : date('Y-m-d');
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');

        $table = array(
            'id_stockopname' => $id,
            'i_stockopname'  => $this->input->post('idocument', TRUE),
            'd_stockopname'  => $dstockopname,
            'i_periode'      => $i_periode,
            'id_customer'    => $this->input->post('idcustomer', TRUE),
            'e_remark'       => $this->input->post('eremark', TRUE),
        );
        $this->db->insert('tm_stockopname', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            if (is_array($this->input->post('i_product[]', TRUE)) || is_object($this->input->post('i_product[]', TRUE))) {
                $i = 0;
                foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                    $iproduct = $this->input->post('i_product', TRUE)[$i];
                    $product = explode(' - ',$iproduct);
                    $i_product = $product[0];
                    if ($i_product != '' || $i_product != null) {
                        $tabledetail = array(
                            'id_stockopname'    => $id,
                            'i_company'         => $this->input->post('i_company', TRUE)[$i],
                            'i_product'         => $i_product,
                            'n_stockopname'     => str_replace(',', '', $this->input->post('qty', TRUE)[$i]),
                        );
                        $this->db->insert('tm_stockopname_item', $tabledetail);
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
                tm_stockopname a
            INNER JOIN 
                tr_customer b ON 
                (b.id_customer = a.id_customer)
            WHERE 
                id_stockopname = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("SELECT
                a.*,
                b.e_company_name,
                c.e_product_name
            FROM
                tm_stockopname_item a
            INNER JOIN tr_company b ON 
                (b.i_company = a.i_company)
            INNER JOIN tr_product c ON 
                (c.i_product = a.i_product AND a.i_company = c.i_company)
            WHERE
                id_stockopname = '$id'
            ORDER BY 
                a.id
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('id', TRUE);

        $dstockopname = ($this->input->post('dstockopname', TRUE) != '') ? date('Y-m-d', strtotime($this->input->post('dstockopname', TRUE))) : date('Y-m-d');
        $i_periode = ($this->input->post('ddocument', TRUE) != '') ? date('Ym', strtotime($this->input->post('ddocument', TRUE))) : date('Ym');

        $table = array(
            'i_stockopname'  => $this->input->post('idocument', TRUE),
            'd_stockopname'  => $dstockopname,
            'i_periode'      => $i_periode,
            'id_customer'    => $this->input->post('idcustomer', TRUE),
            'e_remark'       => $this->input->post('eremark', TRUE),
            'd_update'       => current_datetime(),
        );
        $this->db->where('id_stockopname', $id);
        $this->db->update('tm_stockopname', $table);

        if ($this->input->post('jml', TRUE) > 0) {
            if (is_array($this->input->post('i_product[]', TRUE)) || is_object($this->input->post('i_product[]', TRUE))) {
                $this->db->where('id_stockopname', $id);
                $this->db->delete('tm_stockopname_item');
                $i = 0;
                foreach ($this->input->post('i_product[]', TRUE) as $i_product) {
                    $iproduct = $this->input->post('i_product', TRUE)[$i];
                    $product = explode(' - ',$iproduct);
                    $i_product = $product[0];
                    if ($i_product != '' || $i_product != null) {
                        $tabledetail = array(
                            'id_stockopname'    => $id,
                            'i_company'         => $this->input->post('i_company', TRUE)[$i],
                            'i_product'         => $i_product,
                            'n_stockopname'     => str_replace(',', '', $this->input->post('qty', TRUE)[$i]),
                        );
                        $this->db->insert('tm_stockopname_item', $tabledetail);
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
        $this->db->where('id_stockopname', $id);
        $this->db->update('tm_stockopname', $data);
    }

    /** Get Data Periode */
    public function getperiode()
    {
        return $this->db->query("SELECT
                max(i_periode) AS i_periode
                FROM tm_stockopname 
        ", FALSE);
    }
}

/* End of file Mmaster.php */
