import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;

import '../../../core/errors/app_failure.dart';

/// States of EK-07 "AI busy" (docs/ux/screens/ek-07-ai-busy.md, ADR-0016 pkt 10-14).
enum AiBusyPhase {
  /// A: countdown to the single automatic retry (`slotReleased = true`).
  countdown,

  /// C: a retry of `generatePlan` is running (automatic or "Try now").
  retrying,

  /// B: a retry ended with `ai_busy` again: "Try now" only, no countdown, no automat.
  manual,

  /// D: the deadline passed while the app was in the background: "Try now" only.
  paused,

  /// E: first `ai_busy` without `slotReleased = true`: no automat (owner, UX-TAM98-1).
  noAuto,

  /// The retry succeeded or ended with another error; the host has navigated away.
  done,
}

/// One retry of `generatePlan` with the same form data and a NEW requestId (built by the
/// host). Completes with null when the plan arrived, otherwise with the classified failure.
typedef AiBusyRetry = Future<AppFailure?> Function();

/// Monotonic time since an arbitrary origin (ek-07-ai-busy.md: the deadline is computed
/// from a monotonic clock, not from ticks, so it survives the app going to the background).
typedef MonotonicClock = Duration Function();

MonotonicClock _stopwatchClock() {
  final sw = Stopwatch()..start();
  return () => sw.elapsed;
}

/// Seconds between polite TalkBack announcements of the remaining time.
const aiBusyAnnounceEverySec = 15;

