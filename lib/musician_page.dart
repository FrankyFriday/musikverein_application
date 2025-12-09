import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

class MusicianPage extends StatefulWidget {
  final String instrument;
  final String voice;
  final int conductorPort;

  const MusicianPage({
    super.key,
    required this.instrument,
    required this.voice,
    required this.conductorPort,
  });

  @override
  State<MusicianPage> createState() => _MusicianPageState();
}

class _MusicianPageState extends State<MusicianPage> {
  IOWebSocketChannel? _channel;
  final List<ReceivedPiece> _received = [];
  String _status = 'Verbinde…';
  late String _clientId;
  String? _localIp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _clientId = const Uuid().v4();
    _initLocalIpAndConnect();
  }

  Future<String?> _getLocalIp() async {
    final interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<void> _initLocalIpAndConnect() async {
    setState(() {
      _isLoading = true;
      _status = 'Suche lokale IP…';
    });

    final ip = await _getLocalIp();
    if (ip == null) {
      setState(() {
        _status = "Keine lokale IP-Adresse gefunden";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _localIp = ip;
      _status = "Lokale IP gefunden: $ip — verbinde…";
    });

    await _tryConnectWithIp(ip);
    setState(() => _isLoading = false);
  }

  Future<void> _tryConnectWithIp(String ip) async {
    final uri = "ws://$ip:${widget.conductorPort}";
    debugPrint('Versuche Verbindung zu $uri');

    try {
      final socket = await WebSocket.connect(uri);
      setState(() {
        _channel = IOWebSocketChannel(socket);
        _status = 'Mit Dirigent verbunden (IP: $ip)';
      });

      final reg = jsonEncode({
        'type': 'register',
        'clientId': _clientId,
        'instrument': widget.instrument,
        'voice': widget.voice,
      });
      _channel!.sink.add(reg);

      _channel!.stream.listen((message) async {
        await _handleMessage(message);
      }, onDone: () {
        setState(() => _status = 'Verbindung beendet');
      }, onError: (e) {
        setState(() => _status = 'Fehler: $e');
      });
    } catch (e, st) {
      debugPrint('Fehler beim Verbinden mit WebSocket: $e');
      debugPrint('$st');
      setState(() {
        _status = 'Verbindung fehlgeschlagen: $e';
      });
    }
  }

  Future<void> _handleMessage(dynamic message) async {
    debugPrint('Empfangene Nachricht: $message');
    try {
      final map = jsonDecode(message as String);
      final type = map['type'];

      if (type == 'send_piece') {
        final name = map['name'] ?? 'unknown.pdf';
        final targetInstrument = map['instrument'];
        final targetVoice = map['voice'];

        if (targetInstrument != null && targetInstrument != widget.instrument) return;
        if (targetVoice != null && targetVoice != widget.voice) return;

        final dataB64 = map['data'];
        final bytes = base64Decode(dataB64);
        final file = await saveBytesAsFile(bytes, name);

        setState(() {
          _received.add(
            ReceivedPiece(
              name: name,
              path: file.path,
              receivedAt: DateTime.now(),
            ),
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Neue Noten empfangen: $name')),
          );
        }
      }

      if (type == 'status') {
        setState(() => _status = map['text'] ?? '');
      }
    } catch (e) {
      debugPrint('Fehler beim Verarbeiten: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Widget _buildReceivedList() {
    if (_received.isEmpty) {
      return const Center(
        child: Text(
          'Keine Noten empfangen.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _received.length,
      itemBuilder: (context, i) {
        final p = _received[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, size: 36, color: Colors.black87),
            title: Text(
              p.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Empfangen: ${p.receivedAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.black87),
              tooltip: 'Datei öffnen (noch nicht implementiert)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Datei gespeichert: ${p.path}')),
                );
                // TODO: Datei-Öffnen implementieren
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // eInk-freundlich
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Marschpad Musiker', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Instrument:', widget.instrument, fontWeight: FontWeight.bold, fontSize: 22),
              const SizedBox(height: 4),
              _buildInfoRow('Stimme:', widget.voice, fontWeight: FontWeight.w500, fontSize: 20, color: Colors.black54),
              const SizedBox(height: 8),
              if (_localIp != null)
                _buildInfoRow('Eigene IP:', _localIp!, fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black54),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Status: $_status',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.wifi_protected_setup, size: 28),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          child: Text('Neu verbinden', style: TextStyle(fontSize: 20)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _initLocalIpAndConnect,
                      ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Erhaltene Noten:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildReceivedList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 16,
    Color color = Colors.black,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: label + ' ', style: TextStyle(fontWeight: fontWeight, fontSize: fontSize, color: color)),
          TextSpan(text: value, style: TextStyle(fontSize: fontSize, color: color)),
        ],
      ),
    );
  }
}

class ReceivedPiece {
  final String name;
  final String path;
  final DateTime receivedAt;

  ReceivedPiece({
    required this.name,
    required this.path,
    required this.receivedAt,
  });
}

/// Beispielhafte Implementierung für saveBytesAsFile (aus shared.dart)
Future<File> saveBytesAsFile(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
