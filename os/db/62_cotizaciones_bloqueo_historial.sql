-- ============================================================
-- IS Performance OS - Cotizaciones: bloqueo + historial
-- 1) HISTORIAL: antes de cada cambio o eliminación se guarda una copia
--    completa de la cotización en cotizaciones_hist (para poder recuperarla).
-- 2) BLOQUEO: una cotización CONFIRMADA o ENVIADA no se puede sobrescribir
--    ni eliminar (lo impide la base, aunque venga de una versión vieja de la app).
--    Sí se permite: cambiar el estado (desbloquear = pasar a Borrador), marcar
--    ítems como hechos (avance), y actualizar los datos del cliente.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists cotizaciones_hist (
  id        bigserial primary key,
  cot_id    uuid,
  numero    integer,
  operacion text,                       -- UPDATE | DELETE
  quien     text,
  en        timestamptz default now(),
  datos     jsonb                         -- la cotización tal como estaba ANTES del cambio
);
create index if not exists cotizaciones_hist_num_idx on cotizaciones_hist(numero, en desc);
alter table cotizaciones_hist enable row level security;
drop policy if exists equipo_cotiz_hist on cotizaciones_hist;
create policy equipo_cotiz_hist on cotizaciones_hist for select to authenticated using (true);

-- ítems sin la marca "done" (el avance se puede marcar aunque esté confirmada)
create or replace function cot_sin_done(j jsonb) returns jsonb language sql immutable as $$
  select coalesce(jsonb_agg(case when jsonb_typeof(e)='object' then e - 'done' else e end order by o), '[]'::jsonb)
  from jsonb_array_elements(case when jsonb_typeof(j)='array' then j else '[]'::jsonb end) with ordinality t(e,o)
$$;
create or replace function cot_vehs_sin_done(j jsonb) returns jsonb language sql immutable as $$
  select coalesce(jsonb_agg(case when jsonb_typeof(v)='object' then v || jsonb_build_object('items', cot_sin_done(v->'items')) else v end order by o), '[]'::jsonb)
  from jsonb_array_elements(case when jsonb_typeof(j)='array' then j else '[]'::jsonb end) with ordinality t(v,o)
$$;

create or replace function cotizaciones_guardia() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  quien text := nullif(coalesce(auth.jwt() ->> 'email', ''), '');
  libres text[] := array['estado','editado_por','updated_at','items','vehiculos',
                         'cliente_nombre','cliente_tel','cliente_correo','cliente_contacto','cliente_rut','cliente_giro'];
  a jsonb; b jsonb;
begin
  insert into cotizaciones_hist(cot_id, numero, operacion, quien, datos)
  values (old.id, old.numero, tg_op, quien, to_jsonb(old));

  if upper(coalesce(old.estado,'')) in ('CONFIRMADA','ENVIADA') then
    if tg_op = 'DELETE' then
      raise exception 'Cotización N° % bloqueada (%): pásala a Borrador para eliminarla', old.numero, old.estado;
    end if;
    a := to_jsonb(old) - libres; b := to_jsonb(new) - libres;
    if a is distinct from b
       or cot_sin_done(to_jsonb(old)->'items') is distinct from cot_sin_done(to_jsonb(new)->'items')
       or cot_vehs_sin_done(to_jsonb(old)->'vehiculos') is distinct from cot_vehs_sin_done(to_jsonb(new)->'vehiculos') then
      raise exception 'Cotización N° % bloqueada (%): no se puede sobrescribir. Pásala a Borrador o cópiala como nueva', old.numero, old.estado;
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;

drop trigger if exists cotizaciones_guardia on cotizaciones;
create trigger cotizaciones_guardia before update or delete on cotizaciones
  for each row execute function cotizaciones_guardia();
notify pgrst, 'reload schema';
