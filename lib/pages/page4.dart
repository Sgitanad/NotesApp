
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/note.dart';

class Page4 extends StatefulWidget {
  const Page4({super.key});

  @override
  State<Page4> createState() => _Page4State();
}

class _Page4State extends State<Page4> {
  final ApiService _apiService = ApiService();
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isConnected = true;
  List<bool> _selectedNotes = []; // Track which notes are selected for deletion

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
          _selectedNotes = List<bool>.filled(notes.length, false);
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
    });
    await _loadNotes();
  }

  // Delete single note
  Future<void> _deleteNote(int id, String title) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteNote(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _refreshNotes(); // Reload the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Delete multiple selected notes
  Future<void> _deleteSelectedNotes() async {
    // Get indices of selected notes
    List<int> selectedIndices = [];
    for (int i = 0; i < _selectedNotes.length; i++) {
      if (_selectedNotes[i]) selectedIndices.add(i);
    }

    if (selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one note to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int count = selectedIndices.length;
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $count selected note${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      int successCount = 0;
      int failCount = 0;

      // Delete notes in reverse order to maintain correct indices
      for (int i = selectedIndices.length - 1; i >= 0; i--) {
        int index = selectedIndices[i];
        try {
          await _apiService.deleteNote(_notes[index].id);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        await _refreshNotes();
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount note${successCount > 1 ? 's' : ''} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (failCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete $failCount note${failCount > 1 ? 's' : ''}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Delete all notes
  Future<void> _deleteAllNotes() async {
    if (_notes.isEmpty) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notes'),
        content: const Text('Are you sure you want to delete ALL notes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      int successCount = 0;
      int failCount = 0;

      // Delete notes in reverse order
      for (int i = _notes.length - 1; i >= 0; i--) {
        try {
          await _apiService.deleteNote(_notes[i].id);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        await _refreshNotes();
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All $successCount notes deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (failCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete $failCount note${failCount > 1 ? 's' : ''}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Toggle selection for a note
  void _toggleNoteSelection(int index) {
    setState(() {
      _selectedNotes[index] = !_selectedNotes[index];
    });
  }

  // Select all notes
  void _selectAllNotes() {
    setState(() {
      bool allSelected = _selectedNotes.every((selected) => selected);
      _selectedNotes = List<bool>.filled(_notes.length, !allSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Notes',
          style: TextStyle(
            color: Color(0xFFEAE0CF), 
            fontSize: 30, 
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: const Color(0xFF213448),
        actions: [
          if (_notes.isNotEmpty)
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
              child: const Text('Retry Connection'),
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
            const Icon(Icons.delete_sweep, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No notes to delete',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text('All your notes are safe!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213448),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Selection controls
        if (_notes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _selectedNotes.every((selected) => selected) && _notes.isNotEmpty,
                      tristate: true,
                      onChanged: (_) => _selectAllNotes(),
                    ),
                    const Text('Select All'),
                  ],
                ),
                Text(
                  '${_selectedNotes.where((selected) => selected).length} of ${_notes.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Notes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              final isSelected = _selectedNotes[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isSelected ? Colors.red[50] : null,
                elevation: 2,
                child: ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleNoteSelection(index),
                  ),
                  title: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.red[900] : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        note.content.length > 100 
                          ? '${note.content.substring(0, 100)}...' 
                          : note.content,
                        style: TextStyle(
                          color: isSelected ? Colors.red[800] : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${_formatDate(note.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteNote(note.id, note.title),
                  ),
                  onTap: () => _toggleNoteSelection(index),
                ),
              );
            },
          ),
        ),

        // Bulk actions
        if (_notes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _deleteSelectedNotes,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Selected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _deleteAllNotes,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
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