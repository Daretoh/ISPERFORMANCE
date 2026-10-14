-- ============================================================
-- IS Performance OS - Costos: asegurar columnas vehiculo/referencia/centro
-- La patente del gasto no se guardaba porque faltaba la columna (SQL 42).
-- Esto deja patente + centro + referencia en la tabla gastos (idempotente).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists patente    text;
alter table gastos add column if not exists centro     text;
alter table gastos add column if not exists referencia text;
create index if not exists gastos_patente_idx on gastos (patente);
create index if not exists gastos_centro_idx  on gastos (centro);
notify pgrst, 'reload schema';
