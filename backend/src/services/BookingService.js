const { query } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');

class BookingService {
  async createBooking({ UserID, PointID, StationID, VehicleID, StartTime, EndTime, Notes }) {
    const point = await query(`SELECT * FROM [Infrastructure].[ChargingPoint] WHERE PointID = @PointID AND IsActive = 1`,
      { PointID });
    if (point.recordset.length === 0) throw new NotFoundError('ChargingPoint');
    if (point.recordset[0].PointStatus !== 'Available') {
      throw new ValidationError('Point is not available for booking');
    }

    const existing = await query(`SELECT COUNT(*) AS Cnt FROM [Operations].[Booking]
      WHERE PointID = @PointID AND Status IN ('Pending', 'Confirmed')
      AND StartTime < @End AND EndTime > @Start`,
      { PointID, Start: StartTime, End: EndTime });
    if (existing.recordset[0].Cnt > 0) {
      throw new ValidationError('Time slot conflicts with an existing booking');
    }

    const result = await query(`INSERT INTO [Operations].[Booking]
      (UserID, PointID, StationID, VehicleID, StartTime, EndTime, Status, Notes, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@UserID, @PointID, @StationID, @VehicleID, @Start, @End, 'Pending', @Notes, SYSDATETIME())`,
      { UserID, PointID, StationID, VehicleID: VehicleID || null, Start: StartTime, End: EndTime, Notes: Notes || null });
    return successResponse(result.recordset[0], 'Booking created');
  }

  async confirmBooking(bookingId) {
    const booking = await query(`SELECT * FROM [Operations].[Booking] WHERE BookingID = @ID AND Status = 'Pending'`,
      { ID: bookingId });
    if (booking.recordset.length === 0) throw new NotFoundError('Pending booking');
    const result = await query(`UPDATE [Operations].[Booking] SET Status = 'Confirmed', UpdatedAt = SYSDATETIME()
      OUTPUT INSERTED.* WHERE BookingID = @ID`, { ID: bookingId });
    return successResponse(result.recordset[0], 'Booking confirmed');
  }

  async cancelBooking(bookingId, reason) {
    const booking = await query(`SELECT * FROM [Operations].[Booking] WHERE BookingID = @ID`,
      { ID: bookingId });
    if (booking.recordset.length === 0) throw new NotFoundError('Booking');
    const s = booking.recordset[0];
    if (!['Pending', 'Confirmed'].includes(s.Status)) {
      throw new ValidationError(`Cannot cancel booking with status ${s.Status}`);
    }
    const result = await query(`UPDATE [Operations].[Booking] SET Status = 'Cancelled', CancelledAt = SYSDATETIME(),
      CancelReason = @Reason, UpdatedAt = SYSDATETIME() OUTPUT INSERTED.* WHERE BookingID = @ID`,
      { ID: bookingId, Reason: reason || 'CancelledByUser' });
    return successResponse(result.recordset[0], 'Booking cancelled');
  }

  async checkAvailability(pointId, startTime, endTime) {
    const conflicts = await query(`SELECT COUNT(*) AS Cnt FROM [Operations].[Booking]
      WHERE PointID = @PointID AND Status IN ('Pending', 'Confirmed')
      AND StartTime < @End AND EndTime > @Start`,
      { PointID: pointId, Start: startTime, End: endTime });
    const point = await query(`SELECT PointStatus FROM [Infrastructure].[ChargingPoint] WHERE PointID = @PointID`,
      { PointID: pointId });
    const isAvailable = (point.recordset[0]?.PointStatus === 'Available') && conflicts.recordset[0].Cnt === 0;
    return successResponse({ available: isAvailable, conflictingBookings: conflicts.recordset[0].Cnt });
  }
}

module.exports = new BookingService();
