const BaseRepository = require('../repositories/BaseRepository');
const { NotFoundError, ValidationError, successResponse, paginatedResponse } = require('../utils/response');

function createCrudService(repository, entityName, uniqueFields = []) {
  return {
    async getAll(filters = {}) {
      const items = await repository.findAll(filters);
      const total = await repository.count(filters);
      return filters.page ? paginatedResponse(items, total, filters.page, filters.limit) : successResponse(items);
    },

    async getById(id) {
      const item = await repository.findById(id);
      if (!item) throw new NotFoundError(entityName);
      return successResponse(item);
    },

    async create(data) {
      for (const field of uniqueFields) {
        if (data[field]) {
          const existing = await repository.findOneBy({ [field]: data[field] });
          if (existing) throw new ValidationError(`${entityName} with ${field} '${data[field]}' already exists`);
        }
      }
      const item = await repository.create(data);
      return successResponse(item, `${entityName} created successfully`);
    },

    async update(id, data) {
      const existing = await repository.findById(id);
      if (!existing) throw new NotFoundError(entityName);
      for (const field of uniqueFields) {
        if (data[field] && data[field] !== existing[field]) {
          const dup = await repository.findOneBy({ [field]: data[field] });
          if (dup) throw new ValidationError(`${entityName} with ${field} '${data[field]}' already exists`);
        }
      }
      const item = await repository.update(id, data);
      return successResponse(item, `${entityName} updated successfully`);
    },

    async delete(id) {
      const existing = await repository.findById(id);
      if (!existing) throw new NotFoundError(entityName);
      await repository.delete(id);
      return successResponse(null, `${entityName} deleted successfully`);
    },

    async getBy(conditions) {
      const items = await repository.findBy(conditions);
      return successResponse(items);
    },
  };
}

module.exports = { createCrudService };
