const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse, NotFoundError } = require('../utils/response');
const { query } = require('../config/database');

function createCrudController(service, entityName) {
  return {
    getAll: asyncHandler(async (req, res) => {
      const filters = { ...req.query, ...(req.user?.FranchiseID ? { franchiseId: req.user.FranchiseID } : {}) };
      if (filters.page) filters.page = parseInt(filters.page);
      if (filters.limit) filters.limit = parseInt(filters.limit);
      const result = await service.getAll(filters);
      res.json(result);
    }),

    getById: asyncHandler(async (req, res) => {
      const result = await service.getById(req.params.id);
      res.json(result);
    }),

    create: asyncHandler(async (req, res) => {
      const result = await service.create(req.body);
      res.status(201).json(result);
    }),

    update: asyncHandler(async (req, res) => {
      const result = await service.update(req.params.id, req.body);
      res.json(result);
    }),

    delete: asyncHandler(async (req, res) => {
      const result = await service.delete(req.params.id);
      res.json(result);
    }),
  };
}

module.exports = { createCrudController };
