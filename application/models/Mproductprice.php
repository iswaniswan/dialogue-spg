<?php
defined('BASEPATH') OR exit('No direct script access allowed');
use Ozdemir\Datatables\Datatables;
use Ozdemir\Datatables\DB\CodeigniterAdapter;

class Mproductprice extends CI_Model {

    /** List Datatable */
    public function serverside(){
        $datatables = new Datatables(new CodeigniterAdapter);
        // if ($this->i_company=='1') {
        //     $where = " a.i_company is not null 
        //         /* a.i_company IN (
        //         SELECT 
        //             i_company
        //         FROM 
        //             tm_user_company
        //         WHERE 
        //             id_user = '$this->id_user'
        //     ) */
        //     ";
        // }else{
        //     $where = "
        //         a.i_company = '$this->i_company'
        //     ";
        // }

        $where = "";
        if (!$this->fallcustomer=='t') {
            $where = "WHERE a.id_customer IN (
                                    SELECT id_customer
                                    FROM tm_user_customer
                                    WHERE id_user = '$this->id_user'
                )";
        }

        $sql = "SELECT a.id, 
                        a.id_customer,
                        d.e_customer_name,
                        b.i_product,
                        initcap(b.e_product_name) AS e_product,
                        e.e_brand_name,
                        a.v_price,
                        a.e_periode,
                    CASE
                        WHEN a.d_update ISNULL THEN to_char(a.d_entry, 'dd-mm-yyyy HH12:MI:SS')
                        ELSE to_char(a.d_update, 'dd-mm-yyyy HH12:MI:SS')
                    END AS d_update
                FROM tr_customer_price a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_customer d ON d.id_customer = a.id_customer
                INNER JOIN tr_brand e ON b.id_brand = e.id_brand
                $where 
                GROUP BY 1, 2, 3, 4, 5, b.e_product_name, 6, 7
                ORDER BY d_update, d.e_customer_name, b.e_product_name";

        // var_dump($sql); die();

        $datatables->query($sql, FALSE);       
        
        // formatting harga
        $datatables->edit('v_price', function ($data) {
            $formatted = number_format($data['v_price'], 2, ",", ".");
            return "Rp. $formatted";
        });
        
        $datatables->add('action', function ($data) {
            $id = $data['id'];
            $action = '';

            /** Cek Hak Akses, Apakah User Bisa Edit */
            if (check_role($this->id_menu, 3)) {
                $link = base_url().$this->folder . '/edit/' . encrypt_url($id);
                $class = "icon-database-edit2 text-".$this->color."-800";
                $action = "<a href='$link' title='Edit Data'><i class='$class'></i></a>";
            }

            return $action;
        });
               
        $datatables->hide('id_customer');
        $datatables->hide('d_update');
        return $datatables->generate();
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

