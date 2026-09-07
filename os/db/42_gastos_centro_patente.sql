-- ============================================================
-- IS Performance OS - Costos: centro de costo + vehiculo (patente)
-- Permite asignar cada costo a un centro (Pintura, Taller, Oficina,
-- POS, Bodega, General) y opcionalmente a un vehiculo por patente.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists centro   text;
alter table gastos add column if not exists patente  text;

create index if not exists gastos_centro_idx  on gastos (centro);
create index if not exists gastos_patente_idx on gastos (patente);

notify pgrst, 'reload schema';
