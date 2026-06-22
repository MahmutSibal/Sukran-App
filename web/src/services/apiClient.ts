/**
 * Tek noktadan HTTP istemcisi. Bearer token'ı bir sağlayıcıdan okur, JSON
 * encode/decode yapar ve 204/boş gövdeyi güvenle ele alır.
 */

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, "") ??
  "https://starr-haustorial-robin.ngrok-free.dev";

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

let tokenProvider: () => string | null = () => null;

/** AuthContext, oturum token'ını buraya bağlar. */
export function setAuthTokenProvider(provider: () => string | null): void {
  tokenProvider = provider;
}

/**
 * 401 alındığında çağrılır; access token'ı yeniler ve yeni token'ı döndürür
 * (yenilenemezse null). AuthContext bağlar; tek-uçuş (single-flight) garantisi
 * orada sağlanır. Yenileme başarılıysa istek bir kez daha denenir.
 */
let authRefreshHandler: (() => Promise<string | null>) | null = null;

export function setAuthRefreshHandler(handler: (() => Promise<string | null>) | null): void {
  authRefreshHandler = handler;
}

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  body?: unknown;
  /** Geçici override (login gibi token henüz context'te yokken). */
  token?: string | null;
  query?: Record<string, string | number | boolean | undefined>;
  signal?: AbortSignal;
}

function buildUrl(path: string, query?: RequestOptions["query"]): string {
  const url = new URL(path.startsWith("http") ? path : `${API_BASE_URL}${path}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined) url.searchParams.set(key, String(value));
    }
  }
  return url.toString();
}

export async function request<T>(path: string, options: RequestOptions = {}, retrying = false): Promise<T> {
  const token = options.token !== undefined ? options.token : tokenProvider();

  const response = await fetch(buildUrl(path, options.query), {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      Accept: "application/json",
      // ngrok ücretsiz tünelin tarayıcı uyarı sayfasını atlamak için.
      "ngrok-skip-browser-warning": "true",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    signal: options.signal,
    cache: "no-store",
  });

  // Access token süresi dolmuşsa: bir kez yenile ve isteği tekrar dene.
  // (Açık token override'lı çağrılarda — örn. login — yenileme denenmez.)
  if (
    response.status === 401 &&
    !retrying &&
    options.token === undefined &&
    authRefreshHandler
  ) {
    const refreshed = await authRefreshHandler();
    if (refreshed) return request<T>(path, options, true);
  }

  if (response.status === 204) return undefined as T;

  const text = await response.text();
  const data = text ? safeJsonParse(text) : undefined;

  if (!response.ok) {
    const message =
      (data && typeof data === "object" && "message" in data
        ? String((data as { message: unknown }).message)
        : undefined) ?? text ?? `İstek başarısız (${response.status})`;
    throw new ApiError(response.status, message);
  }

  return data as T;
}

function safeJsonParse(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

export const api = {
  get: <T>(path: string, opts?: Omit<RequestOptions, "method" | "body">) =>
    request<T>(path, { ...opts, method: "GET" }),
  post: <T>(path: string, body?: unknown, opts?: Omit<RequestOptions, "method">) =>
    request<T>(path, { ...opts, method: "POST", body }),
  put: <T>(path: string, body?: unknown, opts?: Omit<RequestOptions, "method">) =>
    request<T>(path, { ...opts, method: "PUT", body }),
  delete: <T>(path: string, opts?: Omit<RequestOptions, "method" | "body">) =>
    request<T>(path, { ...opts, method: "DELETE" }),
};
