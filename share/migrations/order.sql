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

create table if not exists companies (
    companies_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    company character varying NOT NULL DEFAULT '',
    name character varying  NOT NULL DEFAULT '',
    registrationnumber character varying  NOT NULL DEFAULT '',
    phone character varying  NOT NULL DEFAULT '',
    recyclingsystem character varying  NOT NULL DEFAULT '',
    menu_group BIGINT NOT NULL DEFAULT 0,
    homepage character varying NOT NULL DEFAULT '',
    CONSTRAINT companies_pkey PRIMARY KEY (companies_pkey)
);

CREATE UNIQUE INDEX idx_companies_company ON companies (company);

INSERT INTO menu (menu, menu_path, menu_order) VALUES ('Företag', '/app/companies/list/', 100);

-- Table: public.users_companies

-- DROP TABLE public.users_companies;

CREATE TABLE public.users_companies
(
    users_companies_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    companies_fkey bigint NOT NULL,
    users_fkey bigint NOT NULL,
    CONSTRAINT users_companies_pkey PRIMARY KEY (users_companies_pkey),
    CONSTRAINT companies_users_fkey_fkey FOREIGN KEY (companies_fkey)
        REFERENCES public.companies (companies_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT users_company_fkey_fkey FOREIGN KEY (users_fkey)
        REFERENCES public.users (users_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
);

ALTER TABLE public.users_companies
    OWNER to postgres;

-- Index: fki_users_company_companies_fkey_fkey

-- DROP INDEX public.fki_users_company_companies_fkey_fkey;

CREATE INDEX fki_users_company_companies_fkey_fkey
    ON public.users_companies USING btree
        (companies_fkey ASC NULLS LAST);


-- Index: fki_users_company_users_fkey_fkey

-- DROP INDEX public.fki_users_company_users_fkey_fkey;

CREATE INDEX fki_users_company_users_fkey_fkey
    ON public.users_companies USING btree
        (users_fkey ASC NULLS LAST);


-- Index: idx_users_companies_companies

-- DROP INDEX public.idx_users_companies_companies;

CREATE INDEX idx_users_companies_companies
    ON public.users_companies USING btree
        (companies_fkey ASC NULLS LAST);


-- Index: idx_users_companies_unique

-- DROP INDEX public.idx_users_companies_unique;

CREATE UNIQUE INDEX idx_users_companies_unique
    ON public.users_companies USING btree
        (users_fkey ASC NULLS LAST, companies_fkey ASC NULLS LAST);


-- Index: idx_users_companies_users

-- DROP INDEX public.idx_users_companies_users;

CREATE INDEX idx_users_companies_users
    ON public.users_companies USING btree
        (users_fkey ASC NULLS LAST);

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
    users_fkey bigint not null default 0,
    companies_fkey bigint not null default 0,
    CONSTRAINT order_head_pkey PRIMARY KEY (order_head_pkey)
      USING INDEX TABLESPACE "webshop",
    CONSTRAINT order_head_users_fkey_fkey FOREIGN KEY (users_fkey)
      REFERENCES public.users (users_pkey) MATCH SIMPLE
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
      DEFERRABLE,
    CONSTRAINT order_head_companies_fkey_fkey FOREIGN KEY (companies_fkey)
      REFERENCES public.companies (companies_pkey) MATCH SIMPLE
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
      DEFERRABLE
) TABLESPACE "webshop";

CREATE unique INDEX idx_order_head_order_no
    ON public.order_head USING btree
        (order_no ASC NULLS LAST)
    TABLESPACE webshop;


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
    CONSTRAINT order_items_pkey PRIMARY KEY (order_items_pkey)
       USING INDEX TABLESPACE "webshop",
    CONSTRAINT order_head_order_items_fkey FOREIGN KEY (order_head_fkey)
       REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
       ON UPDATE NO ACTION
       ON DELETE NO ACTION
       DEFERRABLE
) TABLESPACE "webshop";

CREATE unique INDEX idx_order_head_fkey_itemno
    ON public.order_items USING btree
        (order_head_fkey, itemno)
    TABLESPACE webshop;

CREATE TABLE public.order_vehicle
(
    order_vehicle_pkey integer NOT NULL DEFAULT nextval('basket_vehicle_basket_vehicle_pkey_seq'::regclass),
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    regplate character varying(10) COLLATE pg_catalog."default" NOT NULL,
    order_items_fkey bigint NOT NULL,
    CONSTRAINT order_vehicle_pkey PRIMARY KEY (order_vehicle_pkey)
        USING INDEX TABLESPACE webshop,
    CONSTRAINT order_vehicle_order_items_fkey FOREIGN KEY (order_items_fkey)
        REFERENCES public.order_items (order_items_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
)TABLESPACE webshop;

CREATE UNIQUE INDEX idx_order_vehicle_order_items_fkey_regplate_unique
    ON public.order_vehicle USING btree
        (regplate, order_items_fkey)
    TABLESPACE webshop;

CREATE TABLE public.order_addresses
(
    order_addresses_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    name character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    address1 character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    address2 character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    address3 character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    city character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    zipcode character varying(200) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    country character varying(30) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    CONSTRAINT order_addresses_pkey PRIMARY KEY (order_addresses_pkey)
        USING INDEX TABLESPACE webshop
) TABLESPACE webshop;


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
    CONSTRAINT order_addresses_order_pkey PRIMARY KEY (order_addresses_order_pkey)
        USING INDEX TABLESPACE webshop,
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
)TABLESPACE webshop;


CREATE UNIQUE INDEX idx_order_address_order_address_address_type_unique
    ON public.order_addresses_order USING btree
        (order_head_fkey, order_addresses_fkey, address_type COLLATE pg_catalog."default")
    TABLESPACE webshop;

CREATE TABLE public.order_companies_order
(
    order_companies_order_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    order_head_fkey bigint NOT NULL,
    companies_fkey bigint NOT NULL,
    relation_type character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'Supplier'::character varying,
    CONSTRAINT order_companies_order_pkey PRIMARY KEY (order_companies_order_pkey)
        USING INDEX TABLESPACE webshop,
    CONSTRAINT order_companies_order_order_head_fkey FOREIGN KEY (order_head_fkey)
        REFERENCES public.order_head (order_head_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE,
    CONSTRAINT order_companies_order_companies_fkey FOREIGN KEY (companies_fkey)
        REFERENCES public.companies (companies_pkey) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE
)TABLESPACE webshop;

CREATE TABLE public.order_basket
(
    order_basket_pkey serial,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    order_head_fkey bigint NOT NULL,
    basket_fkey bigint NOT NULL,
    CONSTRAINT order_basket_pkey PRIMARY KEY (order_basket_pkey)
        USING INDEX TABLESPACE webshop,
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
)TABLESPACE webshop;

ALTER TABLE order_items
    ADD COLUMN freight numeric(15,2) NOT NULL DEFAULT 0;
-- 1 down