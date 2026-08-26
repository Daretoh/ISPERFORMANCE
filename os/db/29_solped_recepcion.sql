-- ============================================================
-- IS Performance OS - Datos de recepción de una Solicitud (SolPed)
-- Al "Recibir" una solicitud se abre un formulario que pide referencia
-- (documento, N°, proveedor, costo, fecha). Estos campos lo guardan aunque
-- la solicitud no esté ligada a un producto del stock.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table solicitudes add column if not exists recep_doc    text;    -- tipo de documento (Guía/Factura/Boleta)
alter table solicitudes add column if not exists recep_ref    text;    -- N° de documento / referencia
alter table solicitudes add column if not exists recep_prov   text;    -- proveedor / de quién
alter table solicitudes add column if not exists recep_costo  integer; -- costo total
alter table solicitudes add column if not exists recep_fecha  date;    -- fecha de recepción
alter table solicitudes add column if not exists recibida_at  timestamptz;
alter table solicitudes add column if not exists recibida_por text;
