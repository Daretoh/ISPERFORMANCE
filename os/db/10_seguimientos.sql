-- ============================================================
-- IS Performance OS - Bitácora de seguimiento de contacto (CRM)
-- Registro por cliente: fecha, resultado (contactado/contestó/agendó...) y nota.
-- Pegar en Supabase > SQL Editor > Run (traducción DESACTIVADA). Seguro de re-ejecutar.
-- ============================================================

create table if not exists seguimientos (
  id         uuid primary key default gen_random_uuid(),
  clave      text not null,          -- misma clave del cliente (tabla clientes)
  fecha      date,                   -- fecha del contacto
  resultado  text,                   -- Contactado | Contestó | No contestó | Agendó | No interesado | Volver a contactar
  nota       text,                   -- detalle opcional
  autor      text,                   -- correo de quien registró
  created_at timestamptz default now()
);

alter table seguimientos enable row level security;
drop policy if exists equipo_seg on seguimientos;
create policy equipo_seg on seguimientos for all to authenticated using (true) with check (true);

create index if not exists seguimientos_clave_idx on seguimientos(clave);

do $$ begin
  begin alter publication supabase_realtime add table seguimientos; exception when duplicate_object then null; end;
end $$;
