import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/journal/journal_entry.dart';
import '/journal/journal_provider.dart';

class PinHistory extends StatefulWidget {
  const PinHistory({super.key});

  @override
  _PinHistoryState createState() => _PinHistoryState();
}

class _PinHistoryState extends State<PinHistory> {
  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    // Flatten pinned entries for Pin History
    List<JournalEntryModel> pinHistory = journalProvider.pinnedEntries.entries
        .expand((entry) => entry.value)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        title: const Text(
          'Pin History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Mom&Baby',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pinned Entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              pinHistory.isEmpty
                  ? const Text('No pinned entries yet.')
                  : Column(
                      children: List.generate(pinHistory.length, (index) {
                        return JournalEntry(
                          entry: pinHistory[index],
                          index: index,
        
                          onDelete: () {
                            final date = journalProvider.pinnedEntries.keys.firstWhere(
                              (key) => journalProvider.pinnedEntries[key]!.contains(pinHistory[index]),
                              orElse: () => DateTime.now(),
                            );
                            journalProvider.pinnedEntries[date]!.removeAt(
                                journalProvider.pinnedEntries[date]!.indexOf(pinHistory[index]));
                            if (journalProvider.pinnedEntries[date]!.isEmpty) {
                              journalProvider.pinnedEntries.remove(date);
                            }
                            journalProvider.notifyListeners();
                          },
                        );
                      }),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}