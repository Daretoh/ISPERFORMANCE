-- ============================================================
-- IS Performance OS - Movimientos de stock (ingresos/salidas con fecha y referencia)
-- El ingreso guarda referencia: guía / factura / boleta, N°, proveedor, costo.
-- Alimenta la rotación/durabilidad. Pegar en Supabase > SQL Editor > Run.
-- ============================================================

create table if not exists movimientos (
  id           uuid primary key default gen_random_uuid(),
  producto_id  uuid not null,               -- producto/insumo del stock
  tipo         text not null,               -- ENTRADA | SALIDA | AJUSTE
  cantidad     integer default 1,
  doc_tipo     text,                         -- Guía | Factura | Boleta | Sin documento (solo ENTRADA)
  doc_num      text,                         -- N° del documento
  proveedor    text,                         -- de quién (solo ENTRADA)
  costo        integer default 0,            -- costo total del ingreso
  motivo       text,                         -- para qué / por qué (solo SALIDA)
  fecha        date default current_date,
  autor        text,
  created_at   timestamptz default now()
);

create index if not exists movimientos_producto_idx on movimientos(producto_id);
create index if not exists movimientos_fecha_idx on movimientos(fecha);

-- stock mínimo por producto (para avisar cuándo reponer)
alter table productos add column if not exists stock_min integer default 0;

alter table movimientos enable row level security;
drop policy if exists equipo_mov on movimientos;
create policy equipo_mov on movimientos for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table movimientos; exception when duplicate_object then null; end;
end $$;
