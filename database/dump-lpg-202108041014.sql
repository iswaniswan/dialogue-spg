--
-- PostgreSQL database dump
--

-- Dumped from database version 10.17
-- Dumped by pg_dump version 12.2

-- Started on 2021-08-04 10:14:02

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
-- TOC entry 3 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3030 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

--
-- TOC entry 196 (class 1259 OID 36115)
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
-- TOC entry 197 (class 1259 OID 36122)
-- Name: tm_pembelian; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian (
    id_document integer NOT NULL,
    id_item integer,
    i_document character varying(50),
    d_receive date,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);


ALTER TABLE public.tm_pembelian OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 36130)
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
-- TOC entry 3031 (class 0 OID 0)
-- Dependencies: 198
-- Name: tm_pembelian_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_id_document_seq OWNED BY public.tm_pembelian.id_document;


--
-- TOC entry 199 (class 1259 OID 36132)
-- Name: tm_pembelian_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    v_price numeric,
    e_remark text
);


ALTER TABLE public.tm_pembelian_item OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 36138)
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
-- TOC entry 3032 (class 0 OID 0)
-- Dependencies: 200
-- Name: tm_pembelian_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_item_id_item_seq OWNED BY public.tm_pembelian_item.id_item;


--
-- TOC entry 201 (class 1259 OID 36140)
-- Name: tm_pembelian_retur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_retur (
    id_document integer NOT NULL,
    i_document character varying(50),
    d_retur date,
    e_remark text,
    f_transfer boolean DEFAULT false,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);


ALTER TABLE public.tm_pembelian_retur OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 36149)
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
-- TOC entry 3033 (class 0 OID 0)
-- Dependencies: 202
-- Name: tm_pembelian_retur_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_retur_id_document_seq OWNED BY public.tm_pembelian_retur.id_document;


--
-- TOC entry 203 (class 1259 OID 36151)
-- Name: tm_pembelian_retur_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_pembelian_retur_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    i_alasan integer,
    i_document character varying(50)
);


ALTER TABLE public.tm_pembelian_retur_item OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 36154)
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
-- TOC entry 3034 (class 0 OID 0)
-- Dependencies: 204
-- Name: tm_pembelian_retur_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_pembelian_retur_item_id_item_seq OWNED BY public.tm_pembelian_retur_item.id_item;


--
-- TOC entry 205 (class 1259 OID 36156)
-- Name: tm_penjualan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_penjualan (
    id_document integer NOT NULL,
    i_document character varying(50),
    d_document date,
    e_customer_sell_name character varying(120),
    e_customer_sell_address character varying(255),
    v_gross numeric,
    n_diskon numeric(2,2),
    v_diskon numeric,
    v_diskon_total numeric,
    v_ppn numeric,
    v_netto numeric,
    v_bayar numeric,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);


ALTER TABLE public.tm_penjualan OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 36164)
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
-- TOC entry 3035 (class 0 OID 0)
-- Dependencies: 206
-- Name: tm_penjualan_id_document_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_penjualan_id_document_seq OWNED BY public.tm_penjualan.id_document;


--
-- TOC entry 207 (class 1259 OID 36166)
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
-- TOC entry 208 (class 1259 OID 36172)
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
-- TOC entry 3036 (class 0 OID 0)
-- Dependencies: 208
-- Name: tm_penjualan_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_penjualan_item_id_item_seq OWNED BY public.tm_penjualan_item.id_item;


--
-- TOC entry 209 (class 1259 OID 36174)
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
-- TOC entry 210 (class 1259 OID 36177)
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
-- TOC entry 211 (class 1259 OID 36185)
-- Name: tm_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user (
    id_user integer NOT NULL,
    username character varying(255),
    password character varying(255),
    e_nama character varying(255),
    i_level integer,
    i_company integer,
    f_status boolean DEFAULT true,
    f_allcustomer boolean DEFAULT false
);


ALTER TABLE public.tm_user OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 36193)
-- Name: tm_user_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user_customer (
    id_user integer NOT NULL,
    id_customer integer NOT NULL
);


ALTER TABLE public.tm_user_customer OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 36196)
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
-- TOC entry 3037 (class 0 OID 0)
-- Dependencies: 213
-- Name: tm_user_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tm_user_id_user_seq OWNED BY public.tm_user.id_user;


--
-- TOC entry 214 (class 1259 OID 36198)
-- Name: tm_user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tm_user_role (
    id_menu smallint NOT NULL,
    i_power smallint NOT NULL,
    i_level smallint NOT NULL
);


