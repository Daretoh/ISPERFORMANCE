-- ============================================================
-- IS Performance OS - Catatumbo: nombre en cotizaciones importadas
-- Las N°149, 151, 152 y 153 se importaron con cliente 'N/A' pero son
-- de Catatumbo (mismo telefono +569 4889 0914).
-- Pegar en Supabase > SQL Editor > Run. Seguro de re-ejecutar.
-- ============================================================
update cotizaciones set cliente_nombre = 'Catatumbo Energy'
where numero in (149, 151, 152, 153) and (cliente_nombre is null or cliente_nombre = 'N/A');
