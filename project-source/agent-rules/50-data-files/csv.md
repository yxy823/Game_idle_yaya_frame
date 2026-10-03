# CSV Rules

CSV cells are text until the schema converts them, and headers are part of the schema API.

## Schema

- **[MUST]** CSV header names are schema API. Missing, duplicate and unknown headers are errors unless an explicit extension schema permits them.
- **[PREFER]** Use header-based mapping; positional schemas are acceptable only when deliberately specified.
- **[MUST]** CSV cells start as Strings and use explicit, locale-independent type conversion.
- **[MUST]** Define the encoding, delimiter, decimal, date, boolean-token and newline policies independently of the OS or Excel locale.
- **[MUST]** Numeric text does not use locale thousands separators. Dates use ISO-style or typed semantics defined by the schema.
- **[MUST]** When `FileAccess.get_csv_line()` and `store_csv_line()` are the parser and writer contract, authoring data uses UTF-8 and a delimiter of exactly one character. `get_csv_line()` does not accept `"` as the delimiter, and embedded quotes use doubled-quote escaping.
- **[MUST]** If the authoring CSV exceeds the built-in `FileAccess` contract, convert it at build time to the canonical contract, or select and version an explicit alternative parser. Do not assume that Godot will interpret the wider dialect.

## Structure

- **[PREFER]** Use a formal simple grammar only for small collections of atomic cells. Prefer relation or child tables for variable one-to-many data.
- **[PREFER]** Use explicit columns for fixed compound values.
- **[REVIEW]** If a CSV cell needs nested grammar, several escaping layers, recursive parsing or dynamic maps, reconsider the format.
- **[MUST]** Do not impose a blanket "no multiline CSV fields" rule; quoted fields may legitimately contain line breaks when the parser supports them.
