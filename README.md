# ETL y calidad de datos de ventas

Proyecto de limpieza y validación de **12.575 transacciones** de retail con **Excel y Power Query**. El flujo recupera valores cuando los datos permiten verificarlos y separa las transacciones cuyo importe no puede reconstruirse. El [caso de estudio en el portafolio](https://app.notion.com/p/3e4711ab612480d1b895cd1919fcf149) explica las decisiones y el análisis.

## Resultado

| Indicador | Valor |
| --- | ---: |
| Ventas válidas | 11.971 |
| Registros para revisión | 604 |
| Precios recuperados desde total / cantidad | 609 |
| Artículos inferidos por categoría y precio único | 1.213 |
| Ingresos de ventas válidas | 1.552.071 unidades monetarias |

## Archivos

- `datos/retail_store_sales.csv`: fuente original, sin modificar.
- `power-query/*.pq`: consultas M del proceso (`Ventas_Transformadas`, `Ventas_Limpias` y `Ventas_Rechazadas`).
- `datos/Ventas_Limpias.csv` y `datos/Ventas_Rechazadas.csv`: salidas de la ejecución verificada sobre este CSV.
- `analisis/Analisis_Ventas.xlsx`: instantánea de indicadores y análisis; **no incluye las consultas Power Query incorporadas**.
- `analisis/diagnostico.json` y `verificacion/procesar_retail.py`: cifras de control y script independiente de verificación.

## Ejecutar las consultas en Excel

1. Descarga el repositorio y abre Excel de escritorio. En Power Query, crea un parámetro de texto `pRutaCSV` con la ruta **completa al archivo** `datos/retail_store_sales.csv` de tu equipo.
2. Crea una consulta en blanco llamada `Ventas_Transformadas` y pega en su Editor avanzado el contenido de `power-query/Ventas_Transformadas.pq`. Cárgala solo como conexión.
3. Repite con `Ventas_Limpias.pq` y `Ventas_Rechazadas.pq`, usando esos mismos nombres de consulta. Carga ambas como tablas y utiliza **Datos → Actualizar todo** para repetir el proceso.

Los importes del CSV usan punto decimal; la consulta aplica la configuración regional `en-US`. En esta versión se obtienen 11.971 ventas válidas y 604 registros apartados. Si cambia el archivo de origen, vuelve a comprobar los recuentos y actualiza los resúmenes de la instantánea de Excel.

**Fuente:** [Retail Store Sales: Dirty for Data Cleaning, Kaggle](https://www.kaggle.com/datasets/ahmedmohamed2003/retail-store-sales-dirty-for-data-cleaning). Datos sintéticos; el archivo no especifica divisa.
