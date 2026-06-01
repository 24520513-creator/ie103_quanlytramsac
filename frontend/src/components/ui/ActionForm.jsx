import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Button } from './index';
import { SpinnerIcon, CloseIcon } from '../Icons';
import { fetchLookup } from '../../lib/api';

const OPTION_LABELS = {
  Active: 'Đang hoạt động',
  Inactive: 'Tạm ngưng',
  UnderMaintenance: 'Đang bảo trì',
  Retired: 'Ngừng sử dụng',
  Available: 'Khả dụng',
  Reserved: 'Đã đặt chỗ',
  Charging: 'Đang sạc',
  Offline: 'Mất kết nối',
  Error: 'Lỗi',
  Maintenance: 'Bảo trì',
  Normal: 'Bình thường',
  Warning: 'Cảnh báo',
  Critical: 'Nghiêm trọng',
  Low: 'Thấp',
  Medium: 'Trung bình',
  High: 'Cao',
  CASH: 'Tiền mặt',
  QR: 'QR',
  BANK_TRANSFER: 'Chuyển khoản',
  Customer: 'Khách hàng',
  OperationsStaff: 'Nhân viên vận hành',
  BusinessManager: 'Quản lý kinh doanh',
  FranchisePartner: 'Đối tác nhượng quyền',
  SystemAdmin: 'Quản trị hệ thống'
};

function inputType(type) {
  if (type === 'date') return 'date';
  if (type === 'dateTime') return 'datetime-local';
  if (type === 'time') return 'time';
  if (type === 'decimal' || type === 'int' || type === 'bigInt') return 'number';
  return 'text';
}

function lookupKey(param) {
  if (!param.lookup) return '';
  return typeof param.lookup === 'string' ? param.lookup : param.lookup.key;
}

function optionValue(option) {
  return typeof option === 'object' ? option.value : option;
}

function optionLabel(option) {
  if (typeof option === 'object') return option.label ?? option.value;
  return OPTION_LABELS[option] || option;
}

function sameValue(left, right) {
  return String(left ?? '') === String(right ?? '');
}

function fieldInputType(param) {
  if (param.inputMode === 'password' || /password/i.test(param.name)) return 'password';
  return inputType(param.type);
}

function dependencyBody(param, values) {
  const out = {};
  for (const name of param.lookup?.dependsOn || []) out[name] = values?.[name] ?? '';
  return out;
}

function hasInitialValue(param, initial) {
  const value = initial?.[param.name];
  return value !== undefined && value !== null && value !== '';
}

