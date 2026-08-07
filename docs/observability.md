# Production observability

RunEarn uses Firebase Crashlytics, Analytics, and Performance Monitoring on
Android and iOS release builds. Collection is disabled in debug/profile builds
and can be switched off by the user under **Settings → Privacy**.

## Data policy

Collected:

- fatal and non-fatal exceptions and stack traces;
- named app screens;
- coarse feature/action/result tokens;
- app initialization and Firestore sync-write timing;
- Firebase's standard device and app diagnostics.

Never attach transaction amounts, balances, descriptions, contributor/member
names, email addresses, account or record IDs, receipt contents, or a Firebase
user ID. New telemetry must go through `AppObservability`; do not call Firebase
telemetry SDKs directly from a feature.

## Release verification

1. Build and install a signed release on a test device.
2. Confirm the Settings privacy switch is enabled.
3. Use Firebase Analytics DebugView only on a dedicated test build/device.
4. Trigger a controlled non-fatal test error and confirm it reaches Crashlytics.
5. Exercise startup and an online sync, then confirm the custom traces
   `app_initialization` and `firestore_sync_write` in Performance Monitoring.
6. Disable the privacy switch and verify that subsequent collection stops.

Do not add a permanent "crash test" control to production UI.
