-- ============================================================
-- IS Performance OS - Cotizaciones: auditoría (quién editó y cuándo)
-- 'autor' ya existe = quien la creó. Agregamos quién hizo la última
-- edición y cuándo, para trazar cambios de la cotización/estado.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists editado_por text;
alter table cotizaciones add column if not exists updated_at  timestamptz;
notify pgrst, 'reload schema';
