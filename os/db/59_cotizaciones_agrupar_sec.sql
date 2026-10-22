-- ============================================================
-- IS Performance OS - Cotizaciones: agrupar secciones en el PDF
-- Con esta columna en true, el PDF muestra cada sección como UNA
-- sola línea (nombre + total), sin los ítems. El editor sigue
-- mostrando el detalle completo. Los ítems sueltos (sin sección,
-- ej. Extras) siempre se muestran.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists agrupar_sec boolean default false;
notify pgrst, 'reload schema';
