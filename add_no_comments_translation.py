#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Add 'No comments yet' translation to djangojs.po files
"""

TRANSLATIONS = {
    'en': {
        'msgid': '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!',
        'msgstr': 'No comments yet. Be the first to comment!'
    },
    'es': {
        'msgid': '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!',
        'msgstr': '¡Aún no hay comentarios. Sé el primero en comentar!'
    },
    'ja': {
        'msgid': '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!',
        'msgstr': 'まだコメントがありません。最初にコメントしてみましょう！'
    }
}

def add_translation(lang_code):
    """Add translation to djangojs.po file"""
    po_file = f'/Users/kyungjunkang/PycharmProjects/hypehere/locale/{lang_code}/LC_MESSAGES/djangojs.po'

    try:
        with open(po_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if translation already exists
        if TRANSLATIONS[lang_code]['msgid'] in content:
            print(f"[{lang_code}] Translation already exists, skipping...")
            return

        # Add new translation entry at the end
        msgid = TRANSLATIONS[lang_code]['msgid']
        msgstr = TRANSLATIONS[lang_code]['msgstr']

        new_entry = f'\n#: templates/base.html:195\nmsgid "{msgid}"\nmsgstr "{msgstr}"\n'

        # Append to file
        with open(po_file, 'a', encoding='utf-8') as f:
            f.write(new_entry)

        print(f"✓ [{lang_code}] Added translation: {msgstr}")

    except Exception as e:
        print(f"✗ [{lang_code}] Error: {e}")

if __name__ == '__main__':
    for lang in ['en', 'es', 'ja']:
        add_translation(lang)
    print("\n✓ All translations added to djangojs.po files!")
