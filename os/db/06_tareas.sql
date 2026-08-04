-- ============================================================
-- IS Performance OS - Tareas / Recordatorios
-- Pegar en Supabase > SQL Editor > Run (traduccion apagada). Seguro de re-ejecutar.
-- ============================================================

create table if not exists tareas (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null,
  detalle     text,
  fecha       date,
  hora        text,
  prioridad   text default 'MEDIA',    -- BAJA | MEDIA | ALTA
  responsable text,
  estado      text default 'PENDIENTE',-- PENDIENTE | HECHA
  created_at  timestamptz default now()
);

alter table tareas enable row level security;
drop policy if exists equipo_tareas on tareas;
create policy equipo_tareas on tareas for all to authenticated using (true) with check (true);
do $$ begin begin alter publication supabase_realtime add table tareas; exception when duplicate_object then null; end; end $$;
