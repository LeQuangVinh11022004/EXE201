import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/journal/journal_entry.dart';
import '/journal/journal_provider.dart';
import '/nav/bottom_nav_bar.dart';

class PinHistory extends StatefulWidget {
  const PinHistory({super.key});

  @override
  _PinHistoryState createState() => _PinHistoryState();
}

class _PinHistoryState extends State<PinHistory> {
  int _currentPage = 1;
  int _pageSize = 3; // Số mục trên mỗi trang
  int _totalPages = 1;
  List<JournalEntryModel> _currentEntries = []; // Danh sách mục hiện tại sau phân trang

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTotalPages();
    _updateCurrentEntries();
  }

  void _updateTotalPages() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final pinHistory = journalProvider.pinnedEntries.entries
        .expand((entry) => entry.value)
        .toList();
    _totalPages = (pinHistory.length / _pageSize).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
  }

  void _updateCurrentEntries() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final pinHistory = journalProvider.pinnedEntries.entries
        .expand((entry) => entry.value)
        .toList();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    setState(() {
      _currentEntries = pinHistory.sublist(
        startIndex,
        endIndex > pinHistory.length ? pinHistory.length : endIndex,
      );
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _updateCurrentEntries();
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    final pinHistory = journalProvider.pinnedEntries.entries
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const JournalPage()),
            );
          },
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
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
              _currentEntries.isEmpty
                  ? const Text('No pinned entries yet.')
                  : Column(
                children: List.generate(_currentEntries.length, (index) {
                  return JournalEntry(
                    entry: _currentEntries[index],
                    index: index,
                    onDelete: () {
                      final date = journalProvider.pinnedEntries.keys.firstWhere(
                            (key) => journalProvider.pinnedEntries[key]!.contains(_currentEntries[index]),
                        orElse: () => DateTime.now(),
                      );
                      journalProvider.pinnedEntries[date]!.removeAt(
                          journalProvider.pinnedEntries[date]!.indexOf(_currentEntries[index]));
                      if (journalProvider.pinnedEntries[date]!.isEmpty) {
                        journalProvider.pinnedEntries.remove(date);
                      }
                      journalProvider.notifyListeners();
                      _updateTotalPages();
                      _updateCurrentEntries();
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage > 1
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}