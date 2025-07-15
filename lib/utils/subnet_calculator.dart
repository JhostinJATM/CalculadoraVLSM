class SubnetCalculator {
  static bool validateIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  static String prefixToMask(int prefix) {
    var mask = '';
    for (int i = 0; i < 4; i++) {
      var bits = 0;
      for (int j = 0; j < 8; j++) {
        bits = (bits << 1) | (i * 8 + j < prefix ? 1 : 0);
      }
      mask += i > 0 ? '.$bits' : '$bits';
    }
    return mask;
  }

  static String calculateBroadcast(String network, String mask) {
    final networkParts = network.split('.').map((e) => int.parse(e)).toList();
    final maskParts = mask.split('.').map((e) => int.parse(e)).toList();

    var broadcast = '';
    for (int i = 0; i < 4; i++) {
      final bcPart = networkParts[i] | (~maskParts[i] & 0xFF);
      broadcast += i > 0 ? '.$bcPart' : '$bcPart';
    }
    return broadcast;
  }

  static Map<String, String> calculateValidRange(String network, String broadcast) {
    final networkParts = network.split('.').map((e) => int.parse(e)).toList();
    final broadcastParts = broadcast.split('.').map((e) => int.parse(e)).toList();

    var first = List<int>.from(networkParts)..[3] += 1;
    _adjustOverflow(first);

    var last = List<int>.from(broadcastParts)..[3] -= 1;
    _adjustUnderflow(last);

    return {'first': first.join('.'), 'last': last.join('.')};
  }

  static void _adjustOverflow(List<int> ip) {
    for (int i = 3; i >= 0; i--) {
      if (ip[i] > 255) {
        ip[i] = 0;
        if (i > 0) ip[i - 1] += 1;
      }
    }
  }

  static void _adjustUnderflow(List<int> ip) {
    for (int i = 3; i >= 0; i--) {
      if (ip[i] < 0) {
        ip[i] = 255;
        if (i > 0) ip[i - 1] -= 1;
      }
    }
  }

  static int findNextPrefix(int hostsNeeded) {
    int bits = 0;
    while ((1 << bits) - 2 < hostsNeeded) {
      bits++;
    }
    return 32 - bits;
  }

  static List<Map<String, String>> calculateSubnets(String network, List<int> hostsList) {
    hostsList.sort((a, b) => b.compareTo(a));
    var currentNetwork = network;
    final results = <Map<String, String>>[];

    for (var hosts in hostsList) {
      final prefix = findNextPrefix(hosts);
      final mask = prefixToMask(prefix);
      final broadcast = calculateBroadcast(currentNetwork, mask);
      final range = calculateValidRange(currentNetwork, broadcast);

      results.add({
        'subnet': currentNetwork,
        'mask': mask,
        'prefix': '/$prefix',
        'broadcast': broadcast,
        'first': range['first']!,
        'last': range['last']!,
        'hosts': hosts.toString(),
      });

      final nextParts = broadcast.split('.').map((e) => int.parse(e)).toList();
      nextParts[3] += 1;
      _adjustOverflow(nextParts);
      currentNetwork = nextParts.join('.');
    }

    return results;
  }
}