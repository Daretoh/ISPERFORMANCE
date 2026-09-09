-- ============================================================
-- IS Performance OS - Vincular cuenta (login) con un trabajador
-- Para que en "Mis horas" cada usuario vea SOLO sus marcajes.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table accesos add column if not exists trabajador text;
notify pgrst, 'reload schema';
