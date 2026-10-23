-- ============================================================
-- IS Performance OS - RRHH: horario base del trabajador fijo
-- Guarda entrada / salida (lun-jue) / salida viernes / colación
-- para calcular las HORAS EXTRA (solo se registra cuando sale más
-- tarde o trabaja fin de semana). JSON: {entrada,salida,salida_vie,colacion}
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table trabajadores add column if not exists horario jsonb;
notify pgrst, 'reload schema';
