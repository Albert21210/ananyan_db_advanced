-- 2. источники в mssql Front
-- каждый select выполнять отдельно и сохранять csv с заголовками

-- 1. ranges.csv - как на занятии
select ID as external_id, sizeid as name, portionrate as factor
from [size];

-- 2. categories.csv - как на занятии
select id as external_id, description as name,
       case when isnull(ParentID, 0) = 0 then null else ParentID end as parent_external_id
from category;

-- 3. vendor_groups.csv
select vendorgroupid as external_id, description as name
from vendorgroup;

-- 4. vendors.csv - связь с группой, как на занятии
select v.id as external_id, v.clientid as name,
       v.clientgroup as group_external_id
from vendors v;

-- 5. products.csv
select id as external_id, description as name,
       CategoryID as category_external_id,
       vendorid as vendor_external_id,
       SizeID as range_external_id
from product;

-- 6. personnel.csv - без персональных паролей
select personid as external_id,
       ltrim(rtrim(concat(firstname, ' ', lastname))) as name
from personnel;

-- 7. storages.csv
select id as external_id, description as name
from storages;

-- 8. purchases.csv - закупки продукции
select o.ID as source_id, convert(date, d.Period) as dt,
       o.ProductID as product_external_id, o.VendorID as vendor_external_id,
       o.StorageID as storage_external_id,
       o.[Count] as quantity, o.Amount as amount
from bm_StorageOperations o
join bm_JournalBarnetDocs d on o.DocumentID = d.ID
where o.OperationID = 1 and d.DocumentTypeID = 4
  and d.Period is not null;

-- 9. sales.csv - факты продаж
select ID as source_id, convert(date, TicketDate) as dt,
       TicketNumber as ticket_number, BludoName as product_name,
       quantity, price, amount
from vw_SalesTicketInfo
where TicketDate is not null;

-- 10. work_hours.csv - таблица может быть пустой
select ID as source_id, convert(date, DateR) as dt,
       PersonID as person_external_id,
       SystemPeriod as system_period, ManualPeriod as manual_period
from bm_WorkHours
where DateR is not null;

-- 11. stock_moves.csv - движение, не текущие остатки
select o.ID as source_id, convert(date, d.Period) as dt,
       o.ProductID as product_external_id, o.StorageID as storage_external_id,
       case when o.OperationID = 1 then abs(o.[Count])
            when o.OperationID = 2 then -abs(o.[Count]) end as quantity_change
from bm_StorageOperations o
join bm_JournalBarnetDocs d on o.DocumentID = d.ID
where o.OperationID in (1, 2) and d.Period is not null;

-- 12. stock_balance.csv - таблица может быть пустой
select convert(date, getdate()) as snapshot_date,
       storageid as storage_external_id,
       productid as product_code, onhand
from storagesonhand;
