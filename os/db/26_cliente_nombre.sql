-- IS Performance OS - Nombre a mostrar del cliente (renombrar sin tocar los vehículos)
-- Pegar en Supabase > SQL Editor > Run.
alter table clientes add column if not exists nombre_mostrar text;
