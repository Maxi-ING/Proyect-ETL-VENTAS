let
    Fuente = Csv.Document(File.Contents(pRutaCSV), [Delimiter=",", Columns=11, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Fuente, [PromoteAllScalars=true]),
    Campos = {"Transaction ID", "Customer ID", "Category", "Item", "Price Per Unit", "Quantity", "Total Spent", "Payment Method", "Location", "Transaction Date", "Discount Applied"},
    TextoLimpio = Table.TransformColumns(Encabezados, List.Transform(Campos, (c) => {c, (v) => let t = if v = null then null else Text.Trim(Text.From(v)) in if t = null or List.Contains({"", "none", "null", "nan"}, Text.Lower(t)) then null else t, type nullable text})),
    Tipos = Table.TransformColumns(TextoLimpio, {
        {"Price Per Unit", each try Number.FromText(_, "en-US") otherwise null, type nullable number},
        {"Quantity", each try Number.FromText(_, "en-US") otherwise null, type nullable number},
        {"Total Spent", each try Number.FromText(_, "en-US") otherwise null, type nullable number},
        {"Transaction Date", each try Date.FromText(_, [Format="yyyy-MM-dd", Culture="en-US"]) otherwise null, type nullable date}
    }),
    MapaBase = Table.SelectRows(Tipos, each [Category] <> null and [Item] <> null and [Price Per Unit] <> null),
    Agrupado = Table.Group(MapaBase, {"Category", "Price Per Unit"}, {{"Opciones", each List.Distinct([Item]), type list}}),
    MapaUnico = Table.TransformColumns(Table.SelectRows(Agrupado, each List.Count([Opciones]) = 1), {{"Opciones", each List.First(_), type text}}),
    PrecioResuelto = Table.AddColumn(Tipos, "_Precio", each if [Price Per Unit] <> null then [Price Per Unit] else if [Quantity] <> null and [Quantity] > 0 and [Total Spent] <> null then [Total Spent] / [Quantity] else null, type nullable number),
    Mapeado = Table.NestedJoin(PrecioResuelto, {"Category", "_Precio"}, MapaUnico, {"Category", "Price Per Unit"}, "Mapa", JoinKind.LeftOuter),
    MapaExpandido = Table.ExpandTableColumn(Mapeado, "Mapa", {"Opciones"}, {"_ItemMapa"}),
    ArticuloResuelto = Table.AddColumn(MapaExpandido, "_Item", each if [Item] <> null then [Item] else [_ItemMapa], type nullable text),
    Estado = Table.AddColumn(ArticuloResuelto, "Estado Calidad", each
        if [Transaction ID] = null or [Customer ID] = null or [Category] = null or [Payment Method] = null or [Location] = null or [Transaction Date] = null then "Dimensión/fecha inválida"
        else if [_Item] = null then "Artículo no identificable"
        else if [_Precio] = null or [_Precio] <= 0 or [Quantity] = null or [Quantity] <= 0 or Number.Mod([Quantity], 1) <> 0 or [Total Spent] = null or [Total Spent] <= 0 then "Importe/cantidad no recuperable"
        else if Number.Abs([_Precio] * [Quantity] - [Total Spent]) > 0.001 then "Total inconsistente"
        else if [Discount Applied] <> null and not List.Contains({"true", "false"}, Text.Lower([Discount Applied])) then "Descuento inválido"
        else "Válida", type text),
    Descuento = Table.AddColumn(Estado, "_Descuento", each if [Discount Applied] = null then "Desconocido" else if Text.Lower([Discount Applied]) = "true" then "Sí" else if Text.Lower([Discount Applied]) = "false" then "No" else "Inválido", type text),
    OrigenPrecio = Table.AddColumn(Descuento, "Origen Precio", each if [Price Per Unit] <> null then "Original" else if [_Precio] <> null then "Derivado: total / cantidad" else "No recuperable", type text),
    OrigenArticulo = Table.AddColumn(OrigenPrecio, "Origen Artículo", each if [Item] <> null then "Original" else if [_Item] <> null then "Inferido: categoría + precio único" else "No recuperable", type text),
    Anio = Table.AddColumn(OrigenArticulo, "Año", each if [Transaction Date] = null then null else Date.Year([Transaction Date]), Int64.Type),
    Mes = Table.AddColumn(Anio, "Mes", each if [Transaction Date] = null then null else Date.Month([Transaction Date]), Int64.Type),
    AnioMes = Table.AddColumn(Mes, "AñoMes", each if [Transaction Date] = null then null else Date.ToText([Transaction Date], "yyyy-MM"), type text),
    Canal = Table.AddColumn(AnioMes, "Canal", each [Location], type nullable text),
    Ingreso = Table.AddColumn(Canal, "Ingreso Validado", each if [Estado Calidad] = "Válida" then [_Precio] * [Quantity] else null, type nullable number),
    QuitarTemporales = Table.RemoveColumns(Ingreso, {"Price Per Unit", "Item", "Discount Applied", "_ItemMapa"}),
    Renombrar = Table.RenameColumns(QuitarTemporales, {{"_Precio", "Price Per Unit"}, {"_Item", "Item"}, {"_Descuento", "Discount Applied"}}),
    Ordenar = Table.ReorderColumns(Renombrar, {"Transaction ID", "Customer ID", "Category", "Item", "Price Per Unit", "Quantity", "Total Spent", "Payment Method", "Location", "Transaction Date", "Discount Applied", "Año", "Mes", "AñoMes", "Canal", "Ingreso Validado", "Origen Precio", "Origen Artículo", "Estado Calidad"}),
    Repetidos = Table.Group(Ordenar, {"Transaction ID"}, {{"CuentaID", each Table.RowCount(_), Int64.Type}}),
    UnirID = Table.NestedJoin(Ordenar, {"Transaction ID"}, Repetidos, {"Transaction ID"}, "IDs", JoinKind.LeftOuter),
    ExpandirID = Table.ExpandTableColumn(UnirID, "IDs", {"CuentaID"}, {"CuentaID"}),
    MarcarDuplicados = Table.AddColumn(ExpandirID, "_EstadoFinal", each if [CuentaID] > 1 or [Transaction ID] = null then "ID ausente/duplicado" else [Estado Calidad], type text),
    SinAuxiliares = Table.RemoveColumns(MarcarDuplicados, {"CuentaID", "Estado Calidad"}),
    Resultado = Table.RenameColumns(SinAuxiliares, {{"_EstadoFinal", "Estado Calidad"}})
in
    Resultado
