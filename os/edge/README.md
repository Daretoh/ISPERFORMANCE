# Puente OpenFactura — cómo desplegarlo en Supabase

Esto crea la función segura que conecta el OS con OpenFactura sin exponer la API Key.
Todo se hace desde el **panel web de Supabase** (no necesitas instalar nada).

## 1) Crear la función
1. Entra a **supabase.com** → tu proyecto.
2. Menú izquierdo: **Edge Functions** → botón **Deploy a new function** (o **Create a new function**).
3. Nombre de la función: **`openfactura`** (tal cual, en minúscula).
4. Se abre un editor de código. **Borra** lo que venga de ejemplo y **pega** todo el contenido de:
   `os/edge/openfactura/index.ts`
5. Presiona **Deploy** (o **Save and deploy**). Espera a que diga desplegada ✅.

## 2) Poner los secretos (la key escondida)
1. En **Edge Functions** → pestaña **Secrets** (o **Manage secrets**).  
   (si no está ahí: **Project Settings → Edge Functions → Secrets**).
2. Agrega estos dos:

   | Nombre | Valor |
   |---|---|
   | `OPENFACTURA_URL` | `https://dev-api.haulmer.com` |
   | `OPENFACTURA_KEY` | `928e15a2d14d4a6292345f04960f4bd3` |

   > Esa es la **key de PRUEBA** de Haulmer (sandbox) — segura para practicar.  
   > Cuando pasemos a producción, cambiaremos estos dos por la URL real
   > (`https://api.haulmer.com`) y tu API Key real.
3. Guarda.

## 3) Avísame
Cuando la función diga **desplegada** y los secretos estén puestos, me dices
**"puente listo"** y desde el OS pruebo la conexión y sigo con la pestaña de
Documentos (ver PDF, resumen, vincular a vehículo).

---

### Notas
- La función solo acepta llamadas de usuarios **con sesión iniciada** en el OS
  (Supabase valida el token automáticamente).
- Solo reenvía a la API de OpenFactura (rutas `/v2/...`); no hace nada más.
- Si algo falla en el despliegue, mándame captura y te guío.
