<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mbrand extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT id_brand,  e_brand_name, f_status FROM tr_brand ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_brand'];
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
                $id         = trim($data['id_brand']);
                $data       = '';
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
                return $data;
            });
        } else {
            $datatables->add('action', function ($data) {
                $data       = '';
                return $data;
            });
        }          
        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tr_brand');
        $this->db->where('id_brand', $id);
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
        $this->db->where('id_brand', $id);
        $this->db->update('tr_brand', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($ebrand)
    {
        return $this->db->query("
            SELECT 
                e_brand_name
            FROM 
                tr_brand 
            WHERE 
                trim(upper(e_brand_name)) = trim(upper('$ebrand'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($ebrand)
    {
        $table = array(
            'e_brand_name' => $ebrand, 
        );
        $this->db->insert('tr_brand', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_brand 
            WHERE
                id_brand = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($ebrand,$ebrandold)
    {
        return $this->db->query("
            SELECT 
                e_brand_name
            FROM 
                tr_brand 
            WHERE 
                trim(upper(e_brand_name)) <> trim(upper('$ebrandold'))
                AND trim(upper(e_brand_name)) = trim(upper('$ebrand'))
        ", FALSE);
    }

    /** Update Data */
    public function update($ibrand,$ebrand)
    {
        $table = array(
            'e_brand_name' => $ebrand, 
        );
        $this->db->where('id_brand', $ibrand);
        $this->db->update('tr_brand', $table);
    }
}

/* End of file Mmaster.php */
