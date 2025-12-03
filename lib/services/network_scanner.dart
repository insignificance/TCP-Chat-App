import 'dart:async';
import 'dart:io';
import '../models/discovered_device.dart';

/// 网络扫描服务
/// 用于发现局域网内的设备
class NetworkScanner {
  /// 获取默认网关IP
  Future<String?> getGatewayIP() async {
    try {
      if (Platform.isMacOS || Platform.isIOS) {
        final result = await Process.run('route', ['-n', 'get', 'default']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final match = RegExp(r'gateway: (\d+\.\d+\.\d+\.\d+)').firstMatch(output);
          if (match != null) {
            return match.group(1);
          }
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('ip', ['route', 'show', 'default']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final match = RegExp(r'default via (\d+\.\d+\.\d+\.\d+)').firstMatch(output);
          if (match != null) {
            return match.group(1);
          }
        }
      } else if (Platform.isWindows) {
        // Windows implementation can be complex, skipping for now or using netstat
        // Simplified approach: return null and rely on interface list
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// 获取所有非回环IPv4地址
  Future<List<String>> getLocalIPs() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list();
      
      // 排序接口：优先 Wi-Fi (wlan0, en0)，其次是以太网 (eth0, en1)
      interfaces.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        
        // 1. 接口名称优先级
        int scoreA = 0;
        int scoreB = 0;
        
        if (aName.contains('wlan') || aName == 'en0') scoreA += 10;
        if (bName.contains('wlan') || bName == 'en0') scoreB += 10;
        
        if (aName.contains('eth')) scoreA += 5;
        if (bName.contains('eth')) scoreB += 5;
        
        if (scoreA != scoreB) return scoreB - scoreA;
        
        return 0;
      });

      for (var interface in interfaces) {
        // 排除虚拟接口、VPN、桥接等
        final name = interface.name.toLowerCase();
        if (name.contains('rmnet') || // Android Mobile Data
            name.contains('tun') ||   // VPN
            name.contains('tap') ||
            name.contains('docker') || 
            name.contains('veth') ||
            name.contains('br') ||    // Bridge
            name.contains('bridge') ||
            name.contains('virbr') || // Libvirt
            name.contains('vbox') ||  // VirtualBox
            name.contains('vmnet')) { // VMware
          continue;
        }

        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // 简单的私有地址检查
            // 优先 192.168.x.x (家庭/小型办公网络)
            if (addr.address.startsWith('192.168.')) {
              ips.insert(0, addr.address); // 插入到最前面
            } 
            // 其次 10.x.x.x (企业/大型网络，但也常用于Docker/VPN，所以优先级较低)
            else if (addr.address.startsWith('10.')) {
              ips.add(addr.address);
            }
            // 最后 172.16-31.x.x
            else if (addr.address.startsWith('172.') && _isClassB(addr.address)) {
              ips.add(addr.address);
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return ips;
  }

  bool _isClassB(String ip) {
    try {
      final secondOctet = int.parse(ip.split('.')[1]);
      return secondOctet >= 16 && secondOctet <= 31;
    } catch (e) {
      return false;
    }
  }

  /// 扫描指定网段的所有设备
  /// [subnet] 网段前缀，如 "192.168.1"
  /// [port] 要检测的端口，默认8888
  /// [timeout] 超时时间（毫秒）
  Stream<DiscoveredDevice> scanNetwork({
    required String subnet,
    int port = 8888,
    int timeout = 500,
  }) async* {
    // 扫描1-255的所有IP
    final futures = <Future<DiscoveredDevice?>>[];
    
    for (int i = 1; i <= 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkHost(ip, port, timeout));
    }

    // 并发执行所有扫描，按完成顺序返回结果
    final results = await Future.wait(futures);
    for (var device in results) {
      if (device != null && device.isReachable) {
        yield device;
      }
    }
  }

  /// 检查单个主机
  Future<DiscoveredDevice?> _checkHost(String ip, int port, int timeout) async {
    try {
      // 尝试连接指定端口
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: timeout),
      ).timeout(Duration(milliseconds: timeout));
      
      await socket.close();
      
      // 连接成功，说明设备可达且端口开放
      return DiscoveredDevice(
        ipAddress: ip,
        isReachable: true,
        openPorts: [port],
      );
    } catch (e) {
      // 连接失败，设备不可达或端口未开放
      return null;
    }
  }

  /// 快速扫描（仅检查可达性，不检测端口）
  Stream<DiscoveredDevice> quickScan({required String subnet}) async* {
    final futures = <Future<DiscoveredDevice?>>[];
    
    for (int i = 1; i <= 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_pingHost(ip));
    }

    final results = await Future.wait(futures);
    for (var device in results) {
      if (device != null && device.isReachable) {
        yield device;
      }
    }
  }

  /// Ping单个主机（使用TCP连接模拟）
  Future<DiscoveredDevice?> _pingHost(String ip) async {
    try {
      // 尝试连接常见端口（如80, 443, 22等）快速检测
      final socket = await Socket.connect(
        ip,
        80, // HTTP端口
        timeout: const Duration(milliseconds: 300),
      ).timeout(const Duration(milliseconds: 300));
      
      await socket.close();
      
      return DiscoveredDevice(
        ipAddress: ip,
        isReachable: true,
        openPorts: [80],
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取当前网段前缀
  /// 例如从 "192.168.1.100" 返回 "192.168.1"
  String? getSubnet(String? ip) {
    if (ip == null) return null;
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
}
