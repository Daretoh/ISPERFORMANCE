-- ============================================================
-- IS Performance OS — Abono (anticipo) y Tipo de venta
-- Pegar en Supabase → SQL Editor → Run (traducción apagada).
-- Solo AGREGA columnas; no toca datos existentes.
-- ============================================================

alter table vehiculos add column if not exists abono      integer default 0;
alter table vehiculos add column if not exists tipo_venta text default 'NORMAL';
