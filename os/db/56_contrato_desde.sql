-- ============================================================
-- IS Performance OS - Fecha desde la que rige el contrato fijo.
-- Remuneraciones calcula como SPOT los meses anteriores a 'contrato_desde'
-- (así pasar a alguien a fijo no cambia los meses ya cerrados). Vacío = siempre fijo.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

alter table trabajadores add column if not exists contrato_desde date;

-- Jhettro Gamboa: spot hasta septiembre 2026; fijo con $750.000 desde octubre 2026.
update trabajadores
   set contrato_desde='2026-10-01', sueldo_desde='2026-10-01'
 where nombre ilike '%jhettro%';

notify pgrst, 'reload schema';

select nombre, tipo_pago, jornada_horas, contrato_desde, sueldo_base, sueldo_desde from trabajadores
 where nombre ilike '%enzo%castro%' or nombre ilike '%jhettro%';
