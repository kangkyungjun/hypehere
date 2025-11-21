"""
Add more expressions to daily life and self-introduction lessons
Run with: python scripts/add_daily_expressions.py
"""
import os
import sys
import django

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from learning.models import SituationCategory, SituationLesson, SituationExpression


def add_self_introduction_expressions():
    """Add more expressions to self-introduction lesson"""

    # Get the daily category and lesson
    category = SituationCategory.objects.get(code='daily')
    lesson = SituationLesson.objects.get(slug='jagisokaehagi', category=category)

    print(f"Adding expressions to lesson: {lesson.title_ko}")

    # Additional expressions (starting from order 6)
    new_expressions = [
        {
            'expression': '저는 25살입니다.',
            'translation': "I'm 25 years old.",
            'pronunciation': '아임 트웬티 파이브 이어스 올드',
            'situation_context': '나이를 말할 때',
            'vocabulary': [
                {'word': 'years old', 'meaning': '~살', 'example': "I'm 20 years old."},
                {'word': 'age', 'meaning': '나이', 'example': 'What is your age?'},
                {'word': 'number', 'meaning': '숫자', 'example': "What's your phone number?"}
            ],
            'order': 6
        },
        {
            'expression': '저는 컴퓨터 공학을 전공했어요.',
            'translation': 'I majored in Computer Science.',
            'pronunciation': '아이 메이져드 인 컴퓨터 사이언스',
            'situation_context': '전공이나 학업에 대해 이야기할 때',
            'vocabulary': [
                {'word': 'major', 'meaning': '전공하다', 'example': 'What did you major in?'},
                {'word': 'Computer Science', 'meaning': '컴퓨터 공학', 'example': 'I study Computer Science.'},
                {'word': 'study', 'meaning': '공부하다', 'example': 'I study English.'}
            ],
            'order': 7
        },
        {
            'expression': '저는 서울에 살아요.',
            'translation': 'I live in Seoul.',
            'pronunciation': '아이 리브 인 서울',
            'situation_context': '거주 지역을 말할 때',
            'vocabulary': [
                {'word': 'live', 'meaning': '살다, 거주하다', 'example': 'Where do you live?'},
                {'word': 'in', 'meaning': '~에', 'example': 'I live in Korea.'},
                {'word': 'city', 'meaning': '도시', 'example': 'Seoul is a big city.'}
            ],
            'order': 8
        },
        {
            'expression': '가족은 4명이에요.',
            'translation': 'I have a family of four.',
            'pronunciation': '아이 해브 어 패밀리 오브 포',
            'situation_context': '가족 구성원 수를 말할 때',
            'vocabulary': [
                {'word': 'family', 'meaning': '가족', 'example': 'I love my family.'},
                {'word': 'have', 'meaning': '가지고 있다', 'example': 'I have two brothers.'},
                {'word': 'member', 'meaning': '구성원', 'example': 'How many family members?'}
            ],
            'order': 9
        },
        {
            'expression': '저는 외향적이에요.',
            'translation': "I'm outgoing.",
            'pronunciation': '아임 아웃고잉',
            'situation_context': '성격에 대해 설명할 때',
            'vocabulary': [
                {'word': 'outgoing', 'meaning': '외향적인', 'example': 'She is very outgoing.'},
                {'word': 'personality', 'meaning': '성격', 'example': 'He has a good personality.'},
                {'word': 'friendly', 'meaning': '친근한', 'example': 'They are friendly.'}
            ],
            'order': 10
        },
        {
            'expression': '영화 보는 걸 좋아해요.',
            'translation': 'I like watching movies.',
            'pronunciation': '아이 라이크 와칭 무비스',
            'situation_context': '좋아하는 활동에 대해 이야기할 때',
            'vocabulary': [
                {'word': 'like', 'meaning': '좋아하다', 'example': 'I like this song.'},
                {'word': 'watch', 'meaning': '보다', 'example': 'I watch TV.'},
                {'word': 'movie', 'meaning': '영화', 'example': "Let's watch a movie."}
            ],
            'order': 11
        },
        {
            'expression': '연락처 교환할까요?',
            'translation': 'Shall we exchange contact information?',
            'pronunciation': '셸 위 익스체인지 컨택트 인포메이션?',
            'situation_context': '연락처를 주고받고 싶을 때',
            'vocabulary': [
                {'word': 'shall we', 'meaning': '~할까요?', 'example': 'Shall we go?'},
                {'word': 'exchange', 'meaning': '교환하다', 'example': 'Exchange phone numbers.'},
                {'word': 'contact', 'meaning': '연락처', 'example': 'Keep in contact.'}
            ],
            'order': 12
        }
    ]

    added_count = 0
    for expr_data in new_expressions:
        # Check if expression already exists
        if not SituationExpression.objects.filter(lesson=lesson, expression=expr_data['expression']).exists():
            SituationExpression.objects.create(lesson=lesson, **expr_data)
            print(f"  ✅ Added: {expr_data['expression']}")
            added_count += 1
        else:
            print(f"  ⏭️  Skipped (already exists): {expr_data['expression']}")

    print(f"\nAdded {added_count} new expressions to {lesson.title_ko}")
    return added_count


