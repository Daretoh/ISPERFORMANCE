-- IS Performance OS - Permisos de acción + rol por correo (Admin tipo ERP)
-- Pegar en Supabase > SQL Editor > Run.
alter table accesos add column if not exists permisos jsonb;  -- acciones permitidas (null = todas)
alter table accesos add column if not exists rol      text;   -- nombre del rol/plantilla asignado
