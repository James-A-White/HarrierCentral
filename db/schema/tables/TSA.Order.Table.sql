-- =====================================================================
-- Table: TSA.Order
-- Description: One meal order per worker per day. Token is encoded
--              in the QR code shown to restaurant staff for redemption.
-- =====================================================================

CREATE TABLE [TSA].[Order] (
    [id]            UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [token]         UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),
    [workerId]      UNIQUEIDENTIFIER    NOT NULL,
    [restaurantId]  UNIQUEIDENTIFIER    NOT NULL,
    [mealId]        UNIQUEIDENTIFIER    NOT NULL,
    [date]          DATE                NOT NULL,
    [redeemedAt]    DATETIME2(7)        NULL,
    [createdAt]     DATETIME2(7)        NOT NULL    DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_TSA_Order]               PRIMARY KEY ([id]),
    CONSTRAINT [UQ_TSA_Order_Token]         UNIQUE      ([token]),
    CONSTRAINT [UQ_TSA_Order_Worker_Date]   UNIQUE      ([workerId], [date]),
    CONSTRAINT [FK_TSA_Order_Worker]        FOREIGN KEY ([workerId])        REFERENCES [TSA].[Worker]([id]),
    CONSTRAINT [FK_TSA_Order_Restaurant]    FOREIGN KEY ([restaurantId])    REFERENCES [TSA].[Restaurant]([id]),
    CONSTRAINT [FK_TSA_Order_MenuItem]      FOREIGN KEY ([mealId])          REFERENCES [TSA].[MenuItem]([id])
);
