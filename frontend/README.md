# EV Charging Management System (Hệ thống Quản lý Trạm sạc Xe điện)

Một ứng dụng quản lý trạm sạc xe điện hiện đại, hỗ trợ cả người dùng cá nhân (Client) và người quản lý hệ thống (Manager).

## 🚀 Tính năng chính

### 👤 Dành cho Khách hàng (Client)
- **Quản lý xe:** Thêm, sửa, xóa thông tin các phương tiện xe điện.
- **Tìm kiếm trạm sạc:** Bản đồ tương tác và danh sách trạm sạc gần nhất.
- **Phiên sạc thời gian thực:** Theo dõi tiến độ sạc, công suất, và chi phí ngay lập tức.
- **Ví điện tử:** Nạp tiền và thanh toán phiên sạc dễ dàng.
- **Lịch sử & Hóa đơn:** Xem lại các phiên sạc cũ và xuất hóa đơn chi tiết.
- **Hồ sơ cá nhân:** Quản lý thông tin liên lạc và cài đặt tài khoản.

### 💼 Dành cho Người quản lý (Manager)
- **Chuỗi quản lý hạ tầng:** Quản lý theo cấp bậc Trạm sạc -> Trụ sạc -> Phiên sạc.
- **Giám sát thời gian thực:** Theo dõi trạng thái hoạt động của toàn bộ hệ thống trụ sạc.
- **Báo cáo doanh thu:** Biểu đồ trực quan về doanh thu, lợi nhuận và lưu lượng sạc.
- **Quản lý lỗi:** Hệ thống log lỗi kỹ thuật giúp xử lý sự cố kịp thời.
- **Quản lý phiên sạc:** Kiểm soát và tra cứu tất cả các giao dịch sạc trong hệ thống.

## 🛠 Công nghệ sử dụng

- **Frontend:** React 18+, TypeScript, Vite.
- **Styling:** Tailwind CSS (Utility-first CSS).
- **Animations:** Framer Motion (Chuyển động mượt mà).
- **Icons:** Lucide React.
- **Charts:** Recharts (Biểu đồ doanh thu).
- **State Management:** React Hooks (useState, useEffect, useMemo).

## 📂 Cấu trúc thư mục

```text
src/
├── components/       # Các thành phần UI dùng chung
│   ├── Client/       # Dashboard và tính năng cho Khách hàng
│   ├── Manager/      # Dashboard và tính năng cho Quản lý
│   └── Layout/       # Sidebar, Header, Auth Layout
├── lib/              # Tiện ích (utils, cn helper)
├── mockData.ts       # Dữ liệu mẫu cho hệ thống
├── types.ts          # Định nghĩa kiểu dữ liệu TypeScript
└── App.tsx           # Thành phần chính điều hướng ứng dụng
```

## 🏁 Bắt đầu

1. **Cài đặt dependencies:**
   ```bash
   npm install
   ```

2. **Chạy môi trường phát triển:**
   ```bash
   npm run dev
   ```

3. **Xây dựng bản sản xuất:**
   ```bash
   npm run build
   ```

## 📝 Ghi chú
Ứng dụng hiện đang sử dụng dữ liệu mẫu (mock data) để minh họa các tính năng. Hệ thống đã được tối ưu hóa cho trải nghiệm người dùng với giao diện hiện đại, hỗ trợ cuộn mượt mà và phản hồi tức thì.
