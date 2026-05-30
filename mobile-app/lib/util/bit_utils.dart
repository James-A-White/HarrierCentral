/// Parse a BIT column value from API JSON.
///
/// The .NET Azure Functions shim serialises SQL Server BIT columns as JSON
/// booleans (true/false), not as integers. The == 1 guard defends against
/// legacy payloads or future API behaviour changes.
///
/// Never use `(json['field'] as int?) == 1` for BIT fields — that throws a
/// TypeError at runtime when the value is a boolean.
bool parseBitField(dynamic value) => value == true || value == 1;
