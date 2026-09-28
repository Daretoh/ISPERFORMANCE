# IS Performance — Dossier para proyecciones y holding (ISgroup)

> Documento de contexto para pasar a otro chat. Resume la empresa, su sistema de gestión (ERP propio), el modelo de negocio, los datos financieros/operativos disponibles y qué se puede proyectar. Fecha de corte: septiembre 2026.

---

## 1. Qué es IS Performance

- **Rubro:** taller de **detailing / estética automotriz** (lavado, pulido, tratamientos cerámicos, sanitización interior, preparación para la venta) en Puerto Montt, Chile.
- **Razón social:** Innovación y Servicios Performance SpA
- **RUT:** 78.270.149-5
- **Banco:** Santander · Cuenta corriente 0-000-2757437-8
- **Contacto:** ventas@isperformance.cl · +569 8561 5636 · isperformance.cl
- **Dotación:** mixta — algunos de **contrato fijo** y muchos **spot** (rotativos, entran según demanda).

### Holding "ISgroup"
- **IS Performance** (detailing) — este sistema.
- **Innovaservi / "InnovaGestión"** — empresa/app hermana (servicios/operaciones, con módulos Operaciones/RRHH/Remuneraciones). IS Performance está imitando su estructura de RRHH y Remuneraciones.
- Objetivo del usuario: ordenar el **holding** y enfocarse en **proyecciones** (financieras y de crecimiento) consolidando ambas.

---

## 2. Sistema de gestión (ERP propio "OS")

- **App web de un solo archivo** (`os/index.html`, ~5.000+ líneas), JavaScript vanilla, HTML por concatenación de strings.
- **Backend:** Supabase (PostgreSQL + PostgREST + Auth). RLS `for all to authenticated`.
- **Archivos/media:** Cloudflare R2 (fotos de vehículos, vouchers, adjuntos de RRHH, facturas).
- **PDF:** plantilla con membrete (jsPDF + html2canvas) para cotizaciones y cierres.
- **Auth:** login por correo; permisos por rol/vista (tabla `accesos`). Modo "tablet/kiosco" para que operarios marquen asistencia.
- Correlativo de cotizaciones **único y compartido** con el Cierre GM (arranca en 169 = agosto 2026).

### Módulos (menú)
Agendamiento · Calendario · Seguimiento (tablero de vehículos en taller) · Tareas · Asistencia · Mis horas · Clientes · Cobro / Ventas · Cotizaciones · Inventario · POS / Ventas · Cierre GM · Cierres cliente · Solicitudes · Costos · RRHH · Remuneraciones.

---

## 3. Modelo de datos (tablas Supabase — para entender qué información existe)

**Operación / ventas**
- `vehiculos` — registro central: cada auto que entra al taller (marca, modelo, patente, año, **talla** S/M/L/XL, cliente, contacto, servicios, trabajos/checklist, estado del flujo, fechas de coordinación/ingreso/inicio/salida, `precioVenta`, `costoProducto`, `envio`, `costoExterno`, `costoEmpresa`, `cobrado`, `docTipo`, `modoPago`, media). **Es la fuente de ingresos y márgenes por servicio.**
- `acciones` — **libro de movimientos** (ledger): `COBRO | INGRESO | SALIDA | PAGO | GASTO`, con monto, fecha, referencia, proveedor, almacén, producto, vehículo, autor. Base del flujo de caja.
- `clientes` — ficha por cliente (tipo NATURAL/EMPRESA, razón social, RUT, giro, representante, email, teléfono/contacto, dirección) + seguimiento de contacto/postventa.
- `cotizaciones` — cotizaciones **multi-vehículo** (cada vehículo con patente, talla y líneas de servicio; cliente con empresa/RUT/giro + contacto/correo/número; fecha o rango desde–hasta; IVA opcional; borrador/confirmada; PDF).
- `cierre_cliente` — cuenta corriente por cliente (cotizaciones + abonos + saldo).

**Flota Guillermo Morales (cliente empresa clave)**
- `gm_cierre` — vehículos del mes con matriz de servicios por talla + extra.
- `gm_cierre_mes` — estado mensual del flujo: BORRADOR → COTIZADO → OC → FACTURADO → COBRADO (con N° cotización, IVA, montos, adjuntos OC/factura, cerrado).
- `gm_log` — historial de cambios (quién agregó/quitó/emitió y cuándo).

**Inventario**
- `productos` — stock (entrada, salida, `stock_alm{BOD,POS}`), costos.
- Almacenes: Bodega (BOD) y POS.

