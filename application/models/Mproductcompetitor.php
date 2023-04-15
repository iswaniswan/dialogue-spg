<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;
use phpDocumentor\Reflection\Types\Null_;

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
                    initcap(c2.e_customer_name) AS e_customer_name,
                    initcap(b.e_product_name) AS e_product_name,
                    initcap(c.e_brand_name) AS e_brand_name,
                    a.v_price,
                    a.f_status,
                    CASE 
                        WHEN a.d_update ISNULL THEN to_char(a.d_entry, 'dd-mm-yyyy HH12:MI:SS') 
                        ELSE to_char(a.d_update, 'dd-mm-yyyy HH12:MI:SS') 
                    END AS d_update
                FROM tm_product_competitor a
                INNER JOIN tr_product b on b.id = a.id_product
                INNER JOIN tr_customer c2 ON c2.id_customer = a.id_customer
                LEFT JOIN tr_brand c ON c.id_brand = a.id_brand
                ORDER BY b.e_product_name ASC";

        $datatables->query($sql, FALSE);

        $datatables->edit('v_price', function ($data) {
            $prefix = 'Rp. ';
            return $prefix . number_format($data['v_price'], 0, ".", ",");
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

        // $datatables->hide('f_status');

        return $datatables->generate();
    }

    /** List Datatable */
    public function serverside2(){
        $datatables = new Datatables(new CodeigniterAdapter);

        $sql_count = "SELECT id_product , count(count_brand) FROM (
                            SELECT tpc.id_product, count(*) AS count_brand  
                            FROM tm_product_competitor tpc 
                            GROUP BY tpc.id_product, e_brand_text
                        ) AS x
                        GROUP BY 1";

        $sql = "SELECT a.id, a.i_product, a.e_product_name, b.e_brand_name, 
                    CASE WHEN cc.count IS NULL THEN 0 ELSE cc.count END AS count
                FROM tr_product a 
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                LEFT JOIN ($sql_count) cc ON cc.id_product = a.id
                WHERE a.f_status = 't'
                ORDER BY count DESC NULLS LAST";

        // var_dump($sql); die();

        $datatables->query($sql, FALSE);        
        
        $datatables->add('action', function ($data) {
            $id = trim($data['id']);       

            $link =  base_url().$this->folder.'/view_competitor/'.encrypt_url($id);
            $data = "<a href='$link' title='View Data'><i class='icon-database-check text-info-800 mr-1'></i></a>";

            $link =  base_url().$this->folder.'/edit_competitor/'.encrypt_url($id);
            $data .= "<a href='$link' title='Add or Edit Data'><i class='icon-database-edit2 text-warning-800 mr-1'></i></a>";

            return $data;
        });

        // $datatables->hide('f_status');        

        return $datatables->generate();
    }

    public function serverside3($id_customer=null)
    {
        $id_user = $this->session->userdata('id_user');

        $where = " WHERE CTE.id_customer IN (
                                        SELECT  id_customer
                                        FROM tm_user_customer
                                        WHERE id_user = '$id_user')";
        if ($id_customer != null) {
            $where = " WHERE CTE.id_customer='$id_customer'";
        }

        $sql = "WITH CTE AS (
                    SELECT p.id AS id_product, c.id_customer FROM tr_product p 
                    CROSS JOIN tr_customer c
                ) SELECT 
                    CTE.id_product, CTE.id_customer,
                    c.e_customer_name, a.i_product, g.e_category_name, gg.e_sub_category_name, a.e_product_name, b.e_brand_name, cc.cnt  
                FROM CTE
                INNER JOIN tr_product a ON a.id = CTE.id_product 
                LEFT JOIN tm_category g ON g.id = a.id_category 
                LEFT JOIN tm_sub_category gg ON gg.id = a.id_sub_category 
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand 
                INNER JOIN tr_customer c ON c.id_customer = CTE.id_customer
                LEFT JOIN (
                            SELECT id_customer, id_product, count(*) AS cnt 
                            FROM (
                                    SELECT id_customer, id_product
                                    FROM tm_product_competitor tpc 
                                    GROUP BY 1, 2, e_brand_text
                                ) AS foo 
                            GROUP BY 1, 2			
                            ) AS cc ON cc.id_customer = CTE.id_customer AND cc.id_product = CTE.id_product
                $where
                ORDER BY cnt DESC NULLS LAST, e_customer_name ASC, e_brand_name ASC, e_product_name ASC";

        $datatables = new Datatables(new CodeigniterAdapter);

        // var_dump($sql); die();

        $datatables->query($sql, FALSE);        
        
        $datatables->add('action', function ($data) {
            $id_product = trim($data['id_product']);
            $id_customer = trim($data['id_customer']);

            $link =  base_url().$this->folder . "/view_competitor?id_product=$id_product&id_customer=$id_customer";
            $data = "<a href='$link' title='View Data'><i class='icon-database-check text-info-800 mr-1'></i></a>";

            $link =  base_url().$this->folder . "/edit_competitor?id_product=$id_product&id_customer=$id_customer";
            $data .= "<a href='$link' title='Add or Edit Data'><i class='icon-database-edit2 text-warning-800 mr-1'></i></a>";

            $link =  base_url().$this->folder . "/report_competitor?id_product=$id_product&id_customer=$id_customer";
            $data .= "<a href='$link' title='Report'><i class='icon-database-time2 text-success-800 mr-1'></i></a>";

            return $data;
        });

        $datatables->hide('id_product');
        // $datatables->hide('id_customer');

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
    public function get_brand($cari, $id_user_customer)
    {
        $sql_cover = "SELECT id_brand FROM tm_user_brand tub WHERE id_user_customer='$id_user_customer'";

        $sql ="SELECT id_brand AS id,
                    e_brand_name AS e_name
                FROM tr_brand 
                WHERE id_brand IN ($sql_cover)
                    AND (e_brand_name ILIKE '%$cari%')
                    AND f_status = 't'
                ORDER BY 2";

        return $this->db->query($sql);
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
        $v_price = $this->input->post('vprice', TRUE);
        $v_price = str_replace(".", "", $v_price);
        $v_price = str_replace(",", "", $v_price);

        $e_periode = $this->input->post('e_periode') ?? null;
        $e_periode = str_replace(" ", "", $e_periode);        

        $table = array(
            'id_customer' => $this->input->post('id_customer'),
            'id_product' => $this->input->post('id_product', TRUE),
            'id_brand' => $this->input->post('id_brand', TRUE),
            'v_price' => $v_price,
            'e_remark' => $this->input->post('e_remark', TRUE),
            'e_periode' => $e_periode
        );
        
        $this->db->insert('tm_product_competitor', $table);
    }

    /** Get Data Untuk Edit */
    public function getdata($id,$icompany=null)
    {
        $sql = "SELECT a1.id, a1.id_product, a1.id_brand, a1.v_price, a1.e_remark, b.e_brand_name,
                        a1.e_periode, c.id_customer, c.e_customer_name,
                        a.e_product_name
                FROM tm_product_competitor a1
                INNER JOIN tr_product a ON a.id = a1.id_product
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                INNER JOIN tr_customer c ON c.id_customer = a1.id_customer
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
        
        $v_price = $this->input->post('vprice', TRUE);
        $v_price = str_replace(".", "", $v_price);
        $v_price = str_replace(",", "", $v_price);

        $e_periode = $this->input->post('e_periode');
        $e_periode = str_replace(" ", "", $e_periode);

        $table = [
            'id_customer' => $this->input->post('id_customer'),
            'id_product' => $this->input->post('id_product', TRUE),
            'id_brand' => $this->input->post('id_brand', TRUE),
            'v_price' => $v_price,
            'e_remark' => $this->input->post('e_remark', TRUE),
            'e_periode' => $e_periode
        ];

        $this->db->where('id', $id);
        $this->db->update('tm_product_competitor', $table);
    }

    public function insert_update_product_competitor($id_customer, $id_product, $v_price, $e_remark, $e_brand_text, $d_berlaku)
    {
        $sql = "INSERT INTO tm_product_competitor
                (id_customer, id_product, v_price, e_remark, e_brand_text, d_berlaku)
                VALUES($id_customer, $id_product, $v_price, '$e_remark', '$e_brand_text', '$d_berlaku') 
                /* ON CONFLICT (id_customer, e_brand_text, d_berlaku) */
                ON CONFLICT ON CONSTRAINT pk_unique_tm_product_competitor
                DO UPDATE SET v_price = $v_price, d_update = current_timestamp" ;

        return $this->db->query($sql);
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

    public function get_all_customer_price($id_product=null)
    {
        $where = "";
        if ($id_product != null) {
            $where = " WHERE id_product='$id_product'";
        }

        $sql = "SELECT tcp.*, tc.e_customer_name
                FROM tr_customer_price tcp
                INNER JOIN tr_customer tc ON tc.id_customer = tcp.id_customer
                $where";

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
    public function get_customer($cari='', $id_customer=null)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = "LIMIT 5";
        if ($cari != '') {
            $limit = "";
        }

        $where = "WHERE (e_customer_name ILIKE '%$cari%') AND f_status = 't' 
                    AND id_customer IN (
                                        SELECT  id_customer
                                        FROM tm_user_customer
                                        WHERE id_user = '$id_user'                
                                    )";

        if ($id_customer != null) {
            $where = "WHERE id_customer='$id_customer'";
        }

        $sql = "SELECT id_customer AS id, e_customer_name AS e_name
                FROM tr_customer 
                $where
                ORDER BY 2
                $limit";

        // var_dump($sql);

        return $this->db->query($sql, FALSE);
    }

    public function get_product_by_id($id_product) 
    {
        $sql = "SELECT a.*, b.e_brand_name
                FROM tr_product a 
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                WHERE id='$id_product'";

        return $this->db->query($sql);
    }

    public function get_product_customer_berjalan($id_product, $id_customer, $e_periode=null) 
    {
        $periode = date('Ym');
        if ($e_periode != null) {
            $periode = $e_periode;
        }

        $sql = "SELECT a.*, b.e_brand_name, p.v_price 
                FROM tr_product a 
                INNER JOIN tr_brand b ON b.id_brand = a.id_brand
                LEFT JOIN (
                            SELECT * 
                            FROM tr_customer_price tcp 
                            WHERE id_customer='$id_customer' AND id_product='$id_product'
                                AND e_periode  <= '$periode' 
                            ORDER BY e_periode DESC
                            LIMIT 1
                ) p ON p.id_customer = '$id_customer' AND p.id_product = a.id
                WHERE a.id='$id_product'";

        return $this->db->query($sql);
    }
    
    public function get_product($cari='', $id_customer, $id_brand=null)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = 'LIMIT 5';
        if (($cari != '')) {
            $limit = "";
        }

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        if ($id_brand != null) {
            $sql_brand_cover = $id_brand;
        }                                        

        $sql = "SELECT a.id,
                i_product,
                e_product_name,
                a.id_brand,
                b.e_brand_name
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE (e_product_name ILIKE '%$cari%' OR i_product ILIKE '%$cari%')
                AND a.f_status = 't'
                AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4,1
            $limit";

        // var_dump($sql); die();

        return $this->db->query($sql, FALSE);
    }

    public function get_id_user_customer($id_customer) 
    {
        $id_user = $this->session->userdata('id_user');

        $sql = "SELECT * FROM tm_user_customer WHERE id_user='$id_user' AND id_customer='$id_customer'";

        return $this->db->query($sql)->row()->id;
    }

    public function get_all_product()
    {
        $sql = "SELECT * FROM tr_product WHERE f_status = 't'";

        return $this->db->query($sql);
    }

    public function get_all_competitor_by_id_product($id_product)
    {
        $sql = "SELECT c.e_customer_name, a.*  FROM tm_product_competitor a 
                INNER JOIN tr_customer c ON c.id_customer = a.id_customer 
                WHERE a.id_product = '$id_product'
                ORDER BY d_berlaku DESC, e_customer_name ASC";

        return $this->db->query($sql);
    }

    public function get_product_competitor($id_product, $id_customer)
    {
        $sql = "SELECT * 
                FROM tm_product_competitor tpc 
                WHERE id_customer = '$id_customer' 
                    AND id_product = '$id_product'";

        // var_dump($sql); die();

        return $this->db->query($sql);
    }

    public function get_product_competitor_rekap($id_product, $id_customer, $e_periode=null)
    {
        if ($e_periode == null) {
            $e_periode = date('Ym');
        }

        $sql_p = "SELECT id_customer, id_product, v_price 
                    FROM tr_customer_price tcp					
                        WHERE id_customer='$id_customer' AND id_product='$id_product' AND e_periode <= '$e_periode' 
                    ORDER BY e_periode DESC LIMIT 1";
        
        $sql_c = "SELECT c.*, p.v_price AS origin_price
                    FROM tm_product_competitor c
                    LEFT JOIN ($sql_p) p ON p.id_customer=c.id_customer AND p.id_product=c.id_product
                    WHERE c.id_customer = '$id_customer' AND c.id_product = '$id_product'
                    ORDER BY d_berlaku desc";

        $sql = "SELECT * 
                FROM (
                        SELECT DISTINCT ON (c.e_brand_text) c.e_brand_text, v_price, d_berlaku, 
                                                (origin_price - v_price ) AS selisih, e_remark
                        FROM ($sql_c) AS c
                ) foo ORDER BY selisih asc";

        return $this->db->query($sql);
    }

    public function delete_product_competitor($id_product)
    {
        $sql = "DELETE FROM tm_product_competitor WHERE id_product='$id_product'";

        return $this->db->query($sql);
    }

}

/* End of file Mmaster.php */
