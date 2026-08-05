-- ============================================================
-- IS Performance OS - Tipo de cliente (Natural / Empresa) + datos de facturacion
-- Agrega a la ficha del cliente si es persona o empresa y sus datos para factura.
-- Pegar en Supabase > SQL Editor > Run (traduccion DESACTIVADA). Seguro de re-ejecutar.
-- ============================================================

alter table clientes add column if not exists tipo          text default 'NATURAL'; -- NATURAL | EMPRESA
alter table clientes add column if not exists rut           text;   -- RUT persona o empresa
alter table clientes add column if not exists razon_social  text;   -- razon social (empresa)
alter table clientes add column if not exists representante  text;   -- nombre del contacto/representante (empresa)
alter table clientes add column if not exists giro          text;   -- giro (empresa)
alter table clientes add column if not exists direccion     text;   -- direccion de facturacion
alter table clientes add column if not exists email         text;   -- correo para envio de boleta/factura
