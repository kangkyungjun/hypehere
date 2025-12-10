#!/usr/bin/env python
"""
나머지 법적 문서 3개를 데이터베이스에 저장하는 스크립트
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from django.contrib.auth import get_user_model
from accounts.models import LegalDocument
from datetime import date

User = get_user_model()

print("=== 나머지 법적 문서 3개 저장 시작 ===\n")

# 슈퍼유저 가져오기
superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print("❌ 슈퍼유저를 찾을 수 없습니다.")
    exit()

# 기존 문서 삭제
LegalDocument.objects.filter(document_type__in=['privacy', 'cookies', 'community'], language='ko').delete()

# 1. 개인정보처리방침
privacy_content = """
<div class="privacy-intro">
    <p>HypeHere는 이용자의 개인정보를 중요하게 생각하며, 개인정보 보호법 및 정보통신망 이용촉진 및 정보보호 등에 관한 법률 등 관련 법령을 준수하고 있습니다. HypeHere는 개인정보처리방침을 통하여 이용자가 제공하는 개인정보가 어떠한 용도와 방식으로 이용되고 있으며 개인정보보호를 위해 어떠한 조치가 취해지고 있는지 알려드립니다.</p>
</div>

<div class="privacy-section">
    <h2>제1조 (개인정보의 처리 목적)</h2>
    <div class="privacy-article">
        <p>HypeHere는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.</p>

        <h3>1. 회원 가입 및 관리</h3>
        <ul>
            <li>회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증</li>
            <li>회원자격 유지·관리, 서비스 부정이용 방지</li>
            <li>각종 고지·통지, 고충처리 등을 목적으로 개인정보를 처리합니다</li>
        </ul>

        <h3>2. 재화 또는 서비스 제공</h3>
        <ul>
            <li>맞춤형 서비스 제공, 본인인증, 연령인증</li>
            <li>콘텐츠 제공, 서비스 제공</li>
        </ul>

        <h3>3. 마케팅 및 광고에의 활용</h3>
        <ul>
            <li>신규 서비스 개발 및 맞춤 서비스 제공</li>
            <li>이벤트 및 광고성 정보 제공 및 참여 기회 제공</li>
        </ul>
    </div>
</div>

<div class="privacy-section">
    <h2>제2조 (개인정보의 처리 및 보유기간)</h2>
    <div class="privacy-article">
        <p>① HypeHere는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의 받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.</p>
        <p>② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:</p>

        <h3>1. 회원 가입 및 관리</h3>
        <ul>
            <li>보유기간: 회원 탈퇴 시까지</li>
            <li>다만, 관계 법령 위반에 따른 수사·조사 등이 진행중인 경우에는 해당 수사·조사 종료 시까지</li>
        </ul>

        <h3>2. 재화 또는 서비스 제공</h3>
        <ul>
            <li>보유기간: 재화·서비스 공급완료 및 요금결제·정산 완료시까지</li>
            <li>다만, 다음의 사유에 해당하는 경우에는 해당 기간 종료시까지
                <ul>
                    <li>「전자상거래 등에서의 소비자 보호에 관한 법률」에 따른 표시·광고, 계약내용 및 이행 등 거래에 관한 기록: 5년</li>
                    <li>소비자의 불만 또는 분쟁처리에 관한 기록: 3년</li>
                </ul>
            </li>
        </ul>
    </div>
</div>

<div class="privacy-section">
    <h2>제3조 (처리하는 개인정보의 항목)</h2>
    <div class="privacy-article">
        <p>HypeHere는 다음의 개인정보 항목을 처리하고 있습니다:</p>

        <h3>1. 회원 가입 및 관리</h3>
        <ul>
            <li>필수항목: 이메일, 비밀번호, 닉네임</li>
            <li>선택항목: 프로필 사진, 모국어, 학습 목표 언어</li>
        </ul>

        <h3>2. 서비스 이용 과정에서 자동 수집되는 정보</h3>
        <ul>
            <li>IP 주소, 쿠키, 서비스 이용 기록, 방문 기록</li>
            <li>기기정보 (OS, 브라우저 종류)</li>
        </ul>
    </div>
