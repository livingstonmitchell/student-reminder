import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/note.dart';
import 'package:students_reminder/src/services/note_service.dart';
import 'package:students_reminder/src/services/auth_service.dart';

class NoteListTile extends StatelessWidget {
  final Note note;
  final VoidCallback? onEdit;

  const NoteListTile({super.key, required this.note, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title ?? ''),
      subtitle: Text(
        note.body ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _softDeleteNote(context, note.id),
      ),
      onTap: onEdit,
    );
  }

  Future<void> _softDeleteNote(BuildContext context, String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Bin?'),
        content: Text('You can restore this note later from the bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = AuthService.instance.currentUser!.uid;
        await NotesService.instance.softDeleteNote(userId, noteId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note moved to bin')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }
}