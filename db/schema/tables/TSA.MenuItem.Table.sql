-- =====================================================================
-- Table: TSA.MenuItem
-- Description: Menu items offered by participating restaurants.
--              dailyQuota tracks how many of this dish can be reserved per day.
-- =====================================================================

CREATE TABLE [TSA].[MenuItem] (
    [id]            UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [restaurantId]  UNIQUEIDENTIFIER    NOT NULL,
    [name]          NVARCHAR(200)       NOT NULL,
    [description]   NVARCHAR(1000)      NULL,
    [imageUrl]      NVARCHAR(500)       NULL,
    [dailyQuota]    INT                 NOT NULL    DEFAULT 20,
    [isAvailable]   BIT                 NOT NULL    DEFAULT 1,
    [createdAt]     DATETIMEOFFSET(7)   NOT NULL    DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT [PK_TSA_MenuItem]            PRIMARY KEY ([id]),
    CONSTRAINT [FK_TSA_MenuItem_Restaurant] FOREIGN KEY ([restaurantId]) REFERENCES [TSA].[Restaurant]([id])
);

CREATE INDEX [IX_TSA_MenuItem_restaurant] ON [TSA].[MenuItem] ([restaurantId]);
