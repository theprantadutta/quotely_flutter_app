import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import 'app_analytics.dart';
import 'install_cohort.dart';

/// One step of the starter path, in day order.
enum StarterStep {
  save('save'),
  trueFalse('true_false'),
  scenes('scenes');

  /// The analytics parameter value.
  final String wire;
  const StarterStep(this.wire);
}

/// The 3-day starter path for new installs: one gentle card at the top of
/// Today on each of the first three days the app is opened. Day 1 asks to
/// save a line, day 2 to play True or False, day 3 to find a film line in
/// Scenes. A step ticks itself off when the user does it (heard through
/// [AppEvents], so it works offline), a card can be dismissed, and the path
/// ends for good after the third active day or once every step is done.
class StarterPath extends ChangeNotifier {
  StarterPath({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static final instance = StarterPath();

  final DateTime Function() _clock;
  SharedPreferences? _prefs;
  StreamSubscription<AppEvent>? _events;
  AppLifecycleListener? _lifecycle;

  /// The days the app was opened on (yyyy-MM-dd), oldest first.
  List<String> _days = [];

  /// The day each step was done on.
  Map<StarterStep, String> _done = {};
  Set<StarterStep> _dismissed = {};
  bool _finished = false;

  Future<void>? _starting;

  /// Counts today and every resume as active, and listens for the steps.
  /// Called by the router on the way into the tabs, so it is listening
  /// before any tab logs a screen view. Runs once; never throws. The install
  /// cohort it relies on was settled in main().
  Future<void> start() => _starting ??= () async {
    try {
      await attach(await SharedPreferences.getInstance());
      _lifecycle ??= AppLifecycleListener(
        onResume: () => unawaited(recordActiveDay()),
      );
    } catch (e) {
      debugPrint('Starter path failed to start: $e');
    }
  }();

  /// [start] without the lifecycle hook; [events] replaces [AppEvents].
  @visibleForTesting
  Future<void> attach(
    SharedPreferences prefs, {
    Stream<AppEvent>? events,
  }) async {
    _prefs = prefs;
    _read(prefs);
    await recordActiveDay();
    _events ??= (events ?? AppEvents.stream).listen(
      (e) => unawaited(onEvent(e.name, e.params)),
    );
  }

  String get _today {
    final d = _clock();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  bool get _active {
    final prefs = _prefs;
    return prefs != null && InstallCohort.isNew(prefs) && !_finished;
  }

  /// Which active day today is (1 = the install day); 0 if not counted.
  int get day => _days.indexOf(_today) + 1;

  bool isDone(StarterStep step) => _done.containsKey(step);

  bool get allDone => _done.length == StarterStep.values.length;

  /// Over for good: past day 3, or every step done.
  bool get finished => _finished;

  /// Today's card, or null. It stays up, ticked, for the rest of the day
  /// its step is done; a step done on an earlier day leaves no card.
  StarterStep? get visibleStep {
    if (!_active) return null;
    final d = day;
    if (d < 1 || d > StarterStep.values.length) return null;
    final step = StarterStep.values[d - 1];
    if (_dismissed.contains(step)) return null;
    final doneOn = _done[step];
    if (doneOn != null && doneOn != _today) return null;
    return step;
  }

  /// Counts today as an active day. A fourth one ends the path.
  Future<void> recordActiveDay() async {
    if (!_active) return;
    final today = _today;
    if (_days.contains(today)) return;
    _days = [..._days, today];
    if (_days.length > StarterStep.values.length) _finished = true;
    await _save();
    notifyListeners();
  }

  /// The step an analytics event completes, if any.
  static StarterStep? stepFor(String name, Map<String, Object> params) =>
      switch (name) {
        'favorite_toggled' when params['saved'] == 'true' => StarterStep.save,
        'facts_game_answered' => StarterStep.trueFalse,
        'screen_view' when params['screen_name'] == 'scenes' =>
          StarterStep.scenes,
        _ => null,
      };

  /// Ticks off the step [name] completes. Steps count on any day of the
  /// path, not only their own.
  Future<void> onEvent(String name, Map<String, Object> params) async {
    final step = stepFor(name, params);
    if (step == null || !_active || isDone(step)) return;
    // The app may have stayed open past midnight.
    await recordActiveDay();
    if (!_active) return;
    _done = {..._done, step: _today};
    logAppEvent('starter_step_done', {'step': step.wire, 'day': day});
    if (allDone) _finished = true;
    await _save();
    notifyListeners();
  }

  /// Hides [step]'s card for good.
  Future<void> dismiss(StarterStep step) async {
    if (!_active || _dismissed.contains(step)) return;
    _dismissed = {..._dismissed, step};
    logAppEvent('starter_dismissed', {
      'step': step.wire,
      'day': day,
      'done': isDone(step).toString(),
    });
    await _save();
    notifyListeners();
  }

  void _read(SharedPreferences prefs) {
    _days = [];
    _done = {};
    _dismissed = {};
    _finished = false;
    final raw = prefs.getString(kStarterPathKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      StarterStep? parse(Object? wire) {
        for (final s in StarterStep.values) {
          if (s.wire == wire) return s;
        }
        return null;
      }

      _days = [for (final d in json['days'] as List? ?? const []) '$d'];
      _done = {
        for (final e in (json['done'] as Map? ?? const {}).entries)
          ?parse(e.key): '${e.value}',
      };
      _dismissed = {
        for (final w in json['dismissed'] as List? ?? const []) ?parse(w),
      };
      _finished = json['finished'] == true;
    } catch (e) {
      // Unreadable: end the path rather than show it twice.
      _finished = true;
    }
  }

  Future<void> _save() async {
    try {
      await _prefs?.setString(
        kStarterPathKey,
        jsonEncode({
          'days': _days,
          'done': {for (final e in _done.entries) e.key.wire: e.value},
          'dismissed': [for (final s in _dismissed) s.wire],
          'finished': _finished,
        }),
      );
    } catch (e) {
      debugPrint('Starter path not saved: $e');
    }
  }

  @visibleForTesting
  Future<void> debugDetach() async {
    await _events?.cancel();
    _events = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _prefs = null;
    _starting = null;
  }
}
