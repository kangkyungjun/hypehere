#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Fix deleted post/comment translations in all language files
"""

import re

# Translations for each language
TRANSLATIONS = {
    'es': {
        '게시물은 신고에 의해 삭제되었습니다.': 'Esta publicación ha sido eliminada debido a un reporte.',
        '신고로 삭제됨': 'Eliminado por reporte'
    },
    'ja': {
        '게시물은 신고에 의해 삭제되었습니다.': 'この投稿は報告により削除されました。',
        '신고로 삭제됨': '報告により削除'
    },
    'en': {
        '게시물은 신고에 의해 삭제되었습니다.': 'This post has been deleted due to a report.',
        '신고로 삭제됨': 'Deleted by report'
    }
}

def fix_translations(lang_code):
    """Fix translations for a specific language"""
    po_file = f'/Users/kyungjunkang/PycharmProjects/hypehere/locale/{lang_code}/LC_MESSAGES/django.po'

    try:
        with open(po_file, 'r', encoding='utf-8') as f:
            content = f.read()

        translations = TRANSLATIONS[lang_code]

        for korean, translation in translations.items():
            # Remove fuzzy markers and old msgid hints
            content = re.sub(r'#, fuzzy\n#\| msgid[^\n]*\n', '', content)

            # Find and replace the translation
            # Pattern: msgid "KOREAN_TEXT"\nmsgstr "..."
            escaped_korean = re.escape(korean)
            pattern = rf'(msgid "{escaped_korean}"\s*\n)msgstr "[^"]*"'
            replacement = rf'\1msgstr "{translation}"'

            content = re.sub(pattern, replacement, content)
            print(f"[{lang_code}] Fixed: {korean[:30]}... → {translation[:30]}...")

        with open(po_file, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"✓ {lang_code}: Translations fixed successfully")

    except Exception as e:
        print(f"✗ {lang_code}: Error - {e}")

if __name__ == '__main__':
    for lang in ['es', 'ja', 'en']:
        fix_translations(lang)
    print("\n✓ All translations fixed!")
