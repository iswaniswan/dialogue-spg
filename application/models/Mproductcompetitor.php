<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mproductcompetitor extends CI_Model {

    /** List Datatable */
    public function serverside(){
        // if ($this->i_company=='1') {
        //     $where = "";
        // }else{
        //     $where = "
        //         WHERE a.i_company = '$this->i_company'
        //     ";
        // }
        $datatables = new Datatables(new CodeigniterAdapter);

        $sql = "SELECT a.id, 
                    initcap(b.e_product_name) AS e_product_name,
                    initcap(c.e_brand_name) AS e_brand_name,
                    a.f_status,
                    a.v_price,
                    CASE 
                        WHEN a.d_update ISNULL THEN to_char(a.d_entry, 'dd-mm-yyyy HH12:MI:SS') 
                        ELSE to_char(a.d_update, 'dd-mm-yyyy HH12:MI:SS') 
                    END AS d_update
                FROM tm_product_competitor a
                INNER JOIN tr_product b on b.id = a.id_product
                left JOIN tr_brand c ON c.id_brand = a.id_brand
                ORDER BY b.e_product_name ASC";

        $datatables->query($sql, FALSE);

        $datatables->edit('v_price', function ($data) {
            $prefix = 'Rp. ';
            return $prefix . number_format($data['v_price'], 2, ".", ",");
        });

        $datatables->edit('f_status', function ($data) {
            $id = $data['id'];
            $status = 'Not Active';
            $color  = 'danger';

            if ($data['f_status']=='t') {
                $status = 'Active';
                $color  = 'success';
            }

            $class = "btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple";
            $onclick = "changestatus(\"".$this->folder."\",\"".$id."\");";
            $data = "<button class='$class' onclick='$onclick'>".$status."</button>";
            return $data;
        });

        $datatables->add('action', function ($data) {
            $id = trim($data['id']);            
            $link =  base_url().$this->folder.'/edit/'.encrypt_url($id);
            $data = "<a href='$link' title='Edit Data'><i class='icon-database-edit2 text-".$this->color."-800'></i></a>";
            return $data;
        });

        $datatables->hide('f_status');

        return $datatables->generate();
    }

    public function changestatus($id)
    {
        $this->db->select('f_status');
        $this->db->from('tr_product');
        $this->db->where('id', $id);

        $query = $this->db->get();
        $old_status = $query->row()->f_status;

        $new_status = $old_status == 'f' ? 't' : 'f';

        $table = array(
            'f_status' => $new_status, 
        );

        $this->db->where('id', $id);
        $this->db->update('tr_product', $table);
    }

    /** Get Data Company */
    public function get_company($cari)
    {
        return $this->db->query("
            SELECT 
                i_company AS id,
                e_company_name AS e_name
            FROM 
                tr_company 
            WHERE 
                (e_company_name ILIKE '%$cari%')
                AND f_status = 't'
                AND db_name IS NOT NULL
                /*AND i_company IN (
                    SELECT 
                        i_company
                    FROM 
                        tm_user_company
                    WHERE 
                        id_user = '$this->id_user'
                )*/
            ORDER BY 2
        ", FALSE);
    }

    /** Get Data Brand */
    public function get_brand($cari)
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

    /** Get Data Company */
    public function get_company_data()
    {
        return $this->db->query("
            SELECT 
                i_company,
                e_company_name
            FROM 
                tr_company 
            WHERE 
                f_status = 't'
                AND db_name IS NOT NULL
                /*AND i_company IN (
                    SELECT 
                        i_company
                    FROM 
                        tm_user_company
                    WHERE 
                        id_user = '$this->id_user'
                )*/
            ORDER BY 2
        ", FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Simpan */
    public function is_product_exist($i_product, $id=null)
    {
        $where = "";
        if ($id != null) {
            $where = " AND id <> $id ";
        }

        $sql = "SELECT i_product
                FROM tr_product 
                WHERE trim(upper(i_product)) = trim(upper('$i_product')) $where";

        $query = $this->db->query($sql, FALSE);

        return $query->num_rows() > 0;
    }

    /** Simpan Data */
    public function save()
    {
        $table = array(
            'id_product' => $this->input->post('id_product', TRUE),
            'id_brand' => $this->input->post('id_brand', TRUE),
            'v_price' => $this->input->post('vprice', TRUE),
            'e_remark' => $this->input->post('e_remark', TRUE),
        );
        
        $this->db->insert('tm_product_competitor', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id,$icompany=null)
    {
        $sql = "SELECT a.*, a1.id_product, a1.id_brand, a1.v_price, a1.e_remark, b.e_brand_name
                FROM tm_product_competitor a1
                INNER JOIN tr_product a ON a.id = a1.id_product
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                WHERE a1.id = '$id'";

        return $this->db->query($sql, FALSE);
    }

    /** Cek Apakah Data Sudah Ada Pas Edit */
    public function cek_edit($iproduct,$iproductold, $icompany, $icompanyold)
    {
        return $this->db->query("
            SELECT 
                i_product
            FROM 
                tr_product
            WHERE 
                upper(trim(i_product)) <> upper(trim('$iproductold'))
                AND upper(trim(i_product)) = upper(trim('$iproduct'))
                ANd i_company = '$icompany'
                ANd i_company <> '$icompanyold'
        ", FALSE);
    }

    /** Update Data */
    public function update()
    {
        $id = $this->input->post('id');

        $table = [
            'id_product' => $this->input->post('id_product', TRUE),
            'id_brand' => $this->input->post('id_brand', TRUE),
            'v_price' => $this->input->post('vprice', TRUE),
            'e_remark' => $this->input->post('e_remark', TRUE),
        ];

        $this->db->where('id', $id);
        $this->db->update('tm_product_competitor', $table);
    }

    /** Transfer Data */
    public function transfer($i_company)
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
                    i_product_base AS i_product,
                    e_product_basename AS e_product_name,
                    b.e_brand_name AS e_product_groupname,
                    NULL AS brand,
                    0 AS v_price_beli,
                    0 AS v_price_jual
                FROM
                    tr_product_base a
                INNER JOIN tr_brand b ON
                    (
                        b.i_brand = a.i_brand
                    )";
        }else{
            $dbexternalna = "
                SELECT
                    i_product,
                    e_product_name ,
                    c.e_product_groupname,	
                    NULL AS brand,
                    0 AS v_price_beli ,
                    0 AS v_price_jual
                FROM
                    tr_product a
                INNER JOIN tr_product_type b ON
                    (
                        a.i_product_type = b.i_product_type
                    )
                INNER JOIN tr_product_group c ON
                    (
                        b.i_product_group = c.i_product_group
                    )
            ";
        }
        return $this->db->query("
            INSERT INTO tr_product (i_company, i_product, e_product_name, e_product_groupname, i_brand, v_price_beli, v_price_jual, d_entry) 
            SELECT
                '$i_company' AS i_company,
                x.i_product,
                x.e_product_name,
                x.e_product_groupname,
                x.brand AS e_brand,
                x.v_price_beli,
                x.v_price_jual,
                current_timestamp AS d_entry
            FROM
                (
                SELECT
                    *
                FROM
                    dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
                    $$ $dbexternalna $$) AS get_product ( i_product CHARACTER VARYING(15),
                    e_product_name CHARACTER VARYING(250),
                    e_product_groupname CHARACTER VARYING(150),
                    brand CHARACTER VARYING(150),
                    v_price_beli NUMERIC (4, 2),
                    v_price_jual NUMERIC (4, 2) ) ) x
            ORDER BY
                x.e_product_name,
                x.i_product ASC
            ON CONFLICT (i_company, i_product) DO UPDATE 
                SET e_product_name = excluded.e_product_name, 
                    e_product_groupname = excluded.e_product_groupname, 
                    e_brand = excluded.e_brand, 
                    d_update = current_timestamp
        ", FALSE);
    }

    public function get_all_customer_price()
    {
        $sql = "SELECT tcp.*, tc.e_customer_name
                FROM tr_customer_price tcp
                INNER JOIN tr_customer tc ON tc.id_customer = tcp.id_customer";

        return $this->db->query($sql);
    }

    public function update_editable($data)
    {
        $update = [
            'v_price' => $data['value']
        ];

        $this->db->where('id', $data['id']);
        $this->db->update('tr_customer_price', $update);
    }

    public function get_button_status_product_price($data)
    {
        if ($data['f_status']=='t') {
            $status = 'Active';
            $color  = 'success';
        }else{
            $status = 'Not Active';
            $color  = 'danger';
        }
        
        $class ="btn btn-sm badge rounded-round alpha-".$color." text-".$color."-800 border-".$color."-600 legitRipple";
        $button = "<button class='$class'".$status."</button>";
        return $button;
    }
    
    public function delete_all()
	{
		$sql = "TRUNCATE TABLE tr_product CASCADE";

		return $this->db->query($sql);
	}

    /** Ambil Data Customer */
    public function get_customer($cari='')
    {
        $id_user = $this->session->userdata('id_user');

        $limit = "LIMIT 5";
        if ($cari != '') {
            $limit = "";
        }

        $sql = "SELECT id_customer AS id, e_customer_name AS e_name
                FROM tr_customer 
                WHERE (e_customer_name ILIKE '%$cari%') AND f_status = 't' 
                    AND id_customer IN (
                                        SELECT  id_customer
                                        FROM tm_user_customer
                                        WHERE id_user = '$id_user'                
                                    )
                ORDER BY 2
                $limit";

        // var_dump($sql);

        return $this->db->query($sql, FALSE);
    }

    public function get_all_product_list($cari='')
    {
        $limit = "LIMIT 5";
        if ($cari != '') {
            $limit = "";
        }

        $sql = "SELECT a.id, a.e_product_name, a.id_brand, b.e_brand_name
                FROM tr_product a
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                WHERE (a.e_product_name ILIKE '%$cari%') AND a.f_status = 't' 
                $limit";

        return $this->db->query($sql);
    }
}

/* End of file Mmaster.php */
