const VIETNAMESE_TEST_STRINGS = [
  'Nguyễn Huệ',
  'Hệ Thống',
  'Trạm Sạc Phú Yên',
  'Điện Năng',
  'Quản Lý',
  '123 Nguyễn Huệ',
  'TP. Hồ Chí Minh',
  'Đà Nẵng',
  'Bình Dương',
  'Vũng Tàu',
  'Lê Duẩn',
  'Lý Thường Kiệt',
  'Tràng Tiền',
];

function validateEncoding(text) {
  if (!text || typeof text !== 'string') return { valid: false, reason: 'Not a string' };
  const expected = VIETNAMESE_TEST_STRINGS.find(s => s.normalize() === text.normalize());
  if (expected) return { valid: true, original: expected, received: text };
  const hasVietnamese = /[ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝàáâãèéêìíòóôõùúýĂăĐđĨĩŨũƠơƯưẠ-ỹ]/u.test(text);
  if (!hasVietnamese) return { valid: true, reason: 'No Vietnamese characters' };
  const corrupted = /[ßþýÿ]/.test(text) || /[\\u0000-\\u001F]/.test(text);
  if (corrupted) {
    const decoded = Buffer.from(text, 'latin1').toString('utf8');
    return { valid: false, original: decoded, received: text, note: 'UTF-8 bytes interpreted as Latin1/CP1252 (mojibake)' };
  }
  return { valid: true, reason: 'Contains Vietnamese but appears correct' };
}

function checkFileEncoding(filePath) {
  const fs = require('fs');
  const bytes = fs.readFileSync(filePath);
  const hasBOM = bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF;
  const isUTF8 = hasBOM || (() => {
    try {
      const decoded = bytes.toString('utf8');
      const reEncoded = Buffer.from(decoded, 'utf8');
      return reEncoded.equals(bytes);
    } catch { return false; }
  })();
  return { file: filePath, hasBOM, isUTF8, size: bytes.length };
}

module.exports = { VIETNAMESE_TEST_STRINGS, validateEncoding, checkFileEncoding };
