#!/usr/bin/env python3
"""
Script to add translations for Cookie Policy and Community Guidelines
to django.po files for English, Japanese, and Spanish.
"""

TRANSLATIONS = {
    # Cookie Policy & Community Guidelines translations
    "쿠키 정책": {
        "en": "Cookie Policy",
        "ja": "クッキーポリシー",
        "es": "Política de Cookies"
    },
    "시행일": {
        "en": "Effective Date",
        "ja": "施行日",
        "es": "Fecha de Vigencia"
    },
    "년": {
        "en": "year",
        "ja": "年",
        "es": "año"
    },
    "월": {
        "en": "month",
        "ja": "月",
        "es": "mes"
    },
    "일": {
        "en": "day",
        "ja": "日",
        "es": "día"
    },
    "제1장: 쿠키의 이해": {
        "en": "Chapter 1: Understanding Cookies",
        "ja": "第1章：クッキーの理解",
        "es": "Capítulo 1: Comprensión de las Cookies"
    },
    "제1조 (쿠키란 무엇인가)": {
        "en": "Article 1 (What are Cookies)",
        "ja": "第1条（クッキーとは何か）",
        "es": "Artículo 1 (¿Qué son las Cookies?)"
    },
    "쿠키는 웹사이트를 방문할 때 브라우저에 저장되는 작은 텍스트 파일입니다.": {
        "en": "Cookies are small text files stored in your browser when you visit a website.",
        "ja": "クッキーは、ウェブサイトを訪問したときにブラウザに保存される小さなテキストファイルです。",
        "es": "Las cookies son pequeños archivos de texto almacenados en su navegador cuando visita un sitio web."
    },
    "쿠키는 웹사이트 기능 작동, 사용자 경험 개선, 분석 데이터 제공 등의 목적으로 사용됩니다.": {
        "en": "Cookies are used for website functionality, improving user experience, and providing analytics data.",
        "ja": "クッキーは、ウェブサイトの機能動作、ユーザーエクスペリエンスの向上、分析データの提供などの目的で使用されます。",
        "es": "Las cookies se utilizan para la funcionalidad del sitio web, mejorar la experiencia del usuario y proporcionar datos analíticos."
    },
    "제2조 (쿠키의 종류)": {
        "en": "Article 2 (Types of Cookies)",
        "ja": "第2条（クッキーの種類）",
        "es": "Artículo 2 (Tipos de Cookies)"
    },
    "필수 쿠키": {
        "en": "Essential Cookies",
        "ja": "必須クッキー",
        "es": "Cookies Esenciales"
    },
    "로그인 세션 유지, 보안 등 필수 기능에 사용": {
        "en": "Used for essential functions such as login sessions and security",
        "ja": "ログインセッションの維持、セキュリティなどの必須機能に使用",
        "es": "Utilizadas para funciones esenciales como sesiones de inicio de sesión y seguridad"
    },
    "기능 쿠키": {
        "en": "Functional Cookies",
        "ja": "機能クッキー",
        "es": "Cookies Funcionales"
    },
    "언어 설정, 테마 선택 등 사용자 설정 저장": {
        "en": "Store user preferences such as language settings and theme selection",
        "ja": "言語設定、テーマ選択などのユーザー設定を保存",
        "es": "Almacenan preferencias del usuario como configuración de idioma y selección de tema"
    },
    "분석 쿠키": {
        "en": "Analytics Cookies",
        "ja": "分析クッキー",
        "es": "Cookies de Análisis"
    },
    "사이트 사용 통계 및 성능 분석": {
        "en": "Site usage statistics and performance analysis",
        "ja": "サイト利用統計とパフォーマンス分析",
        "es": "Estadísticas de uso del sitio y análisis de rendimiento"
    },
    "마케팅 쿠키": {
        "en": "Marketing Cookies",
        "ja": "マーケティングクッキー",
        "es": "Cookies de Marketing"
    },
    "관심사 기반 광고 제공": {
        "en": "Provide interest-based advertising",
        "ja": "関心に基づく広告を提供",
        "es": "Proporcionan publicidad basada en intereses"
    },
    "제2장: HypeHere의 쿠키 사용": {
        "en": "Chapter 2: HypeHere's Cookie Usage",
        "ja": "第2章：HypeHereのクッキー使用",
        "es": "Capítulo 2: Uso de Cookies de HypeHere"
    },
    "제3조 (사용하는 쿠키 목록)": {
        "en": "Article 3 (List of Cookies Used)",
        "ja": "第3条（使用するクッキーのリスト）",
        "es": "Artículo 3 (Lista de Cookies Utilizadas)"
    },
    "HypeHere는 다음과 같은 쿠키를 사용합니다:": {
        "en": "HypeHere uses the following cookies:",
        "ja": "HypeHereは以下のクッキーを使用します：",
        "es": "HypeHere utiliza las siguientes cookies:"
    },
    "쿠키 이름": {
        "en": "Cookie Name",
        "ja": "クッキー名",
        "es": "Nombre de la Cookie"
    },
    "목적": {
        "en": "Purpose",
        "ja": "目的",
        "es": "Propósito"
    },
    "유효기간": {
        "en": "Expiration",
        "ja": "有効期限",
        "es": "Expiración"
    },
    "sessionid": {
        "en": "sessionid",
        "ja": "sessionid",
        "es": "sessionid"
    },
    "로그인 세션 유지 (필수)": {
        "en": "Maintain login session (Essential)",
        "ja": "ログインセッションの維持（必須）",
        "es": "Mantener sesión de inicio de sesión (Esencial)"
    },
    "2주": {
        "en": "2 weeks",
        "ja": "2週間",
        "es": "2 semanas"
    },
    "csrftoken": {
        "en": "csrftoken",
        "ja": "csrftoken",
        "es": "csrftoken"
    },
    "보안 (CSRF 공격 방어, 필수)": {
        "en": "Security (CSRF attack protection, Essential)",
        "ja": "セキュリティ（CSRF攻撃防御、必須）",
        "es": "Seguridad (Protección contra ataques CSRF, Esencial)"
    },
    "1년": {
        "en": "1 year",
        "ja": "1年",
        "es": "1 año"
    },
    "django_language": {
        "en": "django_language",
        "ja": "django_language",
        "es": "django_language"
    },
    "언어 설정 저장 (기능)": {
        "en": "Save language preference (Functional)",
        "ja": "言語設定の保存（機能）",
        "es": "Guardar preferencia de idioma (Funcional)"
    },
    "영구 (사용자 삭제 시까지)": {
        "en": "Permanent (until user deletion)",
        "ja": "永続的（ユーザー削除まで）",
        "es": "Permanente (hasta que el usuario lo elimine)"
    },
    "_ga": {
        "en": "_ga",
        "ja": "_ga",
        "es": "_ga"
    },
    "Google Analytics 사용자 식별 (분석)": {
        "en": "Google Analytics user identification (Analytics)",
        "ja": "Google Analyticsユーザー識別（分析）",
        "es": "Identificación de usuario de Google Analytics (Análisis)"
    },
    "2년": {
        "en": "2 years",
        "ja": "2年",
        "es": "2 años"
    },
    "제4조 (쿠키의 목적별 상세 설명)": {
        "en": "Article 4 (Detailed Description by Purpose)",
        "ja": "第4条（目的別詳細説明）",
        "es": "Artículo 4 (Descripción Detallada por Propósito)"
    },
    "필수 쿠키 (Essential Cookies)": {
        "en": "Essential Cookies",
        "ja": "必須クッキー",
        "es": "Cookies Esenciales"
    },
    "서비스 운영에 필수적인 쿠키로, 이 쿠키가 없으면 사이트의 핵심 기능이 작동하지 않습니다.": {
        "en": "Essential cookies for service operation; core site functions won't work without them.",
        "ja": "サービス運営に必須のクッキーで、このクッキーがないとサイトの核心機能が動作しません。",
        "es": "Cookies esenciales para el funcionamiento del servicio; las funciones principales del sitio no funcionarán sin ellas."
    },
    "사용자의 동의 없이 자동 설치됩니다.": {
        "en": "Automatically installed without user consent.",
        "ja": "ユーザーの同意なしに自動的にインストールされます。",
        "es": "Instaladas automáticamente sin el consentimiento del usuario."
    },
    "기능 쿠키 (Functional Cookies)": {
        "en": "Functional Cookies",
        "ja": "機能クッキー",
        "es": "Cookies Funcionales"
    },
    "사용자가 선택한 설정을 기억하여 더 나은 사용 경험을 제공합니다.": {
        "en": "Remember user preferences to provide a better experience.",
        "ja": "ユーザーが選択した設定を記憶し、より良い利用体験を提供します。",
        "es": "Recuerdan las preferencias del usuario para proporcionar una mejor experiencia."
    },
    "이 쿠키를 거부하면 일부 기능이 정상적으로 작동하지 않을 수 있습니다.": {
        "en": "Some features may not work properly if these cookies are rejected.",
        "ja": "このクッキーを拒否すると、一部の機能が正常に動作しない可能性があります。",
        "es": "Algunas funciones pueden no funcionar correctamente si se rechazan estas cookies."
    },
    "분석 쿠키 (Analytics Cookies)": {
        "en": "Analytics Cookies",
        "ja": "分析クッキー",
        "es": "Cookies de Análisis"
    },
    "사이트 방문자 수, 사용 패턴, 오류 발생 등을 분석하여 서비스 품질을 개선하는 데 사용됩니다.": {
        "en": "Used to analyze visitor count, usage patterns, and errors to improve service quality.",
        "ja": "サイト訪問者数、利用パターン、エラー発生などを分析し、サービス品質を向上させるために使用されます。",
        "es": "Utilizadas para analizar el número de visitantes, patrones de uso y errores para mejorar la calidad del servicio."
    },
    "개인을 식별하지 않는 통계 데이터로만 사용됩니다.": {
        "en": "Used only as non-identifying statistical data.",
        "ja": "個人を特定しない統計データとしてのみ使用されます。",
        "es": "Utilizadas solo como datos estadísticos no identificables."
    },
    "마케팅 쿠키 (Marketing Cookies)": {
        "en": "Marketing Cookies",
        "ja": "マーケティングクッキー",
        "es": "Cookies de Marketing"
    },
    "현재 HypeHere는 마케팅 쿠키를 사용하지 않습니다.": {
        "en": "HypeHere currently does not use marketing cookies.",
        "ja": "現在、HypeHereはマーケティングクッキーを使用していません。",
        "es": "HypeHere actualmente no utiliza cookies de marketing."
    },
    "향후 도입 시 사전 동의를 받을 예정입니다.": {
        "en": "Prior consent will be obtained if introduced in the future.",
        "ja": "今後導入する際には事前同意を得る予定です。",
        "es": "Se obtendrá el consentimiento previo si se introducen en el futuro."
    },
    "제3장: 쿠키 관리 및 거부": {
        "en": "Chapter 3: Cookie Management and Rejection",
        "ja": "第3章：クッキー管理と拒否",
        "es": "Capítulo 3: Gestión y Rechazo de Cookies"
    },
    "제5조 (쿠키 설정 방법)": {
        "en": "Article 5 (Cookie Settings)",
        "ja": "第5条（クッキー設定方法）",
        "es": "Artículo 5 (Configuración de Cookies)"
    },
    "브라우저 설정을 통해 쿠키를 관리할 수 있습니다:": {
        "en": "You can manage cookies through browser settings:",
        "ja": "ブラウザ設定を通じてクッキーを管理できます：",
        "es": "Puede gestionar las cookies a través de la configuración del navegador:"
    },
    "Chrome": {
        "en": "Chrome",
        "ja": "Chrome",
        "es": "Chrome"
    },
    "설정 > 개인정보 및 보안 > 쿠키 및 기타 사이트 데이터": {
        "en": "Settings > Privacy and security > Cookies and other site data",
        "ja": "設定 > プライバシーとセキュリティ > Cookieと他のサイトデータ",
        "es": "Configuración > Privacidad y seguridad > Cookies y otros datos del sitio"
    },
    "Firefox": {
        "en": "Firefox",
        "ja": "Firefox",
        "es": "Firefox"
    },
    "설정 > 개인정보 및 보안 > 쿠키 및 사이트 데이터": {
        "en": "Settings > Privacy & Security > Cookies and Site Data",
        "ja": "設定 > プライバシーとセキュリティ > Cookieとサイトデータ",
        "es": "Configuración > Privacidad y seguridad > Cookies y datos del sitio"
    },
    "Safari": {
        "en": "Safari",
        "ja": "Safari",
        "es": "Safari"
    },
    "환경설정 > 개인정보 > 쿠키 및 웹사이트 데이터": {
        "en": "Preferences > Privacy > Cookies and website data",
        "ja": "環境設定 > プライバシー > Cookieとウェブサイトデータ",
        "es": "Preferencias > Privacidad > Cookies y datos de sitios web"
    },
    "Edge": {
        "en": "Edge",
        "ja": "Edge",
        "es": "Edge"
    },
    "설정 > 쿠키 및 사이트 권한 > 쿠키 및 사이트 데이터 관리 및 삭제": {
        "en": "Settings > Cookies and site permissions > Manage and delete cookies and site data",
        "ja": "設定 > Cookieとサイトのアクセス許可 > Cookieとサイトデータの管理と削除",
        "es": "Configuración > Permisos de cookies y sitios > Administrar y eliminar cookies y datos del sitio"
    },
    "제6조 (쿠키 거부 시 영향)": {
        "en": "Article 6 (Impact of Cookie Rejection)",
        "ja": "第6条（クッキー拒否時の影響）",
        "es": "Artículo 6 (Impacto del Rechazo de Cookies)"
    },
    "필수 쿠키를 거부하면 로그인, 세션 유지 등 핵심 기능이 작동하지 않습니다.": {
        "en": "Rejecting essential cookies will prevent core functions like login and session maintenance.",
        "ja": "必須クッキーを拒否すると、ログイン、セッション維持などの核心機能が動作しません。",
        "es": "Rechazar las cookies esenciales impedirá funciones principales como el inicio de sesión y el mantenimiento de sesiones."
    },
    "기능 쿠키를 거부하면 언어 설정, 테마 등이 저장되지 않습니다.": {
        "en": "Rejecting functional cookies means language settings, themes, etc. won't be saved.",
        "ja": "機能クッキーを拒否すると、言語設定、テーマなどが保存されません。",
        "es": "Rechazar las cookies funcionales significa que no se guardarán las configuraciones de idioma, temas, etc."
    },
    "분석 쿠키를 거부해도 서비스 이용에는 영향이 없습니다.": {
        "en": "Rejecting analytics cookies won't affect service usage.",
        "ja": "分析クッキーを拒否してもサービス利用には影響がありません。",
        "es": "Rechazar las cookies de análisis no afectará el uso del servicio."
    },
    "제4장: 개인정보 보호": {
        "en": "Chapter 4: Privacy Protection",
        "ja": "第4章：個人情報保護",
        "es": "Capítulo 4: Protección de Privacidad"
    },
    "제7조 (개인정보 보호법 준수)": {
        "en": "Article 7 (Compliance with Privacy Laws)",
        "ja": "第7条（個人情報保護法の遵守）",
        "es": "Artículo 7 (Cumplimiento de las Leyes de Privacidad)"
    },
    "HypeHere는 대한민국 개인정보 보호법(PIPA)을 준수합니다.": {
        "en": "HypeHere complies with South Korea's Personal Information Protection Act (PIPA).",
        "ja": "HypeHereは大韓民国個人情報保護法（PIPA）を遵守します。",
        "es": "HypeHere cumple con la Ley de Protección de Información Personal de Corea del Sur (PIPA)."
    },
    "쿠키를 통해 수집되는 정보는 서비스 제공 및 개선 목적으로만 사용됩니다.": {
        "en": "Information collected through cookies is used only for service provision and improvement.",
        "ja": "クッキーを通じて収集される情報は、サービス提供および改善の目的でのみ使用されます。",
        "es": "La información recopilada a través de cookies se utiliza solo para la prestación y mejora del servicio."
    },
    "제8조 (제3자 제공 금지)": {
        "en": "Article 8 (Prohibition of Third-Party Disclosure)",
        "ja": "第8条（第三者提供の禁止）",
        "es": "Artículo 8 (Prohibición de Divulgación a Terceros)"
    },
    "쿠키를 통해 수집된 정보는 사용자 동의 없이 제3자에게 제공되지 않습니다.": {
        "en": "Information collected via cookies is not provided to third parties without user consent.",
        "ja": "クッキーを通じて収集された情報は、ユーザーの同意なしに第三者に提供されません。",
        "es": "La información recopilada a través de cookies no se proporciona a terceros sin el consentimiento del usuario."
    },
    "단, 법률에 의해 요구되는 경우는 예외로 합니다.": {
        "en": "Except when required by law.",
        "ja": "ただし、法律により要求される場合は例外とします。",
        "es": "Excepto cuando sea requerido por la ley."
    },
    "제5장: 정책 변경": {
        "en": "Chapter 5: Policy Changes",
        "ja": "第5章：ポリシー変更",
        "es": "Capítulo 5: Cambios de Política"
    },
    "제9조 (쿠키 정책 변경 시 공지)": {
        "en": "Article 9 (Notification of Cookie Policy Changes)",
        "ja": "第9条（クッキーポリシー変更時の通知）",
        "es": "Artículo 9 (Notificación de Cambios en la Política de Cookies)"
    },
    "쿠키 정책이 변경될 경우, 변경 사항을 사이트에 공지하며 변경된 정책은 공지 즉시 효력이 발생합니다.": {
        "en": "When the cookie policy changes, we will announce it on the site, and the updated policy takes effect immediately.",
        "ja": "クッキーポリシーが変更される場合、変更事項をサイトに通知し、変更されたポリシーは通知と同時に効力が発生します。",
        "es": "Cuando cambie la política de cookies, lo anunciaremos en el sitio y la política actualizada entrará en vigor de inmediato."
    },
    "중요한 변경사항의 경우 이메일 또는 사이트 팝업을 통해 별도 안내합니다.": {
        "en": "For significant changes, we will notify you via email or site popup.",
        "ja": "重要な変更事項の場合、メールまたはサイトポップアップを通じて別途案内します。",
        "es": "Para cambios importantes, le notificaremos por correo electrónico o ventana emergente del sitio."
    },
    "제10조 (사용자 권리)": {
        "en": "Article 10 (User Rights)",
        "ja": "第10条（ユーザーの権利）",
        "es": "Artículo 10 (Derechos del Usuario)"
    },
    "사용자는 언제든지 쿠키 설정을 변경하거나 삭제할 권리가 있습니다.": {
        "en": "Users have the right to change or delete cookie settings at any time.",
        "ja": "ユーザーはいつでもクッキー設定を変更または削除する権利があります。",
        "es": "Los usuarios tienen derecho a cambiar o eliminar la configuración de cookies en cualquier momento."
    },
    "쿠키 관련 문의사항이 있으시면 고객지원 팀으로 연락 주시기 바랍니다.": {
        "en": "For cookie-related inquiries, please contact our customer support team.",
        "ja": "クッキー関連のお問い合わせがある場合は、カスタマーサポートチームまでご連絡ください。",
        "es": "Para consultas relacionadas con cookies, póngase en contacto con nuestro equipo de atención al cliente."
    },
    "커뮤니티 가이드라인": {
        "en": "Community Guidelines",
        "ja": "コミュニティガイドライン",
        "es": "Directrices de la Comunidad"
    },
    "최종 수정일": {
        "en": "Last Updated",
        "ja": "最終更新日",
        "es": "Última Actualización"
    },
    "HypeHere는 언어 학습과 문화 교류를 위한 안전하고 건전한 커뮤니티를 만들기 위해 최선을 다하고 있습니다.": {
        "en": "HypeHere is committed to creating a safe and healthy community for language learning and cultural exchange.",
        "ja": "HypeHereは、言語学習と文化交流のための安全で健全なコミュニティを作るために最善を尽くしています。",
        "es": "HypeHere se compromete a crear una comunidad segura y saludable para el aprendizaje de idiomas y el intercambio cultural."
    },
    "모든 사용자는 다음 가이드라인을 준수해야 하며, 위반 시 계정 제재를 받을 수 있습니다.": {
        "en": "All users must comply with the following guidelines, and violations may result in account sanctions.",
        "ja": "すべてのユーザーは以下のガイドラインを遵守する必要があり、違反した場合はアカウント制裁を受ける可能性があります。",
        "es": "Todos los usuarios deben cumplir con las siguientes directrices, y las violaciones pueden resultar en sanciones de cuenta."
    },
    "제1장: 기본 원칙": {
        "en": "Chapter 1: Basic Principles",
        "ja": "第1章：基本原則",
        "es": "Capítulo 1: Principios Básicos"
    },
    "제1조 (존중과 배려)": {
        "en": "Article 1 (Respect and Consideration)",
        "ja": "第1条（尊重と配慮）",
        "es": "Artículo 1 (Respeto y Consideración)"
    },
    "모든 사용자는 서로를 존중하고 배려해야 합니다.": {
        "en": "All users must respect and be considerate of each other.",
        "ja": "すべてのユーザーは互いに尊重し、配慮しなければなりません。",
        "es": "Todos los usuarios deben respetarse y ser considerados entre sí."
    },
    "국적, 인종, 성별, 종교, 언어 능력에 관계없이 모두가 환영받는 환경을 조성합니다.": {
        "en": "Create a welcoming environment for all, regardless of nationality, race, gender, religion, or language ability.",
        "ja": "国籍、人種、性別、宗教、言語能力に関係なく、すべての人が歓迎される環境を作ります。",
        "es": "Crear un ambiente acogedor para todos, independientemente de la nacionalidad, raza, género, religión o habilidad lingüística."
    },
    "차별적이거나 모욕적인 언행은 금지됩니다.": {
        "en": "Discriminatory or offensive language is prohibited.",
        "ja": "差別的または侮辱的な言動は禁止されます。",
        "es": "El lenguaje discriminatorio u ofensivo está prohibido."
    },
    "제2조 (언어 학습 목적 유지)": {
        "en": "Article 2 (Maintain Language Learning Purpose)",
        "ja": "第2条（言語学習目的の維持）",
        "es": "Artículo 2 (Mantener el Propósito de Aprendizaje de Idiomas)"
    },
    "HypeHere는 언어 학습 플랫폼입니다.": {
        "en": "HypeHere is a language learning platform.",
        "ja": "HypeHereは言語学習プラットフォームです。",
        "es": "HypeHere es una plataforma de aprendizaje de idiomas."
    },
    "모든 활동은 언어 학습 및 문화 교류 목적에 부합해야 합니다.": {
        "en": "All activities must align with language learning and cultural exchange purposes.",
        "ja": "すべての活動は、言語学習および文化交流の目的に沿っている必要があります。",
        "es": "Todas las actividades deben estar alineadas con el propósito de aprendizaje de idiomas e intercambio cultural."
    },
    "데이팅, 상업적 홍보, 정치적 선전 등의 목적으로 플랫폼을 사용하는 것은 금지됩니다.": {
        "en": "Using the platform for dating, commercial promotion, political propaganda, etc. is prohibited.",
        "ja": "デート、商業的宣伝、政治的プロパガンダなどの目的でプラットフォームを使用することは禁止されます。",
        "es": "Está prohibido usar la plataforma para citas, promoción comercial, propaganda política, etc."
    },
    "제2장: 금지 행위": {
        "en": "Chapter 2: Prohibited Actions",
        "ja": "第2章：禁止行為",
        "es": "Capítulo 2: Acciones Prohibidas"
    },
    "제3조 (혐오 발언 및 괴롭힘)": {
        "en": "Article 3 (Hate Speech and Harassment)",
        "ja": "第3条（ヘイトスピーチとハラスメント）",
        "es": "Artículo 3 (Discurso de Odio y Acoso)"
    },
    "다음 행위는 엄격히 금지됩니다:": {
        "en": "The following actions are strictly prohibited:",
        "ja": "以下の行為は厳格に禁止されます：",
        "es": "Las siguientes acciones están estrictamente prohibidas:"
    },
    "욕설, 비방, 협박, 인신공격": {
        "en": "Profanity, slander, threats, personal attacks",
        "ja": "暴言、誹謗、脅迫、人身攻撃",
        "es": "Lenguaje ofensivo, calumnias, amenazas, ataques personales"
    },
    "인종, 성별, 종교, 국적 등에 대한 차별 및 혐오 발언": {
        "en": "Discrimination and hate speech based on race, gender, religion, nationality, etc.",
        "ja": "人種、性別、宗教、国籍などに対する差別とヘイトスピーチ",
        "es": "Discriminación y discurso de odio basado en raza, género, religión, nacionalidad, etc."
    },
    "성적 괴롭힘 및 성희롱": {
        "en": "Sexual harassment",
        "ja": "セクシャルハラスメント",
        "es": "Acoso sexual"
    },
    "스토킹 및 지속적인 괴롭힘": {
        "en": "Stalking and persistent harassment",
        "ja": "ストーカーおよび継続的なハラスメント",
        "es": "Acoso persistente y stalking"
    },
    "제4조 (부적절한 콘텐츠)": {
        "en": "Article 4 (Inappropriate Content)",
        "ja": "第4条（不適切なコンテンツ）",
        "es": "Artículo 4 (Contenido Inapropiado)"
    },
    "다음 콘텐츠의 게시, 공유, 전송은 금지됩니다:": {
        "en": "The following content is prohibited from posting, sharing, or transmission:",
        "ja": "以下のコンテンツの投稿、共有、送信は禁止されます：",
        "es": "Está prohibido publicar, compartir o transmitir el siguiente contenido:"
    },
    "음란물, 성적으로 노골적인 콘텐츠": {
        "en": "Pornography, sexually explicit content",
        "ja": "ポルノ、性的に露骨なコンテンツ",
        "es": "Pornografía, contenido sexualmente explícito"
    },
    "폭력적이거나 잔혹한 이미지/영상": {
        "en": "Violent or graphic images/videos",
        "ja": "暴力的または残酷な画像/動画",
        "es": "Imágenes/videos violentos o gráficos"
    },
    "불법 약물, 무기, 위험물 관련 콘텐츠": {
        "en": "Content related to illegal drugs, weapons, hazardous materials",
        "ja": "違法薬物、武器、危険物に関するコンテンツ",
        "es": "Contenido relacionado con drogas ilegales, armas, materiales peligrosos"
    },
    "저작권 침해 자료 (무단 복제, 배포)": {
        "en": "Copyright-infringing materials (unauthorized reproduction, distribution)",
        "ja": "著作権侵害資料（無断複製、配布）",
        "es": "Materiales que infringen derechos de autor (reproducción no autorizada, distribución)"
    },
    "허위 정보, 사기, 피싱 시도": {
        "en": "False information, fraud, phishing attempts",
        "ja": "虚偽情報、詐欺、フィッシングの試み",
        "es": "Información falsa, fraude, intentos de phishing"
    },
    "제5조 (스팸 및 광고)": {
        "en": "Article 5 (Spam and Advertising)",
        "ja": "第5条（スパムと広告）",
        "es": "Artículo 5 (Spam y Publicidad)"
    },
    "다음 행위는 금지됩니다:": {
        "en": "The following actions are prohibited:",
        "ja": "以下の行為は禁止されます：",
        "es": "Las siguientes acciones están prohibidas:"
    },
    "동일하거나 유사한 내용의 반복 게시 (스팸)": {
        "en": "Repeated posting of identical or similar content (spam)",
        "ja": "同一または類似の内容の繰り返し投稿（スパム）",
        "es": "Publicación repetida de contenido idéntico o similar (spam)"
    },
    "무단 상업 광고 및 홍보": {
        "en": "Unauthorized commercial advertising and promotion",
        "ja": "無断商業広告および宣伝",
        "es": "Publicidad comercial no autorizada y promoción"
    },
    "외부 사이트로의 무분별한 링크 공유": {
        "en": "Indiscriminate sharing of external links",
        "ja": "外部サイトへの無差別なリンク共有",
        "es": "Compartir indiscriminadamente enlaces externos"
    },
    "개인정보 수집 시도 (이메일, 전화번호 등)": {
        "en": "Attempts to collect personal information (email, phone number, etc.)",
        "ja": "個人情報収集の試み（メール、電話番号など）",
        "es": "Intentos de recopilar información personal (correo electrónico, número de teléfono, etc.)"
    },
    "제6조 (시스템 악용)": {
        "en": "Article 6 (System Abuse)",
        "ja": "第6条（システムの悪用）",
        "es": "Artículo 6 (Abuso del Sistema)"
    },
    "다음과 같은 시스템 악용 행위는 금지됩니다:": {
        "en": "The following system abuse actions are prohibited:",
        "ja": "以下のようなシステム悪用行為は禁止されます：",
        "es": "Las siguientes acciones de abuso del sistema están prohibidas:"
    },
    "다중 계정 생성 및 악용": {
        "en": "Creating and abusing multiple accounts",
        "ja": "複数のアカウントの作成と悪用",
        "es": "Crear y abusar de múltiples cuentas"
    },
    "봇, 자동화 도구 사용 (공식 승인 제외)": {
        "en": "Using bots or automation tools (unless officially approved)",
        "ja": "ボット、自動化ツールの使用（公式承認を除く）",
        "es": "Usar bots o herramientas de automatización (a menos que estén oficialmente aprobados)"
    },
    "시스템 취약점 악용 시도": {
        "en": "Attempts to exploit system vulnerabilities",
        "ja": "システムの脆弱性を悪用する試み",
        "es": "Intentos de explotar vulnerabilidades del sistema"
    },
    "타인의 계정 무단 접근": {
        "en": "Unauthorized access to others' accounts",
        "ja": "他人のアカウントへの無断アクセス",
        "es": "Acceso no autorizado a cuentas de otros"
    },
    "서비스 과부하 유발 행위": {
        "en": "Actions that cause service overload",
        "ja": "サービス過負荷を引き起こす行為",
        "es": "Acciones que causan sobrecarga del servicio"
    },
    "제3장: 플랫폼별 가이드라인": {
        "en": "Chapter 3: Platform-Specific Guidelines",
        "ja": "第3章：プラットフォーム別ガイドライン",
        "es": "Capítulo 3: Directrices Específicas de la Plataforma"
    },
    "제7조 (게시물 작성 규칙)": {
        "en": "Article 7 (Post Writing Rules)",
        "ja": "第7条（投稿作成ルール）",
        "es": "Artículo 7 (Reglas de Publicación)"
    },
    "게시물은 언어 학습 관련 내용을 포함해야 합니다.": {
        "en": "Posts must include language learning-related content.",
        "ja": "投稿は言語学習関連の内容を含む必要があります。",
        "es": "Las publicaciones deben incluir contenido relacionado con el aprendizaje de idiomas."
    },
    "적절한 언어 태그 (모국어, 학습 언어)를 사용하세요.": {
        "en": "Use appropriate language tags (native language, target language).",
        "ja": "適切な言語タグ（母国語、学習言語）を使用してください。",
        "es": "Use etiquetas de idioma apropiadas (idioma nativo, idioma objetivo)."
    },
    "다른 사용자의 게시물을 무단으로 복사하지 마세요.": {
        "en": "Do not copy other users' posts without permission.",
        "ja": "他のユーザーの投稿を無断でコピーしないでください。",
        "es": "No copie las publicaciones de otros usuarios sin permiso."
    },
    "제8조 (댓글 작성 규칙)": {
        "en": "Article 8 (Comment Writing Rules)",
        "ja": "第8条（コメント作成ルール）",
        "es": "Artículo 8 (Reglas de Comentarios)"
    },
    "건설적이고 도움이 되는 피드백을 제공하세요.": {
        "en": "Provide constructive and helpful feedback.",
        "ja": "建設的で役立つフィードバックを提供してください。",
        "es": "Proporcione comentarios constructivos y útiles."
    },
    "언어 실수는 친절하게 교정해 주세요.": {
        "en": "Correct language mistakes kindly.",
        "ja": "言語の間違いは親切に訂正してください。",
        "es": "Corrija los errores de idioma amablemente."
    },
    "비난보다는 격려하는 태도를 유지하세요.": {
        "en": "Maintain an encouraging attitude rather than criticism.",
        "ja": "非難よりも励ます態度を維持してください。",
        "es": "Mantenga una actitud alentadora en lugar de crítica."
    },
    "제9조 (1:1 채팅 규칙)": {
        "en": "Article 9 (1:1 Chat Rules)",
        "ja": "第9条（1:1チャットルール）",
        "es": "Artículo 9 (Reglas de Chat 1:1)"
    },
    "상대방의 학습 목표와 수준을 존중하세요.": {
        "en": "Respect the other person's learning goals and level.",
        "ja": "相手の学習目標とレベルを尊重してください。",
        "es": "Respete los objetivos de aprendizaje y el nivel de la otra persona."
    },
    "개인정보 (주소, 전화번호, 금융정보 등)를 요구하거나 공유하지 마세요.": {
        "en": "Do not request or share personal information (address, phone number, financial information, etc.).",
        "ja": "個人情報（住所、電話番号、金融情報など）を要求したり共有したりしないでください。",
        "es": "No solicite ni comparta información personal (dirección, número de teléfono, información financiera, etc.)."
    },
    "일방적인 연락을 원하지 않는 상대방의 의사를 존중하세요.": {
        "en": "Respect the other person's wish not to receive unsolicited contact.",
        "ja": "一方的な連絡を望まない相手の意思を尊重してください。",
        "es": "Respete el deseo de la otra persona de no recibir contactos no solicitados."
    },
    "제10조 (익명 채팅 특별 규칙)": {
        "en": "Article 10 (Anonymous Chat Special Rules)",
        "ja": "第10条（匿名チャット特別ルール）",
        "es": "Artículo 10 (Reglas Especiales de Chat Anónimo)"
    },
    "🎭 익명 채팅 (Anonymous Chat) - 특별 주의사항": {
        "en": "🎭 Anonymous Chat - Special Precautions",
        "ja": "🎭 匿名チャット - 特別注意事項",
        "es": "🎭 Chat Anónimo - Precauciones Especiales"
    },
    "⚠️ 개인정보 공유 절대 금지": {
        "en": "⚠️ Absolutely no sharing of personal information",
        "ja": "⚠️ 個人情報の共有は絶対禁止",
        "es": "⚠️ Prohibido absolutamente compartir información personal"
    },
    "익명 채팅에서는 실명, 사진, 위치, 연락처 등 어떠한 개인정보도 공유하지 마세요.": {
        "en": "In anonymous chat, do not share any personal information such as real name, photos, location, contact information, etc.",
        "ja": "匿名チャットでは、実名、写真、位置、連絡先などのいかなる個人情報も共有しないでください。",
        "es": "En el chat anónimo, no comparta ninguna información personal como nombre real, fotos, ubicación, información de contacto, etc."
    },
    "익명성은 언어 학습을 위한 것이며, 개인적인 만남을 요청하거나 외부 연락을 시도하는 것은 금지됩니다.": {
        "en": "Anonymity is for language learning purposes, and requesting personal meetings or attempting external contact is prohibited.",
        "ja": "匿名性は言語学習のためのものであり、個人的な会合を要求したり、外部連絡を試みることは禁止されます。",
        "es": "El anonimato es para fines de aprendizaje de idiomas, y está prohibido solicitar reuniones personales o intentar contacto externo."
    },
    "⚠️ 녹화/스크린샷 금지": {
        "en": "⚠️ Recording/Screenshots prohibited",
        "ja": "⚠️ 録画/スクリーンショット禁止",
        "es": "⚠️ Prohibido grabar/capturar pantalla"
    },
    "상대방의 동의 없이 영상 통화를 녹화하거나 스크린샷을 찍는 것은 불법입니다.": {
        "en": "Recording video calls or taking screenshots without the other person's consent is illegal.",
        "ja": "相手の同意なしにビデオ通話を録画したりスクリーンショットを撮ることは違法です。",
        "es": "Grabar videollamadas o tomar capturas de pantalla sin el consentimiento de la otra persona es ilegal."
    },
    "위반 시 법적 책임을 질 수 있습니다.": {
        "en": "Violations may result in legal liability.",
        "ja": "違反した場合、法的責任を問われる可能性があります。",
        "es": "Las violaciones pueden resultar en responsabilidad legal."
    },
    "⚠️ 부적절한 행동 즉시 신고": {
        "en": "⚠️ Report inappropriate behavior immediately",
        "ja": "⚠️ 不適切な行動を即座に報告",
        "es": "⚠️ Reporte inmediatamente el comportamiento inapropiado"
    },
    "성적인 내용, 괴롭힘, 혐오 발언 등을 경험하면 즉시 대화를 종료하고 신고하세요.": {
        "en": "If you experience sexual content, harassment, hate speech, etc., immediately end the conversation and report it.",
        "ja": "性的な内容、ハラスメント、ヘイトスピーチなどを経験した場合は、すぐに会話を終了して報告してください。",
        "es": "Si experimenta contenido sexual, acoso, discurso de odio, etc., termine inmediatamente la conversación e infórmelo."
    },
    "플랫폼은 사용자 안전을 최우선으로 하며, 위반 시 즉시 조치합니다.": {
        "en": "The platform prioritizes user safety and takes immediate action upon violations.",
        "ja": "プラットフォームはユーザーの安全を最優先し、違反時には即座に対処します。",
        "es": "La plataforma prioriza la seguridad del usuario y toma medidas inmediatas ante violaciones."
    },
    "제11조 (오픈 채팅방 규칙)": {
        "en": "Article 11 (Open Chat Room Rules)",
        "ja": "第11条（オープンチャットルームルール）",
        "es": "Artículo 11 (Reglas de Salas de Chat Abiertas)"
    },
    "방의 주제와 규칙을 준수하세요.": {
        "en": "Adhere to the room's topic and rules.",
        "ja": "ルームのトピックとルールを遵守してください。",
        "es": "Adhiérase al tema y las reglas de la sala."
    },
    "관리자의 안내와 결정을 존중하세요.": {
        "en": "Respect the guidance and decisions of administrators.",
        "ja": "管理者の案内と決定を尊重してください。",
        "es": "Respete la orientación y las decisiones de los administradores."
    },
    "대화를 독점하거나 주제에서 벗어나는 행위를 자제하세요.": {
        "en": "Refrain from monopolizing the conversation or going off-topic.",
        "ja": "会話を独占したり、トピックから外れる行為を控えてください。",
        "es": "Absténgase de monopolizar la conversación o desviarse del tema."
    },
    "제4장: 위반 시 제재 조치": {
        "en": "Chapter 4: Sanctions for Violations",
        "ja": "第4章：違反時の制裁措置",
        "es": "Capítulo 4: Sanciones por Violaciones"
    },
    "제12조 (제재 단계)": {
        "en": "Article 12 (Sanction Levels)",
        "ja": "第12条（制裁段階）",
        "es": "Artículo 12 (Niveles de Sanción)"
    },
    "위반 행위의 심각성에 따라 다음과 같은 제재가 적용됩니다:": {
        "en": "Depending on the severity of the violation, the following sanctions will be applied:",
        "ja": "違反行為の深刻さに応じて、以下の制裁が適用されます：",
        "es": "Dependiendo de la gravedad de la violación, se aplicarán las siguientes sanciones:"
    },
    "1차 위반: 경고": {
        "en": "1st violation: Warning",
        "ja": "第1回違反：警告",
        "es": "1ª violación: Advertencia"
    },
    "시스템 경고 메시지 발송 + 위반 사항 기록": {
        "en": "System warning message sent + violation recorded",
        "ja": "システム警告メッセージ送信 + 違反事項記録",
        "es": "Mensaje de advertencia del sistema enviado + violación registrada"
    },
    "2차 위반: 일시 정지 (1~7일)": {
        "en": "2nd violation: Temporary suspension (1-7 days)",
        "ja": "第2回違反：一時停止（1〜7日）",
        "es": "2ª violación: Suspensión temporal (1-7 días)"
    },
    "계정 일시 정지 + 주요 기능 제한": {
        "en": "Account temporarily suspended + key features restricted",
        "ja": "アカウント一時停止 + 主要機能制限",
        "es": "Cuenta suspendida temporalmente + funciones clave restringidas"
    },
    "3차 위반: 장기 정지 (7~30일)": {
        "en": "3rd violation: Long-term suspension (7-30 days)",
        "ja": "第3回違反：長期停止（7〜30日）",
        "es": "3ª violación: Suspensión a largo plazo (7-30 días)"
    },
    "계정 장기 정지 + 모든 소셜 기능 제한": {
        "en": "Account long-term suspended + all social features restricted",
        "ja": "アカウント長期停止 + すべてのソーシャル機能制限",
        "es": "Cuenta suspendida a largo plazo + todas las funciones sociales restringidas"
    },
    "4차 이상 / 중대한 위반: 영구 차단": {
        "en": "4th or more / Serious violations: Permanent ban",
        "ja": "第4回以上/重大な違反：永久ブロック",
        "es": "4ª o más / Violaciones graves: Prohibición permanente"
    },
    "계정 영구 삭제 + 재가입 불가": {
        "en": "Account permanently deleted + re-registration prohibited",
        "ja": "アカウント永久削除 + 再登録不可",
        "es": "Cuenta eliminada permanentemente + reregistro prohibido"
    },
    "제13조 (즉시 영구 차단 대상)": {
        "en": "Article 13 (Immediate Permanent Ban Cases)",
        "ja": "第13条（即座に永久ブロック対象）",
        "es": "Artículo 13 (Casos de Prohibición Permanente Inmediata)"
    },
    "다음의 경우 경고 없이 즉시 영구 차단됩니다:": {
        "en": "The following cases will result in immediate permanent ban without warning:",
        "ja": "以下の場合は警告なしに即座に永久ブロックされます：",
        "es": "Los siguientes casos resultarán en una prohibición permanente inmediata sin advertencia:"
    },
    "불법 콘텐츠 유포 (아동 성 착취물, 범죄 조장 등)": {
        "en": "Distribution of illegal content (child sexual exploitation material, incitement to crime, etc.)",
        "ja": "違法コンテンツの流布（児童性的搾取物、犯罪教唆など）",
        "es": "Distribución de contenido ilegal (material de explotación sexual infantil, incitación al crimen, etc.)"
    },
    "타인에 대한 명백한 위해 행위 (협박, 스토킹, 개인정보 유출 등)": {
        "en": "Clear harmful acts against others (threats, stalking, personal information leaks, etc.)",
        "ja": "他人に対する明白な害行為（脅迫、ストーカー、個人情報漏洩など）",
        "es": "Actos dañinos claros contra otros (amenazas, acoso, filtración de información personal, etc.)"
    },
    "시스템 해킹 시도 또는 서비스 마비 공격": {
        "en": "System hacking attempts or service disruption attacks",
        "ja": "システムハッキング試みまたはサービス麻痺攻撃",
        "es": "Intentos de piratería del sistema o ataques de interrupción del servicio"
    },
    "제5장: 신고 및 이의 제기": {
        "en": "Chapter 5: Reporting and Appeals",
        "ja": "第5章：報告と異議申し立て",
        "es": "Capítulo 5: Informes y Apelaciones"
    },
    "제14조 (신고 절차)": {
        "en": "Article 14 (Reporting Procedure)",
        "ja": "第14条（報告手続き）",
        "es": "Artículo 14 (Procedimiento de Informe)"
    },
    "가이드라인 위반 사항을 발견하면 다음과 같이 신고할 수 있습니다:": {
        "en": "If you discover guideline violations, you can report them as follows:",
        "ja": "ガイドライン違反を発見した場合、以下のように報告できます：",
        "es": "Si descubre violaciones de las directrices, puede informarlas de la siguiente manera:"
    },
    "게시물/댓글: 콘텐츠의 신고 버튼 클릭": {
        "en": "Posts/Comments: Click the report button on the content",
        "ja": "投稿/コメント：コンテンツの報告ボタンをクリック",
        "es": "Publicaciones/Comentarios: Haga clic en el botón de informe del contenido"
    },
    "채팅: 채팅방 내 신고 기능 사용": {
        "en": "Chat: Use the report function within the chat room",
        "ja": "チャット：チャットルーム内の報告機能を使用",
        "es": "Chat: Use la función de informe dentro de la sala de chat"
    },
    "사용자: 프로필 페이지의 신고 버튼 사용": {
        "en": "User: Use the report button on the profile page",
        "ja": "ユーザー：プロフィールページの報告ボタンを使用",
        "es": "Usuario: Use el botón de informe en la página de perfil"
    },
    "긴급 상황: 고객지원 팀에 직접 연락": {
        "en": "Urgent situations: Contact customer support team directly",
        "ja": "緊急事態：カスタマーサポートチームに直接連絡",
        "es": "Situaciones urgentes: Contacte directamente al equipo de soporte al cliente"
    },
    "신고는 익명으로 처리되며, 신고자 정보는 보호됩니다.": {
        "en": "Reports are processed anonymously, and reporter information is protected.",
        "ja": "報告は匿名で処理され、報告者情報は保護されます。",
        "es": "Los informes se procesan de forma anónima y la información del informante está protegida."
    },
    "허위 신고는 신고자에게 불이익을 초래할 수 있습니다.": {
        "en": "False reports may result in disadvantages for the reporter.",
        "ja": "虚偽報告は報告者に不利益をもたらす可能性があります。",
        "es": "Los informes falsos pueden resultar en desventajas para el informante."
    },
}


