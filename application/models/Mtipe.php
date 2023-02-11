<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mtipe extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT i_type,  e_type, f_status FROM tr_type_customer ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['i_type'];
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
                $id         = trim($data['i_type']);
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
        $this->db->from('tr_type_customer');
        $this->db->where('i_type', $id);
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
        $this->db->where('i_type', $id);
        $this->db->update('tr_type_customer', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($etype)
    {
        return $this->db->query("
            SELECT 
                e_type
            FROM 
                tr_type_customer 
            WHERE 
                trim(upper(e_type)) = trim(upper('$etype'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($etype)
    {
        $table = array(
            'e_type' => $etype, 
        );
        $this->db->insert('tr_type_customer', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_type_customer 
            WHERE
                i_type = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($etype,$etypeold)
    {
        return $this->db->query("
            SELECT 
                e_type
            FROM 
                tr_type_customer 
            WHERE 
                trim(upper(e_type)) <> trim(upper('$etypeold'))
                AND trim(upper(e_type)) = trim(upper('$etype'))
        ", FALSE);
    }

    /** Update Data */
    public function update($itype,$etype)
    {
        $table = array(
            'e_type' => $etype, 
        );
        $this->db->where('i_type', $itype);
        $this->db->update('tr_type_customer', $table);
    }
}

/* End of file Mmaster.php */
