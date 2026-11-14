-- Задание 1. Анализ наличия ресурсов

-- 1. Закупки
select * from bm_StorageOperations;

-- 2. Продажи
select * from vw_SalesTicketInfo;

-- 3. Поставщики
select * from vendors;

-- 4. Персонал
select * from personnel;

-- 5. Остатки
select * from bm_StorageOperations_Table;

-- Задание 2. Список основных и связанных таблиц

-- 1. Закупки
select * from bm_StorageOperations; -- складские операции
select * from bm_JournalBarnetDocs; -- документы операций

-- 2. Продажи
select * from product; -- справочник товаров
select * from pricelist; -- информация о ценах

-- 3. Поставщики
select * from vendors; -- справочник поставщиков
select * from bm_StorageOperations; -- складские операции

-- 4. Персонал
select * from personnel; -- информация о сотрудниках
select * from bm_BonusHistory; -- история бонусов

-- 5. Остатки
select * from bm_StorageOperations_Table; -- складские операции
select * from bm_JournalBarnetDocs; -- документы операций

-- Задание 4. Запросы которые подтверждают корректность выводов

-- 1. Закупки - соединяем операции с документами
select * from bm_StorageOperations 
join bm_JournalBarnetDocs on bm_StorageOperations.DocumentID = bm_JournalBarnetDocs.ID;

-- 2. Продажи - соединяем цены с товарами
select * from pricelist 
join product on pricelist.productid = product.id;

-- 3. Поставщики - соединяем операции с поставщиками
select * from bm_StorageOperations 
join vendors on bm_StorageOperations.VendorID = vendors.id;

-- 4. Персонал - соединяем сотрудников с историей бонусов
select * from bm_BonusHistory 
join personnel on bm_BonusHistory.PersonID = personnel.personid;

-- 5. Остатки - соединяем складские операции с документами
select * from bm_StorageOperations_Table 
join bm_JournalBarnetDocs on bm_StorageOperations_Table.DocumentID = bm_JournalBarnetDocs.ID;
