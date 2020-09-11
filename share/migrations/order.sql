-- 1 up

create table if not exists users (
     users_pkey serial not null,
     editnum bigint NOT NULL DEFAULT 1,
     insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     userid varchar(100) not null,
     username varchar(100),
     passwd varchar(100) not null,
     menu_group BIGINT NOT NULL DEFAULT 0,
     active BOOLEAN NOT NULL DEFAULT false,
     can_login BOOLEAN NOT NULL DEFAULT false,
     CONSTRAINT users_pkey PRIMARY KEY (users_pkey)
);

CREATE UNIQUE INDEX  idx_users_userid
    ON public.users USING btree
        (userid );

create table if not exists menu (
    menu_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    menu varchar not null,
    menu_path varchar not null,
    menu_order bigint not null,
    CONSTRAINT menu_pkey PRIMARY KEY (menu_pkey)
);

INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Övervakning', '/app/monitor/list/', 0);
INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Användare', '/app/users/list/', 101);
INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Minion', '/minion/', 1);
INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Data', '/yancy/', 2000);
INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Företag', '/app/companies/list/', 100);

drop table if exists basket;

create table if not exists basket
(
    basket_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    basketid varchar(100) not null default '',
    approved boolean not null default false,
    status varchar(100) not null default 'NEW',
    payment varchar(100) not null default '',
    userid varchar(100) not null,
    company varchar(100) not null,
    CONSTRAINT basket_pkey PRIMARY KEY (basket_pkey)

) ;

CREATE INDEX idx_basket_userid ON basket(userid);
CREATE INDEX idx_basket_company ON basket(company);

DROP SEQUENCE IF EXISTS orderno;
CREATE SEQUENCE orderno START 10000;

create table if not exists order_head
(
    order_head_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    order_type int not null default 1,
    order_no varchar(100) not null,
    orderdate timestamp without time zone NOT NULL DEFAULT NOW(),
    userid varchar(100) not null,
    company varchar(100) not null,
    CONSTRAINT order_head_pkey PRIMARY KEY (order_head_pkey)
) ;

CREATE unique INDEX idx_order_head_order_no
    ON public.order_head USING btree
        (order_no ASC NULLS LAST)
   ;


create table if not exists order_items
(
    order_items_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    order_head_fkey bigint not null default 0,
    itemno int not null default 1,
    stockitem varchar(100) not null,
    description varchar(100) not null,
    quantity int not null default 1,
    price numeric(15,2) not null default 0.0,
    deliverydate timestamp without time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT order_items_pkey PRIMARY KEY (order_items_pkey),
    CONSTRAINT order_head_order_items_fkey FOREIGN KEY (order_head_fkey)
       REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
       ON UPDATE NO ACTION
       ON DELETE NO ACTION
       DEFERRABLE
) ;

CREATE unique INDEX idx_order_head_fkey_itemno
    ON public.order_items USING btree
        (order_head_fkey, itemno);

