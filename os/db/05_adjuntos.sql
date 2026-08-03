-- ============================================================
-- IS Performance OS - Adjuntos (fotos, videos, boletas, facturas)
-- Almacenamiento en la nube (Supabase Storage).
-- Pegar en Supabase > SQL Editor > Run (traduccion apagada). Seguro de re-ejecutar.
-- ============================================================

-- Bucket privado para todos los adjuntos
insert into storage.buckets (id, name, public) values ('adjuntos','adjuntos', false)
on conflict (id) do nothing;

-- El equipo autenticado puede subir/ver/borrar en ese bucket
drop policy if exists adjuntos_auth on storage.objects;
create policy adjuntos_auth on storage.objects
  for all to authenticated
  using (bucket_id = 'adjuntos')
  with check (bucket_id = 'adjuntos');

-- Columnas para guardar la referencia de los archivos
alter table vehiculos add column if not exists media jsonb default '[]'::jsonb;
alter table gastos    add column if not exists media jsonb default '[]'::jsonb;
