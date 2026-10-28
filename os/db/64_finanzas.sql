-- ============================================================
-- IS Performance OS - SQL 64: Finanzas (igual que InnovaGestión, con el VEHÍCULO como unidad de costo)
-- Etapa 1: crea las tablas fin_* y COPIA los costos actuales (gastos, gastos_fijos) sin borrar ni cambiar nada.
-- Al final muestra un informe de cuadratura (antes vs después). Se puede volver a correr:
-- no duplica y trae lo nuevo que se haya cargado en Costos desde la última vez.
-- Pegar en Supabase > SQL Editor > Run.
--
-- Roles (fin_rol): revisa = Enzo, Cristopher y ventas@isperformance.cl (todo)
--                  carga  = Yocelyn, Luisa y Jorge (suben y clasifican; sin resultados, flujo ni balance)
-- Estados de un registro: pendiente (falta revisar) -> listo (con categoría y centro) -> pagado.
-- "Por pagar" = sin fecha de pago.
-- ============================================================

-- ---------- Roles ----------
create or replace function public.fin_email() returns text
language sql stable set search_path = public as $$ select lower(coalesce(auth.jwt()->>'email','')) $$;

create or replace function public.fin_rol() returns text
language sql stable security definer set search_path = public as $$
  select case
    when lower(coalesce(auth.jwt()->>'email','')) = any (array['enzo.castro@innovaservi.com','enzo.castro@innovaservi.cl','cristopher.ruiz@innovaservi.com','ventas@isperformance.cl']) then 'revisa'
    when lower(coalesce(auth.jwt()->>'email','')) = any (array['yocelyn.mansilla@innovaservi.cl','luisavelasquez1801@gmail.com','jorge.castro@innovaservi.com']) then 'carga'
  end;
$$;
create or replace function public.fin_beta() returns boolean
language sql stable security definer set search_path = public as $$ select public.fin_rol() = 'revisa' $$;
create or replace function public.fin_carga() returns boolean
language sql stable security definer set search_path = public as $$ select public.fin_rol() is not null $$;
revoke execute on function public.fin_rol() from public, anon;
revoke execute on function public.fin_beta() from public, anon;
revoke execute on function public.fin_carga() from public, anon;
grant execute on function public.fin_rol(), public.fin_beta(), public.fin_carga() to authenticated;

