import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class ApiService {
  // For Android emulator: 10.0.2.2
  // For iOS simulator: localhost
  // For physical device: Your computer's IP address
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  final http.Client client = http.Client();

  // Check API connection
  Future<bool> checkConnection() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Create a note
  Future<Note> createNote(String title, String content) async {
    final response = await client.post(
      Uri.parse('$baseUrl/notes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create note: ${response.statusCode}');
    }
  }

  // Get all notes
  Future<List<Note>> getNotes() async {
    final response = await client.get(
      Uri.parse('$baseUrl/notes/'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes: ${response.statusCode}');
    }
  }

  // Get a single note
  Future<Note> getNote(int id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/notes/$id'),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load note: ${response.statusCode}');
    }
  }

  // Update a note
  Future<Note> updateNote(int id, String title, String content) async {
    final response = await client.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update note: ${response.statusCode}');
    }
  }

  // Delete a note
  Future<void> deleteNote(int id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/notes/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete note: ${response.statusCode}');
    }
  }
}