function LookupField({ param, value, values, initial, token, onChange, onPatch }) {
  const key = lookupKey(param);
  const deps = useMemo(() => dependencyBody(param, values), [param, values]);
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(Boolean(key));
  const [error, setError] = useState('');
  const [activeIndex, setActiveIndex] = useState(-1);
  const inputRef = useRef(null);
  const locked = Boolean(param.lockedWhenInitial && hasInitialValue(param, initial));
  const missingRequiredDependency = Boolean(
    param.required && param.lookup?.dependsOn?.some((name) => values?.[name] === undefined || values?.[name] === null || values?.[name] === '')
  );
  const disabled = locked || missingRequiredDependency;

  useEffect(() => {
    if (!key || missingRequiredDependency) {
      setOptions([]);
      setLoading(false);
      return undefined;
    }
    let active = true;
    setLoading(true);
    setError('');
    fetchLookup(key, { ...deps, search: open ? query : '' }, token)
      .then((json) => { if (active) setOptions(json.options || []); })
      .catch((err) => { if (active) { setError(err.message); setOptions([]); } })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [key, token, query, open, missingRequiredDependency, JSON.stringify(deps)]);

  const selected = options.find((item) => sameValue(item.value, value));
  const hasValue = value !== undefined && value !== null && value !== '';
  // Never surface raw internal ids; while the label is loading show a neutral hint.
  const selectedLabel = selected?.label || (hasValue ? 'Đang tải tên...' : '');

  // Keep the input text in sync with the chosen label whenever the menu is closed.
  useEffect(() => {
    if (!open) setQuery(selectedLabel);
  }, [selectedLabel, open]);

  // Reset the keyboard highlight when the option set or open-state changes.
  useEffect(() => { setActiveIndex(-1); }, [open, options.length]);

  function change(next) {
    onChange(next?.value ?? '');
    setQuery(next?.label ?? '');
    setOpen(false);
    if (next?.meta && param.applyMeta) {
      const patch = {};
      for (const [targetField, metaKey] of Object.entries(param.applyMeta)) {
        if (next.meta[metaKey] !== undefined && next.meta[metaKey] !== null) patch[targetField] = next.meta[metaKey];
      }
      if (Object.keys(patch).length) onPatch?.(patch);
    }
  }

  function clear() {
    onChange('');
    setQuery('');
    setOpen(true);
    inputRef.current?.focus();
  }

  function onKeyDown(e) {
    if (disabled) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (!open) { setOpen(true); return; }
      setActiveIndex((i) => Math.min(i + 1, options.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setActiveIndex((i) => Math.max(i - 1, 0));
    } else if (e.key === 'Enter') {
      if (open && activeIndex >= 0 && options[activeIndex]) {
        e.preventDefault();
        change(options[activeIndex]);
      }
    } else if (e.key === 'Escape') {
      if (open) { e.preventDefault(); setOpen(false); setQuery(selectedLabel); }
    }
  }

  return (
    <>
      <div className="ui-combobox">
        <input
          ref={inputRef}
          className="ui-combobox-input"
          role="combobox"
          aria-expanded={open && !disabled}
          aria-autocomplete="list"
          value={disabled ? selectedLabel : query}
          onFocus={() => { if (!disabled) setOpen(true); }}
          onChange={(e) => {
            // Typing only filters; it never silently drops the current selection.
            setQuery(e.target.value);
            setOpen(true);
          }}
          onKeyDown={onKeyDown}
          onBlur={() => {
            window.setTimeout(() => {
              setOpen(false);
              setQuery(selectedLabel);
            }, 120);
          }}
          placeholder={missingRequiredDependency ? 'Chọn dữ liệu liên quan trước' : 'Tìm hoặc chọn...'}
          disabled={disabled}
          autoComplete="off"
        />
        {!disabled && hasValue && (
          <button
            type="button"
            className="ui-combobox-clear"
            aria-label="Xoá lựa chọn"
            onMouseDown={(e) => { e.preventDefault(); clear(); }}
          >
            <CloseIcon size={14} />
          </button>
        )}
        {!disabled && !hasValue && (
          <button
            type="button"
            className="ui-combobox-caret"
            aria-label={open ? 'Đóng danh sách' : 'Mở danh sách'}
            tabIndex={-1}
            onMouseDown={(e) => { e.preventDefault(); setOpen((v) => !v); inputRef.current?.focus(); }}
          >
            ⌄
          </button>
        )}
        {open && !disabled && (
          <div className="ui-combobox-menu" role="listbox">
            {loading ? (
              <div className="ui-combobox-empty">Đang tải...</div>
            ) : options.length ? (
              options.map((item, idx) => (
                <button
                  key={item.value}
                  type="button"
                  className={`ui-combobox-option${sameValue(item.value, value) ? ' active' : ''}${idx === activeIndex ? ' highlight' : ''}`}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    change(item);
                  }}
                  onMouseEnter={() => setActiveIndex(idx)}
                  role="option"
                  aria-selected={sameValue(item.value, value)}
                >
                  {item.label}
                </button>
              ))
            ) : (
              <div className="ui-combobox-empty">Không có lựa chọn phù hợp.</div>
            )}
          </div>
        )}
      </div>
      {locked && <small className="ui-field-hint">Đã chọn từ màn hình trước.</small>}
      {!loading && !missingRequiredDependency && !options.length && !hasValue && <small className="ui-field-hint">Không có lựa chọn phù hợp.</small>}
      {error && <small className="ui-field-error">{error}</small>}
    </>
  );
}

