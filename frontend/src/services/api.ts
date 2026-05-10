const API_BASE = 'http://localhost:3000/api';

interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data: T;
}

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

async function request<T = any>(
  method: string,
  path: string,
  body?: any
): Promise<ApiResponse<T>> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    localStorage.clear();
    window.location.href = '/';
    throw new ApiError(401, 'Unauthorized');
  }

  const data = await res.json();
  if (!res.ok) {
    throw new ApiError(res.status, data?.message || 'Request failed');
  }
  return data;
}

export const api = {
  get: <T = any>(path: string) => request<T>('GET', path),
  post: <T = any>(path: string, body?: any) => request<T>('POST', path, body),
  put: <T = any>(path: string, body?: any) => request<T>('PUT', path, body),
  delete: <T = any>(path: string) => request<T>('DELETE', path),
};

export type { ApiResponse, ApiError };
