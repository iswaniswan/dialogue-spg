<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mmutasibrand extends CI_Model
{

    /** List Datatable */
    public function serverside($dfrom, $dto, $id_customer, $id_brand = "all")
    {
              
        $datatables = new Datatables(new CodeigniterAdapter);

        $id_user = $this->id_user;

        // if ($id_customer === "all") {

        //         $id_customer = 'NULL';
                
        // } else {
        // $id_customer = $id_customer;
        // }
        // if ($id_user === 1) {

        //     $id_user = 'NULL';
        // } 
        // if($id_brand === "all"){
        //     $where = "";
        // }
        // else if(!$id_brand) {
        //     $where = "";
        // }else {
        //     $where = "WHERE a.id_brand = '$id_brand'";
        // }

        // $d_from         = $dfrom;
        // $d_to           = $dto;
        // $d_jangka_from  = date('Y-m', strtotime($d_from)) . '-01';
        // $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($d_from)));

        // if ($d_jangka_from == $d_from) {
        //     $d_jangka_from = '9999-01-01';
        //     //$d_jangka_to   = '9999-01-31';
        // }

        $user_cover = "SELECT id_customer FROM tm_user_customer
                        WHERE id_user = '$id_user'";

        $user_customer = "SELECT id_customer
                FROM tr_customer
                WHERE f_status = 't' AND id_customer IN ($user_cover)";

        $where_customer = "AND a.id_customer IN ($user_customer)";

        if ($id_customer != null) {
            $where_customer = " AND a.id_customer='$id_customer'";
        }

        $where_and = '';

        $where_and .= $where_customer;

        if ($id_brand != null) {
            $where_and .= " AND a.id_brand='$id_brand'";
        }

        $first_date = '2022-01-01';
        $last_date_before_from = strtotime('-1 day', strtotime($dfrom));
        $last_date_before_from = date('Y-m-d', $last_date_before_from);

        $sql = "SELECT
                    0 AS no,
                    c.e_customer_name,
                    i_product,
                    initcap(e_product_name) AS e_product_name,
                    initcap(e_brand_name) AS e_brand_name,
                    saldo_awal,
                    pembelian,
                    retur,
                    penjualan,
                    adjustment,
                    saldo_akhir,
                    stock_opname,
                    (saldo_akhir - stock_opname) AS selisih
                FROM f_mutasi_brand_baru_new_new('$first_date', '$last_date_before_from', '$dfrom','$dto') a
                INNER JOIN tr_customer c ON (c.id_customer = a.id_customer)
                $where_and
                ORDER BY e_customer_name ASC";

        // var_dump($sql); die();

        $datatables->query($sql, FALSE);

        /** Cek Hak Akses, Apakah User Bisa Edit */
        $datatables->add('action', function ($data) {
            $saldoakhir     = trim($data['saldo_akhir']);
            $data       = '';
            if ($saldoakhir<0) {
                $data      .= "<button class='btn btn-sm badge rounded-round alpha-danger text-danger-800 border-danger-600 legitRipple'>Barang Minus</button>";
            }

            return $data;
        });
        return $datatables->generate();
    }

    /** Ambil Data Company */
    public function get_company()
    {
        if ($this->i_company == 'all') {
            $where = "AND i_company IN (
                SELECT 
                    i_company
                FROM
                    tm_user_company
                WHERE id_user = '$this->id_user'                
            )";
        } else {
            $where = "AND i_company = '$this->i_company' ";
        }
        return $this->db->query("
            SELECT
                i_company,
                e_company_name
            FROM
                tr_company
            WHERE
                f_status = 't'
            ORDER BY
                e_company_name ASC
        ", FALSE);
    }

    /** Ambil Data Customer */
    public function get_customer($cari='', $id_customer=null)
    {
        $limit = " LIMIT 5";
        if ($cari != '') {
            $limit = '';
        }

        $user_cover = "SELECT id_customer FROM tm_user_customer
                        WHERE id_user = '$this->id_user'";

        if ($id_customer != null) {
            $user_cover = $id_customer;
        }

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

    public function get_user_customer_brand($cari='', $id_user, $id_customer=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND id_customer = '$id_customer'";
        }

        $sql = "SELECT tb.id_brand AS id, tb.e_brand_name 
                FROM tm_user_brand tub 
                INNER JOIN tm_user_customer tuc ON tuc.id = tub.id_user_customer
                INNER JOIN tr_brand tb ON tb.id_brand = tub.id_brand 
                WHERE id_user = '$id_user' 
                    $where_and 
                    AND tb.e_brand_name ILIKE '%$cari%'";

        return $this->db->query($sql);
    }

    /** Ambil Data Customer */
    // public function get_brand($id_user = null)
    // {
    //     $where = " WHERE id_user = COALESCE($id_user,id_user)";
    //     if ($id_user == null) {
    //         $where = "";
    //     }

    //     $sql = "SELECT id_brand, e_brand_name
    //             FROM tr_brand
    //             WHERE id_brand IN (SELECT id_brand from tm_user_brand $where)
    //             ORDER BY e_brand_name ASC";          

    //     return $this->db->query($sql, FALSE);
    // }

    /** Export Data */
    public function __export_data($id, $brand, $dfrom, $dto)
    {

        $id_user = $this->id_user;

        if ($id == "all") {

                $id_customer = 'NULL';
                
        } else {
        $id_customer = $id;
        }
        if ($id_user === 1) {

            $id_user = 'NULL';
        }

        if($brand === "all"){
            $where = "";
        }
        else if(!$brand) {
            $where = "";
        }else {
            $where = "WHERE a.id_brand = '$brand'";
        }

    $d_from         = date('Y-m-d',strtotime($dfrom));
    $d_to           = date('Y-m-d',strtotime($dto));
    $d_jangka_from  = date('Y-m', strtotime($d_from)) . '-01';
    $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($d_from)));

    if ($d_jangka_from == $d_from) {
        $d_jangka_from = '9999-01-01';
        //$d_jangka_to   = '9999-01-31';
    }

    $query = $this->db->query("SELECT
            c.e_customer_name,
            i_product,
            initcap(e_product_name) AS e_product_name,
            initcap(e_brand_name) AS e_brand_name,
            saldo_awal,
            pembelian,
            retur,
            penjualan,
            adjustment,
            saldo_akhir,
            stock_opname,
            (saldo_akhir - stock_opname) AS selisih,
            CASE
            WHEN saldo_akhir < 0 THEN 'Barang Minus'
            END keterangan
        FROM
            f_mutasi_brand_baru_new_new('$d_from','$d_to','$d_jangka_from','$d_jangka_to',$id_customer,$id_user) a
        INNER JOIN tr_customer c ON 
                (c.id_customer = COALESCE(".$id_customer.",a.id_customer))
            $where
        ORDER BY saldo_akhir ASC");

    return $query;
    }

    public function export_data($dfrom, $dto, $id_customer=null, $id_brand=null)
    {
        $first_date = '2022-01-01';
        $last_date_before_from = strtotime('-1 day', strtotime($dfrom));
        $last_date_before_from = date('Y-m-d', $last_date_before_from);

        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND a.id_brand='$id_brand'";
        }

        $sql = "SELECT
                    c.e_customer_name,
                    i_product,
                    initcap(e_product_name) AS e_product_name,
                    initcap(e_brand_name) AS e_brand_name,
                    saldo_awal,
                    pembelian,
                    retur,
                    penjualan,
                    adjustment,
                    saldo_akhir,
                    stock_opname,
                    (saldo_akhir - stock_opname) AS selisih,
                    CASE WHEN saldo_akhir < 0 
                        THEN 'Barang Minus'
                    END keterangan
                FROM f_mutasi_brand_baru_new_new('$first_date', '$last_date_before_from', '$dfrom','$dto') a
                INNER JOIN tr_customer c ON (c.id_customer = a.id_customer)
                $where_and
                ORDER BY saldo_akhir ASC";

        return $this->db->query($sql);
    }
}

/* End of file Mmaster.php */
