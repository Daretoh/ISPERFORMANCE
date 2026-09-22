-- ============================================================
-- IS Performance OS - Cierre por cliente (cuenta corriente)
-- Agrupa varias cotizaciones de un mismo cliente (ej. Catatumbo:
-- N°155, 156, 163), registra sus abonos (varios, con fecha, medio
-- y comprobante) y muestra el saldo. Tambien guarda OC y factura.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists cierre_cliente (
  id             uuid primary key default gen_random_uuid(),
  nombre         text not null,                   -- nombre del cierre (ej. 'Catatumbo Energy')
  cliente        text,                            -- cliente (para sugerir sus cotizaciones)
  cotiz          jsonb default '[]'::jsonb,        -- [{numero, monto (null = total de la cotizacion), nota}]
  abonos         jsonb default '[]'::jsonb,        -- [{id, fecha, monto, medio, ref, nota, media:[], accion_id}]
  oc_num         text,
  oc_fecha       date,
  oc_media       jsonb default '[]'::jsonb,
  factura_num    text,
  factura_fecha  date,
  factura_media  jsonb default '[]'::jsonb,
  cerrado        boolean default false,           -- cuenta cerrada (saldada / archivada)
  notas          text,
  autor          text,
  created_at     timestamptz default now()
);

alter table cierre_cliente enable row level security;
drop policy if exists equipo_cierre_cliente on cierre_cliente;
create policy equipo_cierre_cliente on cierre_cliente for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table cierre_cliente; exception when duplicate_object then null; end;
end $$;

-- Primer cierre: Catatumbo Energy con sus cotizaciones 155, 156 y 163
insert into cierre_cliente (nombre, cliente, cotiz, autor)
select 'Catatumbo Energy', 'Catatumbo Energy', '[{"numero":155},{"numero":156},{"numero":163}]'::jsonb, 'sql'
where not exists (select 1 from cierre_cliente where nombre = 'Catatumbo Energy');

-- La 156 se importo con cliente 'N/A': es de Catatumbo
update cotizaciones set cliente_nombre = 'Catatumbo Energy'
where numero = 156 and (cliente_nombre is null or cliente_nombre = 'N/A');

notify pgrst, 'reload schema';
