<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mlevel extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT i_level,  e_level_name, e_deskripsi, f_status FROM tr_level ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['i_level'];
            if ($data['f_status']=='t') {
                $status = 'Active';
                $color  = 'success';
            }else{
                $status = 'Not Active';
                $color  = 'danger';
            }
            $data = "<button class='btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple' onclick='changestatus(\"".$this->folder."\",\"".$id."\");'>".$status."</button>";
            return $data;
        });

        /** Cek Hak Akses, Apakah User Bisa Edit */
        if (check_role($this->id_menu, 3)) {
            $datatables->add('action', function ($data) {
                $id         = trim($data['i_level']);
                $data       = '';
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                return $data;
            });
        }        
        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tr_level');
        $this->db->where('i_level', $id);
        $query = $this->db->get();
        if ($query->num_rows()>0) {
            $status = $query->row()->f_status;
        }else{
            $status = 'f';
        }
        if ($status=='f') {
            $fstatus = 't';
        }else{
            $fstatus = 'f';
        }
        $table = array(
            'f_status' => $fstatus, 
        );
        $this->db->where('i_level', $id);
        $this->db->update('tr_level', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($elevel)
    {
        return $this->db->query("
            SELECT 
                e_level_name
            FROM 
                tr_level 
            WHERE 
                trim(upper(e_level_name)) = trim(upper('$elevel'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($elevel,$deskripsi)
    {
        $table = array(
            'e_level_name' => $elevel, 
            'e_deskripsi'  => $deskripsi, 
        );
        $this->db->insert('tr_level', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_level 
            WHERE
                i_level = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($elevel,$elevelold)
    {
        return $this->db->query("
            SELECT 
                e_level_name
            FROM 
                tr_level 
            WHERE 
                trim(upper(e_level_name)) <> trim(upper('$elevelold'))
                AND trim(upper(e_level_name)) = trim(upper('$elevel'))
        ", FALSE);
    }

    /** Update Data */
    public function update($ilevel,$elevel,$deskripsi)
    {
        $table = array(
            'e_level_name' => $elevel, 
            'e_deskripsi'  => $deskripsi, 
        );
        $this->db->where('i_level', $ilevel);
        $this->db->update('tr_level', $table);
    }
}

/* End of file Mmaster.php */
