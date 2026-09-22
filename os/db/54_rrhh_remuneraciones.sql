-- ============================================================
-- IS Performance OS - RRHH (documentación, capacitaciones, finiquitos)
-- + Remuneraciones semanales (extras/descuentos y ajuste por día).
-- Adaptado de InnovaGestión. Adjuntos (media) van a R2 como jsonb.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

-- 1) Documentación y capacitaciones: un registro por trabajador + tipo
create table if not exists rrhh_docs (
  id            uuid primary key default gen_random_uuid(),
  trabajador_id uuid not null references trabajadores(id) on delete cascade,
  tipo          text not null,                     -- slug: cedula, contrato, riohs, epp, cap_primeros, ...
  estado        text not null default 'pendiente', -- pendiente | entregado
  fecha         date,
  vencimiento   date,                              -- solo los que caducan (cédula, licencia, 1° auxilios...)
  nota          text,
  media         jsonb default '[]'::jsonb,         -- archivos en R2
  autor         text,
  created_at    timestamptz default now()
);
create unique index if not exists rrhh_docs_uni on rrhh_docs (trabajador_id, tipo);

-- 2) Finiquitos
create table if not exists finiquitos (
  id            uuid primary key default gen_random_uuid(),
  trabajador_id uuid references trabajadores(id) on delete set null,
  nombre        text,                              -- se guarda el nombre por si se borra la ficha
  fecha         date,
  motivo        text,
  monto         numeric,
  nota          text,
  media         jsonb default '[]'::jsonb,
  autor         text,
  created_at    timestamptz default now()
);
create index if not exists finiquitos_fecha_idx on finiquitos (fecha desc);

-- 3) Remuneraciones: extras / descuentos / anticipos por trabajador y semana (lunes)
create table if not exists remuneracion_items (
  id            uuid primary key default gen_random_uuid(),
  trabajador_id uuid not null references trabajadores(id) on delete cascade,
  semana        date not null,                     -- lunes de la semana
  tipo          text not null,                     -- bono | descuento | otro
  concepto      text,
  monto         numeric not null default 0,
  autor         text,
  created_at    timestamptz default now()
);
create index if not exists remu_items_semana_idx on remuneracion_items (semana);

-- 4) Remuneraciones: monto contable ajustado a mano por trabajador + día (vs el real por horas)
create table if not exists remu_ajuste_dia (
  trabajador_id uuid not null references trabajadores(id) on delete cascade,
  fecha         date not null,
  monto         numeric not null default 0,
  obs           text,
  autor         text,
  updated_at    timestamptz default now(),
  primary key (trabajador_id, fecha)
);

-- RLS: equipo autenticado (la app controla quién ve cada pestaña)
alter table rrhh_docs          enable row level security;
alter table finiquitos         enable row level security;
alter table remuneracion_items enable row level security;
alter table remu_ajuste_dia    enable row level security;
drop policy if exists equipo_rrhh_docs on rrhh_docs;
create policy equipo_rrhh_docs on rrhh_docs for all to authenticated using (true) with check (true);
drop policy if exists equipo_finiquitos on finiquitos;
create policy equipo_finiquitos on finiquitos for all to authenticated using (true) with check (true);
drop policy if exists equipo_remu_items on remuneracion_items;
create policy equipo_remu_items on remuneracion_items for all to authenticated using (true) with check (true);
drop policy if exists equipo_remu_aj on remu_ajuste_dia;
create policy equipo_remu_aj on remu_ajuste_dia for all to authenticated using (true) with check (true);

notify pgrst, 'reload schema';
