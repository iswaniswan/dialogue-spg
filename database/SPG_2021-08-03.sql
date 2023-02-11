PGDMP     4                    y            spg    10.17    12.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    26447    spg    DATABASE     �   CREATE DATABASE spg WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_Indonesia.1252' LC_CTYPE = 'English_Indonesia.1252';
    DROP DATABASE spg;
                postgres    false            �            1259    26497    dg_log    TABLE     �   CREATE TABLE public.dg_log (
    id_user integer NOT NULL,
    ip_address character varying(16) NOT NULL,
    waktu timestamp without time zone DEFAULT now() NOT NULL,
    activity text
);
    DROP TABLE public.dg_log;
       public            postgres    false            �            1259    26664    tm_pembelian    TABLE     -  CREATE TABLE public.tm_pembelian (
    id_document integer NOT NULL,
    id_item integer,
    i_document character varying(50),
    d_receive date,
    e_remark text,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);
     DROP TABLE public.tm_pembelian;
       public            postgres    false            �            1259    26662    tm_pembelian_id_document_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_pembelian_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.tm_pembelian_id_document_seq;
       public          postgres    false    219            �           0    0    tm_pembelian_id_document_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.tm_pembelian_id_document_seq OWNED BY public.tm_pembelian.id_document;
          public          postgres    false    218            �            1259    26682    tm_pembelian_item    TABLE       CREATE TABLE public.tm_pembelian_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    v_price numeric,
    e_remark text
);
 %   DROP TABLE public.tm_pembelian_item;
       public            postgres    false            �            1259    26680    tm_pembelian_item_id_item_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_pembelian_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.tm_pembelian_item_id_item_seq;
       public          postgres    false    221            �           0    0    tm_pembelian_item_id_item_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.tm_pembelian_item_id_item_seq OWNED BY public.tm_pembelian_item.id_item;
          public          postgres    false    220            �            1259    26698    tm_pembelian_retur    TABLE     B  CREATE TABLE public.tm_pembelian_retur (
    id_document integer NOT NULL,
    i_document character varying(50),
    d_retur date,
    e_remark text,
    f_transfer boolean DEFAULT false,
    f_status boolean DEFAULT true,
    d_entry timestamp without time zone DEFAULT now(),
    d_update timestamp without time zone
);
 &   DROP TABLE public.tm_pembelian_retur;
       public            postgres    false            �            1259    26696 "   tm_pembelian_retur_id_document_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_pembelian_retur_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.tm_pembelian_retur_id_document_seq;
       public          postgres    false    223            �           0    0 "   tm_pembelian_retur_id_document_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.tm_pembelian_retur_id_document_seq OWNED BY public.tm_pembelian_retur.id_document;
          public          postgres    false    222            �            1259    26712    tm_pembelian_retur_item    TABLE       CREATE TABLE public.tm_pembelian_retur_item (
    id_item integer NOT NULL,
    id_document integer,
    i_company integer,
    i_product character varying(15),
    e_product_name character varying(150),
    n_qty integer,
    i_alasan integer,
    i_document character varying(50)
);
 +   DROP TABLE public.tm_pembelian_retur_item;
       public            postgres    false            �            1259    26710 #   tm_pembelian_retur_item_id_item_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_pembelian_retur_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.tm_pembelian_retur_item_id_item_seq;
       public          postgres    false    225            �           0    0 #   tm_pembelian_retur_item_id_item_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.tm_pembelian_retur_item_id_item_seq OWNED BY public.tm_pembelian_retur_item.id_item;
          public          postgres    false    224            �            1259    26730    tm_penjualan    TABLE       CREATE TABLE public.tm_penjualan (
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
     DROP TABLE public.tm_penjualan;
       public            postgres    false            �            1259    26728    tm_penjualan_id_document_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_penjualan_id_document_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.tm_penjualan_id_document_seq;
       public          postgres    false    227            �           0    0    tm_penjualan_id_document_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.tm_penjualan_id_document_seq OWNED BY public.tm_penjualan.id_document;
          public          postgres    false    226            �            1259    26743    tm_penjualan_item    TABLE       CREATE TABLE public.tm_penjualan_item (
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
 %   DROP TABLE public.tm_penjualan_item;
       public            postgres    false            �            1259    26741    tm_penjualan_item_id_item_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_penjualan_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.tm_penjualan_item_id_item_seq;
       public          postgres    false    229            �           0    0    tm_penjualan_item_id_item_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.tm_penjualan_item_id_item_seq OWNED BY public.tm_penjualan_item.id_item;
          public          postgres    false    228            �            1259    26758    tm_saldo_awal    TABLE     �   CREATE TABLE public.tm_saldo_awal (
    id_customer integer NOT NULL,
    i_periode character varying(6) NOT NULL,
    i_company integer NOT NULL,
    i_product character varying(15) NOT NULL,
    n_saldo integer
);
 !   DROP TABLE public.tm_saldo_awal;
       public            postgres    false            �            1259    26448    tm_sessions    TABLE     �   CREATE TABLE public.tm_sessions (
    id character varying(128) NOT NULL,
    ip_address character varying(45) NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    data text DEFAULT ''::text NOT NULL
);
    DROP TABLE public.tm_sessions;
       public            postgres    false            �            1259    26596    tm_user    TABLE     #  CREATE TABLE public.tm_user (
    id_user integer NOT NULL,
    username character varying(255),
    password character varying(255),
    e_nama character varying(255),
    i_level integer,
    i_company integer,
    f_status boolean DEFAULT true,
    f_allcustomer boolean DEFAULT false
);
    DROP TABLE public.tm_user;
       public            postgres    false            �            1259    26617    tm_user_customer    TABLE     i   CREATE TABLE public.tm_user_customer (
    id_user integer NOT NULL,
    id_customer integer NOT NULL
);
 $   DROP TABLE public.tm_user_customer;
       public            postgres    false            �            1259    26594    tm_user_id_user_seq    SEQUENCE     �   CREATE SEQUENCE public.tm_user_id_user_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.tm_user_id_user_seq;
       public          postgres    false    213            �           0    0    tm_user_id_user_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.tm_user_id_user_seq OWNED BY public.tm_user.id_user;
          public          postgres    false    212            �            1259    26466    tm_user_role    TABLE     �   CREATE TABLE public.tm_user_role (
    id_menu smallint NOT NULL,
    i_power smallint NOT NULL,
    i_level smallint NOT NULL
);
     DROP TABLE public.tm_user_role;
       public            postgres    false            �            1259    26656    tr_alasan_retur    TABLE     t   CREATE TABLE public.tr_alasan_retur (
    i_alasan integer NOT NULL,
    e_alasan character varying(80) NOT NULL
);
 #   DROP TABLE public.tr_alasan_retur;
       public            postgres    false            �            1259    26654    tr_alasan_retur_i_alasan_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_alasan_retur_i_alasan_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.tr_alasan_retur_i_alasan_seq;
       public          postgres    false    217            �           0    0    tr_alasan_retur_i_alasan_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.tr_alasan_retur_i_alasan_seq OWNED BY public.tr_alasan_retur.i_alasan;
          public          postgres    false    216            �            1259    26512 
   tr_company    TABLE     j  CREATE TABLE public.tr_company (
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
    DROP TABLE public.tr_company;
       public            postgres    false            �            1259    26510    tr_company_i_company_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_company_i_company_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.tr_company_i_company_seq;
       public          postgres    false    205            �           0    0    tr_company_i_company_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.tr_company_i_company_seq OWNED BY public.tr_company.i_company;
          public          postgres    false    204            �            1259    26553    tr_customer    TABLE     �  CREATE TABLE public.tr_customer (
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
    DROP TABLE public.tr_customer;
       public            postgres    false            �            1259    26551    tr_customer_id_customer_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_customer_id_customer_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.tr_customer_id_customer_seq;
       public          postgres    false    209            �           0    0    tr_customer_id_customer_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.tr_customer_id_customer_seq OWNED BY public.tr_customer.id_customer;
          public          postgres    false    208            �            1259    26571    tr_customer_item    TABLE     G  CREATE TABLE public.tr_customer_item (
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
 $   DROP TABLE public.tr_customer_item;
       public            postgres    false            �            1259    26569    tr_customer_item_id_item_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_customer_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.tr_customer_item_id_item_seq;
       public          postgres    false    211            �           0    0    tr_customer_item_id_item_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.tr_customer_item_id_item_seq OWNED BY public.tr_customer_item.id_item;
          public          postgres    false    210            �            1259    26473    tr_level    TABLE     �   CREATE TABLE public.tr_level (
    i_level integer NOT NULL,
    e_level_name character varying(20) DEFAULT NULL::character varying,
    f_status boolean DEFAULT true,
    e_deskripsi character varying(100) DEFAULT NULL::character varying
);
    DROP TABLE public.tr_level;
       public            postgres    false            �            1259    26479    tr_level_i_level_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_level_i_level_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.tr_level_i_level_seq;
       public          postgres    false    198            �           0    0    tr_level_i_level_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.tr_level_i_level_seq OWNED BY public.tr_level.i_level;
          public          postgres    false    199            �            1259    26481    tr_menu    TABLE     x  CREATE TABLE public.tr_menu (
    id_menu integer NOT NULL,
    e_menu character varying(30) DEFAULT NULL::character varying,
    i_parent smallint,
    n_urut smallint,
    e_folder character varying(30) DEFAULT NULL::character varying,
    icon character varying(30) DEFAULT NULL::character varying,
    e_sub_folder character varying(30) DEFAULT NULL::character varying
);
    DROP TABLE public.tr_menu;
       public            postgres    false            �            1259    26639 
   tr_product    TABLE     w  CREATE TABLE public.tr_product (
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
    DROP TABLE public.tr_product;
       public            postgres    false            �            1259    26521    tr_type_customer    TABLE     h   CREATE TABLE public.tr_type_customer (
    i_type integer NOT NULL,
    e_type character varying(80)
);
 $   DROP TABLE public.tr_type_customer;
       public            postgres    false            �            1259    26519    tr_type_customer_i_type_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_type_customer_i_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.tr_type_customer_i_type_seq;
       public          postgres    false    207            �           0    0    tr_type_customer_i_type_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.tr_type_customer_i_type_seq OWNED BY public.tr_type_customer.i_type;
          public          postgres    false    206            �            1259    26488    tr_user_power    TABLE     �   CREATE TABLE public.tr_user_power (
    i_power integer NOT NULL,
    e_power_name character varying(30) DEFAULT NULL::character varying
);
 !   DROP TABLE public.tr_user_power;
       public            postgres    false            �            1259    26492    tr_user_power_i_power_seq    SEQUENCE     �   CREATE SEQUENCE public.tr_user_power_i_power_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.tr_user_power_i_power_seq;
       public          postgres    false    201            �           0    0    tr_user_power_i_power_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.tr_user_power_i_power_seq OWNED BY public.tr_user_power.i_power;
          public          postgres    false    202            �
           2604    26667    tm_pembelian id_document    DEFAULT     �   ALTER TABLE ONLY public.tm_pembelian ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_id_document_seq'::regclass);
 G   ALTER TABLE public.tm_pembelian ALTER COLUMN id_document DROP DEFAULT;
       public          postgres    false    219    218    219                        2604    26685    tm_pembelian_item id_item    DEFAULT     �   ALTER TABLE ONLY public.tm_pembelian_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_item_id_item_seq'::regclass);
 H   ALTER TABLE public.tm_pembelian_item ALTER COLUMN id_item DROP DEFAULT;
       public          postgres    false    221    220    221                       2604    26701    tm_pembelian_retur id_document    DEFAULT     �   ALTER TABLE ONLY public.tm_pembelian_retur ALTER COLUMN id_document SET DEFAULT nextval('public.tm_pembelian_retur_id_document_seq'::regclass);
 M   ALTER TABLE public.tm_pembelian_retur ALTER COLUMN id_document DROP DEFAULT;
       public          postgres    false    222    223    223                       2604    26715    tm_pembelian_retur_item id_item    DEFAULT     �   ALTER TABLE ONLY public.tm_pembelian_retur_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_pembelian_retur_item_id_item_seq'::regclass);
 N   ALTER TABLE public.tm_pembelian_retur_item ALTER COLUMN id_item DROP DEFAULT;
       public          postgres    false    224    225    225                       2604    26733    tm_penjualan id_document    DEFAULT     �   ALTER TABLE ONLY public.tm_penjualan ALTER COLUMN id_document SET DEFAULT nextval('public.tm_penjualan_id_document_seq'::regclass);
 G   ALTER TABLE public.tm_penjualan ALTER COLUMN id_document DROP DEFAULT;
       public          postgres    false    226    227    227            	           2604    26746    tm_penjualan_item id_item    DEFAULT     �   ALTER TABLE ONLY public.tm_penjualan_item ALTER COLUMN id_item SET DEFAULT nextval('public.tm_penjualan_item_id_item_seq'::regclass);
 H   ALTER TABLE public.tm_penjualan_item ALTER COLUMN id_item DROP DEFAULT;
       public          postgres    false    229    228    229            �
           2604    26599    tm_user id_user    DEFAULT     r   ALTER TABLE ONLY public.tm_user ALTER COLUMN id_user SET DEFAULT nextval('public.tm_user_id_user_seq'::regclass);
 >   ALTER TABLE public.tm_user ALTER COLUMN id_user DROP DEFAULT;
       public          postgres    false    212    213    213            �
           2604    26659    tr_alasan_retur i_alasan    DEFAULT     �   ALTER TABLE ONLY public.tr_alasan_retur ALTER COLUMN i_alasan SET DEFAULT nextval('public.tr_alasan_retur_i_alasan_seq'::regclass);
 G   ALTER TABLE public.tr_alasan_retur ALTER COLUMN i_alasan DROP DEFAULT;
       public          postgres    false    217    216    217            �
           2604    26515    tr_company i_company    DEFAULT     |   ALTER TABLE ONLY public.tr_company ALTER COLUMN i_company SET DEFAULT nextval('public.tr_company_i_company_seq'::regclass);
 C   ALTER TABLE public.tr_company ALTER COLUMN i_company DROP DEFAULT;
       public          postgres    false    204    205    205            �
           2604    26556    tr_customer id_customer    DEFAULT     �   ALTER TABLE ONLY public.tr_customer ALTER COLUMN id_customer SET DEFAULT nextval('public.tr_customer_id_customer_seq'::regclass);
 F   ALTER TABLE public.tr_customer ALTER COLUMN id_customer DROP DEFAULT;
       public          postgres    false    208    209    209            �
           2604    26574    tr_customer_item id_item    DEFAULT     �   ALTER TABLE ONLY public.tr_customer_item ALTER COLUMN id_item SET DEFAULT nextval('public.tr_customer_item_id_item_seq'::regclass);
 G   ALTER TABLE public.tr_customer_item ALTER COLUMN id_item DROP DEFAULT;
       public          postgres    false    210    211    211            �
           2604    26495    tr_level i_level    DEFAULT     t   ALTER TABLE ONLY public.tr_level ALTER COLUMN i_level SET DEFAULT nextval('public.tr_level_i_level_seq'::regclass);
 ?   ALTER TABLE public.tr_level ALTER COLUMN i_level DROP DEFAULT;
       public          postgres    false    199    198            �
           2604    26524    tr_type_customer i_type    DEFAULT     �   ALTER TABLE ONLY public.tr_type_customer ALTER COLUMN i_type SET DEFAULT nextval('public.tr_type_customer_i_type_seq'::regclass);
 F   ALTER TABLE public.tr_type_customer ALTER COLUMN i_type DROP DEFAULT;
       public          postgres    false    206    207    207            �
           2604    26496    tr_user_power i_power    DEFAULT     ~   ALTER TABLE ONLY public.tr_user_power ALTER COLUMN i_power SET DEFAULT nextval('public.tr_user_power_i_power_seq'::regclass);
 D   ALTER TABLE public.tr_user_power ALTER COLUMN i_power DROP DEFAULT;
       public          postgres    false    202    201            �          0    26497    dg_log 
   TABLE DATA           F   COPY public.dg_log (id_user, ip_address, waktu, activity) FROM stdin;
    public          postgres    false    203   ��       �          0    26664    tm_pembelian 
   TABLE DATA           z   COPY public.tm_pembelian (id_document, id_item, i_document, d_receive, e_remark, f_status, d_entry, d_update) FROM stdin;
    public          postgres    false    219   ��       �          0    26682    tm_pembelian_item 
   TABLE DATA           �   COPY public.tm_pembelian_item (id_item, id_document, i_company, i_product, e_product_name, n_qty, v_price, e_remark) FROM stdin;
    public          postgres    false    221   ҥ       �          0    26698    tm_pembelian_retur 
   TABLE DATA           �   COPY public.tm_pembelian_retur (id_document, i_document, d_retur, e_remark, f_transfer, f_status, d_entry, d_update) FROM stdin;
    public          postgres    false    223   �       �          0    26712    tm_pembelian_retur_item 
   TABLE DATA           �   COPY public.tm_pembelian_retur_item (id_item, id_document, i_company, i_product, e_product_name, n_qty, i_alasan, i_document) FROM stdin;
    public          postgres    false    225   �       �          0    26730    tm_penjualan 
   TABLE DATA           �   COPY public.tm_penjualan (id_document, i_document, d_document, e_customer_sell_name, e_customer_sell_address, v_gross, n_diskon, v_diskon, v_diskon_total, v_ppn, v_netto, v_bayar, e_remark, f_status, d_entry, d_update) FROM stdin;
    public          postgres    false    227   )�       �          0    26743    tm_penjualan_item 
   TABLE DATA           �   COPY public.tm_penjualan_item (id_item, id_document, i_company, i_product, e_product_name, n_qty, v_price, v_diskon, e_remark) FROM stdin;
    public          postgres    false    229   F�       �          0    26758    tm_saldo_awal 
   TABLE DATA           ^   COPY public.tm_saldo_awal (id_customer, i_periode, i_company, i_product, n_saldo) FROM stdin;
    public          postgres    false    230   c�       �          0    26448    tm_sessions 
   TABLE DATA           H   COPY public.tm_sessions (id, ip_address, "timestamp", data) FROM stdin;
    public          postgres    false    196   ��       �          0    26596    tm_user 
   TABLE DATA           s   COPY public.tm_user (id_user, username, password, e_nama, i_level, i_company, f_status, f_allcustomer) FROM stdin;
    public          postgres    false    213   ��       �          0    26617    tm_user_customer 
   TABLE DATA           @   COPY public.tm_user_customer (id_user, id_customer) FROM stdin;
    public          postgres    false    214   ��       �          0    26466    tm_user_role 
   TABLE DATA           A   COPY public.tm_user_role (id_menu, i_power, i_level) FROM stdin;
    public          postgres    false    197   צ       �          0    26656    tr_alasan_retur 
   TABLE DATA           =   COPY public.tr_alasan_retur (i_alasan, e_alasan) FROM stdin;
    public          postgres    false    217   ��       �          0    26512 
   tr_company 
   TABLE DATA           �   COPY public.tr_company (i_company, e_company_name, db_user, db_password, db_address, db_port, db_schema, db_name, f_status) FROM stdin;
    public          postgres    false    205   �       �          0    26553    tr_customer 
   TABLE DATA           �   COPY public.tr_customer (id_customer, e_customer_name, e_customer_address, i_type, e_customer_owner, e_customer_phone, f_pkp, e_npwp_name, e_npwp_address, f_status) FROM stdin;
    public          postgres    false    209   .�       �          0    26571    tr_customer_item 
   TABLE DATA           �   COPY public.tr_customer_item (id_item, id_customer, i_company, i_customer, i_area, n_diskon1, n_diskon2, n_diskon3, f_status) FROM stdin;
    public          postgres    false    211   K�       �          0    26473    tr_level 
   TABLE DATA           P   COPY public.tr_level (i_level, e_level_name, f_status, e_deskripsi) FROM stdin;
    public          postgres    false    198   h�       �          0    26481    tr_menu 
   TABLE DATA           b   COPY public.tr_menu (id_menu, e_menu, i_parent, n_urut, e_folder, icon, e_sub_folder) FROM stdin;
    public          postgres    false    200   ��       �          0    26639 
   tr_product 
   TABLE DATA           �   COPY public.tr_product (i_company, i_product, e_product_name, e_brand, v_price_beli, v_price_jual, f_status, d_entry, d_update) FROM stdin;
    public          postgres    false    215   ��       �          0    26521    tr_type_customer 
   TABLE DATA           :   COPY public.tr_type_customer (i_type, e_type) FROM stdin;
    public          postgres    false    207   ��       �          0    26488    tr_user_power 
   TABLE DATA           >   COPY public.tr_user_power (i_power, e_power_name) FROM stdin;
    public          postgres    false    201   ܧ       �           0    0    tm_pembelian_id_document_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tm_pembelian_id_document_seq', 1, false);
          public          postgres    false    218            �           0    0    tm_pembelian_item_id_item_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.tm_pembelian_item_id_item_seq', 1, false);
          public          postgres    false    220            �           0    0 "   tm_pembelian_retur_id_document_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.tm_pembelian_retur_id_document_seq', 1, false);
          public          postgres    false    222            �           0    0 #   tm_pembelian_retur_item_id_item_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.tm_pembelian_retur_item_id_item_seq', 1, false);
          public          postgres    false    224            �           0    0    tm_penjualan_id_document_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tm_penjualan_id_document_seq', 1, false);
          public          postgres    false    226            �           0    0    tm_penjualan_item_id_item_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.tm_penjualan_item_id_item_seq', 1, false);
          public          postgres    false    228            �           0    0    tm_user_id_user_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.tm_user_id_user_seq', 1, false);
          public          postgres    false    212            �           0    0    tr_alasan_retur_i_alasan_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tr_alasan_retur_i_alasan_seq', 1, false);
          public          postgres    false    216            �           0    0    tr_company_i_company_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.tr_company_i_company_seq', 1, false);
          public          postgres    false    204            �           0    0    tr_customer_id_customer_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.tr_customer_id_customer_seq', 1, false);
          public          postgres    false    208            �           0    0    tr_customer_item_id_item_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.tr_customer_item_id_item_seq', 1, false);
          public          postgres    false    210            �           0    0    tr_level_i_level_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.tr_level_i_level_seq', 1, false);
          public          postgres    false    199            �           0    0    tr_type_customer_i_type_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.tr_type_customer_i_type_seq', 1, false);
          public          postgres    false    206            �           0    0    tr_user_power_i_power_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.tr_user_power_i_power_seq', 1, false);
          public          postgres    false    202                       2606    26661    tr_alasan_retur pk_alasan_retur 
   CONSTRAINT     c   ALTER TABLE ONLY public.tr_alasan_retur
    ADD CONSTRAINT pk_alasan_retur PRIMARY KEY (i_alasan);
 I   ALTER TABLE ONLY public.tr_alasan_retur DROP CONSTRAINT pk_alasan_retur;
       public            postgres    false    217                       2606    26518    tr_company pk_company 
   CONSTRAINT     Z   ALTER TABLE ONLY public.tr_company
    ADD CONSTRAINT pk_company PRIMARY KEY (i_company);
 ?   ALTER TABLE ONLY public.tr_company DROP CONSTRAINT pk_company;
       public            postgres    false    205                       2606    26563    tr_customer pk_customer 
   CONSTRAINT     ^   ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT pk_customer PRIMARY KEY (id_customer);
 A   ALTER TABLE ONLY public.tr_customer DROP CONSTRAINT pk_customer;
       public            postgres    false    209                       2606    26577 !   tr_customer_item pk_customer_item 
   CONSTRAINT     d   ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT pk_customer_item PRIMARY KEY (id_item);
 K   ALTER TABLE ONLY public.tr_customer_item DROP CONSTRAINT pk_customer_item;
       public            postgres    false    211                       2606    26505    dg_log pk_log 
   CONSTRAINT     c   ALTER TABLE ONLY public.dg_log
    ADD CONSTRAINT pk_log PRIMARY KEY (id_user, ip_address, waktu);
 7   ALTER TABLE ONLY public.dg_log DROP CONSTRAINT pk_log;
       public            postgres    false    203    203    203                       2606    26674    tm_pembelian pk_tm_pembelian 
   CONSTRAINT     c   ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT pk_tm_pembelian PRIMARY KEY (id_document);
 F   ALTER TABLE ONLY public.tm_pembelian DROP CONSTRAINT pk_tm_pembelian;
       public            postgres    false    219                       2606    26690 &   tm_pembelian_item pk_tm_pembelian_item 
   CONSTRAINT     i   ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT pk_tm_pembelian_item PRIMARY KEY (id_item);
 P   ALTER TABLE ONLY public.tm_pembelian_item DROP CONSTRAINT pk_tm_pembelian_item;
       public            postgres    false    221            !           2606    26709 (   tm_pembelian_retur pk_tm_pembelian_retur 
   CONSTRAINT     o   ALTER TABLE ONLY public.tm_pembelian_retur
    ADD CONSTRAINT pk_tm_pembelian_retur PRIMARY KEY (id_document);
 R   ALTER TABLE ONLY public.tm_pembelian_retur DROP CONSTRAINT pk_tm_pembelian_retur;
       public            postgres    false    223            #           2606    26717 2   tm_pembelian_retur_item pk_tm_pembelian_retur_item 
   CONSTRAINT     u   ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT pk_tm_pembelian_retur_item PRIMARY KEY (id_item);
 \   ALTER TABLE ONLY public.tm_pembelian_retur_item DROP CONSTRAINT pk_tm_pembelian_retur_item;
       public            postgres    false    225            %           2606    26740    tm_penjualan pk_tm_penjualan 
   CONSTRAINT     c   ALTER TABLE ONLY public.tm_penjualan
    ADD CONSTRAINT pk_tm_penjualan PRIMARY KEY (id_document);
 F   ALTER TABLE ONLY public.tm_penjualan DROP CONSTRAINT pk_tm_penjualan;
       public            postgres    false    227            '           2606    26751 &   tm_penjualan_item pk_tm_penjualan_item 
   CONSTRAINT     i   ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT pk_tm_penjualan_item PRIMARY KEY (id_item);
 P   ALTER TABLE ONLY public.tm_penjualan_item DROP CONSTRAINT pk_tm_penjualan_item;
       public            postgres    false    229            )           2606    26762    tm_saldo_awal pk_tm_saldo_awal 
   CONSTRAINT     �   ALTER TABLE ONLY public.tm_saldo_awal
    ADD CONSTRAINT pk_tm_saldo_awal PRIMARY KEY (id_customer, i_periode, i_company, i_product);
 H   ALTER TABLE ONLY public.tm_saldo_awal DROP CONSTRAINT pk_tm_saldo_awal;
       public            postgres    false    230    230    230    230                       2606    26606    tm_user pk_tm_user 
   CONSTRAINT     U   ALTER TABLE ONLY public.tm_user
    ADD CONSTRAINT pk_tm_user PRIMARY KEY (id_user);
 <   ALTER TABLE ONLY public.tm_user DROP CONSTRAINT pk_tm_user;
       public            postgres    false    213                       2606    26621 $   tm_user_customer pk_tm_user_customer 
   CONSTRAINT     t   ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT pk_tm_user_customer PRIMARY KEY (id_user, id_customer);
 N   ALTER TABLE ONLY public.tm_user_customer DROP CONSTRAINT pk_tm_user_customer;
       public            postgres    false    214    214                       2606    26648    tr_product pk_tr_product 
   CONSTRAINT     h   ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT pk_tr_product PRIMARY KEY (i_company, i_product);
 B   ALTER TABLE ONLY public.tr_product DROP CONSTRAINT pk_tr_product;
       public            postgres    false    215    215                       2606    26526 !   tr_type_customer pk_type_customer 
   CONSTRAINT     c   ALTER TABLE ONLY public.tr_type_customer
    ADD CONSTRAINT pk_type_customer PRIMARY KEY (i_type);
 K   ALTER TABLE ONLY public.tr_type_customer DROP CONSTRAINT pk_type_customer;
       public            postgres    false    207            *           2606    26564    tr_customer fk_customer    FK CONSTRAINT     �   ALTER TABLE ONLY public.tr_customer
    ADD CONSTRAINT fk_customer FOREIGN KEY (i_type) REFERENCES public.tr_type_customer(i_type);
 A   ALTER TABLE ONLY public.tr_customer DROP CONSTRAINT fk_customer;
       public          postgres    false    207    2831    209            +           2606    26578 !   tr_customer_item fk_customer_item    FK CONSTRAINT     �   ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);
 K   ALTER TABLE ONLY public.tr_customer_item DROP CONSTRAINT fk_customer_item;
       public          postgres    false    209    2833    211            ,           2606    26583 "   tr_customer_item fk_customer_item2    FK CONSTRAINT     �   ALTER TABLE ONLY public.tr_customer_item
    ADD CONSTRAINT fk_customer_item2 FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);
 L   ALTER TABLE ONLY public.tr_customer_item DROP CONSTRAINT fk_customer_item2;
       public          postgres    false    211    205    2829            0           2606    26675    tm_pembelian fk_tm_pembelian    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_pembelian
    ADD CONSTRAINT fk_tm_pembelian FOREIGN KEY (id_item) REFERENCES public.tr_customer_item(id_item);
 F   ALTER TABLE ONLY public.tm_pembelian DROP CONSTRAINT fk_tm_pembelian;
       public          postgres    false    219    2835    211            1           2606    26691 &   tm_pembelian_item fk_tm_pembelian_item    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_pembelian_item
    ADD CONSTRAINT fk_tm_pembelian_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian(id_document);
 P   ALTER TABLE ONLY public.tm_pembelian_item DROP CONSTRAINT fk_tm_pembelian_item;
       public          postgres    false    219    2845    221            2           2606    26718 2   tm_pembelian_retur_item fk_tm_pembelian_retur_item    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item FOREIGN KEY (id_document) REFERENCES public.tm_pembelian_retur(id_document);
 \   ALTER TABLE ONLY public.tm_pembelian_retur_item DROP CONSTRAINT fk_tm_pembelian_retur_item;
       public          postgres    false    223    2849    225            3           2606    26723 3   tm_pembelian_retur_item fk_tm_pembelian_retur_item2    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_pembelian_retur_item
    ADD CONSTRAINT fk_tm_pembelian_retur_item2 FOREIGN KEY (i_alasan) REFERENCES public.tr_alasan_retur(i_alasan);
 ]   ALTER TABLE ONLY public.tm_pembelian_retur_item DROP CONSTRAINT fk_tm_pembelian_retur_item2;
       public          postgres    false    225    2843    217            4           2606    26752 '   tm_penjualan_item fk_tm_penjualan_item2    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_penjualan_item
    ADD CONSTRAINT fk_tm_penjualan_item2 FOREIGN KEY (id_document) REFERENCES public.tm_penjualan(id_document);
 Q   ALTER TABLE ONLY public.tm_penjualan_item DROP CONSTRAINT fk_tm_penjualan_item2;
       public          postgres    false    229    2853    227            -           2606    26622 $   tm_user_customer fk_tm_user_customer    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer FOREIGN KEY (id_user) REFERENCES public.tm_user(id_user);
 N   ALTER TABLE ONLY public.tm_user_customer DROP CONSTRAINT fk_tm_user_customer;
       public          postgres    false    2837    214    213            .           2606    26627 %   tm_user_customer fk_tm_user_customer2    FK CONSTRAINT     �   ALTER TABLE ONLY public.tm_user_customer
    ADD CONSTRAINT fk_tm_user_customer2 FOREIGN KEY (id_customer) REFERENCES public.tr_customer(id_customer);
 O   ALTER TABLE ONLY public.tm_user_customer DROP CONSTRAINT fk_tm_user_customer2;
       public          postgres    false    214    2833    209            /           2606    26649    tr_product fk_tr_product    FK CONSTRAINT     �   ALTER TABLE ONLY public.tr_product
    ADD CONSTRAINT fk_tr_product FOREIGN KEY (i_company) REFERENCES public.tr_company(i_company);
 B   ALTER TABLE ONLY public.tr_product DROP CONSTRAINT fk_tr_product;
       public          postgres    false    205    215    2829            �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �     