<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mmutasiperusahaan extends CI_Model
{

    /** List Datatable */
    public function serverside($dfrom, $dto, $id_customer)
    {
        
        if ($id_customer == 'all') {
            if ($this->fallcustomer == 'f') {
                $where = "WHERE a.id_customer IN (
                    SELECT 
                        id_customer
                    FROM 
                    tm_user_customer
                    WHERE 
                        id_user = '$this->id_user'
                        )
                        ";
            } else {
                $where = "";
            }
        } else {
            $where = "WHERE a.id_customer = $id_customer ";
        }
        $datatables = new Datatables(new CodeigniterAdapter);

        $d_from         = $dfrom;
        $d_to           = $dto;
        $d_jangka_from  = date('Y-m', strtotime($d_from)) . '-01';
        $d_jangka_to    = date('Y-m-d', strtotime('-1 days', strtotime($d_from)));

        if ($d_jangka_from == $d_from) {
            $d_jangka_from = '9999-01-01';
            $d_jangka_to   = '9999-01-31';
        }

        $datatables->query("SELECT
                a.i_company,
                c.e_customer_name,
                i_product,
                initcap(e_product_name) AS e_product_name,
                saldo_awal,
                pembelian,
                retur,
                penjualan,
                saldo_akhir
            FROM
                f_mutasi_saldo_new('$d_from','$d_to','$d_jangka_from','$d_jangka_to') a
            INNER JOIN tr_company b ON 
                (b.i_company = a.i_company)
            INNER JOIN tr_customer c ON 
                (c.id_customer = a.id_customer)
            $where
            ", FALSE);
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
}

/* End of file Mmaster.php */
