/**
 * OpenCode Client Configuration Module
 *
 * This module provides a configured OpenCode SDK v2 client for interacting
 * with OpenCode sessions, messages, and events.
 *
 * The client supports:
 * - Local development server (http://localhost:11434)
 * - Remote production servers (custom URL)
 * - Server-sent events (SSE) for real-time streaming
 * - Session management, message handling, and event subscriptions
 */

import { createOpencodeClient } from '@opencode-ai/sdk/v2/client';
import type { OpencodeClient } from '@opencode-ai/sdk/v2/client';

/**
 * Default server URL for local development
 * Change this if your OpenCode server runs on a different port
 */
export const DEFAULT_LOCAL_SERVER_URL = 'http://localhost:11434';

/**
 * Client instance (singleton pattern)
 * The client is created once and reused throughout the application
 */
let opencodeClient: OpencodeClient | null = null;

/**
 * OpenCode client configuration options
 *
 * @interface ClientConfig
 * @property {string} [baseUrl] - The base URL of the OpenCode server
 * @property {string} [directory] - Optional directory path for local workspace
 * @property {boolean} [throwOnError] - Whether to throw errors or return them in response
 * @property {'data' | 'fields'} [responseStyle] - Response format style
 */
export interface ClientConfig {
  /**
   * The base URL of the OpenCode server.
   * Defaults to local development server if not provided.
   *
   * Examples:
   * - Local: 'http://localhost:11434'
   * - Remote: 'https://api.opencode.ai'
   * - Custom: 'http://192.168.1.100:11434'
   */
  baseUrl?: string;

  /**
   * Optional workspace directory path.
   * Used for local development to specify the project directory.
   *
   * If not provided, the SDK will use the current working directory.
   */
  directory?: string;

  /**
   * Whether to throw errors immediately or return them in the response object.
   *
   * - `true`: Errors are thrown (use try/catch)
   * - `false`: Errors are returned in the `error` field of response
   *
   * @default false
   */
  throwOnError?: boolean;

  /**
   * Response format style.
   *
   * - `'fields'`: Returns { data, error, request, response } object
   * - `'data'`: Returns only the data directly
   *
   * @default 'fields'
   */
  responseStyle?: 'data' | 'fields';
}

/**
 * Creates or retrieves the OpenCode client singleton instance.
 *
 * This function implements the singleton pattern - the client is created
 * once on first call and reused for subsequent calls. This ensures consistent
 * configuration across the application.
 *
 * @example
 * ```ts
 * // Create client with default configuration (local server)
 * const client = getOpencodeClient();
 *
 * // Create client with custom server URL
 * const client = getOpencodeClient({ baseUrl: 'https://api.opencode.ai' });
 *
 * // Create client with workspace directory
 * const client = getOpencodeClient({
 *   baseUrl: 'http://localhost:11434',
 *   directory: '/path/to/project'
 * });
 * ```
 *
 * @param config - Optional configuration for the client
 * @returns Configured OpenCode client instance
 */
export function getOpencodeClient(config?: ClientConfig): OpencodeClient {
  // Return existing client if already configured with the same options
  if (opencodeClient && !config) {
    return opencodeClient;
  }

  // Create and cache the client with optional directory parameter
  opencodeClient = createOpencodeClient({
    // Use provided baseUrl or default to local server
    baseUrl: config?.baseUrl || DEFAULT_LOCAL_SERVER_URL,
    // Response handling options
    throwOnError: config?.throwOnError ?? false,
    responseStyle: config?.responseStyle ?? 'fields',
    // Optional workspace directory (separate parameter)
    directory: config?.directory,
  });

  return opencodeClient;
}

/**
 * Resets the OpenCode client singleton.
 *
 * This function clears the cached client instance, allowing you to
 * create a new client with different configuration. Use this when:
 * - Switching between different OpenCode servers
 * - Changing workspace directories
 * - Testing with different configurations
 *
 * @example
 * ```ts
 * // Reset client before reconfiguring
 * resetOpencodeClient();
 *
 * // Create new client with different configuration
 * const client = getOpencodeClient({ baseUrl: 'https://api.opencode.ai' });
 * ```
 */
export function resetOpencodeClient(): void {
  opencodeClient = null;
}

/**
 * Creates a new OpenCode client instance (non-singleton).
 *
 * Unlike `getOpencodeClient`, this function always creates a fresh client
 * instance. Use this when you need multiple clients with different configurations.
 *
 * @example
 * ```ts
 * // Create multiple clients for different servers
 * const localClient = createClient({ baseUrl: 'http://localhost:11434' });
 * const remoteClient = createClient({ baseUrl: 'https://api.opencode.ai' });
 * ```
 *
 * @param config - Configuration for the client
 * @returns New OpenCode client instance
 */
export function createClient(config: ClientConfig = {}): OpencodeClient {
  return createOpencodeClient({
    baseUrl: config.baseUrl || DEFAULT_LOCAL_SERVER_URL,
    throwOnError: config.throwOnError ?? false,
    responseStyle: config.responseStyle ?? 'fields',
    directory: config.directory,
  });
}

/**
 * Checks if the client is connected to an OpenCode server.
 *
 * This function attempts to call the health check endpoint to verify
 * connectivity. It returns true if the server responds successfully.
 *
 * @example
 * ```ts
 * const isConnected = await checkConnection();
 * if (isConnected) {
 *   console.log('Connected to OpenCode server');
 * } else {
 *   console.error('Failed to connect to OpenCode server');
 * }
 * ```
 *
 * @returns Promise that resolves to true if connected, false otherwise
 */
export async function checkConnection(): Promise<boolean> {
  try {
    const client = getOpencodeClient();
    const result = await client.global.health();

    // Check if the request was successful
    return result.error === undefined;
  } catch (error) {
    console.error('Failed to check OpenCode connection:', error);
    return false;
  }
}

/**
 * Gets information about the connected OpenCode server.
 *
 * @example
 * ```ts
 * const serverInfo = await getServerInfo();
 * console.log('Server version:', serverInfo.version);
 * ```
 *
 * @returns Promise that resolves to server health information
 */
export async function getServerInfo() {
  const client = getOpencodeClient();
  const result = await client.global.health();

  if (result.error) {
    throw new Error(`Failed to get server info: ${JSON.stringify(result.error)}`);
  }

  return result.data;
}

/**
 * Reconfigures the existing client with new settings.
 *
 * This function resets the client and creates a new one with the
 * provided configuration. All existing event subscriptions will be
 * terminated and must be re-established.
 *
 * @example
 * ```ts
 * // Switch from local to remote server
 * await reconfigureClient({ baseUrl: 'https://api.opencode.ai' });
 * ```
 *
 * @param config - New configuration for the client
 * @returns The newly configured client instance
 */
export function reconfigureClient(config: ClientConfig): OpencodeClient {
  resetOpencodeClient();
  return getOpencodeClient(config);
}

// Export the default client getter for convenience
export default getOpencodeClient;
