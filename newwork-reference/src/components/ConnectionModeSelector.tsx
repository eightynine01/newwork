import { useEffect, useMemo, useState } from 'react';
import { isValidServerUrl, normalizeServerUrl } from '../lib/opencode/utils';
import styles from './ConnectionModeSelector.module.css';

export type ConnectionMode = 'host' | 'client';
export type ConnectionStatus = 'connected' | 'disconnected' | 'checking' | 'error';

export interface ConnectionModeSelectorProps {
  mode: ConnectionMode;
  onModeChange: (mode: ConnectionMode) => void;

  /** Currently applied base URL for Client mode. */
  serverUrl: string;
  onServerUrlChange: (url: string) => void;

  status: ConnectionStatus;
  statusMessage?: string | null;
}

function statusLabel(status: ConnectionStatus): string {
  switch (status) {
    case 'connected':
      return 'Connected';
    case 'checking':
      return 'Checking';
    case 'error':
      return 'Error';
    default:
      return 'Disconnected';
  }
}

export default function ConnectionModeSelector(props: ConnectionModeSelectorProps) {
  const { mode, onModeChange, serverUrl, onServerUrlChange, status, statusMessage } = props;

  const [draftUrl, setDraftUrl] = useState(serverUrl);
  const [touched, setTouched] = useState(false);

  useEffect(() => {
    setDraftUrl(serverUrl);
    setTouched(false);
  }, [serverUrl, mode]);

  const normalizedDraft = useMemo(() => {
    try {
      return normalizeServerUrl(draftUrl.trim());
    } catch {
      return draftUrl.trim();
    }
  }, [draftUrl]);

  const urlIsValid = useMemo(() => {
    if (!draftUrl.trim()) return false;
    return isValidServerUrl(normalizedDraft);
  }, [draftUrl, normalizedDraft]);

  const canApply = mode === 'client' && urlIsValid;

  const handleApply = () => {
    if (!canApply) return;
    onServerUrlChange(normalizedDraft);
  };

  const dotClass =
    status === 'connected'
      ? styles.statusDotConnected
      : status === 'checking'
        ? styles.statusDotChecking
        : status === 'error'
          ? styles.statusDotError
          : styles.statusDotDisconnected;

  return (
    <section className={styles.panel} aria-label="Connection mode">
      <div className={styles.header}>
        <div className={styles.headerText}>
          <h2 className={styles.title}>Connection</h2>
          <p className={styles.subtitle}>Choose local workspace hosting or connect to a remote server.</p>
        </div>

        <div className={styles.status} title={statusMessage ?? undefined}>
          <span className={`${styles.statusDot} ${dotClass}`} />
          <span className={styles.statusLabel}>{statusLabel(status)}</span>
        </div>
      </div>

      <div className={styles.modeToggle} role="tablist" aria-label="Connection mode">
        <button
          type="button"
          className={`${styles.modeButton} ${mode === 'host' ? styles.modeButtonActive : ''}`}
          onClick={() => onModeChange('host')}
          role="tab"
          aria-selected={mode === 'host'}
        >
          Host Mode (Local)
        </button>
        <button
          type="button"
          className={`${styles.modeButton} ${mode === 'client' ? styles.modeButtonActive : ''}`}
          onClick={() => onModeChange('client')}
          role="tab"
          aria-selected={mode === 'client'}
        >
          Client Mode (Remote)
        </button>
      </div>

      {mode === 'client' ? (
        <div className={styles.clientConfig}>
          <label className={styles.label} htmlFor="server-url">
            OpenCode Server URL
          </label>
          <div className={styles.urlRow}>
            <input
              id="server-url"
              className={styles.input}
              value={draftUrl}
              onChange={(e) => {
                setDraftUrl(e.target.value);
                setTouched(true);
              }}
              placeholder="http://localhost:11434"
              inputMode="url"
              spellCheck={false}
              autoCapitalize="none"
              autoCorrect="off"
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  handleApply();
                }
              }}
            />
            <button
              type="button"
              className={`${styles.button} ${styles.primary}`}
              onClick={handleApply}
              disabled={!canApply}
            >
              Connect
            </button>
          </div>
          <p className={styles.hint}>
            {touched && !draftUrl.trim()
              ? 'Enter a server URL to connect.'
              : touched && !urlIsValid
                ? 'URL must start with http:// or https://'
                : `Applied: ${serverUrl}`}
          </p>
          {statusMessage ? <p className={styles.statusMessage}>{statusMessage}</p> : null}
        </div>
      ) : (
        <div className={styles.hostHint}>
          <div className={styles.hostHintRow}>
            <span className={styles.hostBadge}>Local</span>
            <span className={styles.hostHintText}>
              OpenWork will target your local OpenCode server (default URL) and scope sessions to the selected workspace.
            </span>
          </div>
          {statusMessage ? <p className={styles.statusMessage}>{statusMessage}</p> : null}
        </div>
      )}
    </section>
  );
}
