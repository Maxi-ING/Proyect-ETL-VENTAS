"""Replica verificable de las reglas de Ventas_Transformadas.pq.

Uso: python procesar_retail.py retail_store_sales.csv directorio_salida
"""
import csv
import json
import sys
from collections import Counter, defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path

SOURCE = "https://www.kaggle.com/datasets/ahmedmohamed2003/retail-store-sales-dirty-for-data-cleaning"
FIELDS = ["Transaction ID", "Customer ID", "Category", "Item", "Price Per Unit", "Quantity", "Total Spent", "Payment Method", "Location", "Transaction Date", "Discount Applied"]
OUT = ["Transaction ID", "Customer ID", "Category", "Item", "Price Per Unit", "Quantity", "Total Spent", "Payment Method", "Location", "Transaction Date", "Discount Applied", "Año", "Mes", "AñoMes", "Canal", "Ingreso Validado", "Origen Precio", "Origen Artículo", "Estado Calidad"]

def blank(v):
    s = (v or "").strip()
    return None if s.lower() in ("", "none", "null", "nan") else s

def dec(v):
    if v is None: return None
    try: return Decimal(v)
    except InvalidOperation: return None

def fmt(v):
    return "" if v is None else format(v, "f")

def main(src, dest):
    dest.mkdir(parents=True, exist_ok=True)
    with src.open(encoding="utf-8-sig", newline="") as f:
        raw = list(csv.DictReader(f))
    rows = [{k: blank(r.get(k)) for k in FIELDS} for r in raw]
    if list(raw[0]) != FIELDS: raise ValueError("Esquema inesperado: revisar columnas del CSV")
    missing = {k: sum(r[k] is None for r in rows) for k in FIELDS}
    mapping = defaultdict(set)
    for r in rows:
        p = dec(r["Price Per Unit"])
        if r["Category"] and r["Item"] and p is not None:
            mapping[(r["Category"],p)].add(r["Item"])
    unambiguous = {k:next(iter(v)) for k,v in mapping.items() if len(v)==1}
    ids = Counter(r["Transaction ID"] for r in rows)
    cleaned, rejected = [], []
    for r in rows:
        d = dict(r)
        p,q,t = (dec(r[k]) for k in ("Price Per Unit", "Quantity", "Total Spent"))
        price_origin = "Original"
        if p is None and q is not None and q>0 and t is not None:
            p = t/q
            price_origin = "Derivado: total / cantidad"
        item_origin = "Original"
        if d["Item"] is None and (d["Category"],p) in unambiguous:
            d["Item"] = unambiguous[(d["Category"],p)]
            item_origin = "Inferido: categoría + precio único"
        try: dt = date.fromisoformat(d["Transaction Date"] or "")
        except ValueError: dt = None
        disc = (d["Discount Applied"] or "").lower()
        discount = "Sí" if disc == "true" else "No" if disc == "false" else "Desconocido"
        reasons = []
        if not d["Transaction ID"] or ids[d["Transaction ID"]]>1: reasons.append("ID ausente/duplicado")
        if not d["Customer ID"] or not d["Category"] or not d["Payment Method"] or not d["Location"] or not dt: reasons.append("Dimensión/fecha inválida")
        if not d["Item"]: reasons.append("Artículo no identificable")
        if p is None or p<=0 or q is None or q<=0 or q!=q.to_integral_value() or t is None or t<=0: reasons.append("Importe/cantidad no recuperable")
        if p is not None and q is not None and t is not None and abs(p*q-t)>Decimal("0.001"): reasons.append("Total inconsistente")
        if disc not in ("", "true", "false"): reasons.append("Descuento inválido")
        d.update({"Price Per Unit":fmt(p),"Quantity":fmt(q),"Total Spent":fmt(t),
                  "Transaction Date":dt.isoformat() if dt else "", "Discount Applied":discount,
                  "Año": dt.year if dt else "", "Mes":dt.month if dt else "",
                  "AñoMes": dt.strftime("%Y-%m") if dt else "", "Canal":d["Location"] or "",
                  "Ingreso Validado":fmt(p*q) if not reasons else "",
                  "Origen Precio":price_origin,"Origen Artículo":item_origin,
                  "Estado Calidad":"Válida" if not reasons else "; ".join(reasons)})
        (cleaned if not reasons else rejected).append(d)
    def write(name, data):
        with (dest/name).open("w",encoding="utf-8-sig",newline="") as f:
            w=csv.DictWriter(f,fieldnames=OUT);w.writeheader();w.writerows(data)
    write("Ventas_Limpias.csv",cleaned)
    write("Ventas_Rechazadas.csv",rejected)
    revenue=sum(Decimal(r["Ingreso Validado"]) for r in cleaned)
    cats=defaultdict(lambda:[0,Decimal(0)])
    months=defaultdict(lambda:[0,Decimal(0)])
    channels=defaultdict(lambda:[0,Decimal(0)])
    for r in cleaned:
        for group,key in ((cats,r["Category"]),(months,r["AñoMes"]),(channels,r["Location"])):
            group[key][0]+=1;group[key][1]+=Decimal(r["Ingreso Validado"])
    aslist=lambda g:[{"grupo":k,"transacciones":v[0],"ingresos":float(v[1])} for k,v in sorted(g.items())]
    report={"fuente":SOURCE,"registros_originales":len(rows),"nulos_por_columna":missing,"celdas_nulas":sum(missing.values()),
            "ids_duplicados":sum(v-1 for v in ids.values() if v>1),"precio_derivado":sum(r["Origen Precio"]!="Original" for r in cleaned+rejected),
            "articulo_inferido":sum(r["Origen Artículo"]!="Original" for r in cleaned+rejected),
            "registros_limpios":len(cleaned),"registros_rechazados":len(rejected),
            "motivos_rechazo":dict(Counter(reason for r in rejected for reason in r["Estado Calidad"].split("; "))),
            "descuento_desconocido_limpios":sum(r["Discount Applied"]=="Desconocido" for r in cleaned),
            "ingresos_validados":float(revenue),"ticket_medio":float(revenue/len(cleaned)),
            "por_categoria":aslist(cats),"por_mes":aslist(months),"por_canal":aslist(channels)}
    (dest/"diagnostico.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({k:report[k] for k in ("registros_originales","registros_limpios","registros_rechazados","precio_derivado","articulo_inferido","ingresos_validados")},ensure_ascii=False))

if __name__ == "__main__": main(Path(sys.argv[1]),Path(sys.argv[2]))