CREATE TABLE public.order_vehicle
(
    order_vehicle_pkey SERIAL not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    regplate character varying(10) COLLATE pg_catalog."default" NOT NULL,
    order_items_fkey bigint NOT NULL,
    CONSTRAINT order_vehicle_pkey PRIMARY KEY (order_vehicle_pkey),
    CONSTRAINT order_vehicle_order_items_fkey FOREIGN KEY (order_items_fkey)
        REFERENCES public.order_items (order_items_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE UNIQUE INDEX idx_order_vehicle_order_items_fkey_regplate_unique
    ON public.order_vehicle USING btree
        (regplate, order_items_fkey);

CREATE TABLE public.order_addresses
(
    order_addresses_pkey serial,
    editnum              bigint                                             NOT NULL DEFAULT 1,
    insby                character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime          timestamp without time zone                        NOT NULL DEFAULT now(),
    modby                character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime          timestamp without time zone                        NOT NULL DEFAULT now(),
    name                 character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    address1             character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    address2             character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    address3             character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    city                 character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    zipcode              character varying(200) COLLATE pg_catalog."default"         DEFAULT ''::character varying,
    country              character varying(30) COLLATE pg_catalog."default"          DEFAULT ''::character varying,
    CONSTRAINT order_addresses_pkey PRIMARY KEY (order_addresses_pkey)
);


CREATE TABLE public.order_addresses_order
(
    order_addresses_order_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    order_head_fkey bigint NOT NULL,
    order_addresses_fkey bigint NOT NULL,
    address_type character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'Invoice'::character varying,
    CONSTRAINT order_addresses_order_pkey PRIMARY KEY (order_addresses_order_pkey),
    CONSTRAINT order_addresses_order_head_fkey_fkey FOREIGN KEY (order_head_fkey)
        REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT order_addresses_address_fkey_fkey FOREIGN KEY (order_addresses_fkey)
        REFERENCES public.order_addresses (order_addresses_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);


CREATE UNIQUE INDEX idx_order_address_order_address_address_type_unique
    ON public.order_addresses_order USING btree
        (order_head_fkey, order_addresses_fkey, address_type COLLATE pg_catalog."default");

CREATE TABLE public.order_companies_order
(
    order_companies_order_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    order_head_fkey bigint NOT NULL,
    company varchar(100) not null,
    relation_type character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'Supplier'::character varying,
    CONSTRAINT order_companies_order_pkey PRIMARY KEY (order_companies_order_pkey),
    CONSTRAINT order_companies_order_order_head_fkey FOREIGN KEY (order_head_fkey)
        REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

CREATE INDEX idx_order_companies_order_company ON order_companies_order(company);

CREATE TABLE order_basket
(
    order_basket_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    order_head_fkey bigint NOT NULL,
    basket_fkey bigint NOT NULL,
    CONSTRAINT order_basket_pkey PRIMARY KEY (order_basket_pkey),
    CONSTRAINT order_basket_order_head_fkey_fkey FOREIGN KEY (order_head_fkey)
        REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT order_basket_fkey_fkey FOREIGN KEY (basket_fkey)
        REFERENCES public.basket (basket_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

ALTER TABLE order_items
    ADD COLUMN freight numeric(15,2) NOT NULL DEFAULT 0;

create table if not exists languages
(
     languages_pkey serial not null,
     editnum bigint NOT NULL DEFAULT 1,
     insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     lan character varying(10) NOT NULL,
     lan_name character varying(100) NOT NULL,
     CONSTRAINT languages_pkey PRIMARY KEY (languages_pkey)
);

INSERT INTO languages (lan, lan_name) VALUES ('dan', 'Danish');
INSERT INTO languages (lan, lan_name) VALUES ('fin', 'Finnish');
INSERT INTO languages (lan, lan_name) VALUES ('deu', 'German');
INSERT INTO languages (lan, lan_name) VALUES ('nor', 'Norwegian');
INSERT INTO languages (lan, lan_name) VALUES ('eng', 'English');
INSERT INTO languages (lan, lan_name) VALUES ('swe', 'Swedish');

CREATE TABLE IF NOT EXISTS translations
(
    translations_pkey SERIAL NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    languages_fkey integer NOT NULL DEFAULT 0,
    module character varying(100)  NOT NULL,
    tag character varying(100) NOT NULL,
    translation text NOT NULL,
    CONSTRAINT translations_pkey PRIMARY KEY (translations_pkey),
    CONSTRAINT languages_translations_fkey FOREIGN KEY (languages_fkey)
        REFERENCES languages (languages_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
) ;

CREATE UNIQUE INDEX if not exists idx_translations_languages_fkey_module_tag_unique
    ON translations USING btree
        (languages_fkey, module, tag);

CREATE  INDEX if not exists idx_translations_languages_fkey
    ON translations USING btree
        (languages_fkey);

INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'order_item', 'order_items_pkey','Primärnyckel'),
(6, 'order_item', 'order_head_fkey','Orderhuvud'),
(6, 'order_item', 'itemno','Rad'),
(6, 'order_item', 'stockitem','Artikel'),
(6, 'order_item', 'description','Beskrivning'),
(6, 'order_item', 'quantity','Antal'),
(6, 'order_item', 'price','Pris'),
(6, 'order_item', 'deliverydate','Leverans'),
(6, 'order_item', 'rfq_note','Offertförfrågan text');

INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'basket_item', 'basket_item_pkey','Primärnyckel'),
(6, 'basket_item', 'basket_fkey','Kundkorg'),
(6, 'basket_item', 'itemtype','Radtype'),
(6, 'basket_item', 'itemno','Rad'),
(6, 'basket_item', 'stockitem','Artikel'),
(6, 'basket_item', 'description','Beskrivning'),
(6, 'basket_item', 'quantity','Antal'),
(6, 'basket_item', 'price','Pris'),
(6, 'basket_item', 'externalref','Extern referens'),
(6, 'basket_item', 'expirydate','Utgångsdatum'),
(6, 'basket_item', 'supplier_fkey','Leverantör'),
(6, 'basket_item', 'rfq_note','Offertförfrågan');

INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'order_head', 'order_head_pkey','Primärnyckel'),
(6, 'order_head', 'order_type','Order typ'),
(6, 'order_head', 'order_no','Order nummer'),
(6, 'order_head', 'orderdate','Order datum'),
(6, 'order_head', 'users_fkey','Användarnyckel'),
(6, 'order_head', 'companies_fkey','Företagsnyckel');

INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'order_addresses', 'order_addresses_pkey','Primärnyckel'),
(6, 'order_addresses', 'name','Namn'),
(6, 'order_addresses', 'address1','Address'),
(6, 'order_addresses', 'address2','Address'),
(6, 'order_addresses', 'address3','Address'),
(6, 'order_addresses', 'city','Postort'),
(6, 'order_addresses', 'zipcode','Postnummer'),
(6, 'order_addresses', 'country','Land');

INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'basket_item', 'freight','Frakt'),
(6, 'Basket_grid_fields', 'freight','Frakt'),
(6, 'order_item', 'freight','Frakt');

drop table if exists basket_addresses_basket;
drop table if exists addresses_basket ;
drop table if exists basket_addresses;
drop table if exists basket_vehicle;
drop table if exists basket_item;
drop table if exists basket_addresses;


CREATE UNIQUE INDEX idx_basket_basketid
    ON public.basket USING btree
        (basketid );

create table if not exists basket_item
(
   basket_item_pkey serial not null,
   editnum bigint NOT NULL DEFAULT 1,
   insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
   insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
   modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
   moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
   basket_fkey bigint not null default 0,
   itemtype int default 1,
   itemno bigint not null default 1,
   stockitem varchar(100)  not null,
   description varchar(100) default '',
   quantity bigint not null default 1,
   price numeric(15, 2) not null default 0,
   externalref bigint default 0,
   expirydate timestamp without time zone NOT NULL DEFAULT NOW(),
   CONSTRAINT basket_item_pkey PRIMARY KEY (basket_item_pkey)
) ;

ALTER TABLE public.basket_item
    ADD CONSTRAINT basket_fkey_fkey FOREIGN KEY (basket_fkey)
        REFERENCES public.basket (basket_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID;
CREATE INDEX fki_basket_fkey_fkey
    ON public.basket_item(basket_fkey);

CREATE UNIQUE INDEX idx_basket_item_basket_fkey_itemno
    ON public.basket_item USING btree
        (basket_fkey, itemno ) ;

create table if not exists basket_addresses
(
    basket_addresses_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    name varchar(200) default '',
    address1 varchar(200) default '',
    address2 varchar(200) default '',
    address3 varchar(200) default '',
    city varchar(200) default '',
    zipcode varchar(200) default '',
    country varchar(30) default '',
    CONSTRAINT basket_addresses_pkey PRIMARY KEY (basket_addresses_pkey)
);

create table if not exists basket_addresses_basket
(
   basket_addresses_basket_pkey serial not null,
   editnum bigint NOT NULL DEFAULT 1,
   insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
   insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
   modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
   moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
   basket_fkey bigint not null,
   basket_addresses_fkey bigint not null,
   address_type varchar NOT NULL DEFAULT 'Invoice',
   CONSTRAINT basket_addressesbasket_pkey PRIMARY KEY (basket_addresses_basket_pkey),
   CONSTRAINT address_basket_basket_fkey_fkey FOREIGN KEY (basket_fkey)
       REFERENCES public.basket (basket_pkey) MATCH SIMPLE
       ON UPDATE NO ACTION
       ON DELETE NO ACTION
       DEFERRABLE,
   CONSTRAINT basket_addresses_basket_address_fkey_fkey FOREIGN KEY (basket_addresses_fkey)
       REFERENCES public.basket_addresses (basket_addresses_pkey) MATCH SIMPLE
       ON UPDATE NO ACTION
       ON DELETE NO ACTION
       DEFERRABLE
) ;

CREATE UNIQUE INDEX idx_basket_address_basket_address_address_type_unique
    ON public.basket_addresses_basket USING btree
        (basket_fkey, basket_addresses_fkey, address_type);

create table if not exists basket_vehicle
(
     basket_vehicle_pkey serial not null,
     editnum bigint NOT NULL DEFAULT 1,
     insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
     moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
     regplate character varying(10) NOT NULL,
     basket_item_fkey bigint NOT NULL,
     CONSTRAINT basket_vehicle_pkey PRIMARY KEY (basket_vehicle_pkey),
     CONSTRAINT basket_vehicle_basket_fkey FOREIGN KEY (basket_item_fkey)
         REFERENCES public.basket_item (basket_item_pkey) MATCH SIMPLE
         ON UPDATE NO ACTION
         ON DELETE NO ACTION
         DEFERRABLE
);

ALTER TABLE basket_item
    ADD COLUMN rfq_note text default '';

CREATE SEQUENCE rfqno START 10000;

create table if not exists rfqs
(
    rfqs_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    rfq_no varchar(100) not null,
    rfqstatus VARCHAR NOT NULL DEFAULT 'NEW',
    requestdate timestamp without time zone NOT NULL DEFAULT NOW(),
    reqplate varchar(100) not null default '',
    note text not null default '',
    userid varchar(100) not null,
    company varchar(100) not null,
    supplier varchar(100) not null,
    CONSTRAINT rfqs_pkey PRIMARY KEY (rfqs_pkey)
);

CREATE INDEX idx_rfqs_userid ON rfqs(userid);
CREATE INDEX idx_rfqs_company ON rfqs(company);
CREATE INDEX idx_rfqs_supplier ON rfqs(supplier);

CREATE unique INDEX idx_rfqs_rfq_no
    ON public.rfqs USING btree
        (rfq_no ASC NULLS LAST);

ALTER TABLE rfqs
    ADD COLUMN sent BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE rfqs
    ADD COLUMN sentat TIMESTAMP NOT NULL DEFAULT '1900-01-01';

ALTER TABLE rfqs
    RENAME reqplate TO regplate;

-- 1 down

-- 2 up

ALTER TABLE basket_item ADD COLUMN supplier varchar not null;
ALTER TABLE basket_item ADD COLUMN freight numeric(15, 2) not null default 0;

-- 2 down

-- 3 up
CREATE TABLE if not exists settings
(
    settings_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    setting_name character varying(200) COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT settings_pkey PRIMARY KEY (settings_pkey)
        USING INDEX TABLESPACE webshop
) ;

CREATE TABLE if not exists default_settings_values
(
    default_settings_values_pkey serial NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    settings_fkey bigint NOT NULL,
    setting_no BIGINT NOT NULL DEFAULT 0,
    setting_value TEXT NOT NULL DEFAULT '',
    setting_order BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT default_settings_values_pkey PRIMARY KEY (default_settings_values_pkey)
        USING INDEX TABLESPACE webshop,
    CONSTRAINT default_settings_values_settings_fkey FOREIGN KEY (settings_fkey)
        REFERENCES settings (settings_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
) ;

CREATE UNIQUE INDEX if not exists idx_settings_fkey_setting_no_companies_fkey_users_fkey
    ON default_settings_values USING btree
        (settings_fkey,setting_no);

ALTER TABLE default_settings_values
    ADD COLUMN setting_properties VARCHAR NOT NULL DEFAULT '';

INSERT INTO settings (settings_pkey, setting_name) VALUES (4, 'Basket_grid_fields');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 1, 'basket_item_pkey', 0, '{"visible":"false"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 2, 'itemtype', 0, '{"visible":"false"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 3, 'itemno', 1,'{"visible":"true"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 4, 'stockitem', 2,'{"visible":"true"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 5, 'description', 3,'{"visible":"true"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 6, 'quantity', 4,'{"visible":"true"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 7, 'price', 5,'{"visible":"true"}');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order, setting_properties)
values (4, 8, 'expirydate', 0, '{"visible":"false"}');

INSERT INTO settings (settings_pkey, setting_name) VALUES (5, 'Basket_details_fields');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value) values (5, 1, 'basket_pkey');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value) values (5, 2, 'basketid');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value) values (5, 3, 'approved');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value) values (5, 4, 'status');
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value) values (5, 5, 'payment');


