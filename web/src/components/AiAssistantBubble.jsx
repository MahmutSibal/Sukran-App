import { useEffect, useRef, useState } from 'react';
import { streamChat } from '../api/ollama';

// Modelin veri uydurmasını (halüsinasyon) engelleyen temel kurallar.
// Her sistem talimatının başına eklenir.
const GUARDRAILS = `Sen Şükran App platformunun panel asistanısın. Kurallar:
- Canlı veritabanına ERİŞİMİN YOK. Restoran adı, sayısı, adresi, ciro, sipariş,
  kullanıcı, istatistik gibi GERÇEK verileri ASLA uydurma veya tahmin etme.
- Gerçek veri yalnızca aşağıdaki "GÜNCEL VERİ" bölümünde verilmişse kullanılabilir.
  Orada yoksa "Bu bilgiye buradan erişemiyorum" de ve ilgili panel sayfasını öner
  (ör. Restoranlar, Raporlar, Siparişler).
- Örnek/temsili isim, kod veya rakam ÜRETME. Emin değilsen bilmediğini söyle.
- Kısa, net ve düzgün Türkçe yanıt ver. Uydurmaktansa yönlendir.`;

// Yerel Ollama (qwen3.5:9b) ile çalışan baloncuklu sohbet asistanı.
// Admin / Mutfak / Süper Admin panellerinde ortak kullanılır.
// props:
//   subtitle     -> başlık altındaki küçük etiket
//   greeting     -> ilk asistan mesajı
//   systemPrompt -> role/bağlam yönergesi (GUARDRAILS'e eklenir)
//   liveContext  -> panelden çekilen GERÇEK veri özeti (opsiyonel); modele
//                   yalnızca bu veriyi gerçek kabul etmesi söylenir.
export default function AiAssistantBubble({
  subtitle = 'Yapay zeka asistanı',
  greeting = 'Merhaba, sana nasıl yardımcı olabilirim?',
  systemPrompt = 'Restoran yönetim panelinde kullanıcıya yardımcı ol.',
  liveContext = '',
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([
    { role: 'assistant', content: greeting },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const scrollRef = useRef(null);
  const abortRef = useRef(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isOpen]);

  // Bileşen kaldırılırsa devam eden isteği iptal et.
  useEffect(() => () => abortRef.current?.abort(), []);

  const sendMessage = async () => {
    const text = input.trim();
    if (!text || isLoading) return;

    setError('');
    setInput('');

    // Sistem mesajı: kurallar + role + (varsa) gerçek veri.
    const systemContent =
      `${GUARDRAILS}\n\n${systemPrompt}` +
      (liveContext
        ? `\n\nGÜNCEL VERİ (yalnızca bunları gerçek kabul et):\n${liveContext}`
        : '');

    // Modele gönderilecek geçmiş (greeting hariç sistem + konuşma).
    const history = [
      { role: 'system', content: systemContent },
      ...messages
        .filter((m) => m.role === 'user' || m.role === 'assistant')
        .map((m) => ({ role: m.role, content: m.content })),
      { role: 'user', content: text },
    ];

    setMessages((prev) => [
      ...prev,
      { role: 'user', content: text },
      { role: 'assistant', content: '' },
    ]);
    setIsLoading(true);

    const controller = new AbortController();
    abortRef.current = controller;

    try {
      await streamChat(history, {
        signal: controller.signal,
        onToken: (chunk) => {
          setMessages((prev) => {
            const next = [...prev];
            const last = next[next.length - 1];
            if (last && last.role === 'assistant') {
              next[next.length - 1] = {
                ...last,
                content: last.content + chunk,
              };
            }
            return next;
          });
        },
      });
    } catch (err) {
      if (err?.name !== 'AbortError') {
        setError(err?.message || 'Asistana ulaşılamadı.');
        setMessages((prev) => {
          const next = [...prev];
          // Boş kalan asistan balonunu temizle.
          if (next[next.length - 1]?.content === '') next.pop();
          return next;
        });
      }
    } finally {
      setIsLoading(false);
      abortRef.current = null;
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <>
      {isOpen && (
        <div className="fixed right-4 md:right-6 bottom-24 md:bottom-28 z-[999] w-[360px] max-w-[calc(100vw-32px)] bg-surface-container-lowest border border-outline-variant rounded-xl ambient-shadow overflow-hidden">
          <div className="bg-primary-container text-on-primary-container px-4 py-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined">smart_toy</span>
              <div>
                <p className="font-label-md text-label-md">Şükran AI</p>
                <p className="text-[11px] opacity-80">{subtitle}</p>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setIsOpen(false)}
              className="w-8 h-8 rounded-full hover:bg-white/10 flex items-center justify-center"
              aria-label="Asistan panelini kapat"
            >
              <span className="material-symbols-outlined text-[20px]">close</span>
            </button>
          </div>

          <div
            ref={scrollRef}
            className="p-4 flex flex-col gap-3 max-h-[360px] min-h-[160px] overflow-y-auto"
          >
            {messages.map((m, i) =>
              m.role === 'user' ? (
                <div
                  key={i}
                  className="max-w-[82%] self-end bg-primary-container text-on-primary-container rounded-xl rounded-tr-sm p-3"
                >
                  <p className="text-body-sm whitespace-pre-wrap break-words">
                    {m.content}
                  </p>
                </div>
              ) : (
                <div
                  key={i}
                  className="max-w-[82%] bg-surface-container-low border border-outline-variant rounded-xl rounded-tl-sm p-3"
                >
                  <p className="text-body-sm text-on-background whitespace-pre-wrap break-words">
                    {m.content || (
                      <span className="inline-flex gap-1 text-on-surface-variant">
                        <span className="material-symbols-outlined text-[18px] animate-spin">
                          progress_activity
                        </span>
                        Yazıyor...
                      </span>
                    )}
                  </p>
                </div>
              )
            )}

            {error && (
              <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-3 py-2 text-[12px]">
                <span className="material-symbols-outlined text-[18px]">error</span>
                {error}
              </div>
            )}
          </div>

          <div className="border-t border-outline-variant p-3 flex items-center gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              disabled={isLoading}
              placeholder="Mesaj yaz..."
              className="flex-1 bg-surface-container-low border border-outline-variant rounded-full py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none disabled:opacity-60"
            />

            <button
              type="button"
              onClick={sendMessage}
              disabled={isLoading || !input.trim()}
              className="w-10 h-10 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center hover:opacity-90 transition-opacity disabled:opacity-50"
              aria-label="Mesaj gönder"
            >
              <span className="material-symbols-outlined text-[20px]">
                {isLoading ? 'progress_activity' : 'send'}
              </span>
            </button>
          </div>
        </div>
      )}

      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        className="fixed right-4 md:right-6 bottom-5 md:bottom-6 z-[999] w-14 h-14 md:w-16 md:h-16 rounded-full bg-primary-container text-on-primary-container ambient-shadow flex items-center justify-center hover:scale-105 active:scale-95 transition-transform"
        aria-label="Yapay zeka asistanını aç"
      >
        <span className="material-symbols-outlined text-[30px] md:text-[34px]">
          smart_toy
        </span>
        <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-secondary-container border-2 border-background" />
      </button>
    </>
  );
}
