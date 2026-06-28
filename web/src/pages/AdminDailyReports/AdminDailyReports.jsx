import './AdminDailyReports.css';
import { useEffect, useMemo, useState } from 'react';
import { getDailyReport } from '../../api/reports.js';
import { formatPrice } from '../../api/config.js';

function todayIso() {
  // Yerel tarihi yyyy-MM-dd olarak (ISO) verir.
  const d = new Date();
  const off = d.getTimezoneOffset();
  return new Date(d.getTime() - off * 60000).toISOString().slice(0, 10);
}

function densityFor(orderCount, max) {
  if (max === 0) return { label: 'SAKİN', type: 'normal' };
  const ratio = orderCount / max;
  if (ratio >= 0.8) return { label: 'ÇOK YOĞUN', type: 'high' };
  if (ratio >= 0.5) return { label: 'YOĞUN', type: 'medium' };
  return { label: 'NORMAL', type: 'normal' };
}

export default function AdminDailyReports() {
  const [date, setDate] = useState(todayIso());
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let active = true;
    setLoading(true);
    getDailyReport(date)
      .then((r) => active && setReport(r))
      .catch((e) => active && setError(e?.message || 'Rapor yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [date]);

  const maxOrders = useMemo(
    () => Math.max(0, ...(report?.hourly || []).map((h) => h.orderCount)),
    [report]
  );

  const stats = report
    ? [
        { id: 1, label: 'Toplam Ciro', value: formatPrice(report.totalRevenue) },
        { id: 2, label: 'Toplam Sipariş', value: `${report.orderCount} Sipariş` },
        { id: 3, label: 'Ortalama Sepet Tutarı', value: formatPrice(report.averageBasket) },
        { id: 4, label: 'En Yoğun Saat', value: report.peakHour },
      ]
    : [];

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col md:flex-row justify-between items-start md:items-end gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Günlük Raporlar
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Seçtiğiniz güne ait satış performansını ve saatlik istatistikleri
            buradan takip edebilirsiniz.
          </p>
        </div>

        <input
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="bg-surface-container-high px-4 py-2 rounded-full border border-outline-variant font-label-md text-label-md text-primary-container outline-none"
        />
      </section>

      {loading && (
        <div className="flex items-center justify-center gap-3 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined animate-spin">progress_activity</span>
          Yükleniyor...
        </div>
      )}

      {!loading && error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      {!loading && !error && report && (
        <>
          <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-md">
            {stats.map((stat) => (
              <div
                key={stat.id}
                className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col justify-between h-[140px] border-t-2 border-t-primary-container"
              >
                <span className="font-label-md text-label-md text-on-surface-variant">
                  {stat.label}
                </span>
                <p className="font-headline-lg text-headline-lg text-on-background">
                  {stat.value}
                </p>
              </div>
            ))}
          </section>

          <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
            <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">
              Saatlik Satış Performansı
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-surface-container text-on-surface-variant font-label-md text-label-md border-b border-outline-variant">
                    <th className="py-4 px-4 rounded-tl-lg">Saat</th>
                    <th className="py-4 px-4">Sipariş Sayısı</th>
                    <th className="py-4 px-4">Toplam Satış</th>
                    <th className="py-4 px-4">Ortalama Sepet</th>
                    <th className="py-4 px-4 rounded-tr-lg">Yoğunluk</th>
                  </tr>
                </thead>
                <tbody className="font-body-sm text-body-sm text-on-background">
                  {(report.hourly || []).length === 0 && (
                    <tr>
                      <td colSpan="5" className="py-8 px-4 text-center text-on-surface-variant">
                        Bu güne ait satış verisi bulunmuyor.
                      </td>
                    </tr>
                  )}
                  {(report.hourly || []).map((row, index) => {
                    const d = densityFor(row.orderCount, maxOrders);
                    return (
                      <tr
                        key={row.hour}
                        className={`hover:bg-surface-container-low transition-colors ${
                          index !== report.hourly.length - 1 ? 'border-b border-outline-variant' : ''
                        }`}
                      >
                        <td className="py-4 px-4 font-medium">{row.label}</td>
                        <td className="py-4 px-4">{row.orderCount}</td>
                        <td className="py-4 px-4">{formatPrice(row.totalSales)}</td>
                        <td className="py-4 px-4">{formatPrice(row.averageBasket)}</td>
                        <td className="py-4 px-4">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-lg text-[11px] font-bold tracking-wider ${
                              d.type === 'high'
                                ? 'bg-primary-container text-on-primary-container'
                                : d.type === 'medium'
                                ? 'bg-secondary-container text-on-secondary-container'
                                : 'bg-surface-container-high text-on-surface-variant'
                            }`}
                          >
                            {d.label}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        </>
      )}
    </div>
  );
}
