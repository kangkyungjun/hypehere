#!/usr/bin/env python3
"""
Script to add translations for settings page legal links
to django.po files for English, Japanese, and Spanish.
"""

import os
import re

# Settings page legal link translations
TRANSLATIONS = {
    "법적 정보": {
        "en": "Legal Information",
        "ja": "法的情報",
        "es": "Información Legal"
    },
    "이용약관": {
        "en": "Terms of Service",
        "ja": "利用規約",
        "es": "Términos de Servicio"
    },
    "개인정보처리방침": {
        "en": "Privacy Policy",
        "ja": "プライバシーポリシー",
        "es": "Política de Privacidad"
    },
}


def add_translation_to_po_file(po_file_path, msgid, msgstr):
    """Add or update a translation entry in a django.po file."""
    with open(po_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to find existing msgid and msgstr
    pattern = rf'msgid "{re.escape(msgid)}"\nmsgstr ""'
    replacement = f'msgid "{msgid}"\nmsgstr "{msgstr}"'

    if re.search(pattern, content):
        # Update existing empty translation
        content = re.sub(pattern, replacement, content)
        print(f"✅ [{os.path.basename(os.path.dirname(po_file_path))}] {msgid} → {msgstr}")
    else:
        # Check if translation already exists with value
        existing_pattern = rf'msgid "{re.escape(msgid)}"\nmsgstr ".*?"'
        if re.search(existing_pattern, content):
            print(f"⏭️  [{os.path.basename(os.path.dirname(po_file_path))}] {msgid} already has translation")
        else:
            print(f"⚠️  [{os.path.dirname(po_file_path)}] {msgid} not found in file")
            return

    with open(po_file_path, 'w', encoding='utf-8') as f:
        f.write(content)


def main():
    """Add all translations to django.po files."""
    locale_base = '/Users/kyungjunkang/PycharmProjects/hypehere/locale'
    languages = ['en', 'ja', 'es']

    print("=== Adding settings page legal link translations ===\n")

    stats = {lang: 0 for lang in languages}

    for korean_text, translations in TRANSLATIONS.items():
        for lang in languages:
            po_file = f"{locale_base}/{lang}/LC_MESSAGES/django.po"
            if not os.path.exists(po_file):
                print(f"❌ File not found: {po_file}")
                continue

            msgstr = translations[lang]
            add_translation_to_po_file(po_file, korean_text, msgstr)
            stats[lang] += 1

    print(f"\n✅ Translation addition complete!")
    print(f"Statistics:")
    for lang in languages:
        print(f"  - {lang}: {stats[lang]} translations added")


if __name__ == "__main__":
    main()
