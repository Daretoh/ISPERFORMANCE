-- ============================================================
-- IS Performance OS - Modulo Inventario / Stock
-- Pegar en Supabase > SQL Editor > Run (traduccion apagada).
-- Seguro de re-ejecutar. Solo AGREGA.
-- ============================================================

create table if not exists productos (
  id            uuid primary key default gen_random_uuid(),
  tipo          text default 'EQUIPAMIENTO',   -- EQUIPAMIENTO | DETAILING
  producto      text not null,
  marca         text,
  compatibilidad text,
  medidas       text,
  entrada       integer default 0,
  salida        integer default 0,
  costo         integer default 0,
  precio        integer default 0,
  created_at    timestamptz default now()
);

alter table productos enable row level security;
drop policy if exists equipo_productos on productos;
create policy equipo_productos on productos for all to authenticated using (true) with check (true);
do $$ begin begin alter publication supabase_realtime add table productos; exception when duplicate_object then null; end; end $$;

-- Stock de equipamiento (hoja STOCK TALLER)
insert into productos (tipo,producto,marca,compatibilidad,medidas,entrada,salida) values
('EQUIPAMIENTO','BARRA ANTIVUELCO CROMADA','BARRA PREMIUM CROMADA F01CROM REVO 2105+','L200- DMAX- BT50-RANGER-WINGLE 7- COLORADO','145',1,0),
('EQUIPAMIENTO','BARRA ANTIVUELCO BICOLOR','BARRA SS01F05 BICOLOR',null,'150',1,1),
('EQUIPAMIENTO','BARRA ANTIVUELCO CROMADA','BARRA UNIVERSALES F05','HILUX- VIGGO-NAVARA- NP300-COLORADO-BT50- MERCEDES-D-MAX-MAXUS T-60- RANGER','150',1,1),
('EQUIPAMIENTO','BARRA ANTIVUELCO NEGRA','BARRA F05 NEGRA AMAROK','AMAROX-ACTYON-GRAN MUSO-GRAMGAN','160',1,1),
('EQUIPAMIENTO','BOTA AGUA','CHEVROLE/DMAX',null,null,1,1),
('EQUIPAMIENTO','BOTA AGUA','GRAND VITARA',null,null,1,1),
('EQUIPAMIENTO','LONA','TAPA PLEGABLE/FORD F-150',null,null,1,1),
('EQUIPAMIENTO','LONA MARITIMA KEKO','LONA MARITIMA KEKO AMAROK',null,null,1,1),
('EQUIPAMIENTO','PISOS CALCE PERFECTO','GWM/POER',null,null,1,1),
('EQUIPAMIENTO','PISOS CALCE PERFECTO','CHEVROLET/SILVERADO',null,null,1,1),
('EQUIPAMIENTO','PISOS CALCE PERFECTO','AMAROK',null,null,1,1),
('EQUIPAMIENTO','PISOS DE CALCE PERFECTO','L200',null,null,2,2),
('EQUIPAMIENTO','BARRA ANTIVUELCO BICOLOR','BARRA SS01F05 BICOLOR','HILUX- VIGGO-NAVARA- NP300-COLORADO-BT50- MERCEDES-D-MAX-MAXUS T-60- RANGER','150',1,0),
('EQUIPAMIENTO','BARRA ANTIVUELCO CROMADA','BARRA F05 NEGRA VIGO, REVO, RANGER','HILUX- VIGGO-NAVARA- NP300-COLORADO-BT50- MERCEDES-D-MAX-MAXUS T-60- RANGER','150',1,1),
('EQUIPAMIENTO','BARRA ANTIVUELCO NEGRA','BARRA UNIVERSALES F05','HILUX- VIGGO-NAVARA- NP300-COLORADO-BT50- MERCEDES-D-MAX-MAXUS T-60- RANGER','150',1,0),
('EQUIPAMIENTO','PISOS CALCE PERFECTO','HILUX/L200',null,null,1,0),
('EQUIPAMIENTO','PISADERAS','PISADERA BORDE CROMADO L200','MAXUS T60-  WINGLE - DMAX- REVO',null,1,0),
('EQUIPAMIENTO','PISADERAS NEGRA','PISADERA SAFARI L-200 (16-23)','REVO 2015+, NP300 2015-2021 -SILVERADO 2019 - L200 2016-2023',null,1,0),
('EQUIPAMIENTO','PISADERA NORMAL','L200',null,null,1,0),
('EQUIPAMIENTO','RACK DE CARGA 2BLO ALTO PICKUP','UNIVERSAL',null,null,1,0);
