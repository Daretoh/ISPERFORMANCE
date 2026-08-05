// IS Performance OS — enviador de notificaciones de tareas (GitHub Actions, cada ~5 min)
import webpush from 'web-push';
import { createClient } from '@supabase/supabase-js';

const { SUPABASE_URL, SUPABASE_SERVICE_KEY, VAPID_PUBLIC, VAPID_PRIVATE, VAPID_SUBJECT } = process.env;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY || !VAPID_PUBLIC || !VAPID_PRIVATE) {
  console.error('Faltan variables de entorno (secrets).');
  process.exit(1);
}

webpush.setVapidDetails(VAPID_SUBJECT || 'mailto:admin@isperformance.cl', VAPID_PUBLIC, VAPID_PRIVATE);
const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Fecha y hora actuales en horario de Chile (America/Santiago)
function ahoraChile() {
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Santiago', year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hour12: false
  });
  const p = {};
  for (const part of fmt.formatToParts(new Date())) p[part.type] = part.value;
  return { fecha: `${p.year}-${p.month}-${p.day}`, hora: `${p.hour}:${p.minute}` };
}

async function enviar(targets, payload) {
  await Promise.all(targets.map(async s => {
    try {
      await webpush.sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } }, payload);
    } catch (e) {
      if (e.statusCode === 404 || e.statusCode === 410) {
        await sb.from('push_subs').delete().eq('endpoint', s.endpoint); // suscripcion muerta
      } else {
        console.error('push error', e.statusCode || e.message);
      }
    }
  }));
}

async function main() {
  const { fecha, hora } = ahoraChile();
  const { data: subs } = await sb.from('push_subs').select('*');
  const allSubs = subs || [];

  // 1) Bandeja de avisos (agendamientos, cambios de estado, nuevas tareas) — a todos o al responsable
  const { data: notifs } = await sb.from('notificaciones').select('*').eq('enviada', false);
  for (const n of (notifs || [])) {
    let targets = (n.destinatario && n.destinatario !== 'ALL') ? allSubs.filter(s => s.nombre === n.destinatario) : allSubs;
    targets = targets.filter(s => s.email !== n.autor); // no avisar a quien lo hizo
    const payload = JSON.stringify({ title: n.titulo || 'IS Performance OS', body: n.cuerpo || '', url: '/os/' });
    await enviar(targets, payload);
    await sb.from('notificaciones').update({ enviada: true }).eq('id', n.id);
    console.log(`Aviso: "${n.titulo}" -> ${targets.length} dispositivo(s)`);
  }

  // 2) Recordatorios de tareas cuya hora ya llego (dirigido al responsable)
  const { data: tareas, error } = await sb.from('tareas').select('*')
    .eq('estado', 'PENDIENTE').eq('notificada', false).not('fecha', 'is', null);
  if (error) { console.error(error); process.exit(1); }
  const due = (tareas || []).filter(t => t.fecha < fecha || (t.fecha === fecha && (t.hora || '00:00') <= hora));
  for (const t of due) {
    const targets = t.responsable ? allSubs.filter(s => s.nombre === t.responsable) : allSubs;
    const payload = JSON.stringify({ title: '⏰ Recordatorio de tarea', body: t.titulo + (t.hora ? ` (${t.hora})` : ''), url: '/os/' });
    await enviar(targets, payload);
    await sb.from('tareas').update({ notificada: true }).eq('id', t.id);
    console.log(`Recordatorio: "${t.titulo}" -> ${targets.length} dispositivo(s)`);
  }

  if (!(notifs || []).length && !due.length) console.log(`Nada por enviar (${fecha} ${hora}).`);
}

main().catch(e => { console.error(e); process.exit(1); });
