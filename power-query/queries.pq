// Power Query (M) — Integrated Business Analysis
// Data preparation by Fay Naif.
// The long embedded copy of the dataset is shortened to <embedded copy of the data>; the full query is in the .SemanticModel folder.

// ===== Table: Orders =====
let
    // 1) Try the Excel file at the FilePath parameter; 2) if it is not there, use the copy of the same data embedded below.
    FromFile = try Table.Buffer(Excel.Workbook(File.Contents(FilePath), null, true){[Item="Superstore",Kind="Sheet"]}[Data]) otherwise null,
    Embedded = Table.PromoteHeaders(Csv.Document(Binary.Decompress( Binary.FromText("<embedded copy of the data>", BinaryEncoding.Base64), Compression.Deflate), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]), [PromoteAllScalars=true]),
    Source = if FromFile <> null then FromFile else Embedded,
    Selected = Table.SelectColumns(Source, {"row_id", "order_id", "order_date", "ship_date", "ship_mode", "customer_id", "customer_name", "segment", "city", "state", "postal_code", "region", "product_id", "category", "sub_category", "product_name", "sales", "quantity", "discount", "profit", "order_year", "order_month", "days_to_ship", "discount_band", "is_returned", "region_manager"}),
    AsText = Table.TransformColumnTypes(Selected, {{"postal_code", type text}}),
    Typed = Table.TransformColumnTypes(AsText, {{"row_id", Int64.Type}, {"order_id", type text}, {"order_date", type date}, {"ship_date", type date}, {"ship_mode", type text}, {"customer_id", type text}, {"customer_name", type text}, {"segment", type text}, {"city", type text}, {"state", type text}, {"postal_code", type text}, {"region", type text}, {"product_id", type text}, {"category", type text}, {"sub_category", type text}, {"product_name", type text}, {"sales", type number}, {"quantity", Int64.Type}, {"discount", type number}, {"profit", type number}, {"order_year", Int64.Type}, {"order_month", type text}, {"days_to_ship", Int64.Type}, {"discount_band", type text}, {"is_returned", Int64.Type}, {"region_manager", type text}}, "en-US"),
    BandOrder = Table.AddColumn(Typed, "discount_band_order", each if [discount_band] = "0%" then 1 else if [discount_band] = "1-10%" then 2 else if [discount_band] = "11-20%" then 3 else if [discount_band] = "21-30%" then 4 else if [discount_band] = "31-50%" then 5 else 6, Int64.Type)
in
    BandOrder

// ===== Calculated table (DAX): Date =====
Date =
ADDCOLUMNS(CALENDAR(DATE(YEAR(MIN(Orders[order_date])), 1, 1), DATE(YEAR(MAX(Orders[order_date])), 12, 31)), "Year", YEAR([Date]), "Quarter", "Q" & QUARTER([Date]), "Month Num", MONTH([Date]), "Month", FORMAT([Date], "MMM"), "Year Month", FORMAT([Date], "MMM yyyy"), "YearMonthNum", YEAR([Date]) * 100 + MONTH([Date]))

// ===== Parameter: FilePath =====
FilePath = "C:\Users\Public\Superstore_Clean.xlsx" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
