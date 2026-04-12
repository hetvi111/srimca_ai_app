# Flutter Android Build Fix - Gradle Cache Corruption (Persistent)

## Steps:
- [x] Previous cleans (caches only)
- [ ] 1. Kill daemon + delete FULL .gradle dir: `Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\*`
- [ ] 2. Delete project builds: `rmdir /s /q android\build`, `rmdir /s /q android\app\build`, `flutter clean`
- [ ] 3. pub get + test build

Progress: Cache recreates bad files. Full Gradle reset needed. Confirm to delete entire ~/.gradle ? Safe, Gradle regenerates.
