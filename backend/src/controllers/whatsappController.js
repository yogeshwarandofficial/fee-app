const Student  = require('../models/Student');
const { sendMessage } = require('../utils/whatsappProvider');
const { sendSuccess, sendError } = require('../utils/responseHelper');

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Returns true if the number is a valid 10-digit Indian mobile number. */
const isValidPhone = (n) => typeof n === 'string' && /^\d{10}$/.test(n.trim());

/**
 * Builds the plain-text reminder message from student data.
 * Keeps it short, polite, and actionable.
 */
function buildReminderMessage(student) {
  const { full_name, balances } = student;
  const { tuition, transport, other } = balances;
  const total =
    (tuition?.due   || 0) +
    (transport?.due || 0) +
    (other?.due     || 0);

  const lines = [
    `Dear Parent of *${full_name}*,`,
    ``,
    `This is a gentle reminder from MRT & ABR Matriculation School regarding the outstanding fee balance.`,
    ``,
    `📋 *Fee Summary:*`,
  ];

  if ((tuition?.due || 0) > 0) {
    lines.push(`  • Tuition    : ₹${Number(tuition.due).toLocaleString('en-IN')}`);
  }
  if ((transport?.due || 0) > 0) {
    lines.push(`  • Transport  : ₹${Number(transport.due).toLocaleString('en-IN')}`);
  }
  if ((other?.due || 0) > 0) {
    lines.push(`  • Other Fees : ₹${Number(other.due).toLocaleString('en-IN')}`);
  }

  lines.push(``);
  lines.push(`💰 *Total Outstanding: ₹${Number(total).toLocaleString('en-IN')}*`);
  lines.push(``);
  lines.push(`Kindly clear the dues at your earliest convenience.`);
  lines.push(`Thank you for your cooperation.`);
  lines.push(`— MRT & ABR Matriculation School Administration`);

  return lines.join('\n');
}

// ── POST /api/whatsapp/send-individual/:id ────────────────────────────────────

const sendIndividual = async (req, res, next) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return sendError(res, 'Student not found.', 404);

    // Validation: phone number
    if (!isValidPhone(student.phone_number)) {
      return sendError(
        res,
        `Cannot send reminder: ${student.full_name} has a missing or invalid phone number.`,
        400
      );
    }

    // Validation: outstanding balance
    const { tuition, transport, other } = student.balances;
    const totalDue =
      (tuition?.due   || 0) +
      (transport?.due || 0) +
      (other?.due     || 0);

    if (totalDue <= 0) {
      return sendError(
        res,
        `Cannot send reminder: ${student.full_name} has no outstanding balance.`,
        400
      );
    }

    // Build WhatsApp deep link — backend only generates the URL, never opens it.
    const message     = buildReminderMessage(student);
    const encodedText = encodeURIComponent(message);
    const whatsappUrl = `https://wa.me/91${student.phone_number.trim()}?text=${encodedText}`;

    return sendSuccess(res, { url: whatsappUrl }, 'WhatsApp URL generated successfully.');
  } catch (err) {
    next(err);
  }
};

// ── POST /api/whatsapp/send-bulk ──────────────────────────────────────────────

const sendBulk = async (req, res, next) => {
  try {
    const { student_ids } = req.body;

    if (!Array.isArray(student_ids) || student_ids.length === 0) {
      return sendError(res, 'student_ids must be a non-empty array.', 400);
    }

    const totalSelected = student_ids.length;

    // Fetch all selected students in one query
    const students = await Student.find({ _id: { $in: student_ids } });

    // Filter to eligible students only — never fail the whole request
    const eligible = students.filter((s) => {
      if (!isValidPhone(s.phone_number)) return false;
      const { tuition, transport, other } = s.balances;
      const due =
        (tuition?.due   || 0) +
        (transport?.due || 0) +
        (other?.due     || 0);
      return due > 0;
    });

    const skipped = totalSelected - eligible.length;

    // Dispatch all eligible students through the WhatsApp provider
    let sent = 0;
    await Promise.allSettled(
      eligible.map(async (student) => {
        try {
          const message = buildReminderMessage(student);
          await sendMessage(student.phone_number.trim(), message);
          sent++;
        } catch (err) {
          // Log per-student failures but never abort the bulk operation
          console.error(
            `[WhatsApp] Failed to send to ${student.full_name} (${student.phone_number}):`,
            err.message
          );
        }
      })
    );

    return sendSuccess(
      res,
      {
        totalSelected,
        eligible:  eligible.length,
        sent,
        skipped,
      },
      'Bulk reminder dispatch complete.'
    );
  } catch (err) {
    next(err);
  }
};

module.exports = { sendIndividual, sendBulk };
