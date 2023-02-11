--
-- PostgreSQL database dump
--

-- Dumped from database version 10.17 (Ubuntu 10.17-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.17

-- Started on 2021-08-26 10:00:57 WIB

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 235 (class 1255 OID 40746)
-- Name: dblink(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dblink(text, text) RETURNS SETOF record
    LANGUAGE c STRICT
    AS '$libdir/dblink', 'dblink_record';


ALTER FUNCTION public.dblink(text, text) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 41840)
-- Name: f_mutasi_saldo(date, date, date, date, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_mutasi_saldo(d_from date, d_to date, d_jangka_from date, d_jangka_to date, i_company character varying, id_user integer) RETURNS TABLE(i_company integer, i_product character varying, e_product_name character varying, saldo_awal numeric, pembelian numeric, retur numeric, penjualan numeric, saldo_akhir numeric)
    LANGUAGE sql
    AS $_$;

SELECT
    i_company,
    i_product,
    e_product_name,
    0::NUMERIC AS saldo_awal,
    sum(pembelian) AS pembelian,
    sum(retur) AS retur,
    sum(penjualan) AS penjualan,
    sum((saldo_awal + pembelian) - (retur + penjualan)) AS saldo_akhir
FROM
    (
    /*** SALDO AWAL ***/
    SELECT
        i_company,
        i_product,
        e_product_name,
        sum(saldo_awal + saldo_akhir) AS saldo_awal,
        0 AS pembelian,
        0 AS retur,
        0 AS penjualan
    FROM
        (
        SELECT
            a.i_company,
            a.i_product,
            b.e_product_name,
            a.n_saldo AS saldo_awal,
            0 AS saldo_akhir
        FROM
            tm_saldo_awal a
        INNER JOIN tr_product b ON
            (b.i_product = a.i_product
                AND a.i_company = b.i_company)
        WHERE
            a.i_periode = to_char($1, 'YYYYmm')
            AND
            CASE
                WHEN $5 = 'all' THEN a.i_company IN (
                SELECT
                    i_company
                FROM
                    tm_user_company
                WHERE
                    id_user = $6)
                ELSE a.i_company::varchar = $5
            END
    UNION ALL
        SELECT
            i_company,
            i_product,
            e_product_name,
            0 AS saldo_awal,
            saldo_akhir
        FROM
            f_mutasi_saldo_jangka ($3,
            $4,
            $5,
            $6)
    )
    AS a
    GROUP BY
        1,
        2,
        3
    /*** END SALDO AWAL ***/
UNION ALL
    /*** TRANSAKSI PEMBELIAN, RETUR, PENJUALAN ***/
    SELECT
        i_company,
        i_product,
        e_product_name,
        0 AS saldo_awal,
        pembelian,
        retur,
        penjualan
    FROM
        f_mutasi_saldo_jangka ($1,
        $2,
        $5,
        $6)
    /*** END TRANSAKSI PEMBELIAN, RETUR, PENJUALAN ***/
        ) AS x
GROUP BY
    1,
    2,
    3
ORDER BY
    3,
    2,
    1

$_$;


ALTER FUNCTION public.f_mutasi_saldo(d_from date, d_to date, d_jangka_from date, d_jangka_to date, i_company character varying, id_user integer) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 41836)
-- Name: f_mutasi_saldo_jangka(date, date, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_mutasi_saldo_jangka(d_from date, d_to date, i_company character varying, id_user integer) RETURNS TABLE(i_company integer, i_product character varying, e_product_name character varying, saldo_awal numeric, pembelian numeric, retur numeric, penjualan numeric, saldo_akhir numeric)
    LANGUAGE sql
    AS $_$;

SELECT
    i_company,
    i_product,
    e_product_name,
    0::NUMERIC AS saldo_awal,
    sum(pembelian) AS pembelian,
    sum(retur) AS retur,
    sum(penjualan) AS penjualan,
    sum(pembelian - (retur + penjualan)) AS saldo_akhir
FROM
    (
/*** PEMBELIAN ***/
    SELECT
        b.i_company,
        b.i_product,
        b.e_product_name,
        sum(b.n_qty) AS pembelian,
        0 AS retur,
        0 AS penjualan
    FROM
        tm_pembelian a
    INNER JOIN tm_pembelian_item b ON
        (b.id_document = a.id_document)
    WHERE
        a.f_status = 't'
        AND a.d_receive BETWEEN $1 AND $2
        AND CASE
            WHEN $3 = 'all' THEN b.i_company IN (
            SELECT
                i_company
            FROM
                tm_user_company
            WHERE
                id_user = $4)
            ELSE b.i_company::varchar = $3
        END
    GROUP BY
        3,
        2,
        1
/*** END PEMBELIAN ***/
UNION ALL
/*** RETUR ***/
    SELECT
        b.i_company,
        b.i_product,
        b.e_product_name,
        0 AS pembelian,
        sum(b.n_qty) AS retur,
        0 AS penjualan
    FROM
        tm_pembelian_retur a
    INNER JOIN tm_pembelian_retur_item b ON
        (b.id_document = a.id_document)
    WHERE
        a.f_status = 'f'
        AND a.d_retur BETWEEN $1 AND $2
        AND CASE
            WHEN $3 = 'all' THEN b.i_company IN (
            SELECT
                i_company
            FROM
                tm_user_company
            WHERE
                id_user = $4)
            ELSE b.i_company::varchar = $3
        END
    GROUP BY
        3,
        2,
        1
/*** END RETUR ***/
UNION ALL 
/*** PENJUALAN ***/
    SELECT
        b.i_company,
        b.i_product,
        b.e_product_name,
        0 AS pembelian,
        0 AS retur,
        sum(b.n_qty) AS penjualan
    FROM
        tm_penjualan a
    INNER JOIN tm_penjualan_item b ON
        (b.id_document = a.id_document)
    WHERE
        a.f_status = 't'
        AND a.d_document BETWEEN $1 AND $2
        AND CASE
            WHEN $3 = 'all' THEN b.i_company IN (
            SELECT
                i_company
            FROM
                tm_user_company
            WHERE
                id_user = $4)
            ELSE b.i_company::varchar = $3
        END
    GROUP BY
        3,
        2,
        1
/*** END PENJUALAN ***/
        ) AS x
GROUP BY
    3,
    2,
    1
ORDER BY
    3,
    2,
    1
$_$;


ALTER FUNCTION public.f_mutasi_saldo_jangka(d_from date, d_to date, i_company character varying, id_user integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 196 (class 1259 OID 17760)
-- Name: dg_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dg_log (
    id_user integer NOT NULL,
    ip_address character varying(16) NOT NULL,
    waktu timestamp without time zone DEFAULT now() NOT NULL,
    activity text
);


ALTER TABLE public.dg_log OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 17767)
-- Name: tm_pembelian; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian (
    id_document integer NOT NULL,
    id_item integer NOT NULL,
    i_document character varying(50) NOT NULL,
    d_receive date,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone,
    id_user integer NOT NULL,
    i_company integer NOT NULL
);


ALTER TABLE public.tm_pembelian OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 17775)
-- Name: tm_pembelian_id_document_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_pembelian_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_pembelian_id_document_seq OWNER TO postgres;

--
-- TOC entry 3316 (class 0 OID 0)
-- Dependencies: 198
-- Name: tm_pembelian_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_id_document_seq OWNED BY public.tm_pembelian.id_document;


--
-- TOC entry 199 (class 1259 OID 17777)
-- Name: tm_pembelian_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_item (
    id_item integer NOT NULL,
    id_document integer NOT NULL,
    i_company integer NOT NULL,
    i_product character varying(15) NOT NULL,
    e_product_name character varying(150),
    n_qty integer,
    v_price numeric,
    e_remark text
);


ALTER TABLE public.tm_pembelian_item OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 17783)
-- Name: tm_pembelian_item_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_pembelian_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_pembelian_item_id_item_seq OWNER TO postgres;

--
-- TOC entry 3317 (class 0 OID 0)
-- Dependencies: 200
-- Name: tm_pembelian_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_item_id_item_seq OWNED BY public.tm_pembelian_item.id_item;


--
-- TOC entry 201 (class 1259 OID 17785)
-- Name: tm_pembelian_retur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_retur (
    id_document integer NOT NULL,
    i_document character varying(50),
    d_retur date,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone,
    id_customer integer NOT NULL,
    id_user integer NOT NULL
);


ALTER TABLE public.tm_pembelian_retur OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 17794)
-- Name: tm_pembelian_retur_id_document_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_pembelian_retur_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_pembelian_retur_id_document_seq OWNER TO postgres;

--
-- TOC entry 3318 (class 0 OID 0)
-- Dependencies: 202
-- Name: tm_pembelian_retur_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_retur_id_document_seq OWNED BY public.tm_pembelian_retur.id_document;


--
-- TOC entry 203 (class 1259 OID 17796)
-- Name: tm_pembelian_retur_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_retur_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    i_alasan integer
);


ALTER TABLE public.tm_pembelian_retur_item OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 17799)
-- Name: tm_pembelian_retur_item_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_pembelian_retur_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_pembelian_retur_item_id_item_seq OWNER TO postgres;

--
-- TOC entry 3319 (class 0 OID 0)
-- Dependencies: 204
-- Name: tm_pembelian_retur_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_retur_item_id_item_seq OWNED BY public.tm_pembelian_retur_item.id_item;


--
-- TOC entry 205 (class 1259 OID 17801)
-- Name: tm_penjualan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_penjualan (
    id_document integer NOT NULL,
    i_document character varying(50),
    d_document date,
    e_customer_sell_name character varying(120),
    e_customer_sell_address character varying(255),
    v_gross numeric,
    n_diskon numeric,
    v_diskon numeric,
    v_dpp numeric,
    v_ppn numeric,
    v_netto numeric,
    v_bayar numeric,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone,
    id_customer integer,
    id_user integer NOT NULL
);


ALTER TABLE public.tm_penjualan OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 17809)
-- Name: tm_penjualan_id_document_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_penjualan_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_penjualan_id_document_seq OWNER TO postgres;

--
-- TOC entry 3320 (class 0 OID 0)
-- Dependencies: 206
-- Name: tm_penjualan_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_penjualan_id_document_seq OWNED BY public.tm_penjualan.id_document;


--
-- TOC entry 207 (class 1259 OID 17811)
-- Name: tm_penjualan_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_penjualan_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    v_price numeric,
    v_diskon numeric,
    e_remark text
);


ALTER TABLE public.tm_penjualan_item OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 17817)
-- Name: tm_penjualan_item_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_penjualan_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_penjualan_item_id_item_seq OWNER TO postgres;

--
-- TOC entry 3321 (class 0 OID 0)
-- Dependencies: 208
-- Name: tm_penjualan_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_penjualan_item_id_item_seq OWNED BY public.tm_penjualan_item.id_item;


--
-- TOC entry 209 (class 1259 OID 17819)
-- Name: tm_saldo_awal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_saldo_awal (
    id_customer integer NOT NULL,
    i_periode character varying(6) NOT NULL,
    i_company integer NOT NULL,
    i_product character varying(15) NOT NULL,
    n_saldo integer
);


ALTER TABLE public.tm_saldo_awal OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 17822)
-- Name: tm_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_sessions (
    id character varying(128) NOT NULL,
    ip_address character varying(45) NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    data text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.tm_sessions OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 17830)
-- Name: tm_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user (
    id_user integer NOT NULL,
    username character varying(255),
    password character varying(255),
    e_nama character varying(255),
    i_level integer,
    f_status boolean DEFAULT true,
    f_allcustomer boolean DEFAULT false
);


ALTER TABLE public.tm_user OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 17838)
-- Name: tm_user_company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user_company (
    id_user integer NOT NULL,
    i_company integer NOT NULL
);


ALTER TABLE public.tm_user_company OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 17841)
-- Name: tm_user_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user_customer (
    id_user integer NOT NULL,
    id_customer integer NOT NULL
);


ALTER TABLE public.tm_user_customer OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 17844)
-- Name: tm_user_id_user_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tm_user_id_user_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tm_user_id_user_seq OWNER TO postgres;

--
-- TOC entry 3322 (class 0 OID 0)
-- Dependencies: 214
-- Name: tm_user_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_user_id_user_seq OWNED BY public.tm_user.id_user;


--
-- TOC entry 215 (class 1259 OID 17846)
-- Name: tm_user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user_role (
    id_menu smallint NOT NULL,
    i_power smallint NOT NULL,
    i_level smallint NOT NULL
);


ALTER TABLE public.tm_user_role OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 17849)
-- Name: tr_alasan_retur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_alasan_retur (
    i_alasan integer NOT NULL,
    e_alasan character varying(80) NOT NULL,
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_alasan_retur OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 17852)
-- Name: tr_alasan_retur_i_alasan_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_alasan_retur_i_alasan_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_alasan_retur_i_alasan_seq OWNER TO postgres;

--
-- TOC entry 3323 (class 0 OID 0)
-- Dependencies: 217
-- Name: tr_alasan_retur_i_alasan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_alasan_retur_i_alasan_seq OWNED BY public.tr_alasan_retur.i_alasan;


--
-- TOC entry 218 (class 1259 OID 17854)
-- Name: tr_company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_company (
    i_company integer NOT NULL,
    e_company_name character varying(30),
    db_user character varying(30),
    db_password character varying(60),
    db_address character varying(15),
    db_port character varying(8),
    db_schema character varying(30),
    db_name character varying(50),
    f_status boolean DEFAULT true,
    jenis_company character varying(20) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_company OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 17858)
-- Name: tr_company_i_company_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_company_i_company_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_company_i_company_seq OWNER TO postgres;

--
-- TOC entry 3324 (class 0 OID 0)
-- Dependencies: 219
-- Name: tr_company_i_company_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_company_i_company_seq OWNED BY public.tr_company.i_company;


--
-- TOC entry 220 (class 1259 OID 17860)
-- Name: tr_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_customer (
    id_customer integer NOT NULL,
    e_customer_name character varying(255) NOT NULL,
    e_customer_address character varying(255),
    i_type integer,
    e_customer_owner character varying(120),
    e_customer_phone character varying(120),
    f_pkp boolean DEFAULT false,
    e_npwp_name character varying(120),
    e_npwp_address character varying(120),
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_customer OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 17868)
-- Name: tr_customer_id_customer_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_customer_id_customer_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_customer_id_customer_seq OWNER TO postgres;

--
-- TOC entry 3325 (class 0 OID 0)
-- Dependencies: 221
-- Name: tr_customer_id_customer_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_customer_id_customer_seq OWNED BY public.tr_customer.id_customer;


--
-- TOC entry 222 (class 1259 OID 17870)
-- Name: tr_customer_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_customer_item (
    id_item integer NOT NULL,
    id_customer integer NOT NULL,
    i_company integer NOT NULL,
    i_customer character varying(15),
    i_area character varying(2),
    n_diskon1 numeric(4,2),
    n_diskon2 numeric(4,2),
    n_diskon3 numeric(4,2),
    f_status boolean DEFAULT true,
    e_customer_name character varying(250) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_customer_item OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 17874)
-- Name: tr_customer_item_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_customer_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_customer_item_id_item_seq OWNER TO postgres;

--
-- TOC entry 3326 (class 0 OID 0)
-- Dependencies: 223
-- Name: tr_customer_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_customer_item_id_item_seq OWNED BY public.tr_customer_item.id_item;


--
-- TOC entry 232 (class 1259 OID 40796)
-- Name: tr_customer_price; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_customer_price (
    id_customer integer NOT NULL,
    i_company integer NOT NULL,
    i_product character varying(15) NOT NULL,
    v_price numeric NOT NULL,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);


ALTER TABLE public.tr_customer_price OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 17876)
-- Name: tr_level; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_level (
    i_level integer NOT NULL,
    e_level_name character varying(20) DEFAULT NULL::character varying,
    f_status boolean DEFAULT true,
    e_deskripsi character varying(100) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_level OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 17882)
-- Name: tr_level_i_level_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_level_i_level_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_level_i_level_seq OWNER TO postgres;

--
-- TOC entry 3327 (class 0 OID 0)
-- Dependencies: 225
-- Name: tr_level_i_level_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_level_i_level_seq OWNED BY public.tr_level.i_level;


--
-- TOC entry 226 (class 1259 OID 17884)
-- Name: tr_menu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_menu (
    id_menu integer NOT NULL,
    e_menu character varying(30) DEFAULT NULL::character varying,
    i_parent smallint,
    n_urut smallint,
    e_folder character varying(30) DEFAULT NULL::character varying,
    icon character varying(30) DEFAULT NULL::character varying,
    e_sub_folder character varying(30) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_menu OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 40833)
-- Name: tr_panduan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_panduan (
    id integer NOT NULL,
    e_file_name character varying(150) NOT NULL,
    file_path character varying(150) NOT NULL,
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_panduan OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 40831)
-- Name: tr_panduan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_panduan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_panduan_id_seq OWNER TO postgres;

--
-- TOC entry 3328 (class 0 OID 0)
-- Dependencies: 233
-- Name: tr_panduan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_panduan_id_seq OWNED BY public.tr_panduan.id;


--
-- TOC entry 227 (class 1259 OID 17891)
-- Name: tr_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_product (
    i_company integer NOT NULL,
    i_product character varying(15) NOT NULL,
    e_product_name character varying(150),
    e_brand character varying(50),
    v_price_beli numeric,
    v_price_jual numeric,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone,
    e_product_groupname character varying(150) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_product OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17899)
-- Name: tr_type_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_type_customer (
    i_type integer NOT NULL,
    e_type character varying(80),
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_type_customer OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 17902)
-- Name: tr_type_customer_i_type_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_type_customer_i_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_type_customer_i_type_seq OWNER TO postgres;

--
-- TOC entry 3329 (class 0 OID 0)
-- Dependencies: 229
-- Name: tr_type_customer_i_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_type_customer_i_type_seq OWNED BY public.tr_type_customer.i_type;


--
-- TOC entry 230 (class 1259 OID 17904)
-- Name: tr_user_power; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_user_power (
    i_power integer NOT NULL,
    e_power_name character varying(30) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_user_power OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 17908)
-- Name: tr_user_power_i_power_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tr_user_power_i_power_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tr_user_power_i_power_seq OWNER TO postgres;

--
-- TOC entry 3330 (class 0 OID 0)
-- Dependencies: 231
-- Name: tr_user_power_i_power_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_user_power_i_power_seq OWNED BY public.tr_user_power.i_power;


--
-- TOC entry 2923 (class 2604 OID 17910)
-- Name: tm_pembelian id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_id_document_seq'::regclass);


--
-- TOC entry 2924 (class 2604 OID 17911)
-- Name: tm_pembelian_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_item_id_item_seq'::regclass);


--
-- TOC entry 2927 (class 2604 OID 17912)
-- Name: tm_pembelian_retur id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_retur_id_document_seq'::regclass);


--
-- TOC entry 2928 (class 2604 OID 17913)
-- Name: tm_pembelian_retur_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_retur_item_id_item_seq'::regclass);


--
-- TOC entry 2931 (class 2604 OID 17914)
-- Name: tm_penjualan id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan ALTER COLUMN id_document SET DEFAULT nextval('public.tm_penjualan_id_document_seq'::regclass);


--
-- TOC entry 2932 (class 2604 OID 17915)
-- Name: tm_penjualan_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_penjualan_item_id_item_seq'::regclass);


--
-- TOC entry 2937 (class 2604 OID 17916)
-- Name: tm_user id_user; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user ALTER COLUMN id_user SET DEFAULT nextval('public.tm_user_id_user_seq'::regclass);


--
-- TOC entry 2938 (class 2604 OID 17917)
-- Name: tr_alasan_retur i_alasan; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_alasan_retur ALTER COLUMN i_alasan SET DEFAULT nextval('public.tr_alasan_retur_i_alasan_seq'::regclass);


--
-- TOC entry 2941 (class 2604 OID 17918)
-- Name: tr_company i_company; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_company ALTER COLUMN i_company SET DEFAULT nextval('public.tr_company_i_company_seq'::regclass);


--
-- TOC entry 2945 (class 2604 OID 17919)
-- Name: tr_customer id_customer; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer ALTER COLUMN id_customer SET DEFAULT nextval('public.tr_customer_id_customer_seq'::regclass);


--
-- TOC entry 2947 (class 2604 OID 17920)
-- Name: tr_customer_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item ALTER COLUMN id_item SET DEFAULT nextval('public.tr_customer_item_id_item_seq'::regclass);


--
-- TOC entry 2952 (class 2604 OID 17921)
-- Name: tr_level i_level; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_level ALTER COLUMN i_level SET DEFAULT nextval('public.tr_level_i_level_seq'::regclass);


--
-- TOC entry 2965 (class 2604 OID 40836)
-- Name: tr_panduan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_panduan ALTER COLUMN id SET DEFAULT nextval('public.tr_panduan_id_seq'::regclass);


--
-- TOC entry 2960 (class 2604 OID 17922)
-- Name: tr_type_customer i_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_type_customer ALTER COLUMN i_type SET DEFAULT nextval('public.tr_type_customer_i_type_seq'::regclass);


--
-- TOC entry 2963 (class 2604 OID 17923)
-- Name: tr_user_power i_power; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_user_power ALTER COLUMN i_power SET DEFAULT nextval('public.tr_user_power_i_power_seq'::regclass);


