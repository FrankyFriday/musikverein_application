import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'musician_page.dart';

class MusicianSetupPage extends StatefulWidget {
  const MusicianSetupPage({super.key});

  @override
  State<MusicianSetupPage> createState() => _MusicianSetupPageState();
}

class _MusicianSetupPageState extends State<MusicianSetupPage> {
  final _instruments = [
    'Flöte', 'Klarinette', 'Trompete', 'Horn',
    'Posaune', 'Saxophon', 'Tuba', 'Tenorhorn'
  ];

  final _voices = ['1. Stimme', '2. Stimme', '3. Stimme'];

  String? _selectedInstrument;
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedInstrument = prefs.getString('instrument');
      _selectedVoice = prefs.getString('voice');
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedInstrument != null) {
      await prefs.setString('instrument', _selectedInstrument!);
    }
    if (_selectedVoice != null) {
      await prefs.setString('voice', _selectedVoice!);
    }
  }

  void _openMusician() async {
    if (_selectedInstrument == null || _selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Instrument und Stimme wählen.')),
      );
      return;
    }

    await _savePrefs();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MusicianPage(
          instrument: _selectedInstrument!,
          voice: _selectedVoice!, conductorPort: 4041,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Musiker – Setup'),
        centerTitle: true,
        elevation: 3,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wähle dein Instrument',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _buildDropdown(
                value: _selectedInstrument,
                items: _instruments,
                onChanged: (v) => setState(() => _selectedInstrument = v),
              ),

              const SizedBox(height: 24),

              Text(
                'Wähle deine Stimme',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _buildDropdown(
                value: _selectedVoice,
                items: _voices,
                onChanged: (v) => setState(() => _selectedVoice = v),
              ),

              const SizedBox(height: 48),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _openMusician,
                  child: const Text(
                    'Weiter als Musiker',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[300]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: const Text(
          'Bitte wählen',
          style: TextStyle(color: Colors.white70),
        ),
        isExpanded: true,
        dropdownColor: Colors.blue[700],
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        underline: const SizedBox(),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
