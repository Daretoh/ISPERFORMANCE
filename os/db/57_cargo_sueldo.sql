-- ============================================================
-- IS Performance OS - Sueldo fijo por cargo + jornada de Jhettro.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- (Requiere el SQL 47, que crea la tabla 'cargo'.)
-- ============================================================

-- Sueldo base mensual de los fijos de ese cargo (si la ficha no tiene un sueldo propio).
alter table cargo add column if not exists sueldo integer default 0;

-- Jhettro: fijo sin jornada => en su mes de contrato se le pagan todas sus horas además del sueldo
-- (con jornada de 9 h/día se le descontaban 9 h diarias).
update trabajadores set jornada_horas=null where nombre ilike '%jhettro%';

notify pgrst, 'reload schema';

select nombre, tipo_pago, jornada_horas, contrato_desde, sueldo_base, sueldo_desde from trabajadores where nombre ilike '%jhettro%';
