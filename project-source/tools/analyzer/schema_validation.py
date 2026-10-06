"""Execute the small vocabulary used by result.schema.json, without runtime packages.

The JSON file owns required fields and types. Both runtime readers also enforce
finite JSON and the declared x-equal-lengths extension for paired chart arrays.
"""

import json
import math
from pathlib import Path

SCHEMA = json.loads(Path(__file__).with_name("result.schema.json").read_text(encoding="utf-8"))


def finite_json(value):
    if isinstance(value, dict):
        return all(isinstance(k, str) and finite_json(v) for k, v in value.items())
    if isinstance(value, list):
        return all(finite_json(v) for v in value)
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        try:
            return math.isfinite(value)
        except OverflowError:
            return False  # JSON integers must also fit Godot's finite numeric representation.
    return value is None or isinstance(value, (str, bool, int))


def matches(value, rule):
    if "$ref" in rule:
        rule = SCHEMA["$defs"][rule["$ref"].split("/")[-1]]
    kind = rule.get("type")
    checks = {"object": isinstance(value, dict), "array": isinstance(value, list),
              "string": isinstance(value, str), "boolean": isinstance(value, bool),
              "null": value is None,
              "number": isinstance(value, (int, float)) and not isinstance(value, bool),
              "integer": isinstance(value, (int, float)) and not isinstance(value, bool)
              and math.isfinite(value) and value == math.floor(value)}
    if kind and not checks.get(kind, False):
        return False
    if "const" in rule and value != rule["const"]:
        return False
    if "enum" in rule and value not in rule["enum"]:
        return False
    if "not" in rule and matches(value, rule["not"]):
        return False
    if "if" in rule:
        branch = "then" if matches(value, rule["if"]) else "else"
        if not matches(value, rule.get(branch, {})):
            return False
    if isinstance(value, dict):
        if any(key not in value for key in rule.get("required", [])):
            return False
        properties = rule.get("properties", {})
        for key, item in value.items():
            item_rule = properties.get(key, rule.get("additionalProperties", {}))
            if not matches(item, item_rule):
                return False
        lengths = rule.get("x-equal-lengths", [])
        if lengths and len(value[lengths[0]]) != len(value[lengths[1]]):
            return False
    if isinstance(value, list):
        if len(value) > rule.get("maxItems", len(value)):
            return False
        if not all(matches(item, rule.get("items", {})) for item in value):
            return False
    return True


def validate_result(value):
    if not finite_json(value) or not matches(value, SCHEMA):
        raise ValueError("Invalid Analyzer result schema")
    return value
