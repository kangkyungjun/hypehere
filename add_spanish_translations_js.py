#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Spanish Translation Mapper for djangojs.po
Adds Spanish translations to JavaScript translation file
"""

import re
import os

# Complete translation dictionary (Korean -> Spanish)
TRANSLATIONS = {
    # UI Actions & Status
    "즐겨찾기를 불러오는데 실패했습니다.": "No se pudieron cargar los favoritos.",
    "즐겨찾기 해제": "Quitar de favoritos",
    "명": "personas",
    "입장하기": "Entrar",

    # Chat Room Categories
    "언어교환": "Intercambio de idiomas",
    "스터디": "Estudio",
    "문화교류": "Intercambio cultural",
    "질문답변": "Preguntas y respuestas",
    "자유대화": "Conversación libre",

    # General Labels
    "국가": "País",
    "좋아요 취소": "Quitar me gusta",
    "좋아요": "Me gusta",
    "댓글": "Comentarios",

    # Language Names (Keep original for internationalization)
    "한국어": "Coreano",
    "English": "Inglés",
    "日本語": "Japonés",
    "中文": "Chino",
    "Español": "Español",
    "Français": "Francés",
    "Deutsch": "Alemán",
    "Italiano": "Italiano",
    "Português": "Portugués",
    "Русский": "Ruso",

    # Time Units
    "년": "año(s)",
    "개월": "mes(es)",
    "주": "semana(s)",
    "일": "día(s)",
    "시간": "hora(s)",
    "분": "minuto(s)",
    "전": "hace",
    "방금 전": "justo ahora",

    # Error Messages
    "로그인이 필요합니다.": "Inicio de sesión requerido.",
    "좋아요 처리 중 오류가 발생했습니다.": "Ocurrió un error al procesar me gusta.",
    "즐겨찾기를 해제하시겠습니까?": "¿Desea quitar de favoritos?",
    "즐겨찾기 해제에 실패했습니다.": "No se pudo quitar de favoritos.",

    # User Roles
    "방 개설자": "Creador de la sala",
    "관리자": "Administrador",
}

def add_spanish_translations_js(po_file_path):
    """
    Add Spanish translations to djangojs.po file

    Args:
        po_file_path: Path to the djangojs.po file

    Returns:
        int: Number of translations added
    """

    print("=" * 80)
    print("SPANISH TRANSLATION MAPPER FOR DJANGOJS.PO")
    print("=" * 80)
    print(f"Processing: {po_file_path}")
    print(f"Total translations to add: {len(TRANSLATIONS)}")
    print("=" * 80)

    # Read the file
    with open(po_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    translated_count = 0

    # Process each translation
    for korean, spanish in TRANSLATIONS.items():
        # Escape special regex characters in the Korean text
        escaped_korean = re.escape(korean)

        # Pattern to match: msgid "KOREAN_TEXT"\nmsgstr ""
        pattern = rf'(msgid\s+"{escaped_korean}"\s*\n)(msgstr\s+"")'

        # Replacement: msgid "KOREAN_TEXT"\nmsgstr "SPANISH_TEXT"
        replacement = rf'\1msgstr "{spanish}"'

        # Check if pattern exists
        matches = len(re.findall(pattern, content))

        if matches > 0:
            # Replace the pattern
            content = re.sub(pattern, replacement, content)
            translated_count += matches
            print(f"✓ Translated: {korean[:40]}... → {spanish[:40]}... ({matches} occurrence(s))")
        else:
            print(f"⚠ Not found: {korean[:40]}...")

    # Write the updated content back
    with open(po_file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("=" * 80)
    print(f"✓ COMPLETED: {translated_count} translations added successfully!")
    print("=" * 80)

    return translated_count

if __name__ == '__main__':
    # Path to the djangojs.po file
    po_file = '/Users/kyungjunkang/PycharmProjects/hypehere/locale/es/LC_MESSAGES/djangojs.po'

    if not os.path.exists(po_file):
        print(f"Error: File not found - {po_file}")
        exit(1)

    # Add translations
    count = add_spanish_translations_js(po_file)

    print(f"\n✓ Total: {count} Spanish translations added to djangojs.po")
    print("\nNext steps:")
    print("1. Run: python manage.py compilemessages")
    print("2. Test Spanish language mode in browser")
    print("3. Verify all UI elements display correctly")
