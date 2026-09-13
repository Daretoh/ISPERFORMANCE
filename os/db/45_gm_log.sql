-- ============================================================
-- IS Performance OS - Cierre GM: historial de cambios
-- Registra cada vez que alguien agrega, quita o emite en el
-- cierre de un mes (quien, que y cuando). Solo se agrega, no
-- se borra: sirve para auditar "quien le metio mano".
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists gm_log (
  id          uuid primary key default gen_random_uuid(),
  mes         text not null,                 -- 'YYYY-MM'
  accion      text,                          -- agregó / quitó / emitió cotización / registró OC...
  detalle     text,                          -- vehiculo, N° cotizacion, monto, etc.
  autor       text,                          -- correo del usuario
  created_at  timestamptz default now()
);
create index if not exists gm_log_mes_idx on gm_log (mes, created_at desc);

alter table gm_log enable row level security;
drop policy if exists equipo_gm_log on gm_log;
create policy equipo_gm_log on gm_log for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table gm_log; exception when duplicate_object then null; end;
end $$;

notify pgrst, 'reload schema';
