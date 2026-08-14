-- ============================================================
-- IS Performance OS - Solicitudes de pedido (SolPed) / reabastecimiento
-- Pedir químicos, insumos, herramientas, repuestos cuando faltan.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists solicitudes (
  id           uuid primary key default gen_random_uuid(),
  item         text not null,               -- qué se pide (nombre)
  tipo         text,                         -- Químico | Insumo | Herramienta | Repuesto | Otro
  cantidad     text,                         -- ej: "2 bidones", "5 unidades"
  urgencia     text default 'Normal',        -- Normal | Urgente
  motivo       text,                         -- por qué / para qué
  solicitante  text,                         -- correo de quien pide
  estado       text default 'PENDIENTE',     -- PENDIENTE | APROBADA | COMPRADA | RECIBIDA
  producto_id  uuid,                         -- (opcional) vínculo a un producto del stock
  created_at   timestamptz default now()
);

create index if not exists solicitudes_estado_idx on solicitudes(estado);

alter table solicitudes enable row level security;
drop policy if exists equipo_solped on solicitudes;
create policy equipo_solped on solicitudes for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table solicitudes; exception when duplicate_object then null; end;
end $$;
