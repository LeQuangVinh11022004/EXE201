import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';

class JournalProvider with ChangeNotifier {
  final Map<DateTime, List<JournalEntryModel>> _pinnedEntries = {};

  Map<DateTime, List<JournalEntryModel>> get pinnedEntries => _pinnedEntries;

  void pinEntry(DateTime date, JournalEntryModel entry) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _pinnedEntries[normalizedDate] ??= [];
    if (!_pinnedEntries[normalizedDate]!.any((e) => e.journalId == entry.journalId)) {
      _pinnedEntries[normalizedDate]!.add(entry);
      notifyListeners();
    }
  }

  void unpinEntry(DateTime date, JournalEntryModel entry) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _pinnedEntries[normalizedDate]?.removeWhere((e) => e.journalId == entry.journalId);
    if (_pinnedEntries[normalizedDate]?.isEmpty ?? true) {
      _pinnedEntries.remove(normalizedDate);
    }
    notifyListeners();
  }

  void clearPinnedEntries() {
    _pinnedEntries.clear();
    notifyListeners();
  }
}