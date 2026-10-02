-- ============================================================
-- IS Performance OS - Sueldo base de los trabajadores con contrato fijo.
-- Remuneraciones suma el sueldo al total del mes (desde el mes de vigencia)
-- y el CSV exportado lo trae en la columna "Sueldo base" (lo lee InnovaGestión).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

alter table trabajadores add column if not exists sueldo_base  numeric;  -- sueldo base mensual (solo fijos)
alter table trabajadores add column if not exists sueldo_desde date;     -- desde qué mes rige (1er día del mes)

-- Enzo Castro y Jhettro Gamboa: contrato fijo en IS Performance, $750.000 desde septiembre 2026.
-- (En InnovaGestión siguen como spot.) Si no tenían jornada, quedan con 9 h/día como el resto de los fijos.
update trabajadores
   set tipo_pago='contrato', sueldo_base=750000, sueldo_desde='2026-09-01', jornada_horas=coalesce(jornada_horas,9)
 where nombre ilike '%enzo%castro%' or nombre ilike '%jhettro%';

-- Revisión: deberían salir los dos con contrato y sueldo 750000.
select nombre, tipo_pago, jornada_horas, sueldo_base, sueldo_desde from trabajadores
 where nombre ilike '%enzo%castro%' or nombre ilike '%jhettro%';

notify pgrst, 'reload schema';