--
-- TOC entry 3271 (class 0 OID 17760)
-- Dependencies: 196
-- Data for Name: dg_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 08:21:46.524823', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 09:47:44.620321', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 09:51:33.785461', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 09:52:47.39295', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 09:53:47.34405', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:00:35.696419', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:39:10.136008', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:39:41.70008', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:40:59.031685', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:42:32.969568', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:46:12.43713', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:46:15.094017', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:46:42.884737', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:47:05.50741', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:48:52.300637', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:50:23.562568', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:50:28.881992', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:50:29.507812', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:50:29.908624', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 10:50:30.17546', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:07.577835', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:09.458645', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:21.848547', 'Simpan Data Perusahaan : PT HARMONI UTAMA TEKSTIL');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:22.854699', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:24.559573', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:35.848385', 'Simpan Data Perusahaan : CV IMMANUEL KNITING');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:37.022604', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:38.607003', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:48.348478', 'Simpan Data Perusahaan : DIALOGUE GARMINDO UTAMA');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:10:49.293677', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:32:16.222554', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:32:30.85863', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:36:18.315408', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:36:25.857571', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:36:46.869347', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:37:17.868059', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:37:32.77581', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:40:25.297171', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:57:03.874175', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:57:08.242316', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:59:51.378023', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 11:59:55.688176', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 12:33:05.658441', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 12:33:09.423275', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 12:35:44.909585', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 12:37:10.528001', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:00:11.229475', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:01:22.422998', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:27:02.114191', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:27:05.975159', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:27:06.02699', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:28:06.073419', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:29:29.999933', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:29:56.926551', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:30:16.567804', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:32:04.974061', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:15.142338', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:17.123259', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:22.862324', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:22.90748', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:24.241531', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:29.274602', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:31.558091', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:47.022229', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:48.541444', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:33:56.479804', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:34:15.060549', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:34:16.188381', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:34:16.79764', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:37:23.329777', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:37:28.029398', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:38:15.277611', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:38:18.377243', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:39:16.236752', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:39:25.827789', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:40:46.745491', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:44:35.123734', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:44:36.94094', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:45:01.844666', 'Simpan Data Level : admin');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:45:12.000835', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:45:21.323927', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:45:26.365211', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:48:26.601193', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:48:28.763514', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:48:46.816394', 'Update Data Level : admin sales');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:49:24.400362', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:49:24.478424', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:49:27.749472', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:49:45.728223', 'Update Data Level : admin sales');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:50:58.839427', 'Update Data Level : admin sales ');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:51:00.283864', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:51:05.840383', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:51:15.697698', 'Update Data Level : admin sales A');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:51:16.491762', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:51:20.122064', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:53:53.228013', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:56:54.071409', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:56:57.273963', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:00.69685', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:07.167358', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:16.09279', 'Update Data Level : Admin');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:17.300074', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:32.022408', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:52.65187', 'Simpan Data Level : User');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:57:53.87007', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:59:40.282938', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 13:59:45.399995', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:01:39.836371', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:01:44.239936', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:01:46.7754', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:02:51.014673', 'Simpan Data Perusahaan : PT TEGAR PRIMANUSANTARA');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:02:52.325397', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:02:59.190586', 'Membuka Form Edit Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:03:03.989598', 'Update Data Perusahaan : PT TEGAR PRIMA NUSANTARA');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:03:04.904906', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:03:07.436922', 'Membuka Form Edit Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:03:13.889475', 'Update Data Perusahaan : PT TEGAR PRIMANUSANTARA');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:03:14.903988', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:04:00.878538', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:04:04.978305', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:04:17.600985', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:04:22.783029', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:07:29.189498', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:07:34.474323', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:07:37.309482', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:23:09.649927', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:23:22.096823', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:27:31.013728', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:30:44.498778', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:31:03.30166', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:36:35.436673', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:37:22.341925', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:38:15.581548', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:39:14.245991', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:39:59.50074', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:40:21.417471', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:42:15.998234', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:44:01.067221', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:45:28.816097', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:46:27.010717', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:48:56.327479', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:53:34.754162', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:54:06.963678', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:54:30.097223', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:54:49.187706', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:55:59.738666', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:56:19.393252', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:57:00.49055', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:57:33.476869', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:58:50.379032', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:58:57.371918', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 14:59:02.513178', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:01:00.572747', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:08:40.981508', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:08:59.87003', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:08:59.917142', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:09:44.185728', 'Simpan Data Menu : 804');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:09:45.421898', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:10:08.581343', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:17:52.166672', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:17:59.028442', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:19:18.527934', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:24:53.839375', 'Update Data Menu : 804');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:24:54.830523', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:25:09.535992', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:26:33.01997', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:27:34.347476', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:28:03.059951', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:28:26.828053', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:28:46.940617', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:29:31.044285', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:29:56.347838', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:29:58.88831', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:30:00.607148', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:30:02.437645', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:31:05.774834', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:31:20.791349', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:32:28.831753', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:33:22.772037', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:34:16.285552', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-05 15:34:51.299167', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:00:48.662637', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:02:47.302221', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:02:59.563964', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:03:08.159362', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:03:08.188347', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:03:18.175022', 'Update Data Menu : 102');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:07:10.613826', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:07:51.135405', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:07:54.501176', 'Membuka Form Tambah Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:07:59.770422', 'Simpan Data Tipe Toko : Baby');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:00.615543', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:37.194953', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:39.86224', 'Membuka Form Tambah Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:44.897419', 'Simpan Data Tipe Toko : Retail');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:45.597495', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:50.581408', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:08:50.638574', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:09:05.877727', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:09:14.430204', 'Update Data Menu : 103');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:09:15.499164', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:09:31.060157', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:09:31.112117', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:10:10.604851', 'Simpan Data Menu : 805');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:10:11.48994', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:10:32.893957', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:00.824293', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:05.684516', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:14.208197', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:18.062061', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:28.924968', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:28.982099', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:48.110723', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:11:52.454929', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:13:24.084442', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:13:24.180889', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:13:26.45011', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:14:11.150999', 'Simpan Data Menu : 804');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:14:12.265138', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:14:16.130127', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:14:28.548846', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:15:31.499149', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:15:31.527571', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:15:34.360387', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:15:36.90939', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:19:48.948948', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:19:51.032303', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:20:25.820531', 'Simpan Data Data Toko : Abadi Jaya');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:20:26.813671', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:22:55.957875', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:24:14.350433', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:24:40.984244', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:38:23.743048', 'Membuka Form Tambah Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:38:27.86215', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:39:38.278549', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:41:10.356188', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:42:37.519988', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:42:41.889708', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:06.015922', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:06.074051', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:13.996386', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:14.049042', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:24.306684', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:43:24.363786', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:44:47.099179', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:44:50.288666', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:44:58.176989', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:44:59.63136', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:45:05.344607', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:45:15.361527', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:45:15.405733', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:45:46.267077', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:45:59.638018', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:46:14.103529', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:46:25.456113', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:46:45.744111', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:46:53.186192', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:47:02.322507', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:47:21.568723', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:47:21.619403', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:47:37.554116', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:56:30.103007', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:56:36.174789', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:56:43.592416', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:56:48.076062', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 08:56:53.926699', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:00:02.721332', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:00:04.89922', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:00:37.670244', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:01:07.927585', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:01:38.692859', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:10:02.71187', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:13:26.416316', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:14:15.358137', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:14:32.063434', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:14:58.648732', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:23:26.702091', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:24:21.536689', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:24:30.666382', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:24:40.350307', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:31:09.040036', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:33:25.239343', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:43:44.164545', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 09:44:07.099697', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 10:01:21.613868', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 10:40:27.998284', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 10:51:25.96375', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 10:56:16.996593', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:15:48.725061', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:17:56.964246', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:20:27.112975', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:21:51.563618', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:23:34.717322', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:24:49.967982', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:26:35.525966', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:27:53.458206', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:31:02.382133', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:31:49.147236', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:41:49.995725', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 11:50:09.726576', 'Simpan Data Data Toko : Tester');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:00:07.871531', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:01:08.301449', 'Simpan Data Data Toko : Asd');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:03:37.759143', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:03:46.009638', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:04:47.1325', 'Simpan Data Data Toko : Coba Input');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:11:04.081551', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:11:07.258188', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:14:45.351033', 'Simpan Data Data Toko : Toko Afong');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:15:20.779117', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:16:59.290788', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:17:03.522444', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:18:04.553146', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:18:06.96942', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:18:07.000025', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:18:09.185789', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:19:07.450653', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:21:16.842809', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:21:16.879173', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:24:46.506688', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:24:48.033817', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:25:05.340771', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:26:16.010382', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:28:07.417983', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:28:11.805437', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:28:11.849148', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:28:14.960598', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:32:45.307509', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:32:47.160818', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:32:47.197637', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:41:07.411939', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:41:11.216402', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:44:06.073286', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:44:06.105377', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:44:08.313909', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:44:11.211764', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:44:46.448269', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:47:42.473082', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:48:24.224065', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:55:46.74315', 'Update Data Data Toko : Toko Afong');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:55:47.704806', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:55:55.460908', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:56:01.974981', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:56:19.761218', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:56:24.541674', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:56:24.583221', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-07 12:56:26.225231', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:04:30.350718', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:04:48.282539', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:04:57.287167', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:08.388303', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:11.650881', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:11.704236', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:13.467164', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:17.45476', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:23.816284', 'Membuka Form Tambah Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:25.71399', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:41.547672', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:45.207048', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:47.799229', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:05:49.818129', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:24:23.827727', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:24:31.288804', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:24:38.690384', 'Update Data Menu : 104');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:24:39.899117', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:25:19.933033', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:25:26.727145', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:31:16.607529', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:31:30.818162', 'Update Status User Login Id : 1');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:31:32.263111', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:32:14.694181', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:32:16.588607', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:33:39.752479', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:37:15.46025', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:37:44.290119', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:37:47.441795', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:38:47.872725', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:38:51.352933', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:39:27.820011', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:51:10.808538', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:53:17.636449', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:53:51.803688', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:54:05.282781', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:56:51.085829', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:56:51.15544', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:56:52.974031', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:58:25.168537', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:59:04.435375', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 08:59:17.324468', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:06:02.974502', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:06:33.830423', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:12:52.586075', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:13:41.891331', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:14:20.840549', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:14:34.561798', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:15:25.714814', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:15:42.805438', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:23:03.133206', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:23:42.673087', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:24:23.916878', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:24:56.850745', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:25:35.699593', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:26:07.150867', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:26:24.124222', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:26:37.71513', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:26:51.62203', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:29:03.787683', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:30:47.952496', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:31:10.840928', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:40:31.980188', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:40:34.166189', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:45:36.364574', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:49:01.39971', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:49:19.895073', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:50:05.0895', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:50:48.325161', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:51:18.085681', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:51:35.136062', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:52:58.214005', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:57:36.763166', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 09:58:10.082811', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:03:31.131217', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:07:09.904599', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:10:43.251336', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:16:35.94604', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:17:59.632977', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:19:22.123314', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:26:51.170888', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:27:11.061056', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:30:11.007444', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:35:16.316052', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:35:30.19898', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:35:43.836515', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:37:32.276283', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:37:55.906615', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:40:07.266798', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:42:42.709573', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 10:58:06.761284', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:00:47.040348', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:12:35.265213', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:27:11.047224', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:27:51.492124', 'Simpan Data User Login : ');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:29:33.215111', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:30:42.262721', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:31:14.539801', 'Simpan Data User Login : ');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:33:12.432491', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:33:49.19519', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (3, '::1', '2021-08-09 11:34:26.098964', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:34:45.004836', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:34:49.061929', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:34:57.278477', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:35:28.563757', 'Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:35:29.365025', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:35:58.269812', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:36:00.732345', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:36:02.282951', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:36:24.099775', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:36:35.946106', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:36:39.17911', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:37:46.385287', 'Simpan Data User Login : shelly');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:38:08.42078', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:38:29.068385', 'Update Status User Login Id : 4');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:38:30.405459', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:39:09.588973', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:40:39.999833', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:40:44.167904', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:40:49.499221', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:41:14.249073', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:41:16.549706', 'Update Status User Login Id : 4');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:41:18.015027', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:58:23.068172', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:58:26.116666', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:58:29.532853', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:58:31.071645', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 11:58:42.276442', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:34:51.898308', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:36:07.715472', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:37:28.839236', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:37:53.996126', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:37:56.863803', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:37:59.634767', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:39:03.357838', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:40:21.121415', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:41:04.985925', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:42:39.544733', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:44:21.829044', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:11.904933', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:15.731421', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:17.292799', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:17.33721', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:19.927359', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:45:21.615206', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:47:29.658594', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:41.860153', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:41.885238', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:43.986878', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:48.470597', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:50.939669', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:56.486142', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:56.527861', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:54:58.569705', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:55:32.711058', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 12:58:02.540712', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:36.939121', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:38.488879', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:39.888274', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:41.474111', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:41.522795', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:43.204537', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:44.438867', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:45.985809', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:56.789045', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:05:58.539412', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:16:41.224698', 'Update Data User Login : shelly');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:16:42.637039', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:16:59.478885', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:17:08.415964', 'Update Data User Login : shelly');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:17:09.519264', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:17:34.789362', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:18:35.701152', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:00.624424', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:04.144075', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:10.059539', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:18.961558', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:28.929183', 'Update Data Menu : 106');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:21:29.878651', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:24:47.36526', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:24:47.411124', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:24:53.683343', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:24:53.729571', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:28:34.518763', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:29:36.000525', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:29:43.231136', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:30:49.952819', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:30:58.855333', 'Simpan Data Alasan Retur : Barang Rusak');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:30:59.880663', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:31:04.663684', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:31:13.638569', 'Simpan Data Alasan Retur : Barang Tidak Laku-laku');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:31:14.744065', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:31:17.014043', 'Membuka Form Edit Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:32:16.921056', 'Membuka Form Edit Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:32:41.639657', 'Membuka Form Edit Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:32:48.503802', 'Update Data Alasan Retur : Barang Tidak Laku-laku Karena Mahal');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:32:49.464862', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:35:03.314434', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:38:01.508587', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:38:03.525934', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:13.35974', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:22.910867', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:34.332426', 'Update Data Menu : 105');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:35.223303', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:43.955171', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:47.883612', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:52.851035', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:40:54.998988', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:51:36.900788', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:52:16.784969', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:55:12.215482', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:55:27.15419', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:55:40.235583', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:55:57.57799', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 13:59:44.135554', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:00:04.169455', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:10:41.777264', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:13:29.086023', 'Simpan Data Product : dlk33000');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:13:29.868686', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:14:21.719557', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:17:36.402535', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:22:49.699045', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:23:01.201057', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:24:03.259076', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:26:19.084079', 'Simpan Data Product : lfm1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:26:19.886978', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:27:16.14825', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:00.026937', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:03.526543', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:29.42863', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:41.94377', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:44.55635', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:45.957198', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:29:47.042137', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:33:53.57178', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:33:57.130315', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:35:04.205855', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:35:08.262983', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:35:11.094299', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:35:12.957649', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:35:15.658272', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:40:48.33952', 'Update Data Product : LFM1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:40:49.644087', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:40:54.69384', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:41:19.62618', 'Update Data Product : LFM1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:41:20.4753', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:41:55.229835', 'Membuka Form Edit Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:42:05.387641', 'Update Data Product : LFM1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:42:06.209225', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:43:31.586378', 'Update Status Product Id : LFM1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:43:32.765892', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:43:34.744658', 'Update Status Product Id : LFM1001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:43:35.799755', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:21.16874', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:21.210542', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:23.578488', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:30.29572', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:44.746822', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:44.793798', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:54.400523', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:57:59.615947', 'Update Data Menu : 804');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:00.398719', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:07.792217', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:12.437467', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:20.623937', 'Update Data Menu : 804');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:21.426525', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 14:58:43.0922', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 15:13:01.863476', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-09 15:16:21.855074', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:04:23.996246', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:04:45.483955', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:05:07.227776', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:05:52.072706', 'Simpan Data Menu : 107');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:05:53.023468', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:06:04.996934', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:06:08.108048', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:06:14.578321', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:06:21.098294', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:06:21.156772', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:09:33.211787', 'Tranfer Data Product Id : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:09:34.41422', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:10:47.558919', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:12:15.023494', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:12:19.7419', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:12:19.782548', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:12:42.806973', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:14:48.654651', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:14:50.534705', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:22:44.149211', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:22:44.178185', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:23:52.795354', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:46:02.004891', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:46:03.652888', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:47:01.514568', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:47:03.396137', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:47:13.21866', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:47:14.820886', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:49:50.395333', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:49:57.236009', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:49:59.818949', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:51:25.728797', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:51:27.029248', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:53:36.455908', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:54:04.910743', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:55:36.856287', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:55:38.724453', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:55:47.098281', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:55:49.256979', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:58:44.263139', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:59:26.623483', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 08:59:46.719444', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:02:02.202089', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:02:23.855451', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:04:48.676803', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:06:40.111753', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:10:26.834445', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:10:57.758694', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:12:09.370352', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:13:04.298198', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:14:08.286197', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:15:06.563757', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:17:29.398608', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:22:13.359439', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:22:59.577225', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:23:57.09709', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:24:19.551138', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:24:43.178834', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:26:40.777937', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:27:15.791213', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:29:03.995715', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:29:50.105001', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:30:02.43168', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:30:22.758012', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:30:54.518516', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:31:17.382305', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:32:45.044112', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:33:11.061113', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:34:36.460824', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:35:07.19901', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:35:33.350592', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 09:59:10.562309', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:00:03.315406', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:00:31.67933', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:04:32.956888', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:05:35.784633', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:10.929149', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:18.611991', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:26.277245', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:27.374972', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:51.225232', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:07:52.991944', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:08:02.225345', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:08:38.455379', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:08:45.473756', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:08:48.467364', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:09:54.138625', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:24:08.975339', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:24:33.346174', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:24:45.364451', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:25:08.97484', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:25:17.443285', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:30:05.763339', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:33:17.668168', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:33:52.359729', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:35:15.768259', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:39:57.424101', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:40:45.700881', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:41:17.218026', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 10:41:43.527625', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:03:37.146241', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:04:33.940098', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:06:22.54225', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:07:22.562517', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:09:52.311205', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:10:31.358307', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:10:44.6013', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:12:21.191124', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:12:51.628783', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:17:04.605934', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:18:53.086747', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:20:09.431727', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:20:44.504632', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:21:28.892736', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:22:28.318168', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:23:23.783145', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:25:30.144791', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:29:52.231766', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 11:31:21.684811', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:00:56.807528', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:00:56.850865', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:00:59.236001', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:01:08.963028', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:01:11.04098', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:03:06.802362', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:03:31.350082', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:06:55.705436', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:10:02.653486', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:11:56.379854', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:13:29.179398', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:14:30.261768', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:14:43.944177', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:15:16.415509', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:16:04.226664', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:16:38.515391', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:19:36.576223', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:26:19.982292', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:29:25.569782', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:31:52.344057', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:35:24.260332', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:37:15.354229', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:37:48.874475', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:37:50.686912', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:38:19.617774', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:38:21.794228', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:38:34.170893', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:38:36.527472', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:39:17.386404', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:39:51.786241', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:40:10.601779', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:40:17.535341', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:40:55.35642', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:41:03.653941', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:41:06.88466', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:41:22.845917', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:42:45.827069', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:42:47.826358', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:42:50.867252', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:42:58.376834', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:43:00.509224', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:43:26.07306', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:45:52.205151', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:45:54.440791', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:46:02.689849', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:46:04.456754', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:47:08.80989', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:54:15.381349', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:54:34.950864', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:57:25.58418', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:58:56.383454', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:59:01.029194', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:59:30.020389', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:59:42.454162', 'Upload File Harga Barang, Id Company : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 13:59:44.43185', 'Membuka Form Detail Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 14:00:25.160085', 'Tranfer Upload Data Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-13 14:00:33.159425', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:04:31.52623', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:17.879744', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:24.041398', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:31.81725', 'Update Data Menu : 4');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:32.652009', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:35.738789', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:35.806715', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:07:38.470844', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:21:22.98193', 'Simpan Data Penjualan : BON-2108-000001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:21:24.96838', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:23:41.741036', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:30:01.259759', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:30:19.552414', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:31:44.2764', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:31:54.450127', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:32:59.511345', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:35:13.999286', 'Simpan Data Penjualan : BON-2108-000002');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:35:40.544291', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:37:05.528314', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:37:17.660324', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:37:55.441672', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:37:56.501138', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:39:29.443207', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:39:47.959908', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:40:02.936309', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:41:21.367814', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:41:38.494306', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:42:18.991083', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:42:22.079966', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:42:50.285282', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:47:21.327062', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:06.19748', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:38.372021', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:39.230215', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:39.848723', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:40.21436', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:49:40.543885', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:53:08.279215', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:53:26.842707', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:53:49.344856', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:55:40.696111', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 08:58:02.489768', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:06:27.794559', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:06:27.834102', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:07:47.566087', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:16:54.884845', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:17:03.647148', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:17:05.7638', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:17:47.916234', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:18:43.043418', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:34:16.321103', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:36:21.799818', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:37:45.824806', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:38:14.377516', 'Update Data Penjualan ID : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:38:15.486366', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:38:20.687468', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:39:39.515307', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:29.038257', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:40.101547', 'Update Data Penjualan ID : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:41.054741', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:43.646888', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:49.197124', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:51.39858', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:51.448197', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:54.961575', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:40:57.365377', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:43:36.330568', 'Update Data Penjualan ID : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:43:55.336004', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:43:57.986094', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:48:05.5275', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:49:51.664748', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:50:24.055397', 'Update Data Penjualan ID : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:50:24.775194', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:50:27.81514', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 09:53:38.752828', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:34:05.517514', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:34:25.547195', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:34:25.595168', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:34:32.838727', 'Update Data Menu : 7');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:34:33.631305', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:36:36.16364', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:37:13.276556', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:37:17.111419', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:37:21.30916', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:38:12.655857', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:38:57.286405', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:40:40.746626', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:40:56.033693', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:41:11.331279', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:47:33.334171', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:47:39.083305', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:47:39.107094', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:47:46.328125', 'Membuka Form Tambah Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:47:48.163213', 'Membuka Menu Power');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:50:18.038138', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:50:31.052574', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:50:33.570494', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:50:42.369251', 'Update Data Menu : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:50:43.952402', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:51:02.571264', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:51:05.652494', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 10:51:05.704635', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 11:02:57.289019', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 11:02:58.851046', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 11:03:00.010463', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:09:44.856094', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:09:59.353918', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:10:01.188229', 'Membuka Form Tambah Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:37:34.54943', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:37:37.108116', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:42:03.349093', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:42:14.360606', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 13:42:14.428714', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:14:53.898444', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:14:57.133746', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:21:24.096114', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:23:04.506171', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:23:35.793305', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:23:40.016407', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:24:34.729009', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:30:36.462866', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:38:27.61892', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:38:32.733746', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:41:44.801097', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:53:18.001287', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 14:55:19.77328', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:02:58.165488', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:07:54.427534', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:08:03.244252', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:08:07.596027', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:08:09.385005', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-19 15:08:09.445107', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:01:59.9233', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:03:16.13719', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:03:26.845686', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:03:28.678008', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:42.367682', 'Simpan Data Data Toko : Dialogue, TK');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:43.43503', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:47.819372', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:50.437219', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:50.486322', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:05:59.404635', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:06:00.438502', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:09:39.900022', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:09:46.360663', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:09:53.656838', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:09:53.706318', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:09:55.403725', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:11:34.08832', 'Simpan Data Data Toko : Dg');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:11:35.238048', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:11:40.057646', 'Membuka Form Edit Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:11:42.752351', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:14:30.648528', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:14:35.510971', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:17:13.499403', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:17:14.81714', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:18:19.994752', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:22:11.568572', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:22:12.832361', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:27:25.293386', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:27:25.331821', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:27:33.75421', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:30:21.009122', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:30:23.129815', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:39:55.809094', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:01.911144', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:19.500938', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:23.118312', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:26.687225', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:28.966509', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:40:58.227487', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:41:56.393764', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:42:00.828558', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:42:22.343477', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:42:24.004528', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:51:41.620662', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:51:41.64835', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:51:44.217467', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:51:44.284442', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:53:24.83422', 'Simpan Data Data Toko : Har');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:53:26.22808', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:54:15.993197', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:54:20.475513', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:54:38.079149', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:54:39.728485', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 08:54:59.958264', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:21.549672', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:22.746169', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:37.098087', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:37.148724', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:47.372362', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:03:49.656603', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:41:25.804167', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:04:02.938397', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:04:21.115998', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:04:23.096398', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:06:16.622393', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:06:16.704329', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:18.759757', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:18.818607', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:27.964094', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:31.58214', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:31.646973', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:34.863211', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:40:34.895827', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:41:46.677229', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:42:43.78975', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:42:52.540393', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:43:10.856549', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:43:12.988617', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:43:13.039915', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:56:26.40732', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:56:55.132844', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:57:19.774845', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 09:57:47.894451', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:02:02.630991', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:02:15.826091', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:02:50.42047', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:03:53.563833', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:04:27.206612', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:04:29.463143', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:05:49.616681', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:06:10.540269', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:06:13.726297', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:06:13.774637', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:08:18.989352', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:08:34.576859', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:08:46.590499', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:08:57.414888', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:08:57.458033', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:12:18.307623', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:12:18.409074', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:12:20.67316', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:13:29.31709', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:13:31.203316', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:15:08.655354', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:15:53.824606', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:15:59.832704', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:15:59.885561', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:04.382046', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:07.778359', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:09.461168', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:09.521761', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:28.083191', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:35.620451', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:16:54.756369', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:17:21.64912', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:20:38.879734', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:21:11.862261', 'Membuka Form Detail Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:21:30.813412', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:23:07.143182', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:23:07.175409', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:23:11.175932', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-21 10:23:11.242654', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:04:35.766889', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:05:05.045649', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:10:32.144051', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:11:11.508845', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:11:13.463629', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:12:53.289802', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:12:55.804194', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:13:26.351349', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:13:29.518061', 'Membuka Form Tambah Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:13:35.576263', 'Simpan Data Level : Spg');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:13:36.362769', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:13:43.109861', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:14:44.018302', 'Simpan Data User Login : spg');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:14:44.902272', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 08:14:57.873207', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:15:05.050191', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:15:08.915031', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:15:46.469414', 'Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:15:47.620904', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 08:15:56.194188', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 08:15:58.162934', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:16:51.112592', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:16:55.392036', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:16:58.143667', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:17:02.157627', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:17:05.223472', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:17:29.32566', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:20:23.983', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:20:25.80094', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:23:20.307131', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:23:23.49295', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:23:58.874049', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:25:19.234033', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:25:24.905734', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:25:27.018399', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:25:45.405469', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:25:57.073892', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:28:39.897153', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:28:42.349411', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:28:43.245434', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:29:47.105924', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:31:00.555859', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:31:06.603916', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:32:32.652622', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:32:46.670224', 'Membuka Form Tambah Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:32:55.866366', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:33:48.749605', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:35:40.527058', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:38:53.070931', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:39:30.062845', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:39:33.749301', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:39:46.082749', 'Update Data User Login : admin');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:40:04.526293', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:40:12.157695', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:41:28.688808', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:41:31.823582', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:43:05.859094', 'Membuka Form Tambah Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:44:34.450203', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:46:12.739379', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:46:15.560848', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:47:01.048039', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:47:14.041256', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 08:47:16.846362', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:00:55.094885', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:01:06.202388', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:02:04.154287', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:02:09.401002', 'Membuka Form Edit User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:02:15.514646', 'Update Data User Login : admin');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:02:16.470616', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:02:20.863997', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:03:19.679675', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:04:52.817258', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:02.776974', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:22.606732', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:24.328776', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:30.088016', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:32.108453', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:35.185547', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:37.125137', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:45.668626', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:55.786199', 'Cancel Pembelian Id : 38');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:05:56.815453', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:06:01.8366', 'Cancel Pembelian Id : 42');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:06:03.710283', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:06:53.832054', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:07:02.82745', 'Cancel Pembelian Id : 35');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:07:03.717749', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:07:11.366027', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:09:29.712141', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:18:39.756597', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:18:49.45211', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:18:54.516105', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:20:26.403232', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:20:31.623403', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:20:34.428648', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:24:05.420658', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:24:25.344731', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:24:48.015405', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:24:52.932732', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:25:21.105296', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:27:29.912585', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:27:37.291596', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:27:38.514507', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:30:29.365949', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:30:36.734305', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:31:20.462252', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:31:44.532383', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 09:33:23.391008', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:54:26.83565', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:54:28.148663', 'Membuka Form Tambah Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:56:47.543935', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:57:08.840616', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:57:20.359309', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:57:23.073855', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:58:31.920519', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:58:36.50587', 'Membuka Menu Update setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:59:42.749149', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:59:48.700817', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:59:56.145785', 'Update Data Menu : 3');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 09:59:57.15475', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:00:09.4349', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:11:06.698985', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:18:21.717876', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:18:24.648123', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:20:21.27753', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 10:20:34.56418', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:03:34.152024', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:04:29.461667', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:05:11.774022', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:05:16.276012', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:06:44.245557', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:07:09.040813', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:10:21.938227', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:11:19.407658', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:11:38.408852', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:12:37.840658', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:15:28.611423', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (5, '::1', '2021-08-23 11:15:42.476458', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:17:37.409217', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:17:48.076785', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:17:50.107199', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:17:52.592164', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:18:23.235445', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:18:27.86205', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:18:29.898142', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:19:39.724936', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:19:49.003762', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:19:53.205451', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:20:25.659244', 'Membuka Form Detail Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:20:31.972214', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:20:33.733542', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:23:16.694373', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:23:23.791935', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:23:27.292185', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:26:11.620786', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:28:31.495048', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:30:35.18974', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:30:49.455612', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:33:24.440154', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:46:59.28118', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:48:10.436323', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:48:27.018938', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:49:50.925287', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:51:13.733504', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:51:14.986889', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:55:57.528394', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:47:51.367907', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:56:08.694866', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:56:13.782021', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 11:56:16.243453', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:00:54.396246', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:39:15.514227', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:40:53.697641', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:43:41.148836', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:43:42.84624', 'Membuka Form Upload Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:43:51.684044', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:43:53.59697', 'Membuka Form Tambah User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:44:01.164539', 'Membuka Menu User Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:44:05.661881', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:44:07.033266', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:46:17.232679', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:50:54.935213', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:51:10.70905', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:51:43.396107', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:52:09.435139', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:55:35.225575', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 12:59:03.814153', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:00:23.695832', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:08:33.775845', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:09:08.362634', 'Simpan Data Retur Pembelian : RTR-2108-001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:09:09.493566', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:10:03.87693', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:10:28.830759', 'Cancel Retur Pembelian Id : 1');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:10:29.754843', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:15.354091', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:19.306029', 'Cancel Retur Pembelian Id : 1');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:20.199193', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:27.163792', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:34.856461', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:11:56.67218', 'Membuka Form Tambah Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:12:38.614814', 'Simpan Data Retur Pembelian : RTR-2108-001');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:12:39.702364', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:12:43.537631', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:16:40.951159', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:16:52.645494', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:17:10.463951', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:20:49.972488', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:23:54.066556', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:24:23.838481', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:29:35.376921', 'Update Data Retur Pembelian ID : 2');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:29:36.379864', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:29:39.199437', 'Membuka Form Edit Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:29:41.496471', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:29:55.619499', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:30:45.55916', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:31:09.105627', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:31:16.862669', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:31:25.478611', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:31:52.245914', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:32:05.794673', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:32:18.227856', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:34:53.113297', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:35:15.678656', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:36:49.92114', 'Membuka Form Detail Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 13:36:56.54912', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 14:37:22.742465', 'Membuka Menu Retur Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:04:12.069741', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:06:36.146463', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:11:23.767631', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:11:42.875406', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:13:27.114468', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:13:30.593105', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:19:42.960872', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:19:54.209093', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:19:55.909839', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:20:15.057687', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:20:17.543364', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:20:40.983844', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:20:55.438265', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:20:58.674433', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:21:44.648189', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:21:54.086459', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:21:57.754604', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:22:04.652438', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:24:43.623392', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:24:53.80951', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:24:57.294051', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:25:22.075732', 'Membuka Menu Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:27:29.05354', 'Membuka Form Tambah Alasan Retur');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-23 15:29:31.254103', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:05:06.191557', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:05:19.455761', 'Membuka Menu Panduan Manual');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:07:55.976718', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:12:37.246876', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:28:22.863035', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:29:22.876996', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:29:42.509928', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:29:51.870095', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:30:09.197571', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:32:12.152314', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:32:21.06721', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:32:36.40077', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:35:52.036265', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:35:54.048654', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:35:55.040806', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:36:04.724752', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:36:07.139345', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:36:08.947116', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:36:09.258944', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:36:23.847229', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:40:04.450832', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:50:44.417968', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:50:46.632309', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:51:55.380994', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:52:15.503833', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:56:20.502641', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:56:33.579567', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:56:56.961133', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:58:55.678428', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:58:58.228262', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:59:05.539198', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:59:28.08731', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 08:59:56.045336', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:03:29.662589', 'Membuka Menu Tipe Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:03:33.131547', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:03:44.88268', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:09:15.958708', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:09:17.380049', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:09:54.062706', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:14:58.2455', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:15:00.21886', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:15:15.12756', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:26:30.326051', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:26:36.445567', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:28:00.894234', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:29:10.832328', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:29:20.005188', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:29:23.219239', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:34:52.570752', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:34:54.622761', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:34:58.403367', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:35:01.104284', 'Membuka Form Edit Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:38:13.856205', 'Membuka Form Edit Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:38:47.351428', 'Membuka Form Edit Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:38:51.375813', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:40:17.090876', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:40:28.710294', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:40:37.85576', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:54:04.539533', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:54:20.262292', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:54:29.347225', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:54:38.370638', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:55:41.644728', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:55:57.776709', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:15.820346', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:17.12993', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:17.459343', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:39.92912', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:43.541678', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:56:48.890288', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:57:00.927686', 'Membuka Menu View setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:14.00528', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:16.302571', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:16.924731', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:17.197126', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:17.397226', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:17.551595', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:17.70395', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:17.844397', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:18.069663', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:58:58.384335', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:59:47.878478', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 09:59:57.151726', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:00:00.385977', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:00:49.331335', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:01:09.457492', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:03:11.606', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:03:30.054521', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:06:15.461528', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:08:48.88663', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:12:13.840945', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:13:22.04448', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:14:03.438833', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:16:08.528066', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:49:20.311862', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:50:03.901229', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:50:17.958952', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:50:19.786512', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:50:37.731479', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 10:51:01.570778', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 11:14:36.607141', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 11:14:42.886085', 'Membuka Form Edit Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 11:14:46.00019', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:31:48.755797', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:31:58.186104', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:33:58.703422', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:35:43.222616', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:35:48.903565', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:36:03.205914', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:36:28.782856', 'Membuka Menu Harga Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:36:42.170694', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 13:37:23.046627', 'Membuka Menu Product');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 14:53:00.860908', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-24 14:53:05.233175', 'Membuka Form Tambah Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 08:59:37.531997', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 09:00:00.677761', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 09:00:00.734936', 'Membuka Menu Dashboard');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 09:03:04.403947', 'Membuka Menu Perusahaan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 09:32:36.550372', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:15:20.647607', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:15:24.489665', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:15:34.409742', 'Membuka Form Edit Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:15:42.702215', 'Update Data Menu : 5');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:15:43.675193', 'Membuka Menu Menu');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:16:55.475443', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:32:17.107878', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:32:19.451349', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:33:36.166727', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:33:44.385629', 'Membuka Menu setting');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:33:57.99992', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:03.266639', 'Membuka Form Edit Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:13.666672', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:25.843588', 'Update Status Level Id : 1');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:27.161084', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:28.243558', 'Update Status Level Id : 1');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:34:29.642867', 'Membuka Menu Level');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:35:56.459477', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:36:54.605838', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:37:53.56829', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:37:55.709709', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:40:34.212322', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:40:40.947654', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:41:00.099033', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:41:22.472123', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:41:28.227261', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:41:35.696142', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:41:40.509104', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:43:04.164605', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:44:10.565809', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 11:44:22.35237', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:35:42.060773', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:35:58.82859', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:36:03.606701', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:39:16.263643', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:45:28.101418', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:45:45.259018', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:45:50.353872', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:47:08.33821', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:48:30.984188', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:49:01.597577', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:50:29.93163', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:51:32.8811', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 12:55:09.344831', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:03:05.755367', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:03:28.634538', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:15:45.176963', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:16:13.373047', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:16:32.110051', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:16:52.09932', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:17:00.517995', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:17:15.738495', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:17:24.347522', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:18:36.107055', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:19:11.964618', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:19:42.771423', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:19:48.331208', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:19:54.940363', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:20:19.594549', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:20:47.980335', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:20:59.125884', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:23:15.413874', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:34:44.286497', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:34:48.368401', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:34:52.295777', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:36:37.17535', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:36:42.625601', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:38:02.557612', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:40:47.346311', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:41:04.194018', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:41:18.976744', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:49:00.7566', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:49:40.198194', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:50:26.18469', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:50:38.617615', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 13:50:53.548341', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:15:01.484172', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:16:02.213604', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:16:25.908624', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:17:00.645944', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:17:50.277734', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:18:54.481672', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:19:06.804988', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:19:19.01079', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:19:40.369522', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:20:16.290039', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:20:30.51712', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:20:34.967486', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:20:59.346771', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:21:29.602444', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:21:55.599623', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:29:07.2564', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:29:20.073264', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:29:27.589268', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:29:40.640279', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:29:57.771084', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:30:18.605465', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:30:27.235008', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:30:32.202392', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:30:36.586943', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:30:45.735285', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:32:49.429652', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-25 14:33:43.411966', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:03.773538', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:12.619253', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:22.301985', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:28.419281', 'Membuka Menu Mutasi');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:47.751282', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:03:50.64799', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:03.637856', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:04.845933', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:21.964533', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:30.262812', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:31.426196', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:40.561676', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:45.692326', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:04:53.896276', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:02.242524', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:03.792731', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:22.417253', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:24.088684', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:39.777167', 'Membuka Form Tambah Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:55.817373', 'Simpan Data Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:05:57.150658', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:08:03.853617', 'Membuka Menu Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:08:09.217177', 'Membuka Form Tambah Data Toko');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 08:08:32.484172', 'Membuka Menu Pembelian');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 09:01:19.660015', 'Membuka Menu Penjualan');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-26 09:01:25.831413', 'Membuka Form Tambah Penjualan');


