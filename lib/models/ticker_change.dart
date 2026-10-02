/// 티커 정체성 변경 (서버 `GET /api/v1/tickers/changes`, S6).
///
/// ## 왜 필요한가
///
/// 앱은 보유·관심종목을 **티커 문자열로 저장한다.** 티커가 바뀌면 파이프라인이
/// 옛 심볼 전송을 멈추므로 그 포지션이 조용히 안 풀린다 — 상세는 "데이터를
/// 준비 중입니다"(틀린 설명. 준비 중이 아니라 이름이 바뀐 것)를 띄우고,
/// 포트폴리오 합계에서 그 종목이 빠진다.
///
/// 앱 혼자서는 못 고친다. `BK`가 `BNY`가 됐다는 걸 아는 건 파이프라인뿐이다.
library;

import '../utils/ticker_query.dart';

/// 변경 사유.
enum TickerChangeReason {
  /// 심볼이 바뀌었다. 후속 심볼이 **항상 있다**(서버가 보장한다).
  renamed,

  /// 상장폐지. 후속 심볼이 없다.
  delisted,

  /// 서버가 앞으로 추가할 수 있는 사유. 앱은 아무 동작도 하지 않는다.
  ///
  /// 서버가 `reason`을 enum이 아닌 평문으로 두기로 했기 때문에 필요하다 —
  /// 새 사유 때문에 파싱이 터지면 변경 맵 전체를 못 읽게 된다.
  unknown;

  static TickerChangeReason parse(String? raw) => switch (raw) {
        'renamed' => TickerChangeReason.renamed,
        'delisted' => TickerChangeReason.delisted,
        _ => TickerChangeReason.unknown,
      };
}

/// 변경 한 건.
class TickerChange {
  final String oldTicker;

  /// 후속 심볼. `delisted`면 null.
  final String? newTicker;

  final TickerChangeReason reason;

  /// 옛 심볼이 마지막으로 거래된 날. 표기 변경이면 null일 수 있다.
  final DateTime? lastTradedDate;

  final DateTime? detectedAt;

  const TickerChange({
    required this.oldTicker,
    this.newTicker,
    required this.reason,
    this.lastTradedDate,
    this.detectedAt,
  });

  factory TickerChange.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v is! String || v.isEmpty) return null;
      return DateTime.tryParse(v);
    }

    return TickerChange(
      oldTicker: (json['old'] as String).trim().toUpperCase(),
      newTicker: (json['new'] as String?)?.trim().toUpperCase(),
      reason: TickerChangeReason.parse(json['reason'] as String?),
      lastTradedDate: parseDate(json['last_traded_date']),
      detectedAt: parseDate(json['detected_at']),
    );
  }
}

/// 티커 하나를 해소한 결과.
class TickerResolution {
  /// 지금 써야 하는 심볼. 변경이 없으면 입력과 같다.
  final String ticker;

  /// 사용자에게 알려야 하는 변경인가.
  ///
  /// ⚠️ **표기만 바뀐 경우는 false다.** `BRKB → BRK-B`는 같은 회사의 같은
  /// 주식이고 구분자만 다르다. "종목이 변경되었습니다"라고 알리면 사용자는
  /// 무슨 일이 일어난 줄 안다. 조용히 서버 표기를 따르는 것이 맞다.
  bool get shouldNotify =>
      reason == TickerChangeReason.renamed && !spellingOnly ||
      reason == TickerChangeReason.delisted;

  final TickerChangeReason reason;

  /// 구분자만 다른 같은 심볼인가 (`BRKB` → `BRK-B`).
  final bool spellingOnly;

  /// 적용된 첫 변경. 날짜·사유를 문구에 쓰기 위함. 변경이 없으면 null.
  final TickerChange? change;

  /// 거쳐 온 심볼들. `[BK, BNY]` 형태. 변경이 없으면 `[입력]` 하나.
  final List<String> chain;

  const TickerResolution({
    required this.ticker,
    required this.reason,
    required this.spellingOnly,
    required this.chain,
    this.change,
  });

  /// 변경 없음.
  factory TickerResolution.unchanged(String ticker) => TickerResolution(
        ticker: ticker,
        reason: TickerChangeReason.unknown,
        spellingOnly: false,
        chain: [ticker],
      );

