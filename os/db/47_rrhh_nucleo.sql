-- ============================================================
-- IS Performance OS - Nucleo compartido RRHH + Remuneraciones
-- Enriquece la ficha del trabajador y crea el catalogo de cargos
-- (cargo -> trato; valor hora = trato/8). Lo usan los dos modulos.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================

-- 1) Ficha del trabajador: campos base (RRHH + Remuneraciones)
alter table trabajadores add column if not exists cargo         text;
alter table trabajadores add column if not exists estado        text default 'activo';   -- activo | inactivo
alter table trabajadores add column if not exists tipo_pago     text default 'hora';     -- hora (spot) | contrato (fijo)
alter table trabajadores add column if not exists jornada_horas numeric;                 -- horas/dia de jornada normal (solo contrato)
alter table trabajadores add column if not exists chofer        boolean default false;
alter table trabajadores add column if not exists fecha_ingreso date;
alter table trabajadores add column if not exists telefono      text;
alter table trabajadores add column if not exists email         text;
alter table trabajadores add column if not exists talla_botas   text;
alter table trabajadores add column if not exists talla_ropa    text;
alter table trabajadores add column if not exists afp           text;
alter table trabajadores add column if not exists salud         text;
alter table trabajadores add column if not exists direccion     text;
alter table trabajadores add column if not exists emergencia    text;
alter table trabajadores add column if not exists notas         text;
-- (el valor hora propio por persona sigue en la tabla 'valor_hora' que ya existe)

-- 2) Catalogo de cargos y tratos (trato = pago por jornada de 8h; valor hora = trato/8)
create table if not exists cargo (
  id          uuid primary key default gen_random_uuid(),
  nombre      text unique not null,
  trato       integer default 0,
  created_at  timestamptz default now()
);
alter table cargo enable row level security;
drop policy if exists equipo_cargo on cargo;
create policy equipo_cargo on cargo for all to authenticated using (true) with check (true);
do $$ begin
  begin alter publication supabase_realtime add table cargo; exception when duplicate_object then null; end;
end $$;

notify pgrst, 'reload schema';
