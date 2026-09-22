-- ============================================================
-- IS Performance OS - Cotizaciones: correo y contacto del cliente
-- Para mostrar en la cotizacion: Empresa / Numero / Correo / Contacto.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists cliente_correo   text;
alter table cotizaciones add column if not exists cliente_contacto text;
notify pgrst, 'reload schema';