ALTER TABLE public.tm_user_role OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 36201)
-- Name: tr_alasan_retur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_alasan_retur (
    i_alasan integer NOT NULL,
    e_alasan character varying(80) NOT NULL
);


ALTER TABLE public.tr_alasan_retur OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 36204)
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
-- TOC entry 3038 (class 0 OID 0)
-- Dependencies: 216
-- Name: tr_alasan_retur_i_alasan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_alasan_retur_i_alasan_seq OWNED BY public.tr_alasan_retur.i_alasan;


--
-- TOC entry 217 (class 1259 OID 36206)
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
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_company OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 36210)
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
-- TOC entry 3039 (class 0 OID 0)
-- Dependencies: 218
-- Name: tr_company_i_company_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_company_i_company_seq OWNED BY public.tr_company.i_company;


--
-- TOC entry 219 (class 1259 OID 36212)
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
-- TOC entry 220 (class 1259 OID 36220)
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
-- TOC entry 3040 (class 0 OID 0)
-- Dependencies: 220
-- Name: tr_customer_id_customer_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_customer_id_customer_seq OWNED BY public.tr_customer.id_customer;


--
-- TOC entry 221 (class 1259 OID 36222)
-- Name: tr_customer_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_customer_item (
    id_item integer NOT NULL,
    id_customer integer NOT NULL,
    i_company integer NOT NULL,
    i_customer character varying(15),
    i_area character varying(2),
    n_diskon1 numeric(2,2),
    n_diskon2 numeric(2,2),
    n_diskon3 numeric(2,2),
    f_status boolean DEFAULT true
);


ALTER TABLE public.tr_customer_item OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 36226)
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
-- TOC entry 3041 (class 0 OID 0)
-- Dependencies: 222
-- Name: tr_customer_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_customer_item_id_item_seq OWNED BY public.tr_customer_item.id_item;


--
-- TOC entry 223 (class 1259 OID 36228)
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
-- TOC entry 224 (class 1259 OID 36234)
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
-- TOC entry 3042 (class 0 OID 0)
-- Dependencies: 224
-- Name: tr_level_i_level_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_level_i_level_seq OWNED BY public.tr_level.i_level;


--
-- TOC entry 225 (class 1259 OID 36236)
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
-- TOC entry 226 (class 1259 OID 36243)
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
    d_update timestamp without time zone
);


ALTER TABLE public.tr_product OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 36251)
-- Name: tr_type_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_type_customer (
    i_type integer NOT NULL,
    e_type character varying(80)
);


ALTER TABLE public.tr_type_customer OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 36254)
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
-- TOC entry 3043 (class 0 OID 0)
-- Dependencies: 228
-- Name: tr_type_customer_i_type_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_type_customer_i_type_seq OWNED BY public.tr_type_customer.i_type;


--
-- TOC entry 229 (class 1259 OID 36256)
-- Name: tr_user_power; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tr_user_power (
    i_power integer NOT NULL,
    e_power_name character varying(30) DEFAULT NULL::character varying
);


ALTER TABLE public.tr_user_power OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 36260)
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
-- TOC entry 3044 (class 0 OID 0)
-- Dependencies: 230
-- Name: tr_user_power_i_power_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tr_user_power_i_power_seq OWNED BY public.tr_user_power.i_power;


--
-- TOC entry 2789 (class 2604 OID 36262)
-- Name: tm_pembelian id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_id_document_seq'::regclass);


--
-- TOC entry 2790 (class 2604 OID 36263)
-- Name: tm_pembelian_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_item_id_item_seq'::regclass);


--
-- TOC entry 2794 (class 2604 OID 36264)
-- Name: tm_pembelian_retur id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_retur_id_document_seq'::regclass);


--
-- TOC entry 2795 (class 2604 OID 36265)
-- Name: tm_pembelian_retur_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_retur_item_id_item_seq'::regclass);


--
-- TOC entry 2798 (class 2604 OID 36266)
-- Name: tm_penjualan id_document; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan ALTER COLUMN id_document SET DEFAULT nextval('public.tm_penjualan_id_document_seq'::regclass);


--
-- TOC entry 2799 (class 2604 OID 36267)
-- Name: tm_penjualan_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_penjualan_item_id_item_seq'::regclass);


--
-- TOC entry 2804 (class 2604 OID 36268)
-- Name: tm_user id_user; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user ALTER COLUMN id_user SET DEFAULT nextval('public.tm_user_id_user_seq'::regclass);


