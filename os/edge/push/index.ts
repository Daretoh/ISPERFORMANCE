// IS Performance OS — Edge Function "push"
// Envía la notificación push AL INSTANTE cuando se inserta una fila en la tabla `notificaciones`.
// Se dispara con un Database Webhook (INSERT en `notificaciones`).
//
// Deploy (panel web, sin instalar nada):
//   Supabase → Edge Functions → Deploy a new function → nombre: push
//   Borra el ejemplo, pega TODO este archivo, Deploy.
//   IMPORTANTE: desactiva "Verify JWT" en la función (usamos x-webhook-secret).
// Secretos (Edge Functions → Secrets): VAPID_PRIVATE, WEBHOOK_SECRET
//   (VAPID_PUBLIC y VAPID_SUBJECT ya tienen valor por defecto; SUPABASE_URL y
//    SUPABASE_SERVICE_ROLE_KEY los inyecta Supabase automáticamente.)

import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC = Deno.env.get("VAPID_PUBLIC") ||
  "BDt1m2YVzH-GB8MN4CF5ORzPhoEEBEJK3licTQH4K-oy_o1pXMMSbJl7HHbmeHY3XrOzUP-CvcNgz1V_J_CMupw";
const VAPID_PRIVATE = Deno.env.get("VAPID_PRIVATE")!;
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") || "mailto:is.performance4x4@gmail.com";
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") || "";

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC, VAPID_PRIVATE);
const sb = createClient(SUPABASE_URL, SERVICE_KEY);

Deno.serve(async (req) => {
  // Seguridad: solo aceptamos el webhook con el secreto correcto
  if (WEBHOOK_SECRET && req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return new Response("no autorizado", { status: 401 });
  }

  let body: any = {};
  try { body = await req.json(); } catch (_) { /* ignore */ }
  const n = body.record || body; // el webhook trae { type, table, record, old_record }
  if (!n || !n.id) return new Response(JSON.stringify({ ok: true, skip: "sin fila" }), { status: 200 });
  if (n.enviada) return new Response(JSON.stringify({ ok: true, skip: "ya enviada" }), { status: 200 });

  const { data: subs } = await sb.from("push_subs").select("*");
  let targets = (subs || []);
  if (n.destinatario && n.destinatario !== "ALL") {
    targets = targets.filter((s: any) => s.nombre === n.destinatario);
  }
  targets = targets.filter((s: any) => s.email !== n.autor); // no avisar a quien hizo la acción

  const payload = JSON.stringify({
    title: n.titulo || "IS Performance OS",
    body: n.cuerpo || "",
    url: "/os/",
  });

  await Promise.all(targets.map(async (s: any) => {
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        payload,
      );
    } catch (e: any) {
      // suscripción muerta → la limpiamos
      if (e && (e.statusCode === 404 || e.statusCode === 410)) {
        await sb.from("push_subs").delete().eq("endpoint", s.endpoint);
      } else {
        console.error("push error", (e && (e.statusCode || e.message)) || e);
      }
    }
  }));

  await sb.from("notificaciones").update({ enviada: true }).eq("id", n.id);
  return new Response(JSON.stringify({ ok: true, sent: targets.length }), {
    headers: { "content-type": "application/json" },
  });
});
