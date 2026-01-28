/**
 * OpenCode SDK Utility Functions
 *
 * This module provides utility functions for common OpenCode SDK operations,
 * including connection management, URL handling, and error handling.
 */

import type { ServerConnection } from './types';
import { DEFAULT_LOCAL_SERVER_URL } from './client';

/**
 * Determines if a server URL is a local development server.
 *
 * @param url - Server URL to check
 * @returns true if the URL is localhost or 127.0.0.1, false otherwise
 */
export function isLocalServer(url: string): boolean {
  try {
    const parsedUrl = new URL(url);
    const hostname = parsedUrl.hostname.toLowerCase();
    return hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1';
  } catch {
    return false;
  }
}

/**
 * Validates an OpenCode server URL.
 *
 * Checks that the URL is properly formatted and uses HTTP/HTTPS protocol.
 *
 * @param url - Server URL to validate
 * @returns true if the URL is valid, false otherwise
 */
export function isValidServerUrl(url: string): boolean {
  try {
    const parsedUrl = new URL(url);
    return parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:';
  } catch {
    return false;
  }
}

/**
 * Normalizes a server URL by ensuring it has the correct format.
 *
 * Removes trailing slashes and ensures the protocol is present.
 *
 * @param url - Server URL to normalize
 * @returns Normalized server URL
 */
export function normalizeServerUrl(url: string): string {
  // Add protocol if missing (default to http://)
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = `http://${url}`;
  }

  // Remove trailing slash
  return url.replace(/\/$/, '');
}

/**
 * Creates a ServerConnection object from a URL string.
 *
 * @param url - Server URL
 * @param authToken - Optional authentication token
 * @returns ServerConnection object
 */
export function createServerConnection(url: string, authToken?: string): ServerConnection {
  const normalizedUrl = normalizeServerUrl(url);

  if (!isValidServerUrl(normalizedUrl)) {
    throw new Error(`Invalid server URL: ${url}`);
  }

  return {
    url: normalizedUrl,
    isLocal: isLocalServer(normalizedUrl),
    authToken,
  };
}

/**
 * Extracts error information from an API error response.
 *
 * @param error - Error object or unknown value
 * @returns Formatted error message
 */
export function extractErrorMessage(error: unknown): string {
  if (error && typeof error === 'object' && 'message' in error) {
    return String(error.message);
  }

  if (typeof error === 'string') {
    return error;
  }

  return 'An unknown error occurred';
}

/**
 * Checks if an error is a network/connection error.
 *
 * @param error - Error to check
 * @returns true if the error is network-related, false otherwise
 */
export function isNetworkError(error: unknown): boolean {
  const message = extractErrorMessage(error).toLowerCase();
  const networkErrorKeywords = [
    'network',
    'connection',
    'failed to fetch',
    'econnrefused',
    'timeout',
    'unreachable',
  ];

  return networkErrorKeywords.some(keyword => message.includes(keyword));
}

/**
 * Checks if an error is an authentication error.
 *
 * @param error - Error to check
 * @returns true if the error is authentication-related, false otherwise
 */
export function isAuthError(error: unknown): boolean {
  const message = extractErrorMessage(error).toLowerCase();
  const authErrorKeywords = [
    'unauthorized',
    'authentication',
    'unauthenticated',
    'forbidden',
    '401',
    '403',
  ];

  return authErrorKeywords.some(keyword => message.includes(keyword));
}

/**
 * Checks if an error is a not found error (404).
 *
 * @param error - Error to check
 * @returns true if the error is a 404 not found, false otherwise
 */
export function isNotFoundError(error: unknown): boolean {
  const message = extractErrorMessage(error).toLowerCase();
  return message.includes('not found') || message.includes('404');
}

/**
 * Formats an error for display to users.
 *
 * Provides user-friendly error messages based on error type.
 *
 * @param error - Error to format
 * @returns User-friendly error message
 */
