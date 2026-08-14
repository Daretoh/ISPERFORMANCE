-- IS Performance OS - Stock: separar Insumos (consumibles internos) de Productos en venta
-- Pegar en Supabase > SQL Editor > Run.
alter table productos add column if not exists categoria text default 'VENTA';
-- (los productos existentes quedan como 'VENTA'; mueve los consumibles a 'INSUMO' desde la web)
