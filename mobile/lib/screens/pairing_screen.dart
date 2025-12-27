import 'package:flutter/material.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  bool _isScanning = false;
  List<dynamic> _discoveredHosts = [];

  @override
  void initState() {
    super.initState();
    _discoverHosts();
  }

  Future<void> _discoverHosts() async {
    setState(() {
      _isScanning = true;
    });

    // TODO: Implement actual mDNS discovery
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isScanning = false;
      // Simulate discovered hosts
      _discoveredHosts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Photo Host'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to PixlSrve',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connect to your photo host to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            if (_isScanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Discovering hosts on local network...'),
                ],
              )
            else if (_discoveredHosts.isEmpty)
              const Text(
                'No hosts found on local network',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._discoveredHosts.map((host) => _buildHostCard(host)).toList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanQRCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addManually,
                icon: const Icon(Icons.add),
                label: const Text('Add Host Manually'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            if (_discoveredHosts.isEmpty && !_isScanning)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton(
                  onPressed: _discoverHosts,
                  child: const Text('Retry Discovery'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCard(dynamic host) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.computer),
        title: Text(host['name'] as String),
        subtitle: Text('${host['photo_count']} photos'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          // TODO: Connect to host
        },
      ),
    );
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code scanning not yet implemented')),
    );
  }

  void _addManually() {
    showDialog(
      context: context,
      builder: (context) => const _ManualAddDialog(),
    );
  }
}

class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Host Manually'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.1.100',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8080',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Connect to host
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manual pairing not yet implemented')),
            );
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
