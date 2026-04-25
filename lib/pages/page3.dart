
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/note.dart';

class Page3 extends StatefulWidget {
  const Page3({super.key});

  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  final ApiService _apiService = ApiService();
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isConnected = true;
  
  // For editing
  Note? _selectedNote;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    bool connected = await _apiService.checkConnection();
    
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }

    if (!connected) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final notes = await _apiService.getNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _isLoading = true;
      _isEditing = false;
      _selectedNote = null;
      _titleController.clear();
      _contentController.clear();
    });
    await _loadNotes();
  }

  void _startEditingNote(Note note) {
    setState(() {
      _selectedNote = note;
      _isEditing = true;
      _titleController.text = note.title;
      _contentController.text = note.content;
    });
    
    // Scroll to editing section
    Future.delayed(const Duration(milliseconds: 100), () {
      Scrollable.ensureVisible(context);
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedNote = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _updateNote() async {
    if (_selectedNote == null) return;
    
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and content'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if anything actually changed
    if (_titleController.text == _selectedNote!.title && 
        _contentController.text == _selectedNote!.content) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateNote(
        _selectedNote!.id,
        _titleController.text,
        _contentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshNotes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modify Notes',
          style: TextStyle(
            color: Color(0xFFEAE0CF), 
            fontSize: 30, 
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: const Color(0xFF213448),
        actions: [
          IconButton(
            onPressed: _refreshNotes,
            icon: const Icon(Icons.refresh, color: Color(0xFFEAE0CF)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEAE0CF),
      body: _buildBody(),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildBody() {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Cannot connect to server',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('Please start FastAPI backend on port 8000'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213448),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Retry Connection',
                style: TextStyle(color: Color(0xFFEAE0CF)),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No notes to modify',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text('Create some notes first!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213448),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFFEAE0CF), fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes list section
          const Text(
            'Select a Note to Edit:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildNotesList(),

          const SizedBox(height: 30),

          // Editing section (only shown when a note is selected)
          if (_isEditing && _selectedNote != null)
            _buildEditingSection(),

          if (!_isEditing && _notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.edit, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Select a note from the list above to start editing',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        final isSelected = _selectedNote?.id == note.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected ? const Color(0xFF213448) : null,
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? const Color(0xFFEAE0CF) : const Color(0xFF213448),
              child: Text(
                (index + 1).toString(),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF213448) : const Color(0xFFEAE0CF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              note.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFEAE0CF) : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  note.content.length > 80 
                    ? '${note.content.substring(0, 80)}...' 
                    : note.content,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFEAE0CF) : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: ${_formatDate(note.updatedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFFEAE0CF).withOpacity(0.8) : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.edit,
                color: isSelected ? const Color(0xFFEAE0CF) : const Color(0xFF213448),
              ),
              onPressed: () => _startEditingNote(note),
            ),
            onTap: () => _startEditingNote(note),
          ),
        );
      },
    );
  }

  Widget _buildEditingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editing header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editing: ${_selectedNote!.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF213448),
                ),
              ),
              IconButton(
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Title input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Edit note title',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.title, color: Color(0xFF213448)),
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
          ),
          
          const SizedBox(height: 20),
          
          // Content input
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Note Content',
              hintText: 'Edit your note content...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
              alignLabelWithHint: true,
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 8,
            minLines: 4,
            keyboardType: TextInputType.multiline,
          ),
          
          const SizedBox(height: 25),
          
          // Original content preview
          ExpansionTile(
            title: const Text(
              'View Original Content',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title: ${_selectedNote!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Content: ${_selectedNote!.content}'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cancelEditing,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _updateNote,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213448),
                    foregroundColor: const Color(0xFFEAE0CF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _refreshNotes,
          backgroundColor: const Color(0xFF213448),
          child: const Icon(Icons.refresh, color: Color(0xFFEAE0CF)),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          backgroundColor: const Color(0xFF213448),
          child: const Icon(Icons.arrow_back, color: Color(0xFFEAE0CF)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
