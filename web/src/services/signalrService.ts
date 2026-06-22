import {
  HubConnection,
  HubConnectionBuilder,
  HubConnectionState,
  LogLevel,
} from "@microsoft/signalr";
import { API_BASE_URL } from "./apiClient";

const HUB_PATH = process.env.NEXT_PUBLIC_ORDERS_HUB_PATH ?? "/hubs/orders";

/**
 * `/hubs/orders` kanalı için ince sarıcı.
 * Restoran grubuna katılır ve sunucudan gelen olayları dinler.
 */
export class OrdersHub {
  private connection: HubConnection | null = null;
  private joinedRestaurantId: string | null = null;

  constructor(private readonly tokenFactory: () => string | null) {}

  get state(): HubConnectionState {
    return this.connection?.state ?? HubConnectionState.Disconnected;
  }

  async connect(restaurantId: string): Promise<void> {
    if (!this.connection) {
      this.connection = new HubConnectionBuilder()
        .withUrl(`${API_BASE_URL}${HUB_PATH}`, {
          accessTokenFactory: () => this.tokenFactory() ?? "",
        })
        .withAutomaticReconnect([0, 2000, 5000, 10000])
        .configureLogging(LogLevel.Warning)
        .build();

      // Yeniden bağlanınca gruba tekrar katıl.
      this.connection.onreconnected(async () => {
        if (this.joinedRestaurantId) {
          await this.connection?.invoke("JoinRestaurantGroup", this.joinedRestaurantId).catch(() => {});
        }
      });
    }

    if (this.connection.state === HubConnectionState.Disconnected) {
      await this.connection.start();
    }

    if (this.joinedRestaurantId && this.joinedRestaurantId !== restaurantId) {
      await this.connection.invoke("LeaveRestaurantGroup", this.joinedRestaurantId).catch(() => {});
    }
    await this.connection.invoke("JoinRestaurantGroup", restaurantId);
    this.joinedRestaurantId = restaurantId;
  }

  /** Sunucudan gelen herhangi bir sipariş olayını tek geri çağırmaya köprüler. */
  onAnyOrderEvent(handler: (event: string, payload?: unknown) => void): void {
    if (!this.connection) return;
    const events = [
      "OrderCreated",
      "OrderUpdated",
      "OrderItemStatusChanged",
      "BillUpdated",
      "PaymentReceived",
      "TableSessionChanged",
    ];
    for (const evt of events) {
      this.connection.on(evt, (payload: unknown) => handler(evt, payload));
    }
  }

  async disconnect(): Promise<void> {
    if (!this.connection) return;
    try {
      if (this.joinedRestaurantId) {
        await this.connection.invoke("LeaveRestaurantGroup", this.joinedRestaurantId).catch(() => {});
      }
      await this.connection.stop();
    } finally {
      this.joinedRestaurantId = null;
    }
  }
}
