-- ============================================================
-- IS Performance OS - Documentos electrónicos (boletas/facturas OpenFactura)
-- Guarda un registro liviano de cada documento traido desde OpenFactura,
-- para el resumen (dia/semana/mes) y para vincularlo a un vehiculo/servicio.
-- El PDF se pide en vivo por el puente; aca solo guardamos los datos + el vinculo.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists dte (
  id           uuid primary key default gen_random_uuid(),
  tipo         integer,            -- codigo SII: 39 boleta, 33 factura, 61 NC, 56 ND, etc.
  tipo_nombre  text,               -- "Boleta electronica", "Factura electronica", ...
  folio        bigint,             -- numero del documento
  rut_emisor   text,
  rut_receptor text,
  receptor     text,               -- nombre del receptor
  monto        integer default 0,  -- total
  fecha        date,               -- fecha de emision
  estado       text,               -- estado SII / OpenFactura
  vehiculo_id  text,               -- vinculo opcional a un vehiculo del OS
  clave_cli    text,               -- vinculo opcional al cliente (clave)
  raw          jsonb,              -- respuesta cruda por si necesitamos algo mas
  created_at   timestamptz default now(),
  unique (tipo, folio, rut_emisor)  -- evita duplicar el mismo documento
);

create index if not exists dte_fecha_idx on dte (fecha);
create index if not exists dte_veh_idx   on dte (vehiculo_id);

alter table dte enable row level security;
drop policy if exists equipo_dte on dte;
create policy equipo_dte on dte for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table dte; exception when duplicate_object then null; end;
end $$;
