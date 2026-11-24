import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/update_app_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../consent/application/consent_service.dart';
import '../../plan_generation/application/generation_result.dart';
import '../../plan_generation/domain/trip_input.dart';
import '../../plan_generation/presentation/generation_screen.dart';
import '../domain/trip_form_validation.dart';

/// Formats a local time like the UI language: 24 h in PL, system setting in EN.
String formatLocalTime(BuildContext context, int hour, int minute) {
  final pl = Localizations.localeOf(context).languageCode == 'pl';
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: hour, minute: minute),
    alwaysUse24HourFormat: pl || MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Medium date in the UI language (e.g. "12 mar 2027", "Mar 12, 2027").
String formatLocalDate(BuildContext context, LocalDate date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(date.toDateTime());

/// EK-05 Trip form (US-004, US-006). Data lives only in this screen's state: it survives
/// EK-06 and EK-07 (they are pushed on top) and is lost on back (no draft, U5).
///
/// "Create plan": validation -> AI consent (EK-06 when missing) -> EK-07. There is no
/// connectivity check before sending (posrednik-api.md pkt 6, ADR-0011 pkt 2): "offline"
/// is shown after a failed attempt, nothing was used from the limit.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, required this.uid, this.now});

  final String uid;

  /// Clock for the date range (tests).
  final DateTime Function()? now;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _destination = TextEditingController();
  final _lodging = TextEditingController();
  final _airport = TextEditingController();
  final _flightNumber = TextEditingController();
  final _focus = {
    for (final f in [
      TripField.destination,
      TripField.lodging,
      TripField.airport,
      TripField.flightNumber,
    ])
      f: FocusNode(),
  };
  final _keys = {for (final f in TripField.values) f: GlobalKey()};

  int? _days;
  ArrivalMode? _mode;
  LocalDate? _date;
  LocalTime? _time;
  final _interests = <Interest>[];
  Budget _budget = Budget.medium;
  Pace _pace = Pace.moderate;
  int _partySize = TripLimits.defaultPartySize;
  String? _planLanguage;

  /// Fields the user has left (CMP-04: validation when leaving a field).
  final _touched = <TripField>{};
  bool _submitted = false;
  bool _busy = false;

  /// Field reported by the server (`invalid_argument.field`).
  TripField? _serverField;

  // Messages above the button (EK-05 "Stany").
  bool _offline = false;
  bool _consentWithdrawn = false;
  AppFailure? _failure;
  bool _updateApp = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    for (final e in _focus.entries) {
      e.value.addListener(() {
        if (!e.value.hasFocus && mounted) setState(() => _touched.add(e.key));
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_destination, _lodging, _airport, _flightNumber]) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------ validation

  /// Error text for [field], or null. Shown once the field was left or after "Create plan".
  String? _error(AppLocalizations l10n, TripField field, {bool force = false}) {
    if (!force && !_submitted && !_touched.contains(field)) return null;
    if (_serverField == field) return l10n.errorInvalidFormBody;
    String? text(TextFieldError? e, int max) => switch (e) {
      null => null,
      TextFieldError.required => l10n.commonFieldRequiredError,
      TextFieldError.tooLong => l10n.commonFieldTooLongError(max),
      TextFieldError.chars => l10n.commonFieldCharsError,
    };
    switch (field) {
      case TripField.destination:
        return text(
          validateText(_destination.text, max: TripLimits.destinationMax),
          TripLimits.destinationMax,
        );
      case TripField.lodging:
        return text(
          validateText(_lodging.text, max: TripLimits.lodgingMax),
          TripLimits.lodgingMax,
        );
      case TripField.days:
        return _days == null ? l10n.tripFormDaysError : null;
      case TripField.arrivalMode:
        return _mode == null ? l10n.tripFormArrivalModeError : null;
      case TripField.date:
        final d = _date;
        if (d == null) return l10n.commonFieldRequiredError;
        if (!dateInRange(d, _now())) {
          final r = arrivalDateRange(_now());
          return l10n.commonDateRangeError(
            formatLocalDate(context, r.from),
            formatLocalDate(context, r.to),
          );
        }
        return null;
      case TripField.time:
        return _time == null ? l10n.commonFieldRequiredError : null;
      case TripField.airport:
        if (_mode != ArrivalMode.flight) return null;
        return text(
          validateText(_airport.text, max: TripLimits.airportMax),
          TripLimits.airportMax,
        );
      case TripField.flightNumber:
        if (_mode != ArrivalMode.flight) return null;
        return text(
          validateText(
            _flightNumber.text,
            max: TripLimits.flightNumberMax,
            required: false,
          ),
          TripLimits.flightNumberMax,
        );
    }
  }

  List<TripField> _invalidFields(AppLocalizations l10n) => [
    for (final f in TripField.values)
      if (_error(l10n, f, force: true) != null) f,
  ];

  String _uiLanguage() => languageOf(context);

  TripInput _input() {
    final flight = _mode == ArrivalMode.flight;
    final flightNumber = cleanText(_flightNumber.text);
    return TripInput(
      destination: cleanText(_destination.text),
      lodging: cleanText(_lodging.text),
      days: _days!,
      arrivalMode: _mode!,
      arrivalDate: _date!,
      arrivalTime: _time!,
      airport: flight ? cleanText(_airport.text) : null,
      flightNumber: flight && flightNumber.isNotEmpty ? flightNumber : null,
      interests: List.unmodifiable(_interests),
      budget: _budget,
      pace: _pace,
      partySize: _partySize,
      planLanguage: _planLanguage ?? _uiLanguage(),
    );
  }

  // ------------------------------------------------------------------ actions

  void _clearMessages() {
    _offline = false;
    _failure = null;
    _serverField = null;
  }

  Future<void> _generate() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitted = true;
      _clearMessages();
    });
    final invalid = _invalidFields(l10n);
    if (invalid.isNotEmpty) {
      _focusField(invalid.first);
      _announce(l10n.tripFormErrorsCount(invalid.length));
      return;
    }
    setState(() => _busy = true);
    try {
      final state = await ref
          .read(consentServiceProvider)
          .aiConsentState(widget.uid);
      if (!mounted) return;
      switch (state) {
        case AiConsentState.withdrawn:
          setState(() => _consentWithdrawn = true);
          return;
        case AiConsentState.notGiven:
          final granted = await _askAiConsent(updated: false);
          if (!granted || !mounted) return;
        case AiConsentState.granted:
          break;
      }
      _consentWithdrawn = false;
      await _runGeneration();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _askAiConsent({required bool updated}) async {
    final granted = await context.push<bool>(Routes.aiConsent, extra: updated);
    return granted == true;
  }

  /// EK-07 on top of the form. Success navigates to EK-08 from EK-07 itself.
  Future<void> _runGeneration() async {
    final result = await Navigator.of(context).push<GenerationResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GenerationScreen(uid: widget.uid, input: _input()),
      ),
    );
    if (!mounted || result == null) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case GenerationCancelled():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.generationCancelledSnack)));
      case GenerationBack():
        break;
      case GenerationNeedsAiConsent():
        if (await _askAiConsent(updated: true) && mounted) {
          await _runGeneration();
        }
      case GenerationFailed(:final failure):
        _showFailure(failure);
    }
  }

  void _showFailure(AppFailure f) {
    setState(() {
      switch (f.kind) {
        case FailureKind.offline:
          _offline = true;
        case FailureKind.unsupportedVersion:
        case FailureKind.consentRequired:
          _updateApp = true;
        case FailureKind.invalidArgument:
          final field = fieldFromApiPath(f.field);
          if (field != null) {
            _serverField = field;
            _focusField(field);
          } else {
            _failure = f;
          }
        default:
          _failure = f;
      }
    });
  }

  Future<void> _giveConsent() async {
    if (await _askAiConsent(updated: false) && mounted) {
      setState(() => _consentWithdrawn = false);
    }
  }

  void _focusField(TripField field) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _keys[field]!.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 200),
        );
      }
      _focus[field]?.requestFocus();
    });
  }

  void _announce(String message) {
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.of(context),
    );
  }

  void _setMode(ArrivalMode? mode) => setState(() {
    _mode = mode;
    _touched.add(TripField.arrivalMode);
  });

  Future<void> _pickDate() async {
    final r = arrivalDateRange(_now());
    final initial = _date != null && dateInRange(_date!, _now())
        ? _date!
        : LocalDate.fromDateTime(_now());
    final picked = await showDatePicker(
      context: context,
      firstDate: r.from.toDateTime(),
      lastDate: r.to.toDateTime(),
      initialDate: initial.toDateTime(),
    );
    if (!mounted) return;
    setState(() {
      _touched.add(TripField.date);
      if (picked != null) _date = LocalDate.fromDateTime(picked);
    });
  }

  Future<void> _pickTime() async {
    final pl = Localizations.localeOf(context).languageCode == 'pl';
    final picked = await showTimePicker(
      context: context,
      initialTime: _time == null
          ? const TimeOfDay(hour: 12, minute: 0)
          : TimeOfDay(hour: _time!.hour, minute: _time!.minute),
      builder: pl
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(alwaysUse24HourFormat: true),
              child: child!,
            )
          : null,
    );
    if (!mounted) return;
    setState(() {
      _touched.add(TripField.time);
      if (picked != null) _time = LocalTime(picked.hour, picked.minute);
    });
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_updateApp) {
      // EK-16: unsupported_version / newer consent on the server -> blocking CMP-18.
      return Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(l10n.tripFormTitle)),
        ),
        body: const SafeArea(child: UpdateAppView()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l10n.tripFormTitle)),
      ),
      body: SafeArea(
        child: ContentColumn(
          // Not lazy: the first invalid field must exist to scroll to it.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(context, l10n.tripFormSectionWhere),
                _text(
                  field: TripField.destination,
                  controller: _destination,
                  label: l10n.tripFormDestination,
                  helper: l10n.tripFormDestinationHelper,
                  max: TripLimits.destinationMax,
                  l10n: l10n,
                ),
                _text(
                  field: TripField.lodging,
                  controller: _lodging,
                  label: l10n.tripFormLodging,
                  helper: l10n.tripFormLodgingHelper,
                  max: TripLimits.lodgingMax,
                  l10n: l10n,
                ),
                _section(context, l10n.tripFormSectionWhen),
                KeyedSubtree(
                  key: _keys[TripField.days],
                  child: NumberStepper(
                    key: const Key('tripFormDays'),
                    label: l10n.tripFormDays,
                    value: _days,
                    min: TripLimits.minDays,
                    max: TripLimits.maxDays,
                    error: _error(l10n, TripField.days),
                    onChanged: (v) => setState(() {
                      _days = v;
                      _touched.add(TripField.days);
                    }),
                  ),
                ),
                const SizedBox(height: Space.s4),
                _modeField(context, l10n),
                const SizedBox(height: Space.s4),
                _dateTimeRow(context, l10n),
                if (_mode == ArrivalMode.flight) ...[
                  const SizedBox(height: Space.s4),
                  _text(
                    field: TripField.airport,
                    controller: _airport,
                    label: l10n.tripFormAirport,
                    helper: l10n.tripFormAirportHelper,
                    max: TripLimits.airportMax,
                    l10n: l10n,
                  ),
                  _text(
                    field: TripField.flightNumber,
                    controller: _flightNumber,
                    label: l10n.tripFormFlightNumber,
                    helper: l10n.tripFormFlightNumberHelper,
                    max: TripLimits.flightNumberMax,
                    l10n: l10n,
                    upperCase: true,
                  ),
                ],
                _section(context, l10n.tripFormSectionPrefs),
                _interestsField(context, l10n),
                const SizedBox(height: Space.s4),
                _segmented<Budget>(
                  key: const Key('tripFormBudget'),
                  label: l10n.tripFormBudget,
                  values: Budget.values,
                  selected: _budget,
                  text: (b) => switch (b) {
                    Budget.low => l10n.budgetLow,
                    Budget.medium => l10n.budgetMedium,
                    Budget.high => l10n.budgetHigh,
                  },
                  onChanged: (b) => setState(() => _budget = b),
                ),
                const SizedBox(height: Space.s4),
                _segmented<Pace>(
                  key: const Key('tripFormPace'),
                  label: l10n.tripFormPace,
                  values: Pace.values,
                  selected: _pace,
                  text: (p) => switch (p) {
                    Pace.relaxed => l10n.paceRelaxed,
                    Pace.moderate => l10n.paceModerate,
                    Pace.intense => l10n.paceIntense,
                  },
                  helper: switch (_pace) {
                    Pace.relaxed => l10n.paceRelaxedHelper,
                    Pace.moderate => l10n.paceModerateHelper,
                    Pace.intense => l10n.paceIntenseHelper,
                  },
                  onChanged: (p) => setState(() => _pace = p),
                ),
                const SizedBox(height: Space.s4),
                NumberStepper(
                  key: const Key('tripFormPartySize'),
                  label: l10n.tripFormPartySize,
                  value: _partySize,
                  min: TripLimits.minPartySize,
                  max: TripLimits.maxPartySize,
                  onChanged: (v) => setState(() => _partySize = v),
                ),
                const SizedBox(height: Space.s4),
                _segmented<String>(
                  key: const Key('tripFormPlanLanguage'),
                  label: l10n.tripFormPlanLanguage,
                  values: const ['pl', 'en'],
                  selected: _planLanguage ?? _uiLanguage(),
                  text: (v) =>
                      v == 'pl' ? l10n.languageNamePl : l10n.languageNameEn,
                  onChanged: (v) => setState(() => _planLanguage = v),
                ),
                const SizedBox(height: Space.s6),
                ..._messages(context, l10n),
                AppButton.filled(
                  key: const Key('tripFormGenerate'),
                  label: l10n.tripFormGenerate,
                  loading: _busy,
                  onPressed: _generate,
                ),
                const SizedBox(height: Space.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _messages(BuildContext context, AppLocalizations l10n) {
    final out = <Widget>[];
    void add(Widget w) => out
      ..add(w)
      ..add(const SizedBox(height: Space.s4));
    if (_offline) {
      add(
        Notice(
          key: const Key('tripFormOffline'),
          variant: NoticeVariant.warning,
          icon: AppIcons.offline,
          text: l10n.tripFormOfflineNotice,
          liveRegion: true,
        ),
      );
    }
    if (_consentWithdrawn) {
      add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Notice(
              key: const Key('tripFormConsentWithdrawn'),
              variant: NoticeVariant.info,
              icon: AppIcons.info,
              text: l10n.tripFormConsentWithdrawn,
              liveRegion: true,
            ),
            const SizedBox(height: Space.s2),
            AppButton.outlined(
              key: const Key('tripFormGiveConsent'),
              label: l10n.tripFormGiveConsent,
              onPressed: _giveConsent,
            ),
          ],
        ),
      );
    }
    final f = _failure;
    if (f != null) {
      final m = failureMessage(
        l10n,
        f,
        formatTime: (t) => formatLocalTime(context, t.hour, t.minute),
      );
      add(
        Notice(
          key: const Key('tripFormFailure'),
          variant: NoticeVariant.error,
          icon: f.kind == FailureKind.limitExceeded
              ? AppIcons.clock
              : AppIcons.error,
          title: m.title,
          text: m.body,
          liveRegion: true,
        ),
      );
    }
    return out;
  }

  Widget _section(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.s2, bottom: Space.s3),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _text({
    required TripField field,
    required TextEditingController controller,
    required String label,
    required String helper,
    required int max,
    required AppLocalizations l10n,
    bool upperCase = false,
  }) {
    final error = _error(l10n, field);
    return Padding(
      key: _keys[field],
      padding: const EdgeInsets.only(bottom: Space.s4),
      child: TextField(
        key: Key('tripForm.${field.name}'),
        controller: controller,
        focusNode: _focus[field],
        textInputAction: TextInputAction.next,
        textCapitalization: upperCase
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        autocorrect: !upperCase,
        maxLength: max,
        // Counter from 80 % of the limit (CMP-04).
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => currentLength >= (max * 0.8).floor()
            ? Text('$currentLength/$max')
            : null,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        onChanged: (_) {
          if (_serverField == field) _serverField = null;
          if (_submitted || _touched.contains(field)) setState(() {});
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          errorText: error,
          errorMaxLines: 3,
          suffixIcon: error == null
              ? null
              : AppIcon(
                  AppIcons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
        ),
      ),
    );
  }

  Widget _modeField(BuildContext context, AppLocalizations l10n) {
    final error = _error(l10n, TripField.arrivalMode);
    final theme = Theme.of(context);
    return Column(
      key: _keys[TripField.arrivalMode],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tripFormArrivalMode, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Space.s2),
        SegmentedButton<ArrivalMode>(
          key: const Key('tripFormArrivalMode'),
          segments: [
            ButtonSegment(
              value: ArrivalMode.flight,
              label: Text(l10n.tripFormArrivalFlight),
            ),
            ButtonSegment(
              value: ArrivalMode.car,
              label: Text(l10n.tripFormArrivalCar),
            ),
          ],
          // No default (EK-05).
          emptySelectionAllowed: true,
          selected: {?_mode},
          onSelectionChanged: (s) => _setMode(s.isEmpty ? _mode : s.first),
        ),
        if (error != null) _fieldError(context, error),
      ],
    );
  }

  Widget _dateTimeRow(BuildContext context, AppLocalizations l10n) {
    final car = _mode == ArrivalMode.car;
    final date = _pickerField(
      context,
      field: TripField.date,
      label: car ? l10n.tripFormDateCar : l10n.tripFormDateFlight,
      value: _date == null ? null : formatLocalDate(context, _date!),
      icon: AppIcons.calendar,
      onTap: _pickDate,
      l10n: l10n,
    );
    final time = _pickerField(
      context,
      field: TripField.time,
      label: car ? l10n.tripFormTimeCar : l10n.tripFormTimeFlight,
      value: _time == null
          ? null
          : formatLocalTime(context, _time!.hour, _time!.minute),
      icon: AppIcons.clock,
      onTap: _pickTime,
      l10n: l10n,
    );
    // From 150 % text scale the two fields go into one column (EK-05 "Dostępność").
    final narrow = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow) ...[
          date,
          const SizedBox(height: Space.s4),
          time,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: date),
              const SizedBox(width: Space.s4),
              Expanded(child: time),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(top: Space.s1, left: Space.s4),
          child: Text(
            l10n.commonLocalTimeHelper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickerField(
    BuildContext context, {
    required TripField field,
    required String label,
    required String? value,
    required AppIcons icon,
    required VoidCallback onTap,
    required AppLocalizations l10n,
  }) {
    final error = _error(l10n, field);
    return InkWell(
      key: _keys[field],
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xs),
      child: InputDecorator(
        key: Key('tripForm.${field.name}'),
        isEmpty: value == null,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          errorText: error,
          errorMaxLines: 3,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(Space.s3),
            child: AppIcon(icon),
          ),
        ),
        child: Text(value ?? ''),
      ),
    );
  }

  Widget _interestsField(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final full = _interests.length >= TripLimits.maxInterests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tripFormInterests,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              l10n.tripFormInterestsCounter(_interests.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s2),
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            for (final i in Interest.values)
              FilterChip(
                key: Key('interest.${i.wire}'),
                label: Text(interestLabel(l10n, i)),
                selected: _interests.contains(i),
                onSelected: !_interests.contains(i) && full
                    ? null
                    : (on) => setState(() {
                        on ? _interests.add(i) : _interests.remove(i);
                      }),
              ),
          ],
        ),
        if (_interests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s1),
            child: Text(
              l10n.tripFormInterestsEmptyHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _segmented<T>({
    required Key key,
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) text,
    required ValueChanged<T> onChanged,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.textScalerOf(context).scale(10) >= 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Space.s2),
        if (narrow && values.length > 2)
          // CMP-07: from 150 % a 3-option segment becomes a list.
          RadioGroup<T>(
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              key: key,
              children: [
                for (final v in values)
                  RadioListTile<T>(value: v, title: Text(text(v))),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              key: key,
              segments: [
                for (final v in values)
                  ButtonSegment(value: v, label: Text(text(v))),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.s1),
            child: Text(
              helper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

Widget _fieldError(BuildContext context, String error) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(top: Space.s1, left: Space.s4),
    child: Semantics(
      liveRegion: true,
      child: Text(
        error,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ),
  );
}

String interestLabel(AppLocalizations l10n, Interest i) => switch (i) {
  Interest.monumentsHistory => l10n.interestMonumentsHistory,
  Interest.architecture => l10n.interestArchitecture,
  Interest.artMuseums => l10n.interestArtMuseums,
  Interest.natureParks => l10n.interestNatureParks,
  Interest.beachesWater => l10n.interestBeachesWater,
  Interest.localFood => l10n.interestLocalFood,
  Interest.activeSport => l10n.interestActiveSport,
  Interest.familyAttractions => l10n.interestFamilyAttractions,
  Interest.shopping => l10n.interestShopping,
  Interest.nightlife => l10n.interestNightlife,
  Interest.relaxation => l10n.interestRelaxation,
};

/// CMP-05 number stepper: label, value, −/+ (48 dp). [value] null = not chosen yet
/// (no default for the number of days); "+" then starts at [min].
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.error,
  });

  final String label;
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: label,
          value: v?.toString() ?? '–',
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
              ),
              IconButton(
                key: const Key('stepperDecrease'),
                tooltip: l10n.tripFormDecrease,
                onPressed: v != null && v > min ? () => onChanged(v - 1) : null,
                icon: const AppIcon(AppIcons.remove),
              ),
              SizedBox(
                width: 40,
                child: ExcludeSemantics(
                  child: Text(
                    v?.toString() ?? '–',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                key: const Key('stepperIncrease'),
                tooltip: l10n.tripFormIncrease,
                onPressed: v == null
                    ? () => onChanged(min)
                    : (v < max ? () => onChanged(v + 1) : null),
                icon: const AppIcon(AppIcons.add),
              ),
            ],
          ),
        ),
        if (error != null) _fieldError(context, error!),
      ],
    );
  }
}
