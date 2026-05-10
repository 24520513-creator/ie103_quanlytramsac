USE EV_Charging_System;
GO

-- ============================================================
-- sp_ThrowError: Centralized error throwing helper
-- Looks up error message from ErrorCatalog by ErrorCode
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_ThrowError
    @ErrorCode INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Message NVARCHAR(500), @Severity NVARCHAR(10);

    SELECT @Message = ErrorMessage, @Severity = Severity
    FROM Infrastructure.ErrorCatalog
    WHERE ErrorCode = @ErrorCode;

    IF @Message IS NULL
    BEGIN
        SET @Message = N'Unknown error (Code: ' + CAST(@ErrorCode AS NVARCHAR(10)) + N')';
        SET @Severity = 'Error';
    END;

    DECLARE @SeverityInt INT = CASE @Severity
        WHEN 'Info' THEN 10
        WHEN 'Warning' THEN 16
        WHEN 'Error' THEN 16
        WHEN 'Critical' THEN 20
        ELSE 16
    END;

    THROW @ErrorCode, @Message, @SeverityInt;
END;
GO

PRINT N'Error handling created (sp_ThrowError).';
GO
