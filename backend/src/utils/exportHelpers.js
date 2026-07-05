const ExcelJS = require('exceljs');

// ── Brand colours for Excel exports ──────────────────────────────────────────
const HEADER_BG   = '1A3C6E'; // deep institutional blue (matches app theme)
const HEADER_FG   = 'FFFFFF';
const META_BG     = 'DBE9FF'; // light blue for metadata rows
const META_FG     = '001D3D';
const ALT_ROW_BG  = 'F4F6FA'; // alternating row tint

/**
 * Formats a Date as "29 Jun 2026, 09:44 AM IST" for export headers.
 */
const formatExportTimestamp = (date = new Date()) => {
  return date.toLocaleString('en-IN', {
    day:      '2-digit',
    month:    'short',
    year:     'numeric',
    hour:     '2-digit',
    minute:   '2-digit',
    hour12:   true,
    timeZone: 'Asia/Kolkata',
  }) + ' IST';
};

// ─────────────────────────────────────────────────────────────────────────────
// EXCEL HELPER
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Generates an Excel (.xlsx) file as an in-memory Buffer.
 *
 * @param {string} sheetName - Worksheet tab name.
 * @param {Array<{ key: string, header: string, width?: number }>} columns
 *   - `key`    : property name on each row object.
 *   - `header` : column header label shown to the user.
 *   - `width`  : optional column width in characters (default 20).
 * @param {Array<Object>} rows - Array of plain objects; each object's keys
 *   must match the `key` fields in `columns`.
 * @param {Object} [filters={}] - Metadata about applied filters, embedded in
 *   a header section above the data. E.g. { Grade: "Grade 5", Section: "A" }.
 * @returns {Promise<Buffer>} - Resolves with the xlsx buffer.
 */
