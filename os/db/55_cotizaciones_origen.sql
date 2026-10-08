-- ============================================================
-- IS Performance OS - Cotizaciones: origen (de qué cotización se dividió)
-- Cuando una cotización se divide en una por vehículo, cada nueva guarda
-- el N° de la original para poder trazarla en el registro.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists origen_num integer;
notify pgrst, 'reload schema';
