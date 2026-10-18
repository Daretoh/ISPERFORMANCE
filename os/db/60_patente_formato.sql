-- ============================================================
-- IS Performance OS - Patentes con un solo formato: XXXX-XX
-- Toda patente de 6 caracteres queda como "ABCD-12" (mayúsculas, sin puntos ni espacios),
-- así "abcd12", "ABCD 12", "AB.CD-12" y "ABCD-12" son la misma. Otros largos (motos, etc.)
-- quedan en mayúsculas y sin separadores.
-- 1) Corrige lo que ya está guardado  2) La base lo aplica sola de aquí en adelante.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create or replace function fmt_patente(p text) returns text
language sql immutable as $$
  select case
    when c is null or c = '' then null
    when length(c) = 6 then substr(c, 1, 4) || '-' || substr(c, 5, 2)
    else c end
  from (select upper(regexp_replace(coalesce(p, ''), '[^A-Za-z0-9]', '', 'g')) as c) x;
$$;

-- Patentes dentro del arreglo de vehículos de una cotización
create or replace function fmt_patentes_json(v jsonb) returns jsonb
language sql immutable as $$
  select case when v is null or jsonb_typeof(v) <> 'array' then v
    else coalesce((select jsonb_agg(case when jsonb_typeof(e) = 'object' and e ? 'patente'
                                         then jsonb_set(e, '{patente}', to_jsonb(coalesce(fmt_patente(e->>'patente'), '')))
                                         else e end order by i)
                   from jsonb_array_elements(v) with ordinality t(e, i)), '[]'::jsonb) end;
$$;

-- 1) Lo existente
update vehiculos    set patente   = fmt_patente(patente)          where patente   is distinct from fmt_patente(patente);
update gastos       set patente   = fmt_patente(patente)          where patente   is distinct from fmt_patente(patente);
update gm_cierre    set patente   = fmt_patente(patente)          where patente   is distinct from fmt_patente(patente);
update cotizaciones set vehiculos = fmt_patentes_json(vehiculos)  where vehiculos is distinct from fmt_patentes_json(vehiculos);

-- 2) De aquí en adelante (sirve aunque alguien tenga abierta una versión vieja de la app)
create or replace function patente_formato() returns trigger
language plpgsql as $$
begin
  if tg_table_name = 'cotizaciones' then new.vehiculos := fmt_patentes_json(new.vehiculos);
  else new.patente := fmt_patente(new.patente); end if;
  return new;
end $$;

drop trigger if exists patente_formato on vehiculos;
create trigger patente_formato before insert or update of patente on vehiculos for each row execute function patente_formato();
drop trigger if exists patente_formato on gastos;
create trigger patente_formato before insert or update of patente on gastos for each row execute function patente_formato();
drop trigger if exists patente_formato on gm_cierre;
create trigger patente_formato before insert or update of patente on gm_cierre for each row execute function patente_formato();
drop trigger if exists patente_formato on cotizaciones;
create trigger patente_formato before insert or update of vehiculos on cotizaciones for each row execute function patente_formato();

notify pgrst, 'reload schema';
