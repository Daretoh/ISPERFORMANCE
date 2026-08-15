-- IS Performance OS - Enlazar SolPed <-> Ingreso (trazabilidad tipo SAP)
-- Pegar en Supabase > SQL Editor > Run.

-- N° correlativo de la solicitud (registro)
alter table solicitudes add column if not exists numero integer;

-- El movimiento de ingreso puede referenciar la SolPed que lo originó
alter table movimientos add column if not exists solped_id  uuid;
alter table movimientos add column if not exists solped_num integer;
