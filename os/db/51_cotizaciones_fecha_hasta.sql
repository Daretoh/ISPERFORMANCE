-- ============================================================
-- IS Performance OS - Cotizaciones: fecha "hasta" (rango / semana)
-- Permite una cotizacion con Fecha o con Periodo (desde-hasta),
-- util para las cotizaciones semanales.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists fecha_hasta date;
notify pgrst, 'reload schema';
