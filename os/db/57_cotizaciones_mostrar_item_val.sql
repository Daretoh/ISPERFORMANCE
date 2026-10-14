-- ============================================================
-- IS Performance OS - Cotizaciones: mostrar valor por item (toggle)
-- Si está en false, el PDF muestra solo los items y el subtotal por
-- vehiculo (sin el valor de cada item). Util para GM / Catatumbo.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists mostrar_item_val boolean default true;
notify pgrst, 'reload schema';
