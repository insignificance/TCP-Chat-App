import 'package:flutter/material.dart';
import '../models/discovered_device.dart';
import '../services/network_scanner.dart';

/// 设备发现页面
/// 扫描局域网内的可用设备
class DeviceDiscoveryPage extends StatefulWidget {
  final int targetPort;

  const DeviceDiscoveryPage({super.key, this.targetPort = 8888});

  @override
  State<DeviceDiscoveryPage> createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends State<DeviceDiscoveryPage> {
  final NetworkScanner _scanner = NetworkScanner();
  final List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _localIP;

  @override
  void initState() {
    super.initState();
    _initAndScan();
  }

  Future<void> _initAndScan() async {
    // 尝试获取网关IP
    final gatewayIP = await _scanner.getGatewayIP();
    
    if (gatewayIP != null) {
      // 如果有网关，优先扫描网关所在网段
      _localIP = gatewayIP; // 使用网关IP作为参考
      _startScan();
    } else {
      // 如果没有网关，获取所有本地IP
      final ips = await _scanner.getLocalIPs();
      if (ips.isNotEmpty) {
        // 默认使用第一个，或者可以扫描所有
        _localIP = ips.first;
        _startScan();
        
        // 如果有多个IP，后续可以添加UI让用户选择
        if (ips.length > 1) {
          // TODO: 显示网段选择器
        }
      }
    }
  }

  void _startScan() async {
    if (_localIP == null) return;

    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    final subnet = _scanner.getSubnet(_localIP!);
    if (subnet == null) return;

    await for (var device in _scanner.scanNetwork(
      subnet: subnet,
      port: widget.targetPort,
    )) {
      if (mounted) {
        setState(() {
          _devices.add(device);
        });
      }
    }

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '局域网设备扫描',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade800, Colors.teal.shade600],
            ),
          ),
        ),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: '重新扫描',
              onPressed: _startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildScanInfo(),
          if (_isScanning) _buildProgress(),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildScanInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, color: Colors.teal.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前网段: ${_scanner.getSubnet(_localIP ?? "")}.x',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '扫描端口: ${widget.targetPort}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            '扫描中... 已发现 ${_devices.length} 个设备',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (!_isScanning && _devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '未发现设备',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              '确保设备已连接到同一局域网',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pop(context, device),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.ipAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '端口 ${device.openPorts.join(", ")} 已开放',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
