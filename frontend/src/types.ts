export type UserRole = 'client' | 'manager' | 'admin';

export interface Franchisee {
  FranchiseeID: number;
  FranchiseeName: string;
  TaxCode: string;
  ContactPerson: string;
  Phone: string;
  Email: string;
  RevenueShareRate: number;
  ContractDate: string;
}

export interface ElectricitySupplier {
  SupplierID: number;
  SupplierName: string;
  UnitPrice_kWh: number;
  Region: string;
  ContactInfo: string;
}

export interface ChargingStation {
  StationID: number;
  FranchiseeID: number;
  SupplierID: number;
  StationName: string;
  Address: string;
  Station_Status: 'Active' | 'Maintenance' | 'Inactive';
}

export interface ChargingPoint {
  PointID: number;
  StationID: number;
  Power_kW: number;
  Connector_Type: string;
  Point_Status: 'Available' | 'Charging' | 'Occupied' | 'Error';
}

export interface Customer {
  UserID: number;
  FullName: string;
  Email: string;
  Phone: string;
  Address: string;
  WalletBalance: number;
  AccountStatus: 'Active' | 'Suspended';
}

export interface Vehicle {
  VehicleID: number;
  UserID: number;
  PlateNumber: string;
  Brand: string;
  Model: string;
  BatteryCapacity_kWh: number;
  ConnectorType: string;
}

export interface PricingPolicy {
  PolicyID: number;
  PolicyName: string;
  BasePrice_kWh: number;
  PeakHourMultiplier: number;
  AppliedFrom: string;
  AppliedTo: string;
}

export interface ChargingSession {
  SessionID: number;
  UserID: number;
  PointID: number;
  PolicyID: number;
  StartTime: string;
  EndTime?: string;
  Total_kWh: number;
  Cost_Total: number;
  Status: 'Active' | 'Completed' | 'Cancelled';
}

export interface Transaction {
  TransactionID: number;
  UserID: number;
  SessionID?: number;
  Amount: number;
  TransactionType: 'Charging' | 'Top-up' | 'Refund';
  Timestamp: string;
}

export interface ErrorLog {
  ErrorID: number;
  PointID: number;
  ErrorCode: string;
  Description: string;
  OccurredAt: string;
  ResolvedAt?: string;
  Severity: 'Low' | 'Medium' | 'High' | 'Critical';
}
