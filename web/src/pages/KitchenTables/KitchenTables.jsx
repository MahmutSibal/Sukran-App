import { useEffect, useMemo, useState } from 'react';
import './KitchenTables.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import { useRestaurantOrders } from '../../hooks/useRestaurantOrders.js';
import {
  getTables,
  openTableSession,
  closeTableSession,
} from '../../api/restaurants.js';
import { isActiveOrder } from '../../api/orderHelpers.js';
import { OrderItemStatus } from '../../api/config.js';

export default function KitchenTables() {
  const { restaurantId } = useAuth();
  const { orders } = useRestaurantOrders(restaurantId);
  const [rawTables, setRawTables] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const loadTables = async () => {
    if (!restaurantId) {
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const data = await getTables(restaurantId);
      setRawTables(data || []);
      setError('');
    } catch (e) {
      setError(e?.message || 'Masalar yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTables();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [restaurantId]);

  // Masa numarasına göre aktif siparişin durumu
  const orderStatusByTable = useMemo(() => {
    const map = new Map();
    for (const o of orders.filter(isActiveOrder)) {
      let label = 'Sipariş Var';
      if (o.derivedStatus === OrderItemStatus.Ready) label = 'Servise Hazır';
      else if (o.derivedStatus === OrderItemStatus.Preparing) label = 'Hazırlanıyor';
      map.set(o.tableNo, label);
    }
    return map;
  }, [orders]);

  const tables = useMemo(
    () =>
      rawTables.map((t) => {
        const isActive = (t.status || '').toLowerCase() !== 'closed';
        return {
          tableNo: t.tableNo,
          name: `Masa ${t.tableNo}`,
          slug: `m${t.tableNo}`,
          isActive,
          orderStatus: !isActive
            ? 'Pasif'
            : orderStatusByTable.get(t.tableNo) || 'Boş',
        };
      }),
    [rawTables, orderStatusByTable]
  );

  const filteredTables = useMemo(
    () =>
      tables.filter((t) =>
        t.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [tables, searchTerm]
  );

  const handleToggleStatus = async (table) => {
    try {
      if (table.isActive) {
        await closeTableSession(restaurantId, table.tableNo);
      } else {
        await openTableSession(restaurantId, table.tableNo);
      }
      await loadTables();
    } catch (e) {
      alert(e?.message || 'Masa durumu güncellenemedi.');
    }
  };

  const handleOpenMenu = (table) => {
    window.open(`https://sukranapp.com/menu/${table.slug}`, '_blank', 'noopener');
  };

  const activeCount = tables.filter((t) => t.isActive).length;
  const passiveCount = tables.filter((t) => !t.isActive).length;
  const busyCount = tables.filter(
    (t) => t.orderStatus !== 'Boş' && t.orderStatus !== 'Pasif'
  ).length;

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Mutfak Masaları
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Mutfak tarafında masaların aktiflik durumunu ve sipariş yoğunluğunu
            takip edebilirsiniz.
          </p>
        </div>

        <div className="grid grid-cols-3 gap-sm w-full lg:w-auto">
          <Stat label="Aktif" value={activeCount} />
          <Stat label="Siparişli" value={busyCount} />
          <Stat label="Pasif" value={passiveCount} />
        </div>
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
          Yükleniyor...
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
          <p className="font-body-lg text-body-lg">Masa bulunamadı.</p>
        </div>
      )}

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-md">
        {filteredTables.map((table) => (
          <KitchenTableCard
            key={table.tableNo}
            table={table}
            onToggleStatus={handleToggleStatus}
            onOpenMenu={handleOpenMenu}
          />
        ))}
      </section>
    </div>
  );
}

function Stat({ label, value }) {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl px-4 py-3 ambient-shadow">
      <p className="text-label-sm text-on-surface-variant">{label}</p>
      <p className="font-headline-sm text-headline-sm text-on-background">{value}</p>
    </div>
  );
}

function KitchenTableCard({ table, onToggleStatus, onOpenMenu }) {
  const isBusy = table.orderStatus !== 'Boş' && table.orderStatus !== 'Pasif';

  return (
    <div
      className={`bg-surface-container-lowest border rounded-xl p-md ambient-shadow hover:shadow-md transition-all flex flex-col gap-4 ${
        table.isActive ? 'border-outline-variant' : 'border-outline-variant opacity-55'
      }`}
    >
      <div className="flex justify-between items-start gap-md">
        <div>
          <h3 className="font-headline-sm text-headline-sm text-on-background">
            {table.name}
          </h3>
          <p className="text-label-sm text-on-surface-variant mt-1">
            Mutfak masa takibi
          </p>
        </div>
        <span
          className={`inline-flex items-center px-3 py-1 rounded-full text-[11px] font-bold ${
            table.isActive
              ? 'bg-primary-container text-on-primary-container'
              : 'bg-surface-container-high text-on-surface-variant'
          }`}
        >
          {table.isActive ? 'AKTİF' : 'PASİF'}
        </span>
      </div>

      <div className="aspect-square bg-surface-container-low rounded-lg flex flex-col items-center justify-center border border-dashed border-outline-variant gap-2">
        <span
          className={`material-symbols-outlined text-[64px] ${
            isBusy ? 'text-primary-container' : 'text-outline-variant'
          }`}
        >
          table_restaurant
        </span>
        <span
          className={`px-3 py-1 rounded-lg text-[11px] font-bold ${
            table.orderStatus === 'Servise Hazır'
              ? 'bg-primary-container text-on-primary-container'
              : table.orderStatus === 'Hazırlanıyor'
              ? 'bg-secondary-container text-on-secondary-container'
              : table.orderStatus === 'Sipariş Var'
              ? 'bg-surface-container-high text-on-surface-variant'
              : 'bg-surface-container text-on-surface-variant'
          }`}
        >
          {table.orderStatus}
        </span>
      </div>

      <div className="text-center">
        <p className="text-label-sm text-primary-container font-medium truncate">
          sukranapp.com/menu/{table.slug}
        </p>
      </div>

      <button
        type="button"
        onClick={() => onOpenMenu(table)}
        className="w-full flex items-center justify-center gap-2 py-2 border border-outline-variant rounded-lg text-label-md hover:bg-surface-container-low transition-colors"
      >
        <span className="material-symbols-outlined text-[20px]">open_in_new</span>
        QR Menüyü Aç
      </button>

      <div className="flex items-center justify-between pt-2 border-t border-outline-variant">
        <button
          type="button"
          onClick={() => onToggleStatus(table)}
          className="flex items-center gap-2"
        >
          <div
            className={`w-10 h-5 rounded-full relative transition-colors ${
              table.isActive ? 'bg-primary-container' : 'bg-surface-container-high'
            }`}
          >
            <div
              className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                table.isActive ? 'right-1' : 'left-1'
              }`}
            />
          </div>
          <span
            className={`text-label-sm font-bold ${
              table.isActive ? 'text-primary-container' : 'text-on-surface-variant'
            }`}
          >
            {table.isActive ? 'Aktif' : 'Pasif'}
          </span>
        </button>
      </div>
    </div>
  );
}
