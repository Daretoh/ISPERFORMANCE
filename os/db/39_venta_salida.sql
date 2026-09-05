-- ============================================================
-- IS Performance OS - Venta desde Salida de materiales
-- Permite adjuntar el voucher a una accion (venta). Guarda los archivos
-- (en R2, igual que el resto) como referencia en la columna media.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table acciones add column if not exists media jsonb default '[]'::jsonb;
