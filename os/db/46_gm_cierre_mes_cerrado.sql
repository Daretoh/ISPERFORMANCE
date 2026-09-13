-- ============================================================
-- IS Performance OS - Cierre GM: cerrar (congelar) un mes
-- 'cerrado=true' congela la lista del mes: deja de auto-agregar
-- vehiculos nuevos de Seguimiento. Ver el PDF de prueba NO cierra
-- el mes; solo el boton "Emitir / cerrar" lo hace (y "Reabrir" lo
-- vuelve a abrir).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gm_cierre_mes add column if not exists cerrado boolean default false;
notify pgrst, 'reload schema';
