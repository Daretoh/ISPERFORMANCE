-- ============================================================
-- IS Performance OS - Trabajos (checklist) + Cotizar despues
-- Agrega a cada vehiculo:
--   * trabajos: lista de trabajos a realizar, tipo tareas dentro del servicio
--               (jsonb: [{ "t": "texto", "ok": false }, ...])
--   * cotizar_despues: marca los trabajos que se cotizan despues (ej. Guillermo
--               Morales). Se pintan con color especial en la Agenda.
-- Pegar en Supabase > SQL Editor > Run (traduccion DESACTIVADA). Seguro de re-ejecutar.
-- ============================================================

alter table vehiculos add column if not exists trabajos         jsonb   default '[]'::jsonb;
alter table vehiculos add column if not exists cotizar_despues  boolean default false;
-- prioridad en Seguimiento: URGENTE | PRIORIDAD | NORMAL | PROGRAMADO (para el resumen del taller)
alter table vehiculos add column if not exists prioridad        text;
