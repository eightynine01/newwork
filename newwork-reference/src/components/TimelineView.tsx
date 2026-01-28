import { useEffect, useState } from 'react';
import type { OpencodeClient } from '@opencode-ai/sdk/v2/client';
import type { Todo } from '../lib/opencode/types';
import { useSSEStream } from '../hooks/useSSEStream';
import styles from './TimelineView.module.css';

export interface TimelineViewProps {
  sessionId: string;
  client: OpencodeClient;
  directory?: string;
}

export function TimelineView({ sessionId, client, directory }: TimelineViewProps) {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchTodos = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const response = await client.session.todo({
        sessionID: sessionId,
        directory,
      });

      if (response.data) {
        setTodos(response.data);
      } else {
        setTodos([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch todos'));
      setTodos([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    void fetchTodos();
  }, [sessionId]);

  const { status: sseStatus } = useSSEStream({
    client,
    directory,
    enabled: true,
    onTodoUpdated: () => {
      void fetchTodos();
    },
  });

  const formatTimestamp = (timestamp: number | undefined): string => {
    if (!timestamp) {
      return '';
    }

    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) {
      return 'just now';
    }

    if (diff < 3600000) {
      const minutes = Math.floor(diff / 60000);
      return `${minutes}m ago`;
    }

    if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000);
      return `${hours}h ago`;
    }

    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusColor = (status: string): string => {
    switch (status) {
      case 'pending':
        return '#f59e0b';
      case 'in_progress':
        return '#3b82f6';
      case 'completed':
        return '#22c55e';
      case 'cancelled':
        return '#ef4444';
      default:
        return '#9ca3af';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
            <circle cx="12" cy="12" r="10" />
            <circle cx="12" cy="12" r="6" fill="currentColor" />
          </svg>
        );
      case 'in_progress':
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
            <circle cx="12" cy="12" r="10" opacity={0.4} fill="currentColor" />
            <circle cx="12" cy="12" r="6" opacity={0.6} fill="currentColor" />
            <circle cx="12" cy="12" r="2" fill="currentColor" />
          </svg>
        );
      case 'completed':
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5}>
            <circle cx="12" cy="12" r="10" />
            <path d="M8 12 L11 15 L16 9" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        );
      case 'cancelled':
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5}>
            <circle cx="12" cy="12" r="10" />
            <path d="M9 9 L15 15 M15 9 L9 15" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        );
      default:
        return (
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
            <circle cx="12" cy="12" r="10" />
          </svg>
        );
    }
  };

  const getPriorityColor = (priority: string): string => {
    switch (priority) {
      case 'high':
        return 'rgba(239, 68, 68, 0.12)';
      case 'medium':
        return 'rgba(249, 115, 22, 0.12)';
      case 'low':
        return 'rgba(156, 163, 175, 0.12)';
      default:
        return 'rgba(156, 163, 175, 0.12)';
    }
  };

  const getPriorityTextColor = (priority: string): string => {
    switch (priority) {
      case 'high':
        return '#dc2626';
      case 'medium':
        return '#ea580c';
      case 'low':
        return '#6b7280';
      default:
        return '#6b7280';
    }
  };

  if (isLoading && todos.length === 0) {
    return (
      <div className={styles.timelineView}>
        <div className={styles.loadingState}>
          <div className={styles.spinner} />
          <p className={styles.loadingText}>Loading execution plan...</p>
        </div>
      </div>
    );
  }

  if (error && todos.length === 0) {
    return (
      <div className={styles.timelineView}>
        <div className={styles.error}>
          <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
            <circle cx="12" cy="12" r="10" />
            <path d="M12 8 L12 12 M12 16 L12 16.01" strokeLinecap="round" />
          </svg>
          <span>{error.message}</span>
        </div>
      </div>
    );
  }

  if (!isLoading && todos.length === 0) {
    return (
      <div className={styles.timelineView}>
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>
            <svg width={40} height={40} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5}>
              <path d="M9 11 L3 17 L9 23" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M3 17 L21 17" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M15 13 L21 7 L15 1" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M21 7 L3 7" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <h3 className={styles.emptyTitle}>No execution plan yet</h3>
          <p className={styles.emptySubtitle}>
            OpenCode will create a timeline of tasks as it works on this session.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.timelineView}>
      {sseStatus === 'connected' && (
        <div className={styles.streamStatus}>
          <div className={`${styles.streamDot} ${styles.streamDotConnected}`} />
          <span className={styles.streamLabel}>Live</span>
        </div>
      )}

      <div className={styles.timeline}>
        {todos.map((todo, index) => (
          <div key={todo.id} className={styles.timelineItem}>
            <div className={styles.timelineIndicator}>
              <div
                className={styles.statusDot}
                style={{ color: getStatusColor(todo.status) }}
              >
                {getStatusIcon(todo.status)}
              </div>
              {index < todos.length - 1 && (
                <div
                  className={styles.timelineConnector}
                  style={{
                    background: `linear-gradient(to bottom, ${getStatusColor(todo.status)}40, transparent)`,
                  }}
                />
              )}
            </div>
            <div className={styles.timelineContent}>
              <div className={styles.timelineHeader}>
                <span
                  className={styles.priorityBadge}
                  style={{
                    background: getPriorityColor(todo.priority),
                    color: getPriorityTextColor(todo.priority),
                  }}
                >
                  {todo.priority.toUpperCase()}
                </span>
                <span className={styles.timestamp}>{formatTimestamp(todo.createdAt)}</span>
              </div>
              <p className={styles.todoContent}>{todo.content}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
