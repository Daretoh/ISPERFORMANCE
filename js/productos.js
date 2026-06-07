// Fuente de datos: Shopify (productos.json) + compatibilidad.csv
const CAT_MAP = {
  'Tapas y Lonas':   'Tapas',
  'Pisaderas':       'Pisaderas',
  'Barras Antivuelco': 'Barras'
};

function parseCSV(text) {
  const lines = text.trim().split('\n');
  const headers = lines[0].split(',').map(h => h.trim());
  return lines.slice(1).map(line => {
    const vals = [];
    let field = '', quoted = false;
    for (const ch of line) {
      if (ch === '"') { quoted = !quoted; continue; }
      if (ch === ',' && !quoted) { vals.push(field); field = ''; continue; }
      field += ch;
    }
    vals.push(field);
    const obj = {};
    headers.forEach((h, i) => obj[h] = (vals[i] || '').trim());
    return obj;
  }).filter(r => Object.values(r).some(v => v));
}

function buildCompatMap(rows) {
  const map = {};
  for (const r of rows) {
    const key = r['Producto'];
    if (!key) continue;
    if (!map[key]) map[key] = [];
    const desde = parseInt(r['Año Desde']) || 0;
    const hasta = parseInt(r['Año Hasta']) || 0;
    const años = [];
    for (let a = desde; a <= hasta; a++) años.push(a);
    map[key].push({
      marca:  r['Marca Vehículo']  || '',
      modelo: r['Modelo Vehículo'] || '',
      años
    });
  }
  return map;
}

async function cargarProductos() {
  try {
    const STORE = 'is-perfomance.myshopify.com';
    const [resP, resC, resS] = await Promise.all([
      fetch(`https://${STORE}/products.json?limit=250`),
      fetch('compatibilidad.csv'),
      fetch('stock.json').catch(() => null)
    ]);

    const { products } = await resP.json();
    const csvText = await resC.text();
    const compat  = buildCompatMap(parseCSV(csvText));
    const stockMap = resS ? await resS.json().catch(() => ({})) : {};

    let id = 0;
    return products.map(p => {
      const cat    = CAT_MAP[p.product_type] || p.product_type;
      const imgs   = (p.images || []).map(i => i.src);
      const imagen = imgs[0] || 'https://placehold.co/400x280/1A1A1A/FF6B00?text=' + encodeURIComponent(p.title);

      const variant = p.variants && p.variants[0] ? p.variants[0] : {};
      const precio  = parseFloat(variant.price) || 0;
      const stock   = p.handle in stockMap ? stockMap[p.handle] : null;

      const desc = p.body_html || '';

      return {
        id:             ++id,
        shopifyId:      p.id,
        handle:         p.handle,
        nombre:         p.title,
        categoria:      cat,
        vendor:         p.vendor,
        tags:           Array.isArray(p.tags) ? p.tags : (p.tags || '').split(', ').filter(Boolean),
        imagen,
        imagenes:       imgs,
        descripcion:    desc.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 200),
        descripcionHTML: desc,
        shopifyUrl:     `https://${STORE}/products/${p.handle}`,
        variantId:      variant.id || null,
        precio,
        stock,
        vehiculos:      compat[p.title] || []
      };
    });
  } catch (e) {
    console.error('Error cargando productos:', e);
    return [];
  }
}
