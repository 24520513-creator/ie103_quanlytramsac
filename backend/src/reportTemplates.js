const money = { type: 'currency' };
const number = { type: 'number' };

export const reportTemplates = {
  regionRevenue: {
    chart: { type: 'bar', xKey: 'RegionName', yKeys: ['RevenueTotal'], title: 'Doanh thu theo khu vực', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Số khu vực', op: 'countDistinct', key: 'RegionName', ...number },
      { label: 'Khu vực dẫn đầu', op: 'topLabel', labelKey: 'RegionName', valueKey: 'RevenueTotal' }
    ],
    insightRules: [{ type: 'top', labelKey: 'RegionName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }]
  },
  topRevenueStations: {
    chart: { type: 'horizontalBar', xKey: 'StationName', yKeys: ['RevenueTotal'], title: 'Top trạm theo doanh thu', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Số trạm', op: 'countDistinct', key: 'StationCode', ...number },
      { label: 'Trạm dẫn đầu', op: 'topLabel', labelKey: 'StationName', valueKey: 'RevenueTotal' }
    ],
    insightRules: [{ type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }]
  },
  stationRevenueByYear: {
    chart: { type: 'bar', xKey: 'RevenueYear', yKeys: ['RevenueTotal'], title: 'Doanh thu theo năm', format: 'currency', aggregate: true },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Phiên hoàn tất', op: 'sum', key: 'CompletedSessions', ...number },
      { label: 'Số trạm', op: 'countDistinct', key: 'StationCode', ...number }
    ],
    insightRules: [{ type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }]
  },
  stationRevenueDaily: {
    chart: { type: 'line', xKey: 'RevenueDate', yKey: 'RevenueTotal', title: 'Xu hướng doanh thu theo ngày', format: 'currency', aggregate: true },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Phiên hoàn tất', op: 'sum', key: 'CompletedSessions', ...number }
    ],
    insightRules: [{ type: 'top', labelKey: 'StationName', valueKey: 'RevenueTotal', metricLabel: 'doanh thu' }]
  },
  paymentSummary: {
    chart: { type: 'donut', nameKey: 'PaymentMethod', valueKey: 'Amount', title: 'Cơ cấu thanh toán', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng giao dịch', op: 'sum', key: 'TransactionCount', ...number },
      { label: 'Tổng giá trị', op: 'sum', key: 'Amount', ...money },
      { label: 'Nhóm lớn nhất', op: 'topLabel', labelKey: 'PaymentMethod', valueKey: 'Amount' }
    ],
    insightRules: [{ type: 'share', labelKey: 'PaymentMethod', valueKey: 'Amount', metricLabel: 'giá trị thanh toán' }]
  },
  customerGrowth: {
    chart: { type: 'line', xKey: 'CreatedMonth', yKey: 'NewCustomers', title: 'Tăng trưởng khách hàng', format: 'number' },
    summaryMetrics: [
      { label: 'Khách hàng mới', op: 'sum', key: 'NewCustomers', ...number },
      { label: 'Kỳ cao nhất', op: 'topLabel', labelKey: 'CreatedMonth', valueKey: 'NewCustomers' }
    ],
    insightRules: [{ type: 'top', labelKey: 'CreatedMonth', valueKey: 'NewCustomers', metricLabel: 'khách hàng mới' }]
  },
  sessionStatistics: {
    chart: { type: 'donut', nameKey: 'SessionStatus', valueKey: 'SessionCount', title: 'Cơ cấu phiên sạc', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng phiên', op: 'sum', key: 'SessionCount', ...number },
      { label: 'Trạng thái chính', op: 'topLabel', labelKey: 'SessionStatus', valueKey: 'SessionCount' }
    ],
    insightRules: [{ type: 'share', labelKey: 'SessionStatus', valueKey: 'SessionCount', metricLabel: 'số phiên' }]
  },
  topCustomerUsage: {
    chart: { type: 'horizontalBar', xKey: 'FullName', yKeys: ['TotalSpend'], title: 'Top khách hàng theo chi tiêu', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng chi tiêu', op: 'sum', key: 'TotalSpend', ...money },
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Khách hàng dẫn đầu', op: 'topLabel', labelKey: 'FullName', valueKey: 'TotalSpend' }
    ],
    insightRules: [{ type: 'top', labelKey: 'FullName', valueKey: 'TotalSpend', metricLabel: 'chi tiêu' }]
  },
  connectorUtilization: {
    chart: { type: 'bar', xKey: 'ConnectorName', yKeys: ['TotalKWh'], title: 'Sản lượng theo loại đầu sạc', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng kWh', op: 'sum', key: 'TotalKWh', ...number },
      { label: 'Tổng doanh thu', op: 'sum', key: 'TotalRevenue', ...money },
      { label: 'Tổng cổng', op: 'sum', key: 'PointCount', ...number }
    ],
    insightRules: [{ type: 'top', labelKey: 'ConnectorName', valueKey: 'TotalKWh', metricLabel: 'sản lượng' }]
  },
  profitSharing: {
    chart: { type: 'horizontalBar', xKey: 'FranchiseName', yKeys: ['PartnerShareAmount'], title: 'Phần chia cho đối tác', format: 'currency' },
    summaryMetrics: [
      { label: 'Tổng doanh thu', op: 'sum', key: 'RevenueTotal', ...money },
      { label: 'Phần đối tác', op: 'sum', key: 'PartnerShareAmount', ...money },
      { label: 'Đối tác', op: 'countDistinct', key: 'FranchiseName', ...number }
    ],
    insightRules: [{ type: 'top', labelKey: 'FranchiseName', valueKey: 'PartnerShareAmount', metricLabel: 'phần chia' }]
  },
  maintenanceKpi: {
    chart: { type: 'bar', xKey: 'StationName', yKeys: ['OpenTicketCount', 'ActiveErrorCount'], title: 'Ticket mở và lỗi đang hoạt động', format: 'number' },
    summaryMetrics: [
      { label: 'Tổng ticket', op: 'sum', key: 'TicketCount', ...number },
      { label: 'Ticket mở', op: 'sum', key: 'OpenTicketCount', ...number },
      { label: 'Lỗi hoạt động', op: 'sum', key: 'ActiveErrorCount', ...number }
    ],
    insightRules: [{ type: 'top', labelKey: 'StationName', valueKey: 'OpenTicketCount', metricLabel: 'ticket mở' }]
  },
  telemetryHealth: {
    chart: { type: 'bar', xKey: 'StationName', yKeys: ['CriticalCount', 'WarningCount'], title: 'Cảnh báo telemetry', format: 'number' },
    summaryMetrics: [
      { label: 'Critical', op: 'sum', key: 'CriticalCount', ...number },
      { label: 'Warning', op: 'sum', key: 'WarningCount', ...number },
      { label: 'Trạm cần chú ý', op: 'topLabel', labelKey: 'StationName', valueKey: 'CriticalCount' }
    ],
    insightRules: [{ type: 'top', labelKey: 'StationName', valueKey: 'CriticalCount', metricLabel: 'cảnh báo critical' }]
  },
  errorLogActive: {
    chart: { type: 'donut', nameKey: 'Severity', valueKey: 'rowCount', title: 'Cơ cấu lỗi theo mức độ', format: 'number', countRows: true },
    summaryMetrics: [
      { label: 'Lỗi đang mở', op: 'countRows', ...number },
      { label: 'Mức độ chính', op: 'topLabel', labelKey: 'Severity', valueKey: 'rowCount', countRows: true },
      { label: 'Số trạm ảnh hưởng', op: 'countDistinct', key: 'StationCode', ...number }
    ],
    insightRules: [{ type: 'share', labelKey: 'Severity', valueKey: 'rowCount', metricLabel: 'lỗi', countRows: true }]
  }
};

export function getReportTemplate(actionId) {
  return reportTemplates[actionId] || null;
}
