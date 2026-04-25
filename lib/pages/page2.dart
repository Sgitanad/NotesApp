import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/note.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  final ApiService _apiService = ApiService();
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    bool connected = await _apiService.checkConnection();
    setState(() {
      _isConnected = connected;
    });

    if (!connected) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final notes = await _apiService.getNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _refreshNotes() async {
    setState(() {
      _isLoading = true;
    });
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Show Notes',
          style: TextStyle(
            color: Color(0xFFEAE0CF), 
            fontSize: 30, 
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: const Color(0xFF213448),
      ),
      backgroundColor: const Color(0xFFEAE0CF),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshNotes,
        child: const Icon(Icons.refresh),
        backgroundColor: const Color(0xFF213448),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Cannot connect to server',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Please start FastAPI backend on port 8000'),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(fontSize: 20),
            ),
            Text('Create your first note!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotes,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(
                note.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(note.content),
                  SizedBox(height: 8),
                  Text(
                    'Updated: ${note.updatedAt.toString().split('.')[0]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show note details
                _showNoteDetails(note);
              },
            ),
          );
        },
      ),
    );
  }

  void _showNoteDetails(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(note.content),
              SizedBox(height: 16),
              Divider(),
              Text(
                'Created: ${note.createdAt.toString().split('.')[0]}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Updated: ${note.updatedAt.toString().split('.')[0]}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
