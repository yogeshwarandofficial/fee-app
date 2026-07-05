const MasterConfig = require('../models/MasterConfig');
const Student = require('../models/Student');
const { sendSuccess, sendError } = require('../utils/responseHelper');

// ── GET /api/master-config ──────────────────────────────────────────────────
const getConfig = async (req, res, next) => {
  try {
    const { type, parent_id } = req.query;
    const filter = {};
    if (type) filter.type = type;
    if (parent_id) filter.parent_id = parent_id;

    const configs = await MasterConfig.find(filter).sort({ name: 1 });
    return sendSuccess(res, configs, 'Master configs retrieved successfully');
  } catch (err) {
    next(err);
  }
};

// ── POST /api/master-config ─────────────────────────────────────────────────
const createConfig = async (req, res, next) => {
  try {
    const { type, name, parent_id } = req.body;

    if (!name || !name.trim()) {
      return sendError(res, 'Name is required and cannot be empty.', 400);
    }
    
    if (!['grade', 'section', 'route'].includes(type)) {
      return sendError(res, 'Invalid type. Must be grade, section, or route.', 400);
    }

    let validParentId = null;

    if (type === 'section') {
      if (!parent_id) {
        return sendError(res, 'parent_id is required when creating a section.', 400);
      }
      const parent = await MasterConfig.findOne({ _id: parent_id, type: 'grade' });
      if (!parent) {
        return sendError(res, 'Referenced grade does not exist.', 400);
      }
      validParentId = parent._id;
    } else {
      if (parent_id) {
        return sendError(res, 'parent_id must be null for grades and routes.', 400);
      }
    }

    const newConfig = new MasterConfig({
      type,
      name: name.trim(),
      parent_id: validParentId,
    });

    await newConfig.save();
    return sendSuccess(res, newConfig, 'Master config created successfully', 201);
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 'An entry with this name already exists in this category.', 400);
    }
    next(err);
  }
};

// ── PUT /api/master-config/:id ──────────────────────────────────────────────
const updateConfig = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    if (!name || !name.trim()) {
      return sendError(res, 'Name is required and cannot be empty.', 400);
    }

    const config = await MasterConfig.findById(id);
    if (!config) {
      return sendError(res, 'Config not found.', 404);
    }

    config.name = name.trim();
    
    await config.save();
    return sendSuccess(res, config, 'Master config updated successfully');
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 'An entry with this name already exists in this category.', 400);
    }
    next(err);
  }
};

// ── DELETE /api/master-config/:id ───────────────────────────────────────────
const deleteConfig = async (req, res, next) => {
  try {
    const { id } = req.params;
    const config = await MasterConfig.findById(id);
    if (!config) {
      return sendError(res, 'Config not found.', 404);
    }

    if (config.type === 'grade') {
      // Check for child sections
      const sections = await MasterConfig.find({ parent_id: id });
      if (sections.length > 0) {
        return sendError(res, 'Cannot delete this grade because it still has sections attached to it.', 400);
      }
      // Check for students
      const students = await Student.exists({ grade_id: id });
      if (students) {
        return sendError(res, 'Cannot delete this grade because there are students assigned to it.', 400);
      }
    } else if (config.type === 'section') {
      const students = await Student.exists({ section_id: id });
      if (students) {
        return sendError(res, 'Cannot delete this section because there are students assigned to it.', 400);
      }
    } else if (config.type === 'route') {
      const students = await Student.exists({ transport_route_id: id });
      if (students) {
        return sendError(res, 'Cannot delete this route because there are students assigned to it.', 400);
      }
    }

    await config.deleteOne();
    return sendSuccess(res, null, 'Master config deleted successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getConfig,
  createConfig,
  updateConfig,
  deleteConfig,
};
