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
}
/* End of file Mmaster.php */
