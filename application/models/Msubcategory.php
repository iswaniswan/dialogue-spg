<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Msubcategory extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT sc.id, c.e_category_name, sc.e_sub_category_name, sc.f_status 
                FROM tm_sub_category sc
                INNER JOIN tm_category c ON c.id = sc.id_category";

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id'];
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
                $id         = trim($data['id']);
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
        $this->db->from('tm_sub_category');
        $this->db->where('id', $id);
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
        $this->db->where('id', $id);
        $this->db->update('tm_sub_category', $table);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($ebrand)
    {
        return $this->db->query("
            SELECT 
                e_sub_category_name
            FROM 
                tm_sub_category 
            WHERE 
                trim(upper(e_sub_category_name)) = trim(upper('$ebrand'))
        ", FALSE);
    }

    /** Simpan Data */
    public function save($id_category, $e_sub_category_name)
    {
        $table = [
            'id_category' => $id_category,
            'e_sub_category_name' => $e_sub_category_name, 
        ];
        $this->db->insert('tm_sub_category', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        $sql = "SELECT sc.*, c.e_category_name
                FROM tm_sub_category sc
                INNER JOIN tm_category c ON c.id = sc.id_category
                WHERE sc.id = '$id'";

        return $this->db->query($sql, FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($ebrand,$ebrandold)
    {
        return $this->db->query("
            SELECT 
                e_sub_category_name
            FROM 
                tm_sub_category 
            WHERE 
                trim(upper(e_sub_category_name)) <> trim(upper('$ebrandold'))
                AND trim(upper(e_sub_category_name)) = trim(upper('$ebrand'))
        ", FALSE);
    }

    /** Update Data */
    public function update($id_category, $e_sub_category_name, $id)
    {
        $table = array(
            'id_category' => $id_category,
            'e_sub_category_name' => $e_sub_category_name, 
        );
        $this->db->where('id', $id);
        $this->db->update('tm_sub_category', $table);
    }

    public function delete_all()
	{
		$sql = "TRUNCATE TABLE tm_sub_category CASCADE";

		return $this->db->query($sql);
	}

    public function get_category($cari='')
    {
        $limit = " LIMIT 5";
        if ($cari != '') {
            $limit = '';
        }
        
        $sql = "SELECT
                    id,
                    e_category_name 
                FROM tm_category
                WHERE (e_category_name ILIKE '%$cari%')
                    AND f_status = 't'
                ORDER BY e_category_name ASC
                $limit ";

        return $this->db->query($sql, FALSE);
    }

    public function get_sub_category($id_category, $cari='')
    {
        $limit = " LIMIT 5";
        if ($cari != '') {
            $limit = '';
        }
        
        $sql = "SELECT id, e_sub_category_name 
                FROM tm_sub_category
                WHERE id_category = '$id_category' 
                    AND f_status = 't'
                    AND e_sub_category_name ILIKE '%$cari%'
                ORDER BY e_sub_category_name ASC
                $limit ";

        return $this->db->query($sql, FALSE);
    }
}

/* End of file Mmaster.php */
