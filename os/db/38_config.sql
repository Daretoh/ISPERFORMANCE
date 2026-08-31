-- ============================================================
-- IS Performance OS - Configuración general (clave/valor)
-- Guarda ajustes globales del OS, ej. el orden del menú (nav_orden).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists config (
  clave      text primary key,
  valor      jsonb,
  updated_at timestamptz default now()
);
alter table config enable row level security;
drop policy if exists equipo_config on config;
create policy equipo_config on config for all to authenticated using (true) with check (true);