**Gastos / costos**
- `gastos` — gastos variables (con **centro de costo**: Pintura/Taller/Oficina/POS/Bodega/General, y patente opcional).
- `gastos_fijos` — costos fijos mensuales recurrentes.
- `servicios_digitales` — suscripciones/servicios digitales (con ciclo).

**Personas / RRHH / Remuneraciones**
- `trabajadores` — ficha: cargo, estado (activo/inactivo), `tipo_pago` (hora=spot / contrato=fijo), `jornada_horas`, chofer, fecha_ingreso, teléfono, email, tallas, AFP, salud, dirección, emergencia, notas.
- `cargo` — catálogo de cargos con **trato** (pago por jornada 8 h). **Valor hora = trato / 8.**
- `valor_hora` — override de valor hora por persona (+ `__SPOT__` global de respaldo).
- `asistencia` — marcaje ENTRADA/SALIDA por RUT (últimos 4 dígitos). Fuente de horas de **contrato/fijo** (o BUK externo).
- `reloj` — fichaje manual (h_in, h_out, descanso). Fuente de horas **spot**.
- `rrhh_docs` — documentación y capacitaciones por trabajador (estado, vencimiento, adjuntos).
- `finiquitos` — registro de finiquitos.
- `remuneracion_items` — bonos/descuentos/anticipos por trabajador y mes.
- `remu_ajuste_dia` — monto contable ajustado a mano por trabajador+día (vs. real por horas).

**Sistema**
- `accesos` — permisos por email (vistas, permisos, rol, trabajador vinculado).
- `config` — configuración (orden de menú, etc.).

---

## 4. Catálogo de servicios y precios (CLP, por talla)

Tallas: **S** pequeño (hatch chico) · **M** mediano (sedán) · **L** grande (SUV/camioneta) · **XL** muy grande (SUV grande/van).

| Servicio | Categoría | S | M | L | XL |
|---|---|--:|--:|--:|--:|
| CORE — Limpieza básica | Limpiezas | 35.000 | 40.000 | 45.000 | 55.000 |
| ADVANCE — Limpieza intermedia | Limpiezas | 50.000 | 55.000 | 60.000 | 65.000 |
| PRO — Limpieza avanzada | Limpiezas | 80.000 | 90.000 | 95.000 | 100.000 |
| Limpieza de motor | Limpiezas | 25.000 | 30.000 | 40.000 | 45.000 |
| Pulido estándar | Pulido | 120.000 | 140.000 | 150.000 | 170.000 |
| Pulido premium | Pulido | 170.000 | 190.000 | 210.000 | 230.000 |
| Cerámico 1 año | Protección | 200.000 | 250.000 | 300.000 | 350.000 |
| Cerámico 2 años | Protección | 250.000 | 300.000 | 350.000 | 400.000 |
| Cerámico 3 años | Protección | 300.000 | 350.000 | 400.000 | 450.000 |
| Mantención cerámica | Protección | 45.000 | 50.000 | 55.000 | 65.000 |
| Detallado integral interior | Sanitización | 130.000 | 150.000 | 170.000 | 200.000 |
| Detallado integral full | Sanitización | 260.000 | 300.000 | 340.000 | 400.000 |
| Preparación para la venta | Pre-venta | 90.000 | 110.000 | 130.000 | 150.000 |

Precio variable (a cotizar): Tratamiento de vidrios, Limpieza profunda de asientos, Tratamiento interior de techo. Cada servicio tiene un **checklist de tareas** definido (matriz del gerente).

---

## 5. Flota Guillermo Morales (cliente empresa recurrente = ingreso mensual clave)

Automotora que manda **~19–20 vehículos por mes** para preparación de venta. Se factura en **cierre mensual** (no auto por auto) con matriz por talla:

| Servicio | S | M | L | XL |
|---|--:|--:|--:|--:|
| Interior | 25.000 | 25.000 | 30.000 | 30.000 |
| Exterior | 25.000 | 30.000 | 30.000 | 35.000 |
| Motor | 20.000 | 25.000 | 30.000 | 35.000 |
| Realce brillo | 20.000 | 25.000 | 30.000 | 35.000 |
| Corrección barniz | 70.000 | 80.000 | 90.000 | 100.000 |
| Tapiz | 50.000 | 50.000 | 50.000 | 50.000 |
| Desc. vidrios | 20.000 | 20.000 | 25.000 | 25.000 |
| Extra ($) | manual | | | |
| Retiro / entrega | +5.000 (siempre, toda talla) | | | |

