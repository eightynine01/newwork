/**
 * OpenCode SDK Type Definitions
 *
 * This module provides TypeScript type definitions and utilities for working
 * with the OpenCode SDK v2. It re-exports types from the SDK and provides
 * additional application-specific type definitions.
 */

// Re-export all types from the OpenCode SDK v2
export type {
  // Client types
  OpencodeClient,
  OpencodeClientConfig,

  // API response types (selected commonly used ones)
  SessionListResponses,
  SessionCreateResponses,
  SessionGetResponses,
  SessionMessagesResponses,
  SessionPromptResponses,
  SessionTodoResponses,

  // Event types
  EventSubscribeResponses,
} from '@opencode-ai/sdk/v2/client';

/**
 * Represents a session in the OpenCode system.
 *
 * This type consolidates session information from various API responses
 * into a unified interface for easier use in the application.
 */
export interface Session {
  /** Unique identifier for the session */
  id: string;

  /** Session title */
  title: string;

  /** Timestamp when the session was created */
  createdAt: number;

  /** Timestamp when the session was last updated */
  updatedAt: number;

  /** Whether the session is currently archived */
  archived: boolean | null;

  /** Parent session ID if this is a forked session */
  parentId: string | null;
}

/**
 * Represents a message within a session.
 */
export interface Message {
  /** Unique identifier for the message */
  id: string;

  /** Session ID that this message belongs to */
  sessionId: string;

  /** Message role: 'user', 'assistant', or 'system' */
  role: 'user' | 'assistant' | 'system';

  /** Message content */
  content: string;

  /** Timestamp when the message was created */
  createdAt: number;

  /** Whether this message is currently being generated (streaming) */
  isStreaming: boolean;
}

/**
 * Represents a todo item in a session.
 */
export interface Todo {
  /** Unique identifier for the todo item */
  id: string;

  /** Todo description/text */
  content: string;

  /** Todo status */
  status: string;

  /** Todo priority */
  priority: string;

  /** Timestamp when the todo was created */
  createdAt?: number;

  /** Timestamp when the todo was last updated */
  updatedAt?: number;
}

/**
 * Represents an event from the OpenCode SSE stream.
 */
export interface OpenCodeEvent {
  /** Event type */
  type: string;

  /** Event data payload */
  data: unknown;

  /** Timestamp when the event was received */
  timestamp: number;
}

/**
 * Configuration for connecting to an OpenCode server.
 */
export interface ServerConnection {
  /** Server URL (e.g., 'http://localhost:11434') */
  url: string;

  /** Whether this is a local development server */
  isLocal: boolean;

  /** Optional authentication token */
  authToken?: string;
}

/**
 * Error response from OpenCode API.
 */
export interface ApiError {
  /** Error message */
  message: string;

  /** Error code */
  code?: string;

  /** Additional error details */
  details?: Record<string, unknown>;
}

/**
 * Standard API response wrapper.
 *
 * This type represents the response format returned by the SDK
 * when using the default 'fields' response style.
 */
export interface ApiResponse<T = unknown> {
  /** Response data if successful */
  data?: T;

  /** Error information if the request failed */
  error?: ApiError;

  /** Original HTTP request object */
  request: Request;

  /** Original HTTP response object */
  response: Response;
}

/**
 * Options for creating a new session.
 */
export interface CreateSessionOptions {
  /** Session title (optional) */
  title?: string;

  /** Parent session ID to fork from (optional) */
  parentId?: string;

  /** Permission ruleset for the session (optional) */
  permission?: unknown;
}

/**
 * Options for sending a message to a session.
 */
export interface SendMessageOptions {
  /** Session ID to send the message to */
  sessionId: string;

  /** Message content */
  content: string;

  /** Optional message ID to reply to */
  replyToMessageId?: string;

  /** Model configuration (provider and model IDs) */
  model?: {
    providerId: string;
    modelId: string;
  };

  /** Whether to suppress the assistant's reply */
  noReply?: boolean;

  /** Custom system prompt */
  system?: string;
}

/**
 * Options for listing sessions.
 */
export interface ListSessionsOptions {
  /** Maximum number of sessions to return */
  limit?: number;

  /** Starting offset for pagination */
  start?: number;

  /** Search query to filter sessions */
  search?: string;

  /** Whether to include only root sessions (no forks) */
  rootsOnly?: boolean;
}

/**
 * Configuration for SSE event subscription.
 */
export interface EventSubscriptionOptions {
  /** Callback function for when an event is received */
  onEvent: (event: OpenCodeEvent) => void;

  /** Callback function for when an error occurs */
  onError?: (error: Error) => void;

  /** Whether to auto-reconnect on connection loss */
  autoReconnect?: boolean;

  /** Maximum number of reconnection attempts */
  maxRetryAttempts?: number;

  /** Delay between reconnection attempts (ms) */
  retryDelay?: number;
}

/**
 * Represents a stream of events from OpenCode.
 */
export interface EventStream {
  /** Close the event stream and stop receiving events */
  close: () => Promise<void>;

  /** Check if the stream is currently connected */
  isConnected: () => boolean;
}
