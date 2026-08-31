-- ============================================================
-- IS Performance OS - Estado de pago de los costos (por pagar / pagado)
-- Recibir un material/GD NO significa pagarlo. Cada costo nace "por pagar"
-- y se marca "pagado" cuando efectivamente se paga.
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
alter table gastos add column if not exists pagado     boolean default false;
alter table gastos add column if not exists fecha_pago date;
