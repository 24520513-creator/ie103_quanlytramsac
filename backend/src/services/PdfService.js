const PDFDocument = require('pdfkit');
const { execute } = require('../config/database');

class PdfService {
  async generateRevenueReport(franchiseId) {
    const result = await execute('Reporting.sp_GetFranchiseReportData', { FranchiseID: franchiseId });
    const f = result.recordsets[0]?.[0] || {};
    const sts = result.recordsets[1] || [];
    const rev = result.recordsets[2]?.[0] || {};

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50 });
      const buffers = [];
      doc.on('data', (chunk) => buffers.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);

      const blue = '#1e40af';
      const gray = '#64748b';

      doc.fontSize(22).font('Helvetica-Bold').fillColor(blue).text('EVCharge Pro', { align: 'center' });
      doc.fontSize(14).font('Helvetica').fillColor(gray).text('Báo cáo doanh thu', { align: 'center' });
      doc.moveDown(0.5);
      doc.fontSize(9).fillColor('#94a3b8').text(`Ngày xuất: ${new Date().toLocaleDateString('vi-VN')}`, { align: 'center' });
      doc.moveDown(1.5);

      doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor('#e2e8f0').stroke();
      doc.moveDown(1);

      doc.fontSize(14).font('Helvetica-Bold').fillColor(blue).text('Thông tin đối tác');
      doc.moveDown(0.5);
      doc.fontSize(10).font('Helvetica').fillColor('#334155');
      doc.text(`Tên đối tác: ${f.FranchiseName || 'N/A'}`);
      doc.text(`Mã đối tác: ${f.FranchiseCode || 'N/A'}`);
      doc.text(`Mã số thuế: ${f.TaxCode || 'N/A'}`);
      doc.moveDown(1);

      doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor('#e2e8f0').stroke();
      doc.moveDown(1);

      doc.fontSize(14).font('Helvetica-Bold').fillColor(blue).text('Tổng quan doanh thu');
      doc.moveDown(0.5);
      doc.fontSize(10).font('Helvetica').fillColor('#334155');
      doc.text(`Tổng doanh thu: ${(rev.TotalRevenue || 0).toLocaleString()} VND`);
      doc.text(`Tổng kWh: ${(rev.TotalKWh || 0).toFixed(1)}`);
      doc.text(`Tổng số phiên: ${rev.TotalSessions || 0}`);
      doc.text(`Trạm hoạt động: ${sts.filter(s => s.StationStatus === 'Active').length} / ${sts.length}`);
      doc.moveDown(1);

      doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor('#e2e8f0').stroke();
      doc.moveDown(1);

      doc.fontSize(14).font('Helvetica-Bold').fillColor(blue).text('Danh sách trạm');
      doc.moveDown(0.5);

      const tableTop = doc.y;
      const colX = [50, 200, 350, 450];

      doc.fontSize(9).font('Helvetica-Bold').fillColor(blue);
      doc.text('Mã trạm', colX[0], tableTop);
      doc.text('Tên trạm', colX[1], tableTop);
      doc.text('Trạng thái', colX[2], tableTop);
      doc.moveDown(0.5);

      doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor('#e2e8f0').stroke();
      doc.moveDown(0.3);

      doc.fontSize(9).font('Helvetica').fillColor('#334155');
      for (const st of sts) {
        if (doc.y > 700) {
          doc.addPage();
        }
        doc.text(st.StationCode || '', colX[0], doc.y);
        doc.text(st.StationName || '', colX[1], doc.y);
        doc.text(st.StationStatus || '', colX[2], doc.y);
        doc.moveDown(0.5);
        doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor('#f1f5f9').stroke();
        doc.moveDown(0.2);
      }

      doc.moveDown(2);
      doc.fontSize(8).fillColor('#94a3b8').text('EV Charge Pro - Hệ thống quản lý trạm sạc điện', { align: 'center' });

      doc.end();
    });
  }
}

module.exports = new PdfService();
