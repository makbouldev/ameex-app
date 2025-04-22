# Ameex Logistics Suite

A production-grade delivery and fleet management platform for Ameex Express Logistics, built for the Moroccan last-mile delivery market. The suite covers the full operational cycle: order intake, agency handover, real-time driver tracking across Casablanca, Rabat, Marrakech, Tanger, Fès and Agadir, proof-of-delivery, cash-on-delivery reconciliation, and driver settlement.

## Overview

Ameex Logistics Suite is a single Flutter codebase that serves two distinct user interfaces, shipping simultaneously to Android, iOS, Web and Windows:

- An **administrator console** for dispatchers, agency managers and finance operators.
- A **driver application** optimised for the field, with offline-tolerant navigation, swipe-to-start missions and live telemetry.

Both interfaces share a Supabase-backed data layer with realtime subscriptions, role-based authentication and row-level security enforced at the Postgres level.

## Key capabilities

### Administrator console

- Realtime operations dashboard with 14-day KPI trends, revenue tracking, and live delivery-rate monitoring.
- Order lifecycle management: creation, driver assignment, agency handover confirmation, delivery validation and cash remittance reconciliation.
- Live fleet map built on OpenStreetMap tiles, showing every active driver, destination pin and polyline route.
- Team administration: driver onboarding, zone and vehicle assignment, performance monitoring, secure deletion with foreign-key cleanup.
- Activity feed aggregating all status transitions, cancellations and compensation events.
- Cash-on-delivery workflow with per-driver caisse balances and commission unlocking after agency remittance.

### Driver application

- Mission workflow in three enforced stages: acceptance, agency pickup, client delivery.
- Interactive OpenStreetMap navigation with live geolocation, custom destination pinning and route polyline rendering.
- Live telemetry: current speed, distance travelled, remaining distance, ETA.
- Personal wallet with available balance, pending commissions locked until agency remittance, and withdrawal action.
- Delivery history with per-order earnings breakdown and compensation tracking.
- Driver profile with online/offline status toggle and vehicle configuration.

### Financial model

- Separation of principal (merchant cash collected on delivery) from driver commission.
- Commissions remain locked while cash is in the driver's possession and are automatically released when agency receipt is validated by the administrator.
- Compensation policy for deliveries cancelled after 50% progress — the driver keeps full commission to cover fuel and time.

## Technology stack

- **Flutter** 3.x for cross-platform UI (Web, Android, iOS, Windows).
- **Supabase** for authentication (GoTrue), Postgres data layer, realtime streams and row-level security.
- **OpenStreetMap** tiles via `flutter_map` and `latlong2` — no proprietary map SDK, no per-request pricing.
- **Geolocator** for native GPS access with IP-based fallback for web.
- **Plus Jakarta Sans** as the primary typeface.

## Brand identity

- Primary brand blue: `#14307A`
- Midnight navy: `#04205F`
- Deep contrast navy: `#0A192F`
- Surface: `#F7F8FA`
- Text: `#0E1116` primary, `#6B7280` secondary

Design language is intentionally restrained: light surfaces, soft layered shadows, premium analytics tiles with trend indicators, and a signature gradient hero card used sparingly for high-value information (wallet, revenue summary, profile identity).

## Project structure

```
lib/
  main.dart                       Entry point, Supabase init, role-based routing
  theme/
    ameex_theme.dart              Design tokens, Material 3 theme, brand constants
  screens/
    login_screen.dart             Sign-in flow with friendly error translation
    admin_dashboard_screen.dart   Administrator console (5 tabs)
    driver_home_screen.dart       Driver application (4 tabs)
    add_order_screen.dart         Order creation form
    add_driver_screen.dart        Driver onboarding form
    route_history_screen.dart     Order lifecycle timeline
    live_tracking_screen.dart     Shared live-tracking map
  widgets/
    ameex_ui.dart                 Reusable UI primitives (dialog, empty state,
                                  splash, animated number, sparkline, skeleton)
    ameex_animations.dart         Page transitions and entry animations
    driver_avatar.dart            Driver avatar component
    caisse_remittance_helper.dart COD reconciliation logic
web/
  index.html                      Branded bootstrap splash
```

## Installation

Prerequisites: Flutter 3.5 or higher, a configured Supabase project.

```bash
git clone https://github.com/makbouldev/ameex-app.git
cd ameex-app
flutter pub get
```

## Running the application

Debug mode (development):

```bash
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d windows       # Windows desktop
```

Production build:

```bash
flutter run -d chrome --release
flutter build apk --release
flutter build web --release
```



## Test credentials

| Role | Email | Password |
|------|-------|----------|
| Driver (demo) | `youssef.idrissi@ameex.ma` | `driver123456` |



