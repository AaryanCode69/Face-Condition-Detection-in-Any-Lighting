import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogSeverity {
  debug,
  info,

  /// Unexpected but recoverable.
  warning,
  error,
}

class LogEntry {
  LogEntry({
    required this.severity,
    required this.tag,
    required this.message,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  final DateTime timestamp;
  final LogSeverity severity;

  /// Source tag, e.g. 'Camera', 'Inference', 'Isolate'.
  final String tag;
  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final time = timestamp.toIso8601String().substring(11, 23);
    return '[$time] ${severity.name.toUpperCase()} [$tag] $message';
  }
}

/// Routes all output through `debugPrint`.
/// Maintains a rolling buffer of the last [maxEntries] entries
/// for the in-app log viewer.
class AppLogger {
  AppLogger({this.maxEntries = 10000});

  final int maxEntries;
  final Queue<LogEntry> _entries = Queue<LogEntry>();

  /// Newest-last.
  List<LogEntry> get entries => List.unmodifiable(_entries);

  void debug(String tag, String message) =>
      _log(LogSeverity.debug, tag, message);

  void info(String tag, String message) =>
      _log(LogSeverity.info, tag, message);

  void warning(String tag, String message) =>
      _log(LogSeverity.warning, tag, message);

  void error(String tag, String message, [StackTrace? stackTrace]) =>
      _log(LogSeverity.error, tag, message, stackTrace);

  void _log(
    LogSeverity severity,
    String tag,
    String message, [
    StackTrace? stackTrace,
  ]) {
    final entry = LogEntry(
      severity: severity,
      tag: tag,
      message: message,
      stackTrace: stackTrace,
    );

    // Maintain rolling window.
    _entries.addLast(entry);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }

    // Route through debugPrint (never print()).
    debugPrint(entry.toString());
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  void clear() => _entries.clear();
}
