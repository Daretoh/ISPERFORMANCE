-- ============================================================
-- IS Performance OS - Referencia/documento en los costos (gastos)
-- Guarda el documento de respaldo (ej. "FAC 12345", "GD 678") de cada costo.
-- Si no corres esto, la app igual guarda el costo (sin la referencia).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists referencia text;
