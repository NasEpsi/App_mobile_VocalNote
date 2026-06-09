import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'file_storage.dart';

FileStorage createFileStorage() => WebFileStorage();

/// Web storage backed by in-memory blobs and object URLs. Audio references are
/// blob URLs (valid for the current page session); exports trigger downloads.
class WebFileStorage implements FileStorage {
  final Map<String, Uint8List> _cache = {};

  @override
  Future<Uint8List> readBytes(String reference) async {
    final cached = _cache[reference];
    if (cached != null) return cached;
    final response = await http.get(Uri.parse(reference));
    return response.bodyBytes;
  }

  @override
  Future<String> saveAudio(String filename, Uint8List bytes) async {
    final url = _objectUrl(bytes, 'audio/mp4');
    _cache[url] = bytes;
    return url;
  }

  @override
  Future<void> delete(String reference) async {
    _cache.remove(reference);
    try {
      web.URL.revokeObjectURL(reference);
    } catch (_) {}
  }

  @override
  Future<bool> exists(String reference) async => true;

  @override
  Future<void> exportText(String filename, String content) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final url = _objectUrl(bytes, 'text/plain;charset=utf-8');
    _download(url, filename);
  }

  String _objectUrl(Uint8List bytes, String mime) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mime),
    );
    return web.URL.createObjectURL(blob);
  }

  void _download(String url, String filename) {
    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
