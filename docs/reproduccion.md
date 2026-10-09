# ETL Ventas | Repetir el proceso en Excel

**Las consultas de Power Query permiten volver a generar las ventas limpias y los casos para revisión.** La fuente y las salidas están en `datos/`; el archivo de `analisis/` es una instantánea, sin las consultas incorporadas.

## Pasos

1. Descarga el repositorio y abre Excel de escritorio.
2. En Power Query, crea un parámetro de texto llamado `pRutaCSV`. Indica la ruta completa al archivo `datos/retail_store_sales.csv` de tu equipo.
3. Crea una consulta en blanco llamada `Ventas_Transformadas`. En el Editor avanzado, pega el contenido de `power-query/Ventas_Transformadas.pq` y cárgala solo como conexión.
4. Crea las consultas `Ventas_Limpias` y `Ventas_Rechazadas` con sus archivos de la carpeta `power-query/`. Carga ambas como tablas.
5. Usa **Datos → Actualizar todo** para repetir el proceso.

## Resultado esperado

Con la fuente publicada, las salidas contienen **11.971 ventas válidas y 604 registros para revisión**, que suman las 12.575 transacciones originales.

Los importes del CSV utilizan punto decimal; las consultas aplican la configuración regional `en-US`. Si cambias la fuente, comprueba los nuevos recuentos y actualiza los resúmenes de Excel.

Las cifras de la entrega están en `analisis/diagnostico.json`. La carpeta `verificacion/` contiene una comprobación independiente en Python.
