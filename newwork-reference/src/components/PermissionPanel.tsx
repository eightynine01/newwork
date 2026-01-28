import { useCallback, useMemo, useState } from 'react';
import type { EventPermissionAsked, EventPermissionReplied, OpencodeClient } from '@opencode-ai/sdk/v2/client';
import getOpencodeClient from '../lib/opencode/client';
import { useSSEStream } from '../hooks/useSSEStream';
import styles from './PermissionPanel.module.css';

export interface PermissionPanelProps {
  /** Optional directory path for the workspace */
  directory?: string;

  /** Optional custom OpenCode client instance */
  client?: OpencodeClient;
}

/**
 * Permission Panel Component
 *
 * Displays pending permission requests from OpenCode and allows users to
 * approve or deny them with options for "Allow Once" or "Always Allow".
 */
export default function PermissionPanel({ directory, client: customClient }: PermissionPanelProps) {
  const client = useMemo(() => customClient || getOpencodeClient(), [customClient]);

  const [pendingPermissions, setPendingPermissions] = useState<PermissionRequestWithId[]>([]);
  const [handlingPermissionId, setHandlingPermissionId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handlePermissionAsked = useCallback((event: EventPermissionAsked) => {
    const request: PermissionRequestWithId = event.properties as PermissionRequestWithId;
    setPendingPermissions((prev) => [...prev, request]);
    setError(null);
  }, []);

  const handlePermissionReplied = useCallback((event: EventPermissionReplied) => {
    setPendingPermissions((prev) => prev.filter((p) => p.id !== event.properties.requestID));
  }, []);

  useSSEStream({
    client,
    directory,
    onPermissionAsked: handlePermissionAsked,
    onPermissionReplied: handlePermissionReplied,
    enabled: true,
    autoReconnect: true,
    defaultRetryDelayMs: 500,
    maxRetryDelayMs: 8000,
  });

  const handlePermissionResponse = useCallback(
    async (permissionId: string, response: 'once' | 'always' | 'reject') => {
      if (handlingPermissionId) return;

      setHandlingPermissionId(permissionId);
      setError(null);

      try {
        const result = await client.permission.reply({
          requestID: permissionId,
          directory,
          reply: response,
        });

        if (result.error) {
          setError(`Failed to ${response === 'reject' ? 'deny' : 'allow'} permission: ${JSON.stringify(result.error)}`);
          setHandlingPermissionId(null);
        } else {
          setPendingPermissions((prev) => prev.filter((p) => p.id !== permissionId));
          setHandlingPermissionId(null);
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred';
        setError(`Failed to ${response === 'reject' ? 'deny' : 'allow'} permission: ${errorMessage}`);
        setHandlingPermissionId(null);
      }
    },
    [client, directory, handlingPermissionId]
  );

  const getPermissionDescription = useCallback((permission: PermissionRequestWithId): string => {
    const { permission: permissionType, patterns } = permission;

    if (permissionType.includes('bash') || permissionType.includes('execute')) {
      return `Execute command: ${patterns[0] || 'shell command'}`;
    }

    if (permissionType.includes('file') || permissionType.includes('write')) {
      return `Write to file: ${patterns[0] || 'file'}`;
    }

    if (permissionType.includes('read')) {
      return `Read file: ${patterns[0] || 'file'}`;
    }

    if (permissionType.includes('network') || permissionType.includes('http') || permissionType.includes('fetch')) {
      return `Network request: ${patterns[0] || 'external API'}`;
    }

    if (patterns.length > 0) {
      return `${permissionType}: ${patterns[0]}`;
    }

    return permissionType;
  }, []);

  const getRiskLevel = useCallback((permission: PermissionRequestWithId): 'low' | 'medium' | 'high' => {
    const { permission: permissionType, patterns } = permission;

    if (permissionType.includes('bash') || permissionType.includes('execute')) {
      return 'high';
    }

    if (permissionType.includes('network') || permissionType.includes('http')) {
      return 'medium';
    }

    const dangerousPatterns = ['rm ', 'delete', 'format', 'sudo', 'eval', 'exec'];
    if (patterns.some((p) => dangerousPatterns.some((dp) => p.toLowerCase().includes(dp)))) {
      return 'high';
    }

    if (permissionType.includes('write')) {
      return 'medium';
    }

    return 'low';
  }, []);

  return (
    <section className={styles.permissionPanel}>
      <div className={styles.header}>
        <div className={styles.headerContent}>
          <div className={styles.icon}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
            </svg>
          </div>
          <h2 className={styles.title}>Permissions</h2>
        </div>
        <div className={styles.badge}>{pendingPermissions.length} pending</div>
      </div>

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

      <div className={styles.permissionsList}>
        {pendingPermissions.length === 0 ? (
          <div className={styles.emptyState}>
            <div className={styles.emptyIcon}>
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                <path d="M9 12l2 2 4-4" />
              </svg>
            </div>
            <p className={styles.emptyTitle}>No pending permissions</p>
            <p className={styles.emptySubtitle}>All permission requests have been handled</p>
          </div>
        ) : (
          pendingPermissions.map((permission) => {
            const riskLevel = getRiskLevel(permission);
            const isHandling = handlingPermissionId === permission.id;

            return (
              <div key={permission.id} className={styles.permissionCard}>
                <div className={styles.permissionHeader}>
                  <div className={`${styles.riskBadge} ${styles[riskLevel]}`}>
                    {riskLevel === 'high' && (
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                        <path d="M12 9v4" />
                        <path d="M12 17h.01" />
                      </svg>
                    )}
                    {riskLevel}
                  </div>
                  <span className={styles.permissionId}>#{permission.id.slice(-8)}</span>
                </div>

                <div className={styles.permissionBody}>
                  <p className={styles.permissionDescription}>{getPermissionDescription(permission)}</p>

                  {permission.patterns.length > 1 && (
                    <details className={styles.patterns}>
                      <summary className={styles.patternsSummary}>
                        {permission.patterns.length} {permission.patterns.length === 1 ? 'pattern' : 'patterns'}
                      </summary>
                      <ul className={styles.patternsList}>
                        {permission.patterns.map((pattern, idx) => (
                          <li key={idx} className={styles.patternItem}>
                            <code>{pattern}</code>
                          </li>
                        ))}
                      </ul>
                    </details>
                  )}

                  {permission.tool && (
                    <div className={styles.toolInfo}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z" />
                      </svg>
                      <span>Tool: {permission.tool.callID}</span>
                    </div>
                  )}
                </div>

                <div className={styles.permissionActions}>
                  <button
                    type="button"
                    className={`${styles.button} ${styles.denyButton}`}
                    onClick={() => handlePermissionResponse(permission.id, 'reject')}
                    disabled={isHandling}
                    aria-label="Deny permission"
                  >
                    {isHandling ? (
                      <span className={styles.spinner} />
                    ) : (
                      <>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M18 6L6 18" />
                          <path d="M6 6l12 12" />
                        </svg>
                        <span>Deny</span>
                      </>
                    )}
                  </button>

                  <div className={styles.allowButtons}>
                    <button
                      type="button"
                      className={`${styles.button} ${styles.allowOnceButton}`}
                      onClick={() => handlePermissionResponse(permission.id, 'once')}
                      disabled={isHandling}
                      aria-label="Allow permission once"
                    >
                      {isHandling ? (
                        <span className={styles.spinner} />
                      ) : (
                        <>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <polyline points="20 6 9 17 4 12" />
                          </svg>
                          <span>Allow Once</span>
                        </>
                      )}
                    </button>

                    <button
                      type="button"
                      className={`${styles.button} ${styles.allowAlwaysButton}`}
                      onClick={() => handlePermissionResponse(permission.id, 'always')}
                      disabled={isHandling}
                      aria-label="Always allow permission"
                    >
                      {isHandling ? (
                        <span className={styles.spinner} />
                      ) : (
                        <>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                          </svg>
                          <span>Always Allow</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </section>
  );
}

interface PermissionRequestWithId {
  id: string;
  sessionID: string;
  permission: string;
  patterns: string[];
  metadata: {
    [key: string]: unknown;
  };
  always: string[];
  tool?: {
    messageID: string;
    callID: string;
  };
}
