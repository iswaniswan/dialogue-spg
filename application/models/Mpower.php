<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpower extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT i_power,  e_power_name FROM tr_user_power ", FALSE);

        /** Cek Hak Akses, Apakah User Bisa Edit */
        if (check_role($this->id_menu, 3)) {
            $datatables->add('action', function ($data) {
                $id         = trim($data['i_power']);
                $data       = '';
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                return $data;
            });
        }        
        return $datatables->generate();
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($epower)
    {
        return $this->db->query("
            SELECT 
                e_power_name
            FROM 
                tr_user_power 
            WHERE 
                trim(upper(e_power_name)) = trim(upper('$epower'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($epower)
    {
        $table = array(
            'e_power_name' => $epower, 
        );
        $this->db->insert('tr_user_power', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_user_power 
            WHERE
                i_power = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($epower,$epowerold)
    {
        return $this->db->query("
            SELECT 
                e_power_name
            FROM 
                tr_user_power 
            WHERE 
                trim(upper(e_power_name)) <> trim(upper('$epowerold'))
                AND trim(upper(e_power_name)) = trim(upper('$epower'))
        ", FALSE);
    }

    /** Update Data */
    public function update($ipower,$epower)
    {
        $table = array(
            'e_power_name' => $epower, 
        );
        $this->db->where('i_power', $ipower);
        $this->db->update('tr_user_power', $table);
    }
}

/* End of file Mmaster.php */
