# RunEarn automated tests

The suite is divided by risk and execution environment.

- `flutter test test/feature`: unit, repository, migration, and widget tests.
- `flutter test test/feature/accounts/data/datasources`: SQLite migrations.
- `flutter test test/feature/accounts/data/repositories`: offline-sync behavior.
- `flutter test integration_test`: integration smoke flows on a desktop host.
- `flutter test integration_test -d <device>`: integration flows on a device.

Before release, run:

```text
flutter test
flutter test integration_test
flutter analyze
flutter build apk --debug
```

Repository sync tests use deterministic fakes and never contact production
Firebase. Migration tests use an isolated in-memory SQLite database.
