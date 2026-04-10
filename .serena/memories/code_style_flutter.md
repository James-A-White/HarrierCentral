# Flutter / Dart Style and Conventions

## UUID Normalisation (Critical)

SQL Server returns `UNIQUEIDENTIFIER` as uppercase; the `uuid` package normalises to lowercase.
Comparing without normalisation silently returns `false`.

- Use `normalizeUuid(string)` or `.asUuid` extension (`lib/util/uuid_utils.dart`, globally exported via `imports.dart`)
- Normalise UUID string params at the **entry point** of every query or service function
- For new UUID fields in Freezed models: use `@UuidConverter()` + `UuidValue` instead of `String`
- Never compare two UUID strings with raw `==` unless both are guaranteed lowercase

## General
- Freezed models for data classes
- Analysis options: `portal/analysis_options.yaml`
