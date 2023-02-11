<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Transfer extends CI_Controller
{

	public function __construct()
	{
		parent::__construct();
	}

	public function index()
	{
		echo 'Untu ktransfer ';
	}
	/** Default Controllers */
	public function transfer_product()
	{
		$this->db->trans_begin();
        $company = $this->db->query(" select * from tr_company where f_status = true", FALSE);

        if ($company) {
        	foreach ($company->result() as $query) {
        		$i_company        = $query->i_company;
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
						     a.i_brand::varchar AS brand,
						     0 AS v_price_beli,
						     0 AS v_price_jual,
						     true as f_status
						 FROM
						     tr_product_base a
						 INNER JOIN tr_brand b ON (b.i_brand = a.i_brand)
						 where a.i_kelompok = '1'
		            ";
		        }else{
		            $dbexternalna = "
		                SELECT
                         i_product,
                         e_product_name ,
                         c.e_product_groupname,   
                         c.i_product_group AS brand,
                         0 AS v_price_beli ,
                         0 AS v_price_jual ,
                         case when  a.i_product_status <> '4' then true else false end as f_status
                     FROM
                         tr_product a
                     INNER JOIN tr_product_type b on (a.i_product_type = b.i_product_type)
                     INNER JOIN tr_product_group c on (b.i_product_group = c.i_product_group)
		            ";
		        }

		        $this->db->query("
			          INSERT INTO tr_product (i_company, i_product, e_product_name, e_product_group_name, id_brand, v_price_beli, v_price_jual, d_entry, f_status)
			          SELECT
			                '$i_company' AS i_company,
			                x.i_product,
			                x.e_product_name,
			                x.e_product_group_name,
			                y.id_brand,
			                x.v_price_beli,
			                x.v_price_jual,
			                current_timestamp AS d_entry,
			                x.f_status
			            FROM
			                (
			                SELECT
			                    *
			                FROM
			                    dblink('host=$Url user=$User password=$Password dbname=$DbName port=$Port',
			                    $$ $dbexternalna $$) AS get_product ( i_product CHARACTER VARYING(15),
			                    e_product_name CHARACTER VARYING(250),
			                    e_product_group_name CHARACTER VARYING(150),
			                    keybrand varchar(30),
			                    v_price_beli NUMERIC (4, 2),
			                    v_price_jual NUMERIC (4, 2),
			                    f_status boolean) 
			                ) x
					        inner join tr_brand_mapping y on (y.i_company = '$i_company' and y.id_keybrand = x.keybrand)
					        ORDER BY x.e_product_name, x.i_product asc    
			            ON CONFLICT (i_company, i_product) DO UPDATE 
			                SET e_product_name = excluded.e_product_name, 
			                    e_product_group_name = excluded.e_product_group_name, 
			                    f_status = excluded.f_status, 
			                    d_update = current_timestamp 
			        ", FALSE);

		        var_dump("berhasil". $i_company. '<br>');
        	}
        } 
        

        if ($this->db->trans_status() === FALSE) {
			$this->db->trans_rollback();
			$data = array(
				'sukses' => false,
				'ada'	 => false,
			);
		} else {
			$this->db->trans_commit();
			
			$data = array(
				'sukses' => true,
				'ada'	 => false,
			);
		}
		echo json_encode($data);
	}

}