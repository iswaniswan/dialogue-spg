<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mgantipassword extends CI_Model {

    /** Ambil Data Customer */
    public function get_customer($cari)
    {
        return $this->db->query("
            SELECT
                id_customer,
                e_customer_name
            FROM
                tr_customer
            WHERE
                (e_customer_name ILIKE '%$cari%')
                AND f_status = 't'
            ORDER BY
                e_customer_name ASC
        ", FALSE);
    }


    /** Ambil Data Detail Customer */
    public function get_detail_customer($i_customer)
    {
        return $this->db->query("
            SELECT
                e_customer_name,
                e_customer_address,
                e_customer_owner,
                b.e_type
            FROM
                tr_customer a
            INNER JOIN tr_type_customer b ON
                (b.i_type = a.i_type)
            WHERE a.id_customer = '$i_customer'
        ", FALSE);
    }

    /** Get Data Brand */
    public function get_brand($cari)
    {
        return $this->db->query("
            SELECT 
                id_brand AS id,
                e_brand_name AS e_name
            FROM 
                tr_brand 
            WHERE 
                (e_brand_name ILIKE '%$cari%')
                AND f_status = 't'
            ORDER BY 2
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($username)
    {
        return $this->db->query("
            SELECT 
                username
            FROM 
                tm_user 
            WHERE 
                trim(upper(username)) = trim(upper('$username'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save()
    {
        $query = $this->db->query("SELECT max(id_user)+1 AS id FROM tm_user", TRUE);
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

        $fallcustomer = ($this->input->post('fallcustomer', TRUE)=='on') ? true : false ;

        $table = array(
            "id_user"       => $id,
            "username"      => strtolower($this->input->post('username', TRUE)),
            "password"      => encrypt_password($this->input->post('password', TRUE)),
            "e_nama"        => ucwords($this->input->post('ename', TRUE)),
            "i_level"       => $this->input->post('ilevel', TRUE),
            "f_allcustomer" => $fallcustomer,
        );
        if ($this->db->insert('tm_user', $table)) {
            /*
            if (is_array($this->input->post('icompany[]', TRUE)) || is_object($this->input->post('icompany[]', TRUE))) {
                foreach ($this->input->post('icompany[]', TRUE) as $i_company) {
                    $tablecompany = array(
                        'id_user'   => $id,
                        'i_company' => $i_company,
                    );
                    $this->db->insert('tm_user_company', $tablecompany);
                };
            }
            */
            if (is_array($this->input->post('i_brand[]', TRUE)) || is_object($this->input->post('i_brand[]', TRUE))) {
                foreach ($this->input->post('i_brand[]', TRUE) as $id_brand) {
                    $tablecompany = array(
                        'id_user'  => $id,
                        'id_brand' => $id_brand,
                    );
                    $this->db->insert('tm_user_brand', $tablecompany);
                };
            }

            if ($fallcustomer==false){
                foreach ($this->input->post('i_customer[]') as $i_customer) {
                    $tablecustomer = array(
                        'id_user'       => $id,
                        'id_customer'   => $i_customer,
                    );
                    $this->db->insert('tm_user_customer', $tablecustomer);
                }
            }
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT
                *
            FROM
                tm_user
            WHERE 
                id_user = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("
            SELECT
                c.id_customer, 
                e_customer_name,
                e_customer_address,
                e_customer_owner,
                b.e_type
            FROM
                tr_customer a
            INNER JOIN tr_type_customer b ON
                (b.i_type = a.i_type)
            INNER JOIN tm_user_customer c ON
                (c.id_customer = a.id_customer)
            WHERE
                c.id_user = '$id'
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

    /** Get Data Company Edit */
    public function get_brand_data($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.selek
            FROM
                tr_brand a
            LEFT JOIN (
                SELECT
                    id_brand,
                    'selected' AS selek
                FROM
                    tm_user_brand
                WHERE
                    id_user = '$id'
            ) b ON
            (
                b.id_brand = a.id_brand
            )
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($username,$usernameold)
    {
        return $this->db->query("
            SELECT 
                username
            FROM 
                tm_user
            WHERE 
                username <> '$usernameold'
                AND username = '$username'
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('iduser', TRUE);

        $table = array(
            "password"      => encrypt_password($this->input->post('password', TRUE)),
        );
        $this->db->where('id_user', $id);
        $this->db->update('tm_user', $table);
    }
}

/* End of file Mmaster.php */