--
-- TOC entry 2805 (class 2604 OID 36269)
-- Name: tr_alasan_retur i_alasan; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_alasan_retur ALTER COLUMN i_alasan SET DEFAULT nextval('public.tr_alasan_retur_i_alasan_seq'::regclass);


--
-- TOC entry 2807 (class 2604 OID 36270)
-- Name: tr_company i_company; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_company ALTER COLUMN i_company SET DEFAULT nextval('public.tr_company_i_company_seq'::regclass);


--
-- TOC entry 2810 (class 2604 OID 36271)
-- Name: tr_customer id_customer; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer ALTER COLUMN id_customer SET DEFAULT nextval('public.tr_customer_id_customer_seq'::regclass);


--
-- TOC entry 2812 (class 2604 OID 36272)
-- Name: tr_customer_item id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item ALTER COLUMN id_item SET DEFAULT nextval('public.tr_customer_item_id_item_seq'::regclass);


--
-- TOC entry 2816 (class 2604 OID 36273)
-- Name: tr_level i_level; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_level ALTER COLUMN i_level SET DEFAULT nextval('public.tr_level_i_level_seq'::regclass);


--
-- TOC entry 2823 (class 2604 OID 36274)
-- Name: tr_type_customer i_type; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_type_customer ALTER COLUMN i_type SET DEFAULT nextval('public.tr_type_customer_i_type_seq'::regclass);


--
-- TOC entry 2825 (class 2604 OID 36275)
-- Name: tr_user_power i_power; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_user_power ALTER COLUMN i_power SET DEFAULT nextval('public.tr_user_power_i_power_seq'::regclass);


--
-- TOC entry 2990 (class 0 OID 36115)
-- Dependencies: 196
-- Data for Name: dg_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-04 09:43:45.421172', 'Login');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-04 09:43:53.31196', 'Logout');
INSERT INTO public.dg_log VALUES (1, '::1', '2021-08-04 09:44:01.655144', 'Login');


