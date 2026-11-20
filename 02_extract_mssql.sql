-- 2. выборки из mssql Front (каждый запрос сохранить в отдельный csv)

-- purchases.csv - закупки
select o.ID as id, convert(date, d.Period) as dt,
       o.ProductID as product_id, o.VendorID as vendor_id,
       o.StorageID as storage_id, o.[Count] as quantity, o.Amount as amount
from bm_StorageOperations o
join bm_JournalBarnetDocs d on o.DocumentID = d.ID
where o.OperationID = 1 and d.DocumentTypeID = 4 and d.Period is not null;

-- sales.csv - продажи
select ID as id, convert(date, TicketDate) as dt,
       TicketNumber as ticket_number, BludoName as product_name,
       quantity, price, amount
from vw_SalesTicketInfo
where TicketDate is not null;

-- personnel.csv - сотрудники
select personid as person_id,
       ltrim(rtrim(concat(firstname, ' ', lastname))) as person_name
from personnel;

-- work_hours.csv - время работы (исходная таблица пустая)
select ID as id, convert(date, DateR) as dt,
       PersonID as person_id, SystemPeriod as system_period,
       ManualPeriod as manual_period
from bm_WorkHours
where DateR is not null;

-- stock_moves.csv - движение товаров, плюс/минус
select o.ID as id, convert(date, d.Period) as dt,
       o.ProductID as product_id, o.StorageID as storage_id,
       case when o.OperationID = 1 then abs(o.[Count])
            when o.OperationID = 2 then -abs(o.[Count]) end as quantity_change
from bm_StorageOperations o
join bm_JournalBarnetDocs d on o.DocumentID = d.ID
where o.OperationID in (1, 2) and d.Period is not null;

-- stock_balance.csv - остатки (исходная таблица пустая)
select convert(date, getdate()) as snapshot_date,
       storageid as storage_id, productid as product_code, onhand
from storagesonhand;
