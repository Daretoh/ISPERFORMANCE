-- ============================================================
-- IS Performance OS - Cotizaciones: RUT y Giro del cliente
-- Para separar en la cotizacion los datos de EMPRESA (nombre, RUT,
-- giro) de los de CONTACTO (persona, correo, numero).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table cotizaciones add column if not exists cliente_rut  text;
alter table cotizaciones add column if not exists cliente_giro text;
notify pgrst, 'reload schema';
