-- ============================================================
-- IS Performance OS - Cierre mensual Guillermo Morales (flota)
-- Una fila por vehículo del cierre de un mes, con los servicios GM aplicados.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists gm_cierre (
  id           uuid primary key default gen_random_uuid(),
  mes          text not null,                 -- 'YYYY-MM'
  vehiculo_id  uuid,                          -- si viene de un vehículo del sistema (opcional)
  marca        text,
  modelo       text,
  patente      text,
  talla        text default 'M',
  items        jsonb default '{}'::jsonb,     -- { clave_servicio: cantidad }
  descuento    integer default 0,
  cobrado      boolean default false,
  notas        text,
  autor        text,
  created_at   timestamptz default now()
);
create index if not exists gm_cierre_mes_idx on gm_cierre (mes);

alter table gm_cierre enable row level security;
drop policy if exists equipo_gm_cierre on gm_cierre;
create policy equipo_gm_cierre on gm_cierre for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table gm_cierre; exception when duplicate_object then null; end;
end $$;
