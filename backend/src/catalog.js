const roleLabels = {
  Customer: 'Khách hàng',
  OperationsStaff: 'Nhân viên vận hành',
  BusinessManager: 'Quản lý kinh doanh',
  FranchisePartner: 'Đối tác nhượng quyền',
  SystemAdmin: 'Quản trị hệ thống'
};

const groups = {
  dashboard: 'Tổng quan',
  profile: 'Hồ sơ',
  charging: 'Sạc và đặt lịch',
  payment: 'Thanh toán và hóa đơn',
  operations: 'Vận hành',
  maintenance: 'Bảo trì',
  business: 'Kinh doanh',
  franchise: 'Nhượng quyền',
  admin: 'Quản trị',
  reports: 'Báo cáo'
};

const statusOptions = {
  station: ['Active', 'Inactive', 'UnderMaintenance', 'Retired'],
  point: ['Available', 'Reserved', 'Charging', 'Offline', 'Error', 'Maintenance', 'Retired'],
  health: ['Normal', 'Warning', 'Critical', 'Offline'],
  priority: ['Low', 'Medium', 'High', 'Critical'],
  paymentMethod: ['CASH', 'QR', 'BANK_TRANSFER']
};

const dateRangeParams = [
  { name: 'FromDate', label: 'Từ ngày', type: 'date' },
  { name: 'ToDate', label: 'Đến ngày', type: 'date' }
];

function queryAction(base) {
  return {
    kind: 'query',
    pageSize: 25,
    paginated: true,
    ...base
  };
}

function procedureAction(base) {
  return {
    kind: 'procedure',
    ...base
  };
}

