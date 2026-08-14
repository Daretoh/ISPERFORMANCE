// IS Performance OS — DIAGNÓSTICO OpenFactura (Haulmer)
// Objetivo: descubrir el endpoint correcto para LISTAR documentos emitidos (boletas/facturas)
// y ver la estructura real de la respuesta. NO escribe nada, solo consulta y loguea.
// La API key vive en el secreto de GitHub HAULMER — nunca se imprime.

const API_KEY = process.env.HAULMER;
if (!API_KEY) { console.error('Falta el secreto HAULMER.'); process.exit(1); }

const BASE = 'https://api.haulmer.com';

// Rango de fechas: últimos 40 días (por si el filtro es obligatorio)
function isoDaysAgo(n) {
  const d = new Date(Date.now() - n * 86400000);
  return d.toISOString().slice(0, 10);
}
const desde = isoDaysAgo(40);
const hasta = isoDaysAgo(0);

// Combinaciones candidatas (método, ruta, cuerpo) para "documentos emitidos"
const intentos = [
  ['POST', '/v2/dte/document/issued', { Page: 1 }],
  ['POST', '/v2/dte/document/issued', {}],
  ['POST', '/v2/dte/document/issued', { Page: 1, FchEmis: { gte: desde, lte: hasta } }],
  ['GET',  '/v2/dte/document/issued', null],
  ['GET',  '/v2/dte/document/received', null], // referencia: recibidos (para comparar shape)
];

function resumen(obj, prof = 0) {
  // Devuelve las claves de nivel superior y un ejemplo pequeño, sin volcar todo
  if (Array.isArray(obj)) return `Array(${obj.length}) ejemplo[0]=` + JSON.stringify(obj[0] ?? null).slice(0, 800);
  if (obj && typeof obj === 'object') {
    const claves = Object.keys(obj);
    let out = 'Objeto claves=' + JSON.stringify(claves);
    // si hay un arreglo de datos, mostrar el primer elemento
    for (const k of ['data', 'documents', 'Documents', 'items', 'result', 'results']) {
      if (Array.isArray(obj[k])) {
        out += `\n  ${k}: Array(${obj[k].length}) ejemplo[0]=` + JSON.stringify(obj[k][0] ?? null).slice(0, 1200);
      }
    }
    return out;
  }
  return JSON.stringify(obj).slice(0, 800);
}

async function probar(method, path, body) {
  const url = BASE + path;
  const opts = { method, headers: { apikey: API_KEY, 'Content-Type': 'application/json' } };
  if (body !== null) opts.body = JSON.stringify(body);
  try {
    const r = await fetch(url, opts);
    const txt = await r.text();
    let parsed; try { parsed = JSON.parse(txt); } catch { parsed = txt; }
    console.log(`\n=== ${method} ${path} ${body ? JSON.stringify(body) : ''} ===`);
    console.log(`HTTP ${r.status}`);
    if (typeof parsed === 'string') console.log('Respuesta (texto):', parsed.slice(0, 600));
    else console.log(resumen(parsed));
    return r.status;
  } catch (e) {
    console.log(`\n=== ${method} ${path} ===`);
    console.log('ERROR de red:', e.message);
    return 0;
  }
}

async function main() {
  console.log(`Diagnóstico OpenFactura — rango ${desde} a ${hasta}`);
  for (const [m, p, b] of intentos) {
    await probar(m, p, b);
  }
  console.log('\nListo. Revisa arriba cuál devolvió HTTP 200 con la lista de boletas.');
}
main();