    /** Get Data Company */
    public function get_company($id)
    {
        return $this->db->query("
            SELECT 
                i_company
            FROM 
                tr_product 
            WHERE 
                i_product = '$id'
        ", FALSE);
    }

    public function get_customer_id($name){
        return $this->db->query("
            SELECT 
                id_customer
            FROM 
                tr_customer 
            WHERE 
                e_customer_name = '$name'
        ", FALSE);
    }

    public function get_customer_by_id($id_customer){
        $sql = "SELECT * 
                FROM tr_customer 
                WHERE id_customer = '$id_customer'";

        return $this->db->query($sql, FALSE);
    }

    /** Get Data Customer by user cover */
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

    /** Get Data Product sesuai user cover */
    public function get_product($cari='', $id_customer, $all=false)
    {
        $id_user = $this->session->userdata('id_user');

        $limit = 'LIMIT 5';
        if (($cari != '') or ($all)) {
            $limit = "";
        }

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        $sql = "SELECT a.id,
                i_product,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand
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

    /** Simpan Data */
    public function save()
    {
        $id_customer  = $this->input->post('id_customer', TRUE);
        $id_product   = $this->input->post('id_product', TRUE);
        $vprice     = $this->input->post('vprice', TRUE);
        $e_periode_year = $this->input->post('e_periode_year', TRUE);
        $e_periode_month = $this->input->post('e_periode_month', TRUE);
        $e_periode = $e_periode_year . $e_periode_month;

        /** sterilize formatted number */
        $vprice = str_replace(".", "", $vprice);
        $vprice = str_replace(",", ".", $vprice);

        $product = array(
            'id_product' => $id_product,
            'id_customer' => $id_customer,
            'v_price' => $vprice,
            'd_entry' => current_datetime(),
            'e_periode' => $e_periode
        );
        
        $this->db->insert('tr_customer_price', $product);
    }

    public function update()
    {
        $id = $this->input->post('id');
        $id_customer = $this->input->post('id_customer', TRUE);
        $id_product = $this->input->post('id_product', TRUE);
        $e_periode_year = $this->input->post('e_periode_year', TRUE);
        $e_periode_month = $this->input->post('e_periode_month', TRUE);
        $e_periode = $e_periode_year . $e_periode_month;
        
        $vprice = $this->input->post('vprice', TRUE);
        /** sterilize formatted number */
        $vprice = str_replace(".", "", $vprice);
        $vprice = str_replace(",", ".", $vprice);

        $dupdate = date('Y-m-d');
        $data = [
            'v_price'=> $vprice,
            'd_update' => $dupdate,
            'id_customer' => $id_customer,
            'e_periode' => $e_periode,
            'id_product' => $id_product
        ];

        $this->db->where('id', $id);
        $this->db->update('tr_customer_price', $data);
    }

    /** Get Data Untuk Edit */
    public function getdata($id, $i_company, $id_customer)
    {
        $sql = "SELECT a.*,d.e_customer_name, initcap(b.e_product_name) AS e_product_name, b.id_brand, b.i_product
                FROM tr_customer_price a
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_customer d ON d.id_customer = a.id_customer
                WHERE a.id = '$id'";

        return $this->db->query($sql, FALSE);
    }

    /** Export Data */
    public function exportdata()
    {
        $sql = "SELECT i_product, e_product_name, 0 AS v_price 
                FROM tr_product
                WHERE f_status = 't'
                GROUP BY 1,2
                ORDER BY 1";

        return $this->db->query($sql, FALSE);
    }

    public function export_data_by_user_cover($id_customer, $e_periode)
    {
        $id_user = $this->session->userdata('id_user');

        $sql_brand_cover = "SELECT tub.id_brand
                            FROM tm_user_brand tub						
                            WHERE id_user_customer = (
                                            SELECT id
                                            FROM tm_user_customer
                                            WHERE id_user = '$id_user' AND id_customer = '$id_customer'
                                        )";

        $sql_product = "SELECT a.id,
                i_product,
                e_product_name AS e_name,
                a.id_brand,
                b.e_brand_name AS brand,
                $id_customer AS id_customer
            FROM tr_product a
            INNER JOIN tr_brand b ON b.id_brand = a.id_brand
            WHERE a.f_status = 't'AND a.id_brand IN ($sql_brand_cover)
            ORDER BY 4, 1";

        $sql_product_price = "WITH CTE AS ($sql_product) 
            SELECT CTE.brand, CTE.id, CTE.i_product, CTE.e_name, v_price
            FROM tr_customer_price tcp
            RIGHT JOIN CTE ON CTE.id = tcp.id_product AND CTE.id_customer = tcp.id_customer AND tcp.e_periode='$e_periode'";

        // var_dump($sql_product_price); die();

        return $this->db->query($sql_product_price);
    }

    public function cek_produk($i_product, $i_company)
    {
        $this->db->where('i_product',$i_product);
        $this->db->where('i_company',$i_company);
        return $this->db->get('tr_product');
    }

    public function cek_produk_eksis($iproduct,$icompany)
    {
        return $this->db->query("SELECT * FROM tr_customer_price WHERE i_product = '$iproduct' AND i_company = '$icompany'");

    }

    public function is_customer_price_exist($id_product, $id_customer, $e_periode)
    {
        $sql = "SELECT * FROM tr_customer_price WHERE id_product = '$id_product' 
                AND id_customer = '$id_customer'
                AND e_periode = '$e_periode'";
        $query = $this->db->query($sql);
        return $query->num_rows() > 0;
    }

    public function transfer()
    {
        $id_customer = $this->input->post('id_customer', TRUE);
        $jml = $this->input->post('jml', TRUE);

        for ($i=1; $i <= $jml; $i++) { 
            $id_product   = $this->input->post('id_product'.$i, TRUE);
            $vprice     = $this->input->post('v_price'.$i, TRUE);

            $sql = "INSERT INTO tr_customer_price (id_customer, id_product, v_price, d_entry) 
                    VALUES ($id_customer, $id_product, $vprice, now())
                    ON CONFLICT (id_customer, id_product) DO UPDATE 
                    SET v_price = $vprice, 
                        d_update = now()";

            $this->db->query($sql, FALSE);
        }
    }

    public function delete($id)
    {
        $this->db->where('id_customer', $id);
        $this->db->delete('tr_customer_price');
    }

    public function delete_all()
	{
		$sql = "TRUNCATE TABLE tr_customer_price CASCADE";

		return $this->db->query($sql);
	}
}

/* End of file Mmaster.php */
