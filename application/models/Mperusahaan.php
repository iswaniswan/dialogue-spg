<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mperusahaan extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT i_company,  e_company_name, f_status FROM tr_company ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['i_company'];
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
                $id         = trim($data['i_company']);
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
        $this->db->from('tr_company');
        $this->db->where('i_company', $id);
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
        $this->db->where('i_company', $id);
        $this->db->update('tr_company', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($ecompany)
    {
        return $this->db->query("
            SELECT 
                e_company_name
            FROM 
                tr_company 
            WHERE 
                trim(upper(e_company_name)) = trim(upper('$ecompany'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($ecompany)
    {
        $table = array(
            'e_company_name' => $ecompany, 
        );
        $this->db->insert('tr_company', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_company 
            WHERE
                i_company = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($ecompany,$ecompanyold)
    {
        return $this->db->query("
            SELECT 
                e_company_name
            FROM 
                tr_company 
            WHERE 
                trim(upper(e_company_name)) <> trim(upper('$ecompanyold'))
                AND trim(upper(e_company_name)) = trim(upper('$ecompany'))
        ", FALSE);
    }

    /** Update Data */
    public function update($icompany,$ecompany)
    {
        $table = array(
            'e_company_name' => $ecompany, 
        );
        $this->db->where('i_company', $icompany);
        $this->db->update('tr_company', $table);
    }
}

/* End of file Mmaster.php */
