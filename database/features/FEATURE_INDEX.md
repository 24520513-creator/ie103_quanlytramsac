# Muc Luc Feature SQL

Bang nay dung de tra nhanh tinh nang, role su dung, mo ta ngan va file SQL can mo trong SSMS.

| Role | Tinh nang | Mo ta ngan | File |
|---|---|---|---|
| Setup check | Kiem tra database object | Kiem tra schema, bang, view va stored procedure da tao du chua. | `00_setup_check/01_check_database_objects.sql` |
| Setup check | Kiem tra seed data | Kiem tra du lieu nen toi thieu da san sang chay demo. | `00_setup_check/02_check_seed_data.sql` |
| Customer | Xem tram va cong sac kha dung | Khach hang xem cac cong dang san sang de dat lich hoac bat dau sac. | `customer/01_view_available_stations.sql` |
| Customer | Them xe | Tao ho so xe moi bang stored procedure. | `customer/02_create_vehicle.sql` |
| Customer | Cap nhat xe | Cap nhat model, pin, connector uu tien hoac trang thai xe. | `customer/03_update_vehicle.sql` |
| Customer | Tao booking | Dat truoc cong sac theo khung thoi gian hop le. | `customer/04_create_booking.sql` |
| Customer | Huy booking | Huy booking con hieu luc va kiem tra trang thai sau khi huy. | `customer/05_cancel_booking.sql` |
| Customer | Xem lich su booking | Doc lich su dat sac cua khach hang qua view du lieu. | `customer/06_view_booking_history.sql` |
| Customer | Bat dau va ket thuc phien sac | Tao phien sac, ket thuc phien, tinh kWh va chi phi. | `customer/07_start_end_charging_session.sql` |
| Customer | Xem lich su sac | Xem tram, cong, xe, san luong va chi phi cac phien sac. | `customer/08_view_charging_history.sql` |
| Customer | Thanh toan va lap hoa don | Tao giao dich thanh toan va invoice cho phien sac da hoan tat. | `customer/09_create_payment_invoice.sql` |
| Customer | Xem chi tiet hoa don | Xem invoice, payment method, trang thai thanh toan va phien sac lien quan. | `customer/10_view_invoice_detail.sql` |
| OperationsStaff | Xem trang thai tram | Theo doi so cong kha dung, dang sac va gap su co theo tung tram. | `operations_staff/01_view_station_status.sql` |
| OperationsStaff | Cap nhat trang thai tram | Chuyen trang thai tram va ghi nhan audit. | `operations_staff/02_update_station_status.sql` |
| OperationsStaff | Cap nhat trang thai cong sac | Doi point status/health va kiem tra status history. | `operations_staff/03_update_point_status.sql` |
| OperationsStaff | Theo doi phien sac dang chay | Xem cac phien dang sac va thoi luong hoat dong. | `operations_staff/04_view_active_sessions.sql` |
| OperationsStaff | Xu ly phien sac loi | Chuyen phien dang sac sang Failed va giai phong cong. | `operations_staff/05_mark_session_failed.sql` |
| OperationsStaff | Ghi nhan loi thiet bi | Tao error log va maintenance ticket tu loi cong sac. | `operations_staff/06_report_error.sql` |
| OperationsStaff | Quan ly ticket bao tri | Lap lich, phan cong va dong ticket bao tri. | `operations_staff/07_assign_and_close_ticket.sql` |
| OperationsStaff | Theo doi telemetry | Xem mau telemetry Warning, Critical hoac Offline. | `operations_staff/08_view_telemetry_health.sql` |
| BusinessManager | Quan ly chinh sach gia | Tao va vo hieu hoa pricing policy. | `business_manager/01_manage_pricing_policy.sql` |
| BusinessManager | Xem doanh thu theo tram | Lay bo du lieu doanh thu tram theo khoang ngay. | `business_manager/02_view_station_revenue.sql` |
| BusinessManager | Xem doanh thu theo khu vuc | Tong hop doanh thu theo region. | `business_manager/03_view_region_revenue.sql` |
| BusinessManager | Xem top tram doanh thu cao | Xep hang tram theo doanh thu va so phien sac. | `business_manager/04_view_top_revenue_stations.sql` |
| BusinessManager | Thong ke gio cao diem | Phan tich phien sac va doanh thu theo gio bat dau. | `business_manager/05_view_peak_hours.sql` |
| BusinessManager | Cap nhat revenue share policy | Thay doi ty le chia doanh thu franchise. | `business_manager/06_update_revenue_share_policy.sql` |
| BusinessManager | Tao revenue settlement | Tao ky doi soat doanh thu cho franchise. | `business_manager/07_create_revenue_settlement.sql` |
| BusinessManager | Xem chia loi nhuan franchise | Xem phan doanh thu cua doi tac va nen tang. | `business_manager/08_view_franchise_profit.sql` |
| BusinessManager | Xem tang truong khach hang | Dem khach hang moi theo thang. | `business_manager/09_view_customer_growth.sql` |
| BusinessManager | Xem KPI van hanh he thong | Xem tram, cong, phien sac, loi, ticket va top customer. | `business_manager/10_view_system_kpi.sql` |
| BusinessManager | Hoan tien co ban | Doi trang thai payment va invoice sang Refunded, khong tao bang refund rieng. | `business_manager/11_refund_payment.sql` |
| SystemAdmin | Tao tai khoan | Tao user moi va gan role ban dau. | `system_admin/01_create_user.sql` |
| SystemAdmin | Khoa va mo tai khoan | Thay doi AccountStatus de kiem soat truy cap. | `system_admin/02_lock_unlock_user.sql` |
| SystemAdmin | Reset password | Cap nhat PasswordHash va ghi audit. | `system_admin/03_reset_password.sql` |
| SystemAdmin | Gan va go role | Gan hoac go role cua user. | `system_admin/04_assign_remove_role.sql` |
| SystemAdmin | Xem tong hop user-role | Xem tai khoan, trang thai va danh sach role. | `system_admin/05_view_user_role_summary.sql` |
| SystemAdmin | Xem audit log | Kiem tra lich su thay doi du lieu va thao tac quan trong. | `system_admin/06_view_audit_log.sql` |
| SystemAdmin | Chuan bi backup/restore | Xem cau lenh mau de sao luu va phuc hoi database. | `system_admin/07_backup_restore_demo.sql` |
| Security | Kiem tra quyen Customer | Customer doc view duoc cap quyen nhung khong doc truc tiep bang payment. | `security/01_customer_permissions.sql` |
| Security | Kiem tra quyen OperationsStaff | Operator xem du lieu van hanh nhung khong doc truc tiep bang identity. | `security/02_operations_permissions.sql` |
| Security | Kiem tra quyen BusinessManager | Business manager xem doanh thu nhung khong update truc tiep bang tram. | `security/03_business_permissions.sql` |
| Security | Kiem tra quyen SystemAdmin | Admin xem user-role va audit log. | `security/04_admin_permissions.sql` |
| Security | Dynamic data masking | Email, phone va password hash bi che voi user khong co UNMASK. | `security/05_masking_demo.sql` |
| Security | Row-level security | Customer chi thay phien sac cua minh trong policy tam thoi. | `security/06_row_level_security_demo.sql` |
| Security | Soft delete | Vo hieu hoa xe bang IsActive thay vi xoa vat ly. | `security/07_soft_delete_demo.sql` |
| Negative test | Booking sai thoi gian | Tu choi booking co BookedFrom khong nho hon BookedTo. | `negative_tests/01_invalid_booking_time.sql` |
| Negative test | Dat cong da ban | Tu choi booking trung thoi gian tren cung cong sac. | `negative_tests/02_booking_busy_point.sql` |
| Negative test | Thanh toan trung | Tu choi tao payment lan hai cho session da thanh toan. | `negative_tests/03_duplicate_payment.sql` |
| Negative test | Ket thuc session hai lan | Tu choi ket thuc lai session da Completed. | `negative_tests/04_end_session_twice.sql` |
| Negative test | Truy cap trai quyen | Customer bi chan khi doc truc tiep bang identity. | `negative_tests/05_unauthorized_access.sql` |
| Negative test | Rollback transaction | Loi cuong buc lam thao tac tao du lieu do bi rollback. | `negative_tests/06_transaction_rollback.sql` |