INSERT INTO settings (settings_pkey, setting_name) VALUES (6, 'Basket_address_fields');

INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 1, 'basket_addresses_pkey',0);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 2, 'name',1);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 3, 'address1',2);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 4, 'address2',3);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 5, 'address3',4);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 6, 'city',5);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 7, 'zipcode',6);
INSERT INTO default_settings_values (settings_fkey, setting_no, setting_value, setting_order)
values (6, 8, 'country',7);

-- 3 down
-- 4 up

ALTER TABLE default_settings_values
    ADD COLUMN setting_backend_properties VARCHAR NOT NULL DEFAULT '';

-- 4 down

-- 5 up
create table if not exists last_used_basket_addresses
(
    last_used_basket_addresses_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    name varchar(200) default '',
    address1 varchar(200) default '',
    address2 varchar(200) default '',
    address3 varchar(200) default '',
    city varchar(200) default '',
    zipcode varchar(200) default '',
    country varchar(30) default '',
    userid varchar(100) not null,
    company varchar(100) not null,
    address_type varchar NOT NULL DEFAULT 'Invoice',
    CONSTRAINT last_used_basket_addresses_pkey PRIMARY KEY (last_used_basket_addresses_pkey)
);

CREATE UNIQUE INDEX idx_last_used_basket_addresses_userid_company_address_type
    ON last_used_basket_addresses(userid, company, address_type);