--
-- TOC entry 2991 (class 0 OID 36122)
-- Dependencies: 197
-- Data for Name: tm_pembelian; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2993 (class 0 OID 36132)
-- Dependencies: 199
-- Data for Name: tm_pembelian_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2995 (class 0 OID 36140)
-- Dependencies: 201
-- Data for Name: tm_pembelian_retur; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2997 (class 0 OID 36151)
-- Dependencies: 203
-- Data for Name: tm_pembelian_retur_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2999 (class 0 OID 36156)
-- Dependencies: 205
-- Data for Name: tm_penjualan; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3001 (class 0 OID 36166)
-- Dependencies: 207
-- Data for Name: tm_penjualan_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3003 (class 0 OID 36174)
-- Dependencies: 209
-- Data for Name: tm_saldo_awal; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3004 (class 0 OID 36177)
-- Dependencies: 210
-- Data for Name: tm_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_sessions VALUES ('ahiladu3aaht887coggaii91r1f5kp7a', '::1', 1628045626, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MDQ1NjI2O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('i0u8i8ngbc3qkq155k2potfsrmnt2u6p', '::1', 1628046239, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MDQ2MjM5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');
INSERT INTO public.tm_sessions VALUES ('n2iebhksr2p5qb41utspk731undu5khj', '::1', 1628046426, 'X19jaV9sYXN0X3JlZ2VuZXJhdGV8aToxNjI4MDQ2MjM5O2lkX3VzZXJ8czoxOiIxIjtlX25hbWV8czoxMzoiQWRtaW5pc3RyYXRvciI7dXNlcm5hbWV8czo1OiJhZG1pbiI7aV9sZXZlbHxzOjE6IjEiO0Zfc3RhdHVzfHM6MToidCI7Rl9hbGxjdXN0b21lcnxzOjE6ImYiO2NvbG9yfHM6NToic2xhdGUiOw==');


--
-- TOC entry 3005 (class 0 OID 36185)
-- Dependencies: 211
-- Data for Name: tm_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user VALUES (1, 'admin', 'bmp2UkEvZndvUEZ4ek1VTndQRS9EZz09', 'Administrator', 1, 1, true, false);


--
-- TOC entry 3006 (class 0 OID 36193)
-- Dependencies: 212
-- Data for Name: tm_user_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3008 (class 0 OID 36198)
-- Dependencies: 214
-- Data for Name: tm_user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tm_user_role VALUES (101, 1, 1);
INSERT INTO public.tm_user_role VALUES (101, 2, 1);


--
-- TOC entry 3009 (class 0 OID 36201)
-- Dependencies: 215
-- Data for Name: tr_alasan_retur; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3011 (class 0 OID 36206)
-- Dependencies: 217
-- Data for Name: tr_company; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_company VALUES (1, 'All Company', NULL, NULL, NULL, NULL, NULL, NULL, true);


--
-- TOC entry 3013 (class 0 OID 36212)
-- Dependencies: 219
-- Data for Name: tr_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3015 (class 0 OID 36222)
-- Dependencies: 221
-- Data for Name: tr_customer_item; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3017 (class 0 OID 36228)
-- Dependencies: 223
-- Data for Name: tr_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_level VALUES (1, 'Super Admin', true, 'Setting Aplikasi');


--
-- TOC entry 3019 (class 0 OID 36236)
-- Dependencies: 225
-- Data for Name: tr_menu; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_menu VALUES (101, 'Master', 0, 1, '#', '
icon-stack2', NULL);


--
-- TOC entry 3020 (class 0 OID 36243)
-- Dependencies: 226
-- Data for Name: tr_product; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3021 (class 0 OID 36251)
-- Dependencies: 227
-- Data for Name: tr_type_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3023 (class 0 OID 36256)
-- Dependencies: 229
-- Data for Name: tr_user_power; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tr_user_power VALUES (1, 'Create');
INSERT INTO public.tr_user_power VALUES (2, 'Read');
INSERT INTO public.tr_user_power VALUES (3, 'Update');
INSERT INTO public.tr_user_power VALUES (4, 'Delete');


--
-- TOC entry 3045 (class 0 OID 0)
-- Dependencies: 198
-- Name: tm_pembelian_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_id_document_seq', 1, false);


--
-- TOC entry 3046 (class 0 OID 0)
-- Dependencies: 200
-- Name: tm_pembelian_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_item_id_item_seq', 1, false);


--
-- TOC entry 3047 (class 0 OID 0)
-- Dependencies: 202
-- Name: tm_pembelian_retur_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_retur_id_document_seq', 1, false);


--
-- TOC entry 3048 (class 0 OID 0)
-- Dependencies: 204
-- Name: tm_pembelian_retur_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_pembelian_retur_item_id_item_seq', 1, false);


--
-- TOC entry 3049 (class 0 OID 0)
-- Dependencies: 206
-- Name: tm_penjualan_id_document_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_penjualan_id_document_seq', 1, false);


--
-- TOC entry 3050 (class 0 OID 0)
-- Dependencies: 208
-- Name: tm_penjualan_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_penjualan_item_id_item_seq', 1, false);


--
-- TOC entry 3051 (class 0 OID 0)
-- Dependencies: 213
-- Name: tm_user_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tm_user_id_user_seq', 1, true);


--
-- TOC entry 3052 (class 0 OID 0)
-- Dependencies: 216
-- Name: tr_alasan_retur_i_alasan_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_alasan_retur_i_alasan_seq', 1, false);


--
-- TOC entry 3053 (class 0 OID 0)
-- Dependencies: 218
-- Name: tr_company_i_company_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_company_i_company_seq', 1, true);


--
-- TOC entry 3054 (class 0 OID 0)
-- Dependencies: 220
-- Name: tr_customer_id_customer_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_customer_id_customer_seq', 1, false);


--
-- TOC entry 3055 (class 0 OID 0)
-- Dependencies: 222
-- Name: tr_customer_item_id_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_customer_item_id_item_seq', 1, false);


--
-- TOC entry 3056 (class 0 OID 0)
-- Dependencies: 224
-- Name: tr_level_i_level_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_level_i_level_seq', 1, true);


--
-- TOC entry 3057 (class 0 OID 0)
-- Dependencies: 228
-- Name: tr_type_customer_i_type_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_type_customer_i_type_seq', 1, false);


--
-- TOC entry 3058 (class 0 OID 0)
-- Dependencies: 230
-- Name: tr_user_power_i_power_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tr_user_power_i_power_seq', 4, true);


--
-- TOC entry 2847 (class 2606 OID 36277)
-- Name: tr_alasan_retur pk_alasan_retur; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_alasan_retur
    ADD CONSTRAINT pk_alasan_retur PRIMARY KEY (i_alasan);


--
-- TOC entry 2849 (class 2606 OID 36279)
-- Name: tr_company pk_company; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_company
    ADD CONSTRAINT pk_company PRIMARY KEY (i_company);


--
-- TOC entry 2851 (class 2606 OID 36281)
-- Name: tr_customer pk_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT pk_customer PRIMARY KEY (id_customer);


--
-- TOC entry 2853 (class 2606 OID 36283)
-- Name: tr_customer_item pk_customer_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT pk_customer_item PRIMARY KEY (id_item);


--
-- TOC entry 2827 (class 2606 OID 36285)
-- Name: dg_log pk_log; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dg_log
    ADD CONSTRAINT pk_log PRIMARY KEY (id_user, ip_address, waktu);


--
-- TOC entry 2829 (class 2606 OID 36287)
-- Name: tm_pembelian pk_tm_pembelian; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT pk_tm_pembelian PRIMARY KEY (id_document);


--
-- TOC entry 2831 (class 2606 OID 36289)
-- Name: tm_pembelian_item pk_tm_pembelian_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT pk_tm_pembelian_item PRIMARY KEY (id_item);


--
-- TOC entry 2833 (class 2606 OID 36291)
-- Name: tm_pembelian_retur pk_tm_pembelian_retur; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur
    ADD CONSTRAINT pk_tm_pembelian_retur PRIMARY KEY (id_document);


--
-- TOC entry 2835 (class 2606 OID 36293)
-- Name: tm_pembelian_retur_item pk_tm_pembelian_retur_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT pk_tm_pembelian_retur_item PRIMARY KEY (id_item);


--
-- TOC entry 2837 (class 2606 OID 36295)
-- Name: tm_penjualan pk_tm_penjualan; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan
    ADD CONSTRAINT pk_tm_penjualan PRIMARY KEY (id_document);


--
-- TOC entry 2839 (class 2606 OID 36297)
-- Name: tm_penjualan_item pk_tm_penjualan_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT pk_tm_penjualan_item PRIMARY KEY (id_item);


--
-- TOC entry 2841 (class 2606 OID 36299)
-- Name: tm_saldo_awal pk_tm_saldo_awal; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT pk_tm_saldo_awal PRIMARY KEY (id_customer, i_periode, i_company, i_product);


--
-- TOC entry 2843 (class 2606 OID 36301)
-- Name: tm_user pk_tm_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user
    ADD CONSTRAINT pk_tm_user PRIMARY KEY (id_user);


--
-- TOC entry 2845 (class 2606 OID 36303)
-- Name: tm_user_customer pk_tm_user_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT pk_tm_user_customer PRIMARY KEY (id_user, id_customer);


--
-- TOC entry 2855 (class 2606 OID 36305)
-- Name: tr_product pk_tr_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT pk_tr_product PRIMARY KEY (i_company, i_product);


--
-- TOC entry 2857 (class 2606 OID 36307)
-- Name: tr_type_customer pk_type_customer; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_type_customer
    ADD CONSTRAINT pk_type_customer PRIMARY KEY (i_type);


--
-- TOC entry 2865 (class 2606 OID 36308)
-- Name: tr_customer fk_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT fk_customer FOREIGN KEY (i_type) REFERENCES public.tr_type_customer(i_type);


--
-- TOC entry 2866 (class 2606 OID 36313)
-- Name: tr_customer_item fk_customer_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);


--
-- TOC entry 2867 (class 2606 OID 36318)
-- Name: tr_customer_item fk_customer_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item2 FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);


--
-- TOC entry 2858 (class 2606 OID 36323)
-- Name: tm_pembelian fk_tm_pembelian; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian FOREIGN KEY (id_item) REFERENCES public.tr_customer_item(id_item);


--
-- TOC entry 2859 (class 2606 OID 36328)
-- Name: tm_pembelian_item fk_tm_pembelian_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian(id_document);


--
-- TOC entry 2860 (class 2606 OID 36333)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian_retur(id_document);


--
-- TOC entry 2861 (class 2606 OID 36338)
-- Name: tm_pembelian_retur_item fk_tm_pembelian_retur_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item2 FOREIGN KEY (i_alasan) REFERENCES public.tr_alasan_retur(i_alasan);


--
-- TOC entry 2862 (class 2606 OID 36343)
-- Name: tm_penjualan_item fk_tm_penjualan_item2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item2 FOREIGN KEY (id_document) REFERENCES public.tm_penjualan(id_document);


--
-- TOC entry 2863 (class 2606 OID 36348)
-- Name: tm_user_customer fk_tm_user_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user);


--
-- TOC entry 2864 (class 2606 OID 36353)
-- Name: tm_user_customer fk_tm_user_customer2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer2 FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);


--
-- TOC entry 2868 (class 2606 OID 36358)
-- Name: tr_product fk_tr_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT fk_tr_product FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);


-- Completed on 2021-08-04 10:14:04

--
-- PostgreSQL database dump complete
--

