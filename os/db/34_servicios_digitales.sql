-- ============================================================
-- IS Performance OS - Servicios digitales / suscripciones recurrentes
-- (vista Gerencia, solo gerente). Web, hosting, redes, almacenamiento,
-- espacio de trabajo, publicidad. Con semáforo de cobros, costo por
-- empleado y generador de reporte.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists servicios_digitales (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,             -- ej: Hosting, Metricool, Google Workspace
  proveedor   text,                      -- HostingPlus, Google, NIC Chile…
  categoria   text,                      -- Redes / Web / Hosting / Almacenamiento / Espacio de trabajo / Publicidad / Otro
  plan        text,
  asignado_a  text default 'Empresa',    -- nombre del empleado, o 'Empresa' (compartido)
  costo       numeric default 0,         -- monto en su moneda
  moneda      text default 'CLP',        -- CLP | USD
  ciclo       text default 'Mensual',    -- Mensual | Anual | Variable
  dia_cobro   integer,                   -- día del mes del cobro (1-31), para mensuales
  prox_cobro  date,                      -- fecha exacta del próximo cobro (útil para anuales)
  autopago    boolean default false,     -- pago automático activado
  tarjeta     text,                      -- etiqueta de la tarjeta (ej "Visa ****6411")
  activo      boolean default true,
  orden       integer default 0,
  notas       text,
  created_at  timestamptz default now()
);

alter table servicios_digitales enable row level security;
drop policy if exists equipo_sdig on servicios_digitales;
create policy equipo_sdig on servicios_digitales for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table servicios_digitales; exception when duplicate_object then null; end;
end $$;
