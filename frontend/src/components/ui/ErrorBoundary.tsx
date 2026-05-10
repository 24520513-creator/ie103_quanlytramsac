import { Component, type ReactNode, type ErrorInfo } from 'react';

interface Props { children: ReactNode; fallback?: ReactNode; }
interface State { hasError: boolean; error?: Error; }

export default class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, info);
  }

  render() {
    if ((this as any).state.hasError) {
      if ((this as any).props.fallback) return (this as any).props.fallback;
      return (
        <div className="flex flex-col items-center justify-center py-20 text-slate-500">
          <div className="w-16 h-16 bg-red-50 rounded-2xl flex items-center justify-center mb-4">
            <span className="text-red-500 text-2xl font-bold">!</span>
          </div>
          <p className="text-lg font-medium text-slate-700">Something went wrong</p>
          <p className="text-sm text-slate-400 mb-4">{(this as any).state.error?.message}</p>
          <button onClick={() => (this as any).setState({ hasError: false, error: undefined })}
            className="px-4 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
            Try again
          </button>
        </div>
      );
    }
    return (this as any).props.children;
  }
}
