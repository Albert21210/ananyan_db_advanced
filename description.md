# Анализ таблиц (Задание 2)

## 1. Закупки продукции

Основная таблица: bm_StorageOperations - складские операции.

- ID - номер операции (4780421)
- DocumentID - номер документа (388235)
- ProductID - номер товара (4368)

Связанные таблицы:
bm_JournalBarnetDocs - документы операций.

- ID - номер документа (1216)
- ShiftID - номер смены (65)
- DocumentTypeID - тип документа (1)

bm_StorageOperations_Table - складские операции.

- ID - номер операции (134198)
- DocumentID - номер документа (388540)
- OperationID - тип операции (2)
- StorageID - номер склада (41)
- ProductID - номер товара (4345)

product - справочник товаров.

- id - номер товара (4337)
- productid - код товара (1204073)
- description - название товара (Бананы)
- vendorid - номер поставщика (107)
- flaging - флаг состояния товара (1)

vendors - справочник поставщиков.

- id - номер поставщика (90)
- clientid - название поставщика (Габур)
- clientgroup - группа поставщика (32)
- serialnumber - серийный номер (0)
- firstname - наименование поставщика (ИП Габур)

bm_JournalTypeDocuments - типы документов.

- ID - номер типа документа (1)
- Description - название типа (Ввод состава нового рецепта)
- JournalID - номер журнала (1)
- IsParent - признак родительского типа документа (0)

bm_Contracts - договоры.

- ID - номер договора (данных нет)
- ParentType - тип родительского объекта (данных нет)
- CompanyID - номер организации (данных нет)
- VendorID - номер поставщика (данных нет)

storages - склады.

- id - номер склада (41)
- CompanyID - номер организации (6)
- description - название склада (Склад)
- CityID - номер города (NULL)

bm_StorageOperationsType - типы складских операций.

- ID - номер типа операции (1)
- Description - название операции (Поступление)
- Factor - коэффициент операции (1)
- DateAdd - дата добавления (2013-01-15 15:19:12.517)


Связи:
- bm_StorageOperations.DocumentID ссылается на bm_JournalBarnetDocs.ID - операция связана с документом
- bm_JournalBarnetDocs.DocumentTypeID соответствует bm_JournalTypeDocuments.ID - документ связан со своим типом
- bm_StorageOperations.OperationID соответствует bm_StorageOperationsType.ID - операция связана со своим типом
- bm_StorageOperations.StorageID соответствует storages.id - операция связана со складом
- bm_StorageOperations.ContractID может соответствовать bm_Contracts.ID - таблица договоров существует, но записей в ней нет


## 2. Продажи товаров

Основная таблица: product - справочник товаров.

- id - номер товара (4337)
- productid - код товара (1204073)
- description - название товара (Бананы)

Связанные таблицы: 
pricelist - информация о ценах.

- id - номер записи (113681)
- DocumentID - номер документа (142417)

vw_SalesTicketInfo - информация о продажах товаров и блюд.

- ID - номер записи (1675807)
- TicketNumber - номер чека (10329777)
- TicketDate - дата продажи (2020-11-11 23:27:34.000)
- ProductType - тип продукции (Блюдо)
- BludoID - номер блюда (4520)

vw_SalesTicketInfo - это таблица фактов продаж

Связи:
- pricelist.productid соответствует product.id - цена относится к определённому товару
- vw_SalesTicketInfo содержит фактические продажи по чекам, включая номер, дату и проданную позицию


## 3. Поставщики

Основная таблица: vendors - справочник поставщиков.

- id - номер поставщика (90)
- clientid - название поставщика (Габур)
- clientgroup - группа поставщика (32)

Связанные таблицы: 
bm_StorageOperations - складские операции.

- ID - номер операции (4780421)
- DocumentID - номер документа (388235)
- OperationID - тип операции (1)

bm_JournalBarnetDocs - документы операций.

- ID - номер документа (1216)
- JournalID - номер журнала (1)
- ShiftID - номер смены (65)
- DocumentNumber - номер документа в журнале (1)
- Period - дата документа (2013-07-23 10:00:00.000)

Связи:
- bm_StorageOperations.VendorID соответствует vendors.id - операция связана с поставщиком
- bm_StorageOperations.DocumentID соответствует bm_JournalBarnetDocs.ID - операция связана с документом
- Данные для точного расчёта задолженности поставщикам пока не нашел

## 4. Персонал

Основная таблица: personnel - информация о сотрудниках.

- personid - номер сотрудника (897)
- firstname - имя (Администратор Barnet)
- lastname - фамилия (пусто)

Связанные таблицы: 
bm_BonusHistory - история бонусов.

- ID - номер записи (1)
- ClientID - номер клиента (3352)
- ActionName - название действия (User)

bm_WorkHours - учёт рабочего времени сотрудников.

- ID - номер записи (данных нет)
- ShiftID - номер смены (данных нет)
- PersonID - номер сотрудника (данных нет)
- PersonName - имя сотрудника (данных нет)


Связи:
- bm_BonusHistory.PersonID соответствует personnel.personid - запись о бонусах связана с сотрудником
- bm_WorkHours.PersonID предположительно относится к personnel.personid - таблица рабочего времени пустая

## 5. Остатки

Основная таблица: bm_StorageOperations_Table - складские операции.

- ID - номер операции (134198)
- DocumentID - номер документа (388540)
- StorageID - номер склада (41)

Связанные таблицы: 
bm_JournalBarnetDocs - документы операций.

- ID - номер документа (1216)
- ShiftID - номер смены (65)
- DocumentTypeID - тип документа (1)

bm_Journal_Details - детали журнала товаров.

- ID - номер записи (11530445)
- SourceID - номер источника (1675591)
- ProductID - номер товара (4407)
- Quantity - количество (1.0000)
- StorageID - номер склада (41)

Связи:
- bm_StorageOperations_Table.DocumentID соответствует bm_JournalBarnetDocs.ID - складская операция связана с документом
- bm_Journal_Details содержит ProductID и Quantity для описания товарных позиций и их количества
