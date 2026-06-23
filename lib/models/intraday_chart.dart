/// 시간봉(intraday) 차트 데이터.
/// 서버 GET /api/v1/charts/{ticker}/intraday[?interval=1h] 와 1:1.
///
/// date는 ET ISO-8601 그대로 보관(예 "2026-06-18T09:30:00-04:00").
/// 표시 시 dateTime 게터로 변환해 사용.
class IntradayBar {
  final String date; // ET ISO-8601
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final int? volume;

  const IntradayBar({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  });

  /// DateTime.parse는 ISO-8601 datetime/date 둘 다 처리.
  /// 주의: TZ 오프셋이 박힌 ISO 문자열도 UTC 인스턴트로 정규화되어,
  /// .hour/.minute는 단말 로컬 TZ 기준 환산값을 반환. ET 시·분을
  /// 그대로 쓰려면 etHour/etMinute를 사용하라.
  DateTime get dateTime => DateTime.parse(date);

  /// ET 시각의 hour (0..23). 서버가 ET 오프셋을 박아 보내므로
  /// ISO 문자열 슬라이스가 TZ-안전. DST(-4/-5)와 무관.
  int get etHour => int.parse(date.substring(11, 13));

  /// ET 시각의 minute (0..59).
  int get etMinute => int.parse(date.substring(14, 16));

  factory IntradayBar.fromJson(Map<String, dynamic> j) => IntradayBar(
        date: (j['date'] as String?) ?? '',
        open: (j['open'] as num?)?.toDouble(),
        high: (j['high'] as num?)?.toDouble(),
        low: (j['low'] as num?)?.toDouble(),
        close: (j['close'] as num?)?.toDouble(),
        volume: (j['volume'] as num?)?.toInt(),
      );
}

class IntradayChartData {
  final String ticker;
  final String interval; // '1h'
  final List<IntradayBar> data;

  const IntradayChartData({
    required this.ticker,
    required this.interval,
    required this.data,
  });

  bool get isEmpty => data.isEmpty;

  /// 가장 최근 봉의 ET 일자(YYYY-MM-DD)을 추출. 표시용.
  String? get latestDateEt {
    if (data.isEmpty) return null;
    final last = data.last.date;
    // ISO datetime 첫 10글자 = 일자
    return last.length >= 10 ? last.substring(0, 10) : null;
  }

  factory IntradayChartData.fromJson(Map<String, dynamic> j) =>
      IntradayChartData(
        ticker: (j['ticker'] as String?) ?? '',
        interval: (j['interval'] as String?) ?? '1h',
        data: ((j['data'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(IntradayBar.fromJson)
            .toList(),
      );
}