--
-- TOC entry 3272 (class 0 OID 17767)
-- Dependencies: 197
-- Data for Name: tm_pembelian; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3274 (class 0 OID 17777)
-- Dependencies: 199
-- Data for Name: tm_pembelian_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3276 (class 0 OID 17785)
-- Dependencies: 201
-- Data for Name: tm_pembelian_retur; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3278 (class 0 OID 17796)
-- Dependencies: 203
-- Data for Name: tm_pembelian_retur_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3280 (class 0 OID 17801)
-- Dependencies: 205
-- Data for Name: tm_penjualan; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3282 (class 0 OID 17811)
-- Dependencies: 207
-- Data for Name: tm_penjualan_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3284 (class 0 OID 17819)
-- Dependencies: 209
-- Data for Name: tm_saldo_awal; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3285 (class 0 OID 17822)
-- Dependencies: 210
-- Data for Name: tm_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_sessions VALUES ('4brhtgdq1fap6jd3k0pf2evlah38bdrh', '::1', 1628141910, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQxOTEwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('u01027rmin20tnop8qmocnl55cv03e7q', '::1', 1628138237, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM4MjM3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('2ijr8461ggs1nb4580pjnouqvoef1tso', '::1', 1628129427, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTI5NDI3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('kmmaejvgvodf1o6r5i4l4f4dvu7t5cgu', '::1', 1628135510, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM1NTEwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('gdq24db14eqabtro2nanefqflrv4o1tr', '::1', 1628130033, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTMwMDMzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('9k054onhfb8ql295r92tnf3kl1t7pvtn', '::1', 1628138734, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM4NzM0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('2emuh031lhiru28nvf5d1fqnuopdkg5q', '::1', 1628131437, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTMxNDM3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('ve59ar21qjc2lm0c8959lfr61cgaq9ug', '::1', 1628142282, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQyMjgyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('ccqv9pf5i6bvjsdsacfkcmgn1v3qtjv5', '::1', 1628476678, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc2Njc4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('qdcbr791rlahu24nsgscv52rlb5dqge1', '::1', 1628142903, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQyOTAzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('577done0fqq959tt082subkj04jnrtvt', '::1', 1628131893, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTMxODkzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('fvujo5vj58r2rm91m7kqak2t737uuui3', '::1', 1628143211, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQzMjExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('3sh6ckkq4ec3rucbo2mp488pbangjhrv', '::1', 1628139037, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM5MDM3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7');
INSERT INTO public.tm_sessions VALUES ('e412lufukkdiv7jhlb8j9fpvk1q2ke8a', '::1', 1628132435, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTMyNDM1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('itg4fein39eokgj4jk76ck00e4dpdhs1', '::1', 1628144338, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ0MzM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('imirft8usib3nt47k8opesncgsek1rjg', '::1', 1628135172, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM1MTcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('7qm0829rumjpk6ibjh52rue5bgjufrc3', '::1', 1628134750, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM0NzUwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('6j27f93sg46rck3msd5fr8q5ir3t2j9a', '::1', 1628144695, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ0Njk1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('mil13p9b2srl0n4rmmiju9rcsukhe2eo', '::1', 1628139411, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM5NDExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciOw==');
INSERT INTO public.tm_sessions VALUES ('o7qg8jhvgm8438ge4c4agutpr6ieji59', '::1', 1628136607, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM2NjA3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('d8f2pkevb5jvvkr828gb37tvgkn57n7l', '::1', 1628141556, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQxNTU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('orob2ck5n2e4vjchv139tqcpsbhc0h96', '::1', 1628137936, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTM3OTM2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('8arn56dlugq04g51uct2gcmberbgv1r2', '::1', 1628151472, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUxNDcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('lsemdar16p5ukvfpdfatr46fe81dlk1g', '::1', 1628146972, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ2OTcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('65tca4r29jtrgas46bofebm7iu46o9ue', '::1', 1628151809, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUxODA5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('dcb6pqjt8gs493arf0t94m6hp0vtfc77', '::1', 1628145443, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ1NDQzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('54gmujgu8jcijjleml3100gplafhived', '::1', 1628149335, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ5MzM1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('mllt9q9bk6fd5pt5a2uccmcjibcfih67', '::1', 1628145875, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ1ODc1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('bd9bq7k3k3v8cs9bdi9j7qf4fb42lbfo', '::1', 1628149736, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ5NzM2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('dtftq224u9l6c44oe0fkgn9tbtc9jf00', '::1', 1628150046, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUwMDQ2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('mg3sffh6tuq57c3ihnnnc54sikfmrj0r', '::1', 1628146260, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ2MjYwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('059imglsgam8a86mqcb0oqjtnl8qtmvu', '::1', 1628147356, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ3MzU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('sas8b8qmprjg7o14f2vaf7g9v3rv74dm', '::1', 1628144996, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ0OTk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('4m6mnqndk3vn48j3fnnn6d6b5iihaoav', '::1', 1628148186, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ4MTg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('u08odm42upbdjqfrgveumlme7felf86q', '::1', 1628152126, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUyMTI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('a5ng7ncgj1avv6bgv4vlb0bqfd2oanli', '::1', 1628148644, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ4NjQ0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('piu3qb2lt1p2ttcq6eksjqbo29u2dkqs', '::1', 1628148995, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ4OTk1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('90og6ist8spmsf8civmg77n0i7hsarj1', '::1', 1628146614, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTQ2NjE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('8tm0qi49mnu8aih621nnj7ehliioqvhh', '::1', 1628152456, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUyNDU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('nr3ni3rgf8466gs18hf35ivankmf5t4u', '::1', 1628150460, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUwNDYwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('p8la33725k8492dg4hs2rb5c9us806r5', '::1', 1628152491, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUyNDU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('5itqpi5pd2pdr16g550qqptcsjph8q0i', '::1', 1628150920, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MTUwOTIwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('pjo7du4j4f962cdhqg8fbfs9sho71185', '::1', 1628308285, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA4Mjg1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('80i03s0hb26cg23t47ugabidqgkk3m82', '::1', 1628300604, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAwNjA0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('u9egm3v8mjk5o24t7lo4dvb05oj61nlt', '::1', 1628308633, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA4NjMzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0gn4maol6epcd8fh5spfomsle3p2ovjg', '::1', 1628309748, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA5NzQ4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('hq4e5ocr193nlghvra8e8ardd0a0rsel', '::1', 1628304224, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA0MjI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('5m158128k23v4gv6vdvbomoeg64078qk', '::1', 1628476143, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc2MTQzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('btf275rgnfkgs2rvb18lsdt84e5rj2v9', '::1', 1628298430, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4Mjk4NDMwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('mef2o22chp16gqrcpod3hmghj65o2c9c', '::1', 1628301698, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAxNjk4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3b2du4dcc3f64hervnpjo84iu4os1u7e', '::1', 1628305281, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA1MjgxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('lo3pads01oj3v8054brmr281ou3olc6g', '::1', 1628302202, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAyMjAyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('7i68s40vfs8fah4misc7726t762atpqa', '::1', 1628301390, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAxMzkwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('o1m3msanul35pkp85bl4p46levksu5i1', '::1', 1628298800, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4Mjk4ODAwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('7a2d2vnvs1c9bp2eiv7db06kp1oriiv2', '::1', 1628307627, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA3NjI3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('69d3l71djq0clvrabhgs2qu61a72iu88', '::1', 1628310111, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEwMTExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('j3hcokt02087v47clkt5og4p4s72ck6l', '::1', 1628303006, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAzMDA2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('p9a178lbjf6s57mt88vafnvb12nnqmvu', '::1', 1628299188, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4Mjk5MTg4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('bg40u6v9i0a41kc0jgaqg8cl2s71vgrt', '::1', 1628307984, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzA3OTg0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('6bnhnh5c8tcv4qko1p1cq00qvoffgims', '::1', 1628303469, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAzNDY5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8vur84hgcsus631bru2qt2pilsgmflif', '::1', 1628300303, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzAwMzAzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('lrv73fhrjsb4sm09mr9ctk35mqcjjtrm', '::1', 1628310473, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEwNDczO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0fjogjm7hed8p5vs9kht09lv0qsi21bp', '::1', 1628311805, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzExODA1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('v42ben56fpt1tngah9s61l4le1hk3fe9', '::1', 1628474762, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc0NzYyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('pbd426rube2t2m7blpa1phb1storooet', '::1', 1628475172, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc1MTcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3hhebo5b3516ieqtfjuf898ttd45islj', '::1', 1628315578, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzE1NTc4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('6ir5ma1lb5svmpo0adb2aomc0mv9st3b', '::1', 1628311309, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzExMzA5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('fnnsu9qf2flv4fpvh9d0gql1ehq1hbbb', '::1', 1628475776, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc1Nzc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('9vuimpujoudlofkum2i56cabe6ij6r7u', '::1', 1628488049, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg4MDQ5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('hvrmam7m4oifho6eir52eulfebnair39', '::1', 1628315786, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzE1NTc4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('rmpkq27hfpdqbvg6tge18th7pq3vamcn', '::1', 1628472263, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDcyMjYzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3lls8t4qd0okdpaj7jle1a3tqf925t29', '::1', 1628312358, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEyMzU4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('bft8elhjrt8utb6ntu6j1ivu7kdc5m8o', '::1', 1628313414, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEzNDE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ct11vri0pbs95lnpktjhq9r4e94n1vej', '::1', 1628314365, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzE0MzY1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('j2nv411j0p061aeccagfhbvnkhrqo2u5', '::1', 1628313886, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEzODg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('d15hsakt09qtsmhc5i9em2snlqc3b190', '::1', 1628472676, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDcyNjc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('s21k2o3krh283o2jb0i9njtvn733bavn', '::1', 1628315262, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzE1MjYyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('th5067f924nbcp6orp383hb8lmi17f3g', '::1', 1628314867, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzE0ODY3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('1jtnn7opb6d1d1leih6nkao8vsupopo2', '::1', 1628473035, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDczMDM1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('a6gkc5i43ctnhkbim0ffa4eml2fio6su', '::1', 1628473870, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDczODcwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('24jtj46cttil9m2vja2v4ms79jd14v34', '::1', 1628313064, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MzEzMDY0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('89ajl9f5468nbkon0gle16si9aokt45k', '::1', 1628474211, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc0MjExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('90a2ioa27l4av7o519ru7j5f6h1pkinq', '::1', 1628480562, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgwNTYyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('bu696slp823s4nko3iuvevuphmttdgfu', '::1', 1628488481, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg4NDgxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('fega883npsc44cf9gmpt5lq16155osnv', '::1', 1628483910, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgzOTEwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('i4f0qme2968dbsl2n6pol2ftofktgvgi', '::1', 1628478211, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc4MjExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('nr1rg6qcfjqcb5jvdhshtc3b77r682aj', '::1', 1628478643, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc4NjQzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('9vtbqg3f2g6usgkjrtrci5acbd8phlr6', '::1', 1628477136, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc3MTM2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('d10qscincblib5i34k2h8be62i17otdl', '::1', 1628481486, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgxNDg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('mp130r8f7ol88rtqp8a44bv2qlk595uo', '::1', 1628485094, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg1MDk0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('e9idu5882ourn5ulhu5ikm43dtcg1b8f', '::1', 1628477448, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc3NDQ4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('62gppif1317d29h33ma0h9n5qeevfdra', '::1', 1628487291, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg3MjkxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('n5590o6h9p0c6rlaa3h31cmi0cp4vpnm', '::1', 1628478995, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc4OTk1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('ldjfq4h86ehr5nrfplbf66dsgresf3ja', '::1', 1628482355, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgyMzU1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('mg8acedj1at5a495cd35po4vjp2giqb9', '::1', 1628479611, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc5NjExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('2r28ip0poi008mlp50daadl0mstjd45s', '::1', 1628477856, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDc3ODU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('a055m3ghh1htgehbag84lvhevfrrvva6', '::1', 1628487621, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg3NjIxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('hoi0kpcc46vogomtm5957kph0s04kij8', '::1', 1628483231, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgzMjMxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('ohcr6jsg4366qrqgf7ol8k0pvehpl8si', '::1', 1628483592, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgzNTkyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('dridr6e237e1cp73c2bs57hn78ij4icu', '::1', 1628480116, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgwMTE2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('4iqtj7d03lhpdjeotmv7citbv9ugs5jg', '::1', 1628483740, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDgzNjU2O2lkX3VzZXJ8czoxOiIzIjtlX25hbWV8czoxMDoiQWxnaGlmZmFyeSI7dXNlcm5hbWV8czo1OiJhbGdoaSI7aV9sZXZlbHxzOjE6IjMiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ionrrvcfb0014f3ph9tp66mah7jt7tuc', '::1', 1628490903, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkwOTAzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('0apd48h91g2plukj9dc23cl62bn6qvev', '::1', 1628494827, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk0ODI3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('l97tdk27d3eu6i6rt458a8ijoga95t09', '::1', 1629510701, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTEwNzAxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('g7ck09o6o0tihfqac4gvifae0m0r37us', '::1', 1628491213, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkxMjEzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('s0kd5p82h4rlfhmq49qp5iblva5tlk0p', '::1', 1628489136, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg5MTM2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('c6autst1t3smainsfs7rij372j572gj4', '::1', 1628495841, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk1ODQxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('c91bb32n038erd60jo9ngt51jlsrii8k', '::1', 1628491896, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkxODk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('md7ns06q105rt0nevhk0lvmhmasrt15v', '::1', 1628492384, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkyMzg0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('ns16f5o44bun0uvp86o95td0g6islrha', '::1', 1628489719, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDg5NzE5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('tnjl66lkip4qfu4im0t990b3c78jiqnd', '::1', 1628493041, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkzMDQxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('rgibrekcdh4tr8ptokftlsvssmhqk83s', '::1', 1628496781, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk2NzgxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('i8tc3hpa8ffnn5q8q87hek750n3apevv', '::1', 1628493456, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkzNDU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('l7ntqech1qt8idos9igd1qa4rlqnsh0u', '::1', 1628490060, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkwMDYwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('0bpb698d972d5k0o46gsd1svdq5vn4vq', '::1', 1628497095, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk3MDk1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('213nh7oeg3tf5h36m8mer83t5q21ljg3', '::1', 1628493769, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkzNzY5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('33as0dhjf270e2g72ftip1l1p9529e30', '::1', 1628497526, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk3NTI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('g18f61gkj1r37e7pk62f82sp57ingcd4', '::1', 1628490514, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDkwNTE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('014nud3nf0dj8t9m9h72o4spp0nqa1ng', '::1', 1628494140, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk0MTQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('kv464r5nt9heguedlcb12436a79dq16h', '::1', 1628494504, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk0NTA0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('e7l2l703rsih7vf78f2ab7sockafku79', '::1', 1628823550, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIzNTUwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('jsqbunbkp26opa8g2r6qso80acfk0bpn', '::1', 1628498108, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk4MTA4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('et2kugb8f9is753ij1u3cdr5gfq6i03a', '::1', 1628823872, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIzODcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('a1feb5cn58ng49bgeu67o4vv3b9o5uh7', '::1', 1628498182, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4NDk4MTA4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('fsfls2k6foebg4uovgq195jkqgoikffv', '::1', 1628819486, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE5NDg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('a2o67jl6h0f8d57b8gl8ulpd4etguk4v', '::1', 1628820288, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIwMjg4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8mfvn071svju18d2kdke362pvlqjoq1o', '::1', 1628819924, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE5OTI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('11qp7tlnh4dnme0kf744uidh3fcegge0', '::1', 1628824193, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI0MTkzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ohogkmtv59vkee6g69v7cs1j9i6tk35g', '::1', 1628816883, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE2ODgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('rpv8ph26c47hgicjo2kg5oq1ktdqr5u9', '::1', 1628820626, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIwNjI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('niqifjbop19oaumgrq9e1ri2of5lim7m', '::1', 1628825048, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI1MDQ4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3db7ullmbelakiqcn3ea176bde90bu2n', '::1', 1628817718, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE3NzE4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4pd4ouojedilqfbefr4e9mvbn3986pq9', '::1', 1628825404, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI1NDA0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('cp9lqq74q1hk8accc5u16s3vm4joiv5n', '::1', 1628821049, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIxMDQ5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('sbravi0kajo8olo9m22jsu04b8783emo', '::1', 1628825714, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI1NzE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('n91c648k7qeb8ba1d22ikfok6rvgi61i', '::1', 1628821379, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIxMzc5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('f8n96d7iq4gqjt81s8e3uc7gfk9felmi', '::1', 1628821743, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIxNzQzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('5qbp35hr80l4hrrg5ra6fmv5s8ufsomc', '::1', 1628817288, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE3Mjg4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('2ih1rvucc8gekc8v1l5aonvusneq7grg', '::1', 1628822076, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODIyMDc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0tq5rb84jp8j6q6snml8o9eboqju2og5', '::1', 1628819124, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODE5MTI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ea22hob17oep0v3p93ve15q56pfufhhc', '::1', 1628826044, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI2MDQ0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('03vdi0s6uuj2kblkfv3peio5j783lsa9', '::1', 1628827416, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI3NDE2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('9m8j1thlm0hn7oiamu0pfipqbl0hml41', '::1', 1628828991, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI4OTkxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('6ad6ma2l4m03k2kh606cgs8drpsp8vor', '::1', 1628827791, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI3NzkxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ulf42d00daoaeqj2688avm95en3ffol7', '::1', 1628834447, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM0NDQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ped86qra4somc8105k4lp2ktm1phc9vq', '::1', 1628837654, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM3NjU0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('rm5qa12fht4nspb9g030aqm00rann0gu', '::1', 1628828223, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI4MjIzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('vftefrvi5sd5etrjifkb05qlit82m2ob', '::1', 1628834814, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM0ODE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('nggei5mfk25c2d10c5h5lo1p2bk954d9', '::1', 1628835115, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM1MTE1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('c6ua61r18m0l9oq3eo622mgpdokl31uj', '::1', 1628828547, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODI4NTQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('s1jvu9ked8o822umqo139j3i836mv20m', '::1', 1628835575, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM1NTc1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('bshq7n15jag70idoiugjht0p5msahd0r', '::1', 1628835976, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM1OTc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('sq70d7qiut4b77qfrf2trcllrif89jcu', '::1', 1628837969, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM3OTY5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('lvc3q1totr54derdnohfqivtj9aeh9j1', '::1', 1628836311, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM2MzExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('n30npv52ndtvdpt9q1jrgkkh6n19s8rj', '::1', 1628836634, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM2NjM0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('prqhfrtn0b3jbkhgmpr41l22l2pkr8q2', '::1', 1628844194, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ0MTk0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4mfd1kutjljp0dpik2953n3pn9gjhkpm', '::1', 1628844533, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ0NTMzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4vbqd5p7lgp691h5i7q08q8l6gje3duf', '::1', 1628844837, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ0ODM3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('g6it9m477cd0s464do35qrob9gs8og6i', '::1', 1628845142, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ1MTQyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0ng9f0hp3e8dd7ekoi7qtfmnqggpkuck', '::1', 1628836965, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODM2OTY1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8au82jv6hfrnddco2cu2vbkb3n19087c', '::1', 1628845628, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ1NjI4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8asg1jv6pkird6ab4032etbh0vcbnv0h', '::1', 1628845630, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4ODQ1NjI4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0fuuattra51nb00ogat6hnsl82dpe0u5', '::1', 1629685445, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg1NDQ1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('jmfm76qv2emhuv37jfbgq2vqfve6841a', '::1', 1629337641, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM3NjQxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('hhj9cfpl3a91i41d93g2rdf2m15clhue', '::1', 1629340456, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQwNDU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('jh2ksou57ashtrnkfn9cjn4kqdf4ns8f', '::1', 1629337988, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM3OTg4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0on1lcs0pou3jkf3hos2b4jfnkitomh9', '::1', 1629335335, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM1MzM1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('0vfvrmlnq8mcklku1qgomesh7pgf8suk', '::1', 1629336084, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM2MDg0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('52pa0oufqpnp7i77uf23t94r5pfn854b', '::1', 1629340779, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQwNzc5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('j92j53h0bkhmo9ffbkdr6svv85tfr90q', '::1', 1629336601, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM2NjAxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('htip5kkmfpj03vpsrbijape4ep335bis', '::1', 1629341111, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQxMTExO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8kjgt8ia0ho6o2ar0l4269faee6s4639', '::1', 1629341424, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQxNDI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('fih8tkr5gg148339u5k57j6trdbv44vd', '::1', 1629336940, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM2OTQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('85u1qgj7jrh3u1pflt8obkuumsfv8for', '::1', 1629342086, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQyMDg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ds7a9reb1ahdlrp0phm0hjklg8i9l7hg', '::1', 1629344045, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQ0MDQ1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('7suqet7930s3ltgetgfabqse1nql63de', '::1', 1629338787, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM4Nzg3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('p5p9gadmrs5eetrepbu3ngr0v2v62tlu', '::1', 1629337281, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM3MjgxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('99mt06cuqoiqjmb0ea07ekskp78q6qen', '::1', 1629339414, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzM5NDE0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('sk6g0la27gmhvkot09598d6jk4vtsosi', '::1', 1629344440, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQ0NDQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('oj3nntk0acgd31f4v6pqr01o9hht3tqq', '::1', 1629344853, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQ0ODUzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4rdrqlgh5u0ltqlh3882p3e5705pdrcf', '::1', 1629345780, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQ1Nzc3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('t8bsvf780frgpv601bp3j0v01pgpomlr', '::1', 1629681026, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgxMDI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('n62uic7616jckpm903apnflardagbgge', '::1', 1629511066, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTExMDY2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('1shcnm6bgkgfie2262vl488cusvggtjd', '::1', 1629345777, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzQ1Nzc3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('duapme0eiu6qrpa7g2lk2s3vib35soji', '::1', 1629508179, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTA4MTc5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('rhp6o1bf7v2vi9eflbu7dskbnee43vn4', '::1', 1629355054, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU1MDU0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('r4fdpinc5404am0qdrdanirqdoqglncs', '::1', 1629684356, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg0MzU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('s17mj4ebonbdoihcqioqsfhldirlbdsl', '::1', 1629357293, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU3MjkzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('ik949j99ur9d25qcc481d4moo3g1qbn4', '::1', 1629508499, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTA4NDk5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3mjl0hsf2ks05079fth8g70i1p159o2i', '::1', 1629357683, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU3NjgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('0hti40jc1guom8g7213i535gg08og2b5', '::1', 1629509245, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTA5MjQ1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('1vr0crgs63f40o6loecsbd67dvnj5o3e', '::1', 1629508932, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTA4OTMyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('5igb7e7irvaijnlg1ohhkrnv3rktu25q', '::1', 1629358236, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU4MjM2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('gn1ifqkmdr2f086lrevv2f5pr71sf2pn', '::1', 1629509995, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTA5OTk1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('vknrem3qnptb13u186fdm30lur2objlr', '::1', 1629358707, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU4NzA3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('erl5q16ic3l3q5892pfm7psv6dja7e88', '::1', 1629359597, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzU5NTk3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('gaf6l13qjrb35moau3jeskctaegsf8jt', '::1', 1629360178, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzYwMTc4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('7ha0hbol9tp21ps67e635l73vbigt5dk', '::1', 1629360483, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzYwNDgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('g760k39f1v0u3hqsoj6inqm9bkh6stnl', '::1', 1629360489, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5MzYwNDgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('ipqjbt5rvs76n3j00k21prtdcudb1i3q', '::1', 1629682428, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgyNDI4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('revfpatb9puhfkdf9l78u3m8rn6nkecv', '::1', 1629685657, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg1NjU3O2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('jsqi35938s6tepm5tvb52qtla2tafcnd', '::1', 1629692142, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkyMTQyO2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('uj4l3fuu0pmv6inqq14c5odh2h4q3chh', '::1', 1629511402, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTExNDAyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ub30al876o9fsapq5mh28trfrm2l29f5', '::1', 1629516191, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE2MDM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('afts0aotv4huccltrpfc2vc5bsl475nc', '::1', 1629682733, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgyNzMzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('htpi0a49ji4s0asu8ml6okfvb0sae06n', '::1', 1629514586, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE0NTg2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('50v7jueo3h3sjeaedsp92g4mslhdvs2r', '::1', 1629513618, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTEzNjE4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ukhp02k9asadtldintutek91u91p2o8r', '::1', 1629681347, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgxMzQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('4aq3um0n9b9mkq9hifg00okluqcregn7', '::1', 1629683172, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgzMTcyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('rs3ds8jerfm5lnidisben6m4vjoglqaq', '::1', 1629514922, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE0OTIyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('lfgi1c9mgqe6ples05b59p55kuarn6f1', '::1', 1629684055, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg0MDU1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('3e3tsvgv1u2fn1b6hmvbn3v0as4n6fqg', '::1', 1629684066, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg0MDY2O2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('spt26s570cfampobc8a4f7ajml8ou1sq', '::1', 1629681800, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgxODAwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('gkconjdp4hpk1350g4cdqfjlsceo1734', '::1', 1629515298, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE1Mjk4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('q5nbu1l5r2p6pca5lsutpg3690pj161u', '::1', 1629682119, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjgyMTE5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjE6IjIiO2VfY29tcGFueV9uYW1lfHM6MjQ6IlBUIEhBUk1PTkkgVVRBTUEgVEVLU1RJTCI7Y29sb3J8czo2OiJpbmRpZ28iOw==');
INSERT INTO public.tm_sessions VALUES ('8c14tteka4i8sknkormb8d999kga3l9q', '::1', 1629685119, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg1MTE5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('7vhutkkeuebc732080ka7arc1rcrb48v', '::1', 1629515609, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE1NjA5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('pvgt8g7og94vin3753k71d42t8erjsrn', '::1', 1629685231, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg1MjMxO2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('72gfjof1cqhfbn6j5o63vcb9fnip5v96', '::1', 1629516038, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NTE2MDM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('d2vu5epgf7bvod6sis3u5lk03042827r', '::1', 1629685829, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg1ODI5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4phchei3jj7b9rhaanalb3njiukr5fr0', '::1', 1629692128, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkyMTI4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('19fdld482gmvrh0kr91d1pidpvn986kh', '::1', 1629686003, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg2MDAzO2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('bdmdq0cvasaaqvku3n78stgh7gn96dnc', '::1', 1629692142, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkyMTQyO2lkX3VzZXJ8czoxOiI1IjtlX25hbWV8czozOiJTcGciO3VzZXJuYW1lfHM6Mzoic3BnIjtpX2xldmVsfHM6MToiNCI7Rl9zdGF0dXN8czoxOiJ0IjtGX2FsbGN1c3RvbWVyfHM6MToiZiI7aV9jb21wYW55fHM6MzoiYWxsIjtlX2NvbXBhbnlfbmFtZXxzOjExOiJBbGwgQ29tcGFueSI7Y29sb3J8czo1OiJzbGF0ZSI7');
INSERT INTO public.tm_sessions VALUES ('7pb53msobs67528esk41nclh3h6qg51i', '::1', 1629687266, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg3MjY2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('juj3t8enq3intbdjbmpd10qe50olfi8p', '::1', 1629697155, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk3MTU1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('h38edvq5s10b27n930rvisd1k9ub8mqn', '::1', 1629692431, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkyNDMxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjE6IjQiO2VfY29tcGFueV9uYW1lfHM6MjM6IkRJQUxPR1VFIEdBUk1JTkRPIFVUQU1BIjtjb2xvcnxzOjY6ImluZGlnbyI7');
INSERT INTO public.tm_sessions VALUES ('1heb3l7ja99nb64qri0cauvgp5hgg315', '::1', 1629692771, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkyNzcxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('1ki8npdsohm5t1ol385httm26kpf4ipm', '::1', 1629687582, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg3NTgyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('mgc8g7d5dginhi44m7v295j7k1m0q1tm', '::1', 1629688266, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg4MjY2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('a0nhe83gghqnhjqducf8lsj7it94q80t', '::1', 1629693204, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkzMjA0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('5kon67uhh00h85mqug764n644j5f2lnr', '::1', 1629688701, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njg4NzAxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('sh5miujq8aeorirb7p251gkl91uq472m', '::1', 1629693919, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkzOTE5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('gsug76kl6gs13f8shtd2shlpvreajgc5', '::1', 1629691390, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkxMzkwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjE6IjMiO2VfY29tcGFueV9uYW1lfHM6MTk6IkNWIElNTUFOVUVMIEtOSVRJTkciO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('33ms6bl1gvo9ab0nn0shqooeeqd9qei5', '::1', 1629697577, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk3NTc3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('mri4vpr42lkkrfs1mdhhnkbksn6i1vqo', '::1', 1629697903, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk3OTAzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('el7898tsemb4p83eer9kdqttsp8l3746', '::1', 1629691821, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NjkxODIxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('qaqjsshobb514c6kd2ii6c1okfkirvif', '::1', 1629694273, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk0MjczO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('4gh2m1agm41872j99odmsddgati7ai4g', '::1', 1629698343, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk4MzQzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('upcsqiuq0vhjtho7677afo72nvbaompi', '::1', 1629694576, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk0NTc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('hjs04lb5vdvcg9d71d7tqiticlopk7mo', '::1', 1629705744, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA1NzQ0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjk6ImluZG9uZXNpYSI7');
INSERT INTO public.tm_sessions VALUES ('udhihe3rokcna76fc2u64227itf09nhh', '::1', 1629705325, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA1MzI1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjc6ImVuZ2xpc2giOw==');
INSERT INTO public.tm_sessions VALUES ('se6a7in157pfdc4dmeavvk5k3vt5vj8a', '::1', 1629698824, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk4ODI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('291fmu1nprkcf2uob03gm3tqf6jh7f75', '::1', 1629706283, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA2MjgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjc6ImVuZ2xpc2giOw==');
INSERT INTO public.tm_sessions VALUES ('vcs621lgbgffrqqhpd8jm02dj5p6593m', '::1', 1629706782, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA2NzgyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjc6ImVuZ2xpc2giOw==');
INSERT INTO public.tm_sessions VALUES ('bofl8q4oblu5rncll5dhj3vqgrtj59ve', '::1', 1629707083, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA3MDgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjk6ImluZG9uZXNpYSI7');
INSERT INTO public.tm_sessions VALUES ('map7lq6egpkorktailv6tkns8kkp7vq4', '::1', 1629707371, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA3MDgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjtsYW5ndWFnZXxzOjk6ImluZG9uZXNpYSI7');
INSERT INTO public.tm_sessions VALUES ('c9kdma70t87nroj5107o8b9vkdkmtstr', '::1', 1629699159, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk5MTU5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('2dhg2pe6srblv2kqm6634uvdar85gh0o', '::1', 1629699649, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Njk5NjQ5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('78uinh7f3mnstufadnubvvki76h7h37d', '::1', 1629767557, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY3NTU3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('g5idgrg8uci104teuepr72dui6410l26', '::1', 1629700176, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzAwMTc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('8i8311vnp82a3rabpdt28ag557932keq', '::1', 1629767881, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY3ODgxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('f7cst3ftp1lq0fuvia5gc7rgsjfe1vvv', '::1', 1629768183, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY4MTgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('hnksbc8uf143stf2clm7k3c35i2gammb', '::1', 1629700493, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzAwNDkzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('ungmpn1iss3mn05kkst3kkm091qcedr1', '::1', 1629704205, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA0MjA1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('e3e76s6s57lvpgcmoems7o5mm7rug7mo', '::1', 1629704538, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA0NTM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('1sao8hhob98ftq6h2dp77nvs3u0ff8jh', '::1', 1629704900, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzA0OTAwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjIiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NjoiaW5kaWdvIjs=');
INSERT INTO public.tm_sessions VALUES ('gcp9ec78i52elsahus9v7hm84jp3f3eo', '::1', 1629768492, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY4NDkyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('f25nif45udg7md5i3dpl9qaa85s0ifl9', '::1', 1629768952, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY4OTUyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('bjuktaupikdb61b6k0mn9csuob0ukau3', '::1', 1629773938, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzczOTM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('co6uaojta1urtkabgvnm7q79kuecs38e', '::1', 1629769671, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzY5NjcxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('sn82qj85n5o2egdm2fmcptvp177ml0u1', '::1', 1629774375, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc0Mzc1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('cqc5bpdfk4aioqrgp47qiutbhlb8ovbn', '::1', 1629770180, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcwMTgwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('a2bd425ke44jukp8rod245idq4562t9o', '::1', 1629774733, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc0NzMzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('cqsgf0qj1td95mmc99b5ouatvged9h3n', '::1', 1629770609, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcwNjA5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('obqkr7c135rlskv4vaegpmuo9enrbpcp', '::1', 1629776224, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc2MjI0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('gfgq8n54u2b1e392sj2kvudst2h1fk9b', '::1', 1629775203, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc1MjAzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('2q7g7ppu7jdcb62c4ka57205taflp0v2', '::1', 1629776940, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc2OTQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('vqfkiqgde68hq8cmbd4uh88g6rcl5brq', '::1', 1629770955, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcwOTU1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('n83jsqdfpdm01jgdr4dt9r939gb0b9f9', '::1', 1629771298, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcxMjk4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('1ignr8fqna9djvs8n4jctcqv5hgea9sg', '::1', 1629777285, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc3Mjg1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('koi0rlvpc4dr371goacn0thsae958k65', '::1', 1629771990, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcxOTkwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('295npq0ja2dt3ea8go96sqstq2v2pm6n', '::1', 1629772492, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcyNDkyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('k9f87vdenjqqdcpf7p0bv94lplbumj39', '::1', 1629777696, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc3Njk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('gpfr4e9mfl2k2b1mongbsnnn3t6t8djt', '::1', 1629772817, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzcyODE3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('cg6ibul8mmi1ol5hb1sse9b5rukr6vif', '::1', 1629773631, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzczNjMxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('ln8k3g770a787slt88ccgrbm5k0vpdkh', '::1', 1629778476, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzc4NDc2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('48nc8ddged7t84ppvabeou0oct6qoa62', '::1', 1629787601, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg3NjAxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('egtrbj1716q2r0s1kh1vse0910oqniai', '::1', 1629783335, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzgzMzM1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('p5sqojllpgrf1bgnu788eo05njtp0b2e', '::1', 1629791580, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzkxNTgwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('va60ip3hp8is9q8idcj0rnndh3un7jki', '::1', 1629781249, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzgxMjQ5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('2l6i1fu663c1clvig3j2is34sipsc5do', '::1', 1629793726, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzkzNzI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('3omr4rk11uu2tupb9tjionb83ujeca69', '::1', 1629793727, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzkzNzI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('d0eif2so7pd1j0v6rap2lpap9h4b0lf8', '::1', 1629782996, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzgyOTk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('fgkoodfh6bup8df3untubniip8s5bcht', '::1', 1629858756, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODU4NzU2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('dcncu7u3msfdv6316fu8m0uk48kg4uvl', '::1', 1629783942, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5NzgzOTQyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('ekhvf819gdecnvkjnvfsghdl29ure8lb', '::1', 1629864920, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODY0OTIwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('7qv962g4lmdoesht6hj82kvanlnsooge', '::1', 1629784530, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg0NTMwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('9ml6fi7qqdccusbqqvr5eloru1d4jof6', '::1', 1629784851, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg0ODUxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('i6r97rpdbkoua5j1t916daror0r1lopv', '::1', 1629785199, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg1MTk5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('7blr61clu61j8jj9qek614lo61rkrium', '::1', 1629786138, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg2MTM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('1a8iiglg1ljrf3ro8koj6aooc5798sd0', '::1', 1629785791, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg1NzkxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('n2g2mf0jepdg0g0b3ms6qucvaf5skkbl', '::1', 1629786440, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg2NDQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('4acqk4kib42r9qpglac50ttbt9vogb56', '::1', 1629786838, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5Nzg2ODM4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('4fr4a9jfcb85u5d7emn2tl4cq7v79c3l', '::1', 1629865937, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODY1OTM3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('qdhediqb5iov193cv19153o2kpc7nvtt', '::1', 1629872447, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODcyNDQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('s2et8d5kse4usb99bltq2k4886nonjio', '::1', 1629873284, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODczMjg0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('84bs2sb0olvhp76ie75fecpe2ra2e9gd', '::1', 1629940083, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5OTQwMDgzO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('k5b21pjvtmcksns6sk6piemgb8b0o1gj', '::1', 1629870328, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODcwMzI4O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('p77hbln5b1sobafle4f05959llbvg0gb', '::1', 1629873647, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODczNjQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('ttdbq1q6i0j2se95ooip4jo7d4lnocan', '::1', 1629874140, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc0MTQwO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('t5v0dcs90l5qhlo3pm3po3tpsjgo97kd', '::1', 1629875701, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc1NzAxO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('anbegerblpqa5t89sgh5vl6tp6fjj04o', '::1', 1629866273, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODY2MjczO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('b3bu1no4qlokc1pk5j78m86kn780d1f3', '::1', 1629876016, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc2MDE2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('757vh817pep6jub90pa75bh7rr077klh', '::1', 1629869742, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODY5NzQyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('41okj79r8m4c276i1a4b9s8v13bfa2mn', '::1', 1629866584, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODY2NTg0O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('lpsdtt8psivr8f11cq4cu37jh0fqb3b3', '::1', 1629876547, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc2NTQ3O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('ecrh91meuqqbkhmsdsl2btu2voie68bt', '::1', 1629870629, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODcwNjI5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('pfq806q21k5l8lv3ljudhahu8rcv1qat', '::1', 1629872145, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODcyMTQ1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('6gnu95m1sirv6q0j27opaul95kv01ndt', '::1', 1629871385, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODcxMzg1O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('8vi4njnfvbobmctqns3u56rnvsehj1qm', '::1', 1629878332, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc4MzMyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6OToiaW5kb25lc2lhIjs=');
INSERT INTO public.tm_sessions VALUES ('77c900fhaejkm40ctdaral188f6qpnns', '::1', 1629878332, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5ODc4MzMyO2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToiYnJvd24iO2xhbmd1YWdlfHM6NzoiZW5nbGlzaCI7');
INSERT INTO public.tm_sessions VALUES ('6jodsqojpq2c7hevicll66lcn5n64a2p', '::1', 1629943279, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5OTQzMjc5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('e9k5qkngvn6altqoghb6tflr664krjs6', '::1', 1629946796, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5OTQ2Nzk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('kqj2kll9jirmo30t7d0hb6e65vne3i7b', '::1', 1629946796, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI5OTQ2Nzk2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6InQiO2lfY29tcGFueXxzOjM6ImFsbCI7ZV9jb21wYW55X25hbWV8czoxMToiQWxsIENvbXBhbnkiO2NvbG9yfHM6NToic2xhdGUiOw==');


--
-- TOC entry 3286 (class 0 OID 17830)
-- Dependencies: 211
-- Data for Name: tm_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user VALUES (2, 'herdin', 'UnIzamE2SGZaVVNTcEErOTY3RUFQZz09', 'Herdin Nur Rahma', 2, true, true);
INSERT INTO public.tm_user VALUES (3, 'alghi', 'U095Y3lxRFJYVXlVUWpITVQ5ZmZ5dz09', 'Alghiffary', 3, true, true);
INSERT INTO public.tm_user VALUES (4, 'shelly', 'U0RWWi9jL3lEOWtpMWhiUm94djBNQT09', 'Shelly Nur Hadijah', 3, true, true);
INSERT INTO public.tm_user VALUES (5, 'spg', 'MlNXQTRMLzg0WmE0VEhRMWNSUkJ0QT09', 'Spg', 4, true, false);
INSERT INTO public.tm_user VALUES (1, 'admin', 'bmp2UkEvZndvUEZ4ek1VTndQRS9EZz09', 'Administrator', 1, true, true);


--
-- TOC entry 3287 (class 0 OID 17838)
-- Dependencies: 212
-- Data for Name: tm_user_company; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user_company VALUES (2, 4);
INSERT INTO public.tm_user_company VALUES (3, 2);
INSERT INTO public.tm_user_company VALUES (3, 3);
INSERT INTO public.tm_user_company VALUES (3, 5);
INSERT INTO public.tm_user_company VALUES (4, 2);
INSERT INTO public.tm_user_company VALUES (4, 5);
INSERT INTO public.tm_user_company VALUES (4, 4);
INSERT INTO public.tm_user_company VALUES (5, 2);
INSERT INTO public.tm_user_company VALUES (5, 3);
INSERT INTO public.tm_user_company VALUES (5, 4);
INSERT INTO public.tm_user_company VALUES (5, 5);
INSERT INTO public.tm_user_company VALUES (1, 2);
INSERT INTO public.tm_user_company VALUES (1, 3);
INSERT INTO public.tm_user_company VALUES (1, 4);


--
-- TOC entry 3288 (class 0 OID 17841)
-- Dependencies: 213
-- Data for Name: tm_user_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user_customer VALUES (5, 1);
INSERT INTO public.tm_user_customer VALUES (5, 6);


--
-- TOC entry 3290 (class 0 OID 17846)
-- Dependencies: 215
-- Data for Name: tm_user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user_role VALUES (101, 1, 1);
INSERT INTO public.tm_user_role VALUES (101, 2, 1);
INSERT INTO public.tm_user_role VALUES (101, 3, 1);
INSERT INTO public.tm_user_role VALUES (1, 2, 1);
INSERT INTO public.tm_user_role VALUES (0, 2, 1);
INSERT INTO public.tm_user_role VALUES (8, 2, 1);
INSERT INTO public.tm_user_role VALUES (801, 1, 1);
INSERT INTO public.tm_user_role VALUES (801, 2, 1);
INSERT INTO public.tm_user_role VALUES (801, 3, 1);
INSERT INTO public.tm_user_role VALUES (802, 1, 1);
INSERT INTO public.tm_user_role VALUES (802, 2, 1);
INSERT INTO public.tm_user_role VALUES (802, 3, 1);
INSERT INTO public.tm_user_role VALUES (802, 4, 1);
INSERT INTO public.tm_user_role VALUES (803, 1, 1);
INSERT INTO public.tm_user_role VALUES (803, 2, 1);
INSERT INTO public.tm_user_role VALUES (803, 3, 1);
INSERT INTO public.tm_user_role VALUES (803, 4, 1);
INSERT INTO public.tm_user_role VALUES (102, 1, 1);
INSERT INTO public.tm_user_role VALUES (102, 2, 1);
INSERT INTO public.tm_user_role VALUES (102, 3, 1);
INSERT INTO public.tm_user_role VALUES (102, 4, 1);
INSERT INTO public.tm_user_role VALUES (103, 1, 1);
INSERT INTO public.tm_user_role VALUES (103, 2, 1);
INSERT INTO public.tm_user_role VALUES (103, 3, 1);
INSERT INTO public.tm_user_role VALUES (103, 4, 1);
INSERT INTO public.tm_user_role VALUES (104, 1, 1);
INSERT INTO public.tm_user_role VALUES (104, 2, 1);
INSERT INTO public.tm_user_role VALUES (104, 3, 1);
INSERT INTO public.tm_user_role VALUES (104, 4, 1);
INSERT INTO public.tm_user_role VALUES (0, 2, 3);
INSERT INTO public.tm_user_role VALUES (2, 2, 3);
INSERT INTO public.tm_user_role VALUES (3, 2, 3);
INSERT INTO public.tm_user_role VALUES (4, 2, 3);
INSERT INTO public.tm_user_role VALUES (5, 2, 3);
INSERT INTO public.tm_user_role VALUES (7, 2, 3);
INSERT INTO public.tm_user_role VALUES (106, 1, 1);
INSERT INTO public.tm_user_role VALUES (106, 2, 1);
INSERT INTO public.tm_user_role VALUES (106, 3, 1);
INSERT INTO public.tm_user_role VALUES (106, 4, 1);
INSERT INTO public.tm_user_role VALUES (105, 1, 1);
INSERT INTO public.tm_user_role VALUES (105, 2, 1);
INSERT INTO public.tm_user_role VALUES (105, 3, 1);
INSERT INTO public.tm_user_role VALUES (105, 4, 1);
INSERT INTO public.tm_user_role VALUES (804, 1, 1);
INSERT INTO public.tm_user_role VALUES (804, 2, 1);
INSERT INTO public.tm_user_role VALUES (804, 3, 1);
INSERT INTO public.tm_user_role VALUES (107, 1, 1);
INSERT INTO public.tm_user_role VALUES (107, 2, 1);
INSERT INTO public.tm_user_role VALUES (107, 3, 1);
INSERT INTO public.tm_user_role VALUES (4, 1, 1);
INSERT INTO public.tm_user_role VALUES (4, 2, 1);
INSERT INTO public.tm_user_role VALUES (4, 3, 1);
INSERT INTO public.tm_user_role VALUES (4, 4, 1);
INSERT INTO public.tm_user_role VALUES (7, 1, 1);
INSERT INTO public.tm_user_role VALUES (7, 2, 1);
INSERT INTO public.tm_user_role VALUES (7, 3, 1);
INSERT INTO public.tm_user_role VALUES (7, 4, 1);
INSERT INTO public.tm_user_role VALUES (2, 1, 1);
INSERT INTO public.tm_user_role VALUES (2, 2, 1);
INSERT INTO public.tm_user_role VALUES (2, 3, 1);
INSERT INTO public.tm_user_role VALUES (2, 4, 1);
INSERT INTO public.tm_user_role VALUES (2, 1, 4);
INSERT INTO public.tm_user_role VALUES (3, 1, 4);
INSERT INTO public.tm_user_role VALUES (4, 1, 4);
INSERT INTO public.tm_user_role VALUES (0, 2, 4);
INSERT INTO public.tm_user_role VALUES (2, 2, 4);
INSERT INTO public.tm_user_role VALUES (3, 2, 4);
INSERT INTO public.tm_user_role VALUES (4, 2, 4);
INSERT INTO public.tm_user_role VALUES (5, 2, 4);
INSERT INTO public.tm_user_role VALUES (7, 2, 4);
INSERT INTO public.tm_user_role VALUES (2, 3, 4);
INSERT INTO public.tm_user_role VALUES (3, 3, 4);
INSERT INTO public.tm_user_role VALUES (4, 3, 4);
INSERT INTO public.tm_user_role VALUES (2, 4, 4);
INSERT INTO public.tm_user_role VALUES (3, 4, 4);
INSERT INTO public.tm_user_role VALUES (4, 4, 4);
INSERT INTO public.tm_user_role VALUES (3, 1, 1);
INSERT INTO public.tm_user_role VALUES (3, 2, 1);
INSERT INTO public.tm_user_role VALUES (3, 3, 1);
INSERT INTO public.tm_user_role VALUES (3, 4, 1);
INSERT INTO public.tm_user_role VALUES (5, 1, 1);
INSERT INTO public.tm_user_role VALUES (5, 2, 1);
INSERT INTO public.tm_user_role VALUES (5, 3, 1);
INSERT INTO public.tm_user_role VALUES (5, 4, 1);


--
-- TOC entry 3291 (class 0 OID 17849)
-- Dependencies: 216
-- Data for Name: tr_alasan_retur; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_alasan_retur VALUES (1, 'Barang Rusak', true);
INSERT INTO public.tr_alasan_retur VALUES (2, 'Barang Tidak Laku-laku Karena Mahal', true);


--
-- TOC entry 3293 (class 0 OID 17854)
-- Dependencies: 218
-- Data for Name: tr_company; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_company VALUES (2, 'PT HARMONI UTAMA TEKSTIL', 'dedy', 'g#>m[J2P^^', '202.150.150.58', '9191', NULL, 'harmoni', true, 'produksi');
INSERT INTO public.tr_company VALUES (3, 'CV IMMANUEL KNITING', 'dedy', 'g#>m[J2P^^', '202.150.150.58', '9191', NULL, 'imma', true, 'produksi');
INSERT INTO public.tr_company VALUES (4, 'DIALOGUE GARMINDO UTAMA', 'dedy', 'g#>m[J2P^^', '202.150.150.58', '9191', NULL, 'dialogue_new', true, 'distributor');
INSERT INTO public.tr_company VALUES (5, 'PT TEGAR PRIMANUSANTARA', 'dedy', 'g#>m[J2P^^', '202.150.150.58', '9191', NULL, 'tegar', true, 'produksi');


--
-- TOC entry 3295 (class 0 OID 17860)
-- Dependencies: 220
-- Data for Name: tr_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_customer VALUES (1, 'Abadi Jaya', 'jalan rengas dengklok', 1, 'mariani', '', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (2, 'Tester', 'testetes', 1, 'asdas', '423423423423', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (3, 'Asd', 'asd', 1, 'asd', '4234', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (4, 'Coba Input', 'asdasdadasdadasdasd', 2, 'asdsad', '34234', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (5, 'Toko Afong', 'adasdadasd', 1, 'asdasdd', '4234234', false, 'asdasdasdasd ', 'asdasdadad lkjfl j lajlajdlajdlakjdlakjd', true);
INSERT INTO public.tr_customer VALUES (6, 'Dialogue, TK', 'jalan dialogue', 1, 'dialogue', '', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (7, 'Dg', 'jalan jalan', 1, 'dg ner', '', false, NULL, NULL, true);
INSERT INTO public.tr_customer VALUES (8, 'Har', 'jln', 2, 'a', '', false, NULL, NULL, true);


--
-- TOC entry 3297 (class 0 OID 17870)
-- Dependencies: 222
-- Data for Name: tr_customer_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_customer_item VALUES (1, 3, 2, '508', NULL, 0.00, 0.00, 0.00, true, NULL);
INSERT INTO public.tr_customer_item VALUES (2, 3, 5, '508', NULL, 0.00, 0.00, 0.00, true, NULL);
INSERT INTO public.tr_customer_item VALUES (3, 4, 4, '00000', '02', 0.00, 0.00, 0.00, true, '( 00000 ) - TEST');
INSERT INTO public.tr_customer_item VALUES (4, 4, 3, '00000', '02', 0.00, 0.00, 0.00, true, '( 00000 ) - TEST');
INSERT INTO public.tr_customer_item VALUES (5, 4, 2, '00000', '02', 0.00, 0.00, 0.00, true, '( 00000 ) - TEST');
INSERT INTO public.tr_customer_item VALUES (10, 5, 5, '1743', '0', 10.00, 0.00, 0.00, true, '( 00006 ) - PADASUKA JAYA , CV ');
INSERT INTO public.tr_customer_item VALUES (11, 5, 4, '00036', '00', 0.00, 0.00, 0.00, true, '( 00036 ) - YOGYA (A.YANI/PAHLAWAN)');
INSERT INTO public.tr_customer_item VALUES (12, 5, 2, '432', '00', 10.00, 0.00, 0.00, true, '( 00007 ) - CITRA JAYA (JKT)');
INSERT INTO public.tr_customer_item VALUES (13, 5, 3, '1481', '02', 0.00, 0.00, 0.00, true, '( 00006 ) - BIN''S COLLECTION');
INSERT INTO public.tr_customer_item VALUES (14, 6, 4, '02604', '02', 5.00, 0.00, 0.00, true, '( 02604 ) - SEMARANG');
INSERT INTO public.tr_customer_item VALUES (15, 6, 4, 'H5808', 'H5', 0.00, 0.00, 0.00, true, '( H5808 ) - ISTANA BABY');
INSERT INTO public.tr_customer_item VALUES (16, 7, 4, '23412', '23', 0.00, 0.00, 0.00, true, '( 23412 ) - ISTANA BAYI  ARIFIN AHMAD ');
INSERT INTO public.tr_customer_item VALUES (17, 7, 4, '15038', '15', 3.00, 0.00, 0.00, true, '( 15038 ) - SINAR BAHAGIA');
INSERT INTO public.tr_customer_item VALUES (18, 7, 4, '11164', '11', 10.00, 0.00, 0.00, true, '( 11164 ) - AUDREY');
INSERT INTO public.tr_customer_item VALUES (19, 8, 2, '1107', '18', 10.00, 0.00, 0.00, true, '( 18041 ) - BABY STAR (SMD)');
INSERT INTO public.tr_customer_item VALUES (20, 8, 2, '985', '23', 10.00, 0.00, 0.00, true, '( 23023 ) - 24/WTO (MKS)');
INSERT INTO public.tr_customer_item VALUES (21, 8, 2, '1099', '23', 10.00, 0.00, 0.00, true, '( 23025 ) - NAWIR (MKS)');
INSERT INTO public.tr_customer_item VALUES (22, 8, 2, '985', '23', 10.00, 0.00, 0.00, true, '( 23023 ) - 24/WTO (MKS)');


--
-- TOC entry 3307 (class 0 OID 40796)
-- Dependencies: 232
-- Data for Name: tr_customer_price; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ADDH001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ADDH002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AHDH001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'APDH004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VDT1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSC1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMA1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMA1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPK001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPB012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPB017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1365', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1362', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1304', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1376', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1372', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1385', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPB007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MBA0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICBJR09', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJMC006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICBJC10', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJMK005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJMR004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBK004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK033', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBB004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBB002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBB005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBB001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBK005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGB024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKPC003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKPC004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLK001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLB001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLK003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKPC005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLB003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKPC002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLK005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLB005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLK002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLB002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLK004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBLB004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKPC001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CKNOD01', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICKNO01', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK036', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB036', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK034', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB034', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBK003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK035', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB035', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB033', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBK001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICPPS07', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICDDS08', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CPNPD06', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICPNP06', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CPRPD05', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICPRP05', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CDNOD02', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICDNO02', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CDRPD04', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICDRP04', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CDROD03', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICDRO03', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBK002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDBB003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPK008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KDPB008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DBS0043', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB6050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB3020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB3010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMB2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DBS0042', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DBS0041', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CBDI007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ABE1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB2577', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB2810', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK092', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB1500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4901', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB4500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB5000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMB7500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2503', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2501', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4891', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AKB1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AKB1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF01363', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1363', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF1306', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1306', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF01324', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1324', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF01395', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1395', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF01332', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1332', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LF01311', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFO1311', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFF1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFF1801', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KHB1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KHB1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KHB1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFD1713', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFD1791', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFD1702', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFD1774', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1912', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1994', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1991', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1953', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2041', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2042', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB090', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'BA01062', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1428', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK093', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK033', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPK004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK084', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACT1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACT1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPK018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'BP07800', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CV00180', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACR1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACR1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACR1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACR1014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK094', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK034', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB096', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK107', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB125', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK109', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB109', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK124', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK119', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB119', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK112', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB112', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB124', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK118', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB118', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK125', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK108', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB108', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PDC0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK034', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK095', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB097', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK091', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK035', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK036', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB036', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CLE1080', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICE1060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB098', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK038', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB038', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT3014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT2012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AFT2011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFF1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFF1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFF1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB091', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTGK028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB092', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPK007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB099', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPB011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1523', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1525', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1526', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1751', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ATE2011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1609', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4950', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTP002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2901', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GTL0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GTL0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTP001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GTL0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GTL0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GTL0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMG2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMG2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMG1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMG1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1241', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTT7195', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1750', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2412', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH1500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DKL0111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1752', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1749', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1751', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1748', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB093', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB033', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HCSN400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB094', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB034', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB095', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JJE0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JJE0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JJE0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JJE0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JJE0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK039', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB039', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ICBJH11', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJSH003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJSK002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CJSS001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JKMK07', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JKMKP07', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'K151011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKS1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1580310', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMR0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMB0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMB0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMB0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMB0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'K156046', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1562620', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMC1562', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1519190', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1522100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1580300', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '153400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1522300', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1560380', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1510310', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1510271', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1562610', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1562600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1560370', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMR0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1560390', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, '1522310', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'K000013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'K000011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'K000012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLH0080', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAV1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KKH4203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JKMKP06', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JKMKP05', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'JKMKP03', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TMK0077', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KBP0838', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLHP004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4931', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLHP008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTJ200', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLHP009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTJ100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLP1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTP003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLTH009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTR0101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTR0103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTR0104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTR0102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4909', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4919', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4920', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTU0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KYPS001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMK1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMK1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMK2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMK2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0042', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1912', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1902', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1922', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1911', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1901', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1921', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1350', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7112', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7132', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7172', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0038', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3800', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0039', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7173', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7133', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7154', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7134', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKG7131', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1430', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1441', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1260', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1270', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2800', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2900', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2502', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DMT1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3300', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2311', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1235', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1223', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1341', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1913', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1903', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IKO1923', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK4003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0140', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0144', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0126', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1541', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1442', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK2005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1590', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0142', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0143', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0141', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1515', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4955', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4956', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4957', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4958', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH6000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH6418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH6419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH5000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4907', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4908', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW3000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4905', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4906', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AKT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AKT1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AKT1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB035', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHK037', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTHB037', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLK0111', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW2000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CLL0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TLB1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TLB1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1042', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9860', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7350', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KSPK011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK096', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TLB1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1134', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TLB1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1129', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TAS1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9750', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1112', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SSR1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PXT6522', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PXT6521', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV2406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1603', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV2405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9870', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1137', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9880', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7750', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1433', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1456', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1254', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSL1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1434', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XRV1307', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1162', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1559', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1165', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1258', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LST1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LVR1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1275', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LVR1611', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LVV1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL8003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL6003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL5003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1552', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3720', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL9003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1449', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1209', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LXH4201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LXT320900K', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1431', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1236', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VDB1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XXA1208', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL7005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1043', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCH4201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCH420100A', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1247', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1044', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1213', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCH420100B', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCH420100C', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCS2201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1248', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL8001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL6001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL5001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XMV1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1549', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL9001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1142', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1138', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCS2202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LCS220200B', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LSR1501', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LPT2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LPT3209', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XRL1525', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1222', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1570', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1252', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1156', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PLS1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MST2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1175', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXK1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9260', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KXT1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9800', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9850', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KXT6115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1147', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL8004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL6004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL5004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1554', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL9004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9890', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1129', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KXT611500V', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1134', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KXT647200V', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MRT1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1149', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL7006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXA1208', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1505', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK6500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1509', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1510', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MKL1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7260', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7270', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1513', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MRT2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PLS1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MST3201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL8002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL6002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL5002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MST1201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL9002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7760', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1514', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MKL1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PLS1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1131', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK8350', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK8500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1517', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1518', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PLS1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK6000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK5000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1049', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL2006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1241', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1206', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK8000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MKL1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1163', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL4011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1901', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1903', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1902', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1211', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1124', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1125', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1128', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1136', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1126', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1127', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1453', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1239', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH5017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXJ1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1032', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW4000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK7250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1221', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1246', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1230', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1238', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LVR4403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1505', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1506', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1551', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1513', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1514', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LSR1701', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1560', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KML1408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1441', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LVR1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1249', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1231', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1215', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH5011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXJ1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXJ1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1223', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1224', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH5002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1166', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1153', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1206', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1251', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1255', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1214', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1259', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1260', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1041', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9990', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH4303', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXH5001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1146', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1128', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1145', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1148', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL1123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL1144', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1220', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL1164', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK8250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1237', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK9000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4831', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4841', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4791', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1534', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1510', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1511', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4821', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4861', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4871', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4881', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1507', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1506', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1508', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1509', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4507', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1394', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4685', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1525', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1498', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1481', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1452', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1453', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1454', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1377', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1438', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1367', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1372', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1329', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1334', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1381', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1397', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1428', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1431', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1429', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1303', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1304', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1342', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1448', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1444', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1526', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1388', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1338', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1363', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1339', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1445', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1471', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4309', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4506', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1345', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4509', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1300', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1395', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1385', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1441', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1412', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4308', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1305', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMG1700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1449', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1389', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1306', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1354', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1472', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4307', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1360', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1348', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1343', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1347', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1437', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1447', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMC1700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1488', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1489', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1210', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1446', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1455', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1374', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1476', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMG3101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1311', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1312', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4688', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1465', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1316', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1327', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1383', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1365', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1315', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1392', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1378', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1380', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1313', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1341', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1307', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1475', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1382', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1487', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1376', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1450', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1386', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1387', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1396', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1440', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1467', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1451', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1393', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1350', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1336', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1309', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1308', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1435', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1443', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1390', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1473', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1362', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1522', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1364', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1373', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1318', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1356', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1357', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1474', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4508', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1466', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1349', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMD1700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1337', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1358', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1485', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1317', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1379', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1351', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1353', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1335', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1344', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1468', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1469', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1352', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1319', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1355', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1314', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1359', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1310', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1398', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1434', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1433', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1484', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1361', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1432', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1384', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1436', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1442', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1439', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1321', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1340', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1521', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1460', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1461', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1464', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1462', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1503', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4613', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4610', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4617', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4619', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4565', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4614', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4605', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1612', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4686', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4618', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4616', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4671', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4851', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4811', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4305', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4306', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1546', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4304', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4303', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4603', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1541', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1540', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1542', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1539', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4611', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1456', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4606', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4609', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4625', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4627', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4693', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4692', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1611', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4626', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4608', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4801', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4624', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4615', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4564', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4731', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4732', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4790', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4602', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4604', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4622', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1743', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4684', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4682', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4629', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4628', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4770', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4672', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4810', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4612', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2118', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1610', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1753', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4795', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4607', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4309', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4799', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4502', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4696', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4796', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1496', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4304', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4780', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4683', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4720', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4694', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4687', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4730', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4710', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1533', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4400', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4567', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH2110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4563', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4620', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4307', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1544', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1543', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1547', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4503', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4798', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4623', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4305', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4504', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4505', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1745', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1486', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1399', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1744', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH3000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1458', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1459', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1463', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1545', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4695', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4697', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4501', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4903', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4902', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4689', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4690', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4698', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4621', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4794', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4793', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4792', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4601', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA4306', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4670', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4566', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4308', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1504', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1502', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1495', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1499', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1501', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1505', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1328', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1333', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1323', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1326', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1332', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1322', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1325', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1331', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1324', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1330', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1320', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4699', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1497', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1491', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1492', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1482', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1483', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1493', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1494', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4700', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1747', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMW1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1746', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1752', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3200', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4904', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4930', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4932', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4949', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4929', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1206', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1213', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1530', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1531', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1515', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1514', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1532', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1527', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1519', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1520', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1518', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1536', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1529', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1512', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1600', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1513', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1517', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1528', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1523', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1524', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1535', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1516', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1538', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1537', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML143301D', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1433', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1432', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4691', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMK3250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM4060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMM1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMM1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMM1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMM1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH1548', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMH4797', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK097', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AMT1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AMT1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK098', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK099', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SOLJ013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'API1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'BP07500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PM1313', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1273', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HPM0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1212', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HPM0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1231', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFP1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HPM0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HPM0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HPM0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ABP0873', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ABP0872', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR1050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2140', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2080', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2090', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2043', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2160', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR2150', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR3010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR3040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR3020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR3050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFR3030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AST1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1434', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK035', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI1015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARC1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARC1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARC1014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARC1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI1014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ARI1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KPLB001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KPLB004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTSK013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB107', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1133', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMR1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR5404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR4404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSL1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VTR1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VVR4107', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3721', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1200', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VTQ1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1442', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VTF1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VTQ1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1440', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1542', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1737', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR2404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VTQ1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMM2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1641', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMS1160', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMP1300', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1443', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR5406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR5405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR4406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1466', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SVR4405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IML1543', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMS2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMS2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXL1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBK103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ASR1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ASR1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMS1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMS1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS3020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS3010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HBC0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFB1251', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HBC0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1051', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1071', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1081', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1061', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1041', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HBC0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1090', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'HBC0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFB1212', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1140', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1150', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1160', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1170', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS1180', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFB1213', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFB1204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2090', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2080', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'SB', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3655', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3656', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS0006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM3583', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS4010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS4020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFS4030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ABP0874', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ASB1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ASB1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1206', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VHA1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VHA1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1050', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFT1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1506', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL3201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1701', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL3105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL3101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1601', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1214', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1119', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1131', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1124', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1132', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL3110', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1133', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1131', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1121', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT 112712', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1118', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT4003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1223', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT3003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT9002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1290', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT3006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1291', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT3007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRS4570', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1222', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRL3730', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1125', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAS1608', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1266', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1412', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT8001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT9001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT 110612', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT5001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CMT1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1613', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2429', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1601', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1180', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1920', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2433', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1530', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1280', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1930', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1510', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1260', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1910', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT7001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1536', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL6001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1282', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAS4106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1220', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1246', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL8001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTT1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAS1409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL7001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1428', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1147', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1145', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR4106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1126', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT4002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT8002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV2410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT5002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1313', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1116', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR4602', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1521', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1241', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1921', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1531', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1281', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1931', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2054', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR4404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1107', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1511', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1261', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1911', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTT3201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2055', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1138', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1236', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT6582', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1434', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAL1023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1283', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1221', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT3002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1124', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMT1104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1324', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXW1207', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2431', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2432', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1901', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1921', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1931', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1911', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRV1105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSLR005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ATE2031', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL0013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VIB1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1135', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1126', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1107', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1218', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1212', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRL1219', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1132', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1106', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRS1100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1125', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1108', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1142', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1220', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1134', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1235', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1303', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1414', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1241', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1207', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1304', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1122', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1500', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1411', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1123', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2013', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS2201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1535', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1044', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1418', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTT1433', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1430', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRV8104', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1613', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1701', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1610', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVR1810', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVR1311', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1141', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1615', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2430', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1140', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMT1415', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1539', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1835', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1840', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2408', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1059', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MRT1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1230', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6521', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1209', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1264', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1218', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1520', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1240', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2412', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTT6472', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2015', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2014', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT2425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1141', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS1417', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6113', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMS6001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXS1022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1219', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1563', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1565', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6114', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6117', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT6105', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1135', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1435', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1438', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT1419', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT2426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT2427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1325', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1443', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1440', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1313', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1342', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1142', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CMT2019', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1315', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2053', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT6115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1339', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'CRT1246', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1735', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1740', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMT1137', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2056', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2057', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1060', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2058', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1250', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT1022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1049', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6321', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1165', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2506', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2505', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TTN1210', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TTN1212', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1164', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VHP1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VHP1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ATT1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'MAL1413', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2409', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VJG1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2501', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2410', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2416', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2428', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMS1161', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KMS1162', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2421', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2422', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2420', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT2423', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1498', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMA1429', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB086', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRV8103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV3003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVB1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3007', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1130', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1129', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1131', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1132', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1127', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRT1128', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1143', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3204', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT4002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3205', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VDP1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSL1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XXT2005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2431', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1602', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1028', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1108', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VBR1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'XMV1008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TXV8103', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAT1215', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT6401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRT1871', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT4001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3206', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3201', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT4401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT4402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VAB1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSJ1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VVR5108', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2429', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT2427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVB1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK033', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1307', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMT3100', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRV8302', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TRV8301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXT3005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1027', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1407', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VAB1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV3001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSL1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1301', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV3002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'PRV1102', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1006', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTKK029', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1428', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1440', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1425', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1424', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1429', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1430', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1426', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR1607', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2406', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0023', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV1427', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR2001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2401', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2405', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR2005', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR2003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR4009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR2004', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0021', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TXL3203', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0022', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0024', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTL1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0025', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5016', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0012', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH6202', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'DLH5017', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLB1002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLH0070', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLB1001', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KLB1003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KAV1404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TSR2002', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IMV2000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KPL1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TXT6115', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0008', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0009', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0018', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'GVT0010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TTN1120', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TTN1211', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVR1312', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TXL3101', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2402', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2404', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV240200B', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KVT0003', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KOV2403', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'TVR1808', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSG1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VSC1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VPR1000', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'IXV1026', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AWH1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AWH1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AWH1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KTBB084', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'AWC1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFW1020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFW1030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFW1010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ATE1011', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD2030', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD2010', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD2040', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'VMD2020', 0, '2021-08-13 13:58:55.782205', NULL);
INSERT INTO public.tr_customer_price VALUES (1, 3, 'LFM1001', 500, '2021-08-13 13:58:55.782205', '2021-08-13 14:00:24.576368');
INSERT INTO public.tr_customer_price VALUES (1, 3, 'KGBK026', 1000, '2021-08-13 13:58:55.782205', '2021-08-13 14:00:24.576368');
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ABSB', 1500, '2021-08-13 13:58:55.782205', '2021-08-13 14:00:24.576368');
INSERT INTO public.tr_customer_price VALUES (1, 3, 'ACDH001', 2000, '2021-08-13 13:58:55.782205', '2021-08-13 14:00:24.576368');


--
-- TOC entry 3299 (class 0 OID 17876)
-- Dependencies: 224
-- Data for Name: tr_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_level VALUES (2, 'Admin', true, 'Input Data Master');
INSERT INTO public.tr_level VALUES (3, 'User', true, 'input data transaksi');
INSERT INTO public.tr_level VALUES (4, 'Spg', true, '');
INSERT INTO public.tr_level VALUES (1, 'Super Admin', true, 'Setting Aplikasi');


--
-- TOC entry 3301 (class 0 OID 17884)
-- Dependencies: 226
-- Data for Name: tr_menu; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_menu VALUES (101, 'Perusahaan', 1, 1, 'perusahaan', NULL, NULL);
INSERT INTO public.tr_menu VALUES (1, 'Master Data', 0, 2, '#', 'icon-stack2', NULL);
INSERT INTO public.tr_menu VALUES (0, 'Dashboard', 0, 1, 'dashboard', 'icon-home', NULL);
INSERT INTO public.tr_menu VALUES (8, 'Setting', 0, 9, '#', 'icon-cog52', NULL);
INSERT INTO public.tr_menu VALUES (801, 'Level', 8, 1, 'level', NULL, NULL);
INSERT INTO public.tr_menu VALUES (803, 'Hak Akses', 8, 3, 'setting', NULL, NULL);
INSERT INTO public.tr_menu VALUES (802, 'Menu', 8, 2, 'menu', NULL, NULL);
INSERT INTO public.tr_menu VALUES (102, 'Tipe Toko', 1, 2, 'tipe', '', NULL);
INSERT INTO public.tr_menu VALUES (103, 'Data Toko', 1, 3, 'customer', '', NULL);
INSERT INTO public.tr_menu VALUES (104, 'User Login', 1, 4, 'user', '', NULL);
INSERT INTO public.tr_menu VALUES (106, 'Alasan Retur', 1, 6, 'alasan', '', NULL);
INSERT INTO public.tr_menu VALUES (105, 'Product', 1, 5, 'product', '', NULL);
INSERT INTO public.tr_menu VALUES (804, 'Power', 8, 2, 'power', '', NULL);
INSERT INTO public.tr_menu VALUES (107, 'Harga Product', 1, 5, 'productprice', '', NULL);
INSERT INTO public.tr_menu VALUES (4, 'Penjualan', 0, 5, 'penjualan', 'icon-bag', NULL);
INSERT INTO public.tr_menu VALUES (7, 'Panduan Manual', 0, 8, 'panduan', 'icon-bookmark', NULL);
INSERT INTO public.tr_menu VALUES (2, 'Pembelian', 0, 3, 'pembelian', 'icon-cart2', NULL);
INSERT INTO public.tr_menu VALUES (3, 'Retur Pembelian', 0, 4, 'retur', 'icon-cart-remove', NULL);
INSERT INTO public.tr_menu VALUES (5, 'Mutasi', 0, 6, 'mutasi', 'icon-stats-growth', NULL);


--
-- TOC entry 3309 (class 0 OID 40833)
-- Dependencies: 234
-- Data for Name: tr_panduan; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_panduan VALUES (1, 'Chat.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (2, 'Informasi FaQ.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (3, 'Log.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (4, 'Kelola Tiket.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (5, 'Master Data-Department.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (6, 'Master Data-Divisi.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (7, 'Master Data-Jenis Tiket.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (8, 'Master Data-Kategori FaQ.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (9, 'Master Data-Level Jabatan.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (10, 'Master Data-Masalah.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (11, 'Master Data-Perusahaan.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (12, 'Master Data-Prioritas Tiket.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (13, 'Master Data-Status Tiket.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (14, 'Master Karyawan-Admin&Staff.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (15, 'Master Karyawan-User.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (16, 'My Tiket.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (17, 'Pengelolaan FaQ.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (18, 'Report.pdf', 'assets/panduan/', true);
INSERT INTO public.tr_panduan VALUES (19, 'Setting-Hak Akses.pdf', 'assets/panduan/', true);


--
-- TOC entry 3302 (class 0 OID 17891)
-- Dependencies: 227
-- Data for Name: tr_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_product VALUES (2, 'DLK33000', 'Kelambu Gantung Pintu', 'Moms Baby', 5000.00, 6000.00, true, '2021-08-09 14:13:29.065622', NULL, NULL);
INSERT INTO public.tr_product VALUES (3, 'LFM1001', 'Boneka Bayi On Board Karakter Pinguin Ceria', 'Little Friend', 10000.00, 50000.00, true, '2021-08-09 14:26:19.073243', '2021-08-09 14:42:05.377094', NULL);
INSERT INTO public.tr_product VALUES (3, 'KGBK026', 'ABELIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ABSB', 'ACCESORIES BESI KELAMBU AYUN SNOBBY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'ACDH001', 'ACCESORIES COVER DLK01260', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH002', 'ACCESORIES COVER DLK014000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH003', 'ACCESORIES COVER PRL200100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH004', 'ACCESORIES COVER PRL200500', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACDH005', 'ACCESORIES COVER PRL2006', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH006', 'ACCESORIES COVER PRL6001', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH007', 'ACCESORIES COVER PRL700500', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH008', 'ACCESORIES COVER PRL700600', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH009', 'ACCESORIES COVER PRT124000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH010', 'ACCESORIES COVER PRT124100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH011', 'ACCESORIES COVER PRT126000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH012', 'ACCESORIES COVER PRT126100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH013', 'ACCESORIES COVER PRT128000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH014', 'ACCESORIES COVER PRT128100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH015', 'ACCESORIES COVER PRT128200', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH016', 'ACCESORIES COVER PRT1283', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH017', 'ACCESORIES COVER PRT129000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH018', 'ACCESORIES COVER PRT129100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH019', 'ACCESORIES COVER PRT151000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH020', 'ACCESORIES COVER PRT152000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH021', 'ACCESORIES COVER PRT152100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH022', 'ACCESORIES COVER PRT153000', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH023', 'ACCESORIES COVER PRT153100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH024', 'ACCESORIES COVER PRT3007', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ACDH025', 'ACCESORIES COVER TRL190100', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ADDH001', 'ACCESORIES DUS UK. 20X26', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'ADDH002', 'ACCESORIES DUS UK.24*28', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'AHDH001', 'ACCESORIES HEMA', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'APDH006', 'ACCESORIES PLASTIK OPP 20X43.5', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'APDH007', 'ACCESORIES PLASTIK OPP 25X35', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'APDH005', 'ACCESORIES PLASTIK OPP UK. 20X30', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'APDH001', 'ACCESORIES PLASTIK UK. 23X67', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'APDH002', 'ACCESORIES PLASTIK UK. 25X72', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'APDH003', 'ACCESORIES PLASTIK UK. 25X75', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'APDH004', 'ACCESORIES PLASTIK UK. 29X74', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VDT1001', 'ADAY PRINT E/S A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VSC1001', 'ADDY PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTSK007', 'ADELINE', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK021', 'AISAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'VMA1020', 'ALAS STROLLER + BANTAL LENGAN BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMA1010', 'ALAS STROLLER + BANTAL LENGAN RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'KSPK001', 'ALEA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK001', 'ALFIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK012', 'ANIFAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KSPB012', 'ANNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KSPB017', 'ANYYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMA1365', 'APLIKASI 1 KELINCI+LITTLE BEAR LOVE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1362', 'APLIKASI 1 KELINCI LOVE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0013', 'APLIKASI H.KERETA BAYI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0014', 'APLIKASI H.PANDA PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1302', 'APLIKASI LITTLE BEAR LOVE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1304', 'APLIKASI LITTLE BEAR PARTY TIME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1104', 'APLIKASI LITTLE BEAR SWEET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1103', 'APLIKASI M.FUNNY RABBIT BUKU KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1422', 'APLIKASI M.HAPPY BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1376', 'APLIKASI M.KEPALA CAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1372', 'APLIKASI M.KEP GAJAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1102', 'APLIKASI M.KEP SWEET BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1426', 'APLIKASI M.MATA BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1101', 'APLIKASI M.NICE SLEEP 2 BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1385', 'APLIKASI M.RUMAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0019', 'APLIKASI RABBIT WORTEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KSPB007', 'ARSHA', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KTBK104', 'ARUMI', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KTSK006', 'AYUMI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'MBA0001', 'AYUNAN BAYI + KELAMBU OTHELLO SERIES', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ICBJR09', 'BABY JUMPER', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJMC006', 'BABY JUMPER CELANA PENDEK', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICBJC10', 'BABY JUMPER CELANA PENDEK', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJMK005', 'BABY JUMPER LURUS', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJMR004', 'BABY JUMPER PENDEK RIB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'KTBK105', 'BAHIRAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBK004', 'BAJU ADIBA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK015', 'BAJU ALENA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB015', 'BAJU ALENA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK031', 'BAJU ALIYAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB031', 'BAJU  ALIYAH BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK032', 'BAJU ALIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK033', 'BAJU ALIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB032', 'BAJU ALIZA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK011', 'BAJU ANESA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB011', 'BAJU ANESA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK014', 'BAJU ANGELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB014', 'BAJU ANGELLA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK022', 'BAJU ANNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB022', 'BAJU ANNA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK001', 'BAJU ARIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB001', 'BAJU ARIANA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB019', 'BAJU ARISYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK010', 'BAJU ATHIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB010', 'BAJU ATHIA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBB004', 'BAJU BABTIS ALIQA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBB002', 'BAJU BABTIS DWISTY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBB005', 'BAJU BABTIS NARESHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBB001', 'BAJU BELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK002', 'BAJU CEISYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB002', 'BAJU CEISYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK003', 'BAJU DAMIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB003', 'BAJU DAMIA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK020', 'BAJU DELICA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB020', 'BAJU DELICA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK012', 'BAJU DEMYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB012', 'BAJU DEMYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBK005', 'BAJU EFRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK004', 'BAJU ELIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB004', 'BAJU ELIZA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK009', 'BAJU FADHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB009', 'BAJU FADHA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK005', 'BAJU FAIHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB005', 'BAJU FAIHA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK013', 'BAJU FENNY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK021', 'BAJU GAMIS AYANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK023', 'BAJU GAMIS FARAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB027', 'BAJU GAMIS HAIFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK025', 'BAJU GAMIS HANNAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB029', 'BAJU GAMIS KAISA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK016', 'BAJU GAMIS KAOS ATIFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB016', 'BAJU GAMIS KAOS FALISHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK017', 'BAJU GAMIS KAOS HAIFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK018', 'BAJU GAMIS KAOS JIHAN', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB017', 'BAJU GAMIS KAOS KAMALIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB018', 'BAJU GAMIS KAOS NAURA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK019', 'BAJU GAMIS KAOS SAIDA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK020', 'BAJU GAMIS KAOS YASMIN', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB020', 'BAJU GAMIS KAOS ZARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB030', 'BAJU GAMIS KEARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB025', 'BAJU GAMIS KHALIDA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK022', 'BAJU GAMIS NAURA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB019', 'BAJU GAMIS RANIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB026', 'BAJU GAMIS RANNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB028', 'BAJU GAMIS RANNE', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB022', 'BAJU GAMIS SELINA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB021', 'BAJU GAMIS SYAFIQAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB023', 'BAJU GAMIS TISHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGB024', 'BAJU GAMIS UZMA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK024', 'BAJU GAMIS ZARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK028', 'BAJU HAFIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB028', 'BAJU HAFIA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK016', 'BAJU HELIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB016', 'BAJU HELIZA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK023', 'BAJU HESYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB023', 'BAJU HESYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK019', 'BAJU HIDA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB013', 'BAJU JELLICHA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK024', 'BAJU KALIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB024', 'BAJU KALIA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK029', 'BAJU KANINA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB029', 'BAJU KANINA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KKPC003', 'BAJU KAOS BEAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KKPC004', 'BAJU KAOS COW', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLK001', 'BAJU KAOS DOGGY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLB001', 'BAJU KAOS DOGGY BESAR', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KBLK003', 'BAJU KAOS KELINCI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KKPC005', 'BAJU KAOS KELINCI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLB003', 'BAJU KAOS KELINCI BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KKPC002', 'BAJU KAOS KOALA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLK005', 'BAJU KAOS PANJANG LANDAK', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLB005', 'BAJU KAOS PANJANG LANDAK BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLK002', 'BAJU KAOS PANJANG PANDA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLB002', 'BAJU KAOS PANJANG PANDA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLK004', 'BAJU KAOS PENDEK  PANDA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KBLB004', 'BAJU KAOS PENDEK  PANDA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KKPC001', 'BAJU KAOS SHEEP', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'CKNOD01', 'BAJU KUTUNG NECI DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICKNO01', 'BAJU KUTUNG NECI DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'KDPK036', 'BAJU LILYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB036', 'BAJU LILYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK034', 'BAJU MAISHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB034', 'BAJU MAISHA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK007', 'BAJU MELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB007', 'BAJU MELLA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK018', 'BAJU MEYSA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB018', 'BAJU MEYSA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK027', 'BAJU MEYSYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB027', 'BAJU MEYSYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBK003', 'BAJU MILLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK035', 'BAJU NABILA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB035', 'BAJU NABILA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK006', 'BAJU NAFIDAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB006', 'BAJU NAFIDAH BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK030', 'BAJU NASYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB030', 'BAJU NASYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK017', 'BAJU NOWELA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB017', 'BAJU NOWELA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB033', 'BAJU RAINA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK026', 'BAJU RASYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB026', 'BAJU RASYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK025', 'BAJU SAFIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB025', 'BAJU SAFIA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK021', 'BAJU SARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB021', 'BAJU SARA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBK001', 'BAJU SELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ICPPS07', 'BAJU SML PANJANG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICDDS08', 'BAJU SML PENDEK', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CPNPD06', 'BAJU TANGAN PANJANG NECI DAN CELANA PANJANG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICPNP06', 'BAJU TANGAN PANJANG NECI DAN CELANA PANJANG RIB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CPRPD05', 'BAJU TANGAN PANJANG RIB DAN CELANA PANJANG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICPRP05', 'BAJU TANGAN PANJANG RIB DAN CELANA PANJANG RIB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CDNOD02', 'BAJU TANGAN PENDEK NECI DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICDNO02', 'BAJU TANGAN PENDEK NECI DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CDRPD04', 'BAJU TANGAN PENDEK RIB DAN CELANA PANJANG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICDRP04', 'BAJU TANGAN PENDEK RIB DAN CELANA PANJANG ', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CDROD03', 'BAJU TANGAN PENDEK RIB DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICDRO03', 'BAJU TANGAN PENDEK RIB DAN CELANA POB', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'KDBK002', 'BAJU TIARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDBB003', 'BAJU VELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPK008', 'BAJU ZUNAIRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KDPB008', 'BAJU ZUNAIRA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'DBS0043', 'BANTAL BESAR MOTIF BUNGA UKURAN 60X30 CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VMB6040', 'BANTAL FOAMING KOTAK ANIMAL BALLOON ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6020', 'BANTAL FOAMING KOTAK PANDA ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6030', 'BANTAL FOAMING KOTAK RABBIT ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6010', 'BANTAL FOAMING KOTAK RACOON ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6070', 'BANTAL FOAMING PENGUIN', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6060', 'BANTAL FOAMING TIGER ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB6050', 'BANTAL FOAMING WEASEL ', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB3020', 'BANTAL GULING SET BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB3010', 'BANTAL GULING SET RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB2020', 'BANTAL IBU MENYUSUI BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMB2010', 'BANTAL IBU MENYUSUI RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'DBS0042', 'BANTAL SEDANG MOTIF BUNGA UK 43X30 CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DBS0041', 'BANTAL SEGI MOTIF BUNGA UK 42X42 CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'CBDI007', 'BEDONG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ABE1010', 'BEEP 33 MM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMB2577', 'BEEP BEEP 25X77 CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMB2810', 'BEEP BEEP 28X105 CM ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBK092', 'BELHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KGBK027', 'BELIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMB1500', 'BENANG 150 TEXTURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4901', 'BENANG 300 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMB4500', 'BENANG 450 TEXTURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMB5000', 'BENANG 50 FILLAMENT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMB7500', 'BENANG 75 FILLAMENT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2503', 'BENANG FILAMENT 75D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2501', 'BENANG POLYESTER 150 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4891', 'BESI L 4,BT I 2 M', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AKB1012', 'BOLA KRINCINGAN BULAT BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AKB1011', 'BOLA KRINCINGAN BULAT ORANGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFO1010', 'BONEKA BABY ON BOARD KARAKTER BERUANG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1020', 'BONEKA BABY ON BOARD KARAKTER CHICK', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1030', 'BONEKA BABY ON BOARD KARAKTER FOX', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1040', 'BONEKA BABY ON BOARD KARAKTER FROG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1050', 'BONEKA BABY ON BOARD KARAKTER OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1060', 'BONEKA BABY ON BOARD KARAKTER PENGUIN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF01363', 'BONEKA BAYI ON BOARD KARAKTER BERUANG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1363', 'BONEKA BAYI ON BOARD KARAKTER BERUANG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF1306', 'BONEKA BAYI ON BOARD KARAKTER CHICK', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1306', 'BONEKA BAYI ON BOARD KARAKTER CHICK', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF01324', 'BONEKA BAYI ON BOARD KARAKTER FOX', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1324', 'BONEKA BAYI ON BOARD KARAKTER FOX', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF01395', 'BONEKA BAYI ON BOARD KARAKTER FROG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1395', 'BONEKA BAYI ON BOARD KARAKTER FROG', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF01332', 'BONEKA BAYI ON BOARD KARAKTER OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1332', 'BONEKA BAYI ON BOARD KARAKTER OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LF01311', 'BONEKA BAYI ON BOARD KARAKTER PINGUIN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFO1311', 'BONEKA BAYI ON BOARD KARAKTER PINGUIN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFF1010', 'BONEKA FINGER PUPPETS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFF1801', 'BONEKA FINGER PUPPETS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KHB1003', 'BONEKA GIMIK JELLYFISH', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KHB1002', 'BONEKA GIMIK OCTOPUS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KHB1001', 'BONEKA GIMIK PAUS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM2010', 'BONEKA MAINAN CATERPILLAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFD1713', 'BONEKA RATTLE KARAKTER ELEPHANT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR1010', 'BONEKA RATTLE KARAKTER ELEPHANT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFD1791', 'BONEKA RATTLE KARAKTER HIPPO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR1020', 'BONEKA RATTLE KARAKTER HIPPO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFD1702', 'BONEKA RATTLE KARAKTER LION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR1030', 'BONEKA RATTLE KARAKTER LION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFD1774', 'BONEKA RATTLE KARAKTER MOTIF OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR1040', 'BONEKA RATTLE KARAKTER OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2010', 'BONEKA RATTLE STICK KARAKTER BEAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1912', 'BONEKA RATTLE STICK KARAKTER BEAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2011', 'BONEKA RATTLE STICK KARAKTER BEAR BROWN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2060', 'BONEKA RATTLE STICK KARAKTER FOX', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2020', 'BONEKA RATTLE STICK KARAKTER GIRAFFE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1994', 'BONEKA RATTLE STICK KARAKTER GIRAFFE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2050', 'BONEKA RATTLE STICK KARAKTER LION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1991', 'BONEKA RATTLE STICK KARAKTER MONKEY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2030', 'BONEKA RATTLE STICK KARAKTER MONKEY ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2031', 'BONEKA RATTLE STICK KARAKTER MONKEY RED', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2070', 'BONEKA RATTLE STICK KARAKTER PENGUIN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2040', 'BONEKA RATTLE STICK KARAKTER RABBIT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1953', 'BONEKA RATTLE STICK KARAKTER RABBIT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2041', 'BONEKA RATTLE STICK KARAKTER RABBIT NAVY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2042', 'BONEKA RATTLE STICK KARAKTER RABBIT RED', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KTBB090', 'BUNGA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'BA01062', 'BUSA A10 6X10X2 CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTSK008', 'CEISYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMA1428', 'CELEMEK JACQUARD LAPIS PAYUNG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTKK022', 'CESSY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK106', 'CHAYRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK093', 'CHEESY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK033', 'CHUA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KSPK004', 'CINDY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK084', 'CINTYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ACT1013', 'CIRCULAR TEETHER COKLAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACT1012', 'CIRCULAR TEETHER KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACT1011', 'CIRCULAR THEETHER MERAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KSPK018', 'CITRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'BP07800', 'COVER KELAMBU TENDA CHEVRON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'CV00180', 'COVER SNOBBY KELAMBU AYUNAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACR1011', 'C RING BIRU TUA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACR1012', 'C RING COKLAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACR1013', 'C RING ORANGE TUA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ACR1014', 'C RING PEACH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBK094', 'DANIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK034', 'DANIAN', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK023', 'DELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KGBK029', 'DELLIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB096', 'DENNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK002', 'DIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK107', 'DILAYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK111', 'DRESS AFIKA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB111', 'DRESS AFIKA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK121', 'DRESS AINI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK017', 'DRESS ASKA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB125', 'DRESS DIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK109', 'DRESS DIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB109', 'DRESS DIANA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB114', 'DRESS EMELY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK124', 'DRESS EMELY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB122', 'DRESS FIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK120', 'DRESS HASYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB120', 'DRESS HASYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK119', 'DRESS HAUFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB119', 'DRESS HAUFA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK112', 'DRESS KAYLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB112', 'DRESS KAYLA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB121', 'DRESS LIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK123', 'DRESS LILA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB124', 'DRESS MIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK113', 'DRESS MILEA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK122', 'DRESS MISYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK110', 'DRESS NAURA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB110', 'DRESS NAURA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK115', 'DRESS NEYRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB115', 'DRESS NEYRA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK117', 'DRESS RANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB117', 'DRESS RANA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK118', 'DRESS RANI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB118', 'DRESS RANI BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK116', 'DRESS RAYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB116', 'DRESS RAYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB123', 'DRESS RIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK114', 'DRESS SAFIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK125', 'DRESS SALSA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK108', 'DRESS VIOLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB108', 'DRESS VIOLA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB113', 'DRESS VISHAKA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'PDC0001', 'DUS EYEMASK BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTKK034', 'EDRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK095', 'EFFRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK003', 'EFRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB097', 'ELMANIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK091', 'ELSSA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KGBK030', 'EMALIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK035', 'EMALLYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK036', 'EMILI', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB036', 'EMILI BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK024', 'ERNY', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ICE1010', 'EYEMASK BEAR', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1050', 'EYEMASK CROCODILE', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1020', 'EYEMASK FOX', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1030', 'EYEMASK LORIS', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1040', 'EYEMASK PANDA', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CLE1080', 'EYEMASK PRINT ANIMALS', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1070', 'EYEMASK RACOON', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'ICE1060', 'EYEMASK TURTLE', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'KTBB104', 'FADHILA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK009', 'FADHILA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB098', 'FANIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK038', 'FANYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB038', 'FANYA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'AFT3013', 'FEET TEETHER TITIK BABY PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3015', 'FEET TEETHER TITIK BLUE OCEAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3011', 'FEET TEETHER TITIK BROKEN WHITE ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3016', 'FEET TEETHER TITIK BROWN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3017', 'FEET TEETHER TITIK ORANGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3012', 'FEET TEETHER TITIK RED', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT3014', 'FEET TEETHER TITIK YELLOW', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT2012', 'FEET THEETHER HIJAU  (ADA LUBANGNYA)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT1011', 'FEET THEETHER KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AFT2011', 'FEET THEETHER OREN (ADA LUBANGNYA)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KGBK031', 'FELLIA', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'LFF1011', 'FINGER PUPPET ANIMAL 2', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFF1020', 'FINGER PUPPET FRUITS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFF1030', 'FINGER PUPPET SEA ANIMAL ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KTBB106', 'FIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK010', 'FIZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB091', 'FUNNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB032', 'GABRIELA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK027', 'GAMIS HAIFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK029', 'GAMIS KAISA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK030', 'GAMIS KEARA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK026', ' GAMIS RANNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTGK028', 'GAMIS RANNE', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB092', 'GHAISA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KSPK007', 'GHEA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB099', 'GIANNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KSPB011', 'GISELL', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KGBK032', 'GISELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMA1523', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1525', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1526', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1600', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1751', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2411', 'GORDEN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ATE2011', 'GREEN LEAF TEETHER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1111', 'Grey Bunga Idaman', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR1609', 'GREY BUNGA RAMPAI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4950', 'GREY FINISH TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK4050', 'GREY FINISH TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTP002', 'GREY KAIN TILLE L=118CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2901', 'GREY KAIN TRIKOT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GTL0002', 'GREY TILLE L:102CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GTL0003', 'GREY TILLE L:118CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTP001', 'GREY TILLE L=150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GTL0004', 'GREY TILLE L:150CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GTL0005', 'GREY TILLE L:164CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GTL0001', 'GREY TILLE L:88CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VMG2020', 'GULING PENYANGGA BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMG2010', 'GULING PENYANGGA RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMG1020', 'GULING SINGLE BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMG1010', 'GULING SINGLE RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'KTBB105', 'HAFSHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK011', 'HAIFA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTSK004', 'HANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMV2423', 'HANDUK EXP.BORDIR E/S (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1241', 'HANDUK EXPORT PRINT 60X120', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2414', 'HANDUK EXPORT PRINT E/S 60X110 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTT7195', 'HANDUK EXP PRINT E/S 60X110', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1750', 'HANDUK PRINT 60X120 ATL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2412', 'HANDUK PRINT 60X120 ATL (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH1000', 'HANDUK SALUR 70X140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5006', 'HANDUK SALUR POLOS 75X150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2426', 'HANDUK SALUR POLOS 75X150 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5007', 'HANDUK SALUR PRINT 75X150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2427', 'HANDUK SALUR PRINT 75X150 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5008', 'HANDUK SET.EXP PRINT E/S', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH1500', 'HANDUK TENUN 60X120', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DKL0111', 'HANDUK TENUN 70X140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1752', 'HANDUK TENUN BORDIR-2 65X140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2424', 'HANDUK TENUN BORDIR 65X140 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1749', 'HANDUK TENUN GUCCI BORDIR 70X140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1751', 'HANDUK TENUN JACQUARD BORDIR 60X130', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2420', 'HANDUK TENUN JQ BORDIR 60X130 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2413', 'HANDUK TENUN PRINT 60X120 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2425', 'HANDUK TENUN PRINT 60X130 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1748', 'HANDUK TENUN STRIP 70X140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBB093', 'HANNIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB103', 'HASHELA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB003', 'HAYNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB033', 'HAYNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB100', 'HENNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'HCSN400', 'HOLOGRAM SNI CLENCY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTSK005', 'ILIANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK032', 'IMAA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB094', 'IMARSA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB034', 'INDIRA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB101', 'INEZZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB095', 'JANETTA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'JJE0002', 'JASA CUTTING EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JJE0001', 'JASA JAHIT EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JJE0004', 'JASA PACKING EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JJE0005', 'JASA PENGESETAN EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JJE0003', 'JASA QC EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTHK040', 'JESSA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB040', 'JESSA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB102', 'JEZZYCA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK039', 'JOANA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB039', 'JOANA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ICBJH11', 'JUMPER HOODIE', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJSH003', 'JUMSWIT HOODIE', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJSK002', 'JUMSWIT KAKI TANGAN BUKA TUTUP CORONG', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'CJSS001', 'JUMSWIT KAKI TANGAN BUKA TUTUP SLETING', 'CLENCY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'CLENCY');
INSERT INTO public.tr_product VALUES (3, 'IMK3205', 'KAIN JALA FULL ( BENANG 300 )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3204', 'KAIN JALA FULL (BNG 300)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JKMK07', 'KAIN JERSEY SK PUTIH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JKMKP07', 'KAIN JERSEY SK PUTIH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'K151011', 'KAIN KAOS ANTI BAKTERI POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KKS1010', 'KAIN KAOS MOTIF SALUR WARNA MIX', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1580310', 'KAIN MICRO MOTIF BUNGA WARNA BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMR0002', 'KAIN MICRO PRINT BRIDGE 28X38', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMB0003', 'KAIN MICRO PRINT BUNNY COKLAT 11X11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMB0002', 'KAIN MICRO PRINT BUNNY COKLAT 9.9X6', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMB0004', 'KAIN MICRO PRINT BUNNY KUNING 11X11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMB0001', 'KAIN MICRO PRINT BUNNY KUNING 8.5X11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'K156046', 'KAIN MICRO PRINT EYEMASK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1562620', 'KAIN MICRO PRINT MOTIF AMUBA HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMC1562', 'KAIN MICRO PRINT MOTIF AMUBA HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1519190', 'KAIN MICRO PRINT MOTIF ARROW WARNA ORANGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1522100', 'KAIN MICRO PRINT MOTIF BUBLE WARNA WARNI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1580300', 'KAIN MICRO PRINT MOTIF BUNGA WARNA KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '153400', 'KAIN MICRO PRINT MOTIF CHEVRON WARNA HITAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1522300', 'KAIN MICRO PRINT MOTIF CHEVRON WARNA HITAM PUTIH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1560380', 'KAIN MICRO PRINT MOTIF DAUN WARNA WARNI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1510310', 'KAIN MICRO PRINT MOTIF GELOMBANG BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1510271', 'KAIN MICRO PRINT MOTIF LINGKARAN WARNA BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1562610', 'KAIN MICRO PRINT MOTIF PLUS WARNA MERAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1562600', 'KAIN MICRO PRINT MOTIF POLKADOT KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1560370', 'KAIN MICRO PRINT MOTIF STRIPE WARNA PELANGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMR0001', 'KAIN MICRO PRINT RHINO 8.5X11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1560390', 'KAIN MICRO PRINT SEGITIGA WARNA WARNI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, '1522310', 'KAIN MICRO PRINT SPIRAL MONOCHROME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'K000013', 'KAIN MINKY DOT 11X11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'K000011', 'KAIN MINKY DOT BIRU MUDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'K000012', 'KAIN MINKY DOT PEACH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLH0080', 'KAIN POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAV1405', 'KAIN POLY TILLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KKH4203', 'KAIN POLY TILLE POTONGAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JKMKP06', 'KAIN PRINTED JERSEY DK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JKMKP05', 'KAIN PRINTED JERSEY SK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'JKMKP03', 'KAIN+PRINT PE VIOLET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TMK0077', 'KAIN SJ PE STRIPER ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KBP0838', 'KAIN SPANBOND 40GSM PUTIH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3202', 'KAIN TILLE L=120 WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLHP004', 'KAIN TILLE L:130CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0001', 'KAIN TILLE L:130CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4931', 'KAIN TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLHP008', 'KAIN TILLE L:140CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0002', 'KAIN TILLE L:140CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3201', 'KAIN TILLE L=140 (W.BIRU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3203', 'KAIN TILLE L=140 (W.MERAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTJ200', 'KAIN TILLE L=150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLHP009', 'KAIN TILLE L:160CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0003', 'KAIN TILLE L:160CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0009', 'KAIN TILLE L 160 HITAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0008', 'KAIN TILLE L 160 MERAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0007', 'KAIN TILLE L 160 NAVY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0006', 'KAIN TILLE L 160 PINK BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0011', 'KAIN TILLE L:160 W/MERAH HATI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0010', 'KAIN TILLE L:160 W/ SALEM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTJ100', 'KAIN TILLE L=164', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLP1000', 'KAIN TILLE L:180CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0004', 'KAIN TILLE L:180CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTP003', 'KAIN TILLE L=200CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLTH009', 'KAIN TILLE L:200CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0005', 'KAIN TILLE L:200CM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0012', 'KAIN TILLE L:200 PADDING 47 GR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0015', 'KAIN TILLE PADDING WISKA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTR0101', 'KAIN TRIKOT 50X18 K.164 CM - MERAH CABE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTR0103', 'KAIN TRIKOT 50X18 L.164 CM - ABU MUDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTR0104', 'KAIN TRIKOT 50X18 L.164 CM - ABU TUA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTR0102', 'KAIN TRIKOT 50X18 L.164 CM - HIJAU BOTOL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4909', 'KAIN TRIKOT SUPER BRIGHT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4919', 'KAIN TRIKOT SUPER BRIGHT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4920', 'KAIN TRIKOT SUPER BRIGHT (WARNA TUA)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTU0001', 'KAIN TUMMY UPP UK 12.5X12.5', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KYPS001', 'KAIN YELVO PRINT SEPATU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTKK031', 'KALEA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KGBK025', 'KANZHA', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'VMK1020', 'KASUR BAYI LIPAT OVAL BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMK1010', 'KASUR BAYI LIPAT OVAL RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMK2020', 'KASUR BAYI SERUT KOJONG BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMK2010', 'KASUR BAYI SERUT KOJONG RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'IMK3400', 'KELAMBU 1 TIANG PRINT MOTIF GAJAH JERAPAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2401', 'KELAMBU 4 PINTU MAESTRO', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK2101', 'Kelambu 6 K Polos Grandea', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK1101', 'KELAMBU 6K POLOS GRANDEA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3100', 'KELAMBU AYUNAN BABY SNOBBY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'DLK0030', 'KELAMBU AYUN DIALOGUE BABY', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'DLK0042', 'KELAMBU AYUN HIPPO SERIES DIALOGUE ', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IMK3500', 'KELAMBU AYUN HIPPO SERIES SNOBBY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'IKO1912', 'KELAMBU AYUN POLKA SERIES APLIKASI BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1902', 'KELAMBU AYUN POLKA SERIES APLIKASI HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1922', 'KELAMBU AYUN POLKA SERIES APLIKASI PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLK0020', 'KELAMBU BAYI D/P 1 TIANG JC', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'DLK0021', 'KELAMBU BAYI D/P 2 TIANG JC', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IKO1911', 'KELAMBU BAYI TENDA MONO CHEVRON BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1901', 'KELAMBU BAYI TENDA MONO CHEVRON HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1921', 'KELAMBU BAYI TENDA MONO CHEVRON PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2301', 'Kelambu Bordir ( Mentari )', 'MENTARI', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MENTARI');
INSERT INTO public.tr_product VALUES (3, 'KAT1350', 'KELAMBU BORDIR( MENTARI)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKG7112', 'KELAMBU GANTUNG APLIKASI RENDA D-07 MONIQUE BIRU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7132', 'KELAMBU GANTUNG APLIKASI RENDA D-07 MONIQUE HIJAU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7122', 'KELAMBU GANTUNG APLIKASI RENDA D-07 MONIQUE ROSE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7172', 'KELAMBU GANTUNG APLIKASI RENDA D-07 MONIQUE UNGU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMK2407', 'Kelambu gantung bambu jacquard', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'DLK0029', 'KELAMBU GANTUNG DIALOGUE BABY', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IMK2402', 'Kelambu gantung full colour', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1113', 'KELAMBU GANTUNG KING TE MAESTRO RAINBOW', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1410', 'KELAMBU GANTUNG KING TE PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1402', 'KELAMBU GANTUNG MAMBO DIALOGUE BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1401', 'KELAMBU GANTUNG MAMBO KOMBINASI JACQUARD', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2408', 'KELAMBU GANTUNG MONIQUE APLIKASI RUMBAI', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'DLK0038', 'KELAMBU GANTUNG MULTIFUNGSI BOX TIANG MILKY SERIES', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3800', 'KELAMBU GANTUNG MULTIFUNGSI BOX TIANG MILKY SERIES', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'DLK0039', 'KELAMBU GANTUNGMULTIFUNGSI MILKY SERIES', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKG7113', 'KELAMBU GANTUNG PITA MONIQUE BIRU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7173', 'KELAMBU GANTUNG PITA MONIQUE HIJAU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7123', 'KELAMBU GANTUNG PITA MONIQUE ORANGE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7133', 'KELAMBU GANTUNG PITA MONIQUE ROSE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7114', 'KELAMBU GANTUNG RAINBOW MONIQUE BIRU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7154', 'KELAMBU GANTUNG RAINBOW MONIQUE PUTIH', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7134', 'KELAMBU GANTUNG RAINBOW MONIQUE ROSE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMK2700', 'KELAMBU GANTUNG SNOBBY BABY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'IMK2000', 'KELAMBU GANTUNG TILLE KING TE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKG7111', 'KELAMBU GANTUNG TILLE PONI MONIQUE BIRU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7121', 'KELAMBU GANTUNG TILLE PONI MONIQUE ORANGE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IKG7131', 'KELAMBU GANTUNG TILLE PONI MONIQUE ROSE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAT1430', 'KELAMBU GRANDEA PRINT SKYLOVE A/B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1441', 'KELAMBU GRANDEA PRINT SKYLOVE PONI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1260', 'KELAMBU GRANDEA PRINTT SCALOPP A/B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1102', 'KELAMBU GRANDEA SCHALOOP BAWAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2102', 'KELAMBU GRANDEA SCHALOOP BAWAH', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK2103', 'KELAMBU GRANDEA SCHALOOP BAWAH ZAHRA', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK1270', 'KELAMBU GRANDEA SCHALOOP PONI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2201', 'Kelambu Grandea Skylove Poni A/B', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK2202', 'Kelambu Grandea Skylove Poni Print', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK2800', 'KELAMBU JAQUARD DP 1 TIANG SNOBBY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'IMK2900', 'KELAMBU JAQUARD DP 2 TIANG SNOBBY', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'IMK1403', 'KELAMBU KING TE RING KOTAK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2502', 'Kelambu monique T160', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMK2500', 'Kelambu Monique T 180', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMK2600', 'Kelambu Pintu ( Door Mesh )', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'DMT1106', 'KELAMBU POLOS DEWASA DIALOGUE NO.2', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1500', 'KELAMBU PRINT T.200 M.02 PLUS SCHALOOP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3600', 'KELAMBU REFILL PRINT MOTIF ZOO', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'IMK3300', 'KELAMBU ROSALINDA', 'ROSALINDA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'ROSALINDA');
INSERT INTO public.tr_product VALUES (3, 'IMK3003', 'Kelambu sahara kombinasi daun bambu', 'SAHARA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SAHARA');
INSERT INTO public.tr_product VALUES (3, 'IMK3000', 'Kelambu Sahara T 160', 'SAHARA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SAHARA');
INSERT INTO public.tr_product VALUES (3, 'IMK2311', 'KELAMBU SEGI BORDIR BUNGA', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMK1235', 'KELAMBU SEGI MAESTRO MINIMALIS', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK1223', 'KELAMBU SEGI MAESTRO RAINBOW', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK2001', 'Kelambu Sky Love Florencia', 'FLORENCIA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FLORENCIA');
INSERT INTO public.tr_product VALUES (3, 'KAT1341', 'KELAMBU SKYLOVE FLORENCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1913', 'KELAMBU TENDA BERMAIN ANAK POLKADOT BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1903', 'KELAMBU TENDA BERMAIN ANAK POLKADOT HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IKO1923', 'KELAMBU TENDA BERMAIN ANAK POLKADOT PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK4004', 'KELAMBU TENDA LIPAT DIALOGUE-DW', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IMK4001', 'KELAMBU TENDA LIPAT GRANDEA', 'GRANDEA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'GRANDEA');
INSERT INTO public.tr_product VALUES (3, 'IMK4000', 'KELAMBU TENDA LIPAT MAESTRO', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK4002', 'KELAMBU TENDA MOTIF NATURE UK. 180X200X160', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IMK4003', 'KELAMBU TENDA MOTIF NATURE UK. 200X200X160', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'IMK1050', 'KELAMBU TILLE 3K', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2250', 'KELAMBU TILLE 3K 100X200X130 MUNCAK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2007', 'KELAMBU TILLE 3K 100X200X130 PELANGI', 'PELANGI', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PELANGI');
INSERT INTO public.tr_product VALUES (3, 'IMK1005', 'KELAMBU TILLE 3K PELANGI TANPA PINTU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3001', 'Kelambu Tille 3k Sahara 100x200x130 ', 'SAHARA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SAHARA');
INSERT INTO public.tr_product VALUES (3, 'IMK1100', 'KELAMBU TILLE 4K', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2008', 'KELAMBU TILLE 4K 120X200X130 PELANGI', 'PELANGI', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PELANGI');
INSERT INTO public.tr_product VALUES (3, 'IMK3002', 'Kelambu Tille 4k Sahara 120x200x130 ', 'SAHARA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SAHARA');
INSERT INTO public.tr_product VALUES (3, 'DLK0140', 'Kelambu Tille 4 Pintu Prestige 180x200x200', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1401', 'KELAMBU TILLE BAYI BORDIR 1 TIANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1404', 'KELAMBU TILLE BAYI BORDIR 2 TIANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLK0144', 'KELAMBU TILLE DOMETRIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLK0126', 'Kelambu Tille King TE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMK2405', 'Kelambu Tille King TE', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK2406', 'Kelambu Tille King TE Mambo Print', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK2404', 'Kelambu Tille King TE Print', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK2403', 'Kelambu Tille King TE Ring Kotak', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAT1541', 'KELAMBU TILLE PELANGI 180X200 (+PINTU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2002', 'Kelambu Tille Pelangi 180 x 200 x 200 ( + pintu )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2004', 'Kelambu Tille Pelangi 180 x 200 x 200 ( + pintu ) Ratu Ayu', 'RATU AYU', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'RATU AYU');
INSERT INTO public.tr_product VALUES (3, 'KAT1442', 'KELAMBU TILLE PELANGI 200 (TNP PINTU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2003', 'Kelambu Tille Pelangi 200 x 200 x 200 (Tanpa Pintu )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK2005', 'Kelambu Tille Pelangi 200 x 200 x 200 (Tanpa Pintu ) Muncak', 'MUNCAK', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MUNCAK');
INSERT INTO public.tr_product VALUES (3, 'IMK1009', 'KELAMBU TILLE PELANGI (MERK MUNCAK)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1003', 'KELAMBU TILLE PELANGI (+PINTU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1590', 'KELAMBU TILLE PELANGI SINGEL SAMBUNGAN (PINTU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1004', 'KELAMBU TILLE PELANGI (TANPA PINTU)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLK0142', 'Kelambu Tille Renda Plus Pintu u.k 180 x 200 x 200 cm ( DOMETRIA )', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'DLK0143', 'Kelambu Tille Renda Tanpa Pintu u.k 180 x 200 x 200 cm ( TEORIA )', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'DLK0141', 'Kelambu Tille Schaloop u.k 180 x 200 x 200 cm ( BELVA )', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'IMK1250', 'KELAMBU TILLE ZAHRA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1515', 'KELAMBU TILLR PELANGI 200(MRK MUNCAK)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4955', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4956', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4957', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4958', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH6000', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH6418', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH6419', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1000', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2004', 'KERUDUNG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2500', 'KERUDUNG POLOS B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2002', 'KERUDUNG POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2003', 'KERUDUNG POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH5000', 'KERUDUNG POLOS CJ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4907', 'KERUDUNG POLOS TB 300', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4908', 'KERUDUNG POLOS TB 300', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW3000', 'KERUDUNG POLOS VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4905', 'KERUDUNG PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4906', 'KERUDUNG PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AKT1011', 'KEY TEETHER HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AKT1012', 'KEY TEETHER KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AKT1013', 'KEY THEETHER HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTHB035', 'KEZZIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHK037', 'KHANZA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTHB037', 'KHANZA BESAR', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'DLK0111', 'KOJONG BAYI BESAR DIALOGUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2001', 'KOJONG BAYI BESAR LIPAT B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW1002', 'KOJONG BAYI KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW2000', 'KOJONG TARIK 30 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'CLL0001', 'LABEL CLENCY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TLB1004', 'L. BORDIR OVAL M.DUA BUNGA', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TLB1003', 'L. BORDIR SEGI M.DUA BUNGA', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IML1411', 'L.BSR A OVAL MST POLOS TP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1422', 'L.BSR A OVAL MST POLOS TP PACK (BR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1421', 'L.BSR A SEGI MST POLOS TP (br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1042', 'L.BSR A SEGI POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9860', 'L.BSR B OVAL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1007', 'L.BSR B SEGI MST PRINT TP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1101', 'L.BSR B SEGI PLS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7350', 'L.BSR B SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KSPK011', 'LIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK030', 'LIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK096', 'LINNA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'PRL1426', 'LOVER KOKET BATIK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL2007', 'LOVER KOKET BATIK ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'TLB1001', 'LOVER KOKET M/ETNIK GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1134', 'LOVER KOKET M.ETNIX GLITER ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1130', 'LOVER KOKET M/MATAHARI TP', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TLB1002', 'LOVER KOKET MOTIF NATAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1129', 'LOVER KOKET PRINT M/NATAL TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TAS1100', 'LOVER KOKET PRINT M/NATAL TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL2003', 'LOVER MOTIF BATIK ( WINTER)', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRL2001', 'LOVER MOTIF FLAMINGO (SUMMER)', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRL2002', 'LOVER MOTIF MAWAR (SPRING)', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'IML1004', 'LOVER PRINT 300', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1401', 'LOVER PRINT 300', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1113', 'LOVER PRINT KOKET M/NATAL TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR1100', 'LOVER PRINT M-01 TRIKOT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9750', 'LOVER PRINT OVAL BESAR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1121', 'LOVER PRINT OVAL M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1112', 'LOVER PRINT OVAL M-05', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1020', 'LOVER PRINT OVAL SEDANG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1022', 'LOVER PRINT OVAL SEDANG (M.BINGKAI)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SSR1010', 'LOVER PRINT SEGI 100X45 M.BUNGA ADDENIUM M017', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PXT6522', 'LOVER PRINT SEGI 100X45 M.BUNGA SARI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PXT6521', 'LOVER PRINT SEGI 45X100 M. BUNGA KUMBANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1023', 'LOVER PRINT SEGI BESAR N/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1021', 'LOVER PRINT SEGI BESAR N/W (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1115', 'LOVER PRINT SEGI M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV2406', 'LOVER PRINT SEGI M-09(K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1603', 'LOVER PRINT SEGI SDG M-01(K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV2405', 'LOVER PRINT SEGI SDG M-02(K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1114', 'LOVER PRINT SEGI TB M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1116', 'LOVER PRINT SEGI TB M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1117', 'LOVER PRINT SEGI TB M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1104', 'LOVER RD BESAR OVAL A POLOS 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9870', 'LOVER RD BESAR OVAL A PRINT 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1137', 'LOVER RD BESAR OVAL B POLOS 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9880', 'LOVER RD BESAR OVAL B PRINT 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1009', 'LOVER RD BESAR OVAL B PRINT MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1402', 'LOVER RD BESAR SEGI A POLOS MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7500', 'LOVER RD BESAR SEGI A PRINT 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1403', 'LOVER RD BESAR SEGI B POLOS MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7750', 'LOVER RD BESAR SEGI B PRINT 42X102', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1401', 'LOVER RD BULAT JL 17', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1005', 'LOVER RD BULAT PRINT GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1003', 'LOVER RD OVAL SEDANG A PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1433', 'LOVER RD PLS OVAL NATURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL2005', 'LOVER RD PLS PANJANG  + RUMBAI M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1427', 'LOVER RD PLS SEGI NATURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1456', 'Lover  Rd polos 100X50 Rg Tb', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1254', 'LOVER RD.POLOS 100X50 RGTP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1407', 'Lover rd polos 300', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'VSL1003', 'LOVER RD POLOS 300 (4BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1434', 'LOVER RD. POLOS 300 NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'XRV1307', 'LOVER RD POLOS 300 TUTON NYLON (4BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1162', 'Lover Rd. Polos 50x90 Oval 9B', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IML1416', 'LOVER RD.POLOS BSR A WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1559', 'LOVER RD POLOS M.ARWANA RUMBAI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1165', 'Lover Rd. Polos Oval 9A', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IML1404', 'LOVER RD POLOS OVAL BESAR D/RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1102', 'LOVER RD.POLOS OVAL BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1258', 'LOVER RD.POLOS OVAL BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1410', 'LOVER RD.POLOS OVAL BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LST1000', 'LOVER RD.POLOS OVAL BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LVR1013', 'LOVER RD.POLOS OVAL BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1275', 'LOVER RD.POLOS OVAL BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LVR1611', 'LOVER RD.POLOS OVAL BSR B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LVV1012', 'LOVER RD.POLOS OVAL BSR B MAESTRO (Br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4003', 'LOVER RD POLOS OVAL BSR M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL2002', 'LOVER RD POLOS OVAL BSR M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL8003', 'LOVER RD POLOS OVAL BSR M. BUNGA MAWAR', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3002', 'LOVER RD POLOS OVAL BSR M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL6003', 'LOVER RD POLOS OVAL BSR M. SAKURA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL5003', 'LOVER RD POLOS OVAL BSR M. TRIBALL', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1552', 'LOVER RD POLOS OVAL M.ARWANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL3720', 'LOVER RD.POLOS OVAL M.BUNGA MAWAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL9003', 'LOVER RD. POLOS OVAL M/KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1449', 'LOVER RD POLOS OVAL NATURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1209', 'LOVER RD.POLOS OVAL SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1417', 'LOVER RD.POLOS OVAL SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LXH4201', 'LOVER RD.POLOS OVAL SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LXT320900K', 'LOVER RD.POLOS OVAL SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1113', 'LOVER RD.POLOS OVAL SDG A MAESTRO (Br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1424', 'LOVER RD.POLOS OVAL SDG A MAESTRO BROTHER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1431', 'LOVER RD.POLOS OVAL SDG.A WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1236', 'LOVER RD.POLOS OVAL SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1418', 'LOVER RD.POLOS OVAL SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1105', 'LOVER RD.POLOS OVAL SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1106', 'LOVER RD.POLOS OVAL SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1114', 'LOVER RD.POLOS OVAL SDG B MAESTRO (Br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VDB1000', 'LOVER RD.POLOS OVAL SDG B NYLON (2 BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'XXA1208', 'LOVER RD POLOS OVAL SDG B NYLON (4BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4009', 'LOVER RD POLOS OVAL SEDANG M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL7005', 'LOVER RD POLOS PANJANG M.MINIMALIS', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1424', 'LOVER RD.POLOS PANJANG+RUMBAI M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6116', 'LOVER RD POLOS SEGI 45X90 TUTON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1403', 'LOVER RD.POLOS SEGI BESAR D/RG VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1417', 'LOVER RD POLOS SEGI BESAR E VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1419', 'LOVER RD POLOS SEGI BESAR E VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL2008', 'LOVER RD.POLOS SEGI BESAR M.SAKURA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1043', 'LOVER RD.POLOS SEGI BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCH4201', 'LOVER RD.POLOS SEGI BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCH420100A', 'LOVER RD.POLOS SEGI BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1247', 'LOVER RD.POLOS SEGI BSR A/WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1425', 'LOVER RD.POLOS SEGI BSR A WRN NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1044', 'LOVER RD.POLOS SEGI BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1213', 'LOVER RD.POLOS SEGI BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1423', 'LOVER RD.POLOS SEGI BSR B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCH420100B', 'LOVER RD.POLOS SEGI BSR B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCH420100C', 'LOVER RD.POLOS SEGI BSR B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCS2201', 'LOVER RD.POLOS SEGI BSR B MAESTRO (Br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1248', 'LOVER RD.POLOS SEGI BSR B/WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1600', 'LOVER RD POLOS SEGI BSR E', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4001', 'LOVER RD POLOS SEGI BSR M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL2001', 'LOVER RD POLOS SEGI BSR M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL8001', 'LOVER RD POLOS SEGI BSR M. BUNGA MAWAR', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3001', 'LOVER RD POLOS SEGI BSR M. NATURE', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL6001', 'LOVER RD POLOS SEGI BSR M. SAKURA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL5001', 'LOVER RD POLOS SEGI BSR M. TRIBALL', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'XMV1407', 'LOVER RD POLOS SEGI E D/W (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1549', 'LOVER RD POLOS SEGI M.ARWANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL9001', 'LOVER RD. POLOS SEGI M/KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1142', 'LOVER RD POLOS  SEGI SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1138', 'LOVER RD.POLOS SEGI SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1413', 'LOVER RD.POLOS SEGI SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCS2202', 'LOVER RD.POLOS SEGI SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LCS220200B', 'LOVER RD.POLOS SEGI SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LSR1501', 'LOVER RD.POLOS SEGI SDG A MAESTRO (Br)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1415', 'LOVER RD.POLOS SEGI SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LPT2002', 'LOVER RD.POLOS SEGI SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LPT3209', 'LOVER RD.POLOS SEGI SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'XRL1525', 'LOVER RD POLOS SEGI SDG B NYLON (4BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1426', 'LOVER RD.POLOS SEGI SDG E', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1222', 'LOVER RD.POLOS SEGI SDG E D/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1570', 'LOVER RD.POLOS SEGI SDG M.ARWANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4007', 'LOVER RD POLOS SEGI SEDANG M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1252', 'LOVER RD.POLOS SEGI T.10 BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1021', 'LOVER RD POLOS TB 45X180', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1156', 'Lover  Rd print 100X50 Rg Tb', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PLS1004', 'LOVER RD PRINT 100X50 RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1008', 'Lover rd print 300', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1101', 'Lover  Rd .Print  300 ( Full Print )', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'MST2001', 'LOVER RD.PRINT 300 TUTON NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1003', 'LOVER RD PRINT 300 VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1175', 'Lover Rd. Print oval 9A', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IXK1401', 'LOVER RD PRINT OVAL BESAR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1006', 'LOVER RD PRINT OVAL BESAR D/RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9260', 'LOVER RD.PRINT OVAL BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9500', 'LOVER RD.PRINT OVAL BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KXT1106', 'LOVER RD.PRINT OVAL BSR A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9800', 'LOVER RD.PRINT OVAL BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9850', 'LOVER RD.PRINT OVAL BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1113', 'LOVER RD.PRINT OVAL BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KXT6115', 'LOVER RD.PRINT OVAL BSR B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1147', 'LOVER RD.PRINT OVAL BSR D/RG (M-02)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4004', 'LOVER RD PRINT OVAL BSR M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL2003', 'LOVER RD PRINT OVAL BSR M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL8004', 'LOVER RD PRINT OVAL BSR M. BUNGA MAWAR', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3004', 'LOVER RD PRINT OVAL BSR M. NATURE', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL6004', 'LOVER RD PRINT OVAL BSR M. SAKURA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL5004', 'LOVER RD PRINT OVAL BSR M. TRIBALL', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IXL1005', 'LOVER RD PRINT OVAL DRG VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1554', 'LOVER RD PRINT OVAL M.ARWANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL9004', 'LOVER RD. PRINT OVAL M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9890', 'LOVER RD.PRINT OVAL SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1129', 'LOVER RD.PRINT OVAL SDG A (FULL PRINT M/01)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KXT611500V', 'LOVER RD.PRINT OVAL SDG A MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1001', 'LOVER RD.PRINT OVAL SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1134', 'LOVER RD.PRINT OVAL SDG B (FULL PRINT)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KXT647200V', 'LOVER RD.PRINT OVAL SDG B MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MRT1002', 'LOVER RD.PRINT OVAL SDG E (FULL PRINT)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4010', 'LOVER RD PRINT OVAL SEDANG M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1149', 'LOVER RD.PRINT OVAL T17 BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL7006', 'LOVER RD PRINT PANJANG M.MINIMALIS', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL1425', 'LOVER RD.PRINT PANJANG+RUMBAI M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1001', 'LOVER RD PRINT ROSE GARDEN TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1122', 'LOVER RD PRINT SDG A OVAL GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1017', 'LOVER RD PRINT SEDANG E VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXA1208', 'LOVER RD. PRINT SEGI BESAR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1418', 'LOVER RD.PRINT SEGI BESAR A NECI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4003', 'LOVER RD.PRINT SEGI BESAR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1505', 'LOVER RD.PRINT SEGI BESAR B NECI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4202', 'LOVER RD. PRINT SEGI BESAR B VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1016', 'LOVER RD.PRINT SEGI BESAR E', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL2009', 'LOVER RD.PRINT SEGI BESAR M.SAKURA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK6500', 'LOVER RD.PRINT SEGI BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7000', 'LOVER RD.PRINT SEGI BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1509', 'LOVER RD.PRINT SEGI BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1510', 'LOVER RD.PRINT SEGI BSR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MKL1001', 'LOVER RD.PRINT SEGI BSR A (FULL PRINT M/01)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7260', 'LOVER RD.PRINT SEGI BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7270', 'LOVER RD.PRINT SEGI BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1513', 'LOVER RD.PRINT SEGI BSR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MRT2002', 'LOVER RD.PRINT SEGI BSR B ( FULL PRINT/M-01)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PLS1001', 'LOVER RD.PRINT SEGI BSR D/RG (M-02)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MST3201', 'LOVER RD.PRINT SEGI BSR E FULL PRINT(M-02)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4002', 'LOVER RD PRINT SEGI BSR M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL2004', 'LOVER RD PRINT SEGI BSR M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL8002', 'LOVER RD PRINT SEGI BSR M. BUNGA MAWAR', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3003', 'LOVER RD PRINT SEGI BSR M. NATURE', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL6002', 'LOVER RD PRINT SEGI BSR M. SAKURA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL5002', 'LOVER RD PRINT SEGI BSR M. TRIBALL', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'MST1201', 'LOVER RD.PRINT SEGI BSR RG(FULL PRINT)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL9002', 'LOVER RD. PRINT SEGI M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7760', 'LOVER RD.PRINT SEGI SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1514', 'LOVER RD.PRINT SEGI SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4203', 'LOVER RD PRINT SEGI SDG A 38X82 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MKL1002', 'LOVER RD.PRINT SEGI SDG A (FULL PRINT M/01)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PLS1002', 'LOVER RD.PRINT SEGI SDG A FULL PRINT (M-02)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1131', 'LOVER RD PRINT SEGI SDG A GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK8350', 'LOVER RD.PRINT SEGI SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK8500', 'LOVER RD.PRINT SEGI SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1517', 'LOVER RD.PRINT SEGI SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1518', 'LOVER RD.PRINT SEGI SDG B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1007', 'LOVER RD PRINT SEGI SDG B MARGARETHA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1402', 'LOVER RD.PRINT SEGI SDG E FULL PRINT (M-02)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4302', 'LOVER RD. PRINT SEGI SEDANG A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4008', 'LOVER RD PRINT SEGI SEDANG M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PLS1003', 'LOVER RD.PRINT SEGI T.10 BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK6000', 'LOVER RD PRINT TP 45X180', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK5000', 'LOVER RD.PRINT TP 45X180', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1049', 'LOVER RD PRINT TUTTON 9A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1123', 'LOVER RD PRINT TUTTON 9B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL2006', 'LOVER RD PRT PANJANG  + RUMBAI M/BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IML1241', 'LOVER RD SEDANG OVAL B POLOS 38X82', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1206', 'LOVER RD SEDANG SEGI A POLOS 38X82', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9250', 'LOVER RD SEDANG SEGI A PRINT 38X82', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1011', 'LOVER RD SEDANG SEGI A PRINT MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1401', 'LOVER RD SEGI JL 22X27 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4005', 'LOVER RD SEGI POLOS M.ARWANA + RUMBAI', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3007', 'LOVER RD SEGI POLOS NATURE+RUMBAI', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL4006', 'LOVER RD SEGI PRINT M.ARWANA + RUMBAI', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3008', 'LOVER RD SEGI PRINT NATURE+RUMBAI ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMK8000', 'LOVER RD.SEGI SDG A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1003', 'LOVER RD TUTON OVAL 9A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MKL1000', 'LOVER RD TUTON OVAL 9B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1120', 'Lover Rd. Tutton 45x90 Oval 9B', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'PRL1163', 'Lover Rd. Tutton Oval 9A', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IXL1402', 'LOVER SEGI BESAR D/RG POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL4011', 'LOVER SEGI SEDANG M.ARWANA DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0004', 'LOVER SET BORDIR M.BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1414', 'LOVER SET PRINT SEGI HLTB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1417', 'LOVER SET PRINT SEGI RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1901', 'LOVER TRIKOT MOTIF DAHLIA', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRL1903', 'LOVER TRIKOT MOTIF ISTANBUL', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRL1902', 'LOVER TRIKOT MOTIF JASMINE', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'KVT0007', 'LOVER TUTTON 9B PRINT OVAL+L.PRINT 9B OVAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1123', 'L. PRINT M. BUNGA SARI', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRL1120', 'L. PRINT M. MATAHARI', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRL1122', 'L. PRT.  SEGI 45X100 M/KUMBANG', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRL1211', 'L. PRT.  SEGI 45X90 M/MELATI', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRL1124', 'L PRT. SEGI  M.BUNGA ADDENIUM M.017  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1125', 'L PRT. SEGI  M.BUNGA ROSIANA M.018 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1128', 'L PRT. SEGI M.KEMBANG SEPATU ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1136', 'L PRT. SEGI  M.NATAL TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1126', 'L PRT. SEGI  M.ROSIANA M.018 FOAM HBS STOCK. ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRL1127', 'L PRT. SEGI  M.ROSIANA M.018 FOAM TNP PACK ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1453', 'L.RD 100 X 50 RGTP POLOS', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IML1239', 'L. RD 300 FULL PRT NILON', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IXL1201', 'L RD 300 POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH5017', 'L RD BESAR A OVAL PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1404', 'L RD BESAR OVAL A MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXJ1003', 'L RD BESAR OVAL A PRINT PRG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1406', 'L RD BESAR OVAL B MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1006', 'L RD BESAR OVAL B MAESTRO PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1032', 'L RD BESAR OVAL B POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1040', 'L RD BESAR OVAL B POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW4000', 'L RD BESAR SEGI A PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4001', 'L RD BESAR SEGI A PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4201', 'L RD BESAR SEGI B PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9600', 'L.RD BSR A OVAL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK7250', 'L.RD BSR A SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1401', 'L.RD BSR B SEGI PRINT(FREE SAND HLTP)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1015', 'L.RD OVAL BESAR B PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1221', 'L. RD OVAL BSR A (FULL PRT) ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1246', 'L. RD OVAL BSR A (FULL PRT M.02)  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1230', 'L. RD OVAL SDG B FULL PRT', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IML1238', 'L.RD OVAL SDG R/RG POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0009', 'L RD PLS 300 NYLON+VB RD PLS 30X40NYILON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LVR4403', 'L.RD PLS 300 NYLON+VB RD PRT SEGI 30X40', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1505', 'L. RD PLS. OVAL BSR A  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1506', 'L. RD PLS. OVAL BSR B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1551', 'L. RD PLS. OVAL BSR F TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1513', 'L. RD PLS. OVAL SDG A ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1514', 'L. RD PLS. OVAL SDG B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KVT0005', 'L.RD PLS OVAL SDG B NYLON+SAND RD PLS NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LSR1701', 'L.RD PLS OVAL SDG B NYLON+SAND RD PLS NYLON', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1560', 'L. RD PLS. OVAL T.8-28 KECIL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1405', 'L. RD PLS. SEGI BSR A  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1406', 'L. RD PLS. SEGI BSR B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IML1406', 'L.RD PLS SEGI BSR D/RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KML1408', 'L. RD PLS. SEGI BSR E', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1413', 'L. RD PLS. SEGI SDG A ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1414', 'L. RD PLS. SEGI SDG B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IML1441', 'L. RD PLS. SEGI SDG E', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'LVR1102', 'L.RD PLS SEGI SDG E D/W + VB RD PLS SEGI 30X40', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1249', 'L RD POLOS BESAR B NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1023', 'L.RD POLOS OVAL BESAR A PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1231', 'L RD POLOS SDG A NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1215', 'L RD POLOS SDG A TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1022', 'L.RD POLOS SEGI BSR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1416', 'L. RD POLOS. SEGI SDG E D/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1421', 'L.RD POLOS SEGI SDG E VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1427', 'L.RD POLOS SEGI SEDANG A MST (TN)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1403', 'L.RD PRINT 300 FULL PRINT(FREE 2 PCS SAND)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1404', 'L.RD PRINT OVAL 9A(FREE 2 PCS SAND)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH5011', 'L RD PRINT OVAL BESAR A PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1020', 'L.RD PRINT OVAL BSR A MST (TN)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXJ1001', 'L.RD PRINT OVAL BSR A PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXJ1004', 'L.RD PRINT OVAL BSR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1004', 'L.RD PRINT OVAL BSR D/RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1223', 'L. RD PRINT  OVAL SDG A  GLITTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXL1017', 'L.RD PRINT SEGI BESAR E', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4002', 'L.RD PRINT SEGI BSR A VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1224', 'L. RD PRINT SEGI SDG A GLITTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXH5002', 'L.RD PRINT SEGI SDG B VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4301', 'L RD PRINT SEGI SEDANG A (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4204', 'L.RD PRINT SEGI SEDANG A PRESTIGE (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1166', 'L. RD PRINT TUTON 9B BW', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'PRL1153', 'L. RD PRT. 50 x 100 RGTP', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1205', 'L. RD PRT. OVAL BSR A ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1206', 'L. RD PRT. OVAL BSR B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1251', 'L. RD PRT. OVAL BSR F TB  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1255', 'L. RD PRT. OVAL BSR F TB GLITTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1214', 'L. RD PRT. OVAL SDG B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1259', 'L. RD PRT. OVAL T.8', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1260', 'L. RD PRT. OVAL T.8-28 KECIL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRL1105', 'L. RD PRT. SEGI BSR A ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1106', 'L. RD PRT. SEGI BSR B', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1002', 'L. RD PRT. SEGI BSR B NECI', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IML1040', 'L. RD PRT. SEGI BSR. E', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1114', 'L. RD PRT. SEGI SDG B ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IML1041', 'L. RD PRT. SEGI SDG. E', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1417', 'L. RD PRT. SEGI SDG E D/W', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMK9990', 'L.RD SDG A OVAL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1411', 'L RD SEDANG A OVAL MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1024', 'L.RD SEDANG OVAL A FULL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1008', 'L RD SEDANG OVAL A MAESTRO PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1413', 'L RD SEDANG OVAL B MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1407', 'L RD SEDANG SEGI A MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1408', 'L RD SEDANG SEGI B MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1410', 'L RD SEDANG SEGI B POLOS MAESTRO (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH4303', 'L RD SEDANG SEGI B PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXH5001', 'L RD SEDANG SEGI B PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1121', 'L. RD SEGI BSR A (FULL PRT) ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1146', 'L. RD SEGI BSR A (FULL PRT M.02) ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1128', 'L. RD SEGI BSR. E FULL PRT', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1145', 'L. RD SEGI BSR. E FULL PRT M.02', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1148', 'L. RD SEGI SDG A (FULL PRT M.02) ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRL1130', 'L. RD SEGI SDG B FULL PRT', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAL1123', 'L. RD SEGI SDG. E FULL PRT', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAL1144', 'L. RD SEGI SDG. E FULL PRT M.02', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRL1220', 'l.rd Tuton 9b print', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL1164', 'L.RD TUTON PRINT 9A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1201', 'L.SDG A SEGI PLS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK8250', 'L.SDG A SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1237', 'L.SDG B OVAL PLS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK9000', 'L.SDG B SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFM1010', 'MAINAN GANTUNG JERAPAH', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM1020', 'MAINAN GANTUNG MONYET', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM1060', 'MAINAN GANTUNG PORCUPINE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM1070', 'MAINAN GANTUNG TIGER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'IMH4408', 'MAKLO0N BORDIR M.KEPALA GAJAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4831', 'MAKLON B M.BABY JOY BALON DIATAS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4841', 'MAKLON B M.BABY JOY BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4791', 'MAKLONN BORDIR M. BABY BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1534', 'Makloom M.Tiga Panda Besar', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1510', 'Makloon Bear Gap', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1511', 'Makloon Bear Love', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4821', 'MAKLOON B M.BABY JOY BALON DI TENGAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2117', 'MAKLOON BORDIR 1 KELINCI+LIITLE BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2116', 'MAKLOON BORDIR 1 KELINCI LOVE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4861', 'MAKLOON BORDIR BABY JOY BALON ATAS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4871', 'MAKLOON BORDIR BABY JOY BALON BALON DITENGAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4881', 'MAKLOON BORDIR BABY JOY BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1507', 'MAKLOON BORDIR BATH BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1506', 'MAKLOON BORDIR BEAR BALON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1508', 'MAKLOON BORDIR BEAR LEAF', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1509', 'MAKLOON BORDIR BEAR LEAF 2', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4507', 'MAKLOON BORDIR BEAR RODA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1394', 'MAKLOON BORDIR CAT 2 APLIKASI/KOALA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4500', 'MAKLOON BORDIR CAT DOLL FACE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4685', 'MAKLOON BORDIR DUCK POND 2 APLKS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1525', 'MAKLOON BORDIR FUNKY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1498', 'MAKLOON BORDIR GBI BETHEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1481', 'MAKLOON BORDIR H ABSRBA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1452', 'MAKLOON BORDIR H ADVENTURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1000', 'MAKLOON BORDIR H AIR CARGO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1453', 'MAKLOON BORDIR H AMERICAN FLAG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1454', 'MAKLOON BORDIR H ANAK LUMBA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1377', 'MAKLOON BORDIR H ANGEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1438', 'MAKLOON BORDIR H ANGELITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1367', 'MAKLOON BORDIR H APEL B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1372', 'MAKLOON BORDIR H APEL B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1329', 'MAKLOON BORDIR H APEL,JAMBU,STRAWBERY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1334', 'MAKLOON BORDIR H APLIKASI CAMPUR/BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4406', 'MAKLOON BORDIR H APPC', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1381', 'MAKLOON BORDIR H AYAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1397', 'MAKLOON BORDIR H AYAM <APL>', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1428', 'MAKLOON BORDIR H AZALEA B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1431', 'MAKLOON BORDIR H AZELIA K', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1429', 'MAKLOON BORDIR H AZELIA S', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1303', 'MAKLOON BORDIR H BABY 2 BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4407', 'MAKLOON BORDIR H BABY 2 KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1304', 'MAKLOON BORDIR H BABY 2 KECIL NON APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1342', 'MAKLOON BORDIR H BADUT RODA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1410', 'MAKLOON BORDIR H BEAR B KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1400', 'MAKLOON BORDIR H BEAR BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1448', 'MAKLOON BORDIR H BEAR CLOWN KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4400', 'MAKLOON BORDIR H BEAR KADO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1444', 'MAKLOON BORDIR H BEAR KADO (K)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1526', 'MAKLOON BORDIR H BEAR KADO (K)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1388', 'MAKLOON BORDIR H BEAR MUMA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1411', 'MAKLOON BORDIR H BEAR POLA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1338', 'MAKLOON BORDIR H BEAR RODA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1363', 'MAKLOON BORDIR H BEAR SKY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1339', 'MAKLOON BORDIR H BEAR STAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1445', 'MAKLOON BORDIR H BEAR STAR (K)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1403', 'MAKLOON BORDIR H BEAR STAR KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1471', 'MAKLOON BORDIR H BEAR TOPI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4401', 'MAKLOON BORDIR H BEAR V', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4309', 'MAKLOON BORDIR H BEBEK 2 AH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4506', 'MAKLOON BORDIR H.BEBEK 2 AH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1345', 'MAKLOON BORDIR H BEBEK 2 ANAK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4509', 'MAKLOON BORDIR H.BEBEK 2 ANAK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1300', 'MAKLOON BORDIR H BEBEK B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1395', 'MAKLOON BORDIR H BEBEK JALAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1385', 'MAKLOON BORDIR H BENDERA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1425', 'MAKLOON BORDIR H BG.DAUN ULIR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1414', 'MAKLOON BORDIR H BG.RENDA OVAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1441', 'MAKLOON BORDIR H BINTANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1412', 'MAKLOON BORDIR H BIRD CREST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4308', 'MAKLOON BORDIR H BLUE SKY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1305', 'MAKLOON BORDIR H BLUE SKY NON APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1413', 'MAKLOON BORDIR H BRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMG1700', 'MAKLOON BORDIR H BUCHI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1449', 'MAKLOON BORDIR H BUNGA MAWAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1301', 'MAKLOON BORDIR H BUNGA TULIP PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1389', 'MAKLOON BORDIR H BYBS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4409', 'MAKLOON BORDIR H CALIFORNIA BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1306', 'MAKLOON BORDIR H CALIFORNIA KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1354', 'MAKLOON BORDIR H CAPUNG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1472', 'MAKLOON BORDIR H CAROLINE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4307', 'MAKLOON BORDIR H CAT 2 GELAS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1360', 'MAKLOON BORDIR H CAT 2 KERANJANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1406', 'MAKLOON BORDIR H CAT 2 KERANJANG BSR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1405', 'MAKLOON BORDIR H CAT 2 KERANJANG KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1348', 'MAKLOON BORDIR H CAT 2 PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1343', 'MAKLOON BORDIR H CAT CLUB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1347', 'MAKLOON BORDIR H CAT DANCE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1426', 'MAKLOON BORDIR H CHALLENGER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1437', 'MAKLOON BORDIR H COLORADO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1447', 'MAKLOON BORDIR H CRAB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1415', 'MAKLOON BORDIR H CREST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMC1700', 'MAKLOON BORDIR H DANCE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1488', 'MAKLOON BORDIR HELLO KITTY A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1489', 'MAKLOON BORDIR HELLO KITTY B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1210', 'MAKLOON BORDIR H FAMILI PICNIC', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1446', 'MAKLOON BORDIR H FLOWER IN GARDEN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4422', 'MAKLOON BORDIR H FOOT BALL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4423', 'MAKLOON BORDIR H FOOT BALL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1455', 'MAKLOON BORDIR H GAJAH LAYANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1374', 'MAKLOON BORDIR H GAS NEGARA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1476', 'MAKLOON BORDIR H GLASS CLOTH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMG3101', 'MAKLOON BORDIR H GOLF CLUB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4405', 'MAKLOON BORDIR H GPPS (NA)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1416', 'MAKLOON BORDIR H HAPPY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1311', 'MAKLOON BORDIR H HELLO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1312', 'MAKLOON BORDIR H HELLO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4688', 'MAKLOON BORDIR HIBONE OTTO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1465', 'MAKLOON BORDIR H ICE CREAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1316', 'MAKLOON BORDIR H IKAN TUNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1327', 'MAKLOON BORDIR H JAMBU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1383', 'MAKLOON BORDIR H JERUSALEM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4421', 'MAKLOON BORDIR H JUST FOR ME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1365', 'MAKLOON BORDIR H KAKATUA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1315', 'MAKLOON BORDIR H KANGURU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1392', 'MAKLOON BORDIR H KAOS KAKI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1378', 'MAKLOON BORDIR H KELINCI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1380', 'MAKLOON BORDIR H KELINCI 2 APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1313', 'MAKLOON BORDIR H KELINCI KADO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1341', 'MAKLOON BORDIR H KERETA BAYI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1407', 'MAKLOON BORDIR H KID FOR RENT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4420', 'MAKLOON BORDIR H KIPAS MY LOVE BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1307', 'MAKLOON BORDIR H KIPAS MY LOVE KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1475', 'MAKLOON BORDIR H KITCHEN TOWEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1382', 'MAKLOON BORDIR H KRISTUS PENEBUS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1487', 'MAKLOON BORDIR H KRISTUS PENEBUS BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1376', 'MAKLOON BORDIR H KUPU-KUPU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1450', 'MAKLOON BORDIR H KUPU-KUPU BARU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1386', 'MAKLOON BORDIR H LAMPU BP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1387', 'MAKLOON BORDIR H LAMPU IP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1396', 'MAKLOON BORDIR H LILIN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1440', 'MAKLOON BORDIR H LILIN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1467', 'MAKLOON BORDIR H LION', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1101', 'MAKLOON BORDIR H LITTE RABBIT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1409', 'MAKLOON BORDIR H LITTLE RABBIT TNP TULISAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1451', 'MAKLOON BORDIR H LITTLE STAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1393', 'MAKLOON BORDIR H LONCENG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1350', 'MAKLOON BORDIR H LUCKY STRIKE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1336', 'MAKLOON BORDIR H LUMBA-LUMBA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1408', 'MAKLOON BORDIR H MAGIC', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1309', 'MAKLOON BORDIR H MATAHARI BSR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1308', 'MAKLOON BORDIR H MATAHARI KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1435', 'MAKLOON BORDIR H MIAMI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1443', 'MAKLOON BORDIR H MIAMI 20', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1390', 'MAKLOON BORDIR H MIBBY /KELINCI KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1473', 'MAKLOON BORDIR H MINI-MINI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1362', 'MAKLOON BORDIR H MOBIL ANTIK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1522', 'MAKLOON BORDIR H MUKA BONEKA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1364', 'MAKLOON BORDIR H NATURAL TEDDY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1373', 'MAKLOON BORDIR H NENAS SAWI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1318', 'MAKLOON BORDIR H NEW COUPLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1417', 'MAKLOON BORDIR H PALM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1356', 'MAKLOON BORDIR H PANDA AB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1357', 'MAKLOON BORDIR H PANDA AB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1474', 'MAKLOON BORDIR H PANDA BALON/NAIK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1402', 'MAKLOON BORDIR H PANDA KANTONG KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4508', 'MAKLOON BORDIR H.PANDA PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1466', 'MAKLOON BORDIR H PANDA TIDUR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1404', 'MAKLOON BORDIR H PANDA V KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1349', 'MAKLOON BORDIR H PARIS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMD1700', 'MAKLOON BORDIR H PARIS CLUB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1337', 'MAKLOON BORDIR H PERAHU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1358', 'MAKLOON BORDIR H PESANAN KHUSUS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1302', 'MAKLOON BORDIR H PET-PET BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4408', 'MAKLOON BORDIR H PET-PET KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4410', 'MAKLOON BORDIR H PET-PET KECIL NON APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1485', 'MAKLOON BORDIR H PINGUIN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1317', 'MAKLOON BORDIR H PKPRI KAB. PURBALINGGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1379', 'MAKLOON BORDIR H POHON KELAPA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1351', 'MAKLOON BORDIR H RABBIT BALON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1353', 'MAKLOON BORDIR H RABBIT WORTEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1335', 'MAKLOON BORDIR H RABIT JAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1344', 'MAKLOON BORDIR H RADISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1424', 'MAKLOON BORDIR H RAKET APL.', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1418', 'MAKLOON BORDIR H RENDA BG.HANDUK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1419', 'MAKLOON BORDIR H RODEO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1423', 'MAKLOON BORDIR H RUGBY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1468', 'MAKLOON BORDIR H SAYUR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1469', 'MAKLOON BORDIR H SAYUR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1352', 'MAKLOON BORDIR H SEMANGKA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1420', 'MAKLOON BORDIR H SEPASANG KELINCI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1319', 'MAKLOON BORDIR H SINGA (GARFIL)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1355', 'MAKLOON BORDIR H SIPUT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1314', 'MAKLOON BORDIR H SKY BOARD', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1359', 'MAKLOON BORDIR H SPT PESANAN KHUSUS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1310', 'MAKLOON BORDIR H STAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1398', 'MAKLOON BORDIR H SWEETHOME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1421', 'MAKLOON BORDIR H TEDDY BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1434', 'MAKLOON BORDIR H TELETUBIS 4K', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1433', 'MAKLOON BORDIR H TELETUBIS B-2', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1484', 'MAKLOON BORDIR H TENNIS TNP APL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1361', 'MAKLOON BORDIR H TERJUN PAYUNG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1432', 'MAKLOON BORDIR H TITANIC', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1384', 'MAKLOON BORDIR H TOPI ISRAEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1422', 'MAKLOON BORDIR H TOY BOX BSR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1401', 'MAKLOON BORDIR H TOY BOX (K)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1436', 'MAKLOON BORDIR H TULIPE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1442', 'MAKLOON BORDIR H TULIPE 20', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1439', 'MAKLOON BORDIR H UMBRELLA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1321', 'MAKLOON BORDIR H WORTEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1340', 'MAKLOON BORDIR H WORTEL 3', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1521', 'MAKLOON BORDIR KIDDY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2115', 'MAKLOON BORDIR LITTLE BEAR PARTY TIME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1460', 'MAKLOON BORDIR LOGO CEI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1461', 'MAKLOON BORDIR LOGO CHIEDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1464', 'MAKLOON BORDIR LOGO PODSI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1462', 'MAKLOON BORDIR LOGO SUZUKI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1503', 'MAKLOON BORDIR LUSTY BUNNY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4613', 'MAKLOON BORDIR M.1 BEAR PELAUT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4610', 'MAKLOON BORDIR M.1 KELINCI LOVE BEAR(KHUSUS)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4301', 'MAKLOON BORDIR M.1 KELINCI PARTY TIME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4302', 'MAKLOON BORDIR M.1 KELINCI WANITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4617', 'MAKLOON BORDIR M.2 BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4619', 'MAKLOON BORDIR M.2 BEAR KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4565', 'MAKLOON BORDIR M.3 BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4614', 'MAKLOON BORDIR M.3 CIRCLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4605', 'MAKLOON BORDIR M.ABBA LOVE KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1612', 'MAKLOON BORDIR M.ABDI RELLY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4686', 'MAKLOON BORDIR M. ALIUM TANPA TULISAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4618', 'MAKLOON BORDIR M.APEL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4616', 'MAKLOON BORDIR M.APLIKASI BEAR AWAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4671', 'MAKLOON BORDIR M BABY BEAR APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4851', 'MAKLOON BORDIR M.BABY BERDIRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4811', 'MAKLOON BORDIR M.BABY DUDUK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4305', 'MAKLOON BORDIR M.BABY JOY BALON TENGAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4306', 'MAKLOON BORDIR M.BABY JOY BALON TENGAH KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1546', 'MAKLOON BORDIR M.BABY JOY PESAWAT KELINCI K', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4304', 'MAKLOON BORDIR M.BABY JOY PESAWAT KELINCI KK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4303', 'MAKLOON BORDIR M.BABY JOY PESAWAT KELINCI S', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4603', 'MAKLOON BORDIR M.BABY TIME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1541', 'MAKLOON BORDIR M.BALON ATAS BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1540', 'MAKLOON BORDIR M.BALON ATAS KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1542', 'MAKLOON BORDIR M.BALON TENGAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1539', 'MAKLOON BORDIR M.BALON TENGAH BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4611', 'MAKLOON BORDIR M.BEAR AWAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1456', 'MAKLOON BORDIR M/BEAR BINTANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4606', 'MAKLOON BORDIR M.BEAR BUNGA BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4609', 'MAKLOON BORDIR M.BEAR BUNGA KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4625', 'MAKLOON BORDIR M.BEAR FACE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4627', 'MAKLOON BORDIR M.BEAR FACE 1', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4693', 'MAKLOON BORDIR M. BEAR KADO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4692', 'MAKLOON BORDIR M. BEAR V', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1611', 'MAKLOON BORDIR M. BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4626', 'MAKLOON BORDIR M.BENDERA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4608', 'MAKLOON BORDIR M.BE TRANSFORMED', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4801', 'MAKLOON BORDIR M. BONEKA BEAR SATU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4624', 'MAKLOON BORDIR M.Brandon H.Mc Elhoe''s', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4201', 'MAKLOON BORDIR M.BUKU KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4615', 'MAKLOON BORDIR M.BUNGA DAUN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2102', 'MAKLOON BORDIR M.BUNGA KUPU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4564', 'MAKLOON BORDIR M.BUNGA PAGER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4731', 'MAKLOON BORDIR M. BUNGA ROSA POT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4732', 'MAKLOON BORDIR M. BUNGA TULIP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4790', 'MAKLOON BORDIR M. CAT CLUB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4602', 'MAKLOON BORDIR M.CAT PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1427', 'MAKLOON BORDIR M CHALLENGER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4604', 'MAKLOON BORDIR M.CIPUT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4622', 'MAKLOON BORDIR M.CUTE BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1743', 'MAKLOON BORDIR M.DARI NY.ELLA SISWANTO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4684', 'MAKLOON BORDIR M DAUN LEAF', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4682', 'MAKLOON BORDIR M DIALOG BEAR PITA APLIKS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4629', 'MAKLOON BORDIR M.DIALOGUE BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4628', 'MAKLOON BORDIR M.DIALOGUE BABY APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4770', 'MAKLOON BORDIR M. DIALOGUE BABY LIITLE JKT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4672', 'MAKLOON BORDIR M DIALOGUE BEAR APLIKASI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4810', 'MAKLOON BORDIR M. DIALOGUE GROUP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4612', 'MAKLOON BORDIR M.DOG SHE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2118', 'MAKLOON BORDIR M.DOG TOPI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1610', 'MAKLOON BORDIR M. DOKTER JAGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1753', 'MAKLOON BORDIR M. DOKTER JAGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4795', 'MAKLOON BORDIR M. DOLPHIN JUMP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4607', 'MAKLOON BORDIR M.FLOWER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2101', 'MAKLOON BORDIR M.FUNNY RABBIT BUKU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2100', 'MAKLOON BORDIR M.FUNNY RABBIT BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4007', 'MAKLOON BORDIR M.FUNNY RABBIT KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4309', 'MAKLOON BORDIR M.GIVENCI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4799', 'MAKLOON BORDIR M. GO TO BEATH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4502', 'MAKLOON BORDIR M.HAPPY BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4696', 'MAKLOON BORDIR M. HAPPY NAPZ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4796', 'MAKLOON BORDIR M. HUT GII', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1496', 'MAKLOON BORDIR MICKY MOUSE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4304', 'MAKLOON BORDIR M.IKAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4780', 'MAKLOON BORDIR M. KEPALA BEAR JKT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4409', 'MAKLOON BORDIR M.KEPALA CAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4683', 'MAKLOON BORDIR M KEPALA LION', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4407', 'MAKLOON BORDIR M.KEP SWEET BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4720', 'MAKLOON BORDIR M. KOALA COOL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4694', 'MAKLOON BORDIR M. KUCING LAND', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4687', 'MAKLOON BORDIR M. KUDA PONI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4730', 'MAKLOON BORDIR M. KUDA PONI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4710', 'MAKLOON BORDIR M. KUPU KUPU COOL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1533', 'MAKLOON BORDIR M.KUPU-KUPU KCL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4400', 'MAKLOON BORDIR M.LIITLE GIRL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4403', 'MAKLOON BORDIR M.LITTLE BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4567', 'MAKLOON BORDIR M.LITTLE BEAR LOVE 1 KELINCI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH2110', 'MAKLOON BORDIR M.LITTLE BEAR SWEET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4401', 'MAKLOON BORDIR M.LITTLE BOY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4563', 'MAKLOON BORDIR M.LITTLE GARDEN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4620', 'MAKLOON BORDIR M.LITTLE PUSSY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4000', 'MAKLOON BORDIR M.LOVE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4307', 'MAKLOON BORDIR M.MAKARIOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1544', 'MAKLOON BORDIR M.MAMS BABY PA KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1543', 'MAKLOON BORDIR M.MAMS BABY PT KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1547', 'MAKLOON BORDIR M.MAMS BABY PT SEDANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4503', 'MAKLOON BORDIR M.MATA BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4798', 'MAKLOON BORDIR M. MEOW MEOW', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4623', 'MAKLOON BORDIR M.MRS.GOOSE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4305', 'MAKLOON BORDIR M.NATAL USIDA 2010', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4504', 'MAKLOON BORDIR M.NICE COUPLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4505', 'MAKLOON BORDIR M.NICE COUPLE KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4404', 'MAKLOON BORDIR M.NICE SLEEP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4405', 'MAKLOON BORDIR M.NICE SLEEP 1 BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4406', 'MAKLOON BORDIR M.NICE SLEEP 2 BEBEK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1700', 'MAKLOON BORDIR M.NY.ELLA SISWANTO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1745', 'MAKLOON BORDIR M.NY.INE RUDY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1486', 'MAKLOON BORDIR MOTIF GBT KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1399', 'MAKLOON BORDIR M.PANDA PITA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1744', 'MAKLOON BORDIR M.PATRIA''77 POLISI MILITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH3000', 'MAKLOON BORDIR M.PERMEN LITTLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1458', 'MAKLOON BORDIR M/PERSATUAN JUDO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0006', 'MAKLOON BORDIR M.POOH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1459', 'MAKLOON BORDIR M.POOH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1463', 'MAKLOON BORDIR M.POOH + BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1545', 'MAKLOON BORDIR M.PT BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4004', 'MAKLOON BORDIR M.RAMBA KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4695', 'MAKLOON BORDIR M. RIBBON BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4697', 'MAKLOON BORDIR M. RM PENGKOLAN KAOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4501', 'MAKLOON BORDIR M.RUMAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4903', 'MAKLOON BORDIR M.SAPI SNOOBY BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4902', 'MAKLOON BORDIR M.SAPI SNOOBY KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4689', 'MAKLOON BORDIR M SAPI WHITE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4690', 'MAKLOON BORDIR M. SINGA JAZZY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4698', 'MAKLOON BORDIR M. SKIBER BEAR GION', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4621', 'MAKLOON BORDIR M.SMART BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4794', 'MAKLOON BORDIR M. SNOBBY LION', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4793', 'MAKLOON BORDIR M. SNOBBY TIGER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4792', 'MAKLOON BORDIR M. SNOBY BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4600', 'MAKLOON BORDIR M.TAWON LELAKI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4601', 'MAKLOON BORDIR M.TAWON LELAKI+CIPUT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA4306', 'MAKLOON BORDIR M THANK FOR BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4670', 'MAKLOON BORDIR M.TULISAN APP08X-TRA MILE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4566', 'MAKLOON BORDIR M.WANITA BIJAK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4308', 'MAKLOON BORDIR M.ZOO TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1504', 'MAKLOON BORDIR PANDA DIRIGENT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1502', 'MAKLOON BORDIR PANDA PERMADANI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1495', 'MAKLOON BORDIR POOH A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1499', 'MAKLOON BORDIR POOH MUKA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1500', 'MAKLOON BORDIR POOH WAJAH KECIL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1501', 'MAKLOON BORDIR POT BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1505', 'MAKLOON BORDIR SATU MUKA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1328', 'MAKLOON BORDIR SBT APEL A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1333', 'MAKLOON BORDIR SBT APEL B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1323', 'MAKLOON BORDIR SBT APEL NENAS (PERFUME)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1326', 'MAKLOON BORDIR SBT JAMBU A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1332', 'MAKLOON BORDIR SBT JAMBU B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1322', 'MAKLOON BORDIR SBT JAMBU TOMAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1325', 'MAKLOON BORDIR SBT LEMON A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1331', 'MAKLOON BORDIR SBT LEMON B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1324', 'MAKLOON BORDIR SBT STRAWBERY A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1330', 'MAKLOON BORDIR SBT STRAWEBERY B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1320', 'MAKLOON BORDIR SBT WORTEL/CAROT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4699', 'MAKLOON BORDIR SKIBER BEAR GRIYZLI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4402', 'MAKLOON BORDIR SLEEPING BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1497', 'MAKLOON BORDIR SWEET BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1491', 'MAKLOON BORDIR TEDDY BEAR A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1492', 'MAKLOON BORDIR TEDDY BEAR B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1482', 'MAKLOON BORDIR TRISET 02', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1483', 'MAKLOON BORDIR TRISET 03', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1493', 'MAKLOON BORDIR TWEETY A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1494', 'MAKLOON BORDIR TWEETY B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4700', 'MAKLOON BORDIR WORTEL GREEN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW1000', 'MAKLOON GULUNG BENANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2410', 'MAKLOON GULUNG BENANG 100D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2401', 'MAKLOON GULUNG BENANG 150 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1747', 'MAKLOON GULUNG BENANG 300 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMW1001', 'MAKLOON GULUNG BENANG 50D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1746', 'MAKLOON GULUNG BENANG 50 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1752', 'MAKLOON GULUNG BENANG 75 D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3200', 'MAKLOON KAIN JALA FULL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1002', 'MAKLOON KAIN KOKET SALUR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4904', 'MAKLOON KAIN TILE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4930', 'MAKLOON KAIN TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4932', 'MAKLOON KAIN TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4949', 'MAKLOON KAIN TILLE L=140', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4929', 'MAKLOON KAIN TILLE L=140 (101)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1206', 'MAKLOON KAIN TILLE L=150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1205', 'MAKLOON KAIN TILLE L=164', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1213', 'MAKLOON KAIN TILLE L=200', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1530', 'MAKLOON M.BASE BALL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1531', 'MAKLOON M.BEST FRIENDS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1515', 'MAKLOON M/BONEKA SALJU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1514', 'MAKLOON M/BUNGA NATAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1532', 'MAKLOON M.CHO-CHO BEAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1527', 'MAKLOON M.FRIENDSHIP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1519', 'Makloon M/GBI BANDUNG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1520', 'Makloon M.GBI JAKARTA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1518', 'Makloon M GPPS KARAWANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1536', 'MAKLOON M.HAPPY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1529', 'MAKLOON M.KUCING GITAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1512', 'MAKLOON M.LOGO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1600', 'Makloon M.NATAL GIA TKI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1513', 'MAKLOON MOTIF BEAR KUDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1517', 'MAKLOON MOTIF SELAMAT ULANG TAHUN BWI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1528', 'MAKLOON M.PUPET SNOW', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1523', 'MAKLOON M SEPATU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1524', 'MAKLOON M SINTER CLASS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1535', 'Makloon M.Tiga Panda Kecil', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1516', 'MAKLOON M/TONGKAT SEPATU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK1001', 'MAKLOON PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1538', 'MAKLOON PRINT H ADAY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH1537', 'MAKLOON PRINT H SPT DM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML143301D', 'MAKLOON PRINTING GAMBAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1433', 'MAKLOON PRINTING KESET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1432', 'MAKLOON PRINTING MOTIF BEAR MANDI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2201', 'MAKLOON PRINT VITRAGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4691', 'MAKLOON TAWON DAUN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2202', 'MAKLOON VITRAGE M.BURUNG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMK3250', 'MAKLOON VITRAGE M/KAFE KARTEEN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFM4010', 'MATRAS BERMAIN ALPHABET NUMBER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM1202', 'MATRAS BERMAIN ANIMAL ZOO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM4020', 'MATRAS BERMAIN ANIMAL ZOO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM4040', 'MATRAS BERMAIN ASTRONOT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM4030', 'MATRAS BERMAIN CITY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM4050', 'MATRAS BERMAIN DINO NUMBER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM4060', 'MATRAS BERMAIN FARM HOUSE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'VMM1030', 'MATRAS SET ALPACA', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMM1010', 'MATRAS SET SAFARI', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMM1020', 'MATRAS SET TWINNY', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMM1040', 'MATRAS SET WHALES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'IMH1548', 'M.Baby Joy Pesawat Kelincing Kecil', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMH4797', 'M.BORDIR M. MERRY CHRISMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTSK014', 'MEGA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK097', 'MELLAN', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK027', 'MIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'VMD1012', 'MINKY DOLL BEAR BROWN', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD1011', 'MINKY DOLL BEAR GREY', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD1030', 'MINKY DOLL BUNNY', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD1020', 'MINKY DOLL MONKEY', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD1040', 'MINKY DOLL TIGER', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'AMT1010', 'MIRROR 0,25 MM TRANSPARAN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AMT1020', 'MIRROR 0,25 MM TRANSPARAN (LEMBARAN)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFM3010', 'MONTESSORI BALL BLUE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3011', 'MONTESSORI BALL GREEN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3012', 'MONTESSORI BALL PINK', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3021', 'MONTESSORI BALL TOSCA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3020', 'MONTESSORI BALL YELLOW', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3040', 'MONTESSORI RAINBOW', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3030', 'MONTESSORI TRIANGLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3050', 'MONTESSORI TRIANGLE (SIZE M)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3060', 'MONTESSORI TRIANGLE (SIZE S)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'KTSK015', 'NANIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK098', 'NANINA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK026', 'NIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK099', 'OVELIN', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'SOLJ003', 'PE 30S ABU 21920890A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SOLJ011', 'PE 30S HIJAU 24732539A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SOLJ005', 'PE 30S KUBUS 21130170A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SOLJ007', 'PE 30S NAVY 21433384A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SOLJ009', 'PE 30S ORANGE 21230348A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SOLJ013', 'PE 30S PUTIH 21010248A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'API1010', 'PIPET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'BP07500', 'PLASTIK KELAMBU TENDA CHEVRON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PM1313', 'PLASTIK MIKA KELAMBU AYUNAN BABY SNOBBY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFP1204', 'PLAYMAT BEE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1273', 'PLAYMAT CRAB', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HPM0003', 'PLAYMAT DOLPHIN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1205', 'PLAYMAT GARDEN', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1212', 'PLAYMAT HIPPO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HPM0005', 'PLAYMAT JELLYFISH', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1231', 'PLAYMAT LION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1010', 'PLAYMAT LITTLE CRAB', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1020', 'PLAYMAT LITTLE OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1040', 'PLAYMAT LITTLE RACOON', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFP1030', 'PLAYMAT LITTLE SHEEP', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HPM0001', 'PLAYMAT OCTOPUS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HPM0004', 'PLAYMAT STARFISH', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HPM0002', 'PLAYMAT TURTLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'ABP0873', 'PREPET 2.5 CM PUTIH HALUS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ABP0872', 'PREPET 2.5 CM PUTIH KASAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBK100', 'PRICILIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBK101', 'QUENELLA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'LFR1031', 'RATTLE KARAKTER LION SALUR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR1050', 'RATTLE KARAKTER MONKEY SALUR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2120', 'RATTLE STICK CRAB ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2140', 'RATTLE STICK JELLYFISH ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2080', 'RATTLE STICK KOALA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2100', 'RATTLE STICK MOUSE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2090', 'RATTLE STICK OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2110', 'RATTLE STICK PANDA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2130', 'RATTLE STICK PUFFERFISH ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2043', 'RATTLE STICK RABBIT YELLOW', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2160', 'RATTLE STICK RHINO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR2150', 'RATTLE STICK STARFISH ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR3010', 'RATTLE TEETHER CLOUD', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR3040', 'RATTLE TEETHER GIRAFFE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR3020', 'RATTLE TEETHER MOON', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR3050', 'RATTLE TEETHER PANDA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFR3030', 'RATTLE TEETHER STAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'AST1011', 'RED STAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1405', 'RENDA MOTIF BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1434', 'RENDA MOTIF.BUNGA PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTKK035', 'RIBERA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ARI2020', 'RING 68 MM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARI1015', 'RING BLUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARC1013', 'RING CERMIN BENING ABU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARC1012', 'RING CERMIN BENING BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARC1014', 'RING CERMIN BENING PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARC1011', 'RING CERMIN LIS BIRU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARI1014', 'RING LIGNT BLUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARI1013', 'RING ORANGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARI1011', 'RING PURPLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ARI1012', 'RING RED', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBK102', 'RISYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KPLB001', 'ROAD ROLLER BESAR', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KPLB004', 'ROCKET BESAR', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KTSK013', 'SAFIAH', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTBB107', 'SALMA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMV1002', 'SANDARAN LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1015', 'SANDARAN LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1100', 'SANDARAN M.BINGKAI', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'TRT1133', 'SANDARAN PRINT 40X50 FOAMING GLITER BUNGA EDELWEIS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1426', 'SANDARAN PRINT OVAL KOKET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1101', 'SANDARAN RD HL POLOS TB 45X60', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMR1001', 'SANDARAN RD HL PRINT TB 45X60', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1425', 'SANDARAN RD HL PRINT TB (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1001', 'SANDARAN RD OVAL POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1424', 'SANDARAN RD OVAL PRINT MAESTRO (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1003', 'SANDARAN RD OVAL PRINT MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1423', 'SANDARAN RD OVAL PRINT PRG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SVR5404', 'SANDARAN RD PLS LYCIA+VB RD FULL PRT SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR4404', 'SANDARAN RD PLS LYCIA+VB RD PRT SEGI 30X40', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'VSL1002', 'SANDARAN RD POLOS B NYLON (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1405', 'SANDARAN RD.POLOS BULAT MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VTR1000', 'SANDARAN RD POLOS HL TB (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1002', 'SANDARAN RD POLOS HL TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VVR4107', 'SANDARAN RD POLOS LYCIA (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRL3721', 'SANDARAN RD POLOS OVAL PRESTIGE 2', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1011', 'SANDARAN RD.POLOS SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1017', 'SANDARAN RD.POLOS SEGI MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1000', 'SANDARAN RD POLOS VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1100', 'SANDARAN RD.PRINT HL TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1200', 'SANDARAN RD.PRINT HL TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VTQ1000', 'SANDARAN RD PRINT HL TB (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1003', 'Sandaran Rd Print Hl tp', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IML1442', 'SANDARAN RD.PRINT HL TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VTF1000', 'SANDARAN RD PRINT HL TP (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VTQ1001', 'SANDARAN RD PRINT LYCIA (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1000', 'SANDARAN RD.PRINT OVAL MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1002', 'SANDARAN RD PRINT OVAL  MARGARETHA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1000', 'SANDARAN RD.PRINT OVAL ROSE GARDEN', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1440', 'SANDARAN RD.PRINT SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1542', 'SANDARAN RD.PRINT SEGI MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1737', 'SANDARAN RD PRINT SEGI MARGARETHA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1302', 'SANDARAN RD PRT LYCIA+VB RD PRT SEGI 30X40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'SVR2404', 'SANDARAN RD PRT LYCIA+VB RD PRT SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'VTQ1002', 'SANDARAN RD RD POLOS HL TP (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMM2020', 'SANDARAN RD SEGI PRINT MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1641', 'SANDARAN RD.TUTON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMS1160', 'Sandaran Rd. Tutton', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IMP1001', 'SAND.OVAL MST PRINT TP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1102', 'SAND PLS OVAL RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1402', 'SANDRAN HLTB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMP1300', 'SAND.RD HL PRINT TB 45X60', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1443', 'SAND RD HL PRINT TP 40X60', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1414', 'SAND. RD PLS. HL TB', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR5406', 'SAND RD PLS HL TB+VB RD FULL PRT SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR1406', 'SAND RD PLS HL TB+VB RD PLS SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1403', 'SAND RD PLS HL TP ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR5405', 'SAND RD PLS HL TP+VB RD FULL PRT SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR4406', 'SAND RD PLS HL TP+VB RD POLOS SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1415', 'SAND RD PLS LICYA', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMS1402', 'SAND. RD PLS. OVAL  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1401', 'SAND. RD PLS. SEGI  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1416', 'SAND RD PLS SEGI RG', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IML1466', 'SAND RD PRINT HL TP 5PCS+VB.RD POLOS 30X40 1PCS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT3001', 'SAND RD PRINT HL TP 5PCS+VB RD PRINT 30X401PCS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1014', 'SAND. RD PRT. HL TB', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'SVR4405', 'SAND RD PRT HL TP+VB RD PLS SEGI 30X40', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1015', 'SAND. RD PRT LICYA', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMS1002', 'SAND. RD PRT. OVAL ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1001', 'SAND. RD PRT. SEGI  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMS1016', 'SAND. RD PRT SEGI  RG', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'KAT2001', 'SAND RD TUTTON 5PCS+LOVER RD SDG E D/W1PCS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IML1543', 'SAND.SEGI MST PRINT TP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VMS2020', 'SARUNG BANTAL GULING SET BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMS2010', 'SARUNG BANTAL GULING SET RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'IMS1010', 'SELENDANG POLOS TB 300D', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXL1422', 'SELENDANG PRINT VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBK103', 'SELLYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTKK025', 'SINTYA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'ASR1012', 'SMALL STAR RING KUNING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ASR1011', 'SMALL STAR RING PINK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VMS1020', 'SOFA BAYI BUNNY SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMS1010', 'SOFA BAYI RHINO SERIES', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'LFS3020', 'SOFT BALL (M)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS3010', 'SOFT BALL (S)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HBC0001', 'SOFT BOOK ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFB1251', 'SOFT BOOK COLORS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1110', 'SOFT BOOK FARM', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HBC0003', 'SOFT BOOK FRUIT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1051', 'SOFT BOOK MONOCRHOM ALPHABET', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1071', 'SOFT BOOK MONOCRHOM ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1021', 'SOFT BOOK MONOCRHOM BIRD', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1081', 'SOFT BOOK MONOCRHOM FRUITS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1011', 'SOFT BOOK MONOCRHOM HOUSE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1031', 'SOFT BOOK MONOCRHOM NUMBER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1061', 'SOFT BOOK MONOCRHOM SHAPES', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1041', 'SOFT BOOK MONOCRHOM VEHICLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HBC0004', 'SOFT BOOK NUMBER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1090', 'SOFT BOOK  POLICE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1100', 'SOFT BOOK PROFESION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'HBC0002', 'SOFT BOOK SEA WORLD', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFB1212', 'SOFT BOOK SHAPES', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1120', 'SOFT BOOK TEETHER ALPHABET', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1130', 'SOFT BOOK TEETHER ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1140', 'SOFT BOOK TEETHER FARM ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1150', 'SOFT BOOK TEETHER INSECT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1160', 'SOFT BOOK TEETHER LETS COUNT', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1170', 'SOFT BOOK TEETHER LITTLE DINO', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS1180', 'SOFT BOOK TEETHER SEA ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFB1213', 'SOFT BOOK VEGETABLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFB1204', 'SOFT BOOK VEHICIE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0009', 'SOFT CUBE BEAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2030', 'SOFT CUBE KARAKTER EL BEAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2020', 'SOFT CUBE KARAKTER OKY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0008', 'SOFT CUBE OKY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2090', 'SOFT CUBE PRINT DINO ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2080', 'SOFT CUBE PRINT GLAMPING ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2040', 'SOFT CUBE PRINT MY PLANET', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2050', 'SOFT CUBE PRINT NUMBER', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2100', 'SOFT CUBE PRINT SEA ANIMAL ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2060', 'SOFT CUBE PRINT TRANSPORTATION', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2070', 'SOFT CUBE PRINT VEGETABLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0007', 'SOFT CUBE RARA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS2010', 'SOFT CUBE RARA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'SB', 'SOFT CUBE RARA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0005', 'SOFT TOYS BOLA CRAB (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3655', 'SOFT TOYS BOLA CRAB (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0006', 'SOFT TOYS BOLA DINO (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3656', 'SOFT TOYS BOLA DINO (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS0006', 'SOFT TOYS BOLA DINO (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0004', 'SOFT TOYS BOLA SNAIL (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0003', 'SOFT TOYS CUBE GIRAFFE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM3583', 'SOFT TOYS CUBE GIRAFFE (PM)', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0001', 'SOFT TOYS CUBE MIRROR ', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFM0002', 'SOFT TOYS CUBE OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS4010', 'SOFT TRIANGLE ANIMAL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS4020', 'SOFT TRIANGLE SEA WORLD', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFS4030', 'SOFT TRIANGLE VEHICLE', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'ABP0874', 'SPANBOND + BUSA A10', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ASB1011', 'STAR BUCKLE BIRU MUDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ASB1012', 'STAR BUCKLE BIRU TUA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1406', 'T 1X1 KATUN PRINT MST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5009', 'T 1X1 KOKET D/W MERAH MARON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1410', 'T. 1X1 PRINT LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1204', 'T 1X1 PRINT N/W RENDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1205', 'T. 1X1 RD MST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1206', 'T.1X1 RD PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1409', 'T 6K KATUN PRINT BERENDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VHA1000', 'T 6K KATUN PRINT BERENDA (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VHA1001', 'T 6K KATUN PRINT BERENDA (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1424', 'T 6K SEGI PRINT SONETA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2002', 'T 8K SEGI PRINT VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6103', 'T.90X90 M.BATI+LOVER BATIK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1202', 'T.90X90 PRINT N/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1023', 'T 90x90 PRINT TP KOKET (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFT1030', 'TAGGIE BLANKET BEAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1050', 'TAGGIE BLANKET LORIS', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1010', 'TAGGIE BLANKET MONKEY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1040', 'TAGGIE BLANKET OWL', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFT1020', 'TAGGIE BLANKET WHALES', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'MAL1506', 'TAPALK RD PRINT 90X90 TB G', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL3201', 'TAPLAK 1X1 KOKET PRINT M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1701', 'TAPLAK 1X1 KOKET PRINT M.BUAH ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1021', 'TAPLAK 1X1 PRINT TP TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT6003', 'TAPLAK 1X1 SAKURA DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1027', 'TAPLAK 90X90 RGTB DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL3105', 'TAPLAK KOKET 90X90 M/ETNIK GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL3101', 'TAPLAK KOKET 90X90 M/MATAHARI TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1601', 'TAPLAK KOKET BORDIR PANJANG RUMBAI INDAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1214', 'TAPLAK POLOS 8K SEGI NEW MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1405', 'TAPLAK POLOS 8K SEGI NEW PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1119', 'TAPLAK PRINT 80X80 M-05', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1120', 'TAPLAK PRINT 80X80 M-06 (K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1201', 'TAPLAK PRINT 90X90 BUNGA EDELWEIS FG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1131', 'TAPLAK PRINT 90X90 M.01 (BUNGA KOTAK)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1026', 'TAPLAK PRINT 90X90 M.02', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1122', 'TAPLAK PRINT 90X90 M-07 (BINGKAI TULIP)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1124', 'TAPLAK PRINT 90X90 M-08 (BUNGA BINGKAI)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1132', 'TAPLAK PRINT 90X90 TB M.13 BUNGA KUPU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL3110', 'TAPLAK PRINT 90X90 TB M.New German', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1133', 'TAPLAK PRINT KOKET SEGI M/NATAL TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1131', 'TAPLAK PRINT SEGI 90X90 M-11', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1121', 'TAPLAK PRINT SEGI TB M-04', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT 112712', 'TAPLAK PRINT SEGI TB M-04', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1118', 'TAPLAK PRINT SEGI TB M-05', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT4003', 'TAPLAK RD. 1X1 M/ARWANA DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1223', 'TAPLAK RD. 1X1 M/BUAH DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT3003', 'TAPLAK RD. 1X1 M/ NATURE DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT9002', 'TAPLAK RD. 1X1 PRINT M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1290', 'TAPLAK RD. 4K BULAT POLOS M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT3006', 'TAPLAK RD. 4K BULAT POLOS M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1291', 'TAPLAK RD. 4K BULAT PRINT M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT3007', 'TAPLAK RD. 4K BULAT PRINT M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRS4570', 'TAPLAK RD 6K OVAL PRINT M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2417', 'TAPLAK RD 8K SEGI MOTIF BARU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2419', 'TAPLAK RD 8K SEGI POLOS NEW DGU HOME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2418', 'TAPLAK RD 8K SEGI PRINT NEW DGU HOME', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1222', 'TAPLAK RD FULL PRINT 90X90 M.BUAH ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRL3730', 'TAPLAK RD.POLOS 100x130', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1125', 'TAPLAK RD.POLOS 1X1 BUNGA TULIP TNP.PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAS1608', 'TAPLAK RD.POLOS 1X1 BUNGA TULIP TP TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1404', 'Taplak Rd. Polos 1 X 1 Kansa', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'TSR1105', 'Taplak Rd. Polos 1x1 Kansa + 6pc Sandaran Rd. Polos Lycia', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1419', 'Taplak Rd. Polos 1 X 1 Kansa Tnp Pack', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1407', 'Taplak Rd. Polos 1 X 1 Lycia', 'LYCIA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LYCIA');
INSERT INTO public.tr_product VALUES (3, 'IMT1266', 'TAPLAK RD.POLOS 1X1 LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1412', 'TAPLAK RD.POLOS 1X1 MAESTRO BROTHER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT4001', 'TAPLAK RD POLOS 1 X 1 M. ARWANA ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT8001', 'TAPLAK RD POLOS 1 X 1 M. BUNGA MAWAR ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT9001', 'TAPLAK RD. POLOS 1X1 M.KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT 110612', 'TAPLAK RD.POLOS 1X1 MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT6001', 'TAPLAK RD POLOS 1 X 1 M. SAKURA ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT5001', 'TAPLAK RD POLOS 1 X 1 M. TRIBALL ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'CMT1403', 'TAPLAK RD. POLOS 1X1 PRESTIGE TANPA PACK', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'IMT1413', 'TAPLAK RD.POLOS 1X1 ROSE GARDEN TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1613', 'Taplak Rd. Polos  4K Bulat Kansa ', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT2429', 'Taplak Rd. Polos  6K Bulat Kansa ', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'TSR1601', 'Taplak Rd. Polos 6K Bulat Kansa +  6 pc Sandaran Rd. Polos Lycia', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRT1180', 'TAPLAK RD.POLOS 6K BULAT M.ARWANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1920', 'TAPLAK RD. POLOS 6K BULAT M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1104', 'TAPLAK RD.POLOS 6K BULAT MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2433', 'TAPLAK RD.POLOS 6K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1530', 'TAPLAK RD.  POLOS 6K OVAL M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1280', 'TAPLAK RD.  POLOS 6K OVAL M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1930', 'TAPLAK RD. POLOS 6K OVAL M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR1403', 'Taplak Rd. Polos 6K Segi Kansa + 6 pcs Sandaran Rd. Polos Lycia', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT2404', 'Taplak Rd. Polos  6K segi Kansa E/IL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRT1510', 'TAPLAK RD. POLOS 6K SEGI M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1260', 'TAPLAK RD. POLOS 6K SEGI M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1910', 'TAPLAK RD. POLOS 6K SEGI M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT7001', 'TAPLAK RD POLOS 6K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1415', 'TAPLAK RD POLOS 80X120 D/W TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1536', 'Taplak rd polos 80X120 Rose tpTnp Pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT1418', 'TAPLAK RD.POLOS 80X120 SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1422', 'Taplak rd polos 80X120 Tnp Pack', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1417', 'TAPLAK RD.POLOS 80X120 TP SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAL6001', 'TAPLAK RD.POLOS 80X80 D/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1282', 'TAPLAK RD.  POLOS 8K SEGI M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'KAS4106', 'TAPLAK RD POLOS 8K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2018', 'TAPLAK RD.POLOS 8K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1425', 'TAPLAK RD.POLOS 90X09 RGTP (CREM)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1220', 'TAPLAK RD POLOS 90X90 M.BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT3001', 'TAPLAK RD POLOS 90X90 M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1246', 'TAPLAK RD POLOS 90X90 NATURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAL8001', 'TAPLAK RD.POLOS 90X90 RGTP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTT1406', 'TAPLAK RD.POLOS 90X90 RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAS1409', 'TAPLAK RD.POLOS 90X90 RGTP (CREM)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1406', 'Taplak Rd.Polos  90X90 RGTP TNP PACK', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1420', 'Taplak rd polos 90X90 tp Tnp Pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAL7001', 'TAPLAK RD.POLOS 90X90 TP (VALU$)_', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1428', 'TAPLAK RD.POLOS BULAT 75X75 TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1427', 'TAPLAK RD.POLOS SEGI 80X80', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1424', 'TAPLAK RD.PRINT 1X1 B.TULIP TP TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1147', 'TAPLAK RD PRINT 1X1 BUNGA TULIP ( GLITER )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1145', 'TAPLAK RD.PRINT 1X1 BUNGA TULIP TNP.PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1015', 'Taplak Rd. Print 1 X 1 Kansa', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'TSR4106', 'Taplak Rd. Print 1x1 Kansa + 6 pcs Sandaran Rd. Polos Lycia ', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'KAT1126', 'Taplak Rd. Print 1 X 1 Kansa Tnp Pack', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1004', 'Taplak Rd. Print 1 X 1 Lycia', 'LYCIA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LYCIA');
INSERT INTO public.tr_product VALUES (3, 'PRT4002', 'TAPLAK RD PRINT 1 X 1 M. ARWANA ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT8002', 'TAPLAK RD PRINT 1 X 1 M. BUNGA MAWAR ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IXV2410', 'TAPLAK RD.PRINT 1X1 MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT6002', 'TAPLAK RD PRINT 1 X 1 M. SAKURA ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT5002', 'TAPLAK RD PRINT 1 X 1 M. TRIBALL ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMS1103', 'TAPLAK RD.PRINT 1X1 PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1313', 'Taplak Rd. Print  4K Bulat Kansa ', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'KAL4001', 'TAPLAK RD.PRINT 4K BULAT KANSA PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1116', 'TAPLAK RD PRINT 4K BULAT M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAL3001', 'TAPLAK RD.PRINT 4K BULAT MONIQUE GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2003', 'TAPLAK RD.PRINT 4K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2029', 'Taplak Rd. Print   6K Bulat Kansa ', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'TSR4602', 'Taplak Rd. Print  6K Bulat Kansa + 6pcs Sandaran Rd. Polos Lycia', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRT1521', 'TAPLAK RD. PRINT 6K BULAT M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1241', 'TAPLAK RD. PRINT 6K BULAT M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1921', 'TAPLAK RD. PRINT 6K BULAT M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1117', 'TAPLAK RD.PRINT 6K BULAT PRESTIGE (F.PRINT)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1531', 'TAPLAK RD.  PRINT 6K OVAL M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1281', 'TAPLAK RD.  PRINT 6K OVAL M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1931', 'TAPLAK RD. PRINT 6K OVAL M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2054', 'TAPLAK RD PRINT 6K OVAL PRESTIGE BW+GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXV1426', 'TAPLAK RD PRINT 6K SEGI KANSA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR4404', 'Taplak Rd. Print  6K Segi Kansa + 6pcs Sandaran Rd. Polos Lycia', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'KAT1107', 'Taplak Rd. Print  6K segi Kansa E/IL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRT1511', 'TAPLAK RD. PRINT 6K SEGI M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1261', 'TAPLAK RD. PRINT 6K SEGI M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1911', 'TAPLAK RD. PRINT 6K SEGI M. KOLIBRI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1130', 'TAPLAK RD.PRINT 6K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTT3201', 'TAPLAK RD.PRINT 6K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2009', 'TAPLAK RD PRINT 6K SEGI PRESTIGE BW+GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2055', 'TAPLAK RD PRINT 6K SEGI PRESTIGE BW+GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1013', 'TAPLAK RD.PRINT 80X120', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1138', 'TAPLAK RD PRINT 80X120 ROSE TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1236', 'Taplak rd print 80X120 Rose tpTnp Pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT1023', 'Taplak rd print 80X120 Tnp Pack', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1003', 'TAPLAK RD.PRINT 80X90', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT6582', 'TAPLAK RD PRINT 80X90 (FULL PRINT)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1426', 'TAPLAK RD.PRINT 8K BULAT MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAL2001', 'TAPLAK RD PRINT 8K BULAT MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1434', 'TAPLAK RD.PRINT 8K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2010', 'TAPLAK RD PRINT 8K BULAT PRESTIGE BW+GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1201', 'TAPLAK RD PRINT 8K OVAL MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAL1023', 'TAPLAK RD PRINT 8K OVAL MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2011', 'TAPLAK RD PRINT 8K OVAL PRESTIGE BW+GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1283', 'TAPLAK RD.  PRINT 8K SEGI M. BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IXV1407', 'TAPLAK RD.PRINT 8K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1221', 'TAPLAK RD PRINT 90X90 M.BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT3002', 'TAPLAK RD PRINT 90X90 M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMT1019', 'TAPLAK RD.PRINT 90X90 RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL2002', 'TAPLAK RD.PRINT 90X90 RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1124', 'TAPLAK RD PRINT 90X90 RG TP NYLON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1106', 'Taplak Rd.Print  90X90 RGTP TNP PACK', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1009', 'TAPLAK RD.PRINT 90X90 TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMT1104', 'Taplak rd print 90X90 tp Tnp Pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRT1324', 'TAPLAK RD.PRINT BULAT 75X75 TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXW1207', 'TAPLAK RD PRINT BUNGA TULIP TP ( GLITER )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2424', 'TAPLAK SET PRINT 6K SEGI DAMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2431', 'TAPLAK SET RD.POLOS 6K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2432', 'TAPLAK SET RD.POLOS 8K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1901', 'TAPLAK TRIKOT 1X1 MOTIF DAHLIA', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRT1921', 'TAPLAK TRIKOT 6K BULAT MOTIF DAHLIA', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRT1931', 'TAPLAK TRIKOT 6K OVAL MOTIF DAHLIA ', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRT1911', 'TAPLAK TRIKOT 6K SEGI MOTIF DAHLIA', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TRV1105', 'TAPLAK TUTTON 8K SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSLR005', 'TCM SALUR 29 FDR NO 60', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ATE2031', 'TEETHE LINGKARAN HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT1001', 'TEMPAT TUTUP TISSU RENDA', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KTKK028', 'TIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'KTL0014', 'TILLE FASHION CELUP GLITTER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL0013', 'TILLE FASHION PADDING GLITTER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VIB1000', 'T LYCIA BERENDA 130X180 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1135', 'T. PRINT 1X1 M.ADDENIUM FOAM TANPA PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1126', 'T. PRINT 1X1 M.ADDENIUM FOAM TANPA PACK ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1107', 'T.PRINT 80X80 M.04', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1218', 'T.PRINT 8K BULAT DAMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1212', 'T.PRINT 8K BULAT DAMAST BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRL1219', 'T.PRINT 8K BULAT DAMAST RUMBAI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1132', 'T.PRINT 90X90 M.01 (BUNGA KOTAK)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1106', 'T.PRINT 90X90 MOTIF 02 KOKET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1203', 'T PRINT 90X90 N/W', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRS1100', 'T. PRINT M-03', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1022', 'T PRINT TB 90X90 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1125', 'T PRT. 1X1 M. ADDENIUM FOAM ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1108', 'T PRT. 1X1 M.BATIK ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1123', 'T. PRT.  90X90 M. BUNGA KUPU', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRT1142', 'T PRT. 90X90 M.ETNIX GLITER ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1220', 'T. PRT.  90X90 M. NEW GERMANT', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRT1134', 'T. PRT TRIKOT 90 X 90 M.NATAL ', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IMT1302', 'T RD 1X1 BULAT POLOS LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1235', 'T.RD 1X1 KANSA POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1001', 'T.RD 1X1 KANSA PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1411', 'T.RD 1X1 KANSA PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1301', 'T.RD 1X1 LYCIA POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1205', 'T RD 1X1 LYCIA POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1303', 'T RD. 1X1 NATAL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1414', 'T.RD 1X1 PLS RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1408', 'T.RD 1X1 PLS TB RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1409', 'T.RD 1X1 PLS TB RG TNP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1241', 'T RD 1X1 POLOS KOKET', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1207', 'T RD 1X1 POLOS PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1411', 'T RD 1X1 POLOS TB RG TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1304', 'T RD. 1X1 POLOS VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1122', 'T RD 1X1 PRG  FULL PRT ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXT1405', 'T.RD 1X1 PRINT BUNGA TULIP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1500', 'T RD 1X1 PRINT KANSA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1411', 'T RD 1X1 PRINT LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1101', 'T RD 1X1 PRINT MAESTRO (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1017', 'T.RD 1X1 PRINT RG TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1004', 'T RD 1X1 RG PRINT TNP PK (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1123', 'T RD 1X1 RG TB FULL PRT ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT6104', 'T.RD 4K BULAT M.NATURE + LOVER NATURE PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2404', 'T RD 4K BULAT POLOS PRG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2416', 'T RD 4K OVAL POLOS PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2409', 'T RD. 4K SEGI KANSA POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2415', 'T RD 4K SEGI POLOS KANSA TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2410', 'T.RD 6K BULAT KANSA POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2407', 'T RD 6K BULAT KANSA POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2030', 'T RD 6K BULAT POLOS PRG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2301', 'T.RD 6K POLOS BULAT PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2013', 'T.RD 6K SEGI PLS PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2014', 'T RD 6K SEGI POLOS KANSA (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2017', 'T RD. 6K SEGI POLOS PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2016', 'T.RD 6K SEGI POLOS PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1406', 'T RD 80X120 POLOS PRESTIGE TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1405', 'T RD 80X120 POLOS TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1025', 'T.RD 80X120 PRINT GLITER', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1014', 'T RD 80X120 PRINT TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1002', 'T.RD 80X120 PRINT TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS2201', 'T.RD 80X90 PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2020', 'T RD 8K BULAT POLOS PRG (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1535', 'T.RD 8K BULAT PRG PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1423', 'T RD 8K BULAT PRINT PRESTIGE (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2001', 'T.RD 8K OVAL PRINT PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2406', 'T RD. 8K POLOS KANSA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1044', 'T.RD 8K POLOS M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1401', 'T RD. 8K SEGI POLOS VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1420', 'T.RD 8K SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1418', 'T RD 8K SEGI PRINT PRESTIGE (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTT1433', 'T RD PLS. 10K SEGI MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'PRT1430', 'T RD PLS.1X1 BUNGA TULIP TNP ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1403', 'T RD PLS. 1X1 PRG ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1424', 'T RD PLS. 1X1 RG TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRV8104', 'T.RD PLS 4K BLT MONIQUE+6pc VB RD PLS BLT MONIQ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1115', 'T.RD PLS 4K BULAT M.BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1613', 'T RD PLS. 4K BULAT MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TRT1701', 'T RD PLS 4K BULAT MONIQUE+6PC SAND RD PLS LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR1610', 'T RD PLS 4K BULAT MONIQUE+6PC SAND RD PLS LYCIA', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TVR1810', 'T RD PLS 4K BULAT MONIQUE+6PC VB. RD PLS 30X40', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'TVR1311', 'T RD PLS 4K BULAT MONIQUE+6PC VB  RD PLS MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2427', 'T. RD PLS. 4K BULAT PRG', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1141', 'T.RD PLS 6K BLT KANSA+6pc SAND RD PLS LICYA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1615', 'T RD PLS. 6K BULAT MONIQUE ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2407', 'T. RD PLS. 6K BULAT PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2430', 'T. RD PLS. 6K OVAL PRESTIGE ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT1140', 'T.RD PLS 6K SEGI KANSA+6pc SANDR RD PLS LICYA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMT1415', 'T RD PLS. 6K SEGI MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2401', 'T RD PLS. 6K SEGI PRG', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1539', 'T RD PLS. 80X120 M.01', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1835', 'T. RD PLS. 80X120 NECI', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1840', 'T. RD PLS. 80X120 OVAL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1421', 'T RD PLS. 80X90 tnp pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2405', 'T. RD PLS. 8K BULAT PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2408', 'T. RD PLS. 8K OVAL PRESTIGE ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1059', 'T RD PLS. 8K SEGI MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'MRT1004', 'T. RD PLS. 8K SEGI NEW PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2402', 'T. RD PLS. 8K SEGI PRESTIGE ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1230', 'T RD PLS.90 X 90 NEW PRESTIGE ', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IMT1423', 'T RD PLS. 90X90 TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT6521', 'T RD PLS. BULAT 75 TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1209', 'T.RD POLOS 1X1 KANSA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1264', 'T.RD POLOS 1X1 LIROPOL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1403', 'T.RD POLOS 1X1 RG TB VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2405', 'T.RD POLOS 4K 0 PRESTIGE (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1218', 'T. RD POLOS 4K SEGI BUNGA LILI', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1520', 'T. RD POLOS 6K BULAT M. ARWANA', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRT1240', 'T. RD POLOS 6K BULAT M. BUAH', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXT2401', 'T. RD POLOS 6K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2412', 'T.RD POLOS 6K OVAL PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2413', 'T.RD POLOS 6K OVAL VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTT6472', 'T.RD POLOS 6K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2015', 'T.RD POLOS 6K SEGI SILVANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2014', 'T.RD POLOS 6K SEGI VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2403', 'T.RD POLOS 8K BULAT MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2402', 'T.RD POLOS 8K OVAL VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2012', 'T RD.POLOS 8K PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2010', 'T.RD POLOS 8K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT2425', 'T RD POLOS 90X90 BUNGA ASTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1102', 'T.RD POLOS BULAT 75 TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1141', 'T.RD POLOS OVAL M-01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS1417', 'T.RD PRINT 1X1 KANSA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6113', 'T.RD PRINT 1X1 KANSA+6pc SANDR RD PLS LICYA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1011', 'T. RD PRINT 1X1 RG TP VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1016', 'T RD PRINT 1X1 ROSE GARDEN TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMS6001', 'T.RD PRINT 1X1 SILVANA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXS1022', 'T.RD PRINT 1X1  VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2004', 'T.RD PRINT 4K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2005', 'T. RD PRINT 4K BULAT VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1219', 'T.RD PRINT 4K SEGI BUNGA LILI', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'TRT6115', 'T.RD PRINT 6K BLT KANSA+6pc SAND RD PLS LICYA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1563', 'T.RD PRINT 6K BULAT  PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1565', 'T.RD PRINT 6K BULAT PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2006', 'T.RD PRINT 6K OVAL PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1407', 'T RD.PRINT 6K PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6114', 'T.RD PRINT 6K SEGI KANSA+6pc SANDR PLS LICYA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1425', 'T.RD PRINT 6K SEGI MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1409', 'T.RD PRINT 6K SEGI VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6117', 'T RD PRINT 6K TUTTON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT6105', 'T.RD PRINT 80X120 M.01 GLITER+T.90X90 PRINT M/BUAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1003', 'T. RD PRINT 80X120 VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1135', 'T.RD PRINT 80X12X0 OVAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1421', 'T.RD PRINT 8K BULAT MARGARETHA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1435', 'T.RD PRINT 8K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT1422', 'T.RD PRINT 8K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1438', 'T.RD PRINT 8K BULAT PRG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2002', 'T. RD PRINT. 8K SEGI PRESTIGE ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXT1419', 'T.RD PRINT 8K SEGI VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT2426', 'T RD PRINT 90X90 BUNGA ASTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT2427', 'T.RD PRINT 90X90 BUNGA ASTER GLITER ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1010', 'T.RD PRINT 90X90 TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1008', 'T.RD PRINT 90X90 TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1325', 'T.RD PRINT BULAT 75 TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1103', 'T.RD PRINT BULAT 75 TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1011', 'T.RD PRINT TB 90X90 TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT1012', 'T.RD PRINT TB 90X90 TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1443', 'T RD PRT.1X1 BUNGA TULIP GLITTER ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1440', 'T RD PRT.1X1 BUNGA TULIP TNP  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1002', 'T RD PRT. 1X1 PRG ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1024', 'T RD PRT. 1X1 RG TB  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1313', 'T RD PRT. 4K BULAT MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'KAT1342', 'T RD PRT. 4K BULAT MONIQUE GLITER', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2019', 'T RD PRT. 4K BULAT PRG', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1142', 'T.RD PRT 4K BULAT PRG(FREE V,BUNGA)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'CMT2019', 'T RD PRT. 4K BULAT PRG TNP PACK  ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1315', 'T RD PRT. 6K BULAT MONIQUE ', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2008', 'T. RD PRT. 6K BULAT PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2053', 'T. RD PRT. 6K BULAT PRESTIGE  BW GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2030', 'T. RD PRT. 6K OVAL PRESTIGE ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT6115', 'T RD PRT. 6K SEGI MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2001', 'T RD PRT. 6K SEGI PRG   ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1339', 'T RD PRT. 80X120 M.01 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'CRT1246', 'T RD PRT. 80X120 M.01 GLITTER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT1735', 'T. RD PRT. 80X120 NECI', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMT1740', 'T. RD PRT. 80X120 OVAL', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'KMT1137', 'T RD PRT. 80X90 FULL PRT tnp pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT1020', 'T RD PRT. 80X90 tnp pack', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2006', 'T. RD PRT. 8K BULAT PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2056', 'T. RD PRT. 8K BULAT PRESTIGE BW GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2012', 'T. RD PRT. 8K OVAL PRESTIGE', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMT2057', 'T. RD PRT. 8K OVAL PRG BW GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KAT1060', 'T RD PRT. 8K SEGI MONIQUE', 'MONIQUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MONIQUE');
INSERT INTO public.tr_product VALUES (3, 'IMT2058', 'T. RD PRT. 8K SEGI PRESTIGE BW GLITER', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1250', 'T. RD PRT. 90X90 9A', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IMT1022', 'T RD PRT. 90X90 TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1049', 'T. RD PRT. 90X90 TB GLITER', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRT6321', 'T RD PRT. BULAT 75 TB ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1165', 'T. RD PRT. TUTON 90X90', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'IMT2506', 'T RD SEGI POLOS 8K SEGI NEW DGU HOME', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'IMT2505', 'T RD SEGI PRINT 8K SEGI NEW DGU HOME', 'DGU HOME', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DGU HOME');
INSERT INTO public.tr_product VALUES (3, 'TTN1210', 'T. RD TUTON 6K OVAL ', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'TTN1212', 'T.RD TUTON 8K OVAL ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRT1164', 'T. RD TUTON 90X90', 'TUTON', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'TUTON');
INSERT INTO public.tr_product VALUES (3, 'VHP1001', 'T RENDA 6K POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VHP1000', 'T RENDA BULAT POLOS TP PK (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'ATT1011', 'TRIANGEL TEETHER HIJAU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1410', 'TS 6K KATUN PRINT MST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'MAL1413', 'TS.6k KTN Print MST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2409', 'TS 6K SEGI PRINT LYCIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VJG1000', 'TS 6K TP VICTORIA (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3001', 'T.SET RD.POLOS OVAL', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3002', 'T.SET RD.POLOS SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2501', 'T.SET RD.PRINT SEGI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2410', 'TS. PRINT 6K SEGI DAMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2425', 'TS.PRINT 6K SEGI DAMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2426', 'TS.PRINT 6K SEGI DAMAST', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2416', 'TS.PRINT 6K SEGI MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2428', 'TS.PRINT 6K SEGI TP MONIQUE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMS1161', 'TS.PRINT SEGI 6K KATUN JACOB''S (abu-abu)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KMS1162', 'TS.PRINT SEGI 6K KATUN JACOB''S (hijau)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2421', 'TS.RD PRINT 6K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2422', 'TS.RD PRINT 6K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2420', 'TS.RD PRINT 8K BULAT PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT2423', 'TS.RD PRINT 8K SEGI PRESTIGE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1498', 'TUTUP GALON JACQUARD KOMBINASI TILLE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMA1429', 'TUTUP KULKAS JACQUARD', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL1004', 'TUTUP TEMPAT TISSUE RENDA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBB086', 'ULFHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'TRV8103', 'VAS BUNGA BORDIR SEGI M.DUA BUNGA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1405', 'VAS BUNGA BULAT 42 M.BUAH DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV3003', 'VAS BUNGA BULAT 42 M.NATURE DASAR WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1004', 'VAS BUNGA BULAT 42X42 PRINT MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TVB1002', 'VAS BUNGA BULAT BORDIR M. DUA BUNGA', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXT3007', 'VAS BUNGA BULAT PRINT 42X42 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1130', 'VAS BUNGA PRINT BULAT M-01 (K.POLOS)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1129', 'VAS BUNGA PRINT BULAT M-01(K.POLOS)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1131', 'VAS BUNGA PRINT BULAT M-01 (K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1132', 'VAS BUNGA PRINT BULAT M-01 (K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1127', 'VAS BUNGA PRINT SEGI M-01 (K.POLOS)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRT1128', 'VAS BUNGA PRINT SEGI M-01 (K.SALUR)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1143', 'VAS BUNGA RD.30X40 POLOS TP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1404', 'VAS BUNGA RD BULAT 28X28B POLOS MAESTRO TNP PACK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1004', 'VAS BUNGA RD BULAT POLOS A 28X28 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3204', 'VAS BUNGA RD BULAT PRINT 28X28 A (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT4002', 'VAS BUNGA RD BULAT PRINT 42X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3205', 'VAS BUNGA RD BULAT PRINT B 28X28', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VDP1000', 'VAS BUNGA RD.FULL PRINT SEGI 30X40 (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VSL1000', 'VAS BUNGA RD.FULL PRINT SEGI 30X40 (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'XXT2005', 'VAS BUNGA RD FULL PRINT SEGI 30X40 (ISI 4)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1003', 'VAS BUNGA RD OVAL POLOS 20X42 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3402', 'VAS BUNGA RD OVAL PRINT 20X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2431', 'VAS BUNGA RD OVAL PRINT 20X42 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1406', 'VAS BUNGA RD. POLOS BULAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1602', 'VAS BUNGA RD.POLOS BULAT 28 B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1030', 'VAS BUNGA RD.POLOS BULAT 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1040', 'VAS BUNGA RD.POLOS BULAT 28X28 B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1025', 'VAS BUNGA RD.POLOS OVAL 20X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1025', 'VAS BUNGA RD.POLOS OVAL RG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1024', 'VAS BUNGA RD.POLOS SEGI 20X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1401', 'VAS BUNGA RD. POLOS SEGI 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1026', 'VAS BUNGA RD.POLOS SEGI 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1028', 'VAS BUNGA RD.POLOS SEGI 28X28 B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1108', 'VAS BUNGA RD.POLOS SEGI 30X40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VBR1000', 'VAS BUNGA RD.POLOS SEGI 30X40 (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'XMV1008', 'VAS BUNGA RD POLOS SEGI 30X40 (4BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TXV8103', 'VAS BUNGA RD.POLOS SEGI 30X40 + VAS BUNGA RD.PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAT1215', 'VAS BUNGA RD.POLOS SEGI 42 NYLON TUTTON', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT3010', 'VAS BUNGA RD PRINT 30X40 VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT6401', 'VAS BUNGA RD PRINT 42 M.NATURE', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3004', 'VAS BUNGA RD.PRINT BULAT 28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRT1871', 'VAS BUNGA RD.PRINT BULAT 28 B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3203', 'VAS BUNGA RD PRINT BULAT 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3202', 'VAS BUNGA RD.PRINT BULAT 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT3008', 'VAS BUNGA RD.PRINT BULAT 42 VICTORIA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3403', 'VAS BUNGA RD.PRINT BULAT 42X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT4001', 'VAS BUNGA RD.PRINT BULAT 42X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3206', 'VAS BUNGA RD.PRINT OVAL 20X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3201', 'VAS BUNGA RD.PRINT SEGI 28X28 A', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT4401', 'VAS BUNGA RD.PRINT SEGI 30X40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT4402', 'VAS BUNGA RD.PRINT SEGI 30X40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VAB1001', 'VAS BUNGA RD.PRINT SEGI 30X40 (2BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VSJ1000', 'VAS BUNGA RD.PRINT SEGI 30X40 (3BUAH)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT3009', 'VAS BUNGA RD PRINT SEGI 30X40 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VVR5108', 'VAS BUNGA RD PRINT SEGI 30X40 (ISI 4)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3003', 'VAS BUNGA RD.PRINT SEGI 42X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1003', 'VAS BUNGA RD.PRINT SEGI 42X42 MAESTRO', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT3100', 'VAS BUNGA RD SEGI 42X42 PRINT MAESTRO (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3120', 'VAS BUNGA RD SEGI PRINT 20X42', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2429', 'VAS BUNGA RD SEGI PRINT 28X28 B (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT2427', 'VAS BUNGA RD SEGI PRINT 42X42 (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TVB1001', 'VAS BUNGA SEGI BORDIR M. DUA BUNGA', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'KTKK033', 'VASHA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMT3401', 'V.B 20X42 OVAL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1307', 'VB.30 X 40 FULL PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMT3100', 'V.B 42X42 SEGI PRINT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRV8302', 'VB.PRINT BULAT M.01 BHN PLS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TRV8301', 'VB.PRINT SEGI M.01 BAHAN SLR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXT3005', 'VB RD BULAT 42X42 PRINT (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1027', 'V.B RD KOTAK A 28', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1029', 'V.B RD KOTAK B 28', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1402', 'VB RD PLS BULAT 42X42 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMV1403', 'VB RD PLS SEGI 20X42', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'PRV1402', 'VB. RD Pls. SEGI 28X28 B', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'IMV1401', 'VB RD PLS SEGI 42X42 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMV1407', 'VB.RD POLOS 30 X 40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VAB1000', 'VB.RD.POLOS 30X40+VB.RD.FULL PRINT SEGI 30X40', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1403', 'VB RD POLOS BULAT 42 M.BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRV3001', 'VB RD POLOS BULAT 42 M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'VSL1001', 'VB RD POLOS BULAT MONIQUE 3', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'PRV1301', 'VB. RD PRT. BULAT 28X28 A', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRV1404', 'VB RD PRT BULAT 42 M.BUAH', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'PRV3002', 'VB RD PRT BULAT 42 M. NATURE ', 'MAESTRO', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'MAESTRO');
INSERT INTO public.tr_product VALUES (3, 'IMV1006', 'VB RD PRT BULAT 42X42 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMV1005', 'VB. RD PRT. OVAL  20X42', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRV1101', 'VB. RD PRT. SEGI 28X28 A', 'KANSA', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'KANSA');
INSERT INTO public.tr_product VALUES (3, 'PRV1102', 'VB. RD PRT. SEGI 28X28 B', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1008', 'VB RD PRT SEGI 30X40 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IMV1001', 'VB RD PRT SEGI 42X42 ', 'PRESTIGE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'PRESTIGE');
INSERT INTO public.tr_product VALUES (3, 'IXV1006', 'VB RD SEGI 42X42 MAESTRO POLOS (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTKK029', 'VIA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'IMV1428', 'VITRAGE BUNGA 03', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1440', 'VITRAGE MARQISET ( L=150 )', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1425', 'VITRAGE MARQISET POLOS L=220', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1424', 'VITRAGE POLOS (KOKET) L=220', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1429', 'VITRAGE POLOS MARQISET L=150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1430', 'VITRAGE POLOS MARQISET L=150', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1426', 'VITRAGE RD.BUNGA M03', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR1607', 'VITRASE ABJAD FINISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KOV2406', 'VITRASE BABY JOY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0023', 'VITRASE BABY JOY BR 62 GR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV1427', 'VITRASE BUNGA M.03', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR2001', 'VITRASE DASAR POLOS', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0001', 'VITRASE DIALOGUE BABY M.BEAR 01', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'KVT0002', 'VITRASE DIALOGUE BABY M.KOALA 02', 'DIALOGUE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'DIALOGUE');
INSERT INTO public.tr_product VALUES (3, 'KOV2401', 'VITRASE DIALOGUE BABY M.KOALA KG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KOV2405', 'VITRASE DIALOGUE BABY M.SINGA KERETA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR2005', 'VITRASE HAGNOSE PESAWAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR2003', 'VITRASE HAGNOSE TWEETY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR4009', 'VITRASE HAGNOS PESAWAT FINISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR2004', 'VITRASE HAGNOS TWEETTY FINISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL1001', 'VITRASE JACQUARD DIALOGUE BABY M.DB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0021', 'VITRASE JACQUARD DIALOGUE BABY M. DB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0017', 'VITRASE JACQUARD M.BABY JOY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL1002', 'VITRASE JACQUARD M.BABY JOY 02', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0016', 'VITRASE JACQUARD M.BINTIK', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TXL3203', 'VITRASE JACQUARD M.BUNGA 01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0022', 'VITRASE JACQUARD M. BUNGA TULIP', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0024', 'VITRASE JACQUARD M. DIALOGUE LOGO BAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL1003', 'VITRASE JACQUARD M.LOGO DIALOGUE BARU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0020', 'VITRASE JACQUARD M MOMS BABY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTL1000', 'VITRASE JACQUARD M.MOM''S BABY 02', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0025', 'VITRASE JACQUARD M. OMILAND', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5016', 'VITRASE JAQUARD HARMONI M.BUNGA BARU 01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0012', 'VITRASE JAQUARD M.ABJAD', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH6202', 'VITRASE JAQUARD M.ANAK AYAM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'DLH5017', 'VITRASE JAQUARD M.BUNGA RAMPAI', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0011', 'VITRASE JAQUARD M.DAUN BAMBU', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLB1002', 'VITRASE KOKET CORAK MARKISET FB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLH0070', 'VITRASE KOKET CORAK MARKISET SF', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLB1001', 'VITRASE KOKET POLOS MARKISET FB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KLB1003', 'VITRASE KOKET POLOS MARKISET SF', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KAV1404', 'VITRASE KOKET POLOS MARKISET TB', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TSR2002', 'VITRASE MOTIF BABY FINISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IMV2000', 'VITRASE POLOS MO3 MOTIF 3309', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KPL1000', 'VITRASE RENDA JAQUARD M.BUNGA BARU 01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TXT6115', 'VITRASE RENDA MOTIF BUNGA 01', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0008', 'VITRASE SCHALOOP M.GGW', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0009', 'VITRASE SCHALOOP M.PUTIH BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0018', 'VITRASE SCHALOOP SAMBUNGAN M.BUNGA IDAMAN ', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'GVT0010', 'VITRASE SCHALOOP WARNA', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TTN1120', 'VITRASE SKY LOVE COKLAT', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TTN1211', 'VITRASE SKY LOVE GIGI WALANG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TVR1312', 'VITRASE SKY LOVE PUTIH BESAR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TXL3101', 'VITRASE SNOBBY', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KOV2402', 'VITRASE SNOBBY BABY M.JERAPAH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KOV2404', 'VITRASE SNOBBY BABY M.JERAPAH 02', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KOV240200B', 'VITRASE SNOBBY BABY M.JERAPAH L:160', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KVT0003', 'VITRASE SNOBBY BABY M.JERAPAH L:160', 'SNOBBY', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'SNOBBY');
INSERT INTO public.tr_product VALUES (3, 'KOV2403', 'VITRASE SNOBBY M.JERAPAH KG', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'TVR1808', 'VITRSE SKY LOVE FINISH', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VSG1000', 'WASLAP POLOS BORDIR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VSC1000', 'WASLAP PRINT BORDIR', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VPR1000', 'WASLAP PRINT E/S', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'IXV1026', 'WASLAP PRINT E/S (B)', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AWH1010', 'WHISTLE 22 MM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AWH1020', 'WHISTLE 38 MM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'AWH1030', 'WHISTLE 40 MM', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'KTBB084', 'WINA', 'FASHION', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'FASHION');
INSERT INTO public.tr_product VALUES (3, 'AWC1010', 'WIND CHIMES', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'LFW1020', 'WRIST AND ANKLE TOYS LION AND PANDA', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFW1030', 'WRIST AND ANKLE TOYS MOON AND STAR', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'LFW1010', 'WRIST AND ANKLE TOYS MOUSE AND KITTY', 'LITTLE FRIENDS', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LITTLE FRIENDS');
INSERT INTO public.tr_product VALUES (3, 'ATE1011', 'YELLOW TEETHING', 'LAIN-LAIN', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'LAIN-LAIN');
INSERT INTO public.tr_product VALUES (3, 'VMD2030', 'YELVO DOLL PRINT FOX', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD2010', 'YELVO DOLL PRINT RABBIT', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD2040', 'YELVO DOLL PRINT RACOON', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');
INSERT INTO public.tr_product VALUES (3, 'VMD2020', 'YELVO DOLL PRINT SQUIRREL', 'VEE & MEE', 0.00, 0.00, true, '2021-08-13 08:09:32.935612', NULL, 'VEE & MEE');


--
-- TOC entry 3303 (class 0 OID 17899)
-- Dependencies: 228
-- Data for Name: tr_type_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_type_customer VALUES (1, 'Baby', true);
INSERT INTO public.tr_type_customer VALUES (2, 'Retail', true);


--
-- TOC entry 3305 (class 0 OID 17904)
-- Dependencies: 230
-- Data for Name: tr_user_power; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_user_power VALUES (1, 'Create');
INSERT INTO public.tr_user_power VALUES (2, 'Read');
INSERT INTO public.tr_user_power VALUES (3, 'Update');
INSERT INTO public.tr_user_power VALUES (4, 'Delete');


--
-- TOC entry 3331 (class 0 OID 0)
-- Dependencies: 198
-- Name: tm_pembelian_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_id_document_seq', 126, true);


--
-- TOC entry 3332 (class 0 OID 0)
-- Dependencies: 200
-- Name: tm_pembelian_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_item_id_item_seq', 346, true);


--
-- TOC entry 3333 (class 0 OID 0)
-- Dependencies: 202
-- Name: tm_pembelian_retur_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_retur_id_document_seq', 1, false);


--
-- TOC entry 3334 (class 0 OID 0)
-- Dependencies: 204
-- Name: tm_pembelian_retur_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_retur_item_id_item_seq', 7, true);


--
-- TOC entry 3335 (class 0 OID 0)
-- Dependencies: 206
-- Name: tm_penjualan_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_penjualan_id_document_seq', 1, false);


--
-- TOC entry 3336 (class 0 OID 0)
-- Dependencies: 208
-- Name: tm_penjualan_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_penjualan_item_id_item_seq', 21, true);


--
-- TOC entry 3337 (class 0 OID 0)
-- Dependencies: 214
-- Name: tm_user_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_user_id_user_seq', 1, true);


--
-- TOC entry 3338 (class 0 OID 0)
-- Dependencies: 217
-- Name: tr_alasan_retur_i_alasan_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_alasan_retur_i_alasan_seq', 2, true);


--
-- TOC entry 3339 (class 0 OID 0)
-- Dependencies: 219
-- Name: tr_company_i_company_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_company_i_company_seq', 5, true);


--
-- TOC entry 3340 (class 0 OID 0)
-- Dependencies: 221
-- Name: tr_customer_id_customer_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_customer_id_customer_seq', 1, true);


--
-- TOC entry 3341 (class 0 OID 0)
-- Dependencies: 223
-- Name: tr_customer_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_customer_item_id_item_seq', 22, true);


--
-- TOC entry 3342 (class 0 OID 0)
-- Dependencies: 225
-- Name: tr_level_i_level_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_level_i_level_seq', 4, true);


--
-- TOC entry 3343 (class 0 OID 0)
-- Dependencies: 233
-- Name: tr_panduan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_panduan_id_seq', 19, true);


--
-- TOC entry 3344 (class 0 OID 0)
-- Dependencies: 229
-- Name: tr_type_customer_i_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_type_customer_i_type_seq', 2, true);


--
-- TOC entry 3345 (class 0 OID 0)
-- Dependencies: 231
-- Name: tr_user_power_i_power_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_user_power_i_power_seq', 1, true);


--
-- TOC entry 3053 (class 2606 OID 17925)
-- Name: tr_alasan_retur pk_alasan_retur; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_alasan_retur
    ADD CONSTRAINT pk_alasan_retur PRIMARY KEY (i_alasan);


--
-- TOC entry 3057 (class 2606 OID 17927)
-- Name: tr_company pk_company; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_company
    ADD CONSTRAINT pk_company PRIMARY KEY (i_company);


--
-- TOC entry 3062 (class 2606 OID 17929)
-- Name: tr_customer pk_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT pk_customer PRIMARY KEY (id_customer);


--
-- TOC entry 3069 (class 2606 OID 17931)
-- Name: tr_customer_item pk_customer_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT pk_customer_item PRIMARY KEY (id_item);


--
-- TOC entry 2972 (class 2606 OID 17933)
-- Name: dg_log pk_log; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dg_log
    ADD CONSTRAINT pk_log PRIMARY KEY (id_user, ip_address, waktu);


--
-- TOC entry 2979 (class 2606 OID 17935)
-- Name: tm_pembelian pk_tm_pembelian; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT pk_tm_pembelian PRIMARY KEY (id_document);


--
-- TOC entry 2988 (class 2606 OID 17937)
-- Name: tm_pembelian_item pk_tm_pembelian_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT pk_tm_pembelian_item PRIMARY KEY (id_item);


--
-- TOC entry 2997 (class 2606 OID 17939)
-- Name: tm_pembelian_retur pk_tm_pembelian_retur; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur
    ADD CONSTRAINT pk_tm_pembelian_retur PRIMARY KEY (id_document);


--
-- TOC entry 3004 (class 2606 OID 17941)
-- Name: tm_pembelian_retur_item pk_tm_pembelian_retur_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT pk_tm_pembelian_retur_item PRIMARY KEY (id_item);


--
-- TOC entry 3012 (class 2606 OID 17943)
-- Name: tm_penjualan pk_tm_penjualan; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan
    ADD CONSTRAINT pk_tm_penjualan PRIMARY KEY (id_document);


--
-- TOC entry 3019 (class 2606 OID 17945)
-- Name: tm_penjualan_item pk_tm_penjualan_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT pk_tm_penjualan_item PRIMARY KEY (id_item);


--
-- TOC entry 3025 (class 2606 OID 17947)
-- Name: tm_saldo_awal pk_tm_saldo_awal; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT pk_tm_saldo_awal PRIMARY KEY (id_customer, i_periode, i_company, i_product);


--
-- TOC entry 3036 (class 2606 OID 17949)
-- Name: tm_user pk_tm_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user
    ADD CONSTRAINT pk_tm_user PRIMARY KEY (id_user);


--
-- TOC entry 3040 (class 2606 OID 17951)
-- Name: tm_user_company pk_tm_user_company; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_company
    ADD CONSTRAINT pk_tm_user_company PRIMARY KEY (id_user, i_company);


--
-- TOC entry 3044 (class 2606 OID 17953)
-- Name: tm_user_customer pk_tm_user_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT pk_tm_user_customer PRIMARY KEY (id_user, id_customer);


--
-- TOC entry 3049 (class 2606 OID 17955)
-- Name: tm_user_role pk_tm_user_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_role
    ADD CONSTRAINT pk_tm_user_role PRIMARY KEY (id_menu, i_power, i_level);


--
-- TOC entry 3096 (class 2606 OID 40804)
-- Name: tr_customer_price pk_tr_customer_price; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_price
    ADD CONSTRAINT pk_tr_customer_price PRIMARY KEY (id_customer, i_company, i_product);


--
-- TOC entry 3073 (class 2606 OID 17957)
-- Name: tr_level pk_tr_level; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_level
    ADD CONSTRAINT pk_tr_level PRIMARY KEY (i_level);


--
-- TOC entry 3079 (class 2606 OID 17959)
-- Name: tr_menu pk_tr_menu; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_menu
    ADD CONSTRAINT pk_tr_menu PRIMARY KEY (id_menu);


--
-- TOC entry 3100 (class 2606 OID 40839)
-- Name: tr_panduan pk_tr_panduan; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_panduan
    ADD CONSTRAINT pk_tr_panduan PRIMARY KEY (id);


--
-- TOC entry 3086 (class 2606 OID 17961)
-- Name: tr_product pk_tr_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT pk_tr_product PRIMARY KEY (i_company, i_product);


--
-- TOC entry 3094 (class 2606 OID 17963)
-- Name: tr_user_power pk_tr_user_power; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_user_power
    ADD CONSTRAINT pk_tr_user_power PRIMARY KEY (i_power);


--
-- TOC entry 3090 (class 2606 OID 17965)
-- Name: tr_type_customer pk_type_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_type_customer
    ADD CONSTRAINT pk_type_customer PRIMARY KEY (i_type);


--
-- TOC entry 2990 (class 2606 OID 41774)
-- Name: tm_pembelian_item tm_pembelian_item_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT tm_pembelian_item_unique UNIQUE (id_document, i_company, i_product);


--
-- TOC entry 2981 (class 2606 OID 41772)
-- Name: tm_pembelian tm_pembelian_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT tm_pembelian_unique UNIQUE (id_item, i_company, i_document);


--
-- TOC entry 2967 (class 1259 OID 41855)
-- Name: idx_dg_log_activity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dg_log_activity ON public.dg_log USING btree (activity);


--
-- TOC entry 2968 (class 1259 OID 41853)
-- Name: idx_dg_log_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dg_log_address ON public.dg_log USING btree (ip_address);


--
-- TOC entry 2969 (class 1259 OID 41851)
-- Name: idx_dg_log_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dg_log_user ON public.dg_log USING btree (id_user);


--
-- TOC entry 2970 (class 1259 OID 41854)
-- Name: idx_dg_log_waktu; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dg_log_waktu ON public.dg_log USING btree (waktu);


--
-- TOC entry 2973 (class 1259 OID 41858)
-- Name: idx_tm_pembelian_dreceive; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_dreceive ON public.tm_pembelian USING btree (d_receive);


--
-- TOC entry 2982 (class 1259 OID 41880)
-- Name: idx_tm_pembelian_eproductname; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_eproductname ON public.tm_pembelian_item USING btree (e_product_name);


--
-- TOC entry 2974 (class 1259 OID 41860)
-- Name: idx_tm_pembelian_icompany; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_icompany ON public.tm_pembelian USING btree (i_company);


--
-- TOC entry 2975 (class 1259 OID 41856)
-- Name: idx_tm_pembelian_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_id ON public.tm_pembelian USING btree (id_document);


--
-- TOC entry 2983 (class 1259 OID 41877)
-- Name: idx_tm_pembelian_id_document; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_id_document ON public.tm_pembelian_item USING btree (id_document);


--
-- TOC entry 2976 (class 1259 OID 41857)
-- Name: idx_tm_pembelian_idocument; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_idocument ON public.tm_pembelian USING btree (i_document);


--
-- TOC entry 2984 (class 1259 OID 41878)
-- Name: idx_tm_pembelian_item_icompany; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_item_icompany ON public.tm_pembelian_item USING btree (i_company);


--
-- TOC entry 2985 (class 1259 OID 41876)
-- Name: idx_tm_pembelian_item_id_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_item_id_item ON public.tm_pembelian_item USING btree (id_item);


--
-- TOC entry 2986 (class 1259 OID 41879)
-- Name: idx_tm_pembelian_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_product ON public.tm_pembelian_item USING btree (i_product);


--
-- TOC entry 2991 (class 1259 OID 41920)
-- Name: idx_tm_pembelian_retur_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_customer ON public.tm_pembelian_retur USING btree (id_customer);


--
-- TOC entry 2992 (class 1259 OID 41918)
-- Name: idx_tm_pembelian_retur_dretur; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_dretur ON public.tm_pembelian_retur USING btree (d_retur);


--
-- TOC entry 2998 (class 1259 OID 41935)
-- Name: idx_tm_pembelian_retur_eproductname; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_eproductname ON public.tm_pembelian_retur_item USING btree (e_product_name);


--
-- TOC entry 2993 (class 1259 OID 41916)
-- Name: idx_tm_pembelian_retur_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_id ON public.tm_pembelian_retur USING btree (id_document);


--
-- TOC entry 2994 (class 1259 OID 41917)
-- Name: idx_tm_pembelian_retur_idocument; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_idocument ON public.tm_pembelian_retur USING btree (i_document);


--
-- TOC entry 2999 (class 1259 OID 41933)
-- Name: idx_tm_pembelian_retur_item_icompany; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_item_icompany ON public.tm_pembelian_retur_item USING btree (i_company);


--
-- TOC entry 3000 (class 1259 OID 41932)
-- Name: idx_tm_pembelian_retur_item_id_document; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_item_id_document ON public.tm_pembelian_retur_item USING btree (id_document);


--
-- TOC entry 3001 (class 1259 OID 41931)
-- Name: idx_tm_pembelian_retur_item_id_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_item_id_item ON public.tm_pembelian_retur_item USING btree (id_item);


--
-- TOC entry 3002 (class 1259 OID 41934)
-- Name: idx_tm_pembelian_retur_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_product ON public.tm_pembelian_retur_item USING btree (i_product);


--
-- TOC entry 2995 (class 1259 OID 41919)
-- Name: idx_tm_pembelian_retur_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_retur_user ON public.tm_pembelian_retur USING btree (id_user);


--
-- TOC entry 2977 (class 1259 OID 41859)
-- Name: idx_tm_pembelian_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_pembelian_user ON public.tm_pembelian USING btree (id_user);


--
-- TOC entry 3005 (class 1259 OID 41975)
-- Name: idx_tm_penjualan_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_customer ON public.tm_penjualan USING btree (id_customer);


--
-- TOC entry 3006 (class 1259 OID 41976)
-- Name: idx_tm_penjualan_customername; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_customername ON public.tm_penjualan USING btree (e_customer_sell_name);


--
-- TOC entry 3007 (class 1259 OID 41973)
-- Name: idx_tm_penjualan_ddocument; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_ddocument ON public.tm_penjualan USING btree (d_document);


--
-- TOC entry 3008 (class 1259 OID 41971)
-- Name: idx_tm_penjualan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_id ON public.tm_penjualan USING btree (id_document);


--
-- TOC entry 3009 (class 1259 OID 41972)
-- Name: idx_tm_penjualan_idocument; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_idocument ON public.tm_penjualan USING btree (i_document);


--
-- TOC entry 3013 (class 1259 OID 41991)
-- Name: idx_tm_penjualan_item_eproductname; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_item_eproductname ON public.tm_penjualan_item USING btree (e_product_name);


--
-- TOC entry 3014 (class 1259 OID 41989)
-- Name: idx_tm_penjualan_item_icompany; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_item_icompany ON public.tm_penjualan_item USING btree (i_company);


--
-- TOC entry 3015 (class 1259 OID 41988)
-- Name: idx_tm_penjualan_item_id_document; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_item_id_document ON public.tm_penjualan_item USING btree (id_document);


--
-- TOC entry 3016 (class 1259 OID 41987)
-- Name: idx_tm_penjualan_item_id_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_item_id_item ON public.tm_penjualan_item USING btree (id_item);


--
-- TOC entry 3017 (class 1259 OID 41990)
-- Name: idx_tm_penjualan_item_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_item_product ON public.tm_penjualan_item USING btree (i_product);


--
-- TOC entry 3010 (class 1259 OID 41974)
-- Name: idx_tm_penjualan_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_penjualan_user ON public.tm_penjualan USING btree (id_user);


--
-- TOC entry 3020 (class 1259 OID 42007)
-- Name: idx_tm_saldo_awal_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_saldo_awal_customer ON public.tm_saldo_awal USING btree (id_customer);


--
-- TOC entry 3021 (class 1259 OID 42009)
-- Name: idx_tm_saldo_awal_icompany; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_saldo_awal_icompany ON public.tm_saldo_awal USING btree (i_company);


--
-- TOC entry 3022 (class 1259 OID 42008)
-- Name: idx_tm_saldo_awal_periode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_saldo_awal_periode ON public.tm_saldo_awal USING btree (i_periode);


--
-- TOC entry 3023 (class 1259 OID 42010)
-- Name: idx_tm_saldo_awal_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_saldo_awal_product ON public.tm_saldo_awal USING btree (i_product);


--
-- TOC entry 3026 (class 1259 OID 42029)
-- Name: idx_tm_sessions_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_sessions_data ON public.tm_sessions USING btree (data);


--
-- TOC entry 3027 (class 1259 OID 42026)
-- Name: idx_tm_sessions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_sessions_id ON public.tm_sessions USING btree (id);


--
-- TOC entry 3028 (class 1259 OID 42027)
-- Name: idx_tm_sessions_ip; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_sessions_ip ON public.tm_sessions USING btree (ip_address);


--
-- TOC entry 3029 (class 1259 OID 42028)
-- Name: idx_tm_sessions_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_sessions_time ON public.tm_sessions USING btree ("timestamp");


--
-- TOC entry 3037 (class 1259 OID 42040)
-- Name: idx_tm_user_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_company ON public.tm_user_company USING btree (i_company);


--
-- TOC entry 3038 (class 1259 OID 42039)
-- Name: idx_tm_user_company_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_company_user ON public.tm_user_company USING btree (id_user);


--
-- TOC entry 3041 (class 1259 OID 42057)
-- Name: idx_tm_user_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_customer ON public.tm_user_customer USING btree (id_customer);


--
-- TOC entry 3042 (class 1259 OID 42056)
-- Name: idx_tm_user_customer_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_customer_user ON public.tm_user_customer USING btree (id_user);


--
-- TOC entry 3031 (class 1259 OID 42030)
-- Name: idx_tm_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_id ON public.tm_user USING btree (id_user);


--
-- TOC entry 3032 (class 1259 OID 42033)
-- Name: idx_tm_user_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_level ON public.tm_user USING btree (i_level);


--
-- TOC entry 3033 (class 1259 OID 42032)
-- Name: idx_tm_user_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_name ON public.tm_user USING btree (e_nama);


--
-- TOC entry 3045 (class 1259 OID 42070)
-- Name: idx_tm_user_role_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_role_level ON public.tm_user_role USING btree (i_level);


--
-- TOC entry 3046 (class 1259 OID 42068)
-- Name: idx_tm_user_role_menu; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_role_menu ON public.tm_user_role USING btree (id_menu);


--
-- TOC entry 3047 (class 1259 OID 42069)
-- Name: idx_tm_user_role_power; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_role_power ON public.tm_user_role USING btree (i_power);


--
-- TOC entry 3034 (class 1259 OID 42031)
-- Name: idx_tm_user_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tm_user_username ON public.tm_user USING btree (username);


--
-- TOC entry 3050 (class 1259 OID 42086)
-- Name: idx_tr_alasan_retur_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_alasan_retur_id ON public.tr_alasan_retur USING btree (i_alasan);


--
-- TOC entry 3051 (class 1259 OID 42087)
-- Name: idx_tr_alasan_retur_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_alasan_retur_name ON public.tr_alasan_retur USING btree (e_alasan);


--
-- TOC entry 3054 (class 1259 OID 42088)
-- Name: idx_tr_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_company_id ON public.tr_company USING btree (i_company);


--
-- TOC entry 3055 (class 1259 OID 42089)
-- Name: idx_tr_company_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_company_name ON public.tr_company USING btree (e_company_name);


--
-- TOC entry 3058 (class 1259 OID 42090)
-- Name: idx_tr_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_id ON public.tr_customer USING btree (id_customer);


--
-- TOC entry 3063 (class 1259 OID 42100)
-- Name: idx_tr_customer_item_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_item_company ON public.tr_customer_item USING btree (i_company);


--
-- TOC entry 3064 (class 1259 OID 42099)
-- Name: idx_tr_customer_item_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_item_customer ON public.tr_customer_item USING btree (id_customer);


--
-- TOC entry 3065 (class 1259 OID 42102)
-- Name: idx_tr_customer_item_customername; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_item_customername ON public.tr_customer_item USING btree (e_customer_name);


--
-- TOC entry 3066 (class 1259 OID 42098)
-- Name: idx_tr_customer_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_item_id ON public.tr_customer_item USING btree (id_item);


--
-- TOC entry 3067 (class 1259 OID 42101)
-- Name: idx_tr_customer_item_kodecustomer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_item_kodecustomer ON public.tr_customer_item USING btree (i_customer);


--
-- TOC entry 3059 (class 1259 OID 42091)
-- Name: idx_tr_customer_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_name ON public.tr_customer USING btree (e_customer_name);


--
-- TOC entry 3060 (class 1259 OID 42092)
-- Name: idx_tr_customer_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_customer_type ON public.tr_customer USING btree (i_type);


--
-- TOC entry 3070 (class 1259 OID 42138)
-- Name: idx_tr_level_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_level_id ON public.tr_level USING btree (i_level);


--
-- TOC entry 3071 (class 1259 OID 42139)
-- Name: idx_tr_level_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_level_name ON public.tr_level USING btree (e_level_name);


--
-- TOC entry 3074 (class 1259 OID 42143)
-- Name: idx_tr_menu_folder; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_menu_folder ON public.tr_menu USING btree (e_folder);


--
-- TOC entry 3075 (class 1259 OID 42140)
-- Name: idx_tr_menu_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_menu_id ON public.tr_menu USING btree (id_menu);


--
-- TOC entry 3076 (class 1259 OID 42141)
-- Name: idx_tr_menu_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_menu_name ON public.tr_menu USING btree (e_menu);


--
-- TOC entry 3077 (class 1259 OID 42142)
-- Name: idx_tr_menu_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_menu_parent ON public.tr_menu USING btree (i_parent);


--
-- TOC entry 3097 (class 1259 OID 42144)
-- Name: idx_tr_panduan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_panduan_id ON public.tr_panduan USING btree (id);


--
-- TOC entry 3098 (class 1259 OID 42145)
-- Name: idx_tr_panduan_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_panduan_name ON public.tr_panduan USING btree (e_file_name);


--
-- TOC entry 3080 (class 1259 OID 42149)
-- Name: idx_tr_product_brand; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_product_brand ON public.tr_product USING btree (e_brand);


--
-- TOC entry 3081 (class 1259 OID 42146)
-- Name: idx_tr_product_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_product_company ON public.tr_product USING btree (i_company);


--
-- TOC entry 3082 (class 1259 OID 42150)
-- Name: idx_tr_product_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_product_group ON public.tr_product USING btree (e_product_groupname);


--
-- TOC entry 3083 (class 1259 OID 42147)
-- Name: idx_tr_product_kode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_product_kode ON public.tr_product USING btree (i_product);


--
-- TOC entry 3084 (class 1259 OID 42148)
-- Name: idx_tr_product_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_product_name ON public.tr_product USING btree (e_product_name);


--
-- TOC entry 3087 (class 1259 OID 42156)
-- Name: idx_tr_type_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_type_customer_id ON public.tr_type_customer USING btree (i_type);


--
-- TOC entry 3088 (class 1259 OID 42157)
-- Name: idx_tr_type_customer_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_type_customer_name ON public.tr_type_customer USING btree (e_type);


--
-- TOC entry 3091 (class 1259 OID 42158)
-- Name: idx_tr_user_power_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_user_power_id ON public.tr_user_power USING btree (i_power);


--
-- TOC entry 3092 (class 1259 OID 42159)
-- Name: idx_tr_user_power_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tr_user_power_name ON public.tr_user_power USING btree (e_power_name);


--
-- TOC entry 3030 (class 1259 OID 18032)
-- Name: tm_sessions_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tm_sessions_timestamp ON public.tm_sessions USING btree ("timestamp");


--
-- TOC entry 3139 (class 2606 OID 17966)
-- Name: tr_customer fk_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT fk_customer FOREIGN KEY (i_type) REFERENCES public.tr_type_customer(i_type);


--
-- TOC entry 3141 (class 2606 OID 17971)
-- Name: tr_customer_item fk_customer_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);


--
-- TOC entry 3142 (class 2606 OID 17976)
-- Name: tr_customer_item fk_customer_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item2 FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);


--
-- TOC entry 3101 (class 2606 OID 41845)
-- Name: dg_log fk_dg_log; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dg_log
    ADD CONSTRAINT fk_dg_log FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3102 (class 2606 OID 17981)
-- Name: tm_pembelian fk_tm_pembelian; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian FOREIGN KEY (id_item) REFERENCES public.tr_customer_item(id_item);


--
-- TOC entry 3105 (class 2606 OID 41871)
-- Name: tm_pembelian fk_tm_pembelian_i_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian_i_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3103 (class 2606 OID 41861)
-- Name: tm_pembelian fk_tm_pembelian_id_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian_id_item FOREIGN KEY (id_item) REFERENCES public.tr_customer_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3104 (class 2606 OID 41866)
-- Name: tm_pembelian fk_tm_pembelian_id_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian_id_user FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3106 (class 2606 OID 17986)
-- Name: tm_pembelian_item fk_tm_pembelian_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian(id_document);


--
-- TOC entry 3108 (class 2606 OID 41901)
-- Name: tm_pembelian_item fk_tm_pembelian_item_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3107 (class 2606 OID 41896)
-- Name: tm_pembelian_item fk_tm_pembelian_item_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item_id FOREIGN KEY (id_document) REFERENCES public.tm_pembelian(id_document) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3109 (class 2606 OID 41911)
-- Name: tm_pembelian_item fk_tm_pembelian_item_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item_product FOREIGN KEY (i_company, i_product) REFERENCES public.tr_product(i_company, i_product) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3111 (class 2606 OID 41926)
-- Name: tm_pembelian_retur fk_tm_pembelian_retur_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur
    ADD CONSTRAINT fk_tm_pembelian_retur_customer FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3112 (class 2606 OID 17991)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian_retur(id_document);


--
-- TOC entry 3113 (class 2606 OID 17996)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item2 FOREIGN KEY (i_alasan) REFERENCES public.tr_alasan_retur(i_alasan);


--
-- TOC entry 3117 (class 2606 OID 41966)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item_alasan; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item_alasan FOREIGN KEY (i_alasan) REFERENCES public.tr_alasan_retur(i_alasan) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3115 (class 2606 OID 41956)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3114 (class 2606 OID 41951)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item_id FOREIGN KEY (id_document) REFERENCES public.tm_pembelian_retur(id_document) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3116 (class 2606 OID 41961)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item_product FOREIGN KEY (i_company, i_product) REFERENCES public.tr_product(i_company, i_product) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3110 (class 2606 OID 41921)
-- Name: tm_pembelian_retur fk_tm_pembelian_retur_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur
    ADD CONSTRAINT fk_tm_pembelian_retur_user FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3119 (class 2606 OID 41982)
-- Name: tm_penjualan fk_tm_penjualan_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan
    ADD CONSTRAINT fk_tm_penjualan_customer FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3120 (class 2606 OID 18001)
-- Name: tm_penjualan_item fk_tm_penjualan_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item2 FOREIGN KEY (id_document) REFERENCES public.tm_penjualan(id_document);


--
-- TOC entry 3122 (class 2606 OID 41997)
-- Name: tm_penjualan_item fk_tm_penjualan_item_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3121 (class 2606 OID 41992)
-- Name: tm_penjualan_item fk_tm_penjualan_item_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item_id FOREIGN KEY (id_document) REFERENCES public.tm_penjualan(id_document) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3123 (class 2606 OID 42002)
-- Name: tm_penjualan_item fk_tm_penjualan_item_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item_product FOREIGN KEY (i_company, i_product) REFERENCES public.tr_product(i_company, i_product) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3118 (class 2606 OID 41977)
-- Name: tm_penjualan fk_tm_penjualan_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan
    ADD CONSTRAINT fk_tm_penjualan_user FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3125 (class 2606 OID 42016)
-- Name: tm_saldo_awal fk_tm_saldo_awal_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT fk_tm_saldo_awal_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3124 (class 2606 OID 42011)
-- Name: tm_saldo_awal fk_tm_saldo_awal_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT fk_tm_saldo_awal_customer FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3126 (class 2606 OID 42021)
-- Name: tm_saldo_awal fk_tm_saldo_awal_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT fk_tm_saldo_awal_product FOREIGN KEY (i_company, i_product) REFERENCES public.tr_product(i_company, i_product) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3128 (class 2606 OID 18006)
-- Name: tm_user_company fk_tm_user_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_company
    ADD CONSTRAINT fk_tm_user_company FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user);


--
-- TOC entry 3129 (class 2606 OID 18011)
-- Name: tm_user_company fk_tm_user_company2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_company
    ADD CONSTRAINT fk_tm_user_company2 FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);


--
-- TOC entry 3131 (class 2606 OID 42051)
-- Name: tm_user_company fk_tm_user_company_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_company
    ADD CONSTRAINT fk_tm_user_company_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3130 (class 2606 OID 42046)
-- Name: tm_user_company fk_tm_user_company_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_company
    ADD CONSTRAINT fk_tm_user_company_user FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3132 (class 2606 OID 18016)
-- Name: tm_user_customer fk_tm_user_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user);


--
-- TOC entry 3133 (class 2606 OID 18021)
-- Name: tm_user_customer fk_tm_user_customer2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer2 FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);


--
-- TOC entry 3135 (class 2606 OID 42063)
-- Name: tm_user_customer fk_tm_user_customer_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer_customer FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3134 (class 2606 OID 42058)
-- Name: tm_user_customer fk_tm_user_customer_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer_user FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3127 (class 2606 OID 42034)
-- Name: tm_user fk_tm_user_level; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user
    ADD CONSTRAINT fk_tm_user_level FOREIGN KEY (i_level) REFERENCES public.tr_level(i_level) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3137 (class 2606 OID 42081)
-- Name: tm_user_role fk_tm_user_role_level; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_role
    ADD CONSTRAINT fk_tm_user_role_level FOREIGN KEY (i_level) REFERENCES public.tr_level(i_level) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3138 (class 2606 OID 42160)
-- Name: tm_user_role fk_tm_user_role_menu; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_role
    ADD CONSTRAINT fk_tm_user_role_menu FOREIGN KEY (id_menu) REFERENCES public.tr_menu(id_menu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3136 (class 2606 OID 42076)
-- Name: tm_user_role fk_tm_user_role_power; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_role
    ADD CONSTRAINT fk_tm_user_role_power FOREIGN KEY (i_power) REFERENCES public.tr_user_power(i_power) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3144 (class 2606 OID 42108)
-- Name: tr_customer_item fk_tr_customer_item_customer_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_tr_customer_item_customer_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3143 (class 2606 OID 42103)
-- Name: tr_customer_item fk_tr_customer_item_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_tr_customer_item_customer_id FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3148 (class 2606 OID 42128)
-- Name: tr_customer_price fk_tr_customer_price_customer_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_price
    ADD CONSTRAINT fk_tr_customer_price_customer_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3147 (class 2606 OID 42123)
-- Name: tr_customer_price fk_tr_customer_price_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_price
    ADD CONSTRAINT fk_tr_customer_price_customer_id FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3149 (class 2606 OID 42133)
-- Name: tr_customer_price fk_tr_customer_price_customer_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_price
    ADD CONSTRAINT fk_tr_customer_price_customer_product FOREIGN KEY (i_company, i_product) REFERENCES public.tr_product(i_company, i_product) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3140 (class 2606 OID 42093)
-- Name: tr_customer fk_tr_customer_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT fk_tr_customer_type FOREIGN KEY (i_type) REFERENCES public.tr_type_customer(i_type) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3145 (class 2606 OID 18026)
-- Name: tr_product fk_tr_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT fk_tr_product FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);


--
-- TOC entry 3146 (class 2606 OID 42151)
-- Name: tr_product fk_tr_product_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT fk_tr_product_company FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2021-08-26 10:00:57 WIB

--
-- PostgreSQL database dump complete
--

