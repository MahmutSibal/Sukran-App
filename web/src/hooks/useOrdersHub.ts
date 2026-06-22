"use client";

import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { OrdersHub } from "@/services/signalrService";

type HubStatus = "idle" | "connecting" | "connected" | "error";

/**
 * Restoran grubuna SignalR ile bağlanır. Herhangi bir sipariş olayında
 * `onEvent` çağrılır (genelde listeyi yeniden çekmek için).
 */
export function useOrdersHub(restaurantId: string | null, onEvent: () => void) {
  const { identity } = useAuth();
  const [status, setStatus] = useState<HubStatus>("idle");
  const onEventRef = useRef(onEvent);
  onEventRef.current = onEvent;

  useEffect(() => {
    if (!restaurantId || !identity) return;

    let cancelled = false;
    const hub = new OrdersHub(() => identity.accessToken);

    (async () => {
      setStatus("connecting");
      try {
        await hub.connect(restaurantId);
        hub.onAnyOrderEvent(() => onEventRef.current());
        if (!cancelled) setStatus("connected");
      } catch {
        if (!cancelled) setStatus("error");
      }
    })();

    return () => {
      cancelled = true;
      void hub.disconnect();
    };
  }, [restaurantId, identity]);

  return { status };
}