const generateExcelBuffer = async (sheetName, columns, rows, filters = {}) => {
  const workbook  = new ExcelJS.Workbook();
  workbook.creator  = 'MRT & ABR Matriculation School Fee Manager';
  workbook.created  = new Date();
  workbook.modified = new Date();

  const sheet = workbook.addWorksheet(sheetName, {
    views: [{ state: 'frozen', ySplit: 0 }], // updated after metadata rows
  });

  const colCount = columns.length;

  // ── Helper: apply style to a single cell ──────────────────────────────────
  const styleCell = (cell, { bg, fg, bold = false, align = 'left', numFmt } = {}) => {
    if (bg) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${bg}` } };
    if (fg) cell.font = { color: { argb: `FF${fg}` }, bold, name: 'Calibri', size: 11 };
    else if (bold) cell.font = { bold, name: 'Calibri', size: 11 };
    cell.alignment = { vertical: 'middle', horizontal: align, wrapText: false };
    if (numFmt) cell.numFmt = numFmt;
    cell.border = {
      bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
    };
  };

  // ── Metadata section ──────────────────────────────────────────────────────
  let currentRow = 1;

  // Report title
  const titleRow = sheet.getRow(currentRow++);
  titleRow.height = 24;
  const titleCell = titleRow.getCell(1);
  titleCell.value = `MRT & ABR Matriculation School — ${sheetName}`;
  titleCell.font  = { bold: true, size: 14, color: { argb: `FF${HEADER_BG}` }, name: 'Calibri' };
  titleCell.alignment = { vertical: 'middle', horizontal: 'left' };
  sheet.mergeCells(titleRow.number, 1, titleRow.number, colCount);

  // Generated timestamp
  const tsRow  = sheet.getRow(currentRow++);
  const tsCell = tsRow.getCell(1);
  tsCell.value = `Generated: ${formatExportTimestamp()}`;
  tsCell.font  = { italic: true, size: 10, color: { argb: 'FF64748B' }, name: 'Calibri' };
  sheet.mergeCells(tsRow.number, 1, tsRow.number, colCount);

  // Applied filters (one row per filter key)
  const filterEntries = Object.entries(filters);
  if (filterEntries.length > 0) {
    const filterLabelRow = sheet.getRow(currentRow++);
    filterLabelRow.height = 18;
    const flCell = filterLabelRow.getCell(1);
    flCell.value = 'Filters Applied:';
    flCell.font  = { bold: true, size: 10, color: { argb: `FF${META_FG}` }, name: 'Calibri' };
    flCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${META_BG}` } };
    sheet.mergeCells(filterLabelRow.number, 1, filterLabelRow.number, colCount);

    for (const [key, value] of filterEntries) {
      const fRow = sheet.getRow(currentRow++);
      fRow.height = 16;
      const fCell = fRow.getCell(1);
      fCell.value = `  ${key}: ${value}`;
      fCell.font  = { size: 10, color: { argb: `FF${META_FG}` }, name: 'Calibri' };
      fCell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${META_BG}` } };
      sheet.mergeCells(fRow.number, 1, fRow.number, colCount);
    }
  }

  // Blank separator
  currentRow++;

  // ── Column headers ────────────────────────────────────────────────────────
  const headerRow = sheet.getRow(currentRow++);
  headerRow.height = 22;

  columns.forEach((col, idx) => {
    const cell = headerRow.getCell(idx + 1);
    cell.value = col.header;
    styleCell(cell, { bg: HEADER_BG, fg: HEADER_FG, bold: true, align: 'center' });
    sheet.getColumn(idx + 1).width = col.width || 20;
    sheet.getColumn(idx + 1).key   = col.key;
  });

  // Freeze panes at the data start row
  sheet.views = [{ state: 'frozen', ySplit: currentRow - 1 }];

  // ── Data rows ─────────────────────────────────────────────────────────────
  rows.forEach((rowData, rowIdx) => {
    const dataRow = sheet.getRow(currentRow++);
    dataRow.height = 18;
    const isAlt   = rowIdx % 2 === 1;

    columns.forEach((col, colIdx) => {
      const cell  = dataRow.getCell(colIdx + 1);
      cell.value  = rowData[col.key] ?? '';
      styleCell(cell, {
        bg:     isAlt ? ALT_ROW_BG : undefined,
        align:  typeof rowData[col.key] === 'number' ? 'right' : 'left',
        numFmt: col.numFmt,
      });
    });
  });

  // ── Row count footer ──────────────────────────────────────────────────────
  currentRow++;
  const footerRow  = sheet.getRow(currentRow);
  const footerCell = footerRow.getCell(1);
  footerCell.value = `Total records: ${rows.length}`;
  footerCell.font  = { italic: true, size: 10, color: { argb: 'FF64748B' }, name: 'Calibri' };
  sheet.mergeCells(footerRow.number, 1, footerRow.number, colCount);

  return workbook.xlsx.writeBuffer();
};

// ─────────────────────────────────────────────────────────────────────────────
// CSV HELPER
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Escapes a single field value per RFC 4180.
 *
 * Rules:
 *   - If the value contains a comma, double-quote, or newline (CR or LF),
 *     wrap the entire field in double-quotes.
 *   - Internal double-quotes are escaped by doubling them ("").
 *   - null / undefined → empty string.
 */
const escapeCsvField = (value) => {
  if (value === null || value === undefined) return '';
  const str = String(value);
  // Must quote if contains comma, double-quote, CR, or LF
  if (/[,"\r\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
};

/**
 * Generates a RFC 4180-compliant CSV string.
 *
 * @param {Array<{ key: string, header: string }>} columns
 * @param {Array<Object>} rows
 * @param {Object} [filters={}] - Applied filters embedded as comment rows
 *   at the top of the file (lines prefixed with '#').
 * @returns {string} - Complete CSV content as a string (UTF-8).
 */
const generateCsvString = (columns, rows, filters = {}) => {
  const lines = [];

  // ── Metadata comment block ─────────────────────────────────────────────────
  // CSV has no standard for metadata; we use '#' comment lines (widely
  // recognised by Excel, Google Sheets, and pandas).
  lines.push(`# MRT & ABR Matriculation School Fee Manager — Export`);
  lines.push(`# Generated: ${formatExportTimestamp()}`);

  const filterEntries = Object.entries(filters);
  if (filterEntries.length > 0) {
    lines.push('# Filters Applied:');
    for (const [key, value] of filterEntries) {
      lines.push(`#   ${key}: ${value}`);
    }
  }
  lines.push('#'); // blank comment separator

  // ── Header row ────────────────────────────────────────────────────────────
  lines.push(columns.map((col) => escapeCsvField(col.header)).join(','));

  // ── Data rows ─────────────────────────────────────────────────────────────
  for (const rowData of rows) {
    const fields = columns.map((col) => escapeCsvField(rowData[col.key]));
    lines.push(fields.join(','));
  }

  // RFC 4180 §2.1: use CRLF as the line separator.
  return lines.join('\r\n');
};

module.exports = { generateExcelBuffer, generateCsvString };
