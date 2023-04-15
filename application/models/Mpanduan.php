<?php
defined('BASEPATH') or exit('No direct script access allowed');

use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mpanduan extends CI_Model
{

    /** List Data */
    public function getdata()
    {
        return $this->db->get_where('tr_panduan', ['f_status' => 't']);
    }

    /** Delete File */
    public function deletefile($id, $attachment, $path)
    {
        /** Delete File Panduan Manual */
        $this->db->where('id', $id);
        $this->db->delete('tr_panduan');
        unlink($path . $attachment);
    }

    public function get_cover_panduan()
    {
        $id_user = $this->session->userdata("id_user");

        $sql = "SELECT	DISTINCT a.*, p.*
                        FROM tr_menu a
                        INNER JOIN tm_user_role b ON a.id_menu = b.id_menu
                        INNER JOIN tm_user c ON c.i_level = b.i_level
                        INNER JOIN tr_panduan p ON p.id = a.id_panduan 
                        WHERE c.id_user = '$id_user'
                            AND a.f_status = 't'
                            AND p.f_status = 't'
                        ORDER BY id_panduan ASC ";

        return $this->db->query($sql);
    }
}
/* End of file Mmaster.php */