-- 5 down

-- 6 up
INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'Basket_details_fields', 'basketid','Korgid'),
(6, 'Basket_details_fields', 'approved','Godkännd'),
(6, 'Basket_details_fields', 'status','Status'),
(6, 'Basket_details_fields', 'payment','Betalsätt');

-- 6 down

-- 7 up
INSERT INTO translations (languages_fkey, module, tag, translation) VALUES
(6, 'Basket_address_fields', 'address1','Adress 1'),
(6, 'Basket_address_fields', 'address2','Adress 2'),
(6, 'Basket_address_fields', 'address3','Adress 3'),
(6, 'Basket_address_fields', 'city','Postort'),
(6, 'Basket_address_fields', 'zipcode','Postnummer'),
(6, 'Basket_address_fields', 'country','Land'),
(6, 'Basket_address_fields', 'name','Namn');

-- 7 down

-- 8 up
create table if not exists suppliers
(
    suppliers_pkey serial not null ,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    company varchar(100) not null default '',
    name varchar(100) not null default '',
    registrationnumber varchar not null default '',
    phone varchar not null default '',
    homepage varchar not null default '',
    address1 varchar not null default '',
    address2 varchar not null default '',
    address3 varchar not null default '',
    zipcode varchar not null default '',
    city varchar not null default '',
    company_mails varchar not null default '',
    sales_mails varchar not null default '',
    basket_item_fkey  bigint not null UNIQUE,
    CONSTRAINT suppliers_pkey PRIMARY KEY (suppliers_pkey),
    CONSTRAINT suppliers_basket_item_fkey FOREIGN KEY (basket_item_fkey)
        REFERENCES public.basket_item (basket_item_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

-- 8 down

-- 9 up
CREATE UNIQUE INDEX idx_basket_item_basket_fkey_stockitem
    ON public.basket_item USING btree
        (basket_fkey, stockitem ) ;

DROP INDEX idx_basket_item_basket_fkey_itemno;
-- 9 down

-- 10 up

create table if not exists customers
(
    customers_pkey serial not null ,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    company varchar(100) not null default '',
    name varchar(100) not null default '',
    registrationnumber varchar not null default '',
    phone varchar not null default '',
    homepage varchar not null default '',
    address1 varchar not null default '',
    address2 varchar not null default '',
    address3 varchar not null default '',
    zipcode varchar not null default '',
    city varchar not null default '',
    company_mails varchar not null default '',
    basket_fkey  bigint not null UNIQUE,
    CONSTRAINT customers_pkey PRIMARY KEY (customers_pkey),
    CONSTRAINT customers_basket_fkey FOREIGN KEY (basket_fkey)
        REFERENCES basket (basket_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
);

ALTER TABLE basket
    ADD COLUMN reference VARCHAR NOT NULL DEFAULT '';

ALTER TABLE basket
    ADD COLUMN debt VARCHAR NOT NULL DEFAULT '';

ALTER TABLE basket
    ADD COLUMN discount numeric(15,2) not null default 0.0;

-- 10 down

-- 11 up
create table if not exists sales_order_head
(
    sales_order_head_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    order_type int not null default 1,
    order_no varchar(100) not null,
    orderdate timestamp without time zone NOT NULL DEFAULT NOW(),
    userid varchar(100) not null,
    company varchar(100) not null,
    name varchar(100) not null default '',
    registrationnumber varchar not null default '',
    phone varchar not null default '',
    homepage varchar not null default '',
    address1 varchar not null default '',
    address2 varchar not null default '',
    address3 varchar not null default '',
    zipcode varchar not null default '',
    city varchar not null default '',
    company_mails varchar not null default '',
    externalref varchar not null default '',
    CONSTRAINT sales_order_head_pkey PRIMARY KEY (sales_order_head_pkey)
) ;

CREATE unique INDEX idx_sales_order_head_order_no
    ON public.sales_order_head USING btree
        (order_no ASC NULLS LAST)
;

create table if not exists sales_order_items
(
    sales_order_items_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    sales_order_head_fkey bigint not null default 0,
    itemno int not null default 1,
    stockitem varchar(100) not null,
    description varchar(100) not null,
    quantity int not null default 1,
    price numeric(15,2) not null default 0.0,
    deliverydate timestamp without time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT sales_order_items_pkey PRIMARY KEY (sales_order_items_pkey),
    CONSTRAINT sales_order_head_order_items_fkey FOREIGN KEY (sales_order_head_fkey)
        REFERENCES public.sales_order_head (sales_order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
) ;

CREATE unique INDEX idx_sales_order_head_fkey_itemno
    ON public.sales_order_items USING btree
        (sales_order_head_fkey, itemno);

create table if not exists purchase_order_head
(
    purchase_order_head_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    order_type int not null default 1,
    order_no varchar(100) not null,
    orderdate timestamp without time zone NOT NULL DEFAULT NOW(),
    userid varchar(100) not null,
    company varchar(100) not null,
    name varchar(100) not null default '',
    registrationnumber varchar not null default '',
    phone varchar not null default '',
    homepage varchar not null default '',
    address1 varchar not null default '',
    address2 varchar not null default '',
    address3 varchar not null default '',
    zipcode varchar not null default '',
    city varchar not null default '',
    company_mails varchar not null default '',
    sales_mails varchar not null default '',
    externalref varchar not null default '',
    CONSTRAINT purchase_order_head_pkey PRIMARY KEY (purchase_order_head_pkey)
) ;

CREATE unique INDEX idx_purchase_order_head_order_no
    ON public.purchase_order_head USING btree
        (order_no ASC NULLS LAST)
;

create table if not exists purchase_order_items
(
    purchase_order_items_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    purchase_order_head_fkey bigint not null default 0,
    itemno int not null default 1,
    stockitem varchar(100) not null,
    description varchar(100) not null,
    quantity int not null default 1,
    price numeric(15,2) not null default 0.0,
    deliverydate timestamp without time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT purchase_order_items_pkey PRIMARY KEY (purchase_order_items_pkey),
    CONSTRAINT purchase_order_head_order_items_fkey FOREIGN KEY (purchase_order_head_fkey)
        REFERENCES purchase_order_head (purchase_order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
) ;

CREATE unique INDEX idx_purchase_order_head_fkey_itemno
    ON purchase_order_items USING btree
        (purchase_order_head_fkey, itemno);

DROP TABLE order_basket;
DROP TABLE order_vehicle;
DROP TABLE order_addresses_order;
DROP TABLE order_companies_order;
DROP TABLE order_items;
DROP TABLE order_head;

-- 11 down

-- 12 up

ALTER TABLE sales_order_head
    ADD COLUMN debt VARCHAR NOT NULL DEFAULT '';

ALTER TABLE sales_order_head
    ADD COLUMN customer VARCHAR NOT NULL DEFAULT '';

ALTER TABLE purchase_order_head
    ADD COLUMN supplier VARCHAR NOT NULL DEFAULT '';

-- 12 down

-- 13 up

ALTER TABLE basket_item
    ADD COLUMN discount numeric(15,2) not null default 0.0;

CREATE INDEX idx_basket_item_supplier
    ON basket_item(supplier);

ALTER TABLE sales_order_items
    ADD COLUMN discount numeric(15,2) not null default 0.0;

ALTER TABLE sales_order_items
    ADD COLUMN freight numeric(15,2) not null default 0.0;

ALTER TABLE purchase_order_items
    ADD COLUMN discount numeric(15,2) not null default 0.0;

ALTER TABLE purchase_order_items
    ADD COLUMN freight numeric(15,2) not null default 0.0;
-- 13 down

-- 14 up

ALTER TABLE sales_order_head
    ADD COLUMN sales_mails VARCHAR NOT NULL DEFAULT '';

-- 14 down

-- 15 up
ALTER TABLE basket_item
    ADD COLUMN extradata JSONB;

-- 15 down