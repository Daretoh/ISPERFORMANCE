-- ============================================================
-- IS Performance OS — Módulo CRM (clientes / observaciones)
-- Pegar en Supabase → SQL Editor → Run (traducción apagada).
-- Las métricas (total gastado, visitas, etc.) se calculan desde
-- 'vehiculos'; esta tabla guarda solo las observaciones por cliente.
-- ============================================================

create table if not exists clientes (
  clave         text primary key,   -- clave normalizada (teléfono o nombre)
  nombre        text,
  contacto      text,
  observaciones text,
  created_at    timestamptz default now()
);

alter table clientes enable row level security;
drop policy if exists equipo_clientes on clientes;
create policy equipo_clientes on clientes for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table clientes; exception when duplicate_object then null; end;
end $$;
