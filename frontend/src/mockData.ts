import { 
  Franchisee, 
  ElectricitySupplier, 
  ChargingStation, 
  ChargingPoint, 
  Customer, 
  Vehicle, 
  PricingPolicy, 
  ChargingSession, 
  Transaction, 
  ErrorLog 
} from './types';

export const mockFranchisees: Franchisee[] = [
  { FranchiseeID: 1, FranchiseeName: 'VinFast Partner A', TaxCode: '0102030405', ContactPerson: 'Nguyễn Văn A', Phone: '0901234567', Email: 'partnera@vinfast.vn', RevenueShareRate: 15.5, ContractDate: '2023-01-15' },
  { FranchiseeID: 2, FranchiseeName: 'EV Green Solutions', TaxCode: '0102030406', ContactPerson: 'Trần Thị B', Phone: '0907654321', Email: 'contact@evgreen.com', RevenueShareRate: 12.0, ContractDate: '2023-05-20' },
];

export const mockSuppliers: ElectricitySupplier[] = [
  { SupplierID: 1, SupplierName: 'EVN Miền Bắc', UnitPrice_kWh: 2500, Region: 'North', ContactInfo: '19001006' },
  { SupplierID: 2, SupplierName: 'EVN Miền Nam', UnitPrice_kWh: 2700, Region: 'South', ContactInfo: '19001007' },
];

export const mockStations: ChargingStation[] = [
  { StationID: 1, FranchiseeID: 1, SupplierID: 1, StationName: 'Trạm Landmark 81', Address: '720A Điện Biên Phủ, Bình Thạnh, HCM', Station_Status: 'Active' },
  { StationID: 2, FranchiseeID: 1, SupplierID: 1, StationName: 'Trạm Vincom Thảo Điền', Address: '159 Xa lộ Hà Nội, Thảo Điền, Quận 2, HCM', Station_Status: 'Active' },
  { StationID: 3, FranchiseeID: 2, SupplierID: 2, StationName: 'Trạm Aeon Mall Tân Phú', Address: '30 Bờ Bao Tân Thắng, Tân Phú, HCM', Station_Status: 'Active' },
];

export const mockPoints: ChargingPoint[] = [
  { PointID: 1, StationID: 1, Power_kW: 60, Connector_Type: 'CCS2', Point_Status: 'Available' },
  { PointID: 2, StationID: 1, Power_kW: 60, Connector_Type: 'CCS2', Point_Status: 'Charging' },
  { PointID: 3, StationID: 1, Power_kW: 11, Connector_Type: 'Type 2', Point_Status: 'Available' },
  { PointID: 4, StationID: 2, Power_kW: 150, Connector_Type: 'CCS2', Point_Status: 'Occupied' },
  { PointID: 5, StationID: 2, Power_kW: 150, Connector_Type: 'CCS2', Point_Status: 'Error' },
];

export const mockCustomers: Customer[] = [
  { UserID: 1, FullName: 'Trần Kim Hiệu', Email: 'tam.le@gmail.com', Phone: '0988777666', Address: '123 Đường ABC, Quận 1, TP.HCM', WalletBalance: 1250000, AccountStatus: 'Active' },
];

export const mockVehicles: Vehicle[] = [
  { VehicleID: 1, UserID: 1, PlateNumber: '51G-123.45', Brand: 'VinFast', Model: 'VF8', BatteryCapacity_kWh: 82, ConnectorType: 'CCS2' },
];

export const mockPolicies: PricingPolicy[] = [
  { PolicyID: 1, PolicyName: 'Giá tiêu chuẩn', BasePrice_kWh: 3500, PeakHourMultiplier: 1.2, AppliedFrom: '2024-01-01T00:00:00', AppliedTo: '2025-12-31T23:59:59' },
];

export const mockSessions: ChargingSession[] = [
  { SessionID: 101, UserID: 1, PointID: 2, PolicyID: 1, StartTime: '2024-03-20T10:00:00', EndTime: '2024-03-20T11:30:00', Total_kWh: 45.5, Cost_Total: 191100, Status: 'Completed' },
  { SessionID: 102, UserID: 1, PointID: 1, PolicyID: 1, StartTime: '2024-03-25T14:00:00', EndTime: '2024-03-25T15:00:00', Total_kWh: 30.0, Cost_Total: 105000, Status: 'Completed' },
];

export const mockTransactions: Transaction[] = [
  { TransactionID: 1, UserID: 1, SessionID: 101, Amount: -191100, TransactionType: 'Charging', Timestamp: '2024-03-20T11:35:00' },
  { TransactionID: 2, UserID: 1, Amount: 500000, TransactionType: 'Top-up', Timestamp: '2024-03-22T09:00:00' },
];

export const mockErrorLogs: ErrorLog[] = [
  { ErrorID: 1, PointID: 5, ErrorCode: 'E001', Description: 'Mất kết nối module sạc', OccurredAt: '2024-03-28T08:30:00', Severity: 'High' },
];
