"""
Script to modify legal document templates to support conditional rendering (database vs. template content).
Each template will check 'use_database' context variable and display either database content or hardcoded template content.
"""

import re

def modify_template(file_path, title_trans_key):
    """
    Modify a legal template to support conditional rendering.

    Args:
        file_path: Path to the template file
        title_trans_key: Translation key for the document title (e.g., "이용약관")
    """
    print(f"\nModifying {file_path}...")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the {% block content %} line
    content_block_pattern = r'({% block content %})\n'
    match = re.search(content_block_pattern, content)

    if not match:
        print(f"❌ Could not find {'{%'} block content {'%}'} in {file_path}")
        return False

    # Find the closing endblock for content block
    # We'll insert our conditional logic right after block content

    # Split content at block content
    parts = content.split('{' + '% block content %' + '}\n', 1)
    if len(parts) != 2:
        print(f"❌ Could not split content properly in {file_path}")
        return False

    before_content = parts[0] + '{' + '% block content %' + '}\n'
    after_content = parts[1]

    # Now split the after_content to separate the actual content from endblock
    # Find the last endblock which closes the content block
    endblock_pattern = r'\n{' + '% endblock %' + '}'
    matches = list(re.finditer(endblock_pattern, after_content))

    if not matches:
        print(f"❌ Could not find closing endblock in {file_path}")
        return False

    # Get the last {% endblock %} (assuming it closes the content block)
    last_match = matches[-1]
    main_content = after_content[:last_match.start()]
    endblock_part = after_content[last_match.start():]

    # Create the new conditional structure (using concatenation to avoid f-string issues with Django syntax)
    conditional_content = (
        '{' + '% if use_database %' + '}\n'
        '    <!-- Database-driven content -->\n'
        '    <div class="terms-container">\n'
        '        <div class="terms-header">\n'
        '            <h1>{{' + '{ document.title }' + '}}</h1>\n'
        '            <div class="terms-meta">\n'
        '                <p>{' + '% trans "시행일" %' + '}: {{' + '{ document.effective_date|date:"Y년 m월 d일" }' + '}}</p>\n'
        '                <p>{' + '% trans "버전" %' + '}: {{' + '{ document.version }' + '}}</p>\n'
        '            </div>\n'
        '        </div>\n\n'
        '        <div class="terms-content">\n'
        '            {{' + '{ document.content|safe }' + '}}\n'
        '        </div>\n'
        '    </div>\n'
        '{' + '% else %' + '}\n'
        '    <!-- Template fallback content -->\n'
        + main_content + '\n'
        + '{' + '% endif %' + '}'
    )

    # Combine everything
    new_content = before_content + conditional_content + endblock_part

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"✅ Successfully modified {file_path}")
    return True


# Template files to modify
templates = [
    {
        'path': 'accounts/templates/accounts/legal/terms_of_service.html',
        'title': '이용약관'
    },
    {
        'path': 'accounts/templates/accounts/legal/privacy_policy.html',
        'title': '개인정보처리방침'
    },
    {
        'path': 'accounts/templates/accounts/legal/cookie_policy.html',
        'title': '쿠키 정책'
    },
    {
        'path': 'accounts/templates/accounts/legal/community_guidelines.html',
        'title': '커뮤니티 가이드라인'
    }
]

if __name__ == '__main__':
    print("=" * 60)
    print("Modifying legal document templates for conditional rendering")
    print("=" * 60)

    success_count = 0
    for template in templates:
        if modify_template(template['path'], template['title']):
            success_count += 1

    print("\n" + "=" * 60)
    print(f"✅ Successfully modified {success_count}/{len(templates)} templates")
    print("=" * 60)
