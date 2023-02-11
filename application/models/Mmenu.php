<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mmenu extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT 0 AS no, id_menu,  e_menu, i_parent, e_folder, icon FROM tr_menu ORDER BY n_urut", FALSE);

        /** Cek Hak Akses, Apakah User Bisa Edit */
        if (check_role($this->id_menu, 3)) {
            $datatables->add('action', function ($data) {
                $id         = trim($data['id_menu']);
                $data       = '';
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                return $data;
            });
        }        
        return $datatables->generate();
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function get_menu($cari)
    {
        return $this->db->query("
            SELECT 
                id_menu,
                e_menu
            FROM 
                tr_menu 
            WHERE 
                (e_menu ILIKE '%$cari%')
            ORDER BY id_menu
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($id)
    {
        return $this->db->query("
            SELECT 
                id_menu
            FROM 
                tr_menu 
            WHERE 
                id_menu = $id
        ", FALSE);
    }

    /** Simpan Data */
    public function save($iparent,$idmenu,$emenu,$nurut,$efolder,$icon,$ipower)
    {
        $table = array(
            'id_menu'   => $idmenu,
            'e_menu'    => $emenu,
            'i_parent'  => $iparent,
            'n_urut'    => $nurut,
            'e_folder'  => $efolder,
            'icon'      => $icon,
        );
        if($this->db->insert('tr_menu', $table)){
            if ($ipower) {
                foreach ($ipower as $power) {
                    $data = array(
                        'id_menu'   => $idmenu,
                        'i_power'   => $power,
                        'i_level'   => 1,
                    );
                    $this->db->insert('tm_user_role', $data);
                }
            }
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                a.*,
                b.e_menu AS menu_parent
            FROM 
                tr_menu a
            LEFT JOIN tr_menu b ON (b.id_menu = a.i_parent)
            WHERE
                a.id_menu = '$id'
        ", FALSE);
    }

    /** Get Data Power Edit */
    public function get_power($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.selek
            FROM
                tr_user_power a
            LEFT JOIN (
                    SELECT
                        i_power,
                        'selected' AS selek
                    FROM
                        tm_user_role
                    WHERE
                        id_menu = '$id'
                        AND i_level = '1'
                ) b ON
                (
                    b.i_power = a.i_power
                )
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($idmenu,$idmenuold)
    {
        return $this->db->query("
            SELECT 
                id_menu
            FROM 
                tr_menu 
            WHERE 
                id_menu <> $idmenuold
                AND id_menu = $idmenu
        ", FALSE);
    }

    /** Update Data */
    public function update($iparent,$idmenu,$emenu,$nurut,$efolder,$icon,$idmenuold,$ipower)
    {
        $table = array(
            'id_menu'   => $idmenu,
            'e_menu'    => $emenu,
            'i_parent'  => $iparent,
            'n_urut'    => $nurut,
            'e_folder'  => $efolder,
            'icon'      => $icon,
        );
        $this->db->where('id_menu', $idmenuold);
        if($this->db->update('tr_menu', $table)){
            $this->db->where('id_menu', $idmenuold);
            $this->db->where('i_level', 1);
            $this->db->delete('tm_user_role');
            if ($ipower) {
                foreach ($ipower as $power) {
                    $data = array(
                        'id_menu'   => $idmenu,
                        'i_power'   => $power,
                        'i_level'   => 1,
                    );
                    $this->db->insert('tm_user_role', $data);
                }
            }
        };
    }
}

/* End of file Mmaster.php */
