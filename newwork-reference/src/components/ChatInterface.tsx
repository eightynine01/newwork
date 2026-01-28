import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { Event as OpenCodeEvent } from '@opencode-ai/sdk/v2/client';
import getOpencodeClient from '../lib/opencode/client';
import type { Message } from '../lib/opencode/types';
import { useSSEStream } from '../hooks/useSSEStream';
import styles from './ChatInterface.module.css';

export interface ChatInterfaceProps {
  /** Session ID to fetch messages from and send messages to */
  sessionId: string;

  /** Bump this value to force the client to refresh after reconfigureClient(). */
  clientEpoch?: number;
}

function normalizeEpochMs(value: number | undefined): number {
  if (!value) return Date.now();
  // Heuristic: seconds epoch values are ~10 digits; ms are ~13.
  if (value < 1_000_000_000_000) return value * 1000;
  return value;
}

function formatTimestamp(epochMs: number): string {
  return new Intl.DateTimeFormat(undefined, {
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(epochMs));
}

function formatMessageTime(epochMs: number): string {
  const date = new Date(epochMs);
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();
  const isYesterday = date.toDateString() === new Date(now.setDate(now.getDate() - 1)).toDateString();

  if (isToday) {
    return formatTimestamp(epochMs);
  }

  if (isYesterday) {
    return `Yesterday, ${formatTimestamp(epochMs)}`;
  }

  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

type SdkMessage = {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  time?: {
    created?: number;
  };
};

function friendlyApiError(err: unknown): string {
  if (!err) return 'Request failed.';
  if (typeof err === 'string') return err;
  if (err instanceof Error) return err.message;
  try {
    return JSON.stringify(err);
  } catch {
    return 'Request failed.';
  }
}

function toAppMessage(message: SdkMessage): Message {
  return {
    id: message.id,
    sessionId: '',
    role: message.role,
    content: message.content,
    createdAt: normalizeEpochMs(message.time?.created),
    isStreaming: false,
  };
}

export default function ChatInterface({ sessionId, clientEpoch }: ChatInterfaceProps) {
  const client = useMemo(() => getOpencodeClient(), [clientEpoch]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);
  const refreshTimerRef = useRef<number | null>(null);

  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [streamError, setStreamError] = useState<string | null>(null);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  const fetchMessages = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await client.session.messages({ sessionID: sessionId });

      if (result.error) {
        setError(`Failed to load messages: ${friendlyApiError(result.error)}`);
        setMessages([]);
        return;
      }

      const list = (result.data ?? []) as unknown as Array<SdkMessage>;
      setMessages(list.map(toAppMessage));
    } catch (err) {
      setError(`Failed to load messages: ${friendlyApiError(err)}`);
      setMessages([]);
    } finally {
      setIsLoading(false);
    }
  }, [client, sessionId]);

  useEffect(() => {
    void fetchMessages();
  }, [fetchMessages]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scheduleStreamRefresh = useCallback(() => {
    if (refreshTimerRef.current) {
      window.clearTimeout(refreshTimerRef.current);
    }

    refreshTimerRef.current = window.setTimeout(() => {
      void fetchMessages();
    }, 250);
  }, [fetchMessages]);

  useEffect(() => {
    return () => {
      if (refreshTimerRef.current) {
        window.clearTimeout(refreshTimerRef.current);
      }
    };
  }, []);

  const handleStreamEvent = useCallback(
    (event: OpenCodeEvent) => {
      switch (event.type) {
        case 'message.updated': {
          if (event.properties.info.sessionID === sessionId) {
            scheduleStreamRefresh();
          }
          break;
        }
        case 'message.removed': {
          if (event.properties.sessionID === sessionId) {
            scheduleStreamRefresh();
          }
          break;
        }
        case 'message.part.updated': {
          const part = event.properties.part as unknown as { sessionID?: string };
          if (part.sessionID === sessionId) {
            scheduleStreamRefresh();
          }
          break;
        }
        case 'message.part.removed': {
          if (event.properties.sessionID === sessionId) {
            scheduleStreamRefresh();
          }
          break;
        }
        case 'session.updated': {
          if (event.properties.info.id === sessionId) {
            scheduleStreamRefresh();
          }
          break;
        }
        default:
          break;
      }
    },
    [scheduleStreamRefresh, sessionId]
  );

  const { status: streamStatus } = useSSEStream({
    client,
    enabled: Boolean(sessionId),
    onEvent: handleStreamEvent,
    onError: (err) => setStreamError(err.message),
    autoReconnect: true,
    defaultRetryDelayMs: 500,
    maxRetryDelayMs: 8000,
  });

  useEffect(() => {
    if (streamStatus === 'connected') {
      setStreamError(null);
    }
  }, [streamStatus]);

  const handleSendMessage = useCallback(
    async (content: string) => {
      if (!content.trim() || isSending) return;

      setIsSending(true);
      setError(null);

      const userMessage: Message = {
        id: `temp-${Date.now()}`,
        sessionId,
        role: 'user',
        content: content.trim(),
        createdAt: Date.now(),
        isStreaming: false,
      };

      setMessages((prev) => [...prev, userMessage]);
      setInputValue('');

      try {
        const result = await client.session.prompt({
          sessionID: sessionId,
          parts: [{ type: 'text', text: content.trim() }],
        });

        if (result.error) {
          setError(`Failed to send message: ${friendlyApiError(result.error)}`);
          setMessages((prev) => prev.filter((m) => m.id !== userMessage.id));
          return;
        }

        await fetchMessages();
      } catch (err) {
        setError(`Failed to send message: ${friendlyApiError(err)}`);
        setMessages((prev) => prev.filter((m) => m.id !== userMessage.id));
        setInputValue(content);
      } finally {
        setIsSending(false);
      }
    },
    [client, sessionId, isSending, fetchMessages]
  );

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      if (inputValue.trim()) {
        void handleSendMessage(inputValue);
      }
    },
    [inputValue, handleSendMessage]
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        if (inputValue.trim()) {
          void handleSendMessage(inputValue);
        }
      }
    },
    [inputValue, handleSendMessage]
  );

  const nonSystemMessages = messages.filter((m) => m.role !== 'system');

  const streamIndicatorLabel =
    streamStatus === 'connected'
      ? 'Live'
      : streamStatus === 'connecting'
        ? 'Connecting'
        : streamStatus === 'reconnecting'
          ? 'Reconnecting'
          : 'Offline';

  return (
    <section className={styles.chatInterface}>
      <div className={styles.streamStatus} title={`Live updates: ${streamStatus}`}>
        <span
          className={`${styles.streamDot} ${
            streamStatus === 'connected'
              ? styles.streamDotConnected
              : streamStatus === 'connecting' || streamStatus === 'reconnecting'
                ? styles.streamDotConnecting
                : styles.streamDotDisconnected
          }`}
        />
        <span className={styles.streamLabel}>{streamIndicatorLabel}</span>
      </div>

      <div className={styles.messagesContainer} ref={messagesContainerRef}>
        {isLoading && messages.length === 0 && (
          <div className={styles.loadingState}>
            <span className={styles.spinner} />
            <p className={styles.loadingText}>Loading messages…</p>
          </div>
        )}

        {!isLoading && nonSystemMessages.length === 0 && (
          <div className={styles.emptyState}>
            <div className={styles.emptyIcon}>
              <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M21 15a4 4 0 0 1-4 4H7l-4 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z" />
                <path d="M8 10h8" />
                <path d="M8 14h5" />
              </svg>
            </div>
            <p className={styles.emptyTitle}>No messages yet</p>
            <p className={styles.emptySubtitle}>Start a conversation by sending your first message.</p>
          </div>
        )}

        {nonSystemMessages.map((message) => (
          <div
            key={message.id}
            className={`${styles.message} ${message.role === 'user' ? styles.userMessage : styles.assistantMessage}`}
          >
            <div className={styles.messageHeader}>
              <span className={styles.messageRole}>{message.role === 'user' ? 'You' : 'Assistant'}</span>
              <span className={styles.messageTime}>{formatMessageTime(message.createdAt)}</span>
            </div>
            <div className={styles.messageContent}>{message.content}</div>
          </div>
        ))}

        {isSending && (
          <div className={`${styles.message} ${styles.assistantMessage}`}>
            <div className={styles.messageHeader}>
              <span className={styles.messageRole}>Assistant</span>
            </div>
            <div className={styles.messageContent}>
              <span className={styles.typingIndicator}>
                <span className={styles.typingDot} />
                <span className={styles.typingDot} />
                <span className={styles.typingDot} />
              </span>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <form className={styles.inputForm} onSubmit={handleSubmit}>
        <textarea
          className={styles.messageInput}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Type your message…"
          rows={1}
          disabled={isLoading || isSending}
          aria-label="Message input"
        />
        <button
          type="submit"
          className={`${styles.button} ${styles.sendButton}`}
          disabled={!inputValue.trim() || isLoading || isSending}
          aria-label="Send message"
        >
          {isSending ? (
            <span className={styles.spinner} />
          ) : (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M22 2L11 13" />
              <path d="M22 2L15 22L11 13L2 9L22 2Z" />
            </svg>
          )}
        </button>
      </form>

      {error && (
        <div className={styles.error}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10" />
            <path d="M12 8v5" />
            <path d="M12 16h.01" />
          </svg>
          <span>{error}</span>
        </div>
      )}

      {streamError && (
        <div className={styles.error}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10" />
            <path d="M12 8v5" />
            <path d="M12 16h.01" />
          </svg>
          <span>Live updates: {streamError}</span>
        </div>
      )}
    </section>
  );
}
