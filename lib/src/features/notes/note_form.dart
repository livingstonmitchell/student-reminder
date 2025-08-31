import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/note.dart';
import 'package:students_reminder/src/services/note_service.dart';
import 'package:students_reminder/src/services/auth_service.dart';

// Enum for course group (customize as needed)
enum CourseGroup { mobile, web, other }

// Enum for visibility
enum NoteVisibility { public, private }

class NoteForm extends StatefulWidget {
  const NoteForm({super.key});

  @override
  _NoteFormState createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  final NotesService _noteService = NotesService.instance;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  CourseGroup _selectedCourseGroup = CourseGroup.other;
  NoteVisibility _selectedVisibility = NoteVisibility.private;

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = AuthService.instance.currentUser!.uid;

        final note = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          body: _bodyController.text,
          visibility: _selectedVisibility.name,
          aud_dt: DateTime.now(),
          tags: [
            _selectedCourseGroup.name
          ], // Optionally use tags for course group
        );

        await _noteService.createNoteModel(userId, note);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? "Enter a title" : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Content'),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? "Enter content" : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<CourseGroup>(
                initialValue: _selectedCourseGroup,
                items: CourseGroup.values.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCourseGroup = value!);
                },
                decoration: InputDecoration(labelText: 'Course Group'),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<NoteVisibility>(
                initialValue: _selectedVisibility,
                items: NoteVisibility.values.map((visibility) {
                  return DropdownMenuItem(
                    value: visibility,
                    child: Text(visibility.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedVisibility = value!);
                },
                decoration: InputDecoration(labelText: 'Visibility'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveNote,
                child: Text('Save Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}