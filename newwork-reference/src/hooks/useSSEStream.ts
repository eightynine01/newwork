import { useCallback, useEffect, useRef, useState } from 'react';
import type {
  Event as OpenCodeEvent,
  EventFileEdited,
  EventMessageUpdated,
  EventPermissionAsked,
  EventPermissionReplied,
  EventSessionUpdated,
  EventTodoUpdated,
  OpencodeClient,
} from '@opencode-ai/sdk/v2/client';

export type SSEStreamStatus = 'idle' | 'connecting' | 'connected' | 'reconnecting' | 'disconnected' | 'error';

export interface UseSSEStreamOptions {
  client: OpencodeClient;
  directory?: string;
  enabled?: boolean;
  onEvent?: (event: OpenCodeEvent) => void;
  onMessageUpdated?: (event: EventMessageUpdated) => void;
  onTodoUpdated?: (event: EventTodoUpdated) => void;
  onPermissionAsked?: (event: EventPermissionAsked) => void;
  onPermissionReplied?: (event: EventPermissionReplied) => void;
  onSessionUpdated?: (event: EventSessionUpdated) => void;
  onFileEdited?: (event: EventFileEdited) => void;
  onError?: (error: Error) => void;
  autoReconnect?: boolean;
  defaultRetryDelayMs?: number;
  maxRetryDelayMs?: number;
  maxRetryAttempts?: number;
}

type SdkSseResult<T> = {
  stream: AsyncGenerator<T, void, unknown>;
};

async function subscribeToOpenCodeEvents(params: {
  client: OpencodeClient;
  directory?: string;
  signal: AbortSignal;
  onSseError: (err: unknown) => void;
  defaultRetryDelayMs: number;
  maxRetryDelayMs: number;
  maxRetryAttempts?: number;
}): Promise<SdkSseResult<OpenCodeEvent>> {
  const { client, directory, signal, onSseError, defaultRetryDelayMs, maxRetryDelayMs, maxRetryAttempts } = params;

  // SDK v2 currently exposes `client.event.subscribe()`. Some docs/examples
  // reference `client.event.list()`, so we support both at runtime.
  const eventClient = (client as unknown as { event?: Record<string, unknown> }).event as
    | {
        list?: (...args: Array<unknown>) => Promise<SdkSseResult<OpenCodeEvent>>;
        subscribe?: (...args: Array<unknown>) => Promise<SdkSseResult<OpenCodeEvent>>;
      }
    | undefined;

  const globalClient = client as unknown as {
    global?: {
      event?: (...args: Array<unknown>) => Promise<SdkSseResult<unknown>>;
    };
  };

  const options = {
    signal,
    onSseError,
    sseDefaultRetryDelay: defaultRetryDelayMs,
    sseMaxRetryDelay: maxRetryDelayMs,
    sseMaxRetryAttempts: maxRetryAttempts,
  };

  if (eventClient?.list) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return (await eventClient.list(directory ? { directory } : undefined, options)) as SdkSseResult<OpenCodeEvent>;
  }

  if (eventClient?.subscribe) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return (await eventClient.subscribe(directory ? { directory } : undefined, options)) as SdkSseResult<OpenCodeEvent>;
  }

  // Fallback: some SDK variants use `client.global.event()`.
  if (globalClient.global?.event) {
    const result = (await globalClient.global.event(undefined, options)) as SdkSseResult<{ payload: OpenCodeEvent }>;
    async function* unwrap() {
      for await (const item of result.stream) {
        yield item.payload;
      }
    }
    return { stream: unwrap() };
  }

  throw new Error('OpenCode SDK does not expose an SSE event API on this client.');
}

