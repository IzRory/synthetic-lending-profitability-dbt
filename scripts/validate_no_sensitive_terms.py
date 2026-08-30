"""Fail when restricted names, secret patterns, or unsafe artifacts appear in the repository."""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path


RESTRICTED_HASHES = {
    "880646da325848422cc6ff3c2fc269c1cac5c565dfa1607243904f49da0d798f",
    "1705f9e610e51e1fdb146ad12d82117b33599284974bd89552e513e68d08ee9f",
    "2682e7ec264e4877b34ce5b2e313e0f23953f3f7c31e4461feda7a1b11c4f1f5",
    "7cae14b0c0f123b9627a81d18eb10b8eb6ff596849929d798da41a419f9b9dd5",
}
SKIP_DIRECTORIES = {".git", ".venv", "dbt_packages", "logs", "target", "__pycache__"}
BINARY_SUFFIXES = {
    ".duckdb",
    ".gif",
    ".ico",
    ".jpeg",
    ".jpg",
    ".pdf",
    ".png",
    ".pyc",
    ".webp",
}
UNSAFE_SUFFIXES = {".key", ".pem", ".p12", ".pfx"}
SECRET_PATTERNS = {
    "private key material": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "GitHub token": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "cloud access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
}
TOKEN_PATTERN = re.compile(r"[a-z0-9]+")


def restricted_phrase_found(text: str) -> bool:
    tokens = TOKEN_PATTERN.findall(text.lower())
    for size in (1, 2, 3):
        for index in range(0, len(tokens) - size + 1):
            phrase = " ".join(tokens[index : index + size])
            digest = hashlib.sha256(phrase.encode("utf-8")).hexdigest()
            if digest in RESTRICTED_HASHES:
                return True
    return False


def scan_repository(root: Path) -> list[str]:
    findings: list[str] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or any(part in SKIP_DIRECTORIES for part in path.relative_to(root).parts):
            continue
        relative_path = path.relative_to(root).as_posix()
        if path.name == ".env" or path.suffix.lower() in UNSAFE_SUFFIXES:
            findings.append(f"unsafe artifact: {relative_path}")
            continue
        if path.suffix.lower() in BINARY_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if restricted_phrase_found(text):
            findings.append(f"restricted phrase: {relative_path}")
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                findings.append(f"{label}: {relative_path}")
    return findings


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    findings = scan_repository(root)
    if findings:
        print("Sensitive-term validation failed:")
        for finding in findings:
            print(f"- {finding}")
        raise SystemExit(1)
    print("Sensitive-term validation passed: no restricted phrases, secret patterns, or unsafe artifacts found.")


if __name__ == "__main__":
    main()

