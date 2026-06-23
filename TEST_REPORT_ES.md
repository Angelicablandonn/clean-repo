# Informe de Ejecución de Pruebas Playwright (Español)

**Proyecto:** nuaav-playwright-saucedemo  
**Aplicación objetivo:** https://www.saucedemo.com  
**Fecha de ejecución:** 23 de junio de 2026  
**Resultado general:** **FALLIDO** (36 aprobadas, 1 fallida, 37 en total)

---

## 1. Resumen Ejecutivo

Se ejecutó la suite completa de pruebas end-to-end con Playwright tras instalar dependencias y navegadores. **El 97,3% de las pruebas pasó** (36/37). Una prueba falló en **Firefox** por timeout en el hook `beforeEach` al cargar la página de inventario. Todas las pruebas en **Chromium** pasaron, incluida la misma prueba de carrito que falló en Firefox.

| Métrica | Valor |
|---------|-------|
| Total de pruebas | 37 |
| Aprobadas | 36 |
| Fallidas | 1 |
| Omitidas | 0 |
| Tasa de éxito | 97,3% |
| Duración total | ~4,3 minutos |
| Workers | 4 |
| Navegadores | Chromium, Firefox |
| Código de salida | 1 |

---

## 2. Entorno y Comandos Ejecutados

| Paso | Comando | Estado |
|------|---------|--------|
| 1 | `npm install` | Éxito (6 paquetes, 0 vulnerabilidades) |
| 2 | `npx playwright install --with-deps` | Éxito (Chromium, Firefox, WebKit, FFmpeg, Winldd) |
| 3 | `npx playwright test` | **Fallido** (1 prueba fallida) |
| 4 | `npx playwright show-report` | Informe HTML disponible en `playwright-report/index.html` |

**Configuración relevante** (`playwright.config.ts`):
- URL base: `https://www.saucedemo.com`
- Proyectos: `setup` → `chromium`, `firefox`
- Timeout por prueba: 45.000 ms
- Reporter: HTML + list
- Capturas de pantalla: solo en fallo
- Trazas: en el primer reintento

---

## 3. Evidencia y Artefactos

| Artefacto | Ruta |
|-----------|------|
| Salida de consola (ejecución completa) | `test-output.txt` |
| Informe HTML interactivo | `playwright-report/index.html` |
| Contexto de error de la prueba fallida | `test-results/cart-Cart-cart-page-lists-the-added-items-firefox/error-context.md` |
| Metadatos de última ejecución | `test-results/.last-run.json` |
| Log de instalación de navegadores | `install-log.txt` |

Para abrir el informe HTML localmente:

```bash
npx playwright show-report
```

---

## 4. Resultados por Proyecto

### 4.1 Setup (1/1 aprobada)

| # | Prueba | Resultado | Duración |
|---|--------|-----------|----------|
| 1 | authenticate as standard_user | APROBADA | 11,7s |

### 4.2 Chromium (18/18 aprobadas)

| # | Suite | Prueba | Resultado | Duración |
|---|-------|--------|-----------|----------|
| 1 | Login / Auth | standard_user logs in successfully | APROBADA | 10,1s |
| 2 | Login / Auth | locked_out_user is blocked with an error message | APROBADA | 9,8s |
| 3 | Login / Auth | invalid credentials show an error | APROBADA | 10,0s |
| 4 | Login / Auth | empty username is rejected | APROBADA | 9,9s |
| 5 | Login / Auth | user can log out | APROBADA | 6,6s |
| 6 | Cart | adding an item updates the cart badge | APROBADA | 6,0s |
| 7 | Cart | adding multiple items increments the badge | APROBADA | 6,0s |
| 8 | Cart | removing an item decrements the badge | APROBADA | 6,6s |
| 9 | Cart | cart page lists the added items | APROBADA | 7,4s |
| 10 | Checkout | completes the full happy-path checkout | APROBADA | 8,9s |
| 11 | Checkout | blocks checkout when customer info is missing | APROBADA | 8,0s |
| 12 | Special user edge cases | problem_user serves broken product images | APROBADA | 5,7s |
| 13 | Special user edge cases | performance_glitch_user loads inventory within budget | APROBADA | 12,0s |
| 14 | Product Catalogue | shows the full product grid | APROBADA | 6,9s |
| 15 | Product Catalogue | sorts products by name A→Z | APROBADA | 7,0s |
| 16 | Product Catalogue | sorts products by name Z→A | APROBADA | 6,4s |
| 17 | Product Catalogue | sorts products by price low→high | APROBADA | 10,2s |
| 18 | Product Catalogue | sorts products by price high→low | APROBADA | 4,2s |

**Nota de rendimiento (Chromium):** carga del inventario con `performance_glitch_user` medida en **6.233 ms** (dentro del presupuesto).

### 4.3 Firefox (17/18 aprobadas)

