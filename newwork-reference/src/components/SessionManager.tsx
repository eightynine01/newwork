import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { Event as OpenCodeEvent } from '@opencode-ai/sdk/v2/client';
import getOpencodeClient from '../lib/opencode/client';
import type { Session as AppSession } from '../lib/opencode/types';
import { useSSEStream } from '../hooks/useSSEStream';
import styles from './SessionManager.module.css';

export interface SessionManagerProps {
  /** Optional workspace directory used by the OpenCode server to scope sessions. */
  directory?: string | null;

  /** Bump this value to force the client to refresh after reconfigureClient(). */
  clientEpoch?: number;
}

type SdkSession = {
  id: string;
  title?: string;
  parentID?: string;
  time?: {
    created?: number;
    updated?: number;
    archived?: number;
  };
};

function normalizeEpochMs(value: number | undefined): number {
  if (!value) return Date.now();
  // Heuristic: seconds epoch values are ~10 digits; ms are ~13.
  if (value < 1_000_000_000_000) return value * 1000;
  return value;
}

function toAppSession(session: SdkSession): AppSession {
  const createdAt = normalizeEpochMs(session.time?.created);
  const updatedAt = normalizeEpochMs(session.time?.updated);
  const archivedAt = session.time?.archived;

  return {
    id: session.id,
    title: session.title?.trim() ? session.title : 'Untitled Session',
    createdAt,
    updatedAt,
    archived: archivedAt ? true : null,
    parentId: session.parentID ?? null,
  };
}

function formatTimestamp(epochMs: number): string {
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(epochMs));
}

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

