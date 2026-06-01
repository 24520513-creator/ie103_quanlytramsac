import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchLookup, runAction } from './api';

/**
 * Fetch a query/view action and keep its normalized result.
 * Returns { data, rows, loading, error, reload }.
 */
export function useActionData(actionId, { token, body = {}, auto = true } = {}) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(Boolean(auto));
  const [error, setError] = useState('');
  const bodyRef = useRef(body);
  const bodyKey = JSON.stringify(body);
  bodyRef.current = body;

  const reload = useCallback(async (override = {}) => {
    setLoading(true);
    setError('');
    try {
      const json = await runAction(actionId, { ...bodyRef.current, ...override }, token);
      setData(json);
      return json;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [actionId, token]);

  useEffect(() => {
    if (auto) reload().catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [actionId, auto, bodyKey]);

  return { data, rows: data?.rows || [], summary: data?.summary || {}, loading, error, reload };
}

/** Imperatively run a write action (procedure). Returns { run, busy, error }. */
export function useActionRunner(token) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const run = useCallback(async (actionId, body = {}) => {
    setBusy(true);
    setError('');
    try {
      return await runAction(actionId, body, token);
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setBusy(false);
    }
  }, [token]);

  return { run, busy, error, setError };
}

export function useLookupOptions(key, { token, body = {}, auto = true } = {}) {
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(Boolean(auto && key));
  const [error, setError] = useState('');
  const bodyRef = useRef(body);
  bodyRef.current = body;

  const reload = useCallback(async (override = {}) => {
    if (!key) return { options: [] };
    setLoading(true);
    setError('');
    try {
      const json = await fetchLookup(key, { ...bodyRef.current, ...override }, token);
      setOptions(json.options || []);
      return json;
    } catch (err) {
      setError(err.message);
      setOptions([]);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [key, token]);

  useEffect(() => {
    if (auto && key) reload().catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, auto]);

  return { options, loading, error, reload };
}
