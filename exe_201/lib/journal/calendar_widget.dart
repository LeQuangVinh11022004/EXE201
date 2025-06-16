import 'package:exe_201/journal/create_journal_screen.dart';
import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';

class CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<JournalEntryModel>> pinnedEntries;
  final Function(DateTime, JournalEntryModel) onPinEntry;

  const CalendarWidget({
    super.key,
    required this.pinnedEntries,
    required this.onPinEntry,
  });

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _currentMonth = DateTime.now();

  DateTime _firstDayOfMonth() {
    return DateTime(_currentMonth.year, _currentMonth.month, 1);
  }

  int _daysInMonth() {
    return DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    int firstWeekday = _firstDayOfMonth().weekday;
    int adjustedFirstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    int daysInMonth = _daysInMonth();
    int prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    List<Widget> dayCells = [];
    for (int i = adjustedFirstWeekday - 1; i >= 0; i--) {
      dayCells.add(_buildDayCell(
        day: (prevMonthDays - i).toString(),
        isOutsideMonth: true,
      ));
    }
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime day = DateTime(_currentMonth.year, _currentMonth.month, i);
      DateTime normalizedDay = DateTime(day.year, day.month, day.day);
      bool hasPinned = widget.pinnedEntries[normalizedDay]?.isNotEmpty ?? false;
      dayCells.add(_buildDayCell(
        day: i.toString(),
        hasPinned: hasPinned,
        onTap: () {
          _showPinnedEntriesDialog(context, day);
        },
      ));
    }
    int remainingCells = 42 - dayCells.length;
    for (int i = 1; i <= remainingCells; i++) {
      dayCells.add(_buildDayCell(
        day: i.toString(),
        isOutsideMonth: true,
      ));
    }

    return Card(
      elevation: 2,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_left,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 28,
                  ),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 28,
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Mon', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54)),
                Text('Tue', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54)),
                Text('Wed', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54)),
                Text('Thu', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54)),
                Text('Fri', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54)),
                Text('Sat', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.redAccent)),
                Text('Sun', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              children: dayCells,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required String day,
    bool isOutsideMonth = false,
    bool hasPinned = false,
    VoidCallback? onTap,
  }) {
    DateTime dayDate = DateTime(_currentMonth.year, _currentMonth.month, int.parse(day));
    DateTime normalizedDay = DateTime(dayDate.year, dayDate.month, dayDate.day);

    return GestureDetector(
      onTap: isOutsideMonth ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: hasPinned ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutsideMonth
                ? Colors.grey.withOpacity(0.2)
                : hasPinned
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isOutsideMonth ? Colors.grey : Colors.black87,
                fontWeight: hasPinned ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

          ],
        ),
      ),
    );
  }

  void _showPinnedEntriesDialog(BuildContext context, DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    List<JournalEntryModel> entries = widget.pinnedEntries[normalizedDay] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: Theme.of(context).dialogTheme.shape,
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          'Entries for ${day.day}/${day.month}/${day.year}',
          style: Theme.of(context).dialogTheme.titleTextStyle,
        ),
        content: entries.isEmpty
            ? Text(
                'No entries pinned for this day.',
                style: Theme.of(context).dialogTheme.contentTextStyle,
              )
            : SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            entry.head.isEmpty ? 'No Title' : entry.head,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16),
                          ),
                          subtitle: Text(
                            entry.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                widget.pinnedEntries[normalizedDay]!.removeAt(index);
                                if (widget.pinnedEntries[normalizedDay]!.isEmpty) {
                                  widget.pinnedEntries.remove(normalizedDay);
                                }
                              });
                              Navigator.pop(context);
                              _showPinnedEntriesDialog(context, day);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () async {
              final newEntry = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateJournalScreen()),
              );
              if (newEntry != null && newEntry is JournalEntryModel) {
                widget.onPinEntry(normalizedDay, newEntry);
                Navigator.pop(context);
                _showPinnedEntriesDialog(context, day);
              }
            },
            child: const Text('Pin New Entry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}