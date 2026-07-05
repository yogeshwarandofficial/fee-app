const express = require('express');
const router = express.Router();
const {
  listStudents,
  exportStudents,
  getStudent,
  getStudentHistory,
  createStudent,
  updateStudent,
  updateStudentFees,
  addOtherFee,
  deleteStudent,
} = require('../controllers/studentController');

// IMPORTANT: /export must be declared before /:id to prevent Express
// from capturing the literal string "export" as an :id parameter.
router.get('/export',       exportStudents);

router.get('/',             listStudents);
router.get('/:id',          getStudent);
router.get('/:id/history',  getStudentHistory);
router.post('/',            createStudent);
router.put('/:id',          updateStudent);
router.put('/:id/fees',     updateStudentFees);
router.post('/:id/other-fee', addOtherFee);
router.delete('/:id',       deleteStudent);

module.exports = router;
