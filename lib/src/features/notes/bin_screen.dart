import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/note_service.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/models/note.dart';
import 'package:intl/intl.dart';


class BinScreen extends StatelessWidget {
  final NotesService _noteService = NotesService.instance;

  BinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Recycle Bin')),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.watchBinNotes(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final deletedNotes = snapshot.data ?? [];

          return ListView.builder(
            itemCount: deletedNotes.length,
            itemBuilder: (context, index) {
              final note = deletedNotes[index];
              return ListTile(
                title: Text(note.title ?? ''),
                subtitle: Text(
                  'Deleted: ${note.aud_dt != null ? DateFormat.yMd().format(note.aud_dt!) : 'Unknown'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.restore),
                      onPressed: () => _restoreNote(context, note.id, userId),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever),
                      onPressed: () => _permanentDelete(context, note.id, userId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restoreNote(BuildContext context, String noteId, String userId) async {
    try {
      await _noteService.restoreNote(userId, noteId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring note: $e')),
      );
    }
  }

  Future<void> _permanentDelete(BuildContext context, String noteId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _noteService.permanentDeleteNote(userId, noteId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note permanently deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }
}