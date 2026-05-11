const maintenanceService = require('../services/MaintenanceService');
const { asyncHandler } = require('../middleware/errorHandler');
const { ValidationError } = require('../utils/response');

exports.scheduleMaintenance = asyncHandler(async (req, res) => {
  const { StationID, ScheduledFrom, ScheduledTo } = req.body;
  if (!StationID || !ScheduledFrom || !ScheduledTo) {
    throw new ValidationError('StationID, ScheduledFrom, ScheduledTo are required');
  }
  const result = await maintenanceService.scheduleMaintenance({ ...req.body, ScheduledBy: req.user.UserID });
  res.status(201).json(result);
});

exports.completeMaintenance = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Maintenance ID is required');
  const result = await maintenanceService.completeMaintenance(req.params.id, { Notes: req.body.Notes, CompletedAt: req.body.CompletedAt });
  res.json(result);
});

exports.getUpcomingMaintenance = asyncHandler(async (req, res) => {
  const result = await maintenanceService.getUpcoming(req.query.days);
  res.json(result);
});

exports.resolveError = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Error ID is required');
  const result = await maintenanceService.resolveError(req.params.id, { ResolvedBy: req.user.UserID });
  res.json(result);
});
