const { execute } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');
const { Booking } = require('../models/Operations');
const socketService = require('./socketService');
const notificationService = require('./NotificationService');

class BookingService {
  async createBooking({ UserID, PointID, StationID, VehicleID, BookedFrom, BookedTo }) {
    if (!StationID || !PointID || !BookedFrom || !BookedTo) {
      throw new ValidationError('Missing required fields: StationID, PointID, BookedFrom, BookedTo');
    }
    const normalizeDate = (d) => typeof d === 'string' && d.includes('T') && d.length === 16 ? d + ':00' : d;
    BookedFrom = normalizeDate(BookedFrom);
    BookedTo = normalizeDate(BookedTo);
    if (new Date(BookedFrom) >= new Date(BookedTo)) {
      throw new ValidationError('BookedFrom must be earlier than BookedTo');
    }

    const result = await execute('Operations.sp_CreateBooking', {
      UserID, PointID, StationID, VehicleID: VehicleID || null,
      BookedFrom, BookedTo,
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new Error('Create booking returned no result');
    }
    const booking = new Booking(result.recordset[0]);

    try {
      socketService.sendToStation(StationID, 'booking:created', booking);
      socketService.sendToUser(UserID, 'booking:created', booking);
      socketService.sendToRole('Manager', 'booking:created', booking);
    } catch (notifyErr) {
      console.error('Post-commit notification failed:', notifyErr.message);
    }

    return successResponse(booking, 'Booking created');
  }

  async confirmBooking(bookingId) {
    const result = await execute('Operations.sp_ConfirmBooking', { BookingID: bookingId });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('Pending booking');
    }
    const booking = new Booking(result.recordset[0]);

    try {
      socketService.sendToStation(booking.StationID, 'booking:confirmed', booking);
      socketService.sendToUser(booking.UserID, 'booking:confirmed', booking);
      await notificationService.create(booking.UserID, {
        Title: 'Đặt lịch đã xác nhận',
        Body: `Đặt lịch ${booking.BookingCode} tại trạm #${booking.StationID} đã được xác nhận.`,
        Type: 'Success',
        ReferenceType: 'Booking',
        ReferenceID: bookingId,
      });
    } catch (notifyErr) {
      console.error('Post-commit notification failed:', notifyErr.message);
    }

    return successResponse(booking, 'Booking confirmed');
  }

  async cancelBooking(bookingId, reason) {
    const result = await execute('Operations.sp_CancelBooking', { BookingID: bookingId });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('Booking');
    }
    const cancelled = new Booking(result.recordset[0]);

    try {
      socketService.sendToStation(cancelled.StationID, 'booking:cancelled', { BookingID: bookingId, Status: 'Cancelled' });
      socketService.sendToUser(cancelled.UserID, 'booking:cancelled', cancelled);
    } catch (notifyErr) {
      console.error('Post-commit notification failed:', notifyErr.message);
    }

    return successResponse(cancelled, 'Booking cancelled');
  }

  async checkAvailability(pointId, startTime, endTime) {
    const result = await execute('Operations.sp_CheckBookingAvailability', {
      PointID: pointId, FromTime: startTime, ToTime: endTime,
    });
    const row = result.recordset[0] || { IsAvailable: false, ConflictingBookings: 0 };
    return successResponse({ available: row.IsAvailable, conflictingBookings: row.ConflictingBookings });
  }
}

module.exports = new BookingService();
