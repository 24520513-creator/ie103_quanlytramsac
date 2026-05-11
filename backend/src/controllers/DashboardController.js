const dashboardService = require('../services/DashboardService');
const { asyncHandler } = require('../middleware/errorHandler');

exports.getStationDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getStationDashboard(req.params.id, req.query.days);
  res.json(result);
});

exports.getFranchiseDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getFranchiseDashboard(req.params.id, req.query.days);
  res.json(result);
});

exports.getAdminDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getAdminDashboard();
  res.json(result);
});
