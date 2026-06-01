import React from 'react';
import { CustomerHome, FindStations, MyVehicles, Bookings, Sessions, Invoices } from './screens';
import { ProfileScreen } from '../ProfileScreen';
import {
  DashboardIcon, MapPinIcon, ChargingIcon, CalendarIcon, CarIcon, PaymentIcon, ProfileIcon
} from '../../components/Icons';

export function customerSections(h) {
  const sections = [];
  const add = (id, label, icon, group, Comp) => {
    sections.push({ id, label, icon, group, render: (ctx) => <Comp ctx={ctx} h={h} /> });
  };

  add('home', 'Trang chủ', <DashboardIcon size={18} />, 'Tổng quan', CustomerHome);
  if (h.has('availablePoints')) add('find', 'Tìm trạm & sạc', <MapPinIcon size={18} />, 'Sạc điện', FindStations);
  if (h.has('chargingHistory')) add('sessions', 'Phiên sạc', <ChargingIcon size={18} />, 'Sạc điện', Sessions);
  if (h.has('bookingHistory')) add('bookings', 'Đặt chỗ', <CalendarIcon size={18} />, 'Sạc điện', Bookings);
  if (h.has('myVehicles')) add('vehicles', 'Xe của tôi', <CarIcon size={18} />, 'Sạc điện', MyVehicles);
  if (h.has('invoiceDetail')) add('invoices', 'Hoá đơn', <PaymentIcon size={18} />, 'Thanh toán', Invoices);
  if (h.has('me')) {
    sections.push({
      id: 'me', label: 'Hồ sơ', icon: <ProfileIcon size={18} />, group: 'Tài khoản',
      render: (ctx) => <ProfileScreen ctx={ctx} h={h} />
    });
  }
  return sections;
}
