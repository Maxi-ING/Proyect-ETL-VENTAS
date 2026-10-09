# ETL y calidad de datos de ventas

**Excel · Power Query**

**Preparé 11.971 ventas válidas para el análisis y separé 604 casos para revisión.** Recuperé valores cuando los datos permitían verificarlos y conservé el origen de cada corrección. El resultado es un proceso de limpieza que puede repetirse al actualizar la fuente.

Trabajé con **12.575 transacciones de retail** de un dataset sintético. El objetivo fue resolver datos incompletos antes de utilizarlos en reportes de ventas.

## Qué resolví y con qué criterio

| Problema | Decisión aplicada | Resultado |
|---|---|---|
| Precio unitario ausente | Calcular total / cantidad cuando ambos valores permiten recuperarlo. | **609 precios recuperados.** |
| Artículo sin identificar | Inferirlo solo cuando categoría y precio corresponden a un único artículo en los datos. | **1.213 artículos inferidos**, identificados como tales. |
| Cantidad o importe no recuperable | Separar la transacción para revisión. | **604 registros apartados.** |
| Descuento sin información | Mantenerlo como “Desconocido”. | Evitar asumir que se aplicó o que no existió. |

Esta separación permite trabajar con ventas consistentes y revisar los casos pendientes sin perderlos ni inventar importes.

## Cómo construí el flujo

Primero separé los campos del CSV en Excel y los convertí en tabla. Después utilicé Power Query para normalizar textos, asignar tipos, recuperar valores verificables y clasificar cada registro según su calidad.

Añadí campos de fecha, canal, ingreso validado y origen de las correcciones. Las consultas generan dos salidas: ventas limpias y registros para revisión.

## Qué quedó disponible para analizar

Las ventas válidas suman **1.552.071 unidades monetarias**. La instantánea de Excel reúne indicadores y resúmenes por categoría, mes y canal.

El aporte principal del proyecto es preparar una base consistente para esos reportes. Los 604 casos pendientes quedan fuera del ingreso validado hasta poder revisarlos.

## Dónde encontrar cada parte

| Carpeta | Contenido |
|---|---|
| `datos/` | Fuente `retail_store_sales.csv` y salidas `Ventas_Limpias.csv` y `Ventas_Rechazadas.csv`. |
| `power-query/` | Consultas M: `Ventas_Transformadas.pq`, `Ventas_Limpias.pq` y `Ventas_Rechazadas.pq`. |
| `analisis/` | `Analisis_Ventas.xlsx` y cifras de respaldo en `diagnostico.json`. |
| `docs/` | Pasos para repetir el proceso en `reproduccion.md`. |

**Para reproducirlo:** importa las consultas de la carpeta `power-query/` en Excel. El archivo `Analisis_Ventas.xlsx` es una instantánea del análisis y no contiene esas consultas incorporadas.

El script de la carpeta `verificacion/` sirve como comprobación independiente; la transformación principal está en Power Query.

Fuente: *Retail Store Sales: Dirty for Data Cleaning*, de Kaggle. Los datos son sintéticos y no especifican divisa.
