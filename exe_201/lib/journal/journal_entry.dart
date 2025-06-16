import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';

class JournalEntry extends StatelessWidget {
  final JournalEntryModel entry;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const JournalEntry({
    super.key,
    required this.entry,
    required this.index,
    this.onEdit,
    this.onDelete,
  });



  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: Theme.of(context).dialogTheme.shape,
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          title: Text(
            'Xác nhận xóa',
            style: Theme.of(context).dialogTheme.titleTextStyle,
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa nhật ký này?',
            style: Theme.of(context).dialogTheme.contentTextStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Có'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: Theme.of(context).cardTheme.shape,
      elevation: Theme.of(context).cardTheme.elevation,
      margin: Theme.of(context).cardTheme.margin,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.image != null && entry.image!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Image.network(
                      entry.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Ngày: ${DateTime.parse(entry.date).toLocal().toString().split('.')[0]}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiêu đề: ${entry.head.isEmpty ? 'Không có tiêu đề' : entry.head}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Nội dung: ${entry.content.length > 100 ? '${entry.content.substring(0, 100)}...' : entry.content}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (onEdit != null || onDelete != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        final confirmDelete = await _showDeleteConfirmationDialog(context);
                        if (confirmDelete == true && onDelete != null) {
                          onDelete!();
                        }
                      },
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