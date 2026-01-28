import { useCallback, useEffect, useMemo, useState } from 'react';
import ConnectionModeSelector, {
  type ConnectionMode,
  type ConnectionStatus,
} from './components/ConnectionModeSelector';
import WorkspacePicker from "./components/WorkspacePicker";
import SessionManager from './components/SessionManager';
import "./App.css";
import getOpencodeClient, { reconfigureClient } from './lib/opencode/client';
import {
  formatErrorForDisplay,
  getDefaultServerUrl,
  isValidServerUrl,
  normalizeServerUrl,
} from './lib/opencode/utils';

const STORAGE_CONNECTION_MODE_KEY = 'openwork.connectionMode';
const STORAGE_REMOTE_URL_KEY = 'openwork.remoteServerUrl';

function readStorage(key: string): string | null {
  try {
    if (typeof window === 'undefined') return null;
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}

function writeStorage(key: string, value: string) {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    // ignore
  }
}

function normalizeIfPossible(url: string): string {
  try {
    return normalizeServerUrl(url);
  } catch {
    return url;
  }
}

async function checkHealth(): Promise<{ ok: boolean; message?: string }> {
  const client = getOpencodeClient();
  const result = await client.global.health();
  if (result.error) {
    return { ok: false, message: formatErrorForDisplay(result.error) };
  }
  const version = (result.data as unknown as { version?: string } | undefined)?.version;
  return { ok: true, message: version ? `Server OK (v${version})` : 'Server OK' };
}

function App() {
  const [workspacePath, setWorkspacePath] = useState<string | null>(null);
  const [clientEpoch, setClientEpoch] = useState(0);

  const initialMode = useMemo<ConnectionMode>(() => {
    const stored = readStorage(STORAGE_CONNECTION_MODE_KEY);
    return stored === 'client' ? 'client' : 'host';
  }, []);

  const initialRemoteUrl = useMemo(() => {
    return normalizeIfPossible(readStorage(STORAGE_REMOTE_URL_KEY) ?? getDefaultServerUrl());
  }, []);

  const [connectionMode, setConnectionMode] = useState<ConnectionMode>(initialMode);
  const [remoteServerUrl, setRemoteServerUrl] = useState<string>(initialRemoteUrl);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('checking');
  const [connectionMessage, setConnectionMessage] = useState<string | null>(null);

  const bumpClientEpoch = useCallback(() => {
    setClientEpoch((prev) => prev + 1);
  }, []);

  const refreshConnection = useCallback(async () => {
    setConnectionStatus('checking');
    setConnectionMessage(null);

    try {
      const health = await checkHealth();
      setConnectionStatus(health.ok ? 'connected' : 'disconnected');
      setConnectionMessage(health.message ?? null);
    } catch (err) {
      setConnectionStatus('error');
      setConnectionMessage(formatErrorForDisplay(err));
    }
  }, []);

  const applyHostConfig = useCallback(
    async (directory: string | null) => {
      reconfigureClient({ directory: directory ?? undefined });
      bumpClientEpoch();
      await refreshConnection();
    },
    [bumpClientEpoch, refreshConnection]
  );

  const applyClientConfig = useCallback(
    async (baseUrl: string) => {
      const normalized = normalizeIfPossible(baseUrl);
      if (!isValidServerUrl(normalized)) {
        setConnectionStatus('error');
        setConnectionMessage('Invalid server URL. Use http:// or https://');
        return;
      }

      reconfigureClient({ baseUrl: normalized });
      bumpClientEpoch();
      await refreshConnection();
    },
    [bumpClientEpoch, refreshConnection]
  );

  const handleWorkspaceChange = useCallback(
    async (path: string | null) => {
      setWorkspacePath(path);
      if (connectionMode === 'host') {
        await applyHostConfig(path);
      }
    },
    [applyHostConfig, connectionMode]
  );

  const handleModeChange = useCallback(
    async (mode: ConnectionMode) => {
      setConnectionMode(mode);
      writeStorage(STORAGE_CONNECTION_MODE_KEY, mode);

      if (mode === 'host') {
        await applyHostConfig(workspacePath);
      } else {
        await applyClientConfig(remoteServerUrl);
      }
    },
    [applyClientConfig, applyHostConfig, remoteServerUrl, workspacePath]
  );

  const handleRemoteUrlChange = useCallback(
    async (url: string) => {
      const normalized = normalizeIfPossible(url);
      setRemoteServerUrl(normalized);
      writeStorage(STORAGE_REMOTE_URL_KEY, normalized);

      if (connectionMode === 'client') {
        await applyClientConfig(normalized);
      }
    },
    [applyClientConfig, connectionMode]
  );

  useEffect(() => {
    // Initial configuration on app load.
    if (connectionMode === 'client') {
      void applyClientConfig(remoteServerUrl);
    } else {
      void applyHostConfig(workspacePath);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <main className="container">
      <div className="app-header">
        <h1 className="app-title">OpenWork</h1>
        <p className="app-subtitle">Manage your OpenCode sessions</p>
      </div>

      <ConnectionModeSelector
        mode={connectionMode}
        onModeChange={handleModeChange}
        serverUrl={remoteServerUrl}
        onServerUrlChange={handleRemoteUrlChange}
        status={connectionStatus}
        statusMessage={connectionMessage}
      />

      {connectionMode === 'host' && <WorkspacePicker onWorkspaceChange={handleWorkspaceChange} />}

      {connectionMode === 'host' && workspacePath && (
        <div className="workspace-info">
          <p className="info-text">Workspace ready: {workspacePath}</p>
        </div>
      )}

      {connectionMode === 'host' ? (
        workspacePath ? (
          <SessionManager key={clientEpoch} directory={workspacePath} clientEpoch={clientEpoch} />
        ) : null
      ) : (
        <SessionManager key={clientEpoch} clientEpoch={clientEpoch} />
      )}
    </main>
  );
}

export default App;
