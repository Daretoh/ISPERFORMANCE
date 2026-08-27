-- ============================================================
-- IS Performance OS - IVA opcional en cotizaciones
-- Guarda si la cotización lleva IVA (19%) o no. Si no corres esto, la app
-- igual guarda la cotización (sin recordar el IVA) gracias a un reintento.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists con_iva boolean default false;
