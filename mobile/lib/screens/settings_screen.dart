import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vpn_manager.dart';
import '../services/network_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _ConnectionSettings(),
          const Divider(),
          const _DeviceSettings(),
          const Divider(),
          const _AboutSection(),
        ],
      ),
    );
  }
}

class _ConnectionSettings extends StatelessWidget {
  const _ConnectionSettings();

  @override
  Widget build(BuildContext context) {
    final vpnManager = context.watch<VPNManager>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Connection Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Always Use VPN'),
          subtitle: const Text('Force VPN even when on same network as host'),
          value: vpnManager.alwaysUseVPN,
          onChanged: (value) {
            vpnManager.setAlwaysUseVPN(value);
          },
        ),
        SwitchListTile(
          title: const Text('Never Use VPN on Wi-Fi'),
          subtitle: const Text('Only allow VPN on cellular connection'),
          value: vpnManager.neverUseVPNOnWiFi,
          onChanged: (value) {
            vpnManager.setNeverUseVPNOnWiFi(value);
          },
        ),
        SwitchListTile(
          title: const Text('LAN Only'),
          subtitle: const Text('Disable VPN completely, only connect on local network'),
          value: vpnManager.lanOnly,
          onChanged: (value) {
            vpnManager.setLanOnly(value);
          },
        ),
        ListTile(
          title: const Text('Trusted Networks'),
          subtitle: Text('${vpnManager.trustedNetworks.length} networks'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            _showTrustedNetworks(context);
          },
        ),
      ],
    );
  }

  void _showTrustedNetworks(BuildContext context) {
    final vpnManager = context.read<VPNManager>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trusted Networks'),
        content: SizedBox(
          width: double.maxFinite,
          child: vpnManager.trustedNetworks.isEmpty
              ? const Text('No trusted networks configured')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: vpnManager.trustedNetworks.length,
                  itemBuilder: (context, index) {
                    final ssid = vpnManager.trustedNetworks[index];
                    return ListTile(
                      title: Text(ssid),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          vpnManager.removeTrustedNetwork(ssid);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addTrustedNetwork(context);
            },
            child: const Text('Add Network'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addTrustedNetwork(BuildContext context) {
    final controller = TextEditingController();
    final vpnManager = context.read<VPNManager>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Trusted Network'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Wi-Fi SSID',
            hintText: 'Home WiFi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                vpnManager.addTrustedNetwork(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DeviceSettings extends StatelessWidget {
  const _DeviceSettings();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Device Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('Device Name'),
          subtitle: const Text('My iPhone'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            // TODO: Edit device name
          },
        ),
        ListTile(
          title: const Text('Unpair Device'),
          subtitle: const Text('Remove this device from the host'),
          trailing: const Icon(Icons.link_off, color: Colors.red),
          onTap: () {
            _showUnpairDialog(context);
          },
        ),
      ],
    );
  }

  void _showUnpairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text(
          'Are you sure you want to unpair this device? You will need to scan a QR code again to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Unpair device
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/pairing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          title: const Text('View on GitHub'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            // TODO: Open GitHub
          },
        ),
        const ListTile(
          title: Text('License'),
          subtitle: Text('TBD'),
        ),
      ],
    );
  }
}
