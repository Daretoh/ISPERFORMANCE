// ============================================================
//  IS Performance OS — Puente seguro a OpenFactura (Haulmer)
//  Supabase Edge Function. Guarda la API Key escondida (secreto) y
//  reenvía las llamadas a OpenFactura. El OS NUNCA ve la key.
//
//  Secretos que usa (se configuran en Supabase > Edge Functions > Secrets):
//    OPENFACTURA_URL  -> https://dev-api.haulmer.com   (prueba)
//                        https://api.haulmer.com       (producción)
//    OPENFACTURA_KEY  -> tu API Key de Documentos Electrónicos
//
//  El OS la llama así:
//    sbc().functions.invoke('openfactura', { body:{ method:'POST',
//        path:'/v2/dte/document', payload:{...} } })
//  Devuelve { ok, status, json }  o  { ok, status, pdf_base64, contentType }
// ============================================================

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(obj: unknown, status: number) {
  return new Response(JSON.stringify(obj), { status, headers: { ...CORS, "content-type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const BASE = (Deno.env.get("OPENFACTURA_URL") || "https://dev-api.haulmer.com").replace(/\/+$/, "");
    const KEY = Deno.env.get("OPENFACTURA_KEY") || "";
    if (!KEY) return json({ ok: false, error: "Falta el secreto OPENFACTURA_KEY" }, 500);

    const body = await req.json().catch(() => ({}));
    const method = (body.method || "GET").toUpperCase();
    let path = String(body.path || "");
    if (!path.startsWith("/")) path = "/" + path;
    if (!path.startsWith("/v2/")) return json({ ok: false, error: "Ruta no permitida" }, 400);

    const init: RequestInit = {
      method,
      headers: { "apikey": KEY, "content-type": "application/json" },
    };
    if (method !== "GET" && method !== "HEAD" && body.payload != null) {
      init.body = typeof body.payload === "string" ? body.payload : JSON.stringify(body.payload);
    }

    const resp = await fetch(BASE + path, init);
    const ct = resp.headers.get("content-type") || "";

    if (ct.includes("application/json")) {
      const data = await resp.json().catch(() => null);
      return json({ ok: resp.ok, status: resp.status, json: data }, 200);
    }
    const buf = new Uint8Array(await resp.arrayBuffer());
    let bin = ""; for (let i = 0; i < buf.length; i++) bin += String.fromCharCode(buf[i]);
    return json({ ok: resp.ok, status: resp.status, contentType: ct, pdf_base64: btoa(bin) }, 200);
  } catch (e) {
    return json({ ok: false, error: String((e && (e as Error).message) || e) }, 500);
  }
});
