#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Missing Spanish Translation Mapper for django.po
Adds the 10 remaining Spanish translations that were missed
"""

import re
import os

# Complete translation dictionary (Korean -> Spanish)
MISSING_TRANSLATIONS = {
    # Account Management - Deletion Warning
    "30일 후 계정과 모든 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.":
        "Su cuenta y todos los datos se eliminarán permanentemente después de 30 días. Esta acción no se puede deshacer.",

    # Account Management - Deletion Confirmation
    " 계속하려면 \"<strong>영구삭제</strong>\"를 입력하세요:":
        " Para continuar, escriba \"<strong>eliminación permanente</strong>\":",

    # Registration - Password Requirements
    "최소 8자 이상, 영문과 숫자를 포함해야 합니다.":
        "Debe tener al menos 8 caracteres e incluir letras y números.",

    # Report History - Moderation Actions
    "게시물 내용을 \\'신고로 삭제됨\\' 메시지로 변경":
        "Cambiar contenido de la publicación a mensaje 'Eliminado por reporte'",

    "신고 상태를 \\'처리완료\\'로 변경":
        "Cambiar estado del reporte a 'Resuelto'",

    "신고 상태를 \\'기각\\'으로 변경":
        "Cambiar estado del reporte a 'Rechazado'",

    # Settings & Support
    "고객지원":
        "Soporte al cliente",

    # Home Page Description (with HTML break tag)
    "HypeHere는 전 세계 사람들과 언어를 교환하며<br>\n                진정한 친구 관계를 만드는 SNS형 플랫폼입니다.":
        "HypeHere es una plataforma tipo SNS donde intercambias idiomas con personas de todo el mundo<br>\n                y construyes amistades genuinas.",

    # Chat Room - Admin Permissions
    "관리자는 다른 사용자를 강퇴하거나 관리자 권한을 부여/해제할 수 있습니다.":
        "Los administradores pueden expulsar a otros usuarios o otorgar/revocar privilegios de administrador.",

    # Post Creation Modal - Placeholder (THE REPORTED ISSUE!)
    "무슨 일이 일어나고 있나요?&#10;&#10;해시태그를 사용하려면 #을 앞에 붙이세요 (예: #한국어학습)":
        "¿Qué está pasando?&#10;&#10;Usa # antes de una palabra para crear un hashtag (ej: #AprendiendoCoreano)",
}

def add_missing_spanish_translations(po_file_path):
    """
    Add missing Spanish translations to django.po file

    Args:
        po_file_path: Path to the django.po file

    Returns:
        int: Number of translations added
    """

    print("=" * 80)
    print("MISSING SPANISH TRANSLATION MAPPER FOR DJANGO.PO")
    print("=" * 80)
    print(f"Processing: {po_file_path}")
    print(f"Total missing translations to add: {len(MISSING_TRANSLATIONS)}")
    print("=" * 80)

    # Read the file
    with open(po_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    translated_count = 0

    # Process each translation
    for korean, spanish in MISSING_TRANSLATIONS.items():
        # Escape special regex characters in the Korean text
        escaped_korean = re.escape(korean)

        # Pattern to match: msgid "KOREAN_TEXT"\nmsgstr ""
        # Handle multi-line msgid entries
        pattern = rf'(msgid\s+"[^"]*{escaped_korean}[^"]*"\s*\n)(msgstr\s+"")'

        # Replacement: msgid "KOREAN_TEXT"\nmsgstr "SPANISH_TEXT"
        replacement = rf'\1msgstr "{spanish}"'

        # Check if pattern exists
        matches = len(re.findall(pattern, content, re.MULTILINE))

        if matches > 0:
            # Replace the pattern
            content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
            translated_count += matches
            print(f"✓ Translated: {korean[:60]}... → {spanish[:60]}... ({matches} occurrence(s))")
        else:
            # Try alternative pattern for multi-line msgid entries
            # Some entries might be split across lines in the .po file
            korean_parts = korean.split('\n')
            if len(korean_parts) > 1:
                # Try matching the first line
                first_line_escaped = re.escape(korean_parts[0])
                pattern2 = rf'(msgid\s+["\'].*{first_line_escaped}.*["\'].*?\n)(msgstr\s+"")'
                matches2 = len(re.findall(pattern2, content, re.MULTILINE | re.DOTALL))

                if matches2 > 0:
                    content = re.sub(pattern2, rf'\1msgstr "{spanish}"', content, flags=re.MULTILINE | re.DOTALL)
                    translated_count += matches2
                    print(f"✓ Translated (multiline): {korean[:60]}... → {spanish[:60]}... ({matches2} occurrence(s))")
                else:
                    print(f"⚠ Not found: {korean[:60]}...")
            else:
                print(f"⚠ Not found: {korean[:60]}...")

    # Write the updated content back
    with open(po_file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("=" * 80)
    print(f"✓ COMPLETED: {translated_count} missing translations added successfully!")
    print("=" * 80)

    return translated_count

if __name__ == '__main__':
    # Path to the django.po file
    po_file = '/Users/kyungjunkang/PycharmProjects/hypehere/locale/es/LC_MESSAGES/django.po'

    if not os.path.exists(po_file):
        print(f"Error: File not found - {po_file}")
        exit(1)

    # Add missing translations
    count = add_missing_spanish_translations(po_file)

    print(f"\n✓ Total: {count} missing Spanish translations added to django.po")
    print("\nNext steps:")
    print("1. Run: python manage.py compilemessages")
    print("2. Restart Django development server")
    print("3. Test Spanish language mode - especially post creation placeholder")
    print("4. Verify all UI elements display correctly")
