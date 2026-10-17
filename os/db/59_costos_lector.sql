-- ============================================================
-- IS Performance OS - Lector de boletas y facturas (beta) en Costos
-- Agrega a "gastos" los datos del documento leído (emisor, tipo, folio, neto, IVA, ítems)
-- y quién lo subió. El usuario lo fija la base (no se puede falsear desde el navegador).
-- Un mismo documento (emisor + tipo + folio) no se puede cargar dos veces.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists media        jsonb default '[]'::jsonb;
alter table gastos add column if not exists tipo_dte     integer;   -- 33 factura, 39 boleta, 61 nota de crédito, 0 comprobante…
alter table gastos add column if not exists folio        text;
alter table gastos add column if not exists rut_emisor   text;
alter table gastos add column if not exists razon_social text;
alter table gastos add column if not exists neto         integer;
alter table gastos add column if not exists iva          integer;
alter table gastos add column if not exists items        jsonb;
alter table gastos add column if not exists origen       text;      -- timbre | xml | ocr | manual (null = cargado a mano en Costos)
alter table gastos add column if not exists subido_por   text;

create unique index if not exists gastos_doc_unico on gastos (rut_emisor, tipo_dte, folio)
  where rut_emisor is not null and tipo_dte is not null and folio is not null and folio <> '';

create or replace function gastos_autor() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then new.subido_por := lower(coalesce(auth.jwt()->>'email', new.subido_por, ''));
  else new.subido_por := old.subido_por; end if;
  return new;
end $$;
revoke execute on function gastos_autor() from public, anon, authenticated;
drop trigger if exists gastos_autor on gastos;
create trigger gastos_autor before insert or update on gastos
  for each row execute function gastos_autor();

notify pgrst, 'reload schema';
