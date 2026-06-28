import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

// Leaflet'in varsayılan ikon yolları paketleyici (Vite) ile bozulur; elle bağla.
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
});

// API ANAHTARSIZ konum seçici: OpenStreetMap karoları + Nominatim arama/ters-geocode.
// İsimle arama (örn. restoran adı), haritaya tıklama ve pini sürükleme ile
// enlem/boylam (+ adres) seçilir. onChange({ latitude, longitude, address }).
const DEFAULT_CENTER = [39.925, 32.866]; // Türkiye (Ankara) varsayılan görünüm
const NOMINATIM = 'https://nominatim.openstreetmap.org';

export default function MapLocationPicker({ latitude, longitude, onChange }) {
  const mapElRef = useRef(null);
  const mapRef = useRef(null);
  const markerRef = useRef(null);
  const onChangeRef = useRef(onChange);
  useEffect(() => {
    onChangeRef.current = onChange;
  });

  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState('');

  const hasCoords =
    latitude !== '' &&
    longitude !== '' &&
    !Number.isNaN(Number(latitude)) &&
    !Number.isNaN(Number(longitude));

  // Pini belirtilen konuma koy/taşı ve değişikliği yukarı bildir.
  const placeMarker = (lat, lng, address) => {
    const map = mapRef.current;
    if (!map) return;
    if (markerRef.current) {
      markerRef.current.setLatLng([lat, lng]);
    } else {
      const marker = L.marker([lat, lng], { draggable: true }).addTo(map);
      marker.on('dragend', () => {
        const pos = marker.getLatLng();
        emitChange(pos.lat, pos.lng, true);
      });
      markerRef.current = marker;
    }
    onChangeRef.current?.({
      latitude: Number(lat.toFixed(6)),
      longitude: Number(lng.toFixed(6)),
      address,
    });
  };

  // Ters-geocode ile adresi çözüp değişikliği bildirir.
  const emitChange = async (lat, lng, reverse) => {
    if (!reverse) {
      onChangeRef.current?.({
        latitude: Number(lat.toFixed(6)),
        longitude: Number(lng.toFixed(6)),
      });
      return;
    }
    let address;
    try {
      const res = await fetch(
        `${NOMINATIM}/reverse?format=jsonv2&lat=${lat}&lon=${lng}&accept-language=tr`
      );
      if (res.ok) {
        const data = await res.json();
        address = data?.display_name;
      }
    } catch {
      // ters-geocode başarısızsa sessizce sadece koordinatı bildir
    }
    onChangeRef.current?.({
      latitude: Number(lat.toFixed(6)),
      longitude: Number(lng.toFixed(6)),
      address,
    });
  };

  // Haritayı bir kez kur.
  useEffect(() => {
    if (mapRef.current || !mapElRef.current) return;
    const start = hasCoords
      ? [Number(latitude), Number(longitude)]
      : DEFAULT_CENTER;
    const map = L.map(mapElRef.current).setView(start, hasCoords ? 16 : 6);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap katkıda bulunanlar',
    }).addTo(map);

    map.on('click', (e) => {
      placeMarker(e.latlng.lat, e.latlng.lng);
      emitChange(e.latlng.lat, e.latlng.lng, true);
    });

    if (hasCoords) {
      placeMarker(Number(latitude), Number(longitude));
    }

    mapRef.current = map;
    // Layout sonrası boyutu düzelt.
    setTimeout(() => map.invalidateSize(), 0);

    return () => {
      map.remove();
      mapRef.current = null;
      markerRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const runSearch = async () => {
    const q = query.trim();
    if (!q) return;
    setSearching(true);
    setSearchError('');
    setResults([]);
    try {
      const res = await fetch(
        `${NOMINATIM}/search?format=jsonv2&limit=6&addressdetails=1&accept-language=tr&q=${encodeURIComponent(
          q
        )}`
      );
      if (!res.ok) throw new Error('Arama başarısız.');
      const data = await res.json();
      if (!Array.isArray(data) || data.length === 0) {
        setSearchError('Sonuç bulunamadı. Farklı bir arama deneyin.');
        return;
      }
      setResults(data);
    } catch (err) {
      setSearchError(err?.message || 'Arama yapılamadı.');
    } finally {
      setSearching(false);
    }
  };

  const selectResult = (item) => {
    const lat = Number(item.lat);
    const lng = Number(item.lon);
    const map = mapRef.current;
    if (map) map.setView([lat, lng], 17);
    placeMarker(lat, lng, item.display_name);
    setResults([]);
    setQuery(item.display_name?.split(',')[0] || query);
  };

  return (
    <div className="flex flex-col gap-2">
      {/* NOT: Bu dış create formunun içinde olduğu için <form> DEĞİL <div>;
          iç içe form geçersizdir ve Enter dış formu göndermemeli. */}
      <div className="relative">
        <div className="flex gap-2">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
              search
            </span>
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  runSearch();
                }
              }}
              placeholder="Restoran adı veya adres ara..."
              className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 pl-11 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
            />
          </div>
          <button
            type="button"
            onClick={runSearch}
            disabled={searching || !query.trim()}
            className="bg-primary-container text-on-primary-container font-label-md text-label-md px-4 rounded-lg hover:opacity-90 transition-opacity flex items-center gap-1 disabled:opacity-60"
          >
            <span
              className={`material-symbols-outlined text-[20px] ${
                searching ? 'animate-spin' : ''
              }`}
            >
              {searching ? 'progress_activity' : 'travel_explore'}
            </span>
            Ara
          </button>
        </div>

        {results.length > 0 && (
          <ul className="absolute z-[1000] mt-1 w-full bg-surface-container-lowest border border-outline-variant rounded-lg shadow-lg max-h-[240px] overflow-y-auto">
            {results.map((item) => (
              <li key={item.place_id}>
                <button
                  type="button"
                  onClick={() => selectResult(item)}
                  className="w-full text-left px-4 py-2 hover:bg-surface-container-high transition-colors flex items-start gap-2"
                >
                  <span className="material-symbols-outlined text-[18px] text-primary mt-0.5">
                    location_on
                  </span>
                  <span className="text-body-sm text-on-background">
                    {item.display_name}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {searchError && (
        <p className="text-[12px] text-error flex items-center gap-1">
          <span className="material-symbols-outlined text-[16px]">error</span>
          {searchError}
        </p>
      )}

      <div
        ref={mapElRef}
        className="w-full h-[320px] rounded-lg overflow-hidden border border-outline-variant z-0"
      />

      <p className="text-[12px] text-on-surface-variant flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">touch_app</span>
        {hasCoords
          ? `Seçili konum: ${Number(latitude).toFixed(5)}, ${Number(
              longitude
            ).toFixed(5)} — pini sürükleyerek veya haritaya tıklayarak değiştirebilirsin.`
          : 'Arama yap, haritaya tıkla veya pini sürükleyerek konumu seç.'}
      </p>
    </div>
  );
}