-- ---------- Tablas (mismas que Innova; aquí la unidad es el vehículo: patente + vehiculo_id) ----------
create table if not exists public.fin_categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique check (length(trim(nombre)) > 0),
  clase text not null check (clase in ('ingreso','costo_directo','operacion','administracion','financiero')),
  orden int not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.fin_centros (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique check (length(trim(nombre)) > 0),
  orden int not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.fin_recurrentes (
  id uuid primary key default gen_random_uuid(),
  concepto text not null check (length(trim(concepto)) > 0),
  categoria_id uuid not null references public.fin_categorias,
  centro_id uuid references public.fin_centros,
  proveedor text,
  proveedor_rut text,
  monto int not null check (monto >= 0),
  ciclo text not null default 'mensual' check (ciclo in ('mensual','semestral','anual')),
  dia int check (dia between 1 and 31),
  mes_pago int check (mes_pago between 1 and 12),
  doc_tipo text not null default 'factura' check (doc_tipo in ('factura','boleta','otro','sin')),
  desde text not null default to_char(now() at time zone 'America/Santiago','YYYY-MM') check (desde ~ '^\d{4}-\d{2}$'),
  hasta text check (hasta ~ '^\d{4}-\d{2}$'),
  notas text,
  orden int not null default 0,
  activo boolean not null default true,
  gasto_fijo_id uuid unique,                                   -- de dónde se copió (gastos_fijos)
  created_at timestamptz not null default now(),
  created_by text default public.fin_email(),
  check (ciclo = 'mensual' or mes_pago is not null),
  check (hasta is null or hasta >= desde)
);
create table if not exists public.fin_cuentas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  tipo text not null default 'banco' check (tipo in ('banco','tarjeta','caja','otro')),
  orden int not null default 0,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.fin_saldos (
  id uuid primary key default gen_random_uuid(),
  cuenta_id uuid not null references public.fin_cuentas on delete cascade,
  fecha date not null default current_date,
  saldo bigint not null,
  created_at timestamptz not null default now(),
  created_by text default public.fin_email(),
  unique (cuenta_id, fecha)
);
create table if not exists public.fin_proveedores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  rut text unique,
  modalidad text not null default 'por_compra' check (modalidad in ('por_compra','mensual')),
  plazo_dias int not null default 30 check (plazo_dias between 0 and 180),
  contacto text,
  notas text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by text default public.fin_email()
);
create table if not exists public.fin_registros (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('gasto','ingreso')),
  fecha date not null default current_date,
  concepto text not null check (length(trim(concepto)) > 0),
  categoria_id uuid references public.fin_categorias,
  centro_id uuid references public.fin_centros,
  patente text,                                                -- vehículo (ABCD-12), como en Costos
  vehiculo_id uuid,                                            -- vehiculos.id, si se sabe a qué visita corresponde
  faena text,                                                  -- (Innova) no se usa en ISP
  tercero text,
  tercero_rut text,
  proveedor_id uuid references public.fin_proveedores on delete set null,
  doc_tipo text not null default 'sin' check (doc_tipo in ('factura','boleta','guia','nota_credito','otro','sin')),
  doc_numero text,
  neto bigint not null default 0,
  iva bigint not null default 0,
  exento bigint not null default 0,
  total bigint not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','listo','pagado')),
  vence date,
  fecha_pago date,
  cuenta_id uuid references public.fin_cuentas on delete set null,
  recurrente_id uuid references public.fin_recurrentes on delete set null,
  periodo text check (periodo ~ '^\d{4}-\d{2}$'),
  declarable boolean not null default true,
  gasto_id uuid unique,                                        -- costo de origen en la tabla gastos (traspaso)
  notas text,
  created_at timestamptz not null default now(),
  created_by text default public.fin_email(),
  updated_at timestamptz,
  updated_by text,
  deleted_at timestamptz,
  check (neto + iva + exento = total),
  check (estado <> 'pagado' or fecha_pago is not null),
  -- lo traspasado de Costos conserva su estado aunque no tenga categoría (antes no existía)
  check (estado = 'pendiente' or gasto_id is not null or (categoria_id is not null and centro_id is not null)),
  check (recurrente_id is null or periodo is not null)
);
create index if not exists fin_registros_fecha_idx on public.fin_registros (fecha desc) where deleted_at is null;
create index if not exists fin_registros_patente_idx on public.fin_registros (patente) where deleted_at is null;
create index if not exists fin_registros_porpagar_idx on public.fin_registros (tipo, vence) where deleted_at is null and fecha_pago is null;
create unique index if not exists fin_registros_recurrente_mes on public.fin_registros (recurrente_id, periodo) where deleted_at is null;
create table if not exists public.fin_pagos (
  id uuid primary key default gen_random_uuid(),
  fecha date not null default current_date,
  monto bigint not null check (monto > 0),
  medio text not null default 'transferencia' check (medio in ('transferencia','efectivo','debito','credito','cheque','otro')),
  proveedor_id uuid references public.fin_proveedores on delete set null,
  tercero text,
  cuenta_id uuid references public.fin_cuentas on delete set null,
  estado text not null default 'por_validar' check (estado in ('por_validar','validado','rechazado')),
  notas text, motivo_rechazo text,
  created_at timestamptz not null default now(),
  created_by text default public.fin_email(),
  validado_por text, validado_en timestamptz, deleted_at timestamptz
);
create table if not exists public.fin_pago_registros (
  pago_id uuid not null references public.fin_pagos on delete cascade,
  registro_id uuid not null references public.fin_registros on delete cascade,
  monto bigint not null check (monto > 0),
  created_at timestamptz not null default now(),
  primary key (pago_id, registro_id)
);
create table if not exists public.fin_adjuntos (
  id uuid primary key default gen_random_uuid(),
  registro_id uuid references public.fin_registros on delete cascade,
  pago_id uuid references public.fin_pagos on delete cascade,
  url text not null,
  nombre text not null default 'archivo',
  tipo text not null default 'doc',
  tamano int,
  autor text default public.fin_email(),
  created_at timestamptz not null default now(),
  check ((registro_id is null) <> (pago_id is null))
);
create index if not exists fin_adjuntos_reg_idx on public.fin_adjuntos (registro_id);
create table if not exists public.fin_deudas (
  id uuid primary key default gen_random_uuid(),
  tipo text not null default 'prestamo' check (tipo in ('prestamo','leasing','linea','otro')),
  acreedor text not null check (length(trim(acreedor)) > 0),
  saldo bigint not null default 0, fecha_saldo date not null default current_date,
  cuota bigint not null default 0, dia int check (dia between 1 and 31), hasta date,
  notas text, activo boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.fin_prestamos_grupo (
  id uuid primary key default gen_random_uuid(),
  fecha date not null default current_date,
  sentido text not null check (sentido in ('innova_a_isp','isp_a_innova')),
  monto bigint not null check (monto > 0),
  concepto text not null check (length(trim(concepto)) > 0),
  notas text, created_at timestamptz not null default now(), created_by text default public.fin_email(), deleted_at timestamptz
);
create table if not exists public.fin_cierres (
  periodo text primary key check (periodo ~ '^\d{4}-\d{2}$'),
  resultado jsonb not null default '{}'::jsonb,
  cerrado_por text default public.fin_email(),
  cerrado_en timestamptz not null default now()
);
create table if not exists public.fin_config (
  clave text primary key, valor jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now()
);

-- ---------- RLS: revisa todo; carga sube y clasifica ----------
do $$
declare t text;
begin
  foreach t in array array['fin_categorias','fin_centros','fin_recurrentes','fin_cuentas','fin_saldos','fin_proveedores','fin_registros','fin_pagos','fin_pago_registros','fin_adjuntos','fin_deudas','fin_prestamos_grupo','fin_cierres','fin_config'] loop
    execute format('alter table public.%1$s enable row level security', t);
    execute format('drop policy if exists %1$s_sel on public.%1$s', t);
    execute format('drop policy if exists %1$s_ins on public.%1$s', t);
    execute format('drop policy if exists %1$s_upd on public.%1$s', t);
    execute format('drop policy if exists %1$s_del on public.%1$s', t);
    execute format('create policy %1$s_sel on public.%1$s for select to authenticated using (public.fin_beta())', t);
    execute format('create policy %1$s_ins on public.%1$s for insert to authenticated with check (public.fin_beta())', t);
    execute format('create policy %1$s_upd on public.%1$s for update to authenticated using (public.fin_beta()) with check (public.fin_beta())', t);
    if t not in ('fin_registros','fin_prestamos_grupo','fin_pagos') then
      execute format('create policy %1$s_del on public.%1$s for delete to authenticated using (public.fin_beta())', t);
    end if;
    execute format('revoke all on public.%1$s from anon', t);
    execute format('revoke truncate, references, trigger on public.%1$s from authenticated', t);
  end loop;
end $$;
revoke delete on public.fin_registros, public.fin_prestamos_grupo, public.fin_pagos from authenticated;
-- lo que ve y hace quien carga
drop policy if exists fin_categorias_sel_carga on public.fin_categorias;
create policy fin_categorias_sel_carga on public.fin_categorias for select to authenticated using (public.fin_carga());
drop policy if exists fin_centros_sel_carga on public.fin_centros;
create policy fin_centros_sel_carga on public.fin_centros for select to authenticated using (public.fin_carga());
drop policy if exists fin_registros_sel_carga on public.fin_registros;
create policy fin_registros_sel_carga on public.fin_registros for select to authenticated using (public.fin_carga());
drop policy if exists fin_registros_ins_carga on public.fin_registros;
create policy fin_registros_ins_carga on public.fin_registros for insert to authenticated with check (public.fin_carga() and estado = 'pendiente' and recurrente_id is null);
drop policy if exists fin_registros_upd_carga on public.fin_registros;
create policy fin_registros_upd_carga on public.fin_registros for update to authenticated
  using (public.fin_rol() = 'carga' and estado = 'pendiente' and created_by = public.fin_email())
  with check (public.fin_rol() = 'carga' and estado = 'pendiente' and created_by = public.fin_email());
drop policy if exists fin_proveedores_sel_carga on public.fin_proveedores;
create policy fin_proveedores_sel_carga on public.fin_proveedores for select to authenticated using (public.fin_carga());
drop policy if exists fin_proveedores_ins_carga on public.fin_proveedores;
create policy fin_proveedores_ins_carga on public.fin_proveedores for insert to authenticated with check (public.fin_carga());
drop policy if exists fin_pagos_sel_carga on public.fin_pagos;
create policy fin_pagos_sel_carga on public.fin_pagos for select to authenticated using (public.fin_carga());
drop policy if exists fin_pagos_ins_carga on public.fin_pagos;
create policy fin_pagos_ins_carga on public.fin_pagos for insert to authenticated with check (public.fin_carga() and estado = 'por_validar' and validado_por is null);
drop policy if exists fin_pagos_upd_carga on public.fin_pagos;
create policy fin_pagos_upd_carga on public.fin_pagos for update to authenticated
  using (public.fin_rol() = 'carga' and estado = 'por_validar' and created_by = public.fin_email())
  with check (public.fin_rol() = 'carga' and estado = 'por_validar' and validado_por is null and created_by = public.fin_email());
drop policy if exists fin_pago_registros_sel_carga on public.fin_pago_registros;
create policy fin_pago_registros_sel_carga on public.fin_pago_registros for select to authenticated using (public.fin_carga());
drop policy if exists fin_pago_registros_ins_carga on public.fin_pago_registros;
create policy fin_pago_registros_ins_carga on public.fin_pago_registros for insert to authenticated
  with check (exists (select 1 from public.fin_pagos p where p.id = pago_id and p.estado = 'por_validar' and p.created_by = public.fin_email() and public.fin_carga()));
drop policy if exists fin_pago_registros_del_carga on public.fin_pago_registros;
create policy fin_pago_registros_del_carga on public.fin_pago_registros for delete to authenticated
  using (exists (select 1 from public.fin_pagos p where p.id = pago_id and p.estado = 'por_validar' and p.created_by = public.fin_email() and public.fin_carga()));
drop policy if exists fin_adjuntos_sel_carga on public.fin_adjuntos;
create policy fin_adjuntos_sel_carga on public.fin_adjuntos for select to authenticated using (public.fin_carga());
drop policy if exists fin_adjuntos_ins_carga on public.fin_adjuntos;
create policy fin_adjuntos_ins_carga on public.fin_adjuntos for insert to authenticated with check (public.fin_carga() and autor = public.fin_email());
drop policy if exists fin_adjuntos_del_carga on public.fin_adjuntos;
create policy fin_adjuntos_del_carga on public.fin_adjuntos for delete to authenticated using (public.fin_carga() and autor = public.fin_email());

-- ---------- Reglas (iguales a Innova) ----------
create or replace function public.fin_registros_bu() returns trigger
language plpgsql set search_path = public as $$
declare cerrado boolean;
begin
  if tg_op = 'UPDATE' then
    new.updated_at := now(); new.updated_by := public.fin_email();
    new.created_by := old.created_by; new.created_at := old.created_at;
  end if;
  if new.patente is not null then new.patente := nullif(upper(regexp_replace(new.patente, '[^A-Za-z0-9-]', '', 'g')), ''); end if;
  if new.estado = 'listo' and new.fecha_pago is not null then new.estado := 'pagado'; end if;
  if new.estado = 'pagado' and new.fecha_pago is null then new.fecha_pago := current_date; end if;
  if tg_op = 'INSERT' then
    select exists(select 1 from public.fin_cierres c where c.periodo = to_char(new.fecha,'YYYY-MM')) into cerrado;
    if cerrado and new.gasto_id is null and new.recurrente_id is null then
      raise exception 'El mes % está cerrado: anótalo en el mes siguiente o reabre el mes', to_char(new.fecha,'MM-YYYY');
    end if;
  elsif (new.total, new.neto, new.fecha, new.categoria_id, new.centro_id, new.tipo, new.deleted_at)
        is distinct from (old.total, old.neto, old.fecha, old.categoria_id, old.centro_id, old.tipo, old.deleted_at) then
    select exists(select 1 from public.fin_cierres c where c.periodo in (to_char(new.fecha,'YYYY-MM'), to_char(old.fecha,'YYYY-MM'))) into cerrado;
    if cerrado then raise exception 'El mes está cerrado: reabre el mes para cambiar montos, fechas o categorías'; end if;
  end if;
  return new;
end $$;
drop trigger if exists fin_registros_bu on public.fin_registros;
create trigger fin_registros_bu before insert or update on public.fin_registros for each row execute function public.fin_registros_bu();

create or replace function public.fin_registros_proveedor() returns trigger
language plpgsql security definer set search_path = public as $$
declare pid uuid; r text;
begin
  if new.tipo <> 'gasto' or new.proveedor_id is not null then return new; end if;
  r := nullif(upper(regexp_replace(coalesce(new.tercero_rut,''), '[^0-9kK-]', '', 'g')), '');
  if r is null then
    if nullif(trim(coalesce(new.tercero,'')),'') is not null then
      select id into pid from fin_proveedores where lower(nombre) = lower(trim(new.tercero)) limit 1; new.proveedor_id := pid;
    end if;
    return new;
  end if;
  select id into pid from fin_proveedores where rut = r;
  if pid is null then
    insert into fin_proveedores (nombre, rut, created_by) values (coalesce(nullif(trim(new.tercero),''), r), r, coalesce(new.created_by,'sistema'))
    on conflict (rut) do nothing returning id into pid;
    if pid is null then select id into pid from fin_proveedores where rut = r; end if;
  end if;
  new.proveedor_id := pid;
  return new;
end $$;
revoke execute on function public.fin_registros_proveedor() from public, anon, authenticated;
drop trigger if exists fin_registros_proveedor on public.fin_registros;
create trigger fin_registros_proveedor before insert or update of tercero, tercero_rut, proveedor_id on public.fin_registros for each row execute function public.fin_registros_proveedor();

create or replace function public.fin_recalc_registro(p_reg uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r fin_registros; pagado bigint; ult date; cta uuid; n int;
begin
  select * into r from fin_registros where id = p_reg; if not found then return; end if;
  select count(*), coalesce(sum(l.monto) filter (where p.estado = 'validado'),0), max(p.fecha) filter (where p.estado = 'validado'),
         (array_agg(p.cuenta_id order by p.fecha desc) filter (where p.estado = 'validado' and p.cuenta_id is not null))[1]
    into n, pagado, ult, cta
  from fin_pago_registros l join fin_pagos p on p.id = l.pago_id and p.deleted_at is null where l.registro_id = p_reg;
  if n = 0 then return; end if;
  if pagado >= abs(r.total) and r.fecha_pago is null then
    update fin_registros set fecha_pago = ult, cuenta_id = coalesce(cuenta_id, cta),
           estado = case when categoria_id is not null and centro_id is not null then 'pagado' else estado end where id = p_reg;
  elsif pagado < abs(r.total) and r.fecha_pago is not null then
    update fin_registros set fecha_pago = null, estado = case when estado = 'pagado' then 'listo' else estado end where id = p_reg;
  end if;
end $$;
revoke execute on function public.fin_recalc_registro(uuid) from public, anon, authenticated;
create or replace function public.fin_pagos_recalc() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_table_name = 'fin_pago_registros' then perform fin_recalc_registro(coalesce(new.registro_id, old.registro_id)); return coalesce(new, old); end if;
  if tg_op = 'UPDATE' and new.estado = 'validado' and old.estado <> 'validado' then new.validado_por := public.fin_email(); new.validado_en := now(); end if;
  if tg_op = 'UPDATE' and new.estado <> 'validado' and old.estado = 'validado' then new.validado_por := null; new.validado_en := null; end if;
  return new;
end $$;
create or replace function public.fin_pagos_despues() returns trigger
language plpgsql security definer set search_path = public as $$
declare x record;
begin
  if (new.estado, new.monto, new.fecha, new.deleted_at, new.cuenta_id) is distinct from (old.estado, old.monto, old.fecha, old.deleted_at, old.cuenta_id) then
    for x in select registro_id from fin_pago_registros where pago_id = new.id loop perform fin_recalc_registro(x.registro_id); end loop;
  end if;
  return new;
end $$;
revoke execute on function public.fin_pagos_recalc() from public, anon, authenticated;
revoke execute on function public.fin_pagos_despues() from public, anon, authenticated;
drop trigger if exists fin_pagos_bu on public.fin_pagos;
create trigger fin_pagos_bu before update on public.fin_pagos for each row execute function public.fin_pagos_recalc();
drop trigger if exists fin_pagos_au on public.fin_pagos;
create trigger fin_pagos_au after update on public.fin_pagos for each row execute function public.fin_pagos_despues();
drop trigger if exists fin_pago_registros_aiud on public.fin_pago_registros;
create trigger fin_pago_registros_aiud after insert or update or delete on public.fin_pago_registros for each row execute function public.fin_pagos_recalc();

-- Gastos fijos del mes (desde octubre 2026; nunca meses pasados)
create or replace function public.fin_generar_mes(p_periodo text default null) returns int
language plpgsql set search_path = public as $$
declare per text := coalesce(p_periodo, to_char(now() at time zone 'America/Santiago','YYYY-MM')); y int; m int; ultimo int; n int;
begin
  if per !~ '^\d{4}-\d{2}$' then raise exception 'Periodo inválido: %', per; end if;
  if per < '2026-10' or per < to_char(now() at time zone 'America/Santiago','YYYY-MM') then return 0; end if;
  if exists(select 1 from fin_cierres where periodo = per) then return 0; end if;
  y := split_part(per,'-',1)::int; m := split_part(per,'-',2)::int;
  ultimo := extract(day from (make_date(y,m,1) + interval '1 month - 1 day'))::int;
  insert into fin_registros (tipo, fecha, concepto, categoria_id, centro_id, tercero, tercero_rut, doc_tipo, neto, iva, exento, total, estado, vence, recurrente_id, periodo, created_by)
  select 'gasto', make_date(y, m, least(coalesce(r.dia,1), ultimo)), r.concepto, r.categoria_id, r.centro_id, r.proveedor, r.proveedor_rut, r.doc_tipo,
         case when r.doc_tipo = 'factura' then round(r.monto/1.19) else r.monto end,
         case when r.doc_tipo = 'factura' then r.monto - round(r.monto/1.19) else 0 end, 0, r.monto,
         case when r.centro_id is null then 'pendiente' else 'listo' end,
         make_date(y, m, least(coalesce(r.dia,1), ultimo)), r.id, per, 'gasto fijo'
  from fin_recurrentes r
  where r.activo and r.monto > 0 and r.desde <= per and (r.hasta is null or r.hasta >= per)
    and (r.ciclo = 'mensual' or (r.ciclo = 'anual' and r.mes_pago = m) or (r.ciclo = 'semestral' and (r.mes_pago = m or ((r.mes_pago + 5) % 12) + 1 = m)))
  on conflict (recurrente_id, periodo) where deleted_at is null do nothing;
  get diagnostics n = row_count; return n;
end $$;
revoke execute on function public.fin_generar_mes(text) from public, anon;
grant execute on function public.fin_generar_mes(text) to authenticated;

-- ---------- Datos base ----------
insert into public.fin_categorias (nombre, clase, orden) values
  ('Servicios','ingreso',10), ('Venta de productos','ingreso',11), ('Otros ingresos','ingreso',12),
  ('Personal de taller','costo_directo',20), ('Materiales e insumos','costo_directo',21), ('EPP','costo_directo',22),
  ('Combustible y peajes','costo_directo',23), ('Arriendo de equipos','costo_directo',24), ('Subcontratos','costo_directo',25),
  ('Viáticos y colaciones','costo_directo',26), ('Estacionamientos','costo_directo',27),
  ('Herramientas','operacion',31), ('Capacitación','operacion',32), ('Publicidad y redes','operacion',33),
  ('Arriendo','administracion',40), ('Servicios básicos','administracion',41), ('Software y servicios digitales','administracion',42),
  ('Contabilidad y legal','administracion',43), ('Gestión (sueldos administrativos)','administracion',44), ('Otros gastos de administración','administracion',45),
  ('Intereses','financiero',50), ('Comisiones bancarias','financiero',51)
on conflict (nombre) do nothing;
insert into public.fin_centros (nombre, orden) values ('General',1), ('D&P',2), ('Taller',3), ('Oficina',4)
on conflict (nombre) do nothing;

-- ---------- TRASPASO: Costos (gastos) -> fin_registros. No borra ni cambia la tabla gastos ----------
insert into public.fin_registros (tipo, fecha, concepto, categoria_id, centro_id, patente, tercero, tercero_rut, doc_tipo, doc_numero,
                                  neto, iva, exento, total, estado, fecha_pago, gasto_id, notas, created_at, created_by)
select 'gasto', g.fecha, coalesce(nullif(trim(g.concepto),''), 'Costo'),
       case when upper(coalesce(g.tipo,'')) = 'FIJO' and g.concepto ilike '%arriendo%' then (select id from public.fin_categorias where nombre='Arriendo') end,
       (select c.id from public.fin_centros c where lower(c.nombre) = lower(trim(coalesce(g.centro,'')))),
       nullif(g.patente,''), nullif(g.razon_social,''), nullif(g.rut_emisor,''),
       x.dt, coalesce(nullif(g.folio,''), nullif(regexp_replace(coalesce(g.referencia,''), '^\s*[A-Za-z]+\.?\s*', ''), '')),
       x.n, x.i, x.tot - x.n - x.i, x.tot,
       x.est, case when x.est = 'pagado' or g.pagado then coalesce(g.fecha_pago, g.fecha) end,
       g.id,
       trim(both ' ·' from concat_ws(' · ', 'Traspasado de Costos', 'tipo ' || nullif(g.tipo,''), nullif(g.referencia,''), case when g.mov_id is not null then 'ingreso de inventario' end)),
       coalesce(g.created_at, now()), coalesce(nullif(g.subido_por,''), 'traspaso')
from public.gastos g
cross join lateral (
  select coalesce(g.monto,0)::bigint tot,
         case when g.neto is not null and g.iva is not null and g.neto + g.iva <= coalesce(g.monto,0) then g.neto::bigint else coalesce(g.monto,0)::bigint end n,
         case when g.neto is not null and g.iva is not null and g.neto + g.iva <= coalesce(g.monto,0) then g.iva::bigint else 0 end i,
         case when g.tipo_dte in (33,34) then 'factura' when g.tipo_dte in (39,41) then 'boleta' when g.tipo_dte = 61 then 'nota_credito' when g.tipo_dte = 52 then 'guia'
              when g.tipo_dte = 0 then 'otro'
              when g.referencia ~* '^\s*(FAC|FA|FE|FACT)' then 'factura' when g.referencia ~* '^\s*(BOL|BO|BE)' then 'boleta' when g.referencia ~* '^\s*(GD|GUIA)' then 'guia'
              else 'sin' end dt,
         case when g.pagado or upper(coalesce(g.estado,'')) = 'PAGADO' then 'pagado' when upper(coalesce(g.estado,'')) = 'LISTO' then 'listo' else 'pendiente' end est
) x
where not exists (select 1 from public.fin_registros r where r.gasto_id = g.id);

-- Fotos y documentos de cada costo (media: texto con la URL o {url, nombre})
insert into public.fin_adjuntos (registro_id, url, nombre, tipo, autor)
select r.id, u.url, coalesce(nullif(u.nombre,''), 'documento'),
       case when u.url ~* '\.(xml|pdf)(\?|$)' then 'doc' else 'image' end, coalesce(nullif(g.subido_por,''), 'traspaso')
from public.gastos g
join public.fin_registros r on r.gasto_id = g.id
cross join lateral jsonb_array_elements(case when jsonb_typeof(g.media) = 'array' then g.media else '[]'::jsonb end) e
cross join lateral (select case when jsonb_typeof(e) = 'string' then e #>> '{}' else e->>'url' end url,
                           case when jsonb_typeof(e) = 'object' then coalesce(e->>'nombre', e->>'name') end nombre) u
where coalesce(u.url,'') <> '' and not exists (select 1 from public.fin_adjuntos a where a.registro_id = r.id and a.url = u.url);

-- Gastos fijos (plantilla de Gerencia) -> fin_recurrentes (desde octubre 2026)
insert into public.fin_recurrentes (concepto, categoria_id, centro_id, monto, dia, activo, orden, desde, gasto_fijo_id, notas, created_by)
select f.concepto,
       (select id from public.fin_categorias where nombre = case
          when f.concepto ilike '%arriendo%' then 'Arriendo'
          when f.concepto ~* 'internet|luz|agua|gas|tel[eé]fono' then 'Servicios básicos'
          when f.concepto ~* 'contab|asesor|legal|buk|remunera' then 'Contabilidad y legal'
          when f.concepto ~* 'redes|marketing|publicidad|ads' then 'Publicidad y redes'
          when f.concepto ~* 'software|hosting|dominio|app' then 'Software y servicios digitales'
          else 'Otros gastos de administración' end),
       (select id from public.fin_centros where nombre = 'General'),
       coalesce(f.monto,0), f.dia, coalesce(f.activo, true), coalesce(f.orden,0), '2026-10', f.id, 'Traspasado de Gerencia (gastos fijos)', 'traspaso'
from public.gastos_fijos f
where nullif(trim(f.concepto),'') is not null and not exists (select 1 from public.fin_recurrentes r where r.gasto_fijo_id = f.id);

-- ---------- Resumen del mes (misma vista que Innova, para la vista Grupo) ----------
create or replace view public.fin_resumen_mes with (security_invoker = true) as
with r as (
  select to_char(g.fecha,'YYYY-MM') periodo, g.tipo, c.clase,
         case when g.doc_tipo in ('factura','nota_credito') then g.neto + g.exento else g.total end monto, g.estado, g.centro_id
  from public.fin_registros g left join public.fin_categorias c on c.id = g.categoria_id where g.deleted_at is null
)
select 'IS PERFORMANCE'::text empresa, p.periodo,
  coalesce(sum(r.monto) filter (where r.tipo='ingreso'),0) ventas,
  coalesce(sum(r.monto) filter (where r.tipo='gasto' and r.clase='costo_directo'),0)
    + coalesce((select (k.resultado->>'personal')::bigint from public.fin_cierres k where k.periodo = p.periodo),0) costo_directo,
  coalesce(sum(r.monto) filter (where r.tipo='gasto' and r.clase in ('operacion','administracion')),0) fijos,
  coalesce(sum(r.monto) filter (where r.tipo='gasto' and r.clase='financiero'),0) financiero,
  coalesce(sum(r.monto) filter (where r.tipo='gasto' and r.clase is null),0) sin_categoria,
  count(*) filter (where r.estado='pendiente') pendientes,
  count(*) filter (where r.tipo='gasto' and r.centro_id is null) sin_centro,
  exists(select 1 from public.fin_cierres k where k.periodo = p.periodo) cerrado
from (select distinct periodo from r) p join r on r.periodo = p.periodo group by p.periodo;
revoke all on public.fin_resumen_mes from anon;

-- pg_cron (si está instalado): gastos fijos el día 1
do $$ begin
  perform cron.unschedule('fin-generar-mes') where exists (select 1 from cron.job where jobname = 'fin-generar-mes');
  perform cron.schedule('fin-generar-mes', '5 5 1 * *', 'select public.fin_generar_mes()');
exception when others then null;
end $$;

notify pgrst, 'reload schema';

-- ---------- INFORME DE CUADRATURA (Costos vs Finanzas) ----------
-- Cada fila debe decir OK. Si alguna dice REVISAR, copia el resultado y envíaselo a Claude.
with
a as (select count(*) n, coalesce(sum(monto),0) s from public.gastos),
b as (select count(*) n, coalesce(sum(total),0) s from public.fin_registros where gasto_id is not null),
fa as (select count(*) n from public.gastos g, jsonb_array_elements(case when jsonb_typeof(g.media)='array' then g.media else '[]'::jsonb end) e
       where coalesce(case when jsonb_typeof(e)='string' then e #>> '{}' else e->>'url' end,'') <> ''),
fb as (select count(*) n from public.fin_adjuntos a join public.fin_registros r on r.id = a.registro_id where r.gasto_id is not null),
mes as (select coalesce(to_char(g.fecha,'YYYY-MM'),'sin fecha') m, count(*) n, coalesce(sum(g.monto),0) s,
               (select count(*) from public.fin_registros r where r.gasto_id is not null and to_char(r.fecha,'YYYY-MM') = to_char(g.fecha,'YYYY-MM')) n2,
               (select coalesce(sum(r.total),0) from public.fin_registros r where r.gasto_id is not null and to_char(r.fecha,'YYYY-MM') = to_char(g.fecha,'YYYY-MM')) s2
        from public.gastos g group by 1),
cen as (select coalesce(nullif(g.centro,''),'(sin centro)') c, count(*) n, coalesce(sum(g.monto),0) s from public.gastos g group by 1),
cen2 as (select coalesce(c.nombre,'(sin centro)') c, count(*) n, coalesce(sum(r.total),0) s from public.fin_registros r left join public.fin_centros c on c.id = r.centro_id where r.gasto_id is not null group by 1),
pat as (select count(distinct upper(regexp_replace(patente,'[^A-Za-z0-9-]','','g'))) n, coalesce(sum(monto) filter (where coalesce(patente,'')<>''),0) s from public.gastos),
pat2 as (select count(distinct patente) n, coalesce(sum(total) filter (where patente is not null),0) s from public.fin_registros where gasto_id is not null),
est as (select case when pagado or upper(coalesce(estado,''))='PAGADO' then 'pagado' when upper(coalesce(estado,''))='LISTO' then 'listo' else 'pendiente' end e, count(*) n from public.gastos group by 1),
est2 as (select estado e, count(*) n from public.fin_registros where gasto_id is not null group by 1),
gf as (select count(*) n, coalesce(sum(monto),0) s from public.gastos_fijos where nullif(trim(concepto),'') is not null),
gf2 as (select count(*) n, coalesce(sum(monto),0) s from public.fin_recurrentes where gasto_fijo_id is not null)
select '1. Costos copiados' control, a.n || ' costos · $' || a.s antes, b.n || ' registros · $' || b.s despues, case when a.n=b.n and a.s=b.s then 'OK' else 'REVISAR' end estado from a, b
union all select '2. Fotos y documentos', fa.n || ' archivos', fb.n || ' archivos', case when fa.n<=fb.n then 'OK' else 'REVISAR' end from fa, fb
union all select '3. Vehículos (patentes)', pat.n || ' patentes · $' || pat.s, pat2.n || ' patentes · $' || pat2.s, case when pat.n=pat2.n and pat.s=pat2.s then 'OK' else 'REVISAR' end from pat, pat2
union all select '4. Gastos fijos', gf.n || ' · $' || gf.s, gf2.n || ' · $' || gf2.s, case when gf.n=gf2.n and gf.s=gf2.s then 'OK' else 'REVISAR' end from gf, gf2
union all (select '5. Mes ' || m, n || ' · $' || s, n2 || ' · $' || s2, case when n=n2 and s=s2 then 'OK' else 'REVISAR' end from mes order by m)
union all (select '6. Centro ' || cen.c, cen.n || ' · $' || cen.s, coalesce(cen2.n,0) || ' · $' || coalesce(cen2.s,0),
                  case when cen.n=coalesce(cen2.n,0) and cen.s=coalesce(cen2.s,0) then 'OK' else 'REVISAR' end from cen left join cen2 on lower(cen2.c)=lower(cen.c) order by 1)
union all (select '7. Estado ' || est.e, est.n::text, coalesce(est2.n,0)::text, case when est.n=coalesce(est2.n,0) then 'OK' else 'REVISAR' end from est left join est2 on est2.e=est.e order by 1);
