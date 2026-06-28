import { useEffect, useState } from 'react';
import QRCode from 'qrcode';

// Bir masa için müşteri QR kodunu gösteren modal.
// Müşteri URL'si: {origin}/t/{restaurantId}/{tableNo}/{qrToken}
// Bu QR taranınca müşteri oturum açma + menü/sipariş sayfasına gider.
export default function TableQrModal({
  open,
  onClose,
  restaurantId,
  restaurantName,
  tableNo,
  qrToken,
}) {
  const [dataUrl, setDataUrl] = useState('');
  const [error, setError] = useState('');

  const customerUrl =
    restaurantId && qrToken
      ? `${window.location.origin}/t/${restaurantId}/${tableNo}/${qrToken}`
      : '';

  useEffect(() => {
    if (!open || !customerUrl) return;
    let active = true;
    QRCode.toDataURL(customerUrl, { width: 360, margin: 2 })
      .then((url) => {
        if (!active) return;
        setDataUrl(url);
        setError('');
      })
      .catch((e) => active && setError(e?.message || 'QR oluşturulamadı.'));
    return () => {
      active = false;
    };
  }, [open, customerUrl]);

  if (!open) return null;

  const handleDownload = () => {
    if (!dataUrl) return;
    const a = document.createElement('a');
    a.href = dataUrl;
    a.download = `masa-${tableNo}-qr.png`;
    a.click();
  };

  const handlePrint = () => {
    if (!dataUrl) return;
    const w = window.open('', '_blank', 'width=480,height=640');
    if (!w) {
      alert('Yazdırma penceresi engellendi. Lütfen açılır pencerelere izin verin.');
      return;
    }
    w.document.write(`
      <html>
        <head><title>Masa ${tableNo} QR</title>
        <style>
          body { font-family: sans-serif; text-align: center; padding: 32px; }
          h1 { font-size: 22px; margin: 0 0 4px; }
          h2 { font-size: 16px; color: #555; font-weight: normal; margin: 0 0 24px; }
          img { width: 320px; height: 320px; }
          p { color: #888; font-size: 12px; margin-top: 16px; word-break: break-all; }
        </style></head>
        <body>
          <h1>${restaurantName || 'Restoran'}</h1>
          <h2>Masa ${tableNo} — Menü & Sipariş</h2>
          <img src="${dataUrl}" />
          <p>${customerUrl}</p>
          <script>window.onload = function(){ window.print(); }</script>
        </body>
      </html>
    `);
    w.document.close();
  };

  return (
    <div
      className="fixed inset-0 z-[1000] bg-black/50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <div
        className="bg-surface-container-lowest border border-outline-variant rounded-2xl ambient-shadow w-full max-w-[420px] p-lg flex flex-col items-center gap-md"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="w-full flex items-center justify-between">
          <div>
            <h3 className="font-headline-sm text-headline-sm text-on-background">
              Masa {tableNo} QR Kodu
            </h3>
            <p className="text-body-sm text-on-surface-variant">
              Müşteri tarayınca menü ve sipariş ekranı açılır.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-9 h-9 rounded-full hover:bg-surface-container-high flex items-center justify-center"
            aria-label="Kapat"
          >
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="bg-white rounded-xl p-4 flex items-center justify-center min-h-[300px] min-w-[300px]">
          {error ? (
            <span className="text-error text-body-sm">{error}</span>
          ) : dataUrl ? (
            <img src={dataUrl} alt={`Masa ${tableNo} QR`} className="w-[280px] h-[280px]" />
          ) : (
            <span className="material-symbols-outlined animate-spin text-on-surface-variant">
              progress_activity
            </span>
          )}
        </div>

        <p className="text-[11px] text-on-surface-variant break-all text-center w-full">
          {customerUrl}
        </p>

        <div className="flex gap-3 w-full">
          <button
            type="button"
            onClick={handlePrint}
            disabled={!dataUrl}
            className="flex-1 bg-primary-container text-on-primary-container font-label-md text-label-md py-3 rounded-lg hover:opacity-90 transition-opacity flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <span className="material-symbols-outlined text-[20px]">print</span>
            Yazdır
          </button>
          <button
            type="button"
            onClick={handleDownload}
            disabled={!dataUrl}
            className="flex-1 border border-outline-variant text-on-background font-label-md text-label-md py-3 rounded-lg hover:bg-surface-container-high transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <span className="material-symbols-outlined text-[20px]">download</span>
            İndir
          </button>
        </div>
      </div>
    </div>
  );
}
