-- ============================================================
-- IS Performance OS - Costos: quién lo cargó, quién lo editó y qué fue lo último
-- 'subido_por' (SQL 59) = quien lo creó. Se agregan editado_por, editado_en y
-- ultimo_cambio (texto tipo "Patente — → RJWK-81 · Monto 7500 → 8000").
-- Lo llena la base sola con el correo de la sesión, así queda registrado
-- aunque el cambio venga del lector, del modo Editar o de una versión vieja de la app.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists subido_por    text;
alter table gastos add column if not exists created_at    timestamptz default now();
alter table gastos add column if not exists editado_por   text;
alter table gastos add column if not exists editado_en    timestamptz;
alter table gastos add column if not exists ultimo_cambio text;

create or replace function gastos_auditoria() returns trigger
language plpgsql as $$
declare
  quien text := nullif(coalesce(auth.jwt() ->> 'email', ''), '');
  c text[] := '{}';
  f text := '';
begin
  if tg_op = 'INSERT' then
    new.subido_por    := coalesce(nullif(new.subido_por, ''), quien);
    new.created_at    := coalesce(new.created_at, now());
    new.editado_por   := coalesce(nullif(new.subido_por, ''), quien);
    new.editado_en    := now();
    new.ultimo_cambio := 'Creado';
    return new;
  end if;

  if new.concepto   is distinct from old.concepto   then c := c || ('Concepto: ' || coalesce(old.concepto,'—') || ' → ' || coalesce(new.concepto,'—')); end if;
  if new.monto      is distinct from old.monto      then c := c || ('Monto: ' || coalesce(old.monto::text,'—') || ' → ' || coalesce(new.monto::text,'—')); end if;
  if new.fecha      is distinct from old.fecha      then c := c || ('Fecha: ' || coalesce(to_char(old.fecha,'DD/MM'),'—') || ' → ' || coalesce(to_char(new.fecha,'DD/MM'),'—')); end if;
  if new.patente    is distinct from old.patente    then c := c || ('Patente: ' || coalesce(old.patente,'—') || ' → ' || coalesce(new.patente,'—')); end if;
  if new.centro     is distinct from old.centro     then c := c || ('Centro: ' || coalesce(old.centro,'—') || ' → ' || coalesce(new.centro,'—')); end if;
  if new.referencia is distinct from old.referencia then c := c || ('Referencia: ' || coalesce(old.referencia,'—') || ' → ' || coalesce(new.referencia,'—')); end if;
  if new.tipo       is distinct from old.tipo       then c := c || ('Tipo: ' || coalesce(old.tipo,'—') || ' → ' || coalesce(new.tipo,'—')); end if;
  if new.pagado     is distinct from old.pagado     then c := c || (case when new.pagado then 'Marcado pagado' else 'Marcado por pagar' end); end if;
  if coalesce(jsonb_array_length(case when jsonb_typeof(new.media)='array' then new.media end),0)
     <> coalesce(jsonb_array_length(case when jsonb_typeof(old.media)='array' then old.media end),0)
     then c := c || ('Adjuntos: ' || coalesce(jsonb_array_length(case when jsonb_typeof(old.media)='array' then old.media end),0) || ' → ' || coalesce(jsonb_array_length(case when jsonb_typeof(new.media)='array' then new.media end),0)); end if;

  if array_length(c, 1) is null then return new; end if; -- nada relevante cambió (no pisa el último cambio)
  f := array_to_string(c, ' · ');
  new.editado_por   := coalesce(quien, new.editado_por);
  new.editado_en    := now();
  new.ultimo_cambio := left(f, 400);
  return new;
end $$;

drop trigger if exists gastos_auditoria on gastos;
drop trigger if exists z_gastos_auditoria on gastos;
-- "z_" para que corra despues de patente_formato (los triggers van en orden alfabetico)
create trigger z_gastos_auditoria before insert or update on gastos for each row execute function gastos_auditoria();

notify pgrst, 'reload schema';