</div>

<div class="privacy-section">
    <h2>제4조 (개인정보의 제3자 제공)</h2>
    <div class="privacy-article">
        <p>① HypeHere는 정보주체의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보 보호법 제17조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.</p>
        <p>② HypeHere는 현재 개인정보를 제3자에게 제공하고 있지 않습니다.</p>
    </div>
</div>

<div class="privacy-section">
    <h2>제5조 (개인정보처리의 위탁)</h2>
    <div class="privacy-article">
        <p>① HypeHere는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:</p>
        <p>② 현재 개인정보 처리 위탁 업체는 없으며, 향후 위탁이 필요한 경우 사전에 공지하고 동의를 받겠습니다.</p>
    </div>
</div>

<div class="privacy-section">
    <h2>제6조 (정보주체의 권리·의무 및 행사방법)</h2>
    <div class="privacy-article">
        <p>정보주체는 HypeHere에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:</p>

        <ol>
            <li>개인정보 열람 요구</li>
            <li>오류 등이 있을 경우 정정 요구</li>
            <li>삭제 요구</li>
            <li>처리정지 요구</li>
        </ol>

        <p>위 권리 행사는 HypeHere에 대해 서면, 전화, 전자우편 등을 통하여 하실 수 있으며, HypeHere는 이에 대해 지체없이 조치하겠습니다.</p>
    </div>
</div>

<div class="privacy-section">
    <h2>제7조 (개인정보의 파기)</h2>
    <div class="privacy-article">
        <p>① HypeHere는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.</p>

        <p>② 개인정보 파기의 절차 및 방법은 다음과 같습니다:</p>

        <h3>1. 파기절차</h3>
        <p>이용자가 입력한 정보는 목적 달성 후 별도의 DB에 옮겨져(종이의 경우 별도의 서류) 내부 방침 및 기타 관련 법령에 따라 일정기간 저장된 후 혹은 즉시 파기됩니다.</p>

        <h3>2. 파기방법</h3>
        <ul>
            <li>전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다</li>
            <li>종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각을 통하여 파기합니다</li>
        </ul>
    </div>
</div>

<div class="privacy-section">
    <h2>제8조 (개인정보의 안전성 확보조치)</h2>
    <div class="privacy-article">
        <p>HypeHere는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:</p>

        <ol>
            <li>관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육 등</li>
            <li>기술적 조치: 개인정보처리시스템 등의 접근권한 관리, 접근통제시스템 설치, 고유식별정보 등의 암호화, 보안프로그램 설치</li>
            <li>물리적 조치: 전산실, 자료보관실 등의 접근통제</li>
        </ol>
    </div>
</div>

<div class="privacy-section">
    <h2>제9조 (개인정보 보호책임자)</h2>
    <div class="privacy-article">
        <p>① HypeHere는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.</p>

        <div class="privacy-highlight">
            <h3>개인정보 보호책임자</h3>
            <p>성명: [담당자명]</p>
            <p>직책: [직책]</p>
            <p>연락처: [이메일주소]</p>
        </div>

        <p>② 정보주체는 HypeHere의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.</p>
    </div>
</div>

<div class="privacy-section">
    <h2>제10조 (개인정보 처리방침 변경)</h2>
    <div class="privacy-article">
        <p>① 이 개인정보처리방침은 2025년 12월 9일부터 적용됩니다.</p>
        <p>② 이전의 개인정보처리방침은 아래에서 확인하실 수 있습니다.</p>
    </div>
</div>
"""

# 2. 쿠키 정책
cookie_content = """
<div class="cookie-intro">
    <p>이 쿠키 정책은 HypeHere(이하 "회사")가 운영하는 웹사이트 및 서비스에서 쿠키 및 유사한 기술을 어떻게 사용하는지 설명합니다.</p>
</div>

