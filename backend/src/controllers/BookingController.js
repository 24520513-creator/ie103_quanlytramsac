const bookingService = require('../services/BookingService');
const { asyncHandler } = require('../middleware/errorHandler');
const { ValidationError } = require('../utils/response');

exports.createBooking = asyncHandler(async (req, res) => {
  const { PointID, StationID, BookedFrom, BookedTo } = req.body;
  if (!PointID || !StationID || !BookedFrom || !BookedTo) {
    throw new ValidationError('PointID, StationID, BookedFrom, BookedTo are required');
  }
  const result = await bookingService.createBooking({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.confirmBooking = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Booking ID is required');
  const result = await bookingService.confirmBooking(req.params.id);
  res.json(result);
});

exports.cancelBooking = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Booking ID is required');
  const result = await bookingService.cancelBooking(req.params.id, req.body.reason);
  res.json(result);
});

exports.checkPointAvailability = asyncHandler(async (req, res) => {
  const { pointId, startTime, endTime } = req.query;
  if (!pointId || !startTime || !endTime) {
    throw new ValidationError('pointId, startTime, endTime query params are required');
  }
  const result = await bookingService.checkAvailability(pointId, new Date(startTime), new Date(endTime));
  res.json(result);
});
