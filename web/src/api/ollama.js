// Yerel Ollama LLM ile sohbet (baloncuklu asistan).
// Vite proxy'si /ollama isteklerini http://localhost:11434 adresine yönlendirir.
import { OLLAMA_BASE_URL, OLLAMA_MODEL } from './config';

// Ollama /api/chat uç noktasına akışlı (streaming) istek gönderir.
// messages: [{ role: 'system'|'user'|'assistant', content }]
// onToken(textChunk): her gelen parça için çağrılır.
// signal: AbortSignal (isteğe bağlı, iptal için).
// Tüm yanıt metnini döndürür.
export async function streamChat(messages, { onToken, signal } = {}) {
  const res = await fetch(`${OLLAMA_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: OLLAMA_MODEL,
      messages,
      stream: true,
      // Düşünme/akıl yürütme çıktısını kapat: daha hızlı ve temiz yanıt.
      think: false,
    }),
    signal,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(
      `Asistan yanıt veremedi (HTTP ${res.status}). ${text}`.trim()
    );
  }

  // Ollama satır-bazlı JSON (NDJSON) akışı döndürür.
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let full = '';

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    let newlineIndex;
    while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
      const line = buffer.slice(0, newlineIndex).trim();
      buffer = buffer.slice(newlineIndex + 1);
      if (!line) continue;
      let payload;
      try {
        payload = JSON.parse(line);
      } catch {
        continue;
      }
      const chunk = payload?.message?.content || '';
      if (chunk) {
        full += chunk;
        onToken?.(chunk);
      }
    }
  }

  return full;
}
