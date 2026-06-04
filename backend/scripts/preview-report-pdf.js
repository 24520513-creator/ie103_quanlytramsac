import fs from 'node:fs';
import { renderReportPdf } from '../src/pdf.js';
import { getReportTemplate } from '../src/reportTemplates.js';

const user = { fullName: 'Trần Kim Hiếu', username: 'bm.hieu', roleCode: 'BusinessManager' };

const action = {
  title: 'Doanh thu theo trạm theo năm',
  description: 'Tổng hợp doanh thu, sản lượng và số phiên hoàn tất của từng trạm theo năm.',
  group: 'reports',
  params: [],
  columns: ['StationCode', 'StationName', 'RevenueYear', 'CompletedSessions', 'TotalKWh', 'RevenueTotal']
};

const stations = [
  ['ST-HCM-01', 'Trạm Quận 1', 'TP. Hồ Chí Minh'],
  ['ST-HCM-02', 'Trạm Thủ Đức', 'TP. Hồ Chí Minh'],
  ['ST-HN-01', 'Trạm Cầu Giấy', 'Hà Nội'],
  ['ST-DN-01', 'Trạm Hải Châu', 'Đà Nẵng'],
  ['ST-CT-01', 'Trạm Ninh Kiều', 'Cần Thơ']
];

const rows = [];
for (const [code, name] of stations) {
  for (const year of [2024, 2025, 2026]) {
    const base = 40_000_000 + Math.round(Math.random() * 120_000_000);
    rows.push({
      StationCode: code,
      StationName: name,
      RevenueYear: year,
      CompletedSessions: 400 + Math.round(Math.random() * 1800),
      TotalKWh: 12_000 + Math.round(Math.random() * 60_000),
      RevenueTotal: base * (year - 2023)
    });
  }
}

const buffer = await renderReportPdf({
  action,
  rows,
  columns: action.columns,
  template: getReportTemplate('stationRevenueByYear'),
  user,
  body: { fromDate: '2024-01-01', toDate: '2026-06-04' }
});

const out = process.argv[2] || 'C:/Users/hocvi/OneDrive/Documents/Study/IE103_QuanLyThongTin/SourceCode/backend/scripts/_preview-report.pdf';
fs.writeFileSync(out, buffer);
console.log('Wrote', out, buffer.length, 'bytes');