export function Field({ param, value, onChange, values = {}, initial = {}, token, onPatch, invalid = false }) {
  const label = (
    <span className="ui-field-label">
      {param.label}{param.required && <em>*</em>}
    </span>
  );

  if (param.type === 'bit') {
    return (
      <label className="ui-field ui-field-check">
        <input type="checkbox" checked={Boolean(value)} onChange={(e) => onChange(e.target.checked)} />
        {label}
      </label>
    );
  }

  return (
    <label className={`ui-field${invalid ? ' ui-field-invalid' : ''}`}>
      {label}
      {lookupKey(param) ? (
        <LookupField
          param={param}
          value={value}
          values={values}
          initial={initial}
          token={token}
          onChange={onChange}
          onPatch={onPatch}
        />
      ) : param.options?.length ? (
        <select value={value ?? ''} onChange={(e) => onChange(e.target.value)}>
          <option value="">Chọn...</option>
          {param.options.map((o) => <option key={optionValue(o)} value={optionValue(o)}>{optionLabel(o)}</option>)}
        </select>
      ) : (
        <input type={fieldInputType(param)} value={value ?? ''} onChange={(e) => onChange(e.target.value)} />
      )}
    </label>
  );
}

function buildDefaults(params, initial = {}) {
  const out = {};
  for (const p of params || []) out[p.name] = initial[p.name] ?? p.defaultValue ?? (p.type === 'bit' ? false : '');
  return out;
}

function isEmpty(v) {
  return v === undefined || v === null || v === '';
}

export function ActionForm({ action, initial, onSubmit, submitLabel, busy, error, columns = 2, token }) {
  const [values, setValues] = useState(() => buildDefaults(action.params, initial));
  const [localError, setLocalError] = useState('');
  const [invalidFields, setInvalidFields] = useState([]);

  const setField = (name, v) => setValues((prev) => {
    const next = { ...prev, [name]: v };
    for (const p of action.params || []) {
      if (p.lookup?.dependsOn?.includes(name) && !p.lockedWhenInitial && prev[name] !== v) next[p.name] = '';
    }
    return next;
  });

  const patchFields = (patch) => setValues((prev) => ({ ...prev, ...patch }));

  function validate() {
    // Required fields first so the user fixes the obvious gap before format checks.
    const missing = (action.params || []).filter((p) => p.required && p.type !== 'bit' && isEmpty(values[p.name]));
    if (missing.length) {
      return { message: `Vui lòng nhập: ${missing.map((p) => p.label).join(', ')}.`, fields: missing.map((p) => p.name) };
    }
    const badNumber = (action.params || []).find(
      (p) => ['decimal', 'int', 'bigInt'].includes(p.type) && !isEmpty(values[p.name]) && Number.isNaN(Number(values[p.name]))
    );
    if (badNumber) {
      return { message: `"${badNumber.label}" phải là số hợp lệ.`, fields: [badNumber.name] };
    }
    if (values.BookedFrom && values.BookedTo && new Date(values.BookedFrom) >= new Date(values.BookedTo)) {
      return { message: 'Thời gian bắt đầu phải trước thời gian kết thúc.', fields: ['BookedFrom', 'BookedTo'] };
    }
    if (values.TotalKWh !== undefined && values.TotalKWh !== '' && Number(values.TotalKWh) <= 0) {
      return { message: 'Tổng kWh phải lớn hơn 0.', fields: ['TotalKWh'] };
    }
    return null;
  }

  const submit = (e) => {
    e.preventDefault();
    const validationError = validate();
    if (validationError) {
      setLocalError(validationError.message);
      setInvalidFields(validationError.fields);
      return;
    }
    setLocalError('');
    setInvalidFields([]);
    onSubmit(values);
  };

  return (
    <form className="ui-form" onSubmit={submit} noValidate>
      <div className={`ui-form-grid cols-${columns}`}>
        {(action.params || []).map((p) => (
          <Field
            key={p.name}
            param={p}
            value={values[p.name]}
            values={values}
            initial={initial}
            token={token}
            onPatch={patchFields}
            invalid={invalidFields.includes(p.name)}
            onChange={(v) => setField(p.name, v)}
          />
        ))}
      </div>
      {(localError || error) && <p className="error">{localError || error}</p>}
      <div className="ui-form-actions">
        <Button type="submit" disabled={busy} icon={busy ? <SpinnerIcon size={16} /> : null}>
          {busy ? 'Đang xử lý...' : (submitLabel || action.title)}
        </Button>
      </div>
    </form>
  );
}
