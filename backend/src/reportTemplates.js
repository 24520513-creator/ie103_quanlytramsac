const money = { type: 'currency' };
const number = { type: 'number' };
const percent = { type: 'percent' };

const revenueMetrics = [
  { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
  { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
  { label: 'Phiên hoàn tất', op: 'sum', key: 'CompletedSessions', ...number }
];

export const reportTemplates = {
  regionRevenue: {
    chart: { type: 'bar', xKey: 'RegionName', yKeys: ['RevenueTotal'], title: 'Doanh thu theo khu vực', format: 'currency' },
    summaryMetrics: [
      ...revenueMetrics,
      { label: 'Khu vực dẫn đầu', op: 'topLabel', labelKey: 'RegionName', valueKey: 'RevenueTotal' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'RegionName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'share', labelKey: 'RegionName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'concentration', labelKey: 'RegionName', valueKey: 'RevenueTotal', topN: 3, metricLabel: 'doanh thu' }
    ]
  },
  topRevenueStations: {
    chart: { type: 'horizontalBar', xKey: 'StationName', yKeys: ['RevenueTotal'], title: 'Top trạm theo doanh thu', format: 'currency' },
    summaryMetrics: [
      ...revenueMetrics,
      { label: 'Trạm dẫn đầu', op: 'topLabel', labelKey: 'StationName', valueKey: 'RevenueTotal' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'share', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'concentration', labelKey: 'StationName', valueKey: 'RevenueTotal', topN: 5, metricLabel: 'doanh thu' }
    ]
  },
  stationRevenue: {
    chart: { type: 'horizontalBar', xKey: 'StationName', yKeys: ['RevenueTotal'], title: 'Doanh thu theo trạm', format: 'currency' },
    summaryMetrics: [
      ...revenueMetrics,
      { label: 'Trạm doanh thu cao nhất', op: 'topLabel', labelKey: 'StationName', valueKey: 'RevenueTotal' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'share', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }
    ]
  },
  stationRevenueByYear: {
    chart: { type: 'bar', xKey: 'RevenueYear', yKeys: ['RevenueTotal'], title: 'Doanh thu theo năm', format: 'currency', aggregate: true },
    summaryMetrics: [
      ...revenueMetrics,
      { label: 'Số trạm', op: 'countDistinct', key: 'StationCode', ...number }
    ],
    insightRules: [
      { type: 'trend', labelKey: 'RevenueYear', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }
    ]
  },
  stationRevenueDaily: {
    chart: { type: 'line', xKey: 'RevenueDate', yKey: 'RevenueTotal', title: 'Xu hướng doanh thu theo ngày', format: 'currency', aggregate: true },
    summaryMetrics: revenueMetrics,
    insightRules: [
      { type: 'trend', labelKey: 'RevenueDate', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' },
      { type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }
    ]
  },
  peakHours: {
    chart: { type: 'bar', xKey: 'StartHour', yKeys: ['SessionCount'], title: 'Mật độ sử dụng theo giờ', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng phiên', op: 'sum', key: 'SessionCount', ...number },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Giờ cao điểm', op: 'topLabel', labelKey: 'StartHour', valueKey: 'SessionCount' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'StartHour', valueKey: 'SessionCount', metricLabel: 'số phiên' },
      { type: 'share', labelKey: 'StartHour', valueKey: 'SessionCount', metricLabel: 'số phiên' }
    ]
  },
  paymentSummary: {
    chart: { type: 'donut', nameKey: 'PaymentMethod', valueKey: 'TotalAmount', title: 'Cơ cấu thanh toán', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng giao dịch', op: 'sum', key: 'TransactionCount', ...number },
      { label: 'Tổng giá trị', op: 'sum', key: 'TotalAmount', ...money },
      { label: 'Phương thức chính', op: 'topLabel', labelKey: 'PaymentMethod', valueKey: 'TotalAmount' }
    ],
    insightRules: [
      { type: 'share', labelKey: 'PaymentMethod', valueKey: 'TotalAmount', metricLabel: 'giá trị thanh toán' },
      { type: 'top', labelKey: 'TransactionStatus', valueKey: 'TransactionCount', metricLabel: 'số giao dịch' }
    ]
  },
  customerGrowth: {
    chart: { type: 'line', xKey: 'PeriodLabel', labelParts: ['CreatedMonth', 'CreatedYear'], yKey: 'NewCustomers', title: 'Tăng trưởng khách hàng', format: 'number' },
    summaryMetrics: [
      { label: 'Khách hàng mới', op: 'sum', key: 'NewCustomers', ...number },
      { label: 'Số kỳ', op: 'countRows', ...number },
      { label: 'Kỳ cao nhất', op: 'topLabel', labelKey: 'PeriodLabel', valueKey: 'NewCustomers', labelParts: ['CreatedMonth', 'CreatedYear'] }
    ],
    insightRules: [
      { type: 'trend', labelKey: 'PeriodLabel', valueKey: 'NewCustomers', labelParts: ['CreatedMonth', 'CreatedYear'], metricLabel: 'khách hàng mới' },
      { type: 'top', labelKey: 'PeriodLabel', valueKey: 'NewCustomers', labelParts: ['CreatedMonth', 'CreatedYear'], metricLabel: 'khách hàng mới' }
    ]
  },
  systemKpi: {
    chart: { type: 'bar', xKey: 'Metric', yKeys: ['Value'], title: 'KPI hệ thống', format: 'number', pivotMetrics: ['ActiveStations', 'ActivePoints', 'ActiveSessions', 'CompletedSessions', 'FailedSessions', 'OpenTickets'] },
    summaryMetrics: [
      { label: 'Trạm hoạt động', op: 'sum', key: 'ActiveStations', ...number },
      { label: 'Cổng hoạt động', op: 'sum', key: 'ActivePoints', ...number },
      { label: 'Phiên hoàn tất', op: 'sum', key: 'CompletedSessions', ...number },
      { label: 'Tổng doanh thu', op: 'sum', key: 'TotalRevenue', ...money }
    ],
    insightRules: [
      { type: 'ratio', numeratorKey: 'FailedSessions', denominatorKey: 'CompletedSessions', metricLabel: 'tỷ lệ phiên lỗi trên phiên hoàn tất' },
      { type: 'risk', key: 'OpenTickets', threshold: 0, metricLabel: 'ticket đang mở' }
    ]
  },
  sessionStatistics: {
    chart: { type: 'donut', nameKey: 'SessionStatus', valueKey: 'SessionCount', title: 'Cơ cấu phiên sạc', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng phiên', op: 'sum', key: 'SessionCount', ...number },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'SessionStatus', valueKey: 'SessionCount' }
    ],
    insightRules: [
      { type: 'share', labelKey: 'SessionStatus', valueKey: 'SessionCount', metricLabel: 'số phiên' },
      { type: 'trend', labelKey: 'SessionDate', valueKey: 'SessionCount', metricLabel: 'số phiên' }
    ]
  },
  topCustomerUsage: {
    chart: { type: 'horizontalBar', xKey: 'FullName', yKeys: ['TotalSpend'], title: 'Top khách hàng theo chi tiêu', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng chi tiêu', op: 'sum', key: 'TotalSpend', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Phiên hoàn tất', op: 'sum', key: 'CompletedSessions', ...number },
      { label: 'Khách hàng dẫn đầu', op: 'topLabel', labelKey: 'FullName', valueKey: 'TotalSpend' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'FullName', valueKey: 'TotalSpend', metricLabel: 'chi tiêu' },
      { type: 'concentration', labelKey: 'FullName', valueKey: 'TotalSpend', topN: 10, metricLabel: 'chi tiêu' }
    ]
  },
  connectorUtilization: {
    chart: { type: 'bar', xKey: 'ConnectorName', yKeys: ['TotalKWh'], title: 'Sản lượng theo loại đầu sạc', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Tổng doanh thu', op: 'sum', key: 'TotalRevenue', ...money },
      { label: 'Tổng cổng', op: 'sum', key: 'PointCount', ...number },
      { label: 'Đầu sạc chính', op: 'topLabel', labelKey: 'ConnectorName', valueKey: 'TotalKWh' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'ConnectorName', valueKey: 'TotalKWh', metricLabel: 'sản lượng' },
      { type: 'share', labelKey: 'ConnectorName', valueKey: 'TotalRevenue', metricLabel: 'doanh thu' }
    ]
  },
  profitSharing: {
    chart: { type: 'horizontalBar', xKey: 'FranchiseName', yKeys: ['PartnerShareAmount'], title: 'Phần chia cho đối tác', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'GrossRevenue', ...money },
      { label: 'Phần đối tác', op: 'sum', key: 'PartnerShareAmount', ...money },
      { label: 'Phần nền tảng', op: 'sum', key: 'PlatformShareAmount', ...money },
      { label: 'Đối tác', op: 'countDistinct', key: 'FranchiseName', ...number }
    ],
    insightRules: [
      { type: 'top', labelKey: 'FranchiseName', valueKey: 'PartnerShareAmount', metricLabel: 'phần chia' },
      { type: 'share', labelKey: 'FranchiseName', valueKey: 'PartnerShareAmount', metricLabel: 'phần chia' }
    ]
  },
  myFranchiseSettlements: {
    chart: { type: 'bar', xKey: 'PeriodEnd', yKeys: ['GrossRevenue'], title: 'Quyết toán theo kỳ', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'GrossRevenue', ...money },
      { label: 'Phần đối tác', op: 'sum', key: 'PartnerShareAmount', ...money },
      { label: 'Số kỳ', op: 'countRows', ...number }
    ],
    insightRules: [
      { type: 'trend', labelKey: 'PeriodEnd', valueKey: 'GrossRevenue', metricLabel: 'doanh thu quyết toán' },
      { type: 'top', labelKey: 'PeriodEnd', valueKey: 'GrossRevenue', metricLabel: 'doanh thu quyết toán' }
    ]
  },
  myFranchiseStations: {
    chart: { type: 'bar', xKey: 'StationStatus', yKeys: ['rowCount'], title: 'Cơ cấu trạm theo trạng thái', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Số trạm', op: 'countRows', ...number },
      { label: 'Tổng công suất kW', op: 'sum', key: 'MaxPowerKW', ...number },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'StationStatus', valueKey: 'rowCount', countRows: true }
    ],
    insightRules: [{ type: 'share', labelKey: 'StationStatus', valueKey: 'rowCount', metricLabel: 'số trạm', countRows: true }]
  },
  myRevenueSharePolicies: {
    chart: { type: 'bar', xKey: 'PolicyCode', yKeys: ['PartnerShareRate'], title: 'Tỷ lệ chia doanh thu theo chính sách', format: 'percent' },
    summaryMetrics: [
      { label: 'Số chính sách', op: 'countRows', ...number },
      { label: 'Tỷ lệ đối tác TB', op: 'avg', key: 'PartnerShareRate', ...percent },
      { label: 'Chính sách cao nhất', op: 'topLabel', labelKey: 'PolicyCode', valueKey: 'PartnerShareRate' }
    ],
    insightRules: [{ type: 'top', labelKey: 'PolicyCode', valueKey: 'PartnerShareRate', metricLabel: 'tỷ lệ đối tác' }]
  },
  maintenanceKpi: {
    chart: { type: 'bar', xKey: 'StationName', yKeys: ['OpenTicketCount', 'ActiveErrorCount'], title: 'Ticket mở và lỗi đang hoạt động', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng ticket', op: 'sum', key: 'TicketCount', ...number },
      { label: 'Ticket mở', op: 'sum', key: 'OpenTicketCount', ...number },
      { label: 'Lỗi hoạt động', op: 'sum', key: 'ActiveErrorCount', ...number },
      { label: 'Giờ xử lý TB', op: 'avg', key: 'AvgResolveHours', ...number }
    ],
    insightRules: [
      { type: 'top', labelKey: 'StationName', valueKey: 'OpenTicketCount', metricLabel: 'ticket mở' },
      { type: 'risk', key: 'ActiveErrorCount', threshold: 0, metricLabel: 'lỗi đang hoạt động' }
    ]
  },
  maintenanceTickets: {
    chart: { type: 'donut', nameKey: 'TicketStatus', valueKey: 'rowCount', title: 'Cơ cấu ticket theo trạng thái', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Tổng ticket', op: 'countRows', ...number },
      { label: 'Mức ưu tiên chính', op: 'topLabel', labelKey: 'Priority', valueKey: 'rowCount', countRows: true },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'TicketStatus', valueKey: 'rowCount', countRows: true }
    ],
    insightRules: [
      { type: 'share', labelKey: 'TicketStatus', valueKey: 'rowCount', metricLabel: 'ticket', countRows: true },
      { type: 'share', labelKey: 'Priority', valueKey: 'rowCount', metricLabel: 'ticket', countRows: true }
    ]
  },
  telemetryHealth: {
    chart: { type: 'horizontalBar', xKey: 'StationCode', yKeys: ['IssueSamples'], title: 'Điểm telemetry cần chú ý', format: 'number' },
    summaryMetrics: [
      { label: 'Mẫu cảnh báo', op: 'sum', key: 'IssueSamples', ...number },
      { label: 'Nhiệt độ cao nhất', op: 'max', key: 'MaxTemperatureC', ...number },
      { label: 'Trạm cần chú ý', op: 'topLabel', labelKey: 'StationCode', valueKey: 'IssueSamples' }
    ],
    insightRules: [
      { type: 'top', labelKey: 'StationCode', valueKey: 'IssueSamples', metricLabel: 'mẫu cảnh báo' },
      { type: 'top', labelKey: 'PointCode', valueKey: 'MaxTemperatureC', metricLabel: 'nhiệt độ cao nhất' }
    ]
  },
  errorLogActive: {
    chart: { type: 'donut', nameKey: 'Severity', valueKey: 'rowCount', title: 'Cơ cấu lỗi theo mức độ', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Lỗi đang mở', op: 'countRows', ...number },
      { label: 'Mức độ chính', op: 'topLabel', labelKey: 'Severity', valueKey: 'rowCount', countRows: true },
      { label: 'Số trạm ảnh hưởng', op: 'countDistinct', key: 'StationCode', ...number }
    ],
    insightRules: [
      { type: 'share', labelKey: 'Severity', valueKey: 'rowCount', metricLabel: 'lỗi', countRows: true },
      { type: 'top', labelKey: 'StationCode', valueKey: 'rowCount', metricLabel: 'lỗi', countRows: true }
    ]
  },
  stationStatus: {
    chart: { type: 'bar', xKey: 'StationName', yKeys: ['AvailablePoints', 'ProblemPoints'], title: 'Tình trạng cổng theo trạm', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng cổng', op: 'sum', key: 'TotalPoints', ...number },
      { label: 'Cổng khả dụng', op: 'sum', key: 'AvailablePoints', ...number },
      { label: 'Cổng sự cố', op: 'sum', key: 'ProblemPoints', ...number },
      { label: 'Trạm cần chú ý', op: 'topLabel', labelKey: 'StationName', valueKey: 'ProblemPoints' }
    ],
    insightRules: [
      { type: 'ratio', numeratorKey: 'ProblemPoints', denominatorKey: 'TotalPoints', metricLabel: 'tỷ lệ cổng sự cố' },
      { type: 'top', labelKey: 'StationName', valueKey: 'ProblemPoints', metricLabel: 'cổng sự cố' }
    ]
  },
  accountsByRole: {
    chart: { type: 'bar', xKey: 'RoleCode', yKeys: ['AccountCount'], title: 'Tài khoản theo vai trò', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng tài khoản', op: 'sum', key: 'AccountCount', ...number },
      { label: 'Số vai trò', op: 'countDistinct', key: 'RoleCode', ...number },
      { label: 'Vai trò nhiều nhất', op: 'topLabel', labelKey: 'RoleCode', valueKey: 'AccountCount' }
    ],
    insightRules: [{ type: 'share', labelKey: 'RoleCode', valueKey: 'AccountCount', metricLabel: 'tài khoản' }]
  },
  userRoleSummary: {
    chart: { type: 'donut', nameKey: 'AccountStatus', valueKey: 'rowCount', title: 'Cơ cấu tài khoản theo trạng thái', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Tổng tài khoản', op: 'countRows', ...number },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'AccountStatus', valueKey: 'rowCount', countRows: true },
      { label: 'Số nhóm role', op: 'countDistinct', key: 'RoleCodes', ...number }
    ],
    insightRules: [{ type: 'share', labelKey: 'AccountStatus', valueKey: 'rowCount', metricLabel: 'tài khoản', countRows: true }]
  },
  auditLog: {
    chart: { type: 'donut', nameKey: 'ActionType', valueKey: 'rowCount', title: 'Cơ cấu audit theo hành động', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Dòng audit', op: 'countRows', ...number },
      { label: 'Hành động chính', op: 'topLabel', labelKey: 'ActionType', valueKey: 'rowCount', countRows: true },
      { label: 'Bảng ảnh hưởng', op: 'countDistinct', key: 'TableName', ...number }
    ],
    insightRules: [
      { type: 'share', labelKey: 'ActionType', valueKey: 'rowCount', metricLabel: 'audit', countRows: true },
      { type: 'top', labelKey: 'TableName', valueKey: 'rowCount', metricLabel: 'audit', countRows: true }
    ]
  },
  chargingHistory: {
    chart: { type: 'line', xKey: 'StartTime', yKey: 'CostTotal', title: 'Chi phí sạc theo thời gian', format: 'currency', aggregate: true },
    summaryMetrics: [
      { label: 'Tổng chi phí', op: 'sum', key: 'CostTotal', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Số phiên', op: 'countRows', ...number }
    ],
    insightRules: [
      { type: 'trend', labelKey: 'StartTime', valueKey: 'CostTotal', metricLabel: 'chi phí' },
      { type: 'top', labelKey: 'StationName', valueKey: 'CostTotal', metricLabel: 'chi phí' }
    ]
  },
  invoiceDetail: {
    chart: { type: 'donut', nameKey: 'InvoiceStatus', valueKey: 'TotalAmount', title: 'Cơ cấu hóa đơn', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng hóa đơn', op: 'countRows', ...number },
      { label: 'Tổng tiền', op: 'sum', key: 'TotalAmount', ...money },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'InvoiceStatus', valueKey: 'TotalAmount' }
    ],
    insightRules: [{ type: 'share', labelKey: 'InvoiceStatus', valueKey: 'TotalAmount', metricLabel: 'giá trị hóa đơn' }]
  },
  myChargingSummary: {
    chart: { type: 'line', xKey: 'PeriodLabel', labelParts: ['UsageMonth', 'UsageYear'], yKey: 'TotalSpend', title: 'Chi tiêu sạc theo tháng', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng chi tiêu', op: 'sum', key: 'TotalSpend', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Số phiên', op: 'sum', key: 'SessionCount', ...number }
    ],
    insightRules: [
      { type: 'trend', labelKey: 'PeriodLabel', valueKey: 'TotalSpend', labelParts: ['UsageMonth', 'UsageYear'], metricLabel: 'chi tiêu' },
      { type: 'top', labelKey: 'PeriodLabel', valueKey: 'TotalSpend', labelParts: ['UsageMonth', 'UsageYear'], metricLabel: 'chi tiêu' }
    ]
  }
};

export function getReportTemplate(actionId) {
  return reportTemplates[actionId] || null;
}
