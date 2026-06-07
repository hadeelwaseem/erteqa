# SOOQ Mobile — Customer Pages Specification

**Scope:** customer-facing (storefront) pages for the **Order**, **Shipment**, and **Payment** modules.
Out of scope (separate modules / specs): auth, customer profile/addresses, product browsing, returns (RET module).

---

## 0. Conventions

### 0.1 Base URL & environments

| Env | API base |
| --- | --- |
| Dev (local backend) | `http://localhost:8081/api/v1` |
| Prod | `https://api.erteqa.me/api/v1` |

All paths below are **relative to the base URL** (e.g. `POST /public/checkout` = `POST {base}/public/checkout`).

### 0.2 Two auth contexts

| Context | When | Headers |
| --- | --- | --- |
| **Public** (anonymous) | Storefront browsing, guest checkout, guest order tracking, payment methods list, shipping cost, shipment tracking | `X-Tenant-Id: <tenant-uuid>` (required) |
| **Customer** (authenticated) | "My orders", invoice download, cancel order | `Authorization: Bearer <accessToken>` (and `X-Tenant-Id`; the JWT already binds the tenant, but send the header for parity) |

The tenant UUID is obtained at app start via `GET /public/stores/by-slug/{storeSlug}` (auth module — out of scope here). Store the UUID and send it on every API call.

### 0.3 Response envelope

Single-object responses (`ApiResponse<T>`):

```json
{
  "success": true,
  "message": null,
  "data": { /* T */ },
  "timestamp": 1780062656744,
  "errorCode": null,
  "fieldErrors": null
}
```

Paged responses (`PagedApiResponse<T>` — used by `GET /customer/orders`):

```json
{
  "success": true,
  "data": [ /* T[] */ ],
  "meta": {
    "page": 0,
    "size": 20,
    "total": 137,
    "totalPages": 7,
    "hasNext": true,
    "hasPrev": false
  },
  "timestamp": 1780062656744
}
```

Spring Page (used by `Page<OrderResponseDto>` on some endpoints) returns the same content via:

```json
{
  "content": [...],
  "totalElements": 137,
  "totalPages": 7,
  "number": 0,
  "size": 20,
  "first": true,
  "last": false,
  "empty": false
}
```

### 0.4 Error envelope

Any non-2xx response uses the same envelope with `success: false`:

```json
{
  "success": false,
  "status": 400,
  "errorCode": "ERR_1002",
  "message": "File not found: …",
  "details": null,
  "fieldErrors": [
    { "field": "items[0].variantId", "message": "must not be null" }
  ],
  "timestamp": "2026-05-29T16:55:16.7236739"
}
```

Common HTTP codes the client should handle:

