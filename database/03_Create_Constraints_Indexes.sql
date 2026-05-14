USE EV_Charging_System;
GO

CREATE INDEX IX_Region_CountryID ON Core.Region(CountryID);
CREATE INDEX IX_Address_RegionID ON Core.Address(RegionID);

CREATE INDEX IX_UserAccount_Status ON [Identity].UserAccount(AccountStatus);
CREATE INDEX IX_UserRole_RoleID ON [Identity].UserRole(RoleID);
CREATE INDEX IX_StaffProfile_Region ON [Identity].StaffProfile(ManagedRegionID);

CREATE INDEX IX_FranchisePartner_Status ON Franchise.FranchisePartner(PartnerStatus);
CREATE INDEX IX_FranchiseContract_FranchiseID ON Franchise.FranchiseContract(FranchiseID);
CREATE INDEX IX_FranchiseContract_Status_EndDate ON Franchise.FranchiseContract(ContractStatus, EndDate);
CREATE INDEX IX_FranchiseStation_StationID ON Franchise.FranchiseStation(StationID);
CREATE INDEX IX_RevenueSharePolicy_Contract ON Franchise.RevenueSharePolicy(ContractID, IsActive);
CREATE INDEX IX_RevenueShareSettlement_Franchise_Period ON Franchise.RevenueShareSettlement(FranchiseID, PeriodStart, PeriodEnd);
CREATE INDEX IX_RevenueShareSettlement_Status ON Franchise.RevenueShareSettlement(SettlementStatus);

CREATE INDEX IX_ElectricitySupplier_Region ON Infrastructure.ElectricitySupplier(RegionID);
CREATE INDEX IX_ChargingStation_FranchiseID ON Infrastructure.ChargingStation(FranchiseID);
CREATE INDEX IX_ChargingStation_Status ON Infrastructure.ChargingStation(StationStatus);
CREATE INDEX IX_ChargingStation_AddressID ON Infrastructure.ChargingStation(AddressID);
CREATE INDEX IX_StationConnectorType_Connector ON Infrastructure.StationConnectorType(ConnectorTypeID);
CREATE INDEX IX_ChargingPoint_StationID ON Infrastructure.ChargingPoint(StationID);
CREATE INDEX IX_ChargingPoint_ConnectorStatus ON Infrastructure.ChargingPoint(ConnectorTypeID, PointStatus);
CREATE INDEX IX_PointStatusHistory_PointTime ON Infrastructure.PointStatusHistory(PointID, ChangedAt DESC);
CREATE INDEX IX_PointTelemetry_PointTime ON Infrastructure.PointTelemetry(PointID, RecordedAt DESC);
CREATE INDEX IX_PointTelemetry_Health ON Infrastructure.PointTelemetry(HealthStatus, RecordedAt DESC);

CREATE INDEX IX_Vehicle_UserID ON Operations.Vehicle(UserID);
CREATE INDEX IX_Booking_UserTime ON Operations.Booking(UserID, BookedFrom DESC);
CREATE INDEX IX_Booking_PointTime ON Operations.Booking(PointID, BookedFrom, BookedTo);
CREATE INDEX IX_Booking_Status ON Operations.Booking(BookingStatus);
CREATE INDEX IX_ChargingSession_UserTime ON Operations.ChargingSession(UserID, StartTime DESC);
CREATE INDEX IX_ChargingSession_StationTime ON Operations.ChargingSession(StationID, StartTime DESC);
CREATE INDEX IX_ChargingSession_PointStatus ON Operations.ChargingSession(PointID, SessionStatus);
CREATE INDEX IX_ChargingSession_StatusTime ON Operations.ChargingSession(SessionStatus, StartTime DESC);
CREATE INDEX IX_SessionEvent_Session ON Operations.SessionEvent(SessionID, CreatedAt DESC);

CREATE INDEX IX_Wallet_UserID ON Payments.Wallet(UserID);
CREATE INDEX IX_PaymentTransaction_UserTime ON Payments.PaymentTransaction(UserID, TransactedAt DESC);
CREATE INDEX IX_PaymentTransaction_SessionID ON Payments.PaymentTransaction(SessionID);
CREATE INDEX IX_PaymentTransaction_StatusType ON Payments.PaymentTransaction(TransactionStatus, TransactionType);
CREATE INDEX IX_WalletTransaction_WalletTime ON Payments.WalletTransaction(WalletID, CreatedAt DESC);
CREATE INDEX IX_QRPaymentRequest_StatusExpire ON Payments.QRPaymentRequest(RequestStatus, ExpiresAt);
CREATE INDEX IX_Invoice_UserTime ON Payments.Invoice(UserID, IssuedAt DESC);
CREATE INDEX IX_Invoice_SessionID ON Payments.Invoice(SessionID);
CREATE INDEX IX_Refund_OriginalTransaction ON Payments.Refund(OriginalTransactionID);
CREATE INDEX IX_Refund_Status ON Payments.Refund(RefundStatus);

CREATE INDEX IX_ErrorLog_PointTime ON Maintenance.ErrorLog(PointID, OccurredAt DESC);
CREATE INDEX IX_ErrorLog_StationActive ON Maintenance.ErrorLog(StationID, IsActive);
CREATE INDEX IX_MaintenanceTicket_StatusPriority ON Maintenance.MaintenanceTicket(TicketStatus, Priority);
CREATE INDEX IX_MaintenanceTicket_Point ON Maintenance.MaintenanceTicket(PointID);
CREATE INDEX IX_MaintenanceAssignment_Technician ON Maintenance.MaintenanceAssignment(TechnicianUserID);
CREATE INDEX IX_MaintenanceHistory_TicketTime ON Maintenance.MaintenanceHistory(TicketID, ChangedAt DESC);

CREATE INDEX IX_AuditLog_TableTime ON Audit.AuditLog(SchemaName, TableName, ChangedAt DESC);

PRINT N'03 - Indexes created.';
GO
