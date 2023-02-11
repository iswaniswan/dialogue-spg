<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mcustomer extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $id_user = $this->session->userdata('id_user');

        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT
                    0 AS NO,
                    a.id_customer,
                    e_customer_name,
                    e_customer_address,
                    b.e_type,
                    e_customer_owner,
                    e_customer_phone,
                    CASE
                        WHEN f_pkp = 't' THEN 'PKP'
                        ELSE 'Non-PKP'
                    END AS pkp,
                    a.f_status
                FROM tr_customer a
                INNER JOIN tr_type_customer b ON b.i_type = a.i_type
                INNER JOIN tm_user_customer tuc ON tuc.id_user = '$id_user' AND tuc.id_customer = a.id_customer
                WHERE tuc.id_user = '$id_user'
                ORDER BY e_customer_name";         

        $datatables->query($sql, FALSE);

        $datatables->edit('f_status', function ($data) {
            $id         = $data['id_customer'];
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
      
        $datatables->add('action', function ($data) {
            $id         = trim($data['id_customer']);
            $data       = '';

            if (check_role($this->id_menu, 2)) {
                $data      .= "<a href='" . base_url() . $this->folder . '/view/' . encrypt_url($id) . "' title='Lihat Data'><i class='icon-database-check text-success-800'></i></a>";
            }


            if (check_role($this->id_menu, 3)) {
                $data      .= "<a href='".base_url().$this->folder.'/edit/'.encrypt_url($id)."' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
            }

            return $data;
        });

        /** hide column */
        $datatables->hide('id_customer');
  

        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tr_customer');
        $this->db->where('id_customer', $id);
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
        $this->db->where('id_customer', $id);
        $this->db->update('tr_customer', $table);
    }

    /** Ambil Data Perusahaan */
    public function get_company($cari)
    {
        return $this->db->query("SELECT * FROM tr_company WHERE f_status = 't' AND e_company_name ILIKE '%$cari%' ", FALSE);
    }

    /** Ambil Data Customer */
    public function get_customer($id,$cari)
    {
        $this->db->select('*');
        $this->db->from('tr_company');
        $this->db->where('i_company',$id);
        $query      = $this->db->get()->row();
        $Url        = $query->db_address;
        $User       = $query->db_user;
        $Password   = $query->db_password;
        $DbName     = $query->db_name;
        $Port       = $query->db_port;
        $Jenis      = $query->jenis_company;
        if ($Jenis=='produksi') {
            $dbexternalna = "
                SELECT
                    DISTINCT 
                    c.i_customer,
                    '( '|| c.i_customer_code ||' ) - '|| c.e_customer_name AS e_customer_name,
                    a.i_code AS i_area,
                    b.n_customer_discount1 AS v_discount1,
                    b.n_customer_discount2 AS v_discount2,
                    b.n_customer_discount3 AS v_discount3
                FROM
                    tr_branch a
                INNER JOIN tr_customer c ON
                    (c.i_customer = a.i_customer)
                INNER JOIN tr_customer_discount b ON
                    (b.i_customer = c.i_customer)
                WHERE
                    LENGTH(a.i_code) <= 2
                ORDER BY
                    2";
        }else{
            $dbexternalna = "
                SELECT
                    DISTINCT 
                    a.i_customer,
                    '( ' || a.i_customer || ' ) - ' || a.e_customer_name AS e_customer_name,
                    a.i_area,
                    b.n_customer_discount1 AS v_discount1,
                    b.n_customer_discount2 AS v_discount2,
                    b.n_customer_discount3 AS v_discount3
                FROM
                    tr_customer a
                INNER JOIN tr_customer_discount b ON
                    (b.i_customer = a.i_customer)
                ORDER BY 2
            ";
        }
        return $this->db->query("
            SELECT
                DISTINCT x.i_customer,
                x.e_customer_name,
                x.i_area,
                x.v_discount1,
                x.v_discount2,
                x.v_discount3
            FROM
                (
                SELECT
                    *
                FROM
                    dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                    $$ $dbexternalna $$) AS get_op ( i_customer CHARACTER VARYING(6),
                    e_customer_name CHARACTER VARYING(250),
                    i_area CHARACTER VARYING(2),
                    v_discount1 NUMERIC (12, 2),
                    v_discount2 NUMERIC (12, 2),
                    v_discount3 NUMERIC (12, 2) ) ) x
            WHERE
                (x.i_customer ILIKE '%$cari%' OR x.e_customer_name ILIKE '%$cari%')
            ORDER BY
                x.e_customer_name,
                x.i_customer ASC
        ", FALSE);
    }


    /** Ambil Data Detail Customer */
    public function get_detail_customer($i_customer,$i_company)
    {
        $this->db->select('*');
        $this->db->from('tr_company');
        $this->db->where('i_company',$i_company);
        $query      = $this->db->get()->row();
        $Url        = $query->db_address;
        $User       = $query->db_user;
        $Password   = $query->db_password;
        $DbName     = $query->db_name;
        $Port       = $query->db_port;
        $Jenis      = $query->jenis_company;
        if ($Jenis=='produksi') {
            $dbexternalna = "
                SELECT
                    DISTINCT 
                    c.i_customer,
                    '( '|| c.i_customer_code ||' ) - '|| c.e_customer_name AS e_customer_name,
                    a.i_code AS i_area,
                    b.n_customer_discount1 AS v_discount1,
                    b.n_customer_discount2 AS v_discount2,
                    b.n_customer_discount3 AS v_discount3
                FROM
                    tr_branch a
                INNER JOIN tr_customer c ON
                    (c.i_customer = a.i_customer)
                INNER JOIN tr_customer_discount b ON
                    (b.i_customer = c.i_customer)
                WHERE
                    LENGTH(a.i_code) <= 2
                    AND c.i_customer = '$i_customer'
                ORDER BY
                    2";
        }else{
            $dbexternalna = "
                SELECT
                    DISTINCT 
                    a.i_customer,
                    '( ' || a.i_customer || ' ) - ' || a.e_customer_name AS e_customer_name,
                    a.i_area,
                    b.n_customer_discount1 AS v_discount1,
                    b.n_customer_discount2 AS v_discount2,
                    b.n_customer_discount3 AS v_discount3
                FROM
                    tr_customer a
                INNER JOIN tr_customer_discount b ON
                    (b.i_customer = a.i_customer)
                WHERE 
                    a.i_customer = '$i_customer'
                ORDER BY 2
            ";
        }
        return $this->db->query("
            SELECT
                DISTINCT x.i_customer,
                x.e_customer_name,
                x.i_area,
                x.v_discount1,
                x.v_discount2,
                x.v_discount3
            FROM
                (
                SELECT
                    *
                FROM
                    dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                    $$ $dbexternalna $$) AS get_op ( i_customer CHARACTER VARYING(6),
                    e_customer_name CHARACTER VARYING(250),
                    i_area CHARACTER VARYING(2),
                    v_discount1 NUMERIC (4, 2),
                    v_discount2 NUMERIC (4, 2),
                    v_discount3 NUMERIC (4, 2) ) ) x
            ORDER BY
                x.e_customer_name,
                x.i_customer ASC
        ", FALSE);
    }

    /** Simpan Data */
    public function save($itype,$fpkp,$ecustomer,$ecustomernpwp,$eaddress,$eaddressnpwp,$eowner,$ephone)
    {
        $query = $this->db->query("SELECT max(id_customer)+1 AS id FROM tr_customer", TRUE);
		if ($query->num_rows() > 0) {
			$id = $query->row()->id;
			if ($id == null) {
				$id = 1;
			} else {
				$id = $id;
			}
		} else {
			$id = 1;
		}

        $table = array(
            'id_customer'        => $id,
            'e_customer_name'    => $ecustomer,
            'e_customer_address' => $eaddress,
            'i_type'             => $itype,
            'e_customer_owner'   => $eowner,
            'e_customer_phone'   => $ephone,
            'f_pkp'              => $fpkp,
            'e_npwp_name'        => $ecustomernpwp,
            'e_npwp_address'     => $eaddressnpwp,
        );
        if ($this->db->insert('tr_customer', $table)) {
            $x = 0;
            if ($this->input->post('i_company[]')) {
                foreach ($this->input->post('i_company[]') as $i_company) {
                    $data = array(
                        'id_customer'       => $id,
                        'i_company'         => $i_company,
                        'i_customer'        => $this->input->post('i_customer[]')[$x],
                        'i_area'            => $this->input->post('i_area[]')[$x],
                        'n_diskon1'         => $this->input->post('v_discount1[]')[$x],
                        'n_diskon2'         => $this->input->post('v_discount2[]')[$x],
                        'n_diskon3'         => $this->input->post('v_discount3[]')[$x],
                        'e_customer_name'   => $this->input->post('e_customer[]')[$x],
                    );
                    $this->db->insert('tr_customer_item', $data);
                    $x++;
                }
            }   
        };
    }

    /** Get Data Untuk Edit */
    public function getdata($id)
    {
        return $this->db->query("
            SELECT
                *
            FROM
                tr_customer
            WHERE 
                id_customer = '$id'
        ", FALSE);
    }

    /** Get Data Untuk Edit */
    public function getdatadetail($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.e_company_name
            FROM
                tr_customer_item a
            INNER JOIN tr_company b ON 
                (b.i_company = a.i_company)
            WHERE 
                id_customer = '$id'
        ", FALSE);
    }

    public function get_data_brand($id_customer)
    {
        $id_user = $this->session->userdata('id_user');

        $user_customer = $this->get_user_customer($id_user, $id_customer);

        $id_user_customer = $user_customer->row()->id;

        $sql = "SELECT tub.id, tb.*
                FROM tm_user_brand tub
                INNER JOIN tr_brand tb ON tb.id_brand = tub.id_brand
                WHERE id_user_customer = '$id_user_customer' AND tb.f_status = 't'";

        return $this->db->query($sql);
    }

    /** Get Data Power Edit */
    public function get_power($id)
    {
        return $this->db->query("
            SELECT
                a.*,
                b.selek
            FROM
                tr_user_power a
            LEFT JOIN (
                    SELECT
                        i_power,
                        'selected' AS selek
                    FROM
                        tm_user_role
                    WHERE
                        id_menu = '$id'
                        AND i_level = '1'
                ) b ON
                (
                    b.i_power = a.i_power
                )
        ", FALSE);
    }

    /** Update Data */
    public function update($itype,$fpkp,$ecustomer,$ecustomernpwp,$eaddress,$eaddressnpwp,$eowner,$ephone,$idcustomer)
    {
        $table = array(
            'e_customer_name'    => $ecustomer,
            'e_customer_address' => $eaddress,
            'i_type'             => $itype,
            'e_customer_owner'   => $eowner,
            'e_customer_phone'   => $ephone,
            'f_pkp'              => $fpkp,
            'e_npwp_name'        => $ecustomernpwp,
            'e_npwp_address'     => $eaddressnpwp,
        );
        $this->db->where('id_customer', $idcustomer);
        if ($this->db->update('tr_customer', $table)) {
            $x = 0;
            $this->db->where('id_customer', $idcustomer);
            $this->db->delete('tr_customer_item');
            if ($this->input->post('i_company[]')) {
                foreach ($this->input->post('i_company[]') as $i_company) {
                    $data = array(
                        'id_customer'       => $idcustomer,
                        'i_company'         => $i_company,
                        'i_customer'        => $this->input->post('i_customer[]')[$x],
                        'i_area'            => $this->input->post('i_area[]')[$x],
                        'n_diskon1'         => $this->input->post('v_discount1[]')[$x],
                        'n_diskon2'         => $this->input->post('v_discount2[]')[$x],
                        'n_diskon3'         => $this->input->post('v_discount3[]')[$x],
                        'e_customer_name'   => $this->input->post('e_customer[]')[$x],
                    );
                    $this->db->insert('tr_customer_item', $data);
                    $x++;
                }
            }
        };
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