Flujo mensual: Cotizado → OC recibida → Facturado → Cobrado. Ejemplo real agosto 2026: ~$3–4 MM en ~19–20 autos. **Es un ingreso recurrente proyectable.**

---

## 6. Estructura de costos (para proyección)

### Costos fijos mensuales (base cargada)
| Concepto | Monto/mes |
|---|--:|
| Arriendo taller | 1.220.000 |
| Internet taller | 15.990 |
| Asesoría contabilidad | 40.000 |
| Asesoría remuneraciones (BUK) | 50.000 |
| Redes sociales | 40.000 |
| **Total fijo base** | **≈ 1.365.990** |

(Editable en el módulo Costos; se pueden agregar más.)

### Costos variables
- `gastos` por mes (insumos, químicos, repuestos, servicios externos), con centro de costo.
- Costo de producto/insumo por servicio en cada vehículo (`costoProducto`, `envio`, `costoExterno`).

### Personal
- **Spot:** horas del `reloj` × valor hora (trato/8). Dotación variable.
- **Fijo:** renta fija (fuera del cálculo por trato); solo horas sobre jornada cuentan como extra.
- Bonos/descuentos/anticipos en `remuneracion_items`.

### Servicios digitales
- Suscripciones en `servicios_digitales` (web, software, dominios, etc.).

---

## 7. Datos y métricas ya disponibles para PROYECCIONES

El módulo **Costos / Gerencia** ya calcula por mes:
- **Ingresos** (cobrado del mes) = suma de vehículos cobrados (ingreso real) + ventas POS + cierres.
- **Costos** = fijos + variables + personal spot.
- **Resultado** (utilidad/déficit) del mes.
- **N° de autos cobrados** y **ticket promedio**.
- **Tendencia últimos 6 meses** (ingresos vs. gastos).
- **Servicios más vendidos** del mes.

Datos crudos que el otro chat puede pedir/exportar para modelar:
- Serie mensual de **ingresos, costos y resultado**.
- **N° de autos/mes**, ticket promedio, **mix de servicios** (qué se vende más).
- **Clientes recurrentes** y valor por cliente (`cierre_cliente`).
- **Ingreso recurrente flota GM** (mensual, semi-fijo).
- **Costo de personal** por horas marcadas.
- **Márgenes por servicio** (precio − costos).

---

## 8. Estado actual del sistema (sep 2026)

- Operativo en producción (isperformance.cl/os).
- Reciente: Cotizaciones multi-vehículo (con importar autos del Cierre GM por mes, fecha/rango, Empresa+Contacto separados), Cierres cliente (cuenta corriente), RRHH + Remuneraciones portados desde InnovaGestión.
- Módulos Planificación y Químicos: eliminados a pedido.
- Migraciones SQL versionadas en `os/db/` (última: 54 = RRHH+Remuneraciones).

### Pendientes conocidos
- Cargar dotación spot (horas desde `reloj`) y resumen de contrato (BUK) — septiembre es el mes más completo.
- Generar Contrato/ODI/EPP en PDF; detector de duplicados de trabajadores.
- Remuneraciones: cerrar el cálculo semanal (spot vs. fijo, vueltas/peajes de choferes, ajuste contable por día).

---

## 9. Qué pedirle al otro chat (foco proyecciones + holding)

1. **Modelo de proyección financiera** (12 meses) por empresa y consolidado ISgroup: ingresos (por línea: taller retail, flota GM, otros), costos fijos/variables/personal, EBITDA/resultado.
2. **Punto de equilibrio** mensual (cuántos autos/ticket se necesitan para cubrir el fijo ≈ $1,37 MM + personal).
3. **Escenarios** (conservador/base/optimista) según N° de autos, ticket y mix de servicios.
4. **Estacionalidad** y capacidad del taller (autos/día × días hábiles).
5. **Estructura del holding** (roles Isperformance vs. Innovaservi, servicios compartidos, asignación de costos comunes).
6. **KPIs de gestión** a monitorear mensualmente (ticket, ocupación, margen por servicio, recurrencia de clientes, DSO/cobranza vía `cierre_cliente`).

> Nota: los montos exactos por mes viven en la base (Supabase). Si el otro chat necesita las cifras reales, se exportan del módulo Costos/Gerencia o de las tablas `acciones`, `vehiculos`, `gastos`, `gastos_fijos`.