def create_daily_greetings_lesson():
    """Create a new lesson for daily greetings"""

    category = SituationCategory.objects.get(code='daily')

    # Create lesson
    lesson, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='ilsang-insa',
        defaults={
            'title_ko': '일상 인사',
            'title_en': 'Daily Greetings',
            'language': 'EN',
            'order': 3
        }
    )

    if not created:
        print(f"⏭️  Lesson already exists: {lesson.title_ko}")
        return 0

    print(f"✅ Created lesson: {lesson.title_ko}")

    expressions = [
        {
            'expression': '좋은 아침이에요.',
            'translation': 'Good morning.',
            'pronunciation': '굿 모닝',
            'situation_context': '아침에 만났을 때 하는 인사',
            'vocabulary': [
                {'word': 'Good', 'meaning': '좋은', 'example': 'Have a good day.'},
                {'word': 'morning', 'meaning': '아침', 'example': 'I wake up in the morning.'},
                {'word': 'greeting', 'meaning': '인사', 'example': 'Say your greetings.'}
            ],
            'order': 1
        },
        {
            'expression': '안녕하세요.',
            'translation': 'Good afternoon.',
            'pronunciation': '굿 애프터눈',
            'situation_context': '오후에 만났을 때 하는 인사',
            'vocabulary': [
                {'word': 'afternoon', 'meaning': '오후', 'example': 'See you this afternoon.'},
                {'word': 'greet', 'meaning': '인사하다', 'example': 'Greet your friends.'},
                {'word': 'hello', 'meaning': '안녕', 'example': 'Say hello.'}
            ],
            'order': 2
        },
        {
            'expression': '좋은 저녁이에요.',
            'translation': 'Good evening.',
            'pronunciation': '굿 이브닝',
            'situation_context': '저녁에 만났을 때 하는 인사',
            'vocabulary': [
                {'word': 'evening', 'meaning': '저녁', 'example': 'Good evening, everyone.'},
                {'word': 'night', 'meaning': '밤', 'example': 'Good night.'},
                {'word': 'time', 'meaning': '시간', 'example': 'What time is it?'}
            ],
            'order': 3
        },
        {
            'expression': '어떻게 지내세요?',
            'translation': 'How are you?',
            'pronunciation': '하우 아 유?',
            'situation_context': '안부를 물어볼 때',
            'vocabulary': [
                {'word': 'How', 'meaning': '어떻게', 'example': 'How do you do?'},
                {'word': 'are you', 'meaning': '당신은 ~입니까', 'example': 'Are you okay?'},
                {'word': 'doing', 'meaning': '지내는', 'example': 'How are you doing?'}
            ],
            'order': 4
        },
        {
            'expression': '잘 지내요, 감사합니다.',
            'translation': "I'm fine, thank you.",
            'pronunciation': '아임 파인, 땡큐',
            'situation_context': '안부 질문에 대답할 때',
            'vocabulary': [
                {'word': 'fine', 'meaning': '좋은, 괜찮은', 'example': "I'm doing fine."},
                {'word': 'thank you', 'meaning': '감사합니다', 'example': 'Thank you very much.'},
                {'word': 'good', 'meaning': '좋은', 'example': "I'm good."}
            ],
            'order': 5
        },
        {
            'expression': '안녕히 가세요.',
            'translation': 'Goodbye.',
            'pronunciation': '굿바이',
            'situation_context': '헤어질 때 하는 인사',
            'vocabulary': [
                {'word': 'Goodbye', 'meaning': '안녕히 가세요', 'example': 'Goodbye, see you soon.'},
                {'word': 'bye', 'meaning': '잘 가', 'example': 'Bye bye!'},
                {'word': 'farewell', 'meaning': '작별 인사', 'example': 'Say farewell.'}
            ],
            'order': 6
        },
        {
            'expression': '나중에 봐요.',
            'translation': 'See you later.',
            'pronunciation': '씨 유 레이터',
            'situation_context': '다시 만날 예정이 있을 때',
            'vocabulary': [
                {'word': 'see', 'meaning': '보다', 'example': 'See you tomorrow.'},
                {'word': 'later', 'meaning': '나중에', 'example': 'Talk to you later.'},
                {'word': 'soon', 'meaning': '곧', 'example': 'See you soon.'}
            ],
            'order': 7
        },
        {
            'expression': '감사합니다.',
            'translation': 'Thank you.',
            'pronunciation': '땡큐',
            'situation_context': '고마움을 표현할 때',
            'vocabulary': [
                {'word': 'thank', 'meaning': '감사하다', 'example': 'Thank you for your help.'},
                {'word': 'thanks', 'meaning': '고마워요 (비격식)', 'example': 'Thanks a lot!'},
                {'word': 'appreciate', 'meaning': '감사하다 (격식)', 'example': 'I appreciate it.'}
            ],
            'order': 8
        }
    ]

    for expr_data in expressions:
        SituationExpression.objects.create(lesson=lesson, **expr_data)
        print(f"  ✅ Added: {expr_data['expression']}")

    return len(expressions)