export function useSSEStream(options: UseSSEStreamOptions) {
  const {
    client,
    directory,
    enabled = true,
    onEvent,
    onMessageUpdated,
    onTodoUpdated,
    onPermissionAsked,
    onPermissionReplied,
    onSessionUpdated,
    onFileEdited,
    onError,
    autoReconnect = true,
    defaultRetryDelayMs = 500,
    maxRetryDelayMs = 30_000,
    maxRetryAttempts,
  } = options;

  const [status, setStatus] = useState<SSEStreamStatus>('idle');
  const [error, setError] = useState<Error | null>(null);
  const [lastEvent, setLastEvent] = useState<OpenCodeEvent | null>(null);
  const [restartNonce, setRestartNonce] = useState(0);

  const abortRef = useRef<AbortController | null>(null);
  const hasConnectedRef = useRef(false);

  const callbacksRef = useRef({
    onEvent,
    onMessageUpdated,
    onTodoUpdated,
    onPermissionAsked,
    onPermissionReplied,
    onSessionUpdated,
    onFileEdited,
    onError,
  });
  useEffect(() => {
    callbacksRef.current = {
      onEvent,
      onMessageUpdated,
      onTodoUpdated,
      onPermissionAsked,
      onPermissionReplied,
      onSessionUpdated,
      onFileEdited,
      onError,
    };
  }, [onEvent, onMessageUpdated, onTodoUpdated, onPermissionAsked, onPermissionReplied, onSessionUpdated, onFileEdited, onError]);

  const disconnect = useCallback(() => {
    abortRef.current?.abort();
    abortRef.current = null;
    hasConnectedRef.current = false;
    setStatus('disconnected');
  }, []);

  const reconnect = useCallback(() => {
    disconnect();
    setRestartNonce((prev) => prev + 1);
  }, [disconnect]);

  useEffect(() => {
    if (!enabled) {
      disconnect();
      return;
    }

    const controller = new AbortController();
    abortRef.current = controller;
    hasConnectedRef.current = false;
    setError(null);
    setLastEvent(null);
    setStatus((prev) => (prev === 'connected' ? 'reconnecting' : 'connecting'));

    const assumeConnectedTimer = window.setTimeout(() => {
      if (controller.signal.aborted) return;
      // Some servers are quiet until something happens; consider the stream
      // "connected" once we've managed to start it without immediate errors.
      setStatus((prev) => (prev === 'connecting' ? 'connected' : prev));
    }, 1200);

    const onSseError = (err: unknown) => {
      if (controller.signal.aborted) return;

      const nextError = err instanceof Error ? err : new Error(typeof err === 'string' ? err : 'SSE stream error');
      setError(nextError);

      if (autoReconnect) {
        setStatus((prev) => (prev === 'connected' || prev === 'connecting' ? 'reconnecting' : prev));
      } else {
        setStatus('error');
      }

      callbacksRef.current.onError?.(nextError);
    };

    const run = async () => {
      try {
        const result = await subscribeToOpenCodeEvents({
          client,
          directory,
          signal: controller.signal,
          onSseError,
          defaultRetryDelayMs,
          maxRetryDelayMs,
          maxRetryAttempts: autoReconnect ? maxRetryAttempts : 0,
        });

        for await (const event of result.stream) {
          if (controller.signal.aborted) return;
          if (!hasConnectedRef.current) {
            hasConnectedRef.current = true;
            setStatus('connected');
            setError(null);
          }
          setLastEvent(event);

          const callbacks = callbacksRef.current;
          switch (event.type) {
            case 'message.updated':
              callbacks.onMessageUpdated?.(event);
              break;
            case 'todo.updated':
              callbacks.onTodoUpdated?.(event);
              break;
            case 'permission.asked':
              callbacks.onPermissionAsked?.(event);
              break;
            case 'permission.replied':
              callbacks.onPermissionReplied?.(event);
              break;
            case 'session.updated':
              callbacks.onSessionUpdated?.(event);
              break;
            case 'file.edited':
              callbacks.onFileEdited?.(event);
              break;
            default:
              break;
          }

          callbacks.onEvent?.(event);
        }

        if (!controller.signal.aborted) {
          setStatus('disconnected');
        }
      } catch (err) {
        onSseError(err);
      }
    };

    void run();

    return () => {
      window.clearTimeout(assumeConnectedTimer);
      controller.abort();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, client, directory, defaultRetryDelayMs, maxRetryDelayMs, maxRetryAttempts, autoReconnect, restartNonce]);

  return {
    status,
    error,
    lastEvent,
    disconnect,
    reconnect,
  };
}