<div class="cookie-chapter">
    <h2>제1조 (쿠키란 무엇인가요?)</h2>
    <div class="cookie-article">
        <p>쿠키는 웹사이트를 방문할 때 컴퓨터나 모바일 기기에 저장되는 작은 텍스트 파일입니다. 쿠키는 웹사이트가 귀하의 방문을 기억하고, 귀하의 선호사항을 저장하며, 더 나은 사용자 경험을 제공하는 데 도움이 됩니다.</p>
    </div>
</div>

<div class="cookie-chapter">
    <h2>제2조 (회사가 사용하는 쿠키의 종류)</h2>
    <div class="cookie-article">
        <h3>1. 필수 쿠키</h3>
        <p>이러한 쿠키는 웹사이트가 제대로 작동하는 데 필요하며, 귀하의 시스템에서 비활성화할 수 없습니다.</p>
        <ul>
            <li>세션 관리 쿠키: 로그인 상태를 유지합니다</li>
            <li>보안 쿠키: 사용자 인증 및 보안을 보장합니다</li>
            <li>기능 쿠키: 언어 설정 등 귀하의 선택을 기억합니다</li>
        </ul>

        <h3>2. 성능 쿠키</h3>
        <p>이러한 쿠키는 방문자가 웹사이트를 어떻게 사용하는지에 대한 정보를 수집합니다.</p>
        <ul>
            <li>분석 쿠키: 페이지 방문 수, 트래픽 소스 등을 추적합니다</li>
            <li>오류 쿠키: 웹사이트에서 발생하는 오류를 감지합니다</li>
        </ul>

        <h3>3. 기능 쿠키</h3>
        <p>이러한 쿠키는 웹사이트가 귀하의 선택을 기억하고 향상된 기능을 제공할 수 있게 합니다.</p>
        <ul>
            <li>사용자 설정 쿠키: 테마, 언어 등의 선호사항을 저장합니다</li>
            <li>소셜 미디어 쿠키: 소셜 미디어 공유 기능을 가능하게 합니다</li>
        </ul>
    </div>
</div>

<div class="cookie-chapter">
    <h2>제3조 (쿠키 관리 방법)</h2>
    <div class="cookie-article">
        <p>대부분의 웹 브라우저는 자동으로 쿠키를 허용하지만, 귀하는 브라우저 설정을 통해 쿠키를 관리하거나 차단할 수 있습니다.</p>

        <div class="browser-settings">
            <h3>주요 브라우저별 쿠키 설정 방법:</h3>

            <div class="browser-item">
                <h4>Chrome</h4>
                <ol>
                    <li>브라우저 우측 상단의 메뉴(⋮) 클릭</li>
                    <li>설정 > 개인정보 및 보안 > 쿠키 및 기타 사이트 데이터</li>
                    <li>원하는 옵션 선택</li>
                </ol>
            </div>

            <div class="browser-item">
                <h4>Firefox</h4>
                <ol>
                    <li>브라우저 우측 상단의 메뉴(☰) 클릭</li>
                    <li>설정 > 개인정보 및 보안</li>
                    <li>쿠키 및 사이트 데이터 섹션에서 설정 변경</li>
                </ol>
            </div>

            <div class="browser-item">
                <h4>Safari</h4>
                <ol>
                    <li>환경설정 > 개인정보</li>
                    <li>쿠키 및 웹사이트 데이터 관리</li>
                </ol>
            </div>
        </div>

        <div class="warning-note">
            <p><strong>참고:</strong> 쿠키를 차단하면 일부 웹사이트 기능이 제대로 작동하지 않을 수 있습니다.</p>
        </div>
    </div>
</div>

<div class="cookie-chapter">
    <h2>제4조 (쿠키 정책의 변경)</h2>
    <div class="cookie-article">
        <p>회사는 관련 법령 및 서비스 변경에 따라 이 쿠키 정책을 수시로 개정할 수 있습니다. 쿠키 정책이 변경되는 경우, 변경사항은 웹사이트를 통해 공지됩니다.</p>
        <p><strong>최종 수정일:</strong> 2025년 12월 9일</p>
    </div>
