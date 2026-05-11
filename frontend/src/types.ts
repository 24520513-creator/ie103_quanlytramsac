export type UserRole = 'client' | 'manager' | 'admin';

export interface Franchise {
  FranchiseID: number;
  FranchiseCode: string;
  FranchiseName: string;
  TaxCode: string;
  AddressID?: number;
  ContactPerson: string;
  ContactPhone: string;
  ContactEmail: string;
  RevenueShareRate: number;
  ContractSignedDate: string;
  IsActive?: boolean;
}

export interface ElectricitySupplier {
  SupplierID: number;
  SupplierCode: string;
  SupplierName: string;
  RegionID?: number;
  UnitPricePerKWh?: number;
  ContactPerson?: string;
  ContactPhone?: string;
  ContactEmail?: string;
  IsActive?: boolean;
}

export interface ChargingStation {
  StationID: number;
  StationCode: string;
  StationName: string;
  FranchiseID: number;
  AddressID?: number;
  Address?: string;
  ModelName?: string;
  Manufacturer?: string;
  MaxPowerKW?: number;
  ConnectorTypes?: string;
  Latitude?: number;
  Longitude?: number;
  StationStatus: 'Active' | 'Inactive' | 'UnderMaintenance' | 'Retired';
  ImageUrl?: string;
  Notes?: string;
  IsActive?: boolean;
}

export interface ChargingPoint {
  PointID: number;
  PointCode: string;
  StationID: number;
  ConnectorType: string;
  PowerKW: number;
  SerialNumber?: string;
  PointStatus: 'Available' | 'Busy' | 'Error' | 'Offline' | 'Maintenance';
  IsActive?: boolean;
}

export interface User {
  UserID: number;
  Username: string;
  Email: string;
  Phone?: string;
  FullName: string;
  AvatarUrl?: string;
  Role: string;
  FranchiseID?: number;
  AccountStatus: 'Pending' | 'Active' | 'Suspended' | 'Locked';
  WalletBalance?: number;
  CreatedAt?: string;
}

export interface Vehicle {
  VehicleID: number;
  UserID: number;
  PlateNumber: string;
  Brand: string;
  Model: string;
  ModelYear?: number;
  BatteryCapacityKWh?: number;
  ConnectorType?: string;
  IsActive?: boolean;
}

export interface PricingPolicy {
  PolicyID: number;
  PolicyCode?: string;
  PolicyName: string;
  BasePricePerKWh: number;
  CurrencyCode?: string;
  PeakMultiplier?: number;
  PeakStartHour?: number;
  PeakEndHour?: number;
  IsWeekendPeak?: boolean;
  AppliedFrom: string;
  AppliedTo?: string;
  IsActive?: boolean;
}

export interface ChargingSession {
  SessionID: number;
  SessionCode?: string;
  UserID: number;
  VehicleID?: number;
  PointID: number;
  StationID?: number;
  PolicyID?: number;
  StartTime: string;
  EndTime?: string;
  StartBatteryPercent?: number;
  EndBatteryPercent?: number;
  MeterStart?: number;
  MeterEnd?: number;
  TotalKWh?: number;
  ChargingDurationMinutes?: number;
  CostTotal?: number;
  CurrencyCode?: string;
  StopReason?: string;
  SessionStatus: 'Charging' | 'Completed' | 'Cancelled' | 'Failed' | 'Pending';
  Username?: string;
  FullName?: string;
  StationName?: string;
  StationCode?: string;
  PointCode?: string;
  PlateNumber?: string;
}

export interface Transaction {
  TransactionID: number;
  TransactionCode?: string;
  UserID: number;
  SessionID?: number;
  Direction?: 'D' | 'C';
  Amount: number;
  CurrencyCode?: string;
  TransactionType: 'ChargingPayment' | 'WalletTopUp' | 'Refund';
  TransactionStatus?: string;
  PaymentMethod?: string;
  Description?: string;
  TransactedAt: string;
  SettledAt?: string;
  SessionCode?: string;
}

export interface Wallet {
  WalletID: number;
  UserID: number;
  WalletCode: string;
  Balance: number;
  CurrencyCode?: string;
  IsActive?: boolean;
  LastTransactionAt?: string;
}

export interface ErrorLog {
  ErrorID: number;
  PointID?: number;
  StationID?: number;
  SessionID?: number;
  ErrorCode: string;
  Severity: 'Low' | 'Medium' | 'High' | 'Critical';
  Description?: string;
  OccurredAt?: string;
  IsActive?: boolean;
  ResolvedAt?: string;
  ResolvedBy?: number;
  ResolutionNotes?: string;
  PointCode?: string;
}

export interface Booking {
  BookingID: number;
  BookingCode?: string;
  UserID: number;
  PointID: number;
  StationID: number;
  VehicleID?: number;
  BookedFrom: string;
  BookedTo: string;
  Status: 'Pending' | 'Confirmed' | 'Cancelled' | 'Completed';
  CreatedAt?: string;
  StationName?: string;
  PointCode?: string;
  PlateNumber?: string;
}

export interface MaintenanceSchedule {
  ScheduleID: number;
  StationID: number;
  PointID?: number;
  ScheduledBy?: number;
  ScheduledFrom: string;
  ScheduledTo: string;
  MaintenanceType: string;
  Description?: string;
  Status: 'Scheduled' | 'InProgress' | 'Completed' | 'Cancelled';
  CompletedAt?: string;
  Notes?: string;
  CreatedAt?: string;
  StationCode?: string;
  StationName?: string;
  PointCode?: string;
}

export interface StationReview {
  ReviewID: number;
  UserID: number;
  StationID: number;
  SessionID?: number;
  Rating: number;
  Comment?: string;
  CreatedAt?: string;
  FullName?: string;
}

export interface Notification {
  NotificationID: number;
  UserID: number;
  Title: string;
  Body?: string;
  Type: string;
  ReferenceType?: string;
  ReferenceID?: number;
  IsRead: boolean;
  CreatedAt?: string;
}