def create_shopping_lesson():
    """Create a new lesson for shopping"""

    category = SituationCategory.objects.get(code='daily')

    # Create lesson
    lesson, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='shopping',
        defaults={
            'title_ko': '쇼핑하기',
            'title_en': 'Shopping',
            'language': 'EN',
            'order': 4
        }
    )

    if not created:
        print(f"⏭️  Lesson already exists: {lesson.title_ko}")
        return 0

    print(f"✅ Created lesson: {lesson.title_ko}")

    expressions = [
        {
            'expression': '이거 얼마예요?',
            'translation': 'How much is this?',
            'pronunciation': '하우 머치 이즈 디스?',
            'situation_context': '물건의 가격을 물어볼 때',
            'vocabulary': [
                {'word': 'How much', 'meaning': '얼마', 'example': 'How much does it cost?'},
                {'word': 'is', 'meaning': '~입니다', 'example': 'This is nice.'},
                {'word': 'price', 'meaning': '가격', 'example': "What's the price?"}
            ],
            'order': 1
        },
        {
            'expression': '입어봐도 될까요?',
            'translation': 'Can I try this on?',
            'pronunciation': '캔 아이 트라이 디스 온?',
            'situation_context': '옷을 입어보고 싶을 때',
            'vocabulary': [
                {'word': 'try on', 'meaning': '입어보다', 'example': 'Try on these shoes.'},
                {'word': 'fitting room', 'meaning': '탈의실', 'example': 'Where is the fitting room?'},
                {'word': 'size', 'meaning': '사이즈', 'example': "What's your size?"}
            ],
            'order': 2
        },
        {
            'expression': '더 큰 사이즈 있나요?',
            'translation': 'Do you have a bigger size?',
            'pronunciation': '두 유 해브 어 비거 사이즈?',
            'situation_context': '더 큰 사이즈가 필요할 때',
            'vocabulary': [
                {'word': 'bigger', 'meaning': '더 큰', 'example': 'I need something bigger.'},
                {'word': 'smaller', 'meaning': '더 작은', 'example': 'Do you have smaller?'},
                {'word': 'different', 'meaning': '다른', 'example': 'Show me different colors.'}
            ],
            'order': 3
        },
        {
            'expression': '할인되나요?',
            'translation': 'Is there a discount?',
            'pronunciation': '이즈 데어 어 디스카운트?',
            'situation_context': '할인 여부를 물어볼 때',
            'vocabulary': [
                {'word': 'discount', 'meaning': '할인', 'example': 'Can I get a discount?'},
                {'word': 'sale', 'meaning': '세일, 할인', 'example': 'Is this on sale?'},
                {'word': 'cheaper', 'meaning': '더 싼', 'example': 'Do you have anything cheaper?'}
            ],
            'order': 4
        },
        {
            'expression': '이거 살게요.',
            'translation': "I'll take this.",
            'pronunciation': '아일 테이크 디스',
            'situation_context': '물건을 구매하기로 결정했을 때',
            'vocabulary': [
                {'word': "I'll take", 'meaning': '~을 살게요', 'example': "I'll take two."},
                {'word': 'buy', 'meaning': '사다', 'example': 'I want to buy this.'},
                {'word': 'purchase', 'meaning': '구매하다', 'example': 'I will purchase it.'}
            ],
            'order': 5
        },
        {
            'expression': '카드로 할게요.',
            'translation': "I'll pay by card.",
            'pronunciation': '아일 페이 바이 카드',
            'situation_context': '카드로 결제하고 싶을 때',
            'vocabulary': [
                {'word': 'pay', 'meaning': '지불하다', 'example': 'How would you like to pay?'},
                {'word': 'card', 'meaning': '카드', 'example': 'Do you accept credit cards?'},
                {'word': 'cash', 'meaning': '현금', 'example': 'Can I pay in cash?'}
            ],
            'order': 6
        }
    ]

    for expr_data in expressions:
        SituationExpression.objects.create(lesson=lesson, **expr_data)
        print(f"  ✅ Added: {expr_data['expression']}")

    return len(expressions)


