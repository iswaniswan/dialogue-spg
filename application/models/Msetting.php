<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Msetting extends CI_Model {

    public function serverside()
    {
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("            
        SELECT
            i_level,
            e_level_name,
            f_status,
            e_deskripsi 
        FROM
            tr_level
        WHERE i_level <> '1'
        ", false);

        
        $datatables->edit('f_status', function ($data) {
            if ($data['f_status']=='t') {
                $status = 'Active';
                $color  = 'success-800';
            }else{
                $status = 'Not Active';
                $color  = 'danger-800';
            }
            $data = '<span class="badge bg-'.$color.'">'.$status.'</span>';
            return $data;
        });
        $datatables->add('action', function ($data) {
            $id         = trim($data['i_level']);
            $data       = '';
            $data      .= "<a href='".base_url().$this->folder.'/view/'.encrypt_url($id)."' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            $data      .= "<a href='".base_url().$this->folder.'/update/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 ml-2 text-".$this->color."-800'></i></a>";
            return $data;
        });
        return $datatables->generate();
    }

    public function cek_data($id)
    {
        return $this->db->query("                                    
            SELECT 
                z.id_menu,
                z.e_menu,
                z.id as idadmin,
                a.id
            FROM(
                SELECT 
                    a.id_menu, 
                    a.e_menu,
                    string_agg(b.i_power::varchar,',') AS id
                FROM 
                    tr_menu a
                JOIN 
                    tm_user_role b 
                    ON a.id_menu = b.id_menu
                JOIN tr_level c 
                    ON b.i_level = c.i_level
                JOIN tr_user_power d
                    ON b.i_power = d.i_power  
                WHERE 
                    b.i_level ='1'
                GROUP BY 
                    a.id_menu, a.e_menu, c.i_level
                ORDER BY a.n_urut
                ) AS z
            LEFT JOIN
                (
                SELECT 
                    a.id_menu, 
                    a.e_menu,
                    string_agg(b.i_power::varchar,',')as id
                FROM 
                    tr_menu a
                JOIN 
                    tm_user_role b 
                    ON a.id_menu = b.id_menu
                JOIN tr_level c 
                    ON b.i_level = c.i_level
                JOIN tr_user_power d
                    ON b.i_power = d.i_power  
                WHERE 
                    b.i_level ='$id'
                GROUP BY 
                    a.id_menu, a.e_menu, c.i_level
                ORDER BY a.n_urut
                ) AS a ON (z.id_menu = a.id_menu)
            ORDER BY z.id_menu::varchar ASC
        ", FALSE);
    }

    public function userpower()
    {
        return $this->db->query("
            SELECT
                i_power as id, 
                e_power_name as e_name
            FROM
                tr_user_power
            ORDER BY 
                i_power ASC
        ", FALSE);
    }

    public function cek_level($id)
    {
        return $this->db->query("
            SELECT
                e_level_name 
            FROM
                tr_level
            WHERE
                i_level = '$id'
        ", FALSE);
    }

    public function insertdetail($menu,$ipower,$ilevel)
    {
        $this->db->query("
            INSERT
                INTO
                tm_user_role (id_menu, i_power, i_level)
            VALUES ('$menu', '$ipower', '$ilevel') 
            ON
                CONFLICT (id_menu, i_power, i_level) DO
            UPDATE
                SET
                    id_menu = excluded.id_menu,
                    i_power = excluded.i_power,
                    i_level = excluded.i_level
        ", FALSE);
    }

    public function deletedetail($menu,$ipower,$ilevel)
    {
        $this->db->query("
            DELETE 
                FROM tm_user_role
                WHERE id_menu = '$menu'
                AND i_level = '$ilevel'
                AND i_power = '$ipower';
        ", FALSE);
    }
}

/* End of file Mmaster.php */