export const actions = {
  me: procedureAction({
    title: 'Hồ sơ của tôi',
    description: 'Thông tin tài khoản hiện tại và các vai trò được gán.',
    group: 'profile',
    roles: Object.keys(roleLabels),
    procedure: 'AppView.sp_GetCurrentUserProfile',
    params: [],
    columns: ['UserID', 'Username', 'FullName', 'Email', 'Phone', 'AccountStatus', 'RoleCodes']
  }),

  customerDashboard: queryAction({
    title: 'Tổng quan khách hàng',
    description: 'Xe, đặt lịch, phiên sạc và hóa đơn gần nhất của khách hàng hiện tại.',
    group: 'dashboard',
    roles: ['Customer'],
    params: dateRangeParams,
    sql: `
      SELECT N'Xe đang hoạt động' AS ChiSo, COUNT(*) AS GiaTri, N'phương tiện' AS DonVi
      FROM AppView.vw_MyVehicles
      WHERE IsActive = 1
        AND (@FromDate IS NULL OR CreatedAt >= @FromDate)
        AND (@ToDate IS NULL OR CreatedAt < DATEADD(DAY, 1, @ToDate))
      UNION ALL
      SELECT N'Đặt lịch', COUNT(*), N'lượt'
      FROM AppView.vw_CustomerBookingHistory
      WHERE (@FromDate IS NULL OR CreatedAt >= @FromDate)
        AND (@ToDate IS NULL OR CreatedAt < DATEADD(DAY, 1, @ToDate))
      UNION ALL
      SELECT N'Phiên sạc hoàn tất', COUNT(*), N'phiên'
      FROM AppView.vw_CustomerChargingHistory
      WHERE SessionStatus = N'Completed'
        AND (@FromDate IS NULL OR StartTime >= @FromDate)
        AND (@ToDate IS NULL OR StartTime < DATEADD(DAY, 1, @ToDate))
      UNION ALL
      SELECT N'Tổng tiền hóa đơn', COALESCE(SUM(TotalAmount), 0), N'VND'
      FROM AppView.vw_InvoiceDetail
      WHERE (@FromDate IS NULL OR IssuedAt >= @FromDate)
        AND (@ToDate IS NULL OR IssuedAt < DATEADD(DAY, 1, @ToDate))
    `,
    orderBy: 'ChiSo',
    searchColumns: ['ChiSo']
  }),

  availablePoints: queryAction({
    title: 'Cổng sạc khả dụng',
    description: 'Tìm cổng sạc theo khu vực, trạm, loại đầu sạc và công suất.',
    group: 'charging',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_AvailableChargingPoints',
    orderBy: 'StationName, PointCode',
    searchColumns: ['RegionName', 'StationCode', 'StationName', 'PointCode', 'ConnectorCode', 'ConnectorName'],
    columns: ['RegionName', 'StationID', 'StationName', 'PointID', 'PointCode', 'ConnectorName', 'PowerKW', 'PointStatus']
  }),

  myVehicles: queryAction({
    title: 'Xe của tôi',
    description: 'Danh sách phương tiện của tài khoản hiện tại.',
    group: 'charging',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_MyVehicles',
    orderBy: 'CreatedAt DESC, VehicleID DESC',
    searchColumns: ['PlateNumber', 'Brand', 'Model', 'ConnectorCode', 'ConnectorName'],
    columns: ['VehicleID', 'PlateNumber', 'Brand', 'Model', 'BatteryCapacityKWh', 'ConnectorName', 'IsActive']
  }),

  createVehicle: procedureAction({
    title: 'Thêm xe',
    description: 'Tạo phương tiện mới cho khách hàng hiện tại.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_CreateVehicle',
    inject: { UserID: 'userId' },
    params: [
      { name: 'PlateNumber', label: 'Biển số', type: 'nvarchar', required: true },
      { name: 'Brand', label: 'Hãng xe', type: 'nvarchar', required: true },
      { name: 'Model', label: 'Mẫu xe', type: 'nvarchar', required: true },
      { name: 'BatteryCapacityKWh', label: 'Dung lượng pin kWh', type: 'decimal' },
      { name: 'PreferredConnectorTypeID', label: 'Loại đầu sạc ưu tiên', type: 'int', lookup: { key: 'connectorTypes' } }
    ]
  }),

  updateVehicle: procedureAction({
    title: 'Cập nhật xe',
    description: 'Cập nhật hoặc vô hiệu hóa xe thuộc tài khoản hiện tại.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_UpdateVehicle',
    inject: { UserID: 'userId' },
    confirm: true,
    params: [
      { name: 'VehicleID', label: 'Xe', type: 'int', required: true, lookup: { key: 'customerAllVehicles' }, lockedWhenInitial: true },
      { name: 'PlateNumber', label: 'Biển số', type: 'nvarchar' },
      { name: 'Brand', label: 'Hãng xe', type: 'nvarchar' },
      { name: 'Model', label: 'Mẫu xe', type: 'nvarchar' },
      { name: 'BatteryCapacityKWh', label: 'Dung lượng pin kWh', type: 'decimal' },
      { name: 'PreferredConnectorTypeID', label: 'Loại đầu sạc ưu tiên', type: 'int', lookup: { key: 'connectorTypes' } },
      { name: 'IsActive', label: 'Còn hoạt động', type: 'bit' }
    ]
  }),

  bookingHistory: queryAction({
    title: 'Lịch sử đặt lịch',
    description: 'Theo dõi toàn bộ booking của khách hàng hiện tại.',
    group: 'charging',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_CustomerBookingHistory',
    orderBy: 'CreatedAt DESC, BookingID DESC',
    searchColumns: ['BookingCode', 'PlateNumber', 'StationCode', 'StationName', 'PointCode', 'BookingStatus'],
    columns: ['BookingID', 'BookingCode', 'PlateNumber', 'StationName', 'PointCode', 'BookedFrom', 'BookedTo', 'BookingStatus']
  }),

  createBooking: procedureAction({
    title: 'Tạo đặt lịch',
    description: 'Đặt trước cổng sạc khả dụng cho xe của bạn.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_CreateBooking',
    inject: { UserID: 'userId' },
    params: [
      { name: 'VehicleID', label: 'Xe', type: 'int', lookup: { key: 'customerVehicles' } },
      { name: 'PointID', label: 'Cổng sạc', type: 'int', required: true, lookup: { key: 'customerAvailablePoints' }, lockedWhenInitial: true },
      { name: 'BookedFrom', label: 'Bắt đầu', type: 'dateTime', required: true },
      { name: 'BookedTo', label: 'Kết thúc', type: 'dateTime', required: true }
    ]
  }),

  cancelBooking: procedureAction({
    title: 'Hủy đặt lịch',
    description: 'Hủy booking hợp lệ của khách hàng hiện tại.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_CancelBooking',
    inject: { UserID: 'userId' },
    confirm: true,
    params: [{ name: 'BookingID', label: 'Đặt chỗ', type: 'bigInt', required: true, lookup: { key: 'customerCancelableBookings' }, lockedWhenInitial: true }]
  }),

  chargingHistory: queryAction({
    title: 'Phiên sạc của tôi',
    description: 'Lịch sử phiên sạc, chi phí và trạng thái.',
    group: 'charging',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_CustomerChargingHistory',
    orderBy: 'StartTime DESC, SessionID DESC',
    searchColumns: ['SessionCode', 'PlateNumber', 'StationCode', 'StationName', 'PointCode', 'SessionStatus'],
    dateFilter: { column: 'StartTime' },
    report: true,
    columns: ['SessionID', 'SessionCode', 'PlateNumber', 'StationName', 'PointCode', 'StartTime', 'EndTime', 'TotalKWh', 'CostTotal', 'SessionStatus']
  }),

  startSession: procedureAction({
    title: 'Bắt đầu phiên sạc',
    description: 'Khởi tạo phiên sạc tại cổng đã chọn.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_StartChargingSession',
    inject: { UserID: 'userId' },
    params: [
      { name: 'VehicleID', label: 'Xe', type: 'int', lookup: { key: 'customerVehicles' } },
      { name: 'PointID', label: 'Cổng sạc', type: 'int', required: true, lookup: { key: 'customerAvailablePoints' }, lockedWhenInitial: true },
      { name: 'BookingID', label: 'Đặt chỗ đã có', type: 'bigInt', lookup: { key: 'customerStartableBookings' }, applyMeta: { VehicleID: 'VehicleID', PointID: 'PointID' } }
    ]
  }),

  endSession: procedureAction({
    title: 'Kết thúc phiên sạc',
    description: 'Kết thúc phiên sạc và ghi nhận sản lượng.',
    group: 'charging',
    roles: ['Customer'],
    procedure: 'Operations.sp_EndChargingSession',
    confirm: true,
    params: [
      { name: 'SessionID', label: 'Phiên đang sạc', type: 'bigInt', required: true, lookup: { key: 'customerActiveSessions' }, lockedWhenInitial: true }
    ]
  }),

  createPayment: procedureAction({
    title: 'Tạo thanh toán',
    description: 'Tạo giao dịch thanh toán cho phiên sạc hoàn tất.',
    group: 'payment',
    roles: ['Customer'],
    procedure: 'Payments.sp_CreatePayment',
    inject: { UserID: 'userId' },
    confirm: true,
    params: [
      { name: 'SessionID', label: 'Phiên cần thanh toán', type: 'bigInt', required: true, lookup: { key: 'customerPayableSessions' }, lockedWhenInitial: true },
      { name: 'PaymentMethod', label: 'Phương thức', type: 'nvarchar', options: statusOptions.paymentMethod, defaultValue: 'CASH' }
    ]
  }),

  createInvoice: procedureAction({
    title: 'Tạo hóa đơn',
    description: 'Phát hành hóa đơn cho phiên sạc đã thanh toán.',
    group: 'payment',
    roles: ['Customer'],
    procedure: 'Payments.sp_CreateInvoice',
    confirm: true,
    params: [{ name: 'SessionID', label: 'Phiên đã thanh toán', type: 'bigInt', required: true, lookup: { key: 'customerInvoiceableSessions' }, lockedWhenInitial: true }]
  }),

  invoiceDetail: queryAction({
    title: 'Hóa đơn của tôi',
    description: 'Tra cứu hóa đơn và tải PDF hóa đơn.',
    group: 'payment',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_InvoiceDetail',
    orderBy: 'IssuedAt DESC, InvoiceID DESC',
    searchColumns: ['InvoiceCode', 'TransactionCode', 'StationCode', 'StationName', 'InvoiceStatus', 'TransactionStatus'],
    dateFilter: { column: 'IssuedAt' },
    report: true,
    columns: ['InvoiceID', 'InvoiceCode', 'InvoiceStatus', 'IssuedAt', 'TotalAmount', 'TransactionCode', 'PaymentMethod', 'StationName']
  }),

  operationsDashboard: queryAction({
    title: 'Tổng quan vận hành',
    description: 'Tình trạng trạm, cổng, phiên đang sạc và ticket mở.',
    group: 'dashboard',
    roles: ['OperationsStaff'],
    params: dateRangeParams,
    sql: `
      SELECT N'Tổng trạm' AS ChiSo, COUNT(*) AS GiaTri, N'trạm' AS DonVi FROM AppView.vw_StationStatusOverview
      UNION ALL SELECT N'Cổng khả dụng', SUM(AvailablePoints), N'cổng' FROM AppView.vw_StationStatusOverview
      UNION ALL SELECT N'Cổng lỗi', SUM(ProblemPoints), N'cổng' FROM AppView.vw_StationStatusOverview
      UNION ALL SELECT N'Phiên hoàn tất', COUNT(*), N'phiên'
      FROM Operations.ChargingSession
      WHERE SessionStatus = N'Completed'
        AND (@FromDate IS NULL OR StartTime >= @FromDate)
        AND (@ToDate IS NULL OR StartTime < DATEADD(DAY, 1, @ToDate))
      UNION ALL SELECT N'Ticket mở', COUNT(*), N'ticket'
      FROM AppView.vw_MaintenanceTickets
      WHERE TicketStatus IN (N'Open', N'Assigned', N'InProgress')
        AND (@FromDate IS NULL OR OpenedAt >= @FromDate)
        AND (@ToDate IS NULL OR OpenedAt < DATEADD(DAY, 1, @ToDate))
    `,
    orderBy: 'ChiSo',
    searchColumns: ['ChiSo']
  }),

  stationStatus: queryAction({
    title: 'Trạng thái trạm và cổng',
    description: 'Theo dõi tình trạng vận hành từng trạm.',
    group: 'operations',
    roles: ['OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_StationStatusOverview',
    orderBy: 'StationCode',
    searchColumns: ['StationCode', 'StationName', 'StationStatus'],
    dateFilter: { column: 'LastStatusChangeAt' },
    report: true,
    columns: ['StationID', 'StationCode', 'StationName', 'StationStatus', 'TotalPoints', 'AvailablePoints', 'ChargingPoints', 'ProblemPoints']
  }),

  updateStationStatus: procedureAction({
    title: 'Cập nhật trạng thái trạm',
    description: 'Đổi trạng thái vận hành của trạm.',
    group: 'operations',
    roles: ['OperationsStaff'],
    procedure: 'Infrastructure.sp_UpdateStationStatus',
    inject: { ChangedBy: 'userId' },
    confirm: true,
    params: [
      { name: 'StationID', label: 'Trạm sạc', type: 'int', required: true, lookup: { key: 'operationsStations' }, lockedWhenInitial: true },
      { name: 'StationStatus', label: 'Trạng thái trạm', type: 'nvarchar', options: statusOptions.station, required: true }
    ]
  }),

  updatePointStatus: procedureAction({
    title: 'Cập nhật trạng thái cổng',
    description: 'Đổi trạng thái và health của cổng sạc.',
    group: 'operations',
    roles: ['OperationsStaff'],
    procedure: 'Infrastructure.sp_UpdateChargingPointStatus',
    inject: { ChangedBy: 'userId' },
    confirm: true,
    params: [
      { name: 'PointID', label: 'Cổng sạc', type: 'int', required: true, lookup: { key: 'operationsPoints' }, lockedWhenInitial: true },
      { name: 'PointStatus', label: 'Trạng thái cổng', type: 'nvarchar', options: statusOptions.point, required: true },
      { name: 'HealthStatus', label: 'Sức khỏe', type: 'nvarchar', options: statusOptions.health }
    ]
  }),

  activeSessions: queryAction({
    title: 'Phiên đang sạc',
    description: 'Theo dõi phiên sạc hiện hành để xử lý sự cố.',
    group: 'operations',
    roles: ['OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_ActiveChargingSessions',
    orderBy: 'StartTime DESC, SessionID DESC',
    searchColumns: ['SessionCode', 'Username', 'FullName', 'StationCode', 'PointCode'],
    columns: ['SessionID', 'SessionCode', 'FullName', 'StationCode', 'PointCode', 'StartTime', 'TotalKWh', 'SessionStatus']
  }),

  markSessionFailed: procedureAction({
    title: 'Đánh dấu phiên lỗi',
    description: 'Dừng phiên bất thường và ghi nhận lý do.',
    group: 'operations',
    roles: ['OperationsStaff'],
    procedure: 'Operations.sp_MarkChargingSessionFailed',
    inject: { FailedBy: 'userId' },
    confirm: true,
    params: [
      { name: 'SessionID', label: 'Phiên đang sạc', type: 'bigInt', required: true, lookup: { key: 'operationsActiveSessions' }, lockedWhenInitial: true },
      { name: 'StopReason', label: 'Lý do lỗi', type: 'nvarchar', defaultValue: 'Failed' }
    ]
  }),

  reportError: procedureAction({
    title: 'Ghi nhận lỗi thiết bị',
    description: 'Tạo lỗi thiết bị và ticket tự động theo stored procedure.',
    group: 'maintenance',
    roles: ['OperationsStaff'],
    procedure: 'Maintenance.sp_ReportError',
    inject: { CreatedBy: 'userId' },
    params: [
      { name: 'ErrorCode', label: 'Mã lỗi', type: 'nvarchar' },
      { name: 'StationID', label: 'Trạm sạc', type: 'int', lookup: { key: 'operationsStations' } },
      { name: 'PointID', label: 'Cổng sạc', type: 'int', lookup: { key: 'operationsPoints', dependsOn: ['StationID'] } },
      { name: 'Severity', label: 'Mức độ', type: 'nvarchar', options: statusOptions.priority, defaultValue: 'Medium' },
      { name: 'Description', label: 'Mô tả', type: 'nvarchar', required: true }
    ]
  }),

  maintenanceTickets: queryAction({
    title: 'Ticket bảo trì',
    description: 'Lập lịch, phân công và đóng ticket bảo trì.',
    group: 'maintenance',
    roles: ['OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_MaintenanceTickets',
    orderBy: 'OpenedAt DESC, TicketID DESC',
    searchColumns: ['TicketCode', 'Priority', 'TicketStatus', 'Title', 'StationCode', 'PointCode', 'AssignedToUsername'],
    dateFilter: { column: 'OpenedAt' },
    report: true,
    columns: ['TicketID', 'TicketCode', 'Priority', 'TicketStatus', 'Title', 'StationCode', 'PointCode', 'AssignedToFullName', 'OpenedAt']
  }),

  scheduleMaintenance: procedureAction({
    title: 'Lập lịch bảo trì',
    description: 'Tạo ticket bảo trì chủ động.',
    group: 'maintenance',
    roles: ['OperationsStaff'],
    procedure: 'Maintenance.sp_ScheduleMaintenance',
    inject: { CreatedBy: 'userId' },
    params: [
      { name: 'StationID', label: 'Trạm sạc', type: 'int', lookup: { key: 'operationsStations' } },
      { name: 'PointID', label: 'Cổng sạc', type: 'int', lookup: { key: 'operationsPoints', dependsOn: ['StationID'] } },
      { name: 'AssignedTo', label: 'Nhân viên phụ trách', type: 'int', lookup: { key: 'operationsStaffUsers' } },
      { name: 'Priority', label: 'Độ ưu tiên', type: 'nvarchar', options: statusOptions.priority, defaultValue: 'Medium' },
      { name: 'Title', label: 'Tiêu đề', type: 'nvarchar', required: true },
      { name: 'Description', label: 'Mô tả', type: 'nvarchar' }
    ]
  }),

  assignTicket: procedureAction({
    title: 'Phân công ticket',
    description: 'Gán ticket cho nhân viên phụ trách.',
    group: 'maintenance',
    roles: ['OperationsStaff'],
    procedure: 'Maintenance.sp_AssignTicket',
    inject: { AssignedBy: 'userId' },
    confirm: true,
    params: [
      { name: 'TicketID', label: 'Ticket cần phân công', type: 'bigInt', required: true, lookup: { key: 'operationsOpenTickets' }, lockedWhenInitial: true },
      { name: 'AssignedTo', label: 'Nhân viên phụ trách', type: 'int', required: true, lookup: { key: 'operationsStaffUsers' } }
    ]
  }),

  closeTicket: procedureAction({
    title: 'Đóng ticket',
    description: 'Đóng ticket đã xử lý.',
    group: 'maintenance',
    roles: ['OperationsStaff'],
    procedure: 'Maintenance.sp_CloseTicket',
    inject: { ClosedBy: 'userId' },
    confirm: true,
    params: [{ name: 'TicketID', label: 'Ticket cần đóng', type: 'bigInt', required: true, lookup: { key: 'operationsOpenTickets' }, lockedWhenInitial: true }]
  }),

  telemetryHealth: procedureAction({
    title: 'Telemetry cảnh báo',
    description: 'Các cổng có mẫu Warning, Critical hoặc Offline.',
    group: 'maintenance',
    roles: ['OperationsStaff', 'BusinessManager'],
    procedure: 'AppView.sp_GetTelemetryHealth',
    params: [],
    report: true
  }),

  businessDashboard: queryAction({
    title: 'Tổng quan kinh doanh',
    description: 'Doanh thu, phiên hoàn tất, tăng trưởng khách hàng và settlement.',
    group: 'dashboard',
    roles: ['BusinessManager'],
    params: dateRangeParams,
    sql: `
      SELECT N'Doanh thu thanh toán' AS ChiSo, COALESCE(SUM(RevenueTotal), 0) AS GiaTri, N'VND' AS DonVi
      FROM AppView.vw_ChargingSessionStatistics
      WHERE SessionStatus = N'Completed'
        AND (@FromDate IS NULL OR SessionDate >= @FromDate)
        AND (@ToDate IS NULL OR SessionDate < DATEADD(DAY, 1, @ToDate))
      UNION ALL SELECT N'Phiên hoàn tất', COALESCE(SUM(SessionCount), 0), N'phiên'
      FROM AppView.vw_ChargingSessionStatistics
      WHERE SessionStatus = N'Completed'
        AND (@FromDate IS NULL OR SessionDate >= @FromDate)
        AND (@ToDate IS NULL OR SessionDate < DATEADD(DAY, 1, @ToDate))
      UNION ALL SELECT N'Khách hàng mới', COALESCE(SUM(NewCustomers), 0), N'tài khoản'
      FROM AppView.vw_CustomerGrowth
      WHERE (@FromDate IS NULL OR DATEFROMPARTS(CreatedYear, CreatedMonth, 1) >= @FromDate)
        AND (@ToDate IS NULL OR DATEFROMPARTS(CreatedYear, CreatedMonth, 1) < DATEADD(DAY, 1, @ToDate))
      UNION ALL SELECT N'Trạm có doanh thu', COUNT(DISTINCT StationID), N'trạm'
      FROM AppView.vw_StationRevenueDaily
      WHERE RevenueTotal > 0
        AND (@FromDate IS NULL OR RevenueDate >= @FromDate)
        AND (@ToDate IS NULL OR RevenueDate < DATEADD(DAY, 1, @ToDate))
    `,
    orderBy: 'ChiSo',
    searchColumns: ['ChiSo']
  }),

  pricingPolicies: queryAction({
    title: 'Chính sách giá',
    description: 'Danh sách chính sách giá đang và đã áp dụng.',
    group: 'business',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_PricingPolicies',
    orderBy: 'AppliedFrom DESC, PolicyID DESC',
    searchColumns: ['PolicyCode', 'PolicyName'],
    columns: ['PolicyID', 'PolicyCode', 'PolicyName', 'BasePricePerKWh', 'PeakMultiplier', 'AppliedFrom', 'AppliedTo', 'IsActive']
  }),

  createPricingPolicy: procedureAction({
    title: 'Tạo chính sách giá',
    description: 'Tạo pricing policy theo stored procedure hiện có.',
    group: 'business',
    roles: ['BusinessManager'],
    procedure: 'Operations.sp_CreatePricingPolicy',
    confirm: true,
    params: [
      { name: 'PolicyCode', label: 'Mã chính sách', type: 'nvarchar', required: true },
      { name: 'PolicyName', label: 'Tên chính sách', type: 'nvarchar', required: true },
      { name: 'BasePricePerKWh', label: 'Giá/kWh', type: 'decimal', required: true },
      { name: 'PeakMultiplier', label: 'Hệ số cao điểm', type: 'decimal', defaultValue: 1.2 },
      { name: 'PeakStartHour', label: 'Giờ cao điểm bắt đầu', type: 'time' },
      { name: 'PeakEndHour', label: 'Giờ cao điểm kết thúc', type: 'time' },
      { name: 'AppliedFrom', label: 'Áp dụng từ', type: 'dateTime', required: true },
      { name: 'AppliedTo', label: 'Áp dụng đến', type: 'dateTime' }
    ]
  }),

  deactivatePricingPolicy: procedureAction({
    title: 'Vô hiệu hóa chính sách giá',
    description: 'Tắt chính sách giá không còn áp dụng.',
    group: 'business',
    roles: ['BusinessManager'],
    procedure: 'Operations.sp_DeactivatePricingPolicy',
    confirm: true,
    params: [{ name: 'PolicyID', label: 'Chính sách giá đang áp dụng', type: 'int', required: true, lookup: { key: 'businessActivePricingPolicies' }, lockedWhenInitial: true }]
  }),

  activatePricingPolicy: procedureAction({
    title: 'Kích hoạt chính sách giá',
    description: 'Bật lại chính sách giá đã bị vô hiệu hóa.',
    group: 'business',
    roles: ['BusinessManager'],
    procedure: 'AppView.sp_ActivatePricingPolicy',
    confirm: true,
    params: [{ name: 'PolicyID', label: 'Chính sách giá đang tạm ngưng', type: 'int', required: true, lookup: { key: 'businessInactivePricingPolicies' }, lockedWhenInitial: true }]
  }),

  stationRevenue: procedureAction({
    title: 'Doanh thu theo trạm',
    description: 'Báo cáo doanh thu từng trạm theo khoảng ngày.',
    group: 'reports',
    roles: ['BusinessManager'],
    procedure: 'AppView.sp_GetStationRevenue',
    params: [
      { name: 'FromDate', label: 'Từ ngày', type: 'date' },
      { name: 'ToDate', label: 'Đến ngày', type: 'date' }
    ],
    report: true
  }),

  regionRevenue: queryAction({
    title: 'Doanh thu theo khu vực',
    description: 'Tổng hợp doanh thu theo khu vực.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_RegionRevenue',
    orderBy: 'RevenueTotal DESC',
    searchColumns: ['RegionName'],
    report: true
  }),

  topRevenueStations: queryAction({
    title: 'Top trạm doanh thu',
    description: 'Các trạm có doanh thu cao nhất.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_TopRevenueStations',
    orderBy: 'RevenueTotal DESC',
    searchColumns: ['StationCode', 'StationName'],
    report: true
  }),

  peakHours: queryAction({
    title: 'Giờ cao điểm',
    description: 'Thống kê khung giờ sử dụng nhiều.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_PeakHourStatistics',
    orderBy: 'StartHour',
    searchColumns: ['StartHour'],
    report: true
  }),

  customerGrowth: queryAction({
    title: 'Tăng trưởng khách hàng',
    description: 'Số lượng khách hàng mới theo thời gian.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_CustomerGrowth',
    orderBy: 'CreatedYear DESC, CreatedMonth DESC',
    searchColumns: ['CreatedYear', 'CreatedMonth'],
    report: true
  }),

  paymentSummary: procedureAction({
    title: 'Tổng hợp thanh toán',
    description: 'Tổng hợp giao dịch theo phương thức và trạng thái.',
    group: 'reports',
    roles: ['BusinessManager'],
    procedure: 'AppView.sp_GetPaymentSummary',
    params: [],
    report: true
  }),

  systemKpi: queryAction({
    title: 'KPI hệ thống',
    description: 'Chỉ số vận hành và kinh doanh cấp hệ thống.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_SystemOperationalKPI',
    orderBy: 'ActiveStations',
    searchColumns: [],
    report: true
  }),

  topCustomerUsage: queryAction({
    title: 'Top khách hàng sử dụng',
    description: 'Khách hàng có sản lượng và chi tiêu cao.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_TopCustomerUsage',
    orderBy: 'TotalSpend DESC',
    searchColumns: ['Username', 'FullName'],
    report: true
  }),

  sessionStatistics: queryAction({
    title: 'Thống kê phiên sạc',
    description: 'Thống kê phiên sạc theo trạng thái.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_ChargingSessionStatistics',
    orderBy: 'SessionStatus',
    searchColumns: ['SessionStatus'],
    dateFilter: { column: 'SessionDate' },
    report: true
  }),

  stationRevenueByYear: queryAction({
    title: 'Doanh thu theo trạm theo năm',
    description: 'So sánh doanh thu, sản lượng và số phiên của từng trạm giữa các năm.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_StationRevenueByYear',
    orderBy: 'RevenueYear DESC, RevenueTotal DESC',
    searchColumns: ['StationCode', 'StationName', 'RevenueYear'],
    report: true,
    columns: ['StationCode', 'StationName', 'RevenueYear', 'CompletedSessions', 'TotalKWh', 'RevenueTotal']
  }),

  stationRevenueDaily: queryAction({
    title: 'Doanh thu theo trạm theo ngày',
    description: 'Doanh thu, thuế và sản lượng từng trạm theo ngày.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_StationRevenueDaily',
    orderBy: 'RevenueDate DESC, RevenueTotal DESC',
    searchColumns: ['StationCode', 'StationName', 'FranchiseCode', 'FranchiseName'],
    dateFilter: { column: 'RevenueDate' },
    report: true,
    columns: ['RevenueDate', 'StationCode', 'StationName', 'CompletedSessions', 'TotalKWh', 'RevenueTotal']
  }),

  stationRevenueTrend: queryAction({
    title: 'Xu huong doanh thu theo thoi gian',
    description: 'Du lieu tong hop theo ngay cho bieu do doanh thu.',
    group: 'reports',
    roles: ['BusinessManager'],
    sql: `
      SELECT RevenueDate,
             SUM(CompletedSessions) AS CompletedSessions,
             SUM(TotalKWh) AS TotalKWh,
             SUM(RevenueTotal) AS RevenueTotal
      FROM AppView.vw_StationRevenueDaily
      WHERE (@FromDate IS NULL OR RevenueDate >= @FromDate)
        AND (@ToDate IS NULL OR RevenueDate < DATEADD(DAY, 1, @ToDate))
      GROUP BY RevenueDate
    `,
    orderBy: 'RevenueDate',
    searchColumns: [],
    params: [
      { name: 'FromDate', label: 'Tu ngay', type: 'date' },
      { name: 'ToDate', label: 'Den ngay', type: 'date' }
    ],
    columns: ['RevenueDate', 'CompletedSessions', 'TotalKWh', 'RevenueTotal']
  }),

  connectorUtilization: queryAction({
    title: 'Hiệu suất theo loại đầu sạc',
    description: 'Số cổng, phiên hoàn tất, sản lượng và doanh thu theo loại đầu sạc.',
    group: 'reports',
    roles: ['BusinessManager', 'OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_ConnectorUtilization',
    orderBy: 'TotalRevenue DESC',
    searchColumns: ['ConnectorCode', 'ConnectorName'],
    report: true,
    columns: ['ConnectorCode', 'ConnectorName', 'PointCount', 'CompletedSessions', 'TotalKWh', 'TotalRevenue']
  }),

  maintenanceKpi: queryAction({
    title: 'KPI bảo trì theo trạm',
    description: 'Số ticket, ticket mở, lỗi đang hoạt động và thời gian xử lý trung bình.',
    group: 'reports',
    roles: ['OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_MaintenanceKPI',
    orderBy: 'OpenTicketCount DESC, ActiveErrorCount DESC',
    searchColumns: ['StationCode', 'StationName'],
    report: true,
    columns: ['StationCode', 'StationName', 'TicketCount', 'OpenTicketCount', 'ActiveErrorCount', 'AvgResolveHours']
  }),

  errorLogActive: queryAction({
    title: 'Lỗi thiết bị đang hoạt động',
    description: 'Danh sách lỗi chưa xử lý theo trạm và cổng.',
    group: 'reports',
    roles: ['OperationsStaff'],
    sql: 'SELECT * FROM AppView.vw_ErrorLogActive',
    orderBy: 'OccurredAt DESC, ErrorID DESC',
    searchColumns: ['ErrorCode', 'Severity', 'StationCode', 'PointCode', 'Description'],
    dateFilter: { column: 'OccurredAt' },
    report: true,
    columns: ['ErrorCode', 'Severity', 'StationCode', 'PointCode', 'OccurredAt', 'Description']
  }),

  accountsByRole: queryAction({
    title: 'Tài khoản theo vai trò',
    description: 'Số lượng tài khoản theo vai trò và trạng thái.',
    group: 'reports',
    roles: ['SystemAdmin'],
    sql: 'SELECT * FROM AppView.vw_AccountsByRole',
    orderBy: 'RoleCode, AccountStatus',
    searchColumns: ['RoleCode', 'AccountStatus'],
    report: true,
    columns: ['RoleCode', 'AccountStatus', 'AccountCount']
  }),

  myChargingSummary: queryAction({
    title: 'Tổng hợp sạc theo tháng',
    description: 'Sản lượng và chi tiêu sạc của bạn theo từng tháng.',
    group: 'reports',
    roles: ['Customer'],
    sql: 'SELECT * FROM AppView.vw_MyChargingSummary',
    orderBy: 'UsageYear DESC, UsageMonth DESC',
    searchColumns: ['UsageYear', 'UsageMonth'],
    report: true,
    columns: ['UsageYear', 'UsageMonth', 'SessionCount', 'TotalKWh', 'TotalSpend']
  }),

  profitSharing: procedureAction({
    title: 'Chia lợi nhuận franchise',
    description: 'Báo cáo chia doanh thu cho nhượng quyền.',
    group: 'franchise',
    roles: ['BusinessManager'],
    procedure: 'AppView.sp_GetFranchiseProfitSharing',
    params: [],
    report: true
  }),

  updateRevenueSharePolicy: procedureAction({
    title: 'Cập nhật tỷ lệ chia doanh thu',
    description: 'Điều chỉnh revenue share policy.',
    group: 'franchise',
    roles: ['BusinessManager'],
    procedure: 'Franchise.sp_UpdateRevenueSharePolicy',
    confirm: true,
    params: [
      { name: 'RevenueSharePolicyID', label: 'Chính sách chia doanh thu', type: 'int', required: true, lookup: { key: 'businessRevenueSharePolicies' }, lockedWhenInitial: true },
      { name: 'PartnerShareRate', label: 'Tỷ lệ đối tác (%)', type: 'decimal', required: true },
      { name: 'AppliedTo', label: 'Áp dụng đến', type: 'date' }
    ]
  }),

  createRevenueSettlement: procedureAction({
    title: 'Tạo quyết toán doanh thu',
    description: 'Tạo settlement cho franchise theo kỳ.',
    group: 'franchise',
    roles: ['BusinessManager'],
    procedure: 'Franchise.sp_CreateRevenueSettlement',
    confirm: true,
    params: [
      { name: 'FranchiseID', label: 'Đối tác franchise', type: 'int', required: true, lookup: { key: 'businessActiveFranchises' } },
      { name: 'PeriodStart', label: 'Từ ngày', type: 'date', required: true },
      { name: 'PeriodEnd', label: 'Đến ngày', type: 'date', required: true }
    ]
  }),

  refundablePayments: queryAction({
    title: 'Payment có thể hoàn tiền',
    description: 'Các payment Completed để xử lý refund.',
    group: 'payment',
    roles: ['BusinessManager'],
    sql: 'SELECT * FROM AppView.vw_RefundablePayments',
    orderBy: 'PaidAt DESC, TransactionID DESC',
    searchColumns: ['TransactionCode', 'Username', 'FullName', 'InvoiceCode', 'StationCode', 'StationName'],
    columns: ['TransactionID', 'TransactionCode', 'FullName', 'Amount', 'PaymentMethod', 'PaidAt', 'InvoiceCode', 'StationName']
  }),

  refundPayment: procedureAction({
    title: 'Hoàn tiền payment',
    description: 'Cập nhật payment và invoice sang Refunded.',
    group: 'payment',
    roles: ['BusinessManager'],
    procedure: 'Payments.sp_RefundPayment',
    confirm: true,
    params: [
      { name: 'TransactionID', label: 'Giao dịch có thể hoàn tiền', type: 'bigInt', required: true, lookup: { key: 'businessRefundablePayments' }, lockedWhenInitial: true },
      { name: 'Reason', label: 'Lý do hoàn tiền', type: 'nvarchar' }
    ]
  }),

  franchiseDashboard: queryAction({
    title: 'Tổng quan đối tác',
    description: 'Hồ sơ franchise, trạm, hợp đồng và settlement gần nhất.',
    group: 'dashboard',
    roles: ['FranchisePartner'],
    params: dateRangeParams,
    sql: `
      SELECT N'Trạm thuộc franchise' AS ChiSo, COUNT(*) AS GiaTri, N'trạm' AS DonVi FROM AppView.vw_MyFranchiseStations
      UNION ALL SELECT N'Hợp đồng', COUNT(*), N'hợp đồng' FROM AppView.vw_MyFranchiseContracts
      UNION ALL SELECT N'Chính sách đang áp dụng', COUNT(*), N'chính sách' FROM AppView.vw_MyRevenueSharePolicies WHERE IsActive = 1
      UNION ALL SELECT N'Quyết toán', COUNT(*), N'kỳ'
      FROM AppView.vw_MyRevenueShareSettlements
      WHERE (@FromDate IS NULL OR PeriodEnd >= @FromDate)
        AND (@ToDate IS NULL OR PeriodStart < DATEADD(DAY, 1, @ToDate))
    `,
    orderBy: 'ChiSo',
    searchColumns: ['ChiSo']
  }),

  myFranchiseProfile: procedureAction({
    title: 'Hồ sơ franchise',
    description: 'Thông tin đối tác nhượng quyền của tài khoản hiện tại.',
    group: 'franchise',
    roles: ['FranchisePartner'],
    procedure: 'AppView.sp_GetMyFranchiseProfile',
    params: []
  }),

  myFranchiseContracts: procedureAction({
    title: 'Hợp đồng franchise',
    description: 'Hợp đồng thuộc đối tác hiện tại.',
    group: 'franchise',
    roles: ['FranchisePartner'],
    procedure: 'AppView.sp_GetMyFranchiseContracts',
    params: [],
    report: true
  }),

  myFranchiseStations: procedureAction({
    title: 'Trạm thuộc franchise',
    description: 'Danh sách trạm thuộc đối tác hiện tại.',
    group: 'franchise',
    roles: ['FranchisePartner'],
    procedure: 'AppView.sp_GetMyFranchiseStations',
    params: [],
    report: true
  }),

  myRevenueSharePolicies: procedureAction({
    title: 'Chính sách chia doanh thu của tôi',
    description: 'Revenue share policy thuộc franchise hiện tại.',
    group: 'franchise',
    roles: ['FranchisePartner'],
    procedure: 'AppView.sp_GetMyRevenueSharePolicies',
    params: [],
    report: true
  }),

  myFranchiseSettlements: procedureAction({
    title: 'Quyết toán của tôi',
    description: 'Settlement và profit sharing của franchise hiện tại.',
    group: 'franchise',
    roles: ['FranchisePartner'],
    procedure: 'AppView.sp_GetMyRevenueShareSettlements',
    params: [],
    report: true
  }),

  adminDashboard: queryAction({
    title: 'Tổng quan quản trị',
    description: 'Tài khoản, role và audit gần nhất.',
    group: 'dashboard',
    roles: ['SystemAdmin'],
    params: dateRangeParams,
    sql: `
      SELECT N'Tổng user' AS ChiSo, COUNT(*) AS GiaTri, N'tài khoản' AS DonVi
      FROM [Identity].UserAccount
      WHERE (@FromDate IS NULL OR CreatedAt >= @FromDate)
        AND (@ToDate IS NULL OR CreatedAt < DATEADD(DAY, 1, @ToDate))
      UNION ALL SELECT N'User bị khóa', COUNT(*), N'tài khoản' FROM AppView.vw_UserRoleSummary WHERE AccountStatus IN (N'Locked', N'Suspended')
      UNION ALL SELECT N'Role đang dùng', COUNT(DISTINCT RoleCodes), N'nhóm' FROM AppView.vw_UserRoleSummary
      UNION ALL SELECT N'Audit gần nhất', COUNT(*), N'dòng'
      FROM AppView.vw_AuditLogRecent
      WHERE (@FromDate IS NULL OR ChangedAt >= @FromDate)
        AND (@ToDate IS NULL OR ChangedAt < DATEADD(DAY, 1, @ToDate))
    `,
    orderBy: 'ChiSo',
    searchColumns: ['ChiSo']
  }),

  userRoleSummary: queryAction({
    title: 'Tài khoản và vai trò',
    description: 'Danh sách user, trạng thái và role đang gán.',
    group: 'admin',
    roles: ['SystemAdmin'],
    sql: 'SELECT * FROM AppView.vw_UserRoleSummary',
    orderBy: 'Username',
    searchColumns: ['Username', 'FullName', 'Email', 'Phone', 'AccountStatus', 'RoleCodes'],
    report: true,
    columns: ['UserID', 'Username', 'FullName', 'Email', 'Phone', 'AccountStatus', 'RoleCodes']
  }),

  createUser: procedureAction({
    title: 'Tạo tài khoản',
    description: 'Tạo user mới và gán role ban đầu.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_CreateUser',
    confirm: true,
    importable: true,
    params: [
      { name: 'Username', label: 'Tên đăng nhập', type: 'nvarchar', required: true },
      { name: 'Email', label: 'Email', type: 'nvarchar', required: true },
      { name: 'Phone', label: 'Số điện thoại', type: 'nvarchar' },
      { name: 'PasswordHash', label: 'Mật khẩu tạm thời', type: 'nvarchar', required: true, inputMode: 'password' },
      { name: 'FullName', label: 'Họ và tên', type: 'nvarchar', required: true },
      { name: 'RoleCode', label: 'Vai trò', type: 'nvarchar', options: Object.keys(roleLabels), required: true }
    ]
  }),

  lockUser: procedureAction({
    title: 'Khóa tài khoản',
    description: 'Khóa user không được đăng nhập.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_LockUser',
    confirm: true,
    params: [{ name: 'UserID', label: 'Tài khoản cần khóa', type: 'int', required: true, lookup: { key: 'adminLockableUsers' }, lockedWhenInitial: true }]
  }),

  unlockUser: procedureAction({
    title: 'Mở khóa tài khoản',
    description: 'Khôi phục trạng thái hoạt động cho user.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_UnlockUser',
    confirm: true,
    params: [{ name: 'UserID', label: 'Tài khoản cần mở khóa', type: 'int', required: true, lookup: { key: 'adminUnlockableUsers' }, lockedWhenInitial: true }]
  }),

  resetPassword: procedureAction({
    title: 'Reset mật khẩu',
    description: 'Cập nhật mật khẩu mới cho user. Backend sẽ tự hash trước khi lưu.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_ResetPassword',
    confirm: true,
    params: [
      { name: 'UserID', label: 'Tài khoản', type: 'int', required: true, lookup: { key: 'adminUsers' }, lockedWhenInitial: true },
      { name: 'PasswordHash', label: 'Mật khẩu mới', type: 'nvarchar', required: true, inputMode: 'password' }
    ]
  }),

  assignRole: procedureAction({
    title: 'Gán vai trò',
    description: 'Gán thêm role cho user.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_AssignRole',
    confirm: true,
    params: [
      { name: 'UserID', label: 'Tài khoản', type: 'int', required: true, lookup: { key: 'adminUsers' }, lockedWhenInitial: true },
      { name: 'RoleCode', label: 'Vai trò có thể gán', type: 'nvarchar', lookup: { key: 'adminAssignableRoles', dependsOn: ['UserID'] }, required: true }
    ]
  }),

  removeRole: procedureAction({
    title: 'Gỡ vai trò',
    description: 'Gỡ role khỏi user.',
    group: 'admin',
    roles: ['SystemAdmin'],
    procedure: '[Identity].sp_RemoveRole',
    confirm: true,
    params: [
      { name: 'UserID', label: 'Tài khoản', type: 'int', required: true, lookup: { key: 'adminUsers' }, lockedWhenInitial: true },
      { name: 'RoleCode', label: 'Vai trò đang có', type: 'nvarchar', lookup: { key: 'adminRemovableRoles', dependsOn: ['UserID'] }, required: true }
    ]
  }),

  auditLog: queryAction({
    title: 'Audit log',
    description: 'Lịch sử thao tác dữ liệu và bảo mật gần nhất.',
    group: 'admin',
    roles: ['SystemAdmin'],
    sql: 'SELECT * FROM AppView.vw_AuditLogRecent',
    orderBy: 'ChangedAt DESC, AuditID DESC',
    searchColumns: ['SchemaName', 'TableName', 'RecordID', 'ActionType', 'ChangedBy'],
    dateFilter: { column: 'ChangedAt' },
    report: true,
    columns: ['AuditID', 'SchemaName', 'TableName', 'RecordID', 'ActionType', 'ChangedBy', 'ChangedAt']
  }),

  backupRestoreGuide: {
    title: 'Hướng dẫn backup/restore',
    description: 'Trang hướng dẫn dùng script backup/restore hiện có; website không chạy thao tác nguy hiểm.',
    group: 'admin',
    roles: ['SystemAdmin'],
    kind: 'static',
    params: [],
    rows: [
      {
        Muc: 'Backup',
        HuongDan: 'Thực hiện bằng SSMS hoặc script database/12_Backup_Restore.sql trên máy quản trị SQL Server.'
      },
      {
        Muc: 'Restore',
        HuongDan: 'Chỉ restore trong SSMS sau khi xác nhận môi trường, đường dẫn file .bak và kế hoạch dừng dịch vụ.'
      }
    ]
  }
};

export function publicCatalogFor(roleCode) {
  return Object.entries(actions)
    .filter(([, action]) => action.roles.includes(roleCode))
    .map(([id, action]) => ({
      id,
      title: action.title,
      description: action.description,
      group: action.group,
      groupLabel: groups[action.group] || action.group,
      params: action.params || [],
      report: Boolean(action.report),
      exportable: Boolean(action.report || action.kind === 'query' || action.kind === 'static'),
      importable: Boolean(action.importable),
      confirm: Boolean(action.confirm),
      kind: action.kind,
      pageSize: action.pageSize,
      columns: action.columns || []
    }));
}

export function getRoleLabel(roleCode) {
  return roleLabels[roleCode] || roleCode;
}
