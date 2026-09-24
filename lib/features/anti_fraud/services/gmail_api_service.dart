import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class GmailEmailItem {
  final String id;
  final String subject;
  final String from;
  final String snippet;
  final String date;

  GmailEmailItem({
    required this.id,
    required this.subject,
    required this.from,
    required this.snippet,
    required this.date,
  });
}

class GmailApiService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gmail.GmailApi.gmailReadonlyScope,
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<GoogleSignInAccount?> get currentUser async => _googleSignIn.currentUser;

  /// Fetches latest 10 emails from the user's inbox
  static Future<List<GmailEmailItem>> fetchRecentEmails() async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      throw Exception("User is not signed in to Google");
    }

    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw Exception("Failed to obtain authenticated HTTP client");
    }

    final gmailApi = gmail.GmailApi(httpClient);
    
    // 1. Get messages list
    final messagesList = await gmailApi.users.messages.list(
      'me',
      maxResults: 10,
      q: 'category:primary', // Filter for primary inbox emails
    );

    final List<GmailEmailItem> emails = [];

    if (messagesList.messages != null) {
      for (final msgRef in messagesList.messages!) {
        final msgId = msgRef.id;
        if (msgId == null) continue;

        // 2. Fetch message details (metadata format is fast and sufficient for lists)
        final detail = await gmailApi.users.messages.get('me', msgId, format: 'metadata', metadataHeaders: ['From', 'Subject', 'Date']);
        
        String subject = 'No Subject';
        String from = 'Unknown';
        String date = '';

        if (detail.payload?.headers != null) {
          for (final header in detail.payload!.headers!) {
            if (header.name?.toLowerCase() == 'subject') {
              subject = header.value ?? 'No Subject';
            } else if (header.name?.toLowerCase() == 'from') {
              from = header.value ?? 'Unknown';
            } else if (header.name?.toLowerCase() == 'date') {
              date = header.value ?? '';
            }
          }
        }

        emails.add(
          GmailEmailItem(
            id: msgId,
            subject: subject,
            from: from,
            snippet: detail.snippet ?? '',
            date: date,
          ),
        );
      }
    }

    return emails;
  }

  /// Fetches raw message MIME (EML) content for the chosen message ID
  static Future<String> fetchRawEmailContent(String messageId) async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      throw Exception("User is not signed in to Google");
    }

    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw Exception("Failed to obtain authenticated HTTP client");
    }

    final gmailApi = gmail.GmailApi(httpClient);

    // 1. Fetch message in 'raw' format
    final message = await gmailApi.users.messages.get(
      'me',
      messageId,
      format: 'raw',
    );

    final rawBase64 = message.raw;
    if (rawBase64 == null) {
      throw Exception("Failed to retrieve raw EML content from Gmail API");
    }

    // 2. Base64url decode raw MIME contents to plain text
    try {
      final bytes = base64Url.decode(rawBase64);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      // Fallback decoding if standard base64url fails (sometimes padding differs)
      final normalized = base64.normalize(rawBase64.replaceAll('-', '+').replaceAll('_', '/'));
      final bytes = base64.decode(normalized);
      return utf8.decode(bytes, allowMalformed: true);
    }
  }
}
