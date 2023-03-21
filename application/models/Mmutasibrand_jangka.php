<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Mmutasibrand_Jangka extends CI_Model
{
    public function calc_pemebelian($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND e.id_brand='$id_brand'";
        }

        $sql = "SELECT
                a.id_customer,
                b.id_product,
                d.i_product,
                d.e_product_name,
                e.id_brand,
                e.e_brand_name, 
                sum(b.n_qty) AS pembelian,
                0 AS retur,
                0 AS penjualan,
                0 AS adjustment,
                0 AS stock_opname
            FROM tm_pembelian a
            INNER JOIN tm_pembelian_item b ON b.id_pembelian = a.id
            INNER JOIN tr_product d ON d.id = b.id_product
            INNER JOIN tr_brand e ON e.id_brand = d.id_brand
            WHERE a.f_status = 't'
                AND a.d_receive BETWEEN '$date_start' AND '$date_end'
            GROUP BY 1,2,3,4,5,6";

        return $this->db->query($sql);
    }

    public function calc_pembelian_retur($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND e.id_brand='$id_brand'";
        }

        $sql = "SELECT
                a.id_customer,
                b.id_product,
                d.i_product,
                d.e_product_name,
                e.id_brand,
                e.e_brand_name,
                0 AS pembelian,
                sum(b.n_qty) AS retur,
                0 AS penjualan,
                0 AS adjustment,
                0 AS stock_opname
            FROM
                tm_pembelian_retur a
            INNER JOIN tm_pembelian_retur_item b ON (b.id_retur = a.id)
            INNER JOIN tr_product d ON (d.id = b.id_product)
            INNER JOIN tr_brand e ON (e.id_brand = d.id_brand)
            WHERE
                a.f_status = 't'
                AND a.d_approve IS NOT NULL
                AND a.d_retur BETWEEN '$date_start' AND '$date_end'
            GROUP BY 1,2,3,4,5,6";

        return $this->db->query($sql);
    }

    public function calc_penjualan($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND e.id_brand='$id_brand'";
        }

        $sql = "SELECT
                a.id_customer,
                b.id_product,
                d.i_product,
                d.e_product_name,
                e.id_brand,
                e.e_brand_name,
                0 AS pembelian,
                0 AS retur,
                sum(b.n_qty) AS penjualan,
                0 AS adjustment,
                0 AS stock_opname
            FROM tm_penjualan a
            INNER JOIN tm_penjualan_item b ON (b.id_penjualan = a.id)
            INNER JOIN tr_product d ON (d.id = b.id_product)
            INNER JOIN tr_brand e ON (e.id_brand = d.id_brand)
            WHERE
                a.f_status = 't'
                AND a.d_document BETWEEN '$date_start' AND '$date_end'
            GROUP BY 1,2,3,4,5,6";

        return $this->db->query($sql);
    }

    public function calc_adjustment($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND e.id_brand='$id_brand'";
        }

        $sql = "SELECT
                a.id_customer,
                b.id_product,
                d.i_product,
                d.e_product_name,
                d.id_brand,
                e.e_brand_name,
                0 AS pembelian,
                0 AS retur,
                0 AS penjualan,
                sum(b.n_adjustment ::DECIMAL) AS adjustment,
                0 AS stock_opname
            FROM tm_adjustment a
            INNER JOIN tm_adjustment_item b ON (b.id_adjustment = a.id)
            INNER JOIN tr_product d ON (d.id = b.id_product)
            INNER JOIN tr_brand e ON (e.id_brand = d.id_brand)
            WHERE
                a.f_status = 't'
                AND a.d_document BETWEEN '$date_start' AND '$date_end'
            GROUP BY 1,2,3,4,5,6 ";
        
        return $this->db->query($sql);
    }

    public function calc_stockopname($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $where_and = '';

        if ($id_customer != null) {
            $where_and .= " AND a.id_customer='$id_customer'";
        }

        if ($id_brand != null) {
            $where_and .= " AND e.id_brand='$id_brand'";
        }

        $sql = "SELECT 
                    a.id_customer,
                    b.id_product,
                    d.i_product,
                    d.e_product_name,
                    e.id_brand,
                    e.e_brand_name,
                    0 AS pembelian,
                    0 AS retur,
                    0 AS penjualan,
                    0 AS adjustment,
                    b.n_qty AS stock_opname
                FROM tm_stockopname a
                INNER JOIN tm_stockopname_item b ON (b.id_stockopname = a.id)
                INNER JOIN tr_product d ON  (d.id = b.id_product)
                INNER JOIN tr_brand e ON    (e.id_brand = d.id_brand)
                WHERE a.f_status = 't'
                    AND a.d_document BETWEEN '$date_start' AND '$date_end'
                    AND a.id in(
                        SELECT max(id) AS id
                        FROM tm_stockopname ts
                        GROUP BY id_customer, i_periode
                    )    
                GROUP BY 1,2,3,4,5,6,11";

        return $this->db->query($sql);
    }

    public function calc_saldo_awal($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $sql = "SELECT
                    c.id_customer,
                    b.i_product,
                    b.e_product_name,
                    b.id_brand,
                    e.e_brand_name,
                    a.n_saldo AS saldo_awal,
                    0 AS pembelian,
                    0 AS retur,
                    0 AS penjualan,
                    0 AS adjustment
                FROM tm_mutasi_saldoawal c
                INNER JOIN tm_mutasi_saldoawal_item a ON (a.id_header = c.id)
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_brand e ON (e.id_brand = b.id_brand)
                WHERE c.d_approve NOTNULL AND c.f_status = 't'
                UNION ALL 
                SELECT
                    id_customer,
                    i_product,
                    e_product_name,
                    id_brand,
                    e_brand_name,
                    0 AS saldo_awal,
                    pembelian,
                    retur,
                    penjualan,
                    adjustment
                FROM f_mutasi_brand_jangka_baru_new ('$date_start', '$date_end')";

        return $this->db->query($sql);
    }

    public function get_result($date_start, $date_end, $id_customer=null, $id_brand=null)
    {
        $sql_saldo_awal = "SELECT
                    c.id_customer,
                    b.i_product,
                    b.e_product_name,
                    b.id_brand,
                    e.e_brand_name,
                    a.n_saldo AS saldo_awal,
                    0 AS pembelian,
                    0 AS retur,
                    0 AS penjualan,
                    0 AS adjustment
                FROM tm_mutasi_saldoawal c
                INNER JOIN tm_mutasi_saldoawal_item a ON (a.id_header = c.id)
                INNER JOIN tr_product b ON b.id = a.id_product
                INNER JOIN tr_brand e ON (e.id_brand = b.id_brand)
                WHERE c.d_approve NOTNULL AND c.f_status = 't'
                UNION ALL 
                SELECT
                    id_customer,
                    i_product,
                    e_product_name,
                    id_brand,
                    e_brand_name,
                    0 AS saldo_awal,
                    pembelian,
                    retur,
                    penjualan,
                    adjustment
                FROM f_mutasi_brand_jangka_baru_new ('$date_start', '$date_end')";

        $sql = "SELECT
                    id_customer,
                    i_product,
                    upper(e_product_name) AS e_product_name,
                    id_brand,
                    upper(e_brand_name) AS e_brand_name,
                    sum(saldo_awal) AS saldo_awal,
                    sum(pembelian) AS pembelian,
                    sum(retur) AS retur,
                    sum(penjualan) AS penjualan,
                    sum(adjustment) AS adjustment,
                    sum(((saldo_awal + pembelian) - (retur + penjualan)) + adjustment) AS saldo_akhir,
                    sum(stock_opname) AS stock_opname
                FROM (
                        /*** SALDO AWAL ***/
                        SELECT
                            id_customer,
                            i_product,
                            e_product_name,
                            id_brand,
                            e_brand_name,
                            sum(((saldo_awal + pembelian) - (retur + penjualan)) + adjustment) AS saldo_awal,
                            0 AS pembelian,
                            0 AS retur,
                            0 AS penjualan,
                            0 AS adjustment,
                            0 AS stock_opname
                        FROM ($sql_saldo_awal)
                        GROUP BY 1,2,3,4,5
                        /*** END SALDO AWAL ***/
                        UNION ALL
                        /*** TRANSAKSI PEMBELIAN, RETUR, PENJUALAN ***/
                        SELECT
                            id_customer,
                            i_product,
                            e_product_name,
                            id_brand,
                            e_brand_name,
                            0 AS saldo_awal,
                            pembelian,
                            retur,
                            penjualan,
                            adjustment,
                            stock_opname
                        FROM
                            f_mutasi_brand_jangka_baru_new ('$date_start', '$date_end')    
                        /*** END TRANSAKSI PEMBELIAN, RETUR, PENJUALAN ***/                            
                    ) AS x
                GROUP BY 1,2,3,4,5";
    }
}