def add_translation_to_po_file(po_file_path, msgid, msgstr):
    """Add a translation entry to a django.po file."""
    with open(po_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if translation already exists
    if f'msgid "{msgid}"' in content:
        # Find the msgstr and update it if empty
        import re
        pattern = rf'msgid "{re.escape(msgid)}"\nmsgstr "([^"]*)"'
        match = re.search(pattern, content)
        if match and not match.group(1):  # Only update if msgstr is empty
            content = re.sub(pattern, f'msgid "{msgid}"\nmsgstr "{msgstr}"', content)
            with open(po_file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
    else:
        # Add new translation entry at the end
        with open(po_file_path, 'a', encoding='utf-8') as f:
            f.write(f'\nmsgid "{msgid}"\nmsgstr "{msgstr}"\n')
        return True

    return False


def main():
    """Add all translations to django.po files."""
    locale_base = '/Users/kyungjunkang/PycharmProjects/hypehere/locale'
    languages = ['en', 'ja', 'es']

    stats = {lang: 0 for lang in languages}

    print("🔄 Adding translations to django.po files...\n")

    for korean_text, translations in TRANSLATIONS.items():
        for lang in languages:
            po_file = f"{locale_base}/{lang}/LC_MESSAGES/django.po"
            msgstr = translations[lang]

            if add_translation_to_po_file(po_file, korean_text, msgstr):
                stats[lang] += 1
                print(f"✅ [{lang}] {korean_text[:50]}... → {msgstr[:50]}...")

    print(f"\n✅ Translation addition complete!")
    print(f"\nStatistics:")
    for lang in languages:
        print(f"  - {lang}: {stats[lang]} translations added")

    print(f"\nNext step: Run 'python manage.py compilemessages' to compile translations")


if __name__ == "__main__":
    main()
