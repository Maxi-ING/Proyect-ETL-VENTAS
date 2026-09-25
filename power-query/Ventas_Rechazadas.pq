let
    Fuente = Ventas_Transformadas,
    Resultado = Table.SelectRows(Fuente, each [Estado Calidad] <> "Válida")
in
    Resultado
