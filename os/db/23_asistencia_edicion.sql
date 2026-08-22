-- IS Performance OS - Editar marcajes de asistencia dejando registro (respaldo/auditoría)
-- Pegar en Supabase > SQL Editor > Run.
alter table asistencia add column if not exists ts_original    timestamptz; -- hora original antes de la 1a corrección
alter table asistencia add column if not exists motivo_edicion text;        -- por qué se cambió
alter table asistencia add column if not exists editado_por    text;        -- quién lo cambió
alter table asistencia add column if not exists editado_at     timestamptz; -- cuándo se cambió
