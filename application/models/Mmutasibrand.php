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

        if ($id_customer === "all") {

                $id_customer = 'NULL';
                
        } else {
        $id_customer = $id_customer;
        }
        if ($id_user === 1) {

            $id_user = 'NULL';
        } 
        if($id_brand === "all"){
            $where = "";
        }
        else if(!$id_brand) {
            $where = "";
        }else {
            $where = "WHERE a.id_brand = '$id_brand'";
        }

        $d_from         = $dfrom;
        $d_to           = $dto;
        $d_jangka_from  = date('Y-m', strtotime($d_from)) . '-01';
        $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($d_from)));

        if ($d_jangka_from == $d_from) {
            $d_jangka_from = '9999-01-01';
            //$d_jangka_to   = '9999-01-31';
        }

        $datatables->query("SELECT
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
            FROM
                f_mutasi_brand_baru_new_new('$d_from','$d_to','$d_jangka_from','$d_jangka_to',".$id_customer.",".$id_user.") a
            INNER JOIN tr_customer c ON 
                (c.id_customer = COALESCE(".$id_customer.",a.id_customer))
            $where
            ORDER BY saldo_akhir ASC", FALSE);

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
    public function export_data($id, $brand, $dfrom, $dto)
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
}

/* End of file Mmaster.php */