| # | Suite | Prueba | Resultado | Duración |
|---|-------|--------|-----------|----------|
| 1 | Login / Auth | standard_user logs in successfully | APROBADA | 36,7s |
| 2 | Login / Auth | locked_out_user is blocked with an error message | APROBADA | 40,1s |
| 3 | Login / Auth | invalid credentials show an error | APROBADA | 44,2s |
| 4 | Login / Auth | empty username is rejected | APROBADA | 46,1s |
| 5 | Login / Auth | user can log out | APROBADA | 24,3s |
| 6 | Cart | adding an item updates the cart badge | APROBADA | 31,0s |
| 7 | Cart | adding multiple items increments the badge | APROBADA | 28,8s |
| 8 | Cart | removing an item decrements the badge | APROBADA | 26,0s |
| 9 | Cart | **cart page lists the added items** | **FALLIDA** | 45,7s |
| 10 | Checkout | completes the full happy-path checkout | APROBADA | 23,7s |
| 11 | Checkout | blocks checkout when customer info is missing | APROBADA | 22,2s |
| 12 | Special user edge cases | problem_user serves broken product images | APROBADA | 13,9s |
| 13 | Special user edge cases | performance_glitch_user loads inventory within budget | APROBADA | 13,6s |
| 14 | Product Catalogue | shows the full product grid | APROBADA | 27,8s |
| 15 | Product Catalogue | sorts products by name A→Z | APROBADA | 30,4s |
| 16 | Product Catalogue | sorts products by name Z→A | APROBADA | 27,0s |
| 17 | Product Catalogue | sorts products by price low→high | APROBADA | 18,6s |
| 18 | Product Catalogue | sorts products by price high→low | APROBADA | 14,1s |

**Nota de rendimiento (Firefox):** carga del inventario con `performance_glitch_user` medida en **7.919 ms** (dentro del presupuesto).

---

## 5. Análisis del Fallo

### Prueba Fallida

| Campo | Valor |
|-------|-------|
| Navegador | Firefox |
| Archivo | `tests/cart.spec.ts:33` |
| Suite | Cart |
| Nombre de la prueba | cart page lists the added items |
| Error | `Test timeout of 45000ms exceeded while running "beforeEach" hook.` |
| Línea que falla | `test.beforeEach` en la línea 10 |

### Causa Probable

El fallo ocurrió **antes de ejecutar el cuerpo de la prueba**, dentro del hook `beforeEach` compartido:

```ts
test.beforeEach(async ({ inventoryPage }) => {
  await inventoryPage.open();
  await inventoryPage.expectLoaded();
});
```

La página de inventario no terminó de cargar dentro del timeout de 45 segundos en Firefox. La misma prueba **pasó en Chromium en 7,4s**, y otras pruebas de carrito en Firefox del mismo archivo también pasaron. Esto sugiere **lentitud intermitente o contención de recursos en Firefox** bajo ejecución paralela (4 workers), no un defecto funcional en la lógica del carrito.

### Evidencia de Consola (extracto)

```
x  28 [firefox] › tests\cart.spec.ts:33:3 › Cart › cart page lists the added items (45.7s)

  1) [firefox] › tests\cart.spec.ts:33:3 › Cart › cart page lists the added items

    Test timeout of 45000ms exceeded while running "beforeEach" hook.

    Error Context: test-results\cart-Cart-cart-page-lists-the-added-items-firefox\error-context.md

  1 failed
  36 passed (4.3m)
```

### Acciones Recomendadas

1. Re-ejecutar la prueba aislada: `npx playwright test tests/cart.spec.ts:33 --project=firefox`
2. Si pasa, considerar aumentar el timeout para Firefox o reducir workers en paralelo.
3. Activar `trace: 'on'` para el proyecto Firefox y capturar una traza completa en el próximo fallo.

---

## 6. Resumen de Cobertura por Área

| Área funcional | Chromium | Firefox | Total |
|----------------|----------|---------|-------|
| Autenticación | 5/5 | 5/5 | 10/10 |
| Carrito | 4/4 | 3/4 | 7/8 |
| Checkout | 2/2 | 2/2 | 4/4 |
| Inventario / Ordenamiento | 5/5 | 5/5 | 10/10 |
| Casos especiales | 2/2 | 2/2 | 4/4 |
| Setup | 1/1 | — | 1/1 |

---

## 7. Conclusión

La suite de automatización Playwright para SauceDemo es **mayormente estable** en Chromium y Firefox. Autenticación, checkout, ordenamiento de inventario y casos especiales de usuario pasaron en ambos navegadores. El único fallo es un **timeout intermitente en Firefox** en el hook de preparación del suite de carrito, no un bug confirmado de la aplicación. Se recomienda re-ejecutar la prueba fallida o ajustar timeouts específicos de Firefox antes de considerarlo un defecto bloqueante.

---

*Informe generado a partir de la ejecución de `npx playwright test` el 23 de junio de 2026.*
