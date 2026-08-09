-- ============================================================
-- IS Performance OS - Accesos / permisos por correo (Panel Admin)
-- Define qué pestañas ve cada correo. Si un correo NO está aquí, ve todo.
-- El dueño (ventas@isperformance.cl) siempre ve todo (forzado en el código).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists accesos (
  email      text primary key,
  vistas     jsonb default '[]'::jsonb,   -- lista de vistas permitidas: ["agenda","clientes",...]
  updated_at timestamptz default now()
);

alter table accesos enable row level security;
drop policy if exists equipo_acc on accesos;
create policy equipo_acc on accesos for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table accesos; exception when duplicate_object then null; end;
end $$;
