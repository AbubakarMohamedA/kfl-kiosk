import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Lightweight service to interact with Firestore via REST API.
/// This is used as a fallback on platforms where the Firebase SDK is not supported (e.g., Linux).
class FirebaseRestService {
  static const String projectId = 'kflkiosk-dc264';
  static const String baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  final http.Client _client = http.Client();

  /// Fetches a single document from Firestore.
  Future<Map<String, dynamic>?> getDocument(String path) async {
    try {
      final url = Uri.parse('$baseUrl/$path');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseFirestoreDocument(data);
      } else if (response.statusCode == 404) {
        debugPrint('Firestore REST: Document not found at $path');
        return null;
      } else {
        debugPrint('Firestore REST Error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Firestore REST Exception: $e');
      return null;
    }
  }

  /// Helper to fetch all documents in a collection.
  Future<List<Map<String, dynamic>>> getCollection(String path) async {
    try {
      final url = Uri.parse('$baseUrl/$path');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>?;
        if (documents == null) return [];

        return documents.map((doc) => _parseFirestoreDocument(doc as Map<String, dynamic>)).toList();
      } else {
        debugPrint('Firestore REST Collection Error (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Firestore REST Collection Exception: $e');
      return [];
    }
  }

  /// Performs a structured query via REST (useful for login verification).
  Future<List<Map<String, dynamic>>> runQuery(String collection, List<Map<String, dynamic>> filters, {bool allDescendants = false}) async {
    try {
      final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery');
      
      final dynamic where;
      if (filters.isEmpty) {
        where = null;
      } else if (filters.length == 1) {
        where = filters.first;
      } else {
        where = {
          'compositeFilter': {
            'op': 'AND',
            'filters': filters,
          }
        };
      }

      final query = {
        'structuredQuery': {
          'from': [{'collectionId': collection, 'allDescendants': allDescendants}],
          if (where != null) 'where': where,
        }
      };

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(query),
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>;
        List<Map<String, dynamic>> parsedDocs = [];
        
        for (final result in results) {
          if (result['document'] != null) {
            parsedDocs.add(_parseFirestoreDocument(result['document'] as Map<String, dynamic>));
          }
        }
        return parsedDocs;
      } else {
        debugPrint('Firestore REST Query Error (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Firestore REST Query Exception: $e');
      return [];
    }
  }

  /// Updates an existing document (PATCH).
  Future<bool> patchDocument(String path, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/$path');
      final body = {
        'fields': data.map((key, value) => MapEntry(key, _toFirestoreValue(value)))
      };

      final response = await _client.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Firestore REST Patch Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Firestore REST Patch Exception: $e');
      return false;
    }
  }

  /// Creates a new document (POST).
  Future<bool> createDocument(String collection, String? docId, Map<String, dynamic> data) async {
    try {
      var urlStr = '$baseUrl/$collection';
      if (docId != null) {
        urlStr += '?documentId=$docId';
      }
      final url = Uri.parse(urlStr);
      
      final body = {
        'fields': data.map((key, value) => MapEntry(key, _toFirestoreValue(value)))
      };

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Firestore REST Create Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Firestore REST Create Exception: $e');
      return false;
    }
  }

  /// Converts a standard Dart value into Firestore's "Typed Value" format.
  Map<String, dynamic> _toFirestoreValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry(k, _toFirestoreValue(v)))
        }
      };
    }
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((v) => _toFirestoreValue(v)).toList()
        }
      };
    }
    return {'stringValue': value.toString()};
  }

  /// Parses Firestore's "Typed Value" format into a standard Map.
  /// Example: {"name": {"stringValue": "John"}} -> {"name": "John"}
  Map<String, dynamic> _parseFirestoreDocument(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final result = <String, dynamic>{};
    
    // Extract ID and Full Name from full path (projects/.../documents/coll/ID)
    final String name = doc['name'] as String? ?? '';
    result['id'] = name.split('/').last;
    result['__path'] = name;

    fields.forEach((key, value) {
      result[key] = _parseFirestoreValue(value as Map<String, dynamic>);
    });

    return result;
  }

  dynamic _parseFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) return int.tryParse(value['integerValue'].toString());
    if (value.containsKey('doubleValue')) return (value['doubleValue'] as num).toDouble();
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('timestampValue')) return DateTime.tryParse(value['timestampValue'].toString());
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('mapValue')) {
      final mapValue = value['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      return mapValue.map((k, v) => MapEntry(k, _parseFirestoreValue(v as Map<String, dynamic>)));
    }
    if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue']['values'] as List<dynamic>? ?? [];
      return arrayValue.map((v) => _parseFirestoreValue(v as Map<String, dynamic>)).toList();
    }
    return null;
  }
}
