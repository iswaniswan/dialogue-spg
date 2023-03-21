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

        $sql = "SELECT
                    id,
                    i_document,
                    i_periode,
                    to_char(d_document, 'DD FMMonth YYYY') AS d_so,
                    d_document,
                    b.e_customer_name,
                    e_remark,
                    a.f_status
                FROM tm_stockopname a, tr_customer b
                WHERE 
                    a.id_customer = b.id_customer
                    AND d_document BETWEEN '$dfrom' 
                    AND '$dto'
                ORDER BY a.d_entry DESC";

        // var_dump($sql); die();
        
        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $id = $data['id'];
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
            $id         = trim($data['id']);
            $ddocument  = $data['d_document'];
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
        $datatables->hide('d_document');
        return $datatables->generate();
    }

    /** Running Number Dokumen */

    public function runningnumber($thbl, $tahun)
    {
        $query  = $this->db->query("SELECT
                max(substring(i_document, 9, 3)) AS max
            FROM
                tm_stockopname
            WHERE 
                f_status = 't'
                AND substring(i_document, 4, 2) = substring('$thbl',1,2)
                AND to_char (d_document, 'yyyy') >= '$tahun'
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
        $sql = "SELECT a.*, b.e_customer_name
                FROM tm_stockopname a
                INNER JOIN tr_customer b ON (b.id_customer = a.id_customer)
                WHERE id = '$id'";

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        $sql = "SELECT
                    a.*,
                    c.i_product,
                    c.e_product_name,
                    d.e_brand_name
                FROM tm_stockopname_item a
                INNER JOIN tm_stockopname b ON b.id = a.id_stockopname
                INNER JOIN tr_product c ON c.id = a.id_product
                INNER JOIN tr_brand d ON d.id_brand = c.id_brand
                WHERE b.id = '$id'
                ORDER BY a.id";

        // var_dump($sql); die();

        return $this->db->query($sql, FALSE);
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
        $this->db->where('id', $id);
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

    public function insert_stockopname($i_document, $d_document, $id_customer, $i_periode, $e_remark, $id_user=null)
    {
        if ($id_user == null) {
            $id_user = $this->session->userdata('id_user');
        };

        $data = [
            'i_document' => $i_document,
            'd_document' => $d_document,
            'i_periode' => $i_periode,
            'id_customer' => $id_customer,
            'e_remark' => $e_remark,
            'id_user' => $id_user,
        ];
        $this->db->insert('tm_stockopname', $data);
    }

    public function insert_stockopname_item($id_stockopname, $id_product, $n_qty)
    {
        $data = [
            'id_stockopname' => $id_stockopname,
            'id_product' => $id_product,
            'n_qty' => $n_qty
        ];
        $this->db->insert('tm_stockopname_item', $data);
    }

    public function update_stockopname($i_document, $d_document, $id_customer, $i_periode, $e_remark, $id)
    {
        $data = [
            'i_document' => $i_document,
            'd_document' => $d_document,
            'i_periode' => $i_periode,
            'id_customer' => $id_customer,
            'e_remark' => $e_remark,
        ];

        $this->db->where('id', $id);
        $this->db->update('tm_stockopname', $data);
    }

    public function delete_stockopname_item_by_id_stockopname($id_stockopname)
    {
        $this->db->where('id_stockopname', $id_stockopname);
        $this->db->delete('tm_stockopname_item');
    }

    public function get_customer_by_id($id_customer){
        $sql = "SELECT * 
                FROM tr_customer 
                WHERE id_customer = '$id_customer'";

        return $this->db->query($sql, FALSE);
    }

    public function export_data_by_user_cover($id_customer)
    {
        $id_user = $this->session->userdata('id_user');
        $i_periode = date('Ym');

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        $cte = "SELECT a.id,
                i_product,
                e_product_name,
                a.id_brand,
                b.e_brand_name
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE a.f_status = 't'AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4, 1";

        $sql = "WITH CTE AS ($cte) 
                SELECT CTE.id, CTE.i_product, CTE.e_product_name, CTE.e_brand_name, so.n_qty
                    FROM CTE
                    LEFT JOIN (
                        SELECT tsi.id_product, tsi.n_qty
                        FROM tm_stockopname_item tsi
                        INNER JOIN tm_stockopname ts ON ts.id = tsi.id_stockopname                        
                        WHERE ts.id = (
                                SELECT max(id) FROM tm_stockopname ts 
                                WHERE i_periode = '$i_periode' and f_status='t'
                                    AND id_customer = '$id_customer'
                            )
                    ) so ON so.id_product = CTE.id 
                    ORDER BY CTE.i_product ASC, CTE.e_product_name ASC";

        // var_dump($sql); die();

        return $this->db->query($sql);
    }

    public function transfer()
    {
        $id_customer = $this->input->post('id_customer', TRUE);
        $jml = $this->input->post('jml', TRUE);

        for ($i=1; $i <= $jml; $i++) { 
            $id_product   = $this->input->post('id_product'.$i, TRUE);
            $vprice     = $this->input->post('v_price'.$i, TRUE);

            $sql = "INSERT INTO tr_customer_price (id_customer, id_product, v_price, d_entry) 
                    VALUES ($id_customer, $id_product, $vprice, now())
                    ON CONFLICT (id_customer, id_product) DO UPDATE 
                    SET v_price = $vprice, 
                        d_update = now()";

            $this->db->query($sql, FALSE);
        }
    }

    public function generate_nomor_dokumen($id_customer) {

        $kode = 'SO';

        $sql = "SELECT count(*) 
                FROM tm_stockopname ts
                WHERE ts.id_customer = '$id_customer'
                    AND to_char(d_document, 'yyyy-mm') = to_char(now(), 'yyyy-mm')
                    AND f_status = 't'";

        $query = $this->db->query($sql);
        $result = $query->row()->count;
        $count = intval($result) + 1;
        $generated = $kode . '-' . date('ym') . '-' . sprintf('%04d', $count);

        return $generated;
    }

    public function delete_all()
	{
		$sql = "TRUNCATE TABLE tm_stockopname CASCADE; 
                TRUNCATE TABLE tm_stockopname_item CASCADE;";

		return $this->db->query($sql);
	}

}