| Code | Meaning |
| --- | --- |
| 400 | Validation / business-rule violation (read `errorCode`, `message`, `fieldErrors`) |
| 401 | Missing/expired customer JWT → refresh or send to login |
| 403 | Forbidden (e.g. order doesn't belong to this customer; missing `X-Tenant-Id`) |
| 404 | Resource not found (also returned for "no shipment yet" on `/public/shipping/track/{orderId}` — render as empty state, don't toast) |
| 409 / 422 | Idempotency conflict / business conflict (e.g. cancelling an already-shipped order) |

### 0.5 Enums

```ts
type OrderStatus =
  | "PENDING" | "CONFIRMED" | "PROCESSING" | "SHIPPED"
  | "DELIVERED" | "COMPLETED" | "CANCELLED" | "RETURNED"
  | "REFUNDED" | "FAILED"

type PaymentStatus =
  | "UNPAID" | "PENDING" | "PAID" | "FAILED" | "REFUNDED"

type PaymentMethod = "COD" | "PAYMERA"          // string on the wire

type ShipmentStatus =
  | "PENDING" | "PICKED_UP" | "IN_TRANSIT"
  | "READY_FOR_PICKUP_AT_OFFICE"
  | "DELIVERED" | "FAILED" | "RETURNED"
```

### 0.6 Money & dates

- Currency: **SYP** (Syrian Pound). All amounts are JSON numbers; render as integers (no fractional SYP).
- Timestamps: ISO-8601 local datetime, e.g. `"2026-05-29T16:50:17.00093"` — treat as the server's clock; format on the client.

---

# Order Module

## Page 1 — Cart  (client-side only, no API)

**Purpose:** local shopping cart before checkout.

**State (per device, persisted):**

```ts
type CartLine = {
  variantId: string         // UUID
  quantity: number          // ≥ 1
  // Snapshots — for display only; do NOT trust on checkout (server reprices)
  productTitle: string
  variantTitle?: string
  unitPrice: number
  thumbnailUrl?: string
}

type Cart = { items: CartLine[] }
```

**Actions:** add line · change quantity · remove line · clear cart. No backend roundtrip.

> The cart key on web is `sooq.storefront.cart.v1`. Mobile can pick its own key but should keep the **same line shape** so a future cart-sync feature stays compatible.

---

## Page 2 — Checkout

Single page (or wizard) that gathers: shipping address (GPS + recipient), payment method, optional discount code, optional notes, optional guest email. Submits one order.

### 2.1 Prefetch — payment methods

```
GET /public/payments/methods
Headers: X-Tenant-Id
```

**Response (`ApiResponse<PublicPaymentMethodDto[]>`):**

```json
{
  "success": true,
  "data": [
    { "providerCode": "PAYMERA", "displayName": "Paymera (بطاقة)", "requiresRedirect": true,  "supportsSavedCards": true },
    { "providerCode": "COD",     "displayName": "COD",              "requiresRedirect": false, "supportsSavedCards": false }
  ]
}
```

Use `providerCode` as the `paymentMethod` value when placing the order. `requiresRedirect: true` means the client must navigate the customer to a hosted page after checkout (see §Payment-Online below — currently TBD).

### 2.2 Prefetch — shipping cost

Call once GPS coords are picked. Re-call when coords change.

```
POST /public/shipping/calculate
Headers: X-Tenant-Id, Content-Type: application/json
```

**Body (`ShippingCostRequestDto`):**

```json
{
  "originLat": 33.5138,
  "originLng": 36.2765,
  "destinationLat": 33.5012,
  "destinationLng": 36.2901,
  "shippingProviderId": null
}
```

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `originLat` / `originLng` | number | ✓ | Store origin coords (from store config — bootstrap call returns these) |
| `destinationLat` / `destinationLng` | number | ✓ | Customer-picked GPS |
| `shippingProviderId` | UUID? | optional | Force a specific 3PL; omit to let the backend route automatically |

**Response (`ApiResponse<ShippingCostResponseDto>`):**

```json
{
  "success": true,
  "data": {
    "shippingCostSyp": 25000,
    "providerCode": "DOMESTIC",
    "providerName": "اسم شركة الشحن",
    "estimatedDeliveryHours": 48
  }
}
```

### 2.3 Optional — validate discount code

Call before submitting if the customer types a code.

```
GET /public/checkout/validate-discount
  ?code=10OFF
  &subtotal=125000
  &shippingCost=25000
Headers: X-Tenant-Id
```

**Response (`ApiResponse<ApplyDiscountResultDto>`):**

```json
{
  "success": true,
  "data": {
    "discountCodeId": "c1b2…-…",
    "code": "10OFF",
    "discountType": "PERCENTAGE",
    "appliedAmount": 12500
  }
}
```

On failure (invalid / expired / threshold not met) the envelope is `success: false` — render the `message` inline, don't block the page.

### 2.4 Submit — place order

```
POST /public/checkout
Headers:
  X-Tenant-Id
  Content-Type: application/json
  Authorization: Bearer <token>    ← OPTIONAL: include only if the customer is logged in;
                                     server links the order to their customer profile.
```

**Body (`CheckoutRequestDto`):**

```json
{
  "items": [
    { "variantId": "d2000000-…", "quantity": 2 }
  ],
  "shippingAddress": {
    "latitude": 33.5012,
    "longitude": 36.2901,
    "recipientName": "أحمد علي",
    "phone": "+963999999999",
    "addressLabel": "Al-Hamra St, Bldg 5, near the bakery"   // optional, free text
  },
  "paymentMethod": "COD",                                     // or "PAYMERA"
  "checkoutToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",    // generate a UUIDv4 client-side; idempotency key
  "discountCode": "10OFF",                                    // optional
  "notesCustomer": "Please deliver after 5pm",                // optional
  "guestEmail": "guest@example.com"                           // optional; REQUIRED for guest checkout (needed by §4 guest-tracking lookup)
}
```

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `items` | `[{ variantId, quantity }]` | ✓ | At least one item, `quantity ≥ 1` |
| `shippingAddress.latitude/longitude` | number | ✓ | -90..90 / -180..180 |
| `shippingAddress.recipientName` | string | ✓ | Non-blank |
| `shippingAddress.phone` | string | ✓ | E.164 form (`+963…`) |
| `shippingAddress.addressLabel` | string | optional | Free-text note shown on invoice; not used for routing |
| `paymentMethod` | string | ✓ | `providerCode` from §2.1 |
| `checkoutToken` | UUID | ✓ | **Generate once per checkout attempt and persist** — resubmitting the same token returns the same order (no duplicates on retry) |
| `discountCode` | string | optional | |
| `notesCustomer` | string | optional | Visible to merchant + customer |
| `guestEmail` | email | optional | Required for guest checkout — without it the customer can't track the order via §4 |

**Response (`ApiResponse<OrderDetailResponseDto>`) — full order:**

```json
{
  "success": true,
  "data": {
    "orderId": "f281e41d-…",
    "tenantId": "b0e061f0-…",
    "customerId": null,                          // null for guest
    "orderNumber": "ORD-1713091200000",
    "orderStatus": "PENDING",
    "paymentStatus": "UNPAID",
    "paymentMethod": "COD",
    "currencyCode": "SYP",
    "subtotal":      125000,
    "discountAmount": 12500,
    "taxAmount":         0,
    "shippingCost":  25000,
    "total":        137500,
    "shippingAddress": { "latitude": 33.5012, "longitude": 36.2901, "recipientName": "…", "phone": "…", "addressLabel": "…" },
    "notesCustomer": "Please deliver after 5pm",
    "notesInternal": null,                       // hidden from customer (always null here)
    "guestEmail":    "guest@example.com",
    "placedAt":      "2026-05-29T16:50:17.00093",
    "items": [
      {
        "orderItemId":  "oi-…",
        "variantId":    "d2000000-…",
        "productTitle": "Cotton shirt",
        "variantTitle": "M / Blue",
        "sku":          "CS-M-BLU",
        "quantity":     2,
        "unitPrice":    62500,
        "discountAmount": 0,
        "totalPrice":   125000
      }
    ],
    "timeline": [
      { "timelineId": "…", "action": "ORDER_CREATED", "actor": "CUSTOMER", "details": null, "createdAt": "…" }
    ],
    "invoiceNumber":  null,                      // generated later
    "invoicePdfUrl":  null
  }
}
```

After success: clear the cart, persist `orderId` + `orderNumber` + `guestEmail` (for guest tracking), then navigate to §3.

---

## Page 3 — Order Confirmation / Success

Static page; shows `orderNumber`, recap, and three actions:

- **"تتبّع الطلب"** → §4 (guest tracking, if guest) or §6 (account order detail, if logged in).
- **"عرض الطلبات"** → §5 (if logged in).
- **"العودة للتسوّق"** → home.

For **`paymentMethod: "PAYMERA"`** (online), see §Payment-Online below — flow currently incomplete.

No API call needed; uses the response from §2.4 directly.

---

## Page 4 — Guest Order Tracking (anonymous)

URL pattern (web): `/track/{orderNumber}`. Mobile equivalent: a "Track an order" entry point that prompts for the **order number** plus the **email used at checkout**, then renders the full order detail.

```
GET /public/checkout/orders/lookup?orderNumber={orderNumber}&email={email}
Headers: X-Tenant-Id
```

**Response (`ApiResponse<CustomerOrderResponseDto>`):** see §6.3 — same shape as the authenticated order detail (without `notesInternal`).

| HTTP | Render |
| --- | --- |
| 200 | Order detail page (items, address, timeline, summary). Pair with §Shipment-Track to show carrier status. |
| 404 / 400 | "تعذّر العثور على الطلب — تأكد من رقم الطلب والبريد الإلكتروني." Don't fire a global error toast. |

---

## Page 5 — My Orders (list, authenticated)

```
GET /customer/orders?page=0&size=20&status=DELIVERED
Headers: X-Tenant-Id, Authorization: Bearer <token>
```

| Query | Type | Notes |
| --- | --- | --- |
| `page` | int | 0-based |
| `size` | int | default 20 |
| `status` | `OrderStatus` | optional filter |
| `sort` | string | optional; defaults to `placedAt` desc |

**Response (`ApiResponse<Page<OrderResponseDto>>`):**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "orderId":      "…",
        "tenantId":     "…",
        "customerId":   "…",
        "orderNumber":  "ORD-…",
        "orderStatus":  "DELIVERED",
        "paymentStatus":"PAID",
        "paymentMethod":"COD",
        "subtotal":     125000,
        "discountAmount": 0,
        "taxAmount":      0,
        "total":        150000,
        "itemCount":      3,
        "placedAt":     "2026-05-29T…"
      }
    ],
    "totalElements": 137,
    "totalPages":     7,
    "number":         0,
    "size":          20,
    "first":       true,
    "last":       false,
    "empty":      false
  }
}
```

Row shows: order number · status badge · payment-status badge · item count · placed-at · total. Tap → §6.

---

## Page 6 — Order Detail (authenticated)

```
GET /customer/orders/{orderId}
Headers: X-Tenant-Id, Authorization: Bearer <token>
```

**Response (`ApiResponse<CustomerOrderResponseDto>`):**

```json
{
  "success": true,
  "data": {
    "orderId":        "f281e41d-…",
    "orderNumber":    "ORD-…",
    "orderStatus":    "DELIVERED",
    "paymentStatus":  "PAID",
    "paymentMethod":  "COD",
    "currencyCode":   "SYP",
    "subtotal":       125000,
    "discountAmount":  12500,
    "taxAmount":           0,
    "shippingCost":    25000,
    "total":          137500,
    "shippingAddress": { "latitude": 33.5012, "longitude": 36.2901, "recipientName": "…", "phone": "…", "addressLabel": "…" },
    "notesCustomer":  "…",
    "placedAt":       "2026-05-29T…",
    "items": [
      { "orderItemId": "…", "variantId": "…", "productTitle": "…", "variantTitle": "…", "sku": "…",
        "quantity": 2, "unitPrice": 62500, "discountAmount": 0, "totalPrice": 125000 }
    ],
    "timeline": [
      { "timelineId": "…", "action": "ORDER_CREATED",  "actor": "CUSTOMER", "details": null, "createdAt": "…" },
      { "timelineId": "…", "action": "ORDER_CONFIRMED","actor": "MERCHANT", "details": null, "createdAt": "…" },
      { "timelineId": "…", "action": "ORDER_SHIPPED",  "actor": "MERCHANT", "details": null, "createdAt": "…" },
      { "timelineId": "…", "action": "ORDER_DELIVERED","actor": "MERCHANT", "details": null, "createdAt": "…" }
    ]
  }
}
```

Errors: **404** if the order doesn't exist *or* belongs to another customer (don't differentiate — same UX message).

### Actions on the order-detail page

| Action | When to show | Endpoint |
| --- | --- | --- |
| **Track shipment** | Always | embed §Shipment-Track (`/public/shipping/track/{orderId}`) |
| **Cancel order** | `orderStatus ∈ { PENDING, CONFIRMED }` | §7 |
| **Download invoice** | `orderStatus ∈ { CONFIRMED, PROCESSING, SHIPPED, DELIVERED, COMPLETED }` | §8 |
| **Request return** | `orderStatus == DELIVERED` | RET module — out of scope here |

---

## Page 7 — Cancel Order

Confirm-dialog → call cancel.

```
POST /customer/orders/{orderId}/cancel
Headers: X-Tenant-Id, Authorization: Bearer <token>
Content-Type: application/json
```

**Body (optional, `CancelOrderRequestDto`):**

```json
{ "reason": "غيّرت رأيي" }
```

**Response (`ApiResponse<CustomerOrderResponseDto>`):** same as §6 with `orderStatus: "CANCELLED"` and a new timeline entry.

**Failure cases:**
- 400 if the order is not cancellable (shipped/delivered/already-cancelled). Surface the `message`.

---

## Page 8 — Order Invoice

```
GET /customer/orders/{orderId}/invoice
Headers: X-Tenant-Id, Authorization: Bearer <token>
```

**Response (`ApiResponse<InvoiceResponseDto>`):**

```json
{
  "success": true,
  "data": {
    "invoiceId":     "…",
    "orderId":       "…",
    "invoiceNumber": "INV-ORD-1713091200000",
    "pdfUrl":        "https://…/invoice/INV-….pdf",
    "generatedAt":   "2026-05-29T…"
  }
}
```

Open `pdfUrl` in the system browser / PDF viewer. The URL is publicly downloadable by anyone who has it.

**Failure cases:**
- 404 if the invoice hasn't been generated yet for this order (merchant hasn't issued it).

---

# Shipment Module

The customer-visible shipment surface is two things:

1. A **shipping cost quote** during checkout — already covered in §2.2 (`POST /public/shipping/calculate`).
2. A **track-shipment card** rendered on the order detail and the guest tracking page.

## Page (embedded) — Shipment Tracking

```
GET /public/shipping/track/{orderId}
Headers: X-Tenant-Id
```

`orderId` is the **order UUID** (not the order number). On the guest-tracking flow, get it from the §4 lookup response. On the authenticated order detail, you already have it.

**Response (`ApiResponse<CustomerShipmentStatusResponseDto>`):**

```json
{
  "success": true,
  "data": {
    "shipmentId":             "…",
    "orderId":                "…",
    "shipmentStatus":         "IN_TRANSIT",
    "statusLabel":            "قيد التوصيل",            // server-rendered, optional fallback
    "carrierTrackingUrl":     "https://carrier.example/track/AB-123",
    "officePickupInstructions": null,                   // only when status == READY_FOR_PICKUP_AT_OFFICE
    "deliveredAt":            null,                     // set when DELIVERED
    "createdAt":              "2026-05-29T…",
    "statusHistory": [
      { "status": "PENDING",    "timestamp": "2026-05-29T16:50:17" },
      { "status": "PICKED_UP",  "timestamp": "2026-05-29T18:00:00" },
      { "status": "IN_TRANSIT", "timestamp": "2026-05-30T09:00:00" }
    ]
  }
}
```

| State | Render |
| --- | --- |
| 200 with data | Status badge (use the `ShipmentStatus` enum), `statusLabel`, the history timeline, the carrier link (if present), and the office-pickup instructions when `shipmentStatus == "READY_FOR_PICKUP_AT_OFFICE"`. |
| **404** ("Shipment not found") | The order has no shipment yet. Render a calm empty state — "لم تبدأ عملية الشحن بعد." **Do not toast.** This is the normal pre-shipment state. |
| Other error | Hide the card (don't block the rest of the order detail). |

> The endpoint is **public** so it works for both the guest tracking page and the authenticated order detail.

---

# Payment Module

## On-checkout method picker — covered in §2.1

`GET /public/payments/methods` returns the methods the merchant has configured. Use the `providerCode` as `paymentMethod` in §2.4.

## COD flow (fully working)

1. Customer picks `COD` at checkout → `paymentMethod: "COD"`.
2. Order is created with `orderStatus: "PENDING"`, `paymentStatus: "UNPAID"`.
3. Customer waits for delivery. The merchant marks the order paid via the admin app — no customer-facing API call required on the mobile side.

The order detail will reflect `paymentStatus: "PAID"` after the merchant confirms delivery; just refresh the detail or rely on push notifications (NTF module).

## Online (Paymera) flow — **INCOMPLETE — contract gap**

The backend supports Paymera end-to-end (provider creates the payment + redirect URL, webhook handles the result, `POST /webhooks/payments/{providerCode}` confirms via signed callback), but **the customer client has no public endpoint that returns the redirect URL after a successful checkout**.

- `POST /public/checkout` returns `OrderDetailResponseDto`, which has no `redirectUrl` / `paymentSessionUrl` field.
- There is no documented `POST /public/payments/orders/{orderId}/start` (or equivalent) yet.
- Internally `PaymeraPaymentProvider.createPayment(...)` does produce a redirect URL (`CreatePaymentResult.redirectUrl`), but it isn't surfaced.

**Until that contract is added on the backend, mobile should:**

- Treat any method with `requiresRedirect: true` as **disabled** in the UI ("قريباً"), and **only allow `COD`** for now.
- Filter the §2.1 response to `requiresRedirect: false` and silently drop the rest.

**Once backend exposes the redirect URL**, the expected client flow is:

1. `POST /public/checkout` with `paymentMethod: "PAYMERA"` → response includes (TBD) a `paymentRedirectUrl` and `paymentTransactionId`.
2. Open `paymentRedirectUrl` in an in-app browser / Chrome Custom Tab. Provider handles capture.
3. After the provider redirects back, **poll status** until terminal:

```
GET /public/payments/{txnId}/status
Headers: X-Tenant-Id
```

**Response (`ApiResponse<PaymentStatusResult>`):**

```json
{
  "success": true,
  "data": {
    "status": "PAID",        // PENDING | PAID | FAILED | UNPAID  (Paymera maps P/A/F/C → these)
    "rrn":    "RRN12345",    // bank reference
    "amountMinor": 13750000, // SYP * 100 (provider's minor unit)
    "rawResponse": "…"       // provider raw JSON; usually ignore on the client
  }
}
```

Poll every 2–5s with a max ~30s, then navigate to §6 / §3 with the updated order. (The merchant gets the webhook in parallel, so the order's `paymentStatus` will flip to `PAID` server-side regardless of polling.)

---

# Quick-reference endpoint table

| # | Page / Use | Method | Path | Auth | Body / Params |
| --- | --- | --- | --- | --- | --- |
| §2.1 | Checkout — payment methods | GET | `/public/payments/methods` | public | — |
| §2.2 | Checkout — shipping cost | POST | `/public/shipping/calculate` | public | `ShippingCostRequestDto` |
| §2.3 | Checkout — validate discount | GET | `/public/checkout/validate-discount?code=&subtotal=&shippingCost=` | public | query |
| §2.4 | Checkout — place order | POST | `/public/checkout` | public (or bearer-optional) | `CheckoutRequestDto` |
| §4 | Guest order tracking | GET | `/public/checkout/orders/lookup?orderNumber=&email=` | public | query |
| §5 | My orders list | GET | `/customer/orders?page=&size=&status=` | bearer | query |
| §6 | My order detail | GET | `/customer/orders/{orderId}` | bearer | — |
| §7 | Cancel my order | POST | `/customer/orders/{orderId}/cancel` | bearer | `{ reason? }` |
| §8 | My order invoice | GET | `/customer/orders/{orderId}/invoice` | bearer | — |
| Shipment | Track shipment | GET | `/public/shipping/track/{orderId}` | public | — |
| Payment | Poll payment status | GET | `/public/payments/{txnId}/status` | public | — |

---

# Known backend gaps the mobile team should be aware of

1. **Paymera (online) redirect URL** isn't exposed on the public checkout response — see §Payment-Online. Track via backend.
2. **Media URLs** (product images) may carry stale absolute hosts (e.g. a dead ngrok URL from `application-local.yml`). Mobile should treat any URL containing `/api/v1/public/media/` as **served by the API origin** and rewrite the host accordingly — i.e. take the path portion and prefix with the configured API base origin. (The web storefront does this via a `resolveMediaUrl` helper.) Likewise thumbnails (`_150.png`, `_300.png`, `_600.png`) aren't always generated — fall back to the full image URL on load error.
3. **Multi-tenancy header**: every public call needs `X-Tenant-Id`. Missing/blank → `403 ACCESS_DENIED` ("Tenant context missing"). Resolve the tenant UUID once at app start from the store slug and cache.