/// Logic of the "AI busy" state, one instance per `ai_busy` answer to ONE form submission.
///
/// Rules (ADR-0016 pkt 11-12, ek-07-ai-busy.md):
/// - with `slotReleased = true`: countdown from `retryAfterSec`, then ONE automatic retry,
///   only when the app is in the foreground (`resumed`) at the deadline;
/// - "Try now" during the countdown replaces the automatic retry (never adds a second one);
/// - after the deadline in the background: state D (button only, automat counted as used);
/// - without `slotReleased = true`: state E, no automat;
/// - a retry ending with `ai_busy` again: state B (button only), never another automat;
/// - success or any other error: [onSuccess] / [onFailure] (EK-08 / EK-16 mapping).
class AiBusyController extends ChangeNotifier {
  AiBusyController({
    required AppFailure failure,
    required this._retry,
    required this._onSuccess,
    required this._onFailure,
    MonotonicClock? clock,
  }) : assert(failure.kind == FailureKind.aiBusy),
       _clock = clock ?? _stopwatchClock(),
       retryAfterSec = failure.retryAfterSec ?? defaultRetryAfterSec,
       _slotReleased = failure.slotReleased {
    // Review PR #159 #1: the answer may arrive while the app is already in the background
    // (generation takes up to 120 s). AppLifecycleListener reports only CHANGES, and no
    // frame (so no view initState) is built in the background, so the controller itself
    // starts from the current state and follows the lifecycle. In the background the
    // countdown runs, the automat never fires (deadline there -> state D).
    final current = WidgetsBinding.instance.lifecycleState;
    _foreground = current == null || current == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (s) => setForeground(s == AppLifecycleState.resumed),
    );
    if (_slotReleased == true) {
      _phase = AiBusyPhase.countdown;
      _deadline = _clock() + Duration(seconds: retryAfterSec);
      _remainingSec = retryAfterSec;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _phase = AiBusyPhase.noAuto;
      _autoUsed = true;
    }
  }

  final AiBusyRetry _retry;
  final VoidCallback _onSuccess;
  final void Function(AppFailure failure) _onFailure;
  final MonotonicClock _clock;

  /// Normalised `retryAfterSec` (30-120, default 60) of the first answer.
  final int retryAfterSec;

  late AiBusyPhase _phase;
  bool? _slotReleased;
  late bool _foreground;
  late final AppLifecycleListener _lifecycle;
  bool _autoUsed = false;
  bool _disposed = false;
  Duration? _deadline;
  int _remainingSec = 0;
  int? _lastAnnounced;
  int _announcements = 0;
  Timer? _timer;
  int _retries = 0;

  AiBusyPhase get phase => _phase;

  /// `slotReleased` of the LAST answer (the quota sentence in B and D follows it).
  bool? get slotReleased => _slotReleased;

  /// Whole seconds left in the countdown (state A), rounded up.
  int get remainingSec => _remainingSec;

  /// Countdown bar value: remaining / total, 1 -> 0.
  double get remainingFraction =>
      retryAfterSec == 0 ? 0 : _remainingSec / retryAfterSec;

  /// Remaining seconds to announce politely (45, 30, 15 for 60 s; never the start or 0).
  /// [announcements] grows by one with every new value; the view announces each once.
  int? get announcedSec => _lastAnnounced;
  int get announcements => _announcements;

  /// Whether the single automatic retry is used up (fired, replaced or skipped).
  bool get autoUsed => _autoUsed;

  /// Number of `generatePlan` retries started from this state (tests, diagnostics).
  int get retries => _retries;

  /// "Try now" in A, B, D or E. Ignored while a retry runs (double tap).
  void tryNow() {
    if (!_canRetryNow) return;
    _startRetry();
  }

  bool get _canRetryNow => switch (_phase) {
    AiBusyPhase.countdown ||
    AiBusyPhase.manual ||
    AiBusyPhase.paused ||
    AiBusyPhase.noAuto => true,
    AiBusyPhase.retrying || AiBusyPhase.done => false,
  };

  /// "Back to the form" / system back: cancels the scheduled retry. The host navigates.
  void cancel() {
    _stopTimer();
    if (_phase == AiBusyPhase.retrying || _phase == AiBusyPhase.done) return;
    _phase = AiBusyPhase.done;
    if (!_disposed) notifyListeners();
  }

  /// App lifecycle: foreground only in `AppLifecycleState.resumed`.
  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground || _phase != AiBusyPhase.countdown) return;
    // Back after the deadline (timers may have been frozen in the background): state D,
    // never a late automatic retry.
    if (_deadline! - _clock() <= Duration.zero) {
      _goPaused();
    } else {
      _tick();
    }
  }

  void _goPaused() {
    _stopTimer();
    _autoUsed = true;
    _remainingSec = 0;
    _phase = AiBusyPhase.paused;
    notifyListeners();
  }

  void _tick() {
    if (_disposed || _phase != AiBusyPhase.countdown) return;
    final left = _deadline! - _clock();
    final remaining = math.max(0, (left.inMilliseconds / 1000).ceil());
    if (remaining != _remainingSec) {
      _remainingSec = remaining;
      if (remaining > 0 &&
          remaining < retryAfterSec &&
          remaining % aiBusyAnnounceEverySec == 0 &&
          _lastAnnounced != remaining) {
        _lastAnnounced = remaining;
        _announcements++;
      }
    }
    if (left > Duration.zero) {
      notifyListeners();
      return;
    }
    if (_foreground) {
      _startRetry();
    } else {
      _goPaused(); // deadline passed in the background: no automat, button only (D)
    }
  }

  Future<void> _startRetry() async {
    _stopTimer();
    _autoUsed = true;
    _retries++;
    _phase = AiBusyPhase.retrying;
    notifyListeners();
    final AppFailure? failure;
    try {
      failure = await _retry();
    } catch (_) {
      if (_disposed) return;
      _phase = AiBusyPhase.done;
      notifyListeners();
      _onFailure(const AppFailure(FailureKind.generic));
      return;
    }
    if (_disposed) return;
    if (failure == null) {
      _phase = AiBusyPhase.done;
      notifyListeners();
      _onSuccess();
    } else if (failure.kind == FailureKind.aiBusy) {
      _slotReleased = failure.slotReleased;
      _phase = AiBusyPhase.manual;
      notifyListeners();
    } else {
      _phase = AiBusyPhase.done;
      notifyListeners();
      _onFailure(failure);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    _stopTimer();
    super.dispose();
  }
}
