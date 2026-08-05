-- ============================================================
-- IS Performance OS - Bandeja de avisos (notificaciones de actividad)
-- Cada accion (agendar, cambio de estado, nueva tarea) deja un aviso aqui;
-- el robot lo reparte por push y las apps abiertas lo muestran al instante.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists notificaciones (
  id           uuid primary key default gen_random_uuid(),
  titulo       text,
  cuerpo       text,
  destinatario text default 'ALL',   -- 'ALL' o el nombre del responsable
  origen       text,                 -- agendamiento | seguimiento | tarea
  autor        text,                 -- correo de quien la genero (para no auto-avisarse)
  enviada      boolean default false,-- ya repartida por push (robot)
  created_at   timestamptz default now()
);

alter table notificaciones enable row level security;
drop policy if exists equipo_notif on notificaciones;
create policy equipo_notif on notificaciones for all to authenticated using (true) with check (true);
do $$ begin begin alter publication supabase_realtime add table notificaciones; exception when duplicate_object then null; end; end $$;