def create_directions_lesson():
    """Create a new lesson for asking directions"""

    category = SituationCategory.objects.get(code='daily')

    # Create lesson
    lesson, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='gil-mutgi',
        defaults={
            'title_ko': '길 묻기',
            'title_en': 'Asking for Directions',
            'language': 'EN',
            'order': 5
        }
    )

    if not created:
        print(f"⏭️  Lesson already exists: {lesson.title_ko}")
        return 0

    print(f"✅ Created lesson: {lesson.title_ko}")

    expressions = [
        {
            'expression': '역이 어디 있어요?',
            'translation': 'Where is the station?',
            'pronunciation': '웨어 이즈 더 스테이션?',
            'situation_context': '역의 위치를 물어볼 때',
            'vocabulary': [
                {'word': 'Where', 'meaning': '어디', 'example': 'Where are you?'},
                {'word': 'station', 'meaning': '역', 'example': 'Go to the station.'},
                {'word': 'location', 'meaning': '위치', 'example': 'What is the location?'}
            ],
            'order': 1
        },
        {
            'expression': '여기서 어떻게 가요?',
            'translation': 'How do I get there from here?',
            'pronunciation': '하우 두 아이 겟 데어 프롬 히어?',
            'situation_context': '가는 방법을 물어볼 때',
            'vocabulary': [
                {'word': 'How', 'meaning': '어떻게', 'example': 'How can I go?'},
                {'word': 'get there', 'meaning': '거기에 가다', 'example': 'How to get there?'},
                {'word': 'from here', 'meaning': '여기서', 'example': 'Start from here.'}
            ],
            'order': 2
        },
        {
            'expression': '여기서 멀어요?',
            'translation': 'Is it far from here?',
            'pronunciation': '이즈 잇 파 프롬 히어?',
            'situation_context': '거리를 물어볼 때',
            'vocabulary': [
                {'word': 'far', 'meaning': '멀다', 'example': 'Is it far away?'},
                {'word': 'close', 'meaning': '가깝다', 'example': 'Is it close?'},
                {'word': 'distance', 'meaning': '거리', 'example': 'What is the distance?'}
            ],
            'order': 3
        },
        {
            'expression': '걸어갈 수 있어요?',
            'translation': 'Can I walk there?',
            'pronunciation': '캔 아이 워크 데어?',
            'situation_context': '걸어갈 수 있는지 물어볼 때',
            'vocabulary': [
                {'word': 'walk', 'meaning': '걷다', 'example': 'I like to walk.'},
                {'word': 'there', 'meaning': '거기에', 'example': 'Go there.'},
                {'word': 'distance', 'meaning': '거리', 'example': 'Walking distance.'}
            ],
            'order': 4
        },
        {
            'expression': '택시 좀 불러주세요.',
            'translation': 'Could you call a taxi?',
            'pronunciation': '쿠드 유 콜 어 택시?',
            'situation_context': '택시를 불러달라고 부탁할 때',
            'vocabulary': [
                {'word': 'call', 'meaning': '부르다, 전화하다', 'example': 'Call me later.'},
                {'word': 'taxi', 'meaning': '택시', 'example': 'Take a taxi.'},
                {'word': 'please', 'meaning': '부탁합니다', 'example': 'Help me, please.'}
            ],
            'order': 5
        },
        {
            'expression': '몇 번 버스 타야 해요?',
            'translation': 'Which bus should I take?',
            'pronunciation': '위치 버스 슈드 아이 테이크?',
            'situation_context': '타야 할 버스 번호를 물어볼 때',
            'vocabulary': [
                {'word': 'which', 'meaning': '어느, 몇', 'example': 'Which one?'},
                {'word': 'bus', 'meaning': '버스', 'example': 'Take the bus.'},
                {'word': 'take', 'meaning': '타다', 'example': 'Take the subway.'}
            ],
            'order': 6
        },
        {
            'expression': '도움 주셔서 감사합니다.',
            'translation': 'Thank you for your help.',
            'pronunciation': '땡큐 포 유어 헬프',
            'situation_context': '도움을 받은 후 감사 인사할 때',
            'vocabulary': [
                {'word': 'thank you', 'meaning': '감사합니다', 'example': 'Thank you so much.'},
                {'word': 'help', 'meaning': '도움', 'example': 'I need help.'},
                {'word': 'appreciate', 'meaning': '감사하다', 'example': 'I appreciate your help.'}
            ],
            'order': 7
        }
    ]

    for expr_data in expressions:
        SituationExpression.objects.create(lesson=lesson, **expr_data)
        print(f"  ✅ Added: {expr_data['expression']}")

    return len(expressions)


def main():
    """Main function to add all new expressions"""
    print("=" * 60)
    print("Adding New Daily Life & Self-Introduction Expressions")
    print("=" * 60)

    total_added = 0

    # 1. Add more expressions to existing self-introduction lesson
    print("\n[1/4] Adding expressions to '자기소개하기' lesson...")
    total_added += add_self_introduction_expressions()

    # 2. Create daily greetings lesson
    print("\n[2/4] Creating '일상 인사' lesson...")
    total_added += create_daily_greetings_lesson()

    # 3. Create shopping lesson
    print("\n[3/4] Creating '쇼핑하기' lesson...")
    total_added += create_shopping_lesson()

    # 4. Create directions lesson
    print("\n[4/4] Creating '길 묻기' lesson...")
    total_added += create_directions_lesson()

    print("\n" + "=" * 60)
    print(f"✅ Added {total_added} new expressions!")
    print("=" * 60)
    print(f"Total Lessons: {SituationLesson.objects.filter(category__code='daily').count()}")
    print(f"Total Expressions: {SituationExpression.objects.filter(lesson__category__code='daily').count()}")
    print("\nYou can now view these in the admin panel or on the learning pages.")


if __name__ == '__main__':
    main()