</div>
"""

# 3. 커뮤니티 가이드라인
community_content = """
<div class="guidelines-intro">
    <p>HypeHere 커뮤니티 가이드라인은 모든 사용자가 안전하고 존중받는 환경에서 언어를 학습하고 교류할 수 있도록 만들어졌습니다. 이 가이드라인을 준수함으로써 우리 모두가 긍정적인 학습 커뮤니티를 만들어갈 수 있습니다.</p>
</div>

<div class="guidelines-chapter">
    <h2>제1장 핵심 원칙</h2>

    <div class="guidelines-article">
        <h3>제1조 (존중과 배려)</h3>
        <p>모든 회원은 다른 사용자를 존중하고 배려해야 합니다:</p>
        <ul>
            <li>다른 사용자의 의견과 학습 방식을 존중합니다</li>
            <li>문화적, 언어적 차이를 인정하고 수용합니다</li>
            <li>건설적이고 긍정적인 피드백을 제공합니다</li>
            <li>초보 학습자를 격려하고 지원합니다</li>
        </ul>
    </div>

    <div class="guidelines-article">
        <h3>제2조 (안전한 환경)</h3>
        <p>HypeHere는 모든 사용자에게 안전한 공간을 제공하기 위해 최선을 다합니다:</p>
        <ul>
            <li>괴롭힘, 협박, 스토킹은 절대 용납되지 않습니다</li>
            <li>개인정보 보호를 최우선으로 합니다</li>
            <li>부적절한 행동을 신고할 수 있는 시스템을 제공합니다</li>
        </ul>
    </div>
</div>

<div class="guidelines-chapter">
    <h2>제2장 금지 행위</h2>

    <div class="guidelines-article">
        <h3>제3조 (혐오 표현 및 차별)</h3>
        <p>다음과 같은 행위는 엄격히 금지됩니다:</p>
        <ul>
            <li>인종, 민족, 국적에 대한 차별적 발언</li>
            <li>성별, 성적 지향에 대한 혐오 표현</li>
            <li>종교, 장애에 대한 비하 또는 조롱</li>
            <li>연령, 외모에 대한 차별</li>
        </ul>

        <div class="warning-box">
            <p><strong>처벌:</strong> 혐오 표현은 경고 없이 즉시 계정 정지될 수 있습니다.</p>
        </div>
    </div>

    <div class="guidelines-article">
        <h3>제4조 (괴롭힘 및 위협)</h3>
        <p>다음 행위는 금지됩니다:</p>
        <ul>
            <li>반복적인 원치 않는 메시지 전송</li>
            <li>협박, 위협, 스토킹</li>
            <li>타인의 개인정보 무단 공개 (신상 털기)</li>
            <li>허위 사실 유포</li>
        </ul>
    </div>

    <div class="guidelines-article">
        <h3>제5조 (부적절한 콘텐츠)</h3>
        <p>다음과 같은 콘텐츠의 게시는 금지됩니다:</p>
        <ul>
            <li>음란물, 성적으로 노골적인 콘텐츠</li>
            <li>폭력적이거나 충격적인 이미지/영상</li>
            <li>불법 약물, 무기 관련 콘텐츠</li>
            <li>자해, 자살을 조장하는 콘텐츠</li>
        </ul>
    </div>

    <div class="guidelines-article">
        <h3>제6조 (스팸 및 상업적 활동)</h3>
        <p>다음 행위는 금지됩니다:</p>
        <ul>
            <li>무분별한 광고 게시</li>
            <li>피라미드, 다단계 홍보</li>
            <li>무단 상업적 메시지 전송</li>
            <li>반복적인 동일 콘텐츠 게시</li>
        </ul>
    </div>
</div>

<div class="guidelines-chapter">
    <h2>제3장 건전한 사용</h2>

    <div class="guidelines-article">
        <h3>제7조 (콘텐츠 작성 가이드)</h3>
        <p>양질의 콘텐츠를 위한 권장사항:</p>
        <ul>
            <li>명확하고 정확한 정보를 제공하세요</li>
            <li>적절한 언어와 표현을 사용하세요</li>
            <li>저작권을 존중하고, 출처를 명시하세요</li>
            <li>건설적인 토론에 참여하세요</li>
        </ul>
    </div>

    <div class="guidelines-article">
        <h3>제8조 (채팅 예절)</h3>
        <p>실시간 채팅 시 지켜야 할 사항:</p>
        <ul>
            <li>상대방의 학습 수준을 고려하여 대화하세요</li>
            <li>인내심을 갖고 실수를 교정해 주세요</li>
            <li>개인적인 질문은 신중하게 하세요</li>
            <li>대화 시간대를 존중하세요</li>
        </ul>
    </div>
</div>

<div class="guidelines-chapter">
    <h2>제4장 신고 및 제재</h2>

    <div class="guidelines-article">
        <h3>제9조 (신고 시스템)</h3>
        <p>부적절한 행동을 목격하셨다면:</p>
        <ol>
            <li>해당 게시물이나 메시지의 신고 버튼을 클릭하세요</li>
            <li>신고 사유를 선택하고 상세 내용을 작성하세요</li>
            <li>관리팀이 24시간 내에 검토합니다</li>
            <li>필요 시 추가 정보를 요청할 수 있습니다</li>
        </ol>

        <p><strong>허위 신고</strong>는 오히려 신고자에게 불이익을 줄 수 있습니다.</p>
    </div>

    <div class="guidelines-article">
        <h3>제10조 (제재 단계)</h3>
        <div class="sanction-levels">
            <div class="sanction-item">
                <h4>1단계: 경고</h4>
                <p>첫 번째 경미한 위반 시 경고 메시지가 발송됩니다.</p>
            </div>

            <div class="sanction-item">
                <h4>2단계: 일시 정지</h4>
                <p>반복적인 위반이나 중대한 위반 시 7일~30일 계정 정지가 적용됩니다.</p>
            </div>

            <div class="sanction-item severe">
                <h4>3단계: 영구 정지</h4>
                <p>심각한 위반이나 반복적인 위반 시 계정이 영구적으로 정지됩니다.</p>
            </div>
        </div>

        <div class="severe-note">
            <p><strong>즉시 영구 정지 대상 행위:</strong></p>
            <ul>
                <li>명백한 혐오 표현</li>
                <li>성적 괴롭힘</li>
                <li>개인정보 무단 공개</li>
                <li>불법 활동 조장</li>
            </ul>
        </div>
    </div>
</div>

<div class="guidelines-footer">
    <h3>맺음말</h3>
    <p>HypeHere 커뮤니티 가이드라인은 모든 사용자가 안전하고 즐겁게 언어를 학습할 수 있는 환경을 만들기 위해 존재합니다. 가이드라인을 준수해 주시는 모든 분들께 감사드리며, 함께 더 나은 커뮤니티를 만들어 갑시다.</p>
    <p><strong>시행일:</strong> 2025년 12월 9일</p>
</div>
"""

# 3개 문서 저장
documents = [
    {'type': 'privacy', 'title': 'HypeHere 개인정보처리방침', 'content': privacy_content},
    {'type': 'cookies', 'title': 'HypeHere 쿠키 정책', 'content': cookie_content},
    {'type': 'community', 'title': 'HypeHere 커뮤니티 가이드라인', 'content': community_content},
]

for doc_data in documents:
    legal_doc = LegalDocument.objects.create(
        document_type=doc_data['type'],
        language='ko',
        title=doc_data['title'],
        content=doc_data['content'].strip(),
        version='1.0',
        is_active=True,
        effective_date=date.today(),
        created_by=superuser,
        modified_by=superuser
    )

    print(f"✅ {doc_data['title']} 저장 완료!")
    print(f"   - 문서 ID: {legal_doc.id}")
    print(f"   - 버전: {legal_doc.version}")
    print(f"   - 콘텐츠 크기: {len(legal_doc.content):,}자\n")

print("\n=== 전체 법적 문서 저장 완료 ===")
print(f"총 {LegalDocument.objects.filter(language='ko', is_active=True).count()}개 문서")
