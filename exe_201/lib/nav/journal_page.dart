import 'package:exe_201/chat/chat_page.dart';
import 'package:exe_201/journal/updateJournalScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chatdoctors.dart';
import '/nav/bottom_nav_bar.dart';
import '/journal/create_journal_screen.dart';
import '/journal/journal_entry.dart';
import '/journal/pregnancy_milestones_screen.dart';
import '/journal/calendar_widget.dart';
import '/journal/journal_provider.dart';
import '/api/journal_api.dart';

class JournalEntryModel {
  String? journalId;
  String date;
  String head;
  String content;
  String? image;

  JournalEntryModel({
    this.journalId,
    required this.date,
    required this.head,
    required this.content,
    this.image,
  });

  @override
  String toString() {
    return 'JournalEntryModel(journalId: $journalId, date: $date, head: $head, content: $content, image: $image)';
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _journalData;
  bool _shouldUpdateEntry = false;
  int _currentPage = 1;
  int _pageSize = 3; // Hiển thị tối đa 3 mục mỗi trang
  int _totalPages = 1;
  List<JournalEntryModel> _currentEntries = []; // Danh sách hiện tại sau phân trang

  @override
  void initState() {
    super.initState();
    _fetchJournalEntries();
  }

  Future<void> _fetchJournalEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await JournalApi.getJournalEntries(
        pageIndex: 0,
        pageSize: 10,
        headOrContent: null,
        isDescending: true,
      );
      setState(() {
        _journalData = result['body'] as Map<String, dynamic>?;
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        journalProvider.clearPinnedEntries(); // Xóa các mục ghim cũ để tránh trùng lặp
        final entriesList = _journalData?['items'] as List<dynamic>?;
        final entries = List<JournalEntryModel>.from(
          entriesList?.map((e) {
            final id = e['id'] as String?;
            if (id == null || id.isEmpty) {
              throw Exception('Invalid journalId in API response: $e');
            }
            final createdTime = e['createdTime'] as String? ?? '';
            return JournalEntryModel(
              journalId: id,
              date: createdTime,
              head: e['head'] as String? ?? '',
              content: e['content'] as String? ?? '',
              image: e['image'] as String?,
            );
          }) ?? [],
        );
        for (var entry in entries) {
          try {
            final createdDate = DateTime.parse(entry.date);
            final normalizedDate = DateTime(createdDate.year, createdDate.month, createdDate.day);
            journalProvider.pinEntry(normalizedDate, entry);
          } catch (e) {
            print('Error parsing createdTime for entry ${entry.journalId}: $e');
            journalProvider.pinEntry(DateTime.now(), entry);
          }
        }
        _updateTotalPages(journalProvider.pinnedEntries);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching journal entries: $e. Please ensure the server is running and accessible.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateTotalPages(Map<DateTime, List<JournalEntryModel>> pinnedEntries) {
    final allEntries = pinnedEntries.entries.expand((e) => e.value).toList();
    _totalPages = (allEntries.length / _pageSize).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages; // Đảm bảo trang không vượt quá tổng số trang
    _updateCurrentEntries(allEntries);
  }

  void _updateCurrentEntries(List<JournalEntryModel> allEntries) {
    if (allEntries.isEmpty) {
      setState(() {
        _currentEntries = [];
        _totalPages = 1;
        _currentPage = 1;
      });
      return;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    setState(() {
      _currentEntries = allEntries.sublist(
        startIndex.clamp(0, allEntries.length),
        endIndex.clamp(0, allEntries.length),
      );
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    _updateCurrentEntries(journalProvider.pinnedEntries.entries.expand((e) => e.value).toList());
  }

  Future<void> _createJournalEntry(JournalEntryModel newEntry) async {
    try {
      await _fetchJournalEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry created successfully!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing journal entries: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _updateJournalEntry(JournalEntryModel updatedEntry) async {
    try {
      if (updatedEntry.journalId == null || updatedEntry.journalId!.isEmpty) {
        throw Exception('Journal ID is missing or invalid. Cannot update entry.');
      }
      if (updatedEntry.head.isEmpty) {
        throw Exception('Head is required. Cannot update entry.');
      }
      await JournalApi.updateJournalEntry(
        journalId: updatedEntry.journalId!,
        head: updatedEntry.head,
        content: updatedEntry.content,
        imagePath: updatedEntry.image,
      );
      await _fetchJournalEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry updated successfully!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating journal entry: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _deleteJournalEntry(String journalId) async {
    try {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      journalProvider.pinnedEntries.removeWhere((_, entries) => entries.any((entry) => entry.journalId == journalId));
      await JournalApi.deleteJournalEntry(journalId: journalId);
      await _fetchJournalEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry deleted successfully!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting journal entry: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    List<JournalEntryModel> pinHistory = [];
    try {
      pinHistory = journalProvider.pinnedEntries.entries
          .expand((entry) => entry.value.map((e) => {'date': entry.key, 'entry': e}))
          .toList()
          .cast<Map<dynamic, dynamic>>()
          .map((e) => e['entry'] as JournalEntryModel)
          .toList()
        ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _updateTotalPages(journalProvider.pinnedEntries); // Cập nhật tổng số trang
    } catch (e) {
      pinHistory = [];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'My Journal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
              ).createShader(
                Rect.fromLTWH(0, 0, 200, 70), // Fixed size for gradient, adjust if needed
              ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.chat_sharp),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsPage())),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEntry = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJournalScreen()),
          );
          if (newEntry != null && newEntry is JournalEntryModel) {
            await _createJournalEntry(newEntry);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchJournalEntries,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recently Pinned',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _currentEntries.isEmpty
                  ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No pinned entries yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
                  : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentEntries.length,
                    itemBuilder: (context, index) {
                      return AnimatedOpacity(
                        opacity: _shouldUpdateEntry && index == 0 ? 0.7 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: JournalEntry(
                          entry: _currentEntries[index],
                          index: index,
                          onEdit: () async {
                            final updatedEntry = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateJournalScreen(
                                  existingEntry: _currentEntries[index],
                                ),
                              ),
                            );
                            if (updatedEntry != null && updatedEntry is JournalEntryModel) {
                              setState(() {
                                _shouldUpdateEntry = true;
                              });
                              await _updateJournalEntry(updatedEntry);
                              setState(() {
                                _shouldUpdateEntry = false;
                              });
                            }
                          },
                          onDelete: () async {
                            if (_currentEntries[index].journalId != null) {
                              await _deleteJournalEntry(_currentEntries[index].journalId!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid journal ID. Cannot delete entry.')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentPage > 1
                            ? () {
                          _goToPage(_currentPage - 1);
                        }
                            : null,
                      ),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _currentPage < _totalPages
                            ? () {
                          _goToPage(_currentPage + 1);
                        }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pregnancy Milestone Calendar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PregnancyMilestonesScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CalendarWidget(
                pinnedEntries: journalProvider.pinnedEntries,
                onPinEntry: journalProvider.pinEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}