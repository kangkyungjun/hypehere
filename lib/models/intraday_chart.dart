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
  DateTime get dateTime => DateTime.parse(date);

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
