<?php
defined('BASEPATH') OR exit('No direct script access allowed');
/* use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter; */

class Mdashboard extends CI_Model {

    /** Get Data Penjualan */
    public function get_chart_history($year)
    {
        if ($this->i_company=='all') {
            $where = "
                WHERE b.i_company IN (
                SELECT 
                    i_company
                FROM 
                    tm_user_company
                WHERE 
                    id_user = '$this->id_user'
            )
            ";
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
            $where = "
                WHERE b.i_company = '$this->i_company'
            ";
            $and = "
                AND b.i_company = '$this->i_company'
            ";
        }
        return $this->db->query("        
            WITH a AS (
                SELECT
                    to_char(m, 'Mon') AS MONTH,
                    e_company_name,
                    i_company
                FROM
                    generate_series( '$year-01-01'::date, '$year-12-31', '1 month' ) s(m)
                CROSS JOIN tr_company b
                $where
                ORDER BY
                        i_company)
                SELECT
                    e_company_name,
                    jsonb_agg(a.MONTH) AS MONTH,
                    jsonb_agg(COALESCE (b.qty, 0)) AS qty
                FROM
                    (
                    SELECT
                        sum(n_qty) AS qty,
                        a.i_company,
                        to_char(c.d_document, 'Mon') AS MONTH
                    FROM
                        tm_penjualan_item a
                    INNER JOIN tr_company b ON
                        (b.i_company = a.i_company)
                    INNER JOIN tm_penjualan c ON
                        (c.id_document = a.id_document)
                    WHERE
                        to_char(c.d_document, 'YYYY') = '$year'
                        AND c.f_status = 't'
                        $and
                    GROUP BY
                        2,
                        3 ) AS b
                RIGHT JOIN a ON
                    (a.i_company = b.i_company
                        AND a.MONTH = b.MONTH)
                GROUP BY
                    a.e_company_name
                ORDER BY 
                    a.e_company_name
        ", FALSE);
    }

    /** Get Data Bulan 1 Tahun */
    public function get_bulan($year)
    {
        return $this->db->query("SELECT
                jsonb_agg(to_char(m, 'Mon')) AS MONTH
            FROM
                generate_series( '$year-01-01'::date, '$year-12-31', '1 month' ) s(m)");
    }

    /** Get Data Company */
    public function get_company()
    {
        if ($this->i_company=='all') {
            $where = "
                WHERE i_company IN (
                SELECT 
                    i_company
                FROM 
                    tm_user_company
                WHERE 
                    id_user = '$this->id_user'
            )
            ";
        }else{
            $where = "
                WHERE i_company = '$this->i_company'
            ";
        }
        return $this->db->query("SELECT
                jsonb_agg(e_company_name) AS e_company_name
            FROM
                tr_company
            $where
            ORDER BY e_company_name ASC");
    }

    public function get_notif_saldo()
    {
        return $this->db->query("
            SELECT
                id,
                i_periode,
                d_entry
            FROM
                tm_mutasi_saldoawal
            WHERE
                d_approve = NULL AND
                f_status = 't'
        ", FALSE);
    }

    public function clear_database()
    {
        $result = "success";

        /** instance model */
        $CI = &get_instance();

        /** log */
        $CI->load->model('Logger');
        $CI->Logger->delete_all();

        /** master toko */
        $CI->load->model('Mcustomer');
        $CI->Mcustomer->delete_all();

        /** master user */
        $CI->load->model('Muser');
        $CI->Muser->delete_all();

        /** customer price */
        $CI->load->model('Mproductprice');
        $CI->Mproductprice->delete_all();

        /** master product */
        $CI->load->model('Mproduct');
        $CI->Mproduct->delete_all();

        /** master brand */
        $CI->load->model('Mbrand');
        $CI->Mbrand->delete_all();

        /** master alasan */
        $CI->load->model('Malasan');
        $CI->Malasan->delete_all();

        /** retur */
        $CI->load->model('Mretur');
        $CI->Mretur->delete_all();

        // /** stockopname */
        $CI->load->model('Mso');
        $CI->Mso->delete_all();

        echo $result;
    }
}

/* End of file Mmaster.php */
