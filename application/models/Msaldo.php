<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Msaldo extends CI_Model
{

    /** List Datatable */
    public function serverside()
    {
        $datatables = new Datatables(new CodeigniterAdapter);
        if ($this->fallcustomer == 't') {
            $and = "";
        } else {
            $and = "
                WHERE a.id_customer IN (
                    SELECT 
                        id_customer
                    FROM
                        tm_user_customer
                    WHERE id_user = '$this->id_user'                
                )
            ";
        }
        $datatables->query("SELECT
                a.id,
                a.id_customer,
                b.e_customer_name,
                i_periode,
                d_approve,
                e_remark,
                a.f_status
            FROM
                tm_mutasi_saldoawal a
            INNER JOIN tr_customer b ON
                (a.id_customer = b.id_customer)
            $and
        ", FALSE);

        $datatables->edit('f_status', function ($data) {
            if ($data['f_status'] == 't') {
                $status = 'Active';
                $color  = 'success';
            } else {
                $status = 'Not Active';
                $color  = 'danger';
            }
            $data = "<span class='btn btn-sm badge rounded-round alpha-" . $color . " text-" . $color . "-800 border-" . $color . "-600 legitRipple'>" . $status . "</span>";
            return $data;
        });

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

        /** Cek Hak Akses, Apakah User Bisa Edit */
        // if (check_role($this->id_menu, 3)) {
        $datatables->add('action', function ($data) {
            $id        = trim($data['id']);
            $d_approve = trim($data['d_approve']);
            $i_periode = trim($data['i_periode']);
            $id_customer = trim($data['id_customer']);
            $status    = $data['f_status'];
            /* $i_company  = $data['i_company'];
            $id_customer= $data['id_customer']; */
            $data = "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "' title='View Data'><i class='icon-database-check text-success-800 mr-1'></i></a>";
                            
            if (check_role($this->id_menu, 3) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                $data      .= "<a href='" . base_url() . $this->folder . '/edit/' . encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "' title='Edit Data'><i class='icon-database-edit2 mr-1 text-" . $this->color . "-800'></i></a>";
            }

            if (check_role($this->id_menu, 4) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                $data      .= "<a href='#' onclick='sweetcancel(\"" . $this->folder . "\",\"" . $id . "\");' title='Cancel Data'><i class='icon-database-remove text-danger-800 mr-1'></i></a>";
            }
            
            if (check_role($this->id_menu, 5) && ($d_approve == '' || $d_approve == null) && $status == 't') {
                $data      .= "<a href='" . base_url() . $this->folder . '/approvement/'. encrypt_url($id) .'/'.encrypt_url($i_periode).'/'.encrypt_url($id_customer) . "'  title='Approve Data'><i class='icon-database-check text-teal-800 mr-1'></i></a>";
            }

            return $data;
        });
        // }
        $datatables->hide('id_customer');
        return $datatables->generate();
    }

    /** Get Data Company */
    public function get_company_data()
    {
        return $this->db->query("
            SELECT 
                i_company,
                e_company_name
            FROM 
                tr_company 
            WHERE 
                f_status = 't'
                AND db_name IS NOT NULL
                AND i_company IN (
                    SELECT 
                        i_company
                    FROM 
                        tm_user_company
                    WHERE 
                        id_user = '$this->id_user'
                )
            ORDER BY 2
        ", FALSE);
    }

    /** Get Data Customer by user cover */
    public function get_customer($cari='', $i_periode)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = "LIMIT 5";
        if ($cari != '') {
            $limit = "";
        }

        $sql_mutasi = "SELECT id_customer
                        FROM tm_mutasi_saldoawal";
                        // WHERE i_periode = '$i_periode'";

        $sql = "SELECT id_customer AS id, e_customer_name AS e_name
                FROM tr_customer 
                WHERE (e_customer_name ILIKE '%$cari%') AND f_status = 't' 
                    AND id_customer IN (
                                        SELECT  id_customer
                                        FROM tm_user_customer
                                        WHERE id_user = '$id_user' 
                                            AND id_customer NOT IN ($sql_mutasi)        
                                    )
                ORDER BY 2
                $limit";

        // var_dump($sql);

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
    public function get_detail_product($id_product)
    {
        $sql = "SELECT a.id_brand,
                    initcap(a.e_product_name) AS e_product_name,                    
                    c.e_brand_name
                FROM tr_product a
                INNER JOIN tr_brand c ON c.id_brand = a.id_brand
                WHERE a.id = '$id_product'";

        return $this->db->query($sql, FALSE);
    }
    // public function get_detail_product($i_product,$i_brand/* , $i_company */)
    // {
    //     return $this->db->query("SELECT
    //     initcap(a.e_product_name) AS e_product_name,
    //     a.id_brand,
    //     c.e_brand_name, 
    //     a.i_company,
    //     b.e_company_name
    // FROM
    //     tr_product a
    // INNER JOIN
    //     tr_company b ON (b.i_company = a.i_company)
    // INNER JOIN
    //     tr_brand c ON (c.id_brand = a.id_brand)
    // WHERE
    //     b.i_company = a.i_company
    //     AND a.i_product = '$i_product'
    //     AND a.id_brand = '$i_brand'
    //     ", FALSE);
    // }

    /** Simpan Data */
    public function save()
    {
        $id_user = $this->session->userdata('id_user');

        $year = $this->input->post('year');
		$month = $this->input->post('month');
		$i_periode = "$year$month";

        $data_header = [
            'id_customer' => $this->input->post('icustomer', TRUE),
            'i_periode' => $i_periode,
            'e_remark' => $this->input->post('eremark', TRUE),
            'id_user' => $id_user
        ];

        $this->db->insert('tm_mutasi_saldoawal', $data_header);
        $id_header = $this->db->insert_id();

        $items = $this->input->post('items');

        foreach ($items as $item) {
            $data_detail = [
                'id_header' => $id_header,
                'id_product' => $item['id_product'],
                'n_saldo' => $item['qty']
            ];
            $this->db->insert('tm_mutasi_saldoawal_item', $data_detail);            
        };
<<<<<<< HEAD
=======


        /** generate pesan untuk notification */
        $this->generate_notification($id_header);
>>>>>>> 844c827aad37b9956919299383305669e1af12d7
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        $sql = "SELECT *
                FROM tm_mutasi_saldoawal
                WHERE id = '$id'";

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        $sql = "SELECT a.*,
                    b.e_product_name AS e_product,
                    b.i_product,
                    c.id_brand,
                    c.e_brand_name AS brand,
                    a.n_saldo AS qty
                FROM tm_mutasi_saldoawal_item a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_brand c ON c.id_brand = b.id_brand
                WHERE a.id_header = '$id'
                ORDER BY a.id_product";

        // var_dump($sql); die();
        
        return $this->db->query($sql, FALSE);
    }

    /** Export Data */
    public function export_data_by_user_cover($id_customer, $i_periode)
    {
        /* if ($this->i_company == '1') {
            $where = "AND i_company IN (SELECT i_company FROM tm_user_company WHERE id_user = '$this->id_user' )";
        }else{
            $where = "AND i_company = '$this->i_company'";
        } */

        $id_user = $this->session->userdata('id_user');

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        $sql_product = "SELECT a.id,
                i_product,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand,
                $id_customer AS id_customer
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE a.f_status = 't'AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4, 1";

        $sql_mutasi = "SELECT tms.*, tmsi.id_product, tmsi.n_saldo
                       FROM tm_mutasi_saldoawal tms
                       INNER JOIN tm_mutasi_saldoawal_item tmsi ON tmsi.id_header = tms.id
                       WHERE tms.i_periode = '$i_periode' AND tms.id_customer = '$id_customer'";

        $sql = "WITH CTE AS ($sql_product)
                SELECT CTE.brand, CTE.id AS id_product, CTE.i_product, CTE.e_name, sm.n_saldo
                FROM ($sql_mutasi) AS sm
                RIGHT JOIN CTE ON CTE.id = sm.id_product";

        // var_dump($sql); die();  

        return $this->db->query($sql);
    }

    public function cek_produk($i_product, $i_company)
    {
        $this->db->where('i_product', $i_product);
        $this->db->where('i_company', $i_company);
        return $this->db->get('tr_product');
    }

    private function is_mutasi_exist($i_periode, $id_customer, $return_id=false)
    {
        $sql = "SELECT *
                FROM tm_mutasi_saldoawal
                WHERE i_periode = '$i_periode' AND id_customer = '$id_customer'";

        $query = $this->db->query($sql);

        if ($return_id) {
            $result = $query->result()[0];
            return $result->id;
        }

        return $query->num_rows() > 0;
    }

    public function transfer()
    {
        $id_customer = $this->input->post('id_customer', TRUE);
        $i_periode = $this->input->post('i_periode', TRUE);
        $e_remark = $this->input->post('e_remark', TRUE);

        // cek if create or update
        $id_mutasi_saldoawal = null;
        if ($this->is_mutasi_exist($i_periode, $id_customer)) {
            $id_mutasi_saldoawal = $this->is_mutasi_exist($i_periode, $id_customer, true);
        };

        // create 
        $sql = "INSERT INTO tm_mutasi_saldoawal (id_customer, i_periode, e_remark, d_entry)     
                        VALUES ($id_customer, '$i_periode', '$e_remark', now())";

        if ($id_mutasi_saldoawal != null) {
            // update
            $sql = "INSERT INTO tm_mutasi_saldoawal (id, id_customer, i_periode, e_remark, d_entry)
                    VALUES ($id_mutasi_saldoawal, $id_customer, '$i_periode', '$e_remark', now())
                    ON CONFLICT (id_customer, i_periode) 
                        DO UPDATE 
                        SET e_remark = excluded.e_remark,
                            d_update = now()";
        }

        $this->db->query($sql, FALSE);

        if ($id_mutasi_saldoawal == null) {
            $id_mutasi_saldoawal = $this->db->insert_id();
        }

        $jml = $this->input->post('jml', TRUE);
        for ($i = 1; $i <= $jml; $i++) {
            $id_product   = $this->input->post('id_product' . $i, TRUE);
            $qty = $this->input->post('qty' . $i, TRUE);

            $sql = "INSERT INTO tm_mutasi_saldoawal_item (id_header, id_product, n_saldo) 
                    VALUES ($id_mutasi_saldoawal, $id_product, $qty)
                    ON CONFLICT (id_header, id_product) 
                        DO UPDATE 
                        SET n_saldo = excluded.n_saldo
                        WHERE excluded.n_saldo > 0";

            $this->db->query($sql, FALSE);
        }
    }

    public function update_detail()
    {
        $id = $this->input->post('id', TRUE);
        $data_header = [
            'id_customer' => $this->input->post('id_customer', TRUE),
            'i_periode' => $this->input->post('i_periode', TRUE),
            'e_remark' => $this->input->post('e_remark', TRUE),
            'd_update' => date('Y-m-d H:i:s')
        ];
        $this->db->where('id', $id);
        $this->db->update('tm_mutasi_saldoawal', $data_header);

        $items = $this->input->post('items');        
        $this->db->where('id_header', $id);
        $this->db->delete('tm_mutasi_saldoawal_item');

        foreach ($items as $item) {
            $id_header = $id;
            $id_product = $item['id_product'];
            $qty = $item['qty'];

            $sql = "INSERT INTO tm_mutasi_saldoawal_item 
                        (id_header, id_product, n_saldo)
                    VALUES ($id_header,$id_product, $qty)
                    ON CONFLICT (id_header, id_product) 
                        DO UPDATE 
                        SET n_saldo = $qty";

            $this->db->query($sql, FALSE);
        };
    }

    public function update_header($id){
        $this->db->set('d_approve', '');
        $this->db->where('id', $id);
        $this->db->update('tm_mutasi_saldoawal');
    }

    public function cancel($id)
    {

        $this->db->query("DELETE FROM tm_mutasi_saldoawal_item where id_header = '$id'");
        $this->db->query("DELETE FROM tm_mutasi_saldoawal where id = '$id'");

    }

    public function approve($id)
    {
        $data = array(
            'i_approve' => $this->id_user,
            'd_approve' => date('Y-m-d'),
        );
        $this->db->where('id', $id);
        $this->db->update('tm_mutasi_saldoawal', $data);
    }

    public function get_customer_by_id($id_customer)
    {
        $this->db->select();
        $this->db->where('id_customer', $id_customer);
        return $this->db->get('tr_customer');        
    }
<<<<<<< HEAD
=======

    public function generate_notification($id_reff)
    {
        $this->load->model('Mnotification');
        $this->Mnotification->create_notification_saldo_awal($id_reff);
    }

    
>>>>>>> 844c827aad37b9956919299383305669e1af12d7
}

/* End of file Mmaster.php */
