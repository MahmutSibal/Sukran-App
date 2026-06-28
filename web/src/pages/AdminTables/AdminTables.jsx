import { useEffect, useMemo, useState } from 'react';
import './AdminTables.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import {
  getTables,
  addTable,
  removeTable,
  getRestaurant,
  openTableSession,
  closeTableSession,
} from '../../api/restaurants.js';
import TableQrModal from '../../components/TableQrModal.jsx';

// Backend masası (TableNo + status + qrToken) -> UI modeli
function mapTable(t) {
  const status = (t.status || '').toLowerCase();
  return {
    tableNo: t.tableNo,
    name: `Masa ${t.tableNo}`,
    // "Closed" dışındaki durumlar aktif (oturum açık) kabul edilir
    isActive: status !== 'closed',
    isOccupied: status === 'occupied',
    status: t.status,
    qrToken: t.qrToken,
    tableSessionId: t.tableSessionId,
  };
}

export default function AdminTables() {
  const { restaurantId } = useAuth();
  const [tables, setTables] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newTableNo, setNewTableNo] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [restaurantName, setRestaurantName] = useState('');
  const [qrTable, setQrTable] = useState(null); // QR modalında gösterilecek masa
  const [busyTableNo, setBusyTableNo] = useState(null); // aç/kapat işlemi süren masa

  const load = async () => {
    if (!restaurantId) {
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const data = await getTables(restaurantId);
      setTables((data || []).map(mapTable));
      setError('');
    } catch (e) {
      setError(e?.message || 'Masalar yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Veri yükleme efekti (harici sistem = backend); rule bu deseni yanlış işaretliyor.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    load();
    // Restoran adını QR yazdırma başlığı için al.
    if (restaurantId) {
      getRestaurant(restaurantId)
        .then((r) => setRestaurantName(r?.name || ''))
        .catch(() => setRestaurantName(''));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [restaurantId]);

  const filteredTables = useMemo(
    () =>
      tables.filter((table) =>
        table.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [tables, searchTerm]
  );

  const handleCreateTable = async () => {
    const parsed = newTableNo.trim() === '' ? null : Number(newTableNo);
    if (parsed !== null && (Number.isNaN(parsed) || parsed <= 0)) {
      alert('Lütfen geçerli bir masa numarası girin (veya boş bırakın).');
      return;
    }
    setSubmitting(true);
    try {
      await addTable(restaurantId, parsed);
      setNewTableNo('');
      setIsAddModalOpen(false);
      await load();
    } catch (e) {
      alert(e?.message || 'Masa eklenemedi.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteTable = async (tableNo) => {
    if (!window.confirm('Bu masayı silmek istediğinize emin misiniz?')) return;
    try {
      await removeTable(restaurantId, tableNo);
      setTables((prev) => prev.filter((t) => t.tableNo !== tableNo));
    } catch (e) {
      alert(e?.message || 'Masa silinemedi.');
    }
  };

  // QR göster: masa oturumu açıksa mevcut qrToken ile direkt göster;
  // kapalıysa önce oturumu aç (backend yeni qrToken üretir), sonra göster.
  const handleShowQr = async (table) => {
    if (table.isOccupied && table.qrToken) {
      setQrTable(table);
      return;
    }
    setBusyTableNo(table.tableNo);
    try {
      const session = await openTableSession(restaurantId, table.tableNo);
      const opened = {
        ...table,
        isOccupied: true,
        isActive: true,
        status: session.status,
        qrToken: session.qrToken,
        tableSessionId: session.tableSessionId,
      };
      setTables((prev) =>
        prev.map((t) => (t.tableNo === table.tableNo ? opened : t))
      );
      setQrTable(opened);
    } catch (e) {
      alert(e?.message || 'Masa oturumu açılamadı.');
    } finally {
      setBusyTableNo(null);
    }
  };

  // Masa oturumunu kapat (QR geçersiz olur, masa Closed olur).
  const handleCloseSession = async (table) => {
    if (
      !window.confirm(
        `Masa ${table.tableNo} oturumunu kapatmak istediğinize emin misiniz? Mevcut QR geçersiz olur.`
      )
    )
      return;
    setBusyTableNo(table.tableNo);
    try {
      await closeTableSession(restaurantId, table.tableNo);
      await load();
    } catch (e) {
      alert(e?.message || 'Masa oturumu kapatılamadı.');
    } finally {
      setBusyTableNo(null);
    }
  };

  return (
    <>
      <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
        <section className="flex flex-col md:flex-row justify-between items-start md:items-end gap-md">
          <div>
            <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
              Masalar
            </h2>
            <p className="font-body-lg text-body-lg text-on-surface-variant">
              QR Menü masalarını buradan oluşturabilir ve yönetebilirsiniz.
            </p>
          </div>

          <button
            type="button"
            onClick={() => {
              setNewTableNo('');
              setIsAddModalOpen(true);
            }}
            className="bg-primary-container text-on-primary-container font-label-md text-label-md px-6 py-3 rounded-lg hover:opacity-90 transition-opacity flex items-center gap-2"
          >
            <span className="material-symbols-outlined">add</span>
            Masa Ekle
          </button>
        </section>

        <section className="relative w-full">
          <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant">
            search
          </span>
          <input
            className="w-full bg-surface-container-lowest border border-outline-variant rounded-xl py-4 pl-12 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all ambient-shadow"
            placeholder="Masa ara..."
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </section>

        {loading && (
          <div className="flex items-center justify-center gap-3 py-16 text-on-surface-variant">
            <span className="material-symbols-outlined animate-spin">progress_activity</span>
            Masalar yükleniyor...
          </div>
        )}

        {!loading && error && (
          <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
            <span className="material-symbols-outlined text-[20px]">error</span>
            {error}
          </div>
        )}

        {!loading && !error && filteredTables.length === 0 && (
          <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
            <span className="material-symbols-outlined text-[40px]">table_restaurant</span>
            <p className="font-body-lg text-body-lg">Henüz masa eklenmemiş.</p>
          </div>
        )}

        <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-md">
          {filteredTables.map((table) => (
            <TableCard
              key={table.tableNo}
              table={table}
              busy={busyTableNo === table.tableNo}
              onShowQr={handleShowQr}
              onCloseSession={handleCloseSession}
              onDelete={handleDeleteTable}
            />
          ))}
        </section>
      </div>

      <TableQrModal
        open={Boolean(qrTable)}
        onClose={() => setQrTable(null)}
        restaurantId={restaurantId}
        restaurantName={restaurantName}
        tableNo={qrTable?.tableNo}
        qrToken={qrTable?.qrToken}
      />

      {isAddModalOpen && (
        <AddTableModal
          value={newTableNo}
          submitting={submitting}
          onChange={setNewTableNo}
          onClose={() => setIsAddModalOpen(false)}
          onSubmit={handleCreateTable}
        />
      )}
    </>
  );
}

function TableCard({ table, busy, onShowQr, onCloseSession, onDelete }) {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow hover:shadow-md transition-all flex flex-col gap-4">
      <div className="flex justify-between items-center">
        <h3 className="font-headline-sm text-headline-sm text-on-background">
          {table.name}
        </h3>
        <span
          className={`text-label-sm font-bold px-2 py-0.5 rounded-full ${
            table.isOccupied
              ? 'bg-primary-container text-on-primary-container'
              : 'bg-surface-container-high text-on-surface-variant'
          }`}
        >
          {table.isOccupied ? 'Oturum Açık' : 'Kapalı'}
        </span>
      </div>

      <div className="aspect-square bg-surface-container-low rounded-lg flex flex-col items-center justify-center gap-1 border border-dashed border-outline-variant">
        <span
          className={`material-symbols-outlined text-[64px] ${
            table.isOccupied ? 'text-primary-container' : 'text-outline-variant'
          }`}
        >
          qr_code_2
        </span>
        <span className="text-[11px] text-on-surface-variant">
          {table.isOccupied ? 'QR hazır' : 'Açınca QR üretilir'}
        </span>
      </div>

      <button
        type="button"
        onClick={() => onShowQr(table)}
        disabled={busy}
        className="w-full flex items-center justify-center gap-2 py-2.5 bg-primary-container text-on-primary-container rounded-lg text-label-md hover:opacity-90 transition-opacity disabled:opacity-60"
      >
        <span
          className={`material-symbols-outlined text-[20px] ${
            busy ? 'animate-spin' : ''
          }`}
        >
          {busy ? 'progress_activity' : 'qr_code_2'}
        </span>
        {table.isOccupied ? 'QR Göster' : 'Masayı Aç & QR'}
      </button>

      {table.isOccupied && (
        <button
          type="button"
          onClick={() => onCloseSession(table)}
          disabled={busy}
          className="w-full flex items-center justify-center gap-2 py-2 border border-outline-variant rounded-lg text-label-sm hover:bg-surface-container-low transition-colors disabled:opacity-60"
        >
          <span className="material-symbols-outlined text-[18px]">lock</span>
          Oturumu Kapat
        </button>
      )}

      <button
        type="button"
        onClick={() => onDelete(table.tableNo)}
        className="w-full flex items-center justify-center gap-2 py-2 text-error hover:bg-error-container/10 rounded-lg text-label-sm transition-colors"
      >
        <span className="material-symbols-outlined text-[18px]">delete</span>
        Masa Sil
      </button>
    </div>
  );
}

function AddTableModal({ value, submitting, onChange, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-on-surface/40 backdrop-blur-sm">
      <div className="bg-surface-container-lowest w-full max-w-md rounded-xl shadow-xl border border-outline-variant overflow-hidden">
        <div className="p-md border-b border-outline-variant flex justify-between items-start">
          <div>
            <h3 className="font-headline-sm text-headline-sm text-primary-container">
              Yeni Masa Ekle
            </h3>
            <p className="font-body-sm text-body-sm text-on-surface-variant mt-1">
              Masa numarası girin veya otomatik atanması için boş bırakın.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="text-on-surface-variant hover:bg-surface-container-low rounded-full p-1 transition-colors"
          >
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="p-md">
          <label className="font-label-md text-label-md text-on-background">
            Masa Numarası (opsiyonel)
          </label>
          <input
            className="mt-2 w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 px-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
            placeholder="Örn: 25"
            type="number"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') onSubmit();
              if (e.key === 'Escape') onClose();
            }}
            autoFocus
          />
        </div>

        <div className="p-md bg-surface-container-low flex justify-end gap-3">
          <button
            type="button"
            onClick={onClose}
            className="px-6 py-2.5 rounded-lg font-label-md text-label-md text-on-surface-variant hover:bg-surface-container-high transition-colors"
          >
            İptal
          </button>
          <button
            type="button"
            onClick={onSubmit}
            disabled={submitting}
            className="px-6 py-2.5 rounded-lg font-label-md text-label-md bg-primary-container text-white hover:opacity-90 transition-opacity shadow-sm disabled:opacity-60"
          >
            Masa Ekle
          </button>
        </div>
      </div>
    </div>
  );
}
