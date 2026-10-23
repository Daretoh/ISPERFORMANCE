-- ============================================================
-- IS Performance OS - Costos: estado del costo (PENDIENTE / LISTO / PAGADO)
-- 'pagado' (sí/no) se mantiene: es true solo cuando estado = PAGADO.
-- Los costos que ya existen toman su estado desde 'pagado'.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists estado text;
update gastos set estado = case when pagado then 'PAGADO' else 'PENDIENTE' end where estado is null;
alter table gastos alter column estado set default 'PENDIENTE';
notify pgrst, 'reload schema';
