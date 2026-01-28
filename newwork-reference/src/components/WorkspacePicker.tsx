import { useState, useCallback } from 'react';
import { open } from '@tauri-apps/plugin-dialog';
import styles from './WorkspacePicker.module.css';

interface WorkspacePickerProps {
  onWorkspaceChange?: (path: string | null) => void;
}

export default function WorkspacePicker({ onWorkspaceChange }: WorkspacePickerProps) {
  const [workspacePath, setWorkspacePath] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSelectWorkspace = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const selected = await open({
        directory: true,
        title: 'Select Workspace Folder',
      });

      if (selected && typeof selected === 'string') {
        setWorkspacePath(selected);
        onWorkspaceChange?.(selected);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to select folder';
      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  }, [onWorkspaceChange]);

  const handleChangeWorkspace = useCallback(async () => {
    await handleSelectWorkspace();
  }, [handleSelectWorkspace]);

  const truncatePath = (path: string, maxLength: number = 50): string => {
    if (path.length <= maxLength) return path;
    const start = Math.floor(maxLength / 2);
    const end = path.length - Math.floor(maxLength / 2);
    return `${path.slice(0, start)}...${path.slice(end)}`;
  };

  return (
    <div className={styles.workspacePicker}>
      <div className={styles.header}>
        <h2 className={styles.title}>Workspace</h2>
        {!workspacePath && (
          <p className={styles.subtitle}>Select your project directory to get started</p>
        )}
      </div>

      {!workspacePath ? (
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M3 7v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-6l-2-2H5a2 2 0 0 0-2 2Z" />
              <path d="M12 17l-2.5-2.5" />
              <path d="M12 17l2.5-2.5" />
            </svg>
          </div>
          <p className={styles.emptyMessage}>No workspace selected</p>
          <button
            className={`${styles.button} ${styles.primary}`}
            onClick={handleSelectWorkspace}
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <span className={styles.spinner} />
                Opening...
              </>
            ) : (
              'Select Workspace'
            )}
          </button>
        </div>
      ) : (
        <div className={styles.selectedState}>
          <div className={styles.pathContainer}>
            <div className={styles.pathIcon}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
              </svg>
            </div>
            <div className={styles.pathInfo}>
              <p className={styles.pathLabel}>Current Workspace</p>
              <p className={styles.pathValue} title={workspacePath}>
                {truncatePath(workspacePath)}
              </p>
            </div>
          </div>
          <button
            className={`${styles.button} ${styles.secondary}`}
            onClick={handleChangeWorkspace}
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <span className={styles.spinner} />
                Opening...
              </>
            ) : (
              <>
                Change Workspace
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M21.5 2v6h-6M21.5 8c-1.5-3-5-5-9-5C7 3 3 6.6 2 11.5 1.6 13 1.6 14.5 2 16c1.5 5 6.5 8 11.5 7 4.5-1 8-5 8-9.5" />
                </svg>
              </>
            )}
          </button>
        </div>
      )}

      {error && (
        <div className={styles.error}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10" />
            <path d="m12 8 4 8" />
            <path d="M12 8v8" />
          </svg>
          <span>{error}</span>
        </div>
      )}
    </div>
  );
}
