-- ============================================================
-- IS Performance OS - Asistencia (reloj de entrada/salida por RUT)
-- Trabajadores se identifican con los últimos 4 dígitos de su RUT.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

-- Trabajadores (ficha: nombre, RUT completo, valor hora; rut4 = últimos 4 para marcar)
create table if not exists trabajadores (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  rut        text,                   -- RUT completo (lo ve solo admin)
  rut4       text not null,          -- últimos 4 dígitos (con lo que marca en el kiosco)
  valor_hora integer default 0,      -- $ por hora
  activo     boolean default true,
  created_at timestamptz default now()
);
-- por si la tabla ya existía sin estas columnas:
alter table trabajadores add column if not exists rut text;
alter table trabajadores add column if not exists valor_hora integer default 0;

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
