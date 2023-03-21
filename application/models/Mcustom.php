<?php
defined('BASEPATH') OR exit('No direct script access allowed');
/* use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter; */

class Mcustom extends CI_Model {

    public function get_company($id_user)
    {
        return $this->db->query("
            SELECT
                b.i_company,
                b.e_company_name
            FROM
                tm_user_company a
            JOIN tr_company b ON
                (b.i_company = a.i_company)
            WHERE
                a.id_user = '$id_user'
            ORDER BY
                1 asc
        ", FALSE);
    }

    public function get_menu($id_user)
    {
        return $this->db->query("
            SELECT
                DISTINCT a.*
            FROM
                tr_menu a
            INNER JOIN tm_user_role b ON
                (a.id_menu = b.id_menu)
            INNER JOIN tm_user c ON
                (c.i_level = b.i_level)
            WHERE
                c.id_user = '$id_user'
                AND a.i_parent = '0'
                AND a.f_status = 't'
            ORDER BY
                4,
                1
        ", FALSE);
    }

    public function get_sub_menu($id_user,$id_menu)
    {
        return $this->db->query("
            SELECT
                DISTINCT a.*
            FROM
                tr_menu a
            INNER JOIN tm_user_role b ON
                (a.id_menu = b.id_menu)
            INNER JOIN tm_user c ON
                (c.i_level = b.i_level)
            WHERE
                c.id_user = '$id_user'
                AND a.i_parent = '$id_menu'
                AND a.f_status = 't'
            ORDER BY
                4,
                1
        ", FALSE);
    }

    public function cek_role($id_user,$id_menu,$id)
    {
        $sql = "SELECT DISTINCT a.*
                FROM tr_menu a
                INNER JOIN tm_user_role b ON a.id_menu = b.id_menu
                INNER JOIN tm_user c ON c.i_level = b.i_level
                WHERE c.id_user = '$id_user'
                    AND a.id_menu = '$id_menu'
                    AND b.i_power = '$id'
                ORDER BY 4, 1";

        // var_dump($sql); die();

        return $this->db->query($sql, FALSE);
    }

    public function get_notif_saldo()
    {
        return $this->db->query("
            SELECT
                id,
                id_customer,
                i_periode,
                d_entry
            FROM
                tm_mutasi_saldoawal
            WHERE
                d_approve IS NULL AND
                f_status = 't'
        ", FALSE);
    }

    public function get_notif_retur()
    {
        return $this->db->query("
            SELECT
                id,
                i_document,
                d_entry
            FROM
                tm_pembelian_retur
            WHERE
                d_approve IS NULL AND
                f_status = 't'
        ", FALSE);
    }

    public function get_notif_adjust()
    {
        return $this->db->query("
            SELECT
                id,
                i_document,
                d_entry
            FROM
                tm_adjustment
            WHERE
                d_approve IS NULL AND
                f_status = 't'
        ", FALSE);
    }
}

/* End of file Mmaster.php */