export default function SessionManager({ directory, clientEpoch }: SessionManagerProps) {
  const client = useMemo(() => {
    return getOpencodeClient();
  }, [clientEpoch]);

  const refreshTimerRef = useRef<number | null>(null);

  const [sessions, setSessions] = useState<AppSession[]>([]);
  const [isListing, setIsListing] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [deletingIds, setDeletingIds] = useState<Set<string>>(() => new Set());
  const [error, setError] = useState<string | null>(null);

  const refreshSessions = useCallback(async () => {
    setIsListing(true);
    setError(null);

    try {
      const result = await client.session.list({
        directory: directory ?? undefined,
      });

      if (result.error) {
        setError(`Failed to load sessions: ${friendlyApiError(result.error)}`);
        setSessions([]);
        return;
      }

      const list = (result.data ?? []) as unknown as Array<SdkSession>;
      setSessions(list.map(toAppSession));
    } catch (err) {
      setError(`Failed to load sessions: ${friendlyApiError(err)}`);
      setSessions([]);
    } finally {
      setIsListing(false);
    }
  }, [client, directory]);

  const scheduleRefresh = useCallback(() => {
    if (refreshTimerRef.current) {
      window.clearTimeout(refreshTimerRef.current);
    }
    refreshTimerRef.current = window.setTimeout(() => {
      void refreshSessions();
    }, 250);
  }, [refreshSessions]);

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
        case 'session.created':
        case 'session.updated':
        case 'session.deleted':
          scheduleRefresh();
          break;
        default:
          break;
      }
    },
    [scheduleRefresh]
  );

  useSSEStream({
    client,
    directory: directory ?? undefined,
    enabled: true,
    onEvent: handleStreamEvent,
    autoReconnect: true,
    defaultRetryDelayMs: 500,
    maxRetryDelayMs: 8000,
  });

  useEffect(() => {
    void refreshSessions();
  }, [refreshSessions]);

  const handleCreate = useCallback(async () => {
    if (isCreating) return;

    const suggested = `Session ${new Intl.DateTimeFormat(undefined, {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
    }).format(new Date())}`;

    const titleInput = window.prompt('New session title', suggested);
    if (titleInput === null) return;
    const title = titleInput.trim();

    setIsCreating(true);
    setError(null);

    try {
      const result = await client.session.create({
        directory: directory ?? undefined,
        title: title.length ? title : undefined,
      });

      if (result.error) {
        setError(`Failed to create session: ${friendlyApiError(result.error)}`);
        return;
      }

      await refreshSessions();
    } catch (err) {
      setError(`Failed to create session: ${friendlyApiError(err)}`);
    } finally {
      setIsCreating(false);
    }
  }, [client, directory, isCreating, refreshSessions]);

  const handleDelete = useCallback(
    async (sessionId: string, title: string) => {
      if (deletingIds.has(sessionId)) return;

      const ok = window.confirm(`Delete "${title}"? This cannot be undone.`);
      if (!ok) return;

      setDeletingIds((prev) => {
        const next = new Set(prev);
        next.add(sessionId);
        return next;
      });
      setError(null);

      try {
        const result = await client.session.delete({
          sessionID: sessionId,
          directory: directory ?? undefined,
        });

        if (result.error) {
          setError(`Failed to delete session: ${friendlyApiError(result.error)}`);
          return;
        }

        await refreshSessions();
      } catch (err) {
        setError(`Failed to delete session: ${friendlyApiError(err)}`);
      } finally {
        setDeletingIds((prev) => {
          const next = new Set(prev);
          next.delete(sessionId);
          return next;
        });
      }
    },
    [client, deletingIds, directory, refreshSessions]
  );

  const showBusy = isListing && sessions.length === 0;

  return (
    <section className={styles.sessionManager}>
      <header className={styles.header}>
        <div className={styles.headerText}>
          <h2 className={styles.title}>Sessions</h2>
          <p className={styles.subtitle}>Create, review, and clean up your OpenCode sessions</p>
        </div>

        <div className={styles.headerActions}>
          <button
            className={`${styles.button} ${styles.secondary}`}
            onClick={() => void refreshSessions()}
            disabled={isListing || isCreating}
            title="Refresh"
          >
            {isListing ? (
              <>
                <span className={styles.spinner} />
                Refreshing
              </>
            ) : (
              'Refresh'
            )}
          </button>

          <button
            className={`${styles.button} ${styles.primary}`}
            onClick={() => void handleCreate()}
            disabled={isCreating || isListing}
          >
            {isCreating ? (
              <>
                <span className={styles.spinner} />
                Creating
              </>
            ) : (
              'Create New Session'
            )}
          </button>
        </div>
      </header>

      {showBusy && (
        <div className={styles.loadingState}>
          <span className={styles.bigSpinner} />
          <p className={styles.loadingText}>Loading sessions…</p>
        </div>
      )}

      {!showBusy && sessions.length === 0 && (
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>
            <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M21 15a4 4 0 0 1-4 4H7l-4 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z" />
              <path d="M8 10h8" />
              <path d="M8 14h5" />
            </svg>
          </div>
          <p className={styles.emptyTitle}>No sessions yet</p>
          <p className={styles.emptySubtitle}>Create your first OpenCode session to start working.</p>

          <button
            className={`${styles.button} ${styles.primary}`}
            onClick={() => void handleCreate()}
            disabled={isCreating || isListing}
          >
            {isCreating ? (
              <>
                <span className={styles.spinner} />
                Creating
              </>
            ) : (
              'Create New Session'
            )}
          </button>
        </div>
      )}

      {!showBusy && sessions.length > 0 && (
        <div className={styles.sessionGrid}>
          {sessions.map((session) => {
            const isDeleting = deletingIds.has(session.id);

            return (
              <article key={session.id} className={styles.sessionCard}>
                <div className={styles.cardTop}>
                  <div className={styles.cardTitleRow}>
                    <h3 className={styles.sessionTitle} title={session.title}>
                      {session.title}
                    </h3>
                    {session.archived ? <span className={styles.archived}>Archived</span> : null}
                  </div>
                  <p className={styles.sessionId} title={session.id}>
                    {session.id}
                  </p>
                </div>

                <div className={styles.metaGrid}>
                  <div className={styles.metaItem}>
                    <span className={styles.metaLabel}>Created</span>
                    <span className={styles.metaValue}>{formatTimestamp(session.createdAt)}</span>
                  </div>
                  <div className={styles.metaItem}>
                    <span className={styles.metaLabel}>Updated</span>
                    <span className={styles.metaValue}>{formatTimestamp(session.updatedAt)}</span>
                  </div>
                </div>

                <div className={styles.cardActions}>
                  <button
                    className={`${styles.button} ${styles.danger}`}
                    onClick={() => void handleDelete(session.id, session.title)}
                    disabled={isDeleting || isListing || isCreating}
                  >
                    {isDeleting ? (
                      <>
                        <span className={styles.spinner} />
                        Deleting
                      </>
                    ) : (
                      'Delete'
                    )}
                  </button>
                </div>
              </article>
            );
          })}
        </div>
      )}

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
    </section>
  );
}
