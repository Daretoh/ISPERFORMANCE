-- ============================================================
-- IS Performance OS - Registro de usuarios que inician sesión
-- Cada vez que alguien entra, se guarda su correo aquí. Así el panel Admin
-- puede listar automáticamente las cuentas reales (sin usar la service_role
-- key, que no debe exponerse en la página).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
create table if not exists usuarios (
  email      text primary key,
  nombre     text,
  last_login timestamptz,
  created_at timestamptz default now()
);
alter table usuarios enable row level security;
drop policy if exists equipo_usuarios on usuarios;
create policy equipo_usuarios on usuarios for all to authenticated using (true) with check (true);
