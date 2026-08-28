-- ============================================================
-- IS Performance OS - Almacenes: stock por ubicacion (POS, Bodega, etc.)
-- Guarda el desglose de stock de cada producto por almacen codificado.
-- Ej: {"BOD": 10, "POS": 6}. Los traslados mueven cantidades entre almacenes.
-- Si no corres esto, la app igual funciona (guarda el stock total como antes).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table productos add column if not exists stock_alm jsonb;
