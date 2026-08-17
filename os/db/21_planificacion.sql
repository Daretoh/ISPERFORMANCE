-- ============================================================
-- IS Performance OS - Planificación (plan maestro: prioridad, responsable, vencimiento)
-- Pegar en Supabase > SQL Editor > Run.
-- ============================================================

create table if not exists planificacion (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null,
  area        text,                         -- WEB INTERNA | MARKETING | CLIENTES | ...
  prioridad   text default 'MEDIA',         -- ALTA | MEDIA | BAJA
  estado      text default 'PENDIENTE',     -- PENDIENTE | PROCESO | HECHO
  asignado    text,                         -- responsable (nombre)
  vence       date,
  descripcion text,
  costo       integer default 0,            -- costo estimado (CLP)
  orden       integer default 0,
  autor       text,
  created_at  timestamptz default now()
);

create index if not exists planificacion_vence_idx on planificacion(vence);
-- si ya creaste la tabla antes, esto agrega la columna de costo:
alter table planificacion add column if not exists costo integer default 0;

alter table planificacion enable row level security;
drop policy if exists equipo_plan on planificacion;
create policy equipo_plan on planificacion for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table planificacion; exception when duplicate_object then null; end;
end $$;
