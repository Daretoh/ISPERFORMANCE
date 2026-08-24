-- ============================================================
-- IS Performance OS - Limpiar basura de importación en vehículos
-- Algunas filas quedaron con texto tipo "System.Xml.XmlElement" pegado
-- en marca / modelo / patente (una importación vieja guardó el objeto en
-- vez del valor real). Esto lo borra y deja el texto limpio.
--
-- Pegar en Supabase > SQL Editor. Traducción DESACTIVADA. Seguro de re-ejecutar.
-- ============================================================

-- 1) PRIMERO MIRA qué filas están afectadas (no cambia nada):
select id, marca, modelo, patente, cliente
from vehiculos
where marca   ilike '%System.%'
   or modelo  ilike '%System.%'
   or patente ilike '%System.%'
   or cliente ilike '%System.%';

-- 2) Cuando confirmes, corre esto para limpiarlas:
update vehiculos set
  marca   = nullif(trim(regexp_replace(coalesce(marca,''),   'System\.[A-Za-z0-9_.]*', '', 'gi')), ''),
  modelo  = nullif(trim(regexp_replace(coalesce(modelo,''),  'System\.[A-Za-z0-9_.]*', '', 'gi')), ''),
  patente = nullif(trim(regexp_replace(coalesce(patente,''), 'System\.[A-Za-z0-9_.]*', '', 'gi')), ''),
  cliente = nullif(trim(regexp_replace(coalesce(cliente,''), 'System\.[A-Za-z0-9_.]*', '', 'gi')), '')
where marca   ilike '%System.%'
   or modelo  ilike '%System.%'
   or patente ilike '%System.%'
   or cliente ilike '%System.%';
