<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Muser extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        $datatables->query("SELECT
                id_user, 
                username,
                e_nama,
                b.e_level_name,
                CASE
                    WHEN a.f_allcustomer = 't' THEN 'Ya'
                    ELSE 'Tidak'
                END AS all_customer,
                a.f_status
            FROM
                tm_user a
            INNER JOIN tr_level b ON
                (b.i_level = a.i_level)
            ORDER BY e_nama ", FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_user'];
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


        $datatables->add('action', function ($data) {
            /** Cek Hak Akses, Apakah User Bisa Edit */
            $id         = trim($data['id_user']);
            $data       = '';
            $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
            
            if (check_role($this->id_menu, 3)) {
                return $data;
            }  
        });

              
        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tm_user');
        $this->db->where('id_user', $id);
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
        $this->db->where('id_user', $id);
        $this->db->update('tm_user', $table);
    }

    /** Ambil Data Customer */
    public function get_customer($cari="")
    {
        return $this->db->query("
            SELECT
                id_customer,
                e_customer_name
            FROM
                tr_customer
            WHERE
                (e_customer_name ILIKE '%$cari%')
                AND f_status = 't'
            ORDER BY
                e_customer_name ASC
        ", FALSE);
    }


    /** Ambil Data Detail Customer */
    public function get_detail_customer($i_customer)
    {
        return $this->db->query("
            SELECT
                e_customer_name,
                e_customer_address,
                e_customer_owner,
                b.e_type
            FROM
                tr_customer a
            INNER JOIN tr_type_customer b ON
                (b.i_type = a.i_type)
            WHERE a.id_customer = '$i_customer'
        ", FALSE);
    }

    /** Get Data Brand */
    public function get_brand($cari="")
    {
        return $this->db->query("
            SELECT 
                id_brand AS id,
                e_brand_name AS e_name
            FROM 
                tr_brand 
            WHERE 
                (e_brand_name ILIKE '%$cari%')
                AND f_status = 't'
            ORDER BY 2
        ", FALSE);
    }

    public function get_user_brand($id_user_customer) 
    {
        $sql = "SELECT tub.id, tb.*
                FROM tm_user_brand tub
                INNER JOIN tr_brand tb ON tb.id_brand = tub.id_brand
                WHERE id_user_customer = '$id_user_customer' AND tb.f_status = 't'";

        return $this->db->query($sql);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function cek($username)
    {
        return $this->db->query("
            SELECT 
                username
            FROM 
                tm_user 
            WHERE 
                trim(upper(username)) = trim(upper('$username'))
        ", FALSE);
    }

    public function save($params=[])
    {
        /** insert table user */
        $user = [
            "username" => strtolower($params['username']),
            "password" => encrypt_password($params['password']),
            "e_nama" => ucwords($params['ename']),
            "i_level" => $params['ilevel'],
            "f_allcustomer" => $params['fallcustomer'],
            "id_atasan" => $params['id_atasan']
        ];     

        $this->db->insert('tm_user', $user);
        $id_user = $this->db->insert_id();

        if ($params['fallcustomer']) {
            /** default semua brand */
            $all_brand = $this->get_brand();

            /** insert table user all customer & user_brand */            
            $all_customer = $this->get_customer();
            foreach ($all_customer->result() as $customer) {
                $user_customer = [
                    'id_user' => $id_user,
                    'id_customer' => $customer->id_customer
                ];
    
                $this->db->insert('tm_user_customer', $user_customer);
                $id_user_customer = $this->db->insert_id();
    
                foreach ($all_brand->result() as $brand) {
                    $brand = [
                        'id_user_customer' => $id_user_customer,
                        'id_brand' => $brand->id
                    ];
                    $this->db->insert('tm_user_brand', $brand);
                }
            }

            return;
        }

        /** insert table user_customer */
        foreach (@$params['i_customer'] as $customer) {
            $user_customer = [
                'id_user' => $id_user,
                'id_customer' => $customer['id']
            ];

            $this->db->insert('tm_user_customer', $user_customer);
            $id_user_customer = $this->db->insert_id();

            foreach (@$customer['i_brand'] as $brand) {
                $brand = [
                    'id_user_customer' => $id_user_customer,
                    'id_brand' => $brand
                ];
                $this->db->insert('tm_user_brand', $brand);
            }
        }
    }

    /** Simpan Data */
    // public function save()
    // {
    //     $query = $this->db->query("SELECT max(id_user)+1 AS id FROM tm_user", TRUE);
	// 	if ($query->num_rows() > 0) {
	// 		$id = $query->row()->id;
	// 		if ($id == null) {
	// 			$id = 1;
	// 		} else {
	// 			$id = $id;
	// 		}
	// 	} else {
	// 		$id = 1;
	// 	}

    //     $fallcustomer = ($this->input->post('fallcustomer', TRUE)=='on') ? true : false ;

    //     $table = array(
    //         "id_user"       => $id,
    //         "username"      => strtolower($this->input->post('username', TRUE)),
    //         "password"      => encrypt_password($this->input->post('password', TRUE)),
    //         "e_nama"        => ucwords($this->input->post('ename', TRUE)),
    //         "i_level"       => $this->input->post('ilevel', TRUE),
    //         "f_allcustomer" => $fallcustomer,
    //         "id_atasan" => $this->input->post('id_atasan', TRUE)
    //     );
    //     if ($this->db->insert('tm_user', $table)) {
    //         /*
    //         if (is_array($this->input->post('icompany[]', TRUE)) || is_object($this->input->post('icompany[]', TRUE))) {
    //             foreach ($this->input->post('icompany[]', TRUE) as $i_company) {
    //                 $tablecompany = array(
    //                     'id_user'   => $id,
    //                     'i_company' => $i_company,
    //                 );
    //                 $this->db->insert('tm_user_company', $tablecompany);
    //             };
    //         }
    //         */
    //         if (is_array($this->input->post('i_brand[]', TRUE)) || is_object($this->input->post('i_brand[]', TRUE))) {
    //             foreach ($this->input->post('i_brand[]', TRUE) as $id_brand) {
    //                 $tablecompany = array(
    //                     'id_user'  => $id,
    //                     'id_brand' => $id_brand,
    //                 );
    //                 $this->db->insert('tm_user_brand', $tablecompany);
    //             };
    //         }

    //         if ($fallcustomer==false){
    //             foreach ($this->input->post('i_customer[]') as $i_customer) {
    //                 $tablecustomer = array(
    //                     'id_user'       => $id,
    //                     'id_customer'   => $i_customer,
    //                 );
    //                 $this->db->insert('tm_user_customer', $tablecustomer);
    //             }
    //         }
    //     };
    // }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT
                *
            FROM
                tm_user
            WHERE 
                id_user = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        $sql = "SELECT
                    c.id_customer, 
                    e_customer_name,
                    e_customer_address,
                    e_customer_owner,
                    b.e_type
                FROM tr_customer a
                INNER JOIN tr_type_customer b ON b.i_type = a.i_type
                INNER JOIN tm_user_customer c ON c.id_customer = a.id_customer
                WHERE c.id_user = '$id'";

        return $this->db->query($sql, FALSE);
    }

    public function get_data_customer_with_brand($id)
    {
        $result = [];

        $detail = $this->getdatadetail($id);

        foreach ($detail->result() as $customer) {

            $all_user_customer = $this->get_user_customer($id, $customer->id_customer);

            foreach ($all_user_customer->result() as $user_customer) {

                $all_brand = $this->get_user_brand($user_customer->id);

                $result[] = [
                    'customer' => $customer,
                    'brand' => $all_brand->result()
                ];
            }            
        }

        return $result;
    }

    /** Get Data Company Edit */
    public function get_company($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.selek
            FROM
                tr_company a
            LEFT JOIN (
                SELECT
                    i_company,
                    'selected' AS selek
                FROM
                    tm_user_company
                WHERE
                    id_user = '$id'
            ) b ON
            (
                b.i_company = a.i_company
            )
        ", FALSE);
    }

    /** Get Data Company Edit */
    public function get_brand_data($id)
    {
        $sql = "SELECT a.*,
                    b.selek
                FROM tr_brand a
                LEFT JOIN (
                            SELECT id_brand, 'selected' AS selek
                            FROM tm_user_brand
                            WHERE id_user = '$id'
                        ) b ON b.id_brand = a.id_brand";

        return $this->db->query($sql, FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($username,$usernameold)
    {
        return $this->db->query("
            SELECT 
                username
            FROM 
                tm_user
            WHERE 
                username <> '$usernameold'
                AND username = '$username'
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('iduser', TRUE);
        $fallcustomer = ($this->input->post('fallcustomer', TRUE)=='on') ? true : false ;

        $table = array(
            "username"      => strtolower($this->input->post('username', TRUE)),
            "password"      => encrypt_password($this->input->post('password', TRUE)),
            "e_nama"        => ucwords($this->input->post('ename', TRUE)),
            "i_level"       => $this->input->post('ilevel', TRUE),
            "f_allcustomer" => $fallcustomer,
        );
        $this->db->where('id_user', $id);
        if ($this->db->update('tm_user', $table)) {
            $this->db->where('id_user', $id);
            $this->db->delete('tm_user_company');
            /*
            if (is_array($this->input->post('icompany[]', TRUE)) || is_object($this->input->post('icompany[]', TRUE))) {
                foreach ($this->input->post('icompany[]', TRUE) as $i_company) {
                    var_dump($i_company);
                    $tablecompany = array(
                        'id_user'   => $id,
                        'i_company' => $i_company,
                    );
                    $this->db->insert('tm_user_company', $tablecompany);
                };
            }
            */

            $this->db->where('id_user', $id);
            // $this->db->delete('tm_user_brand');
            // if (is_array($this->input->post('i_brand[]', TRUE)) || is_object($this->input->post('i_brand[]', TRUE))) {
            //     foreach ($this->input->post('i_brand[]', TRUE) as $id_brand) {
            //         $tablecompany = array(
            //             'id_user'  => $id,
            //             'id_brand' => $id_brand,
            //         );
            //         $this->db->insert('tm_user_brand', $tablecompany);
            //     };
            // }

            $this->db->where('id_user', $id);
            $this->db->delete('tm_user_customer');
            if ($fallcustomer==false){
                foreach ($this->input->post('i_customer[]') as $i_customer) {
                    $tablecustomer = array(
                        'id_user'       => $id,
                        'id_customer'   => $i_customer,
                    );
                    $this->db->insert('tm_user_customer', $tablecustomer);
                }
            }
        };
    }

    public function update_password($params=[])
    {
        $id_user = $params['id_user'];
        $data = [
            "password" => encrypt_password($params['password'])
        ];   
        
        $this->db->where('id_user', $id_user);
        $this->db->update('tm_user', $data);
    }

    public function update2($params=[])
    {
        $id_user = $params['id_user'];
        /** update table user */
        $user = [
            "username" => strtolower($params['username']),
            "password" => encrypt_password($params['password']),
            "e_nama" => ucwords($params['ename']),
            "i_level" => $params['ilevel'],
            "f_allcustomer" => $params['fallcustomer'],
        ];   

        if (@$params['id_atasan'] != null){
            $user['id_atasan'] = $params['id_atasan'];
        }
        
        $this->db->where('id_user', $id_user);
        $this->db->update('tm_user', $user);

        /** recreate user customer & user brand */
        $all_user_customer = $this->get_user_customer($id_user);
        foreach ($all_user_customer->result() as $user_customer) {
            /** hapus user brand */
            $this->db->where('id_user_customer', $user_customer->id);
            $this->db->delete('tm_user_brand');

            /** hapus user customer */
            $this->db->where('id', $user_customer->id);
            $this->db->delete('tm_user_customer');
        }

        /** create user customer & user brand */
        if ($params['fallcustomer']) {
            /** default semua brand */
            $all_brand = $this->get_brand();

            /** insert table user all customer & user_brand */            
            $all_customer = $this->get_customer();
            foreach ($all_customer->result() as $customer) {
                $user_customer = [
                    'id_user' => $id_user,
                    'id_customer' => $customer->id_customer
                ];
    
                $this->db->insert('tm_user_customer', $user_customer);
                $id_user_customer = $this->db->insert_id();
    
                foreach ($all_brand->result() as $brand) {
                    $brand = [
                        'id_user_customer' => $id_user_customer,
                        'id_brand' => $brand->id
                    ];
                    $this->db->insert('tm_user_brand', $brand);
                }
            }

            return;
        }

        /** insert table user_customer */
        foreach (@$params['i_customer'] as $customer) {
            $user_customer = [
                'id_user' => $id_user,
                'id_customer' => $customer['id']
            ];

            $this->db->insert('tm_user_customer', $user_customer);
            $id_user_customer = $this->db->insert_id();

            foreach (@$customer['i_brand'] as $brand) {
                $brand = [
                    'id_user_customer' => $id_user_customer,
                    'id_brand' => $brand
                ];
                $this->db->insert('tm_user_brand', $brand);
            }
        }



        
    }

    public function get_list_team_leader($params=[])
    {
        $like = '';

        if (@$params['keyword'] != null) {
            $like = " AND e_nama ILIKE '%$like%'";
        }

        $TEAM_LEADER = 5;

        $sql = "SELECT * 
                FROM tm_user 
                WHERE i_level = '$TEAM_LEADER' AND f_status = 't' $like";        

        return $this->db->query($sql);
    }

    public function get_user_customer($id_user, $id_customer=null) 
    {
        $where = ['id_user' => $id_user];

        if ($id_customer != null) {
            $where = ['id_user' => $id_user, 'id_customer' => $id_customer];
        }

        $this->db->select()
            ->from('tm_user_customer')
            ->where($where);

        return $this->db->get();

    }
}

/* End of file Mmaster.php */
