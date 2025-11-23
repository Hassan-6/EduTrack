import 'package:shared_preferences/shared_preferences.dart';

class EmailHistoryService {
  static const String _emailHistoryKey = 'email_history';
  static const int _maxEmails = 5; // Store maximum 5 recent emails

  /// Save an email to history after successful login
  static Future<void> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emails = await getEmailHistory();
      
      // Remove email if it already exists to avoid duplicates
      emails.remove(email);
      
      // Add email to the beginning of the list
      emails.insert(0, email);
      
      // Keep only the most recent emails
      if (emails.length > _maxEmails) {
        emails = emails.sublist(0, _maxEmails);
      }
      
      await prefs.setStringList(_emailHistoryKey, emails);
      print('Email saved to history: $email');
    } catch (e) {
      print('Error saving email to history: $e');
    }
  }

  /// Get list of previously used emails
  static Future<List<String>> getEmailHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_emailHistoryKey) ?? [];
    } catch (e) {
      print('Error getting email history: $e');
      return [];
    }
  }

  /// Clear email history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailHistoryKey);
      print('Email history cleared');
    } catch (e) {
      print('Error clearing email history: $e');
    }
  }

  /// Remove a specific email from history
  static Future<void> removeEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emails = await getEmailHistory();
      emails.remove(email);
      await prefs.setStringList(_emailHistoryKey, emails);
      print('Email removed from history: $email');
    } catch (e) {
      print('Error removing email from history: $e');
    }
  }

  /// Get filtered email suggestions based on query
  static Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) {
      return await getEmailHistory();
    }
    
    final emails = await getEmailHistory();
    return emails.where((email) => 
      email.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
