-- ============================================================
-- IS Performance OS - Notificaciones push (paso 2)
-- Pegar en Supabase > SQL Editor > Run (traduccion apagada). Seguro de re-ejecutar.
-- ============================================================

-- Suscripciones push de cada dispositivo
create table if not exists push_subs (
  id         uuid primary key default gen_random_uuid(),
  email      text,
  nombre     text,
  endpoint   text unique not null,
  p256dh     text not null,
  auth       text not null,
  created_at timestamptz default now()
);

alter table push_subs enable row level security;
drop policy if exists equipo_push on push_subs;
create policy equipo_push on push_subs for all to authenticated using (true) with check (true);

-- Marca para no re-enviar la misma tarea
alter table tareas add column if not exists notificada boolean default false;
