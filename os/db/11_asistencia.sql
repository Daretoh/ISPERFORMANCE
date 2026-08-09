-- ============================================================
-- IS Performance OS - Asistencia (reloj de entrada/salida por RUT)
-- Trabajadores se identifican con los últimos 4 dígitos de su RUT.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

-- Trabajadores (nombre + últimos 4 del RUT para marcar)
create table if not exists trabajadores (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  rut4       text not null,          -- últimos 4 dígitos del RUT
  activo     boolean default true,
  created_at timestamptz default now()
);

-- Marcajes (cada entrada/salida)
create table if not exists asistencia (
  id         uuid primary key default gen_random_uuid(),
  nombre     text,                   -- nombre del trabajador (copiado al marcar)
  rut4       text,                   -- últimos 4 del RUT
  tipo       text,                   -- ENTRADA | SALIDA
  ts         timestamptz default now(),
  created_at timestamptz default now()
);

create index if not exists asistencia_rut4_idx on asistencia(rut4);
create index if not exists asistencia_ts_idx on asistencia(ts);

alter table trabajadores enable row level security;
alter table asistencia enable row level security;

drop policy if exists equipo_trab on trabajadores;
create policy equipo_trab on trabajadores for all to authenticated using (true) with check (true);

drop policy if exists equipo_asis on asistencia;
create policy equipo_asis on asistencia for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table asistencia; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table trabajadores; exception when duplicate_object then null; end;
end $$;
