-- ============================================================
-- IS Performance OS - Libro de movimientos / acciones (trazabilidad tipo SAP)
-- Cada accion (cobro, ingreso, salida, gasto, etc.) queda registrada aqui con
-- un N° de accion correlativo unico. La vista "Movimientos" busca sobre esto.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists acciones (
  id           uuid primary key default gen_random_uuid(),
  num          bigint,                 -- N° de accion correlativo (ej. 123 -> A-000123)
  tipo         text,                   -- COBRO | INGRESO | SALIDA | GASTO | COTIZACION | AJUSTE
  fecha        date,
  descripcion  text,
  monto        integer default 0,
  cantidad     integer,                -- para movimientos de stock
  ref_tipo     text,                   -- FACTURA | GUIA | BOLETA | ...
  ref_num      text,                   -- N° del documento
  proveedor    text,
  almacen      text,                   -- ubicacion/almacen codificado (para el modulo de almacenes)
  producto_id  text,
  vehiculo_id  text,
  autor        text,
  created_at   timestamptz default now()
);
create index if not exists acciones_num_idx   on acciones (num);
create index if not exists acciones_fecha_idx  on acciones (fecha);
create index if not exists acciones_tipo_idx   on acciones (tipo);

alter table acciones enable row level security;
drop policy if exists equipo_acciones on acciones;
create policy equipo_acciones on acciones for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table acciones; exception when duplicate_object then null; end;
end $$;
