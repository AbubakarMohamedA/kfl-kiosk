import 'package:flutter/material.dart';
import 'package:sss/features/home/presentation/screens/home_screen.dart';
import 'package:sss/core/services/sync_service.dart';
import 'package:sss/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConnectionScreen extends StatefulWidget {
  const ServerConnectionScreen({super.key});

  @override
  State<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends State<ServerConnectionScreen> {
  final _ipController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  String? _troubleshootingStep;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null) {
      _ipController.text = savedIp;
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _troubleshootingStep = null;
    });

    try {
      final syncService = getIt<SyncService>();
      final result = await syncService.connectAndSync(ip);
      
      if (!result.success) {
        setState(() {
          _errorMessage = result.message;
          _troubleshootingStep = result.troubleshootingStep;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()), 
        );
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, size: 80, color: Color(0xFF1a237e)),
              const SizedBox(height: 24),
              const Text(
                'Connect to Server',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the IP address displayed on the Desktop App', // User instruction
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Server IP Address',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 192.168.1.10',
                  prefixIcon: Icon(Icons.wifi),
                ),
                keyboardType: TextInputType.number,
              ),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_troubleshootingStep != null) ...[
                        const Divider(),
                        Text(
                          _troubleshootingStep!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a237e),
                    foregroundColor: Colors.white,
                  ),
                  child: _isConnecting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Connect'),
                ),
              ),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Troubleshooting Checklist:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildChecklist([
                'Both devices are on the SAME Wi-Fi network.',
                'Windows/Linux Firewall allows Port 8080.',
                'The IP address matches the one on Desktop.',
                'If using an emulator, try 10.0.2.2.',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
