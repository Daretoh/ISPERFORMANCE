-- ============================================================
-- IS Performance OS - Cierre mensual GM: flujo por mes
-- Cotizado -> OC recibida -> Facturado -> Cobrado
-- Una fila por mes con el estado, numeros/fechas y adjuntos (R2).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists gm_cierre_mes (
  id             uuid primary key default gen_random_uuid(),
  mes            text not null unique,            -- 'YYYY-MM'
  estado         text default 'BORRADOR',         -- BORRADOR|COTIZADO|OC|FACTURADO|COBRADO
  iva            boolean default true,            -- afecto a IVA 19%
  cotiz_fecha    date,
  cotiz_total    integer,                         -- total (con IVA) al momento de cotizar
  oc_num         text,
  oc_fecha       date,
  oc_media       jsonb default '[]'::jsonb,        -- adjuntos R2 de la OC
  factura_num    text,
  factura_fecha  date,
  factura_media  jsonb default '[]'::jsonb,        -- adjuntos R2 de la factura
  cobro_fecha    date,
  cobro_monto    integer,
  notas          text,
  autor          text,
  created_at     timestamptz default now()
);
create unique index if not exists gm_cierre_mes_mes_idx on gm_cierre_mes (mes);

alter table gm_cierre_mes enable row level security;
drop policy if exists equipo_gm_cierre_mes on gm_cierre_mes;
create policy equipo_gm_cierre_mes on gm_cierre_mes for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table gm_cierre_mes; exception when duplicate_object then null; end;
end $$;
