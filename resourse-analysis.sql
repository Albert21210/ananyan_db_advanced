-- Задание 1. Анализ наличия ресурсов

-- 1. Закупки
select * from bm_StorageOperations;
select * from bm_StorageOperations_Table;

-- 2. Продажи
select * from vw_SalesTicketInfo;

-- 3. Поставщики
select * from vendors;

-- 4. Персонал
select * from personnel;
select * from bm_WorkHours;

-- 5. Остатки
select * from bm_StorageOperations_Table;
select * from bm_Journal_Details;

-- Задание 2. Список основных и связанных таблиц

-- 1. Закупки
select * from bm_StorageOperations; -- складские операции
select * from bm_JournalBarnetDocs; -- документы операций
select * from bm_StorageOperations_Table; -- складские операции
select * from product; -- справочник товаров
select * from vendors; -- поставщики
select * from bm_JournalTypeDocuments; -- типы документов
select * from bm_Contracts; -- договоры
select * from storages; -- склады
select * from bm_StorageOperationsType; -- типы складских операций

-- 2. Продажи
select * from product; -- справочник товаров
select * from pricelist; -- информация о ценах
select * from vw_SalesTicketInfo; -- факты продаж

-- 3. Поставщики
select * from vendors; -- справочник поставщиков
select * from bm_StorageOperations; -- складские операции
select * from bm_JournalBarnetDocs; -- документы операций

-- 4. Персонал
select * from personnel; -- информация о сотрудниках
select * from bm_BonusHistory; -- история бонусов
select * from bm_WorkHours; -- рабочее время сотрудников

-- 5. Остатки
select * from bm_StorageOperations_Table; -- складские операции
select * from bm_JournalBarnetDocs; -- документы операций
select * from bm_Journal_Details; -- детали журнала

-- Задание 4. Запросы которые подтверждают корректность выводов

-- 1. Закупки - соединяем операции с документами
select * from bm_StorageOperations 
join bm_JournalBarnetDocs on bm_StorageOperations.DocumentID = bm_JournalBarnetDocs.ID;

-- соединяем документы и их типы
select * from bm_JournalBarnetDocs
join bm_JournalTypeDocuments on bm_JournalBarnetDocs.DocumentTypeID = bm_JournalTypeDocuments.ID;

-- соединяем операции и их типы
select * from bm_StorageOperations
join bm_StorageOperationsType on bm_StorageOperations.OperationID = bm_StorageOperationsType.ID;

-- соединяем операции и склады
select * from bm_StorageOperations
join storages on bm_StorageOperations.StorageID = storages.id;

-- соединяем операции и договоры
select * from bm_StorageOperations
join bm_Contracts on bm_StorageOperations.ContractID = bm_Contracts.ID;

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
