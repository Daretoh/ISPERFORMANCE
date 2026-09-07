-- ============================================================
-- IS Performance OS - Cierre GM: excluir un vehiculo del mes
-- Cuando se elimina un vehiculo (que viene de Seguimiento) del cierre,
-- se marca excluido=true para que NO reaparezca en la tabla del mes.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gm_cierre add column if not exists excluido boolean default false;
notify pgrst, 'reload schema';
