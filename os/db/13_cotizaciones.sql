-- ============================================================
-- IS Performance OS - Cotizaciones (registro con N° automático)
-- Reemplaza el Excel manual. Pegar en Supabase > SQL Editor > Run.
-- ============================================================

create table if not exists cotizaciones (
  id             uuid primary key default gen_random_uuid(),
  numero         integer not null,          -- N° correlativo (automático)
  fecha          date default current_date,
  cliente_nombre text,
  cliente_tel    text,
  vehiculo       text,
  anio           text,
  items          jsonb default '[]'::jsonb, -- [{desc, cant, precio, descPct}]
  desc_adic_pct  numeric default 0,         -- descuento adicional %
  estado         text default 'ENVIADA',    -- ENVIADA | APROBADA | RECHAZADA
  autor          text,
  created_at     timestamptz default now()
);

create unique index if not exists cotizaciones_numero_idx on cotizaciones(numero);

alter table cotizaciones enable row level security;
drop policy if exists equipo_cotiz on cotizaciones;
create policy equipo_cotiz on cotizaciones for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table cotizaciones; exception when duplicate_object then null; end;
end $$;
