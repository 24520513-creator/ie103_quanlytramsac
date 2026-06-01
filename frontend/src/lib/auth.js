// Shared auth helpers — single source of truth for password rules & register validation.
// Used by screens/auth/AuthPage.jsx (do not duplicate these inline).

const STRENGTH_LABELS = ['Chưa đạt', 'Yếu', 'Đạt', 'Tốt', 'Mạnh'];

export function passwordStrength(password = '') {
  let score = 0;
  if (password.length >= 10) score += 1;
  if (/[A-Za-zÀ-ỹ]/.test(password) && /\d/.test(password)) score += 1;
  if (/[^A-Za-zÀ-ỹ0-9]/.test(password)) score += 1;
  if (password.length >= 14) score += 1;
  return { score, label: STRENGTH_LABELS[score] || STRENGTH_LABELS[0] };
}

export function validateRegister(form) {
  if (!form.fullName.trim() || !form.username.trim() || !form.email.trim() || !form.password) {
    return 'Vui lòng nhập đầy đủ các trường bắt buộc.';
  }
  if (!/^[a-zA-Z0-9._-]{4,50}$/.test(form.username)) {
    return 'Tên đăng nhập phải có 4-50 ký tự, chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.';
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return 'Email không hợp lệ.';
  if (form.password !== form.confirmPassword) return 'Mật khẩu nhập lại không khớp.';
  if (passwordStrength(form.password).score < 2) return 'Mật khẩu phải có ít nhất 10 ký tự và gồm cả chữ lẫn số.';
  if (!form.acceptedTerms) return 'Bạn cần đồng ý với điều khoản sử dụng.';
  return '';
}