export function formatErrorForDisplay(error: unknown): string {
  const message = extractErrorMessage(error);

  if (isNetworkError(error)) {
    return 'Failed to connect to OpenCode server. Please check your network connection and server URL.';
  }

  if (isAuthError(error)) {
    return 'Authentication failed. Please check your credentials and try again.';
  }

  if (isNotFoundError(error)) {
    return 'The requested resource was not found.';
  }

  return message;
}

/**
 * Creates a promise that resolves after a specified delay.
 *
 * @param ms - Delay in milliseconds
 * @returns Promise that resolves after the delay
 */
export function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Retries a function with exponential backoff.
 *
 * @param fn - Function to retry (should return a Promise)
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @param initialDelay - Initial delay in milliseconds (default: 1000)
 * @returns Promise that resolves with the function result
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  initialDelay = 1000
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry on the last attempt
      if (attempt < maxRetries - 1) {
        const delayMs = initialDelay * Math.pow(2, attempt);
        await delay(delayMs);
      }
    }
  }

  throw lastError;
}

/**
 * Handles an API response and extracts data or throws an error.
 *
 * @param response - API response from SDK
 * @returns Response data if successful
 * @throws Error if the response contains an error
 */
export async function handleApiResponse<T>(response: {
  data?: T;
  error?: unknown;
}): Promise<T> {
  if (response.error) {
    throw new Error(extractErrorMessage(response.error));
  }

  if (response.data === undefined) {
    throw new Error('No data received from API');
  }

  return response.data;
}

/**
 * Safely parses JSON with error handling.
 *
 * @param json - JSON string to parse
 * @returns Parsed object or null if parsing fails
 */
export function safeJsonParse<T = unknown>(json: string): T | null {
  try {
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

/**
 * Formats a timestamp into a human-readable date string.
 *
 * @param timestamp - Unix timestamp in milliseconds
 * @returns Formatted date string
 */
export function formatTimestamp(timestamp: number): string {
  return new Date(timestamp).toLocaleString();
}

/**
 * Calculates the relative time difference between two timestamps.
 *
 * @param timestamp - Unix timestamp in milliseconds
 * @returns Relative time string (e.g., "5 minutes ago")
 */
export function getRelativeTime(timestamp: number): string {
  const now = Date.now();
  const diff = now - timestamp;
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''} ago`;
  }
  if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''} ago`;
  }
  if (minutes > 0) {
    return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
  }
  return 'just now';
}

/**
 * Truncates a string to a maximum length with ellipsis.
 *
 * @param str - String to truncate
 * @param maxLength - Maximum length (default: 50)
 * @returns Truncated string with ellipsis if needed
 */
export function truncateString(str: string, maxLength = 50): string {
  if (str.length <= maxLength) {
    return str;
  }
  return `${str.slice(0, maxLength - 3)}...`;
}

/**
 * Debounces a function call.
 *
 * @param fn - Function to debounce
 * @param delay - Delay in milliseconds
 * @returns Debounced function
 */
export function debounce<T extends (...args: unknown[]) => unknown>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;

  return (...args: Parameters<T>) => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

/**
 * Gets the default server URL based on environment.
 *
 * In development, returns the local server URL.
 * In production, can be configured via environment variable.
 *
 * @returns Default server URL
 */
export function getDefaultServerUrl(): string {
  // Check for environment variable first
  if (import.meta.env?.VITE_OPENCODE_SERVER_URL) {
    return import.meta.env.VITE_OPENCODE_SERVER_URL;
  }

  // Default to local development server
  return DEFAULT_LOCAL_SERVER_URL;
}

/**
 * Logs an error to the console with context.
 *
 * @param error - Error to log
 * @param context - Additional context information
 */
export function logError(error: unknown, context?: Record<string, unknown>): void {
  console.error('OpenCode Error:', {
    message: extractErrorMessage(error),
    error,
    context,
    timestamp: new Date().toISOString(),
  });
}