  /// 심볼이 달라졌는가 (표기 변경 포함).
  bool get moved => ticker != chain.first;

  bool get isDelisted => reason == TickerChangeReason.delisted;
}

/// 변경 맵. 서버 응답을 받아 조회·체인 해소를 담당한다.
class TickerChangeMap {
  /// 정규화 키 → 변경. `BRK.B`로 들고 있어도 `BRKB` 항목을 찾게 하려는 것.
  final Map<String, TickerChange> _byNormalized;

  /// 대문자 원본 키 → 변경. 정규화보다 **먼저** 본다.
  final Map<String, TickerChange> _byExact;

  const TickerChangeMap._(this._byExact, this._byNormalized);

  static const empty = TickerChangeMap._({}, {});

  factory TickerChangeMap.fromJson(Map<String, dynamic> json) {
    final list = (json['changes'] as List?) ?? const [];
    final exact = <String, TickerChange>{};
    final normalized = <String, TickerChange>{};

    for (final raw in list) {
      final c = TickerChange.fromJson(raw as Map<String, dynamic>);
      exact[c.oldTicker] = c;
      // 정규화 키가 겹치면 **덮어쓰지 않는다.** 겹치는 경우 어느 쪽이 맞는지
      // 알 수 없으므로 먼저 온 것을 유지하고, 정확 일치가 있으면 그쪽이
      // 우선하므로 실제 손해가 없다.
      normalized.putIfAbsent(normalizeTicker(c.oldTicker), () => c);
    }
    return TickerChangeMap._(exact, normalized);
  }

  bool get isEmpty => _byExact.isEmpty;
  int get length => _byExact.length;

  TickerChange? _lookup(String ticker) {
    final upper = ticker.trim().toUpperCase();
    if (upper.isEmpty) return null;
    return _byExact[upper] ?? _byNormalized[normalizeTicker(upper)];
  }

  /// 티커를 끝까지 따라가 현재 심볼을 찾는다.
  ///
  /// 체인(`A → B`, 이후 `B → C`)은 서버에 두 행으로 저장되므로 `new`를
  /// 따라가며 해소한다. 순환(`A → B`, `B → A`)은 서버가 막지 않으므로
  /// 홉 수를 제한한다 — 데이터가 잘못돼도 앱이 멈추진 않게 한다.
  TickerResolution resolve(String ticker) {
    final start = ticker.trim().toUpperCase();
    if (start.isEmpty) return TickerResolution.unchanged(start);

    final first = _lookup(start);
    if (first == null) return TickerResolution.unchanged(start);

    final chain = <String>[start];
    final seen = <String>{normalizeTicker(start)};
    var current = first;
    var hops = 0;

    while (hops < 10) {
      hops++;
      final next = current.newTicker;

      // 후속이 없다 — 상장폐지, 또는 renamed인데 서버가 비워 보낸 경우.
      // 후자는 서버가 422로 막지만, 막연히 믿지 않는다.
      if (next == null || next.isEmpty) {
        return TickerResolution(
          ticker: chain.last,
          reason: current.reason,
          spellingOnly: false,
          chain: chain,
          change: first,
        );
      }

      chain.add(next);

      // 순환 — 더 따라가지 않고 지금까지의 결과를 쓴다.
      if (!seen.add(normalizeTicker(next))) break;

      final onward = _lookup(next);
      // ⚠️ 자기 참조 방지. `BRK-B`를 정규화하면 `BRKB`이고, 그게 바로
      // `BRKB → BRK-B` 항목의 **옛 심볼**이다. 그대로 따라가면 영원히
      // 제자리를 돈다. 다음 홉이 같은 항목이면 체인은 끝난 것이다.
      if (onward == null || onward.oldTicker == current.oldTicker) break;
      current = onward;
    }

    final end = chain.last;
    return TickerResolution(
      ticker: end,
      // 구분자를 떼면 같은 심볼 — 표기만 바뀐 것이다.
      spellingOnly: normalizeTicker(end) == normalizeTicker(start),
      reason: first.reason,
      chain: chain,
      change: first,
    );
  }
}
