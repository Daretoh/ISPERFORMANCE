-- ============================================================
-- IS Performance OS - Cotizaciones multi-vehiculo
-- Cada cotizacion puede tener varios vehiculos, cada uno con
-- patente, talla y sus propias lineas de servicio.
-- 'vehiculos' guarda ese arreglo; 'items' se mantiene (plano)
-- por compatibilidad con las cotizaciones antiguas.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists vehiculos jsonb default '[]'::jsonb;
notify pgrst, 'reload schema';
