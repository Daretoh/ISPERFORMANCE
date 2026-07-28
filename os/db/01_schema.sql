-- ============================================================
-- IS Performance OS — Esquema base (núcleo del taller)
-- Pegar completo en Supabase → SQL Editor → New query → Run
-- Seguro de re-ejecutar (usa IF NOT EXISTS / ON CONFLICT).
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- SERVICIOS (catálogo) ----------
create table if not exists servicios (
  id            text primary key,
  nombre        text not null,
  categoria     text not null,
  precio_s      integer,
  precio_m      integer,
  precio_l      integer,
  precio_xl     integer,
  precio_variable boolean default false,
  tiempo        text,
  orden         integer default 0,
  activo        boolean default true
);

-- ---------- VEHÍCULOS / INGRESOS (entidad central) ----------
create table if not exists vehiculos (
  id            uuid primary key default gen_random_uuid(),
  marca         text,
  modelo        text,
  patente       text,
  anio_veh      integer,
  talla         text default 'M',
  cliente       text,
  contacto      text,
  servicios     text[] default '{}',
  estado        text default 'AGENDADO',
  trabajador    text,
  f_coord       date,  h_coord   text,
  f_ingreso     date,  h_ingreso text,
  f_inicio      date,  h_inicio  text,
  f_salida      date,  h_salida  text,
  t_muerto      integer default 0,
  doc_tipo      text default 'BOLETA',
  modo_pago     text,
  aplica_bono   text default 'NO',
  precio_venta  integer default 0,
  costo_producto integer default 0,
  envio         integer default 0,
  costo_externo integer default 0,
  costo_empresa integer default 0,
  cobrado       boolean default false,
  created_at    timestamptz default now(),
  created_by    uuid default auth.uid()
);

-- ---------- RELOJ (horas trabajadas) ----------
create table if not exists reloj (
  id          uuid primary key default gen_random_uuid(),
  trabajador  text not null,
  fecha       date not null,
  h_in        text,
  h_out       text,
  descanso    integer default 0,
  created_at  timestamptz default now()
);

-- ---------- GASTOS del taller ----------
create table if not exists gastos (
  id          uuid primary key default gen_random_uuid(),
  concepto    text not null,
  tipo        text default 'FIJO',
  monto       integer default 0,
  fecha       date not null,
  created_at  timestamptz default now()
);

-- ---------- VALOR HORA por trabajador ----------
create table if not exists valor_hora (
  trabajador  text primary key,
  valor       integer default 0
);

-- ============ SEGURIDAD (RLS) ============
-- Solo usuarios autenticados (tu equipo con login) pueden ver/editar.
alter table servicios  enable row level security;
alter table vehiculos  enable row level security;
alter table reloj      enable row level security;
alter table gastos     enable row level security;
alter table valor_hora enable row level security;

drop policy if exists equipo_servicios  on servicios;
drop policy if exists equipo_vehiculos  on vehiculos;
drop policy if exists equipo_reloj       on reloj;
drop policy if exists equipo_gastos      on gastos;
drop policy if exists equipo_valorhora   on valor_hora;

create policy equipo_servicios  on servicios  for all to authenticated using (true) with check (true);
create policy equipo_vehiculos  on vehiculos  for all to authenticated using (true) with check (true);
create policy equipo_reloj      on reloj      for all to authenticated using (true) with check (true);
create policy equipo_gastos     on gastos     for all to authenticated using (true) with check (true);
create policy equipo_valorhora  on valor_hora for all to authenticated using (true) with check (true);

-- ============ TIEMPO REAL (para que el equipo vea cambios en vivo) ============
alter publication supabase_realtime add table vehiculos;
alter publication supabase_realtime add table reloj;
alter publication supabase_realtime add table gastos;
alter publication supabase_realtime add table valor_hora;

-- ============ CATÁLOGO (16 servicios) ============
insert into servicios (id,nombre,categoria,precio_s,precio_m,precio_l,precio_xl,precio_variable,tiempo,orden) values
 ('core','CORE — Limpieza básica','Limpiezas',35000,40000,45000,55000,false,'2-3 horas',1),
 ('advance','ADVANCE — Limpieza intermedia','Limpiezas',50000,55000,60000,65000,false,'3,5-4 horas',2),
 ('pro','PRO — Limpieza avanzada','Limpiezas',80000,90000,95000,100000,false,'5,5-6 horas',3),
 ('motor','Limpieza de motor','Limpiezas',25000,30000,40000,45000,false,'1,5 hora',4),
 ('pulido-estandar','Pulido estándar','Pulido de pintura',120000,140000,150000,170000,false,'1-2 días',5),
 ('pulido-premium','Pulido premium','Pulido de pintura',170000,190000,210000,230000,false,'1-2 días',6),
 ('ceramico-1','Tratamiento cerámico — 1 año','Protección y sellados',200000,250000,300000,350000,false,'2-3 días',7),
 ('ceramico-2','Tratamiento cerámico — 2 años','Protección y sellados',250000,300000,350000,400000,false,'2-3 días',8),
 ('ceramico-3','Tratamiento cerámico — 3 años','Protección y sellados',300000,350000,400000,450000,false,'3-4 días',9),
 ('mantencion','Mantención cerámica','Protección y sellados',45000,50000,55000,65000,false,'1,5-2,5 horas',10),
 ('vidrios','Tratamiento de vidrios','Protección y sellados',null,null,null,null,true,'1 hora',11),
 ('detallado-interior','Detallado integral interior','Sanitización interior',130000,150000,170000,200000,false,'1-2 días',12),
 ('detallado-full','Detallado integral full','Sanitización interior',260000,300000,340000,400000,false,'1-2 días',13),
 ('asientos','Limpieza profunda de asientos','Sanitización interior',null,null,null,null,true,'2-3 horas',14),
 ('techo','Tratamiento interior de techo','Sanitización interior',null,null,null,null,true,'1-2 horas',15),
 ('pre-venta','Preparación para la venta','Pre-venta',90000,110000,130000,150000,false,'5-6 horas',16)
on conflict (id) do nothing;
