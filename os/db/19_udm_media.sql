-- IS Performance OS - Insumos: unidad de medida + adjuntar documentos a los movimientos
-- Pegar en Supabase > SQL Editor > Run.
alter table productos   add column if not exists udm text;
alter table movimientos add column if not exists media jsonb default '[]'::jsonb;
