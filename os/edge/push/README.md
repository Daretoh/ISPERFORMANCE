# Notificaciones INSTANTÁNEAS (Edge Function `push` + Webhook)

Hoy las notificaciones las manda una GitHub Action cada ~5 min. Con esto salen
**al instante**: cada vez que la app crea una fila en `notificaciones`
(agendamiento, cambio de estado en seguimiento, tarea nueva), se dispara un
Webhook que llama a la función `push` y esta manda el aviso de inmediato.

Todo se hace desde el **panel web de Supabase** (no instalas nada).

## 1) Crear la función
1. Supabase → tu proyecto **nuevo** → **Edge Functions** → **Deploy a new function**.
2. Nombre exacto: **`push`**.
3. Borra el ejemplo y pega **todo** `os/edge/push/index.ts`.
4. Si aparece un interruptor **"Verify JWT"**, **desactívalo** (usamos nuestro propio secreto).
5. **Deploy**. Copia la **URL de la función** (algo como
   `https://osmdueveprvwhbtlfnqf.functions.supabase.co/push`).

## 2) Poner los secretos
En **Edge Functions → Secrets** (o Project Settings → Edge Functions → Secrets), agrega:

| Nombre | Valor |
|---|---|
| `VAPID_PRIVATE` | *(la misma clave privada VAPID que ya usas en GitHub Secrets)* |
| `WEBHOOK_SECRET` | *(inventa una palabra/clave larga al azar, ej: `isp-2026-xk92mz`)* |

> No hace falta poner `SUPABASE_URL` ni `SUPABASE_SERVICE_ROLE_KEY`: Supabase los
> inyecta solos. `VAPID_PUBLIC` y `VAPID_SUBJECT` ya vienen con valor por defecto.

## 3) Crear el Webhook de base de datos
1. Supabase → **Database → Webhooks** → **Create a new hook**.
2. Nombre: `push-instant`.
3. Tabla: **`notificaciones`**. Evento: **Insert**.
4. Tipo: **HTTP Request** (POST). URL: la de la función del paso 1.
5. En **HTTP Headers** agrega uno:
   - `x-webhook-secret` = *(el mismo valor que pusiste en `WEBHOOK_SECRET`)*
6. Guarda.

## 4) Probar
- En el OS haz una acción (cambia el estado de un vehículo en Seguimiento, o crea
  una tarea). Debería llegar el push **en segundos** a los demás dispositivos.

## Notas
- La GitHub Action sigue existiendo como **respaldo** (si el webhook fallara, la
  próxima corrida reenvía lo pendiente) y para **recordatorios por horario**
  (tareas con hora, y a futuro los recordatorios de SOLPED).
- No hay envíos duplicados: quien envía primero marca `enviada = true` y el otro lo omite.
