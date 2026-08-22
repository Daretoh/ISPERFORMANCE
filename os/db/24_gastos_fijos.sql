-- ============================================================
-- IS Performance OS - Gastos fijos recurrentes (vista Gerencia, solo gerente)
-- Se definen una vez y se descuentan cada mes en el resumen de costos.
-- Pegar en Supabase > SQL Editor > Run.
-- ============================================================

create table if not exists gastos_fijos (
  id         uuid primary key default gen_random_uuid(),
  concepto   text not null,
  monto      integer default 0,
  dia        integer,               -- día de pago del mes (1-31)
  activo     boolean default true,
  orden      integer default 0,
  autor      text,
  created_at timestamptz default now()
);

alter table gastos_fijos enable row level security;
drop policy if exists equipo_gfijos on gastos_fijos;
create policy equipo_gfijos on gastos_fijos for all to authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table gastos_fijos; exception when duplicate_object then null; end;
end $$;
