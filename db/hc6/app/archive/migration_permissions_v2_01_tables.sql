-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions V2, Phase 1a: source tables
-- =====================================================================
-- Creates the three data-driven permission tables. These are the SOURCE OF
-- TRUTH the server reads directly (indexed); the app reads compiled JSON
-- projections, not these tables. INERT until Phase 3 wires CheckKennelPermission
-- to read them — creating them changes no behaviour.
--
-- Not mobile-synced (no updatedAtBias/removed). Server-only.
-- INT identity PKs (not uniqueidentifier) deliberately — this is a hot lookup
-- path and narrow keys keep the covering index tight.
--
-- ⚠️  RUN MANUALLY, ONCE. Not picked up by deploy_hc6.sh. Archive after running.
-- =====================================================================
SET XACT_ABORT ON;
GO

-- Catalog of gate-able functions (the matrix columns).
IF OBJECT_ID('HC.PermissionFunction') IS NULL
BEGIN
    CREATE TABLE HC.PermissionFunction (
        id          INT IDENTITY(1,1) NOT NULL
                    CONSTRAINT PK_PermissionFunction PRIMARY KEY,
        FunctionKey NVARCHAR(80)  NOT NULL
                    CONSTRAINT UQ_PermissionFunction_Key UNIQUE,
        DisplayName NVARCHAR(120) NOT NULL,
        FeatureArea NVARCHAR(60)  NOT NULL,
        HareScoped  SMALLINT      NOT NULL
                    CONSTRAINT DF_PermissionFunction_HareScoped DEFAULT (0),
        SortOrder   INT           NOT NULL
                    CONSTRAINT DF_PermissionFunction_SortOrder DEFAULT (0)
    );
END
GO

-- Catalog of grantors — unifies mismanagement roles AND app-access flags.
-- GrantorType: 'mmRole' (bit tested against HKM.MismanagementRoles),
--              'appFlag' (bit tested against HKM.AppAccessFlags),
--              'bypass'  (SuperAdmin — grants everything in code, never a matrix cell).
IF OBJECT_ID('HC.PermissionRole') IS NULL
BEGIN
    CREATE TABLE HC.PermissionRole (
        id          INT IDENTITY(1,1) NOT NULL
                    CONSTRAINT PK_PermissionRole PRIMARY KEY,
        GrantorKey  NVARCHAR(80)  NOT NULL
                    CONSTRAINT UQ_PermissionRole_Key UNIQUE,
        DisplayName NVARCHAR(120) NOT NULL,
        GrantorType NVARCHAR(20)  NOT NULL
                    CONSTRAINT CK_PermissionRole_Type
                    CHECK (GrantorType IN ('mmRole','appFlag','bypass')),
        Bit         INT           NOT NULL,
        SortOrder   INT           NOT NULL
                    CONSTRAINT DF_PermissionRole_SortOrder DEFAULT (0)
    );
END
GO

-- The grants. KennelId NULL = global default (Allowed 1 = granted, absent = not).
-- KennelId set = per-kennel override, tri-state Allowed: 1 grant / -1 revoke /
-- 0 inherit. Effective = CASE kennelRow WHEN 1 THEN grant WHEN -1 THEN revoke
-- ELSE global END.
IF OBJECT_ID('HC.RolePermission') IS NULL
BEGIN
    CREATE TABLE HC.RolePermission (
        id         INT IDENTITY(1,1) NOT NULL
                   CONSTRAINT PK_RolePermission PRIMARY KEY,
        GrantorId  INT NOT NULL
                   CONSTRAINT FK_RolePermission_Grantor
                   REFERENCES HC.PermissionRole(id),
        FunctionId INT NOT NULL
                   CONSTRAINT FK_RolePermission_Function
                   REFERENCES HC.PermissionFunction(id),
        KennelId   UNIQUEIDENTIFIER NULL
                   CONSTRAINT FK_RolePermission_Kennel
                   REFERENCES HC.Kennel(id),
        Allowed    SMALLINT NOT NULL
                   CONSTRAINT DF_RolePermission_Allowed DEFAULT (1)
                   CONSTRAINT CK_RolePermission_Allowed CHECK (Allowed IN (-1,0,1))
    );

    -- One global row + one row per kennel, per (function, grantor).
    -- SQL Server treats NULLs as equal in a unique index, so this caps global
    -- rows at exactly one per cell.
    CREATE UNIQUE INDEX UQ_RolePermission_cell
        ON HC.RolePermission (FunctionId, GrantorId, KennelId);

    -- Hot lookup path for CheckKennelPermission.
    CREATE INDEX IX_RolePermission_lookup
        ON HC.RolePermission (FunctionId, KennelId, GrantorId) INCLUDE (Allowed);
END
GO
