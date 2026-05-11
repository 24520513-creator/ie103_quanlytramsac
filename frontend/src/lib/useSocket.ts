import { useEffect, useCallback, useRef } from 'react';
import { getSocket } from '../services/socket';

type EventHandler = (...args: any[]) => void;

export function useSocketEvent(event: string, handler: EventHandler) {
  const handlerRef = useRef<EventHandler>(handler);
  handlerRef.current = handler;

  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const wrapper = (...args: any[]) => handlerRef.current(...args);
    socket.on(event, wrapper);
    return () => { socket.off(event, wrapper); };
  }, [event]);
}

export function useSocket() {
  const emit = useCallback((event: string, data?: any) => {
    getSocket()?.emit(event, data);
  }, []);

  return { emit };
}
