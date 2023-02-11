<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Malasan extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT i_alasan,  e_alasan, f_status FROM tr_alasan_retur ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['i_alasan'];
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
                $id         = trim($data['i_alasan']);
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
        $this->db->from('tr_alasan_retur');
        $this->db->where('i_alasan', $id);
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
        $this->db->where('i_alasan', $id);
        $this->db->update('tr_alasan_retur', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($ealasan)
    {
        return $this->db->query("
            SELECT 
                e_alasan
            FROM 
                tr_alasan_retur 
            WHERE 
                trim(upper(e_alasan)) = trim(upper('$ealasan'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($ealasan)
    {
        $table = array(
            'e_alasan' => $ealasan, 
        );
        $this->db->insert('tr_alasan_retur', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT 
                *
            FROM 
                tr_alasan_retur 
            WHERE
                i_alasan = '$id'
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($ealasan,$ealasanold)
    {
        return $this->db->query("
            SELECT 
                e_alasan
            FROM 
                tr_alasan_retur 
            WHERE 
                trim(upper(e_alasan)) <> trim(upper('$ealasanold'))
                AND trim(upper(e_alasan)) = trim(upper('$ealasan'))
        ", FALSE);
    }

    /** Update Data */
    public function update($ialasan,$ealasan)
    {
        $table = array(
            'e_alasan' => $ealasan, 
        );
        $this->db->where('i_alasan', $ialasan);
        $this->db->update('tr_alasan_retur', $table);
    }
}

/* End of file Mmaster.php */
