-- =====================================================================
-- Table: TSA.Restaurant
-- Description: Participating restaurants and food providers.
--              serviceTypes is comma-separated: pickup,delivery,dine-in,food-truck
-- =====================================================================

CREATE TABLE [TSA].[Restaurant] (
    [id]            UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [name]          NVARCHAR(200)       NOT NULL,
    [address]       NVARCHAR(500)       NOT NULL,
    [latitude]      DECIMAL(9,6)        NULL,
    [longitude]     DECIMAL(9,6)        NULL,
    [cuisineType]   NVARCHAR(100)       NULL,
    [serviceTypes]  NVARCHAR(200)       NULL,
    [phone]         NVARCHAR(30)        NULL,
    [description]   NVARCHAR(1000)      NULL,
    [imageUrl]      NVARCHAR(500)       NULL,
    [dailyQuota]    INT                 NOT NULL    DEFAULT 50,
    [isActive]      BIT                 NOT NULL    DEFAULT 1,
    [createdAt]     DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT [PK_TSA_Restaurant] PRIMARY KEY ([id])
);
