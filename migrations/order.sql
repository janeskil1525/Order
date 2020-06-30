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


-- 1 down