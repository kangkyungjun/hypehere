/// GICS 섹터명 축약 — 좁은 폭에 7~11개가 병렬로 놓이는 곳 전용.
///
/// 서버는 `Consumer Discretionary` 같은 전체 이름을 내려준다. 섹터 막대차트는
/// 402pt 화면에서 7열을 나눠 쓰므로 열당 ~50pt뿐이고, 전체 이름을 넣으면
/// **단어 중간에서 끊긴다**(`Consum / er Discre…`). 끊긴 조각은 읽히지 않는다.
///
/// 이 사전은 원래 `models/news_data.dart` 안에 private으로 갇혀 있었다.
/// 같은 문제를 가진 다른 화면이 재사용할 수 없어 각자 잘라 쓰고 있었다.
library;

const _abbreviations = <String, String>{
  'Technology': 'Tech',
  'Information Technology': 'Tech',
  'Healthcare': 'Health',
  'Health Care': 'Health',
  'Consumer Cyclical': 'Cyclical',
  'Consumer Defensive': 'Defensive',
  'Consumer Discretionary': 'Discret.',
  'Consumer Staples': 'Staples',
  'Communication Services': 'Comm',
  'Financial Services': 'Finance',
  'Financials': 'Finance',
  'Industrials': 'Indust.',
  'Energy': 'Energy',
  'Utilities': 'Util.',
  'Real Estate': 'RE',
  'Basic Materials': 'Materials',
  'Materials': 'Materials',
};

/// 축약형을 돌려준다. 사전에 없으면 원문 그대로.
///
/// 사전에 없는 값은 서버가 새 섹터명을 내려준 경우다 — 원문을 그대로 보여
/// 잘못된 축약을 지어내지 않는다.
String shortSectorName(String sector) => _abbreviations[sector] ?? sector;

/// 축약해도 한 줄에 안 들어갈 만큼 긴가? (진단·테스트용)
bool sectorNameFitsOneLine(String sector, {int maxChars = 10}) =>
    shortSectorName(sector).length <= maxChars;
