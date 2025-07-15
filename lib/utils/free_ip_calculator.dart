import 'subnet_calculator.dart';

class FreeIpCalculator {
  static List<Map<String, String>> calculateFreeSubnets(
    List<Map<String, dynamic>> requirements,
    List<Map<String, String>> connections,
  ) {
    final subnets = <Map<String, String>>[];

    // 1. Ordenar los routers por clase y tamaño
    final sortedRequirements = _sortRequirements(requirements);

    // 2. Procesar cada router en el orden ordenado
    for (int i = 0; i < sortedRequirements.length; i++) {
      final req = sortedRequirements[i];
      final route = req['route'] as String;
      final ipClass = req['class'] as String;
      // final requiredHosts = req['hosts'] as int?;
      // final requiredSubnets = req['subnets'] as int?;

      // Determinar si es el último router
      final isLastRouter = i == sortedRequirements.length - 1;

      if (ipClass.toUpperCase() == 'A') {
        _processClassA(req, route, subnets, isLastRouter, connections);
      } else if (ipClass.toUpperCase() == 'B') {
        _processClassB(req, route, subnets, isLastRouter, connections);
      } else if (ipClass.toUpperCase() == 'C') {
        _processClassC(req, route, subnets, isLastRouter, connections);
      }
    }

    return subnets;
  }

  // Método para ordenar los requerimientos
  static List<Map<String, dynamic>> _sortRequirements(
    List<Map<String, dynamic>> requirements,
  ) {
    requirements.sort((a, b) {
      // Primero ordenar por clase (A < B < C)
      final classA = a['class'].toString().toUpperCase();
      final classB = b['class'].toString().toUpperCase();
      final classOrder = classA.compareTo(classB);
      if (classOrder != 0) return classOrder;

      // Dentro de cada clase, primero procesar subredes luego hosts
      final hasSubnetsA = a.containsKey('subnets') && a['subnets'] != null;
      final hasSubnetsB = b.containsKey('subnets') && b['subnets'] != null;

      // Si ambos tienen subredes, ordenar por cantidad (mayor a menor)
      if (hasSubnetsA && hasSubnetsB) {
        final subA = a['subnets'] as int;
        final subB = b['subnets'] as int;
        return subB.compareTo(subA);
      }

      // Si A tiene subredes y B no, A va primero
      if (hasSubnetsA) return -1;

      // Si B tiene subredes y A no, B va primero
      if (hasSubnetsB) return 1;

      // Si ambos tienen hosts, ordenar por cantidad (mayor a menor)
      final hostsA = a['hosts'] as int;
      final hostsB = b['hosts'] as int;
      return hostsB.compareTo(hostsA);
    });

    return requirements;
  }

  static bool _isValidPrivateIP(String ip, String ipClass) {
    final parts = ip.split('.').map(int.parse).toList();

    switch (ipClass.toUpperCase()) {
      case 'A':
        // Rango válido: 10.0.0.0 - 10.255.255.255
        return parts[0] == 10;
      case 'B':
        // Rango válido: 172.16.0.0 - 172.31.255.255
        return parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31;
      case 'C':
        // Rango válido: 192.168.0.0 - 192.168.255.255
        return parts[0] == 192 && parts[1] == 168;
      default:
        return false;
    }
  }

  // Resto de los métodos permanecen igual...
  static void _processClassA(
    Map<String, dynamic> req,
    String route,
    List<Map<String, String>> subnets,
    bool isLastRouter,
    List<Map<String, String>> connections,
  ) {
    final requiredSubnets = req['subnets'] as int?;
    final requiredHosts = req['hosts'] as int?;

    // Función de validación para Clase A
    bool isValidClassAIP(String ip) {
      final parts = ip.split('.').map(int.parse).toList();
      return parts[0] == 10; // Solo 10.x.x.x es válido para Clase A privada
    }

    if (requiredSubnets != null) {
      // Procesamiento por subredes
      final bitsNeeded = _calculateBitsNeeded(requiredSubnets);
      final prefix = 8 + bitsNeeded;
      final increment = 256 >> bitsNeeded;
      String currentIP = '10.0.0.0';

      for (int i = 0; i < requiredSubnets; i++) {
        // Validar que la IP generada sea 10.x.x.x
        if (!isValidClassAIP(currentIP)) {
          throw 'Error en Clase A: IP generada fuera de rango privado ($currentIP). '
              'El rango válido es 10.0.0.0/8.';
        }

        final mask = _prefixToMask(prefix);
        final broadcast = _calculateBroadcast(currentIP, mask);
        final range = _calculateValidRange(currentIP, broadcast);

        subnets.add({
          'type': 'router',
          'route': '$route.${i + 1}',
          'network': '$currentIP/$prefix',
          'gateway': incrementIp(currentIP, 1),
          'first': range['first']!,
          'last': range['last']!,
          'broadcast': broadcast,
        });

        final parts = currentIP.split('.').map(int.parse).toList();
        parts[1] += increment;
        if (parts[1] > 255) {
          parts[0] += parts[1] ~/ 256;
          parts[1] = parts[1] % 256;
        }
        currentIP = parts.join('.');
      }
    } else if (requiredHosts != null) {
      // Procesamiento por hosts
      final bitsHosts = _calculateBitsHosts(requiredHosts);
      final prefix = 32 - bitsHosts;
      String currentIP = '10.0.0.0';

      // Buscar la última subred clase A para continuar
      final lastASubnet = subnets.lastWhere(
        (s) => s['network']!.startsWith('10.'),
        orElse: () => {'network': '10.0.0.0/8'},
      );

      if (lastASubnet['network'] != '10.0.0.0/8') {
        currentIP = incrementIp(lastASubnet['broadcast']!, 1);
      }

      // Validar IP para hosts
      if (!isValidClassAIP(currentIP)) {
        throw 'Error en Clase A: IP generada fuera de rango privado ($currentIP). '
            'El rango válido es 10.0.0.0/8.';
      }

      final mask = _prefixToMask(prefix);
      final broadcast = _calculateBroadcast(currentIP, mask);
      final range = _calculateValidRange(currentIP, broadcast);

      subnets.add({
        'type': 'router',
        'route': route,
        'network': '$currentIP/$prefix',
        'gateway': incrementIp(currentIP, 1),
        'first': range['first']!,
        'last': range['last']!,
        'broadcast': broadcast,
      });
    }

    // Si es el último router, agregar seriales
    if (isLastRouter) {
      final lastSubnet = subnets.last;
      _addSerialConnections(lastSubnet['broadcast']!, connections, subnets);
    }
  }

  static void _processClassB(
    Map<String, dynamic> req,
    String route,
    List<Map<String, String>> subnets,
    bool isLastRouter,
    List<Map<String, String>> connections,
  ) {
    final requiredSubnets = req['subnets'] as int?;
    final requiredHosts = req['hosts'] as int?;

    if (requiredSubnets != null) {
      // Nuevo procesamiento por subredes (similar a clase A)
      final bitsNeeded = _calculateBitsNeeded(requiredSubnets);
      final prefix = 16 + bitsNeeded;
      final increment = 256 >> bitsNeeded;
      String currentIP = '172.16.0.0';

      // Buscar la última subred clase B para continuar
      final lastBSubnet = subnets.lastWhere(
        (s) => s['network']!.startsWith('172.'),
        orElse: () => {'network': '172.16.0.0/16'},
      );

      if (lastBSubnet['network'] != '172.16.0.0/16') {
        currentIP = incrementIp(lastBSubnet['broadcast']!, 1);
      }

      for (int i = 0; i < requiredSubnets; i++) {
        final mask = _prefixToMask(prefix);
        final broadcast = _calculateBroadcast(currentIP, mask);
        final range = _calculateValidRange(currentIP, broadcast);

        subnets.add({
          'type': 'router',
          'route': '$route.${i + 1}',
          'network': '$currentIP/$prefix',
          'gateway': incrementIp(currentIP, 1),
          'first': range['first']!,
          'last': range['last']!,
          'broadcast': broadcast,
        });

        final parts = currentIP.split('.').map(int.parse).toList();
        parts[2] += increment;
        if (parts[2] > 255) {
          parts[1] += parts[2] ~/ 256;
          parts[2] = parts[2] % 256;
        }
        currentIP = parts.join('.');
      }
    } else if (requiredHosts != null) {
      // Procesamiento por hosts (existente)
      final bitsHosts = _calculateBitsHosts(requiredHosts);
      final prefix = 32 - bitsHosts;
      String currentIP = '172.16.0.0';

      final lastBSubnet = subnets.lastWhere(
        (s) => s['network']!.startsWith('172.'),
        orElse: () => {'network': '172.16.0.0/16'},
      );

      if (lastBSubnet['network'] != '172.16.0.0/16') {
        currentIP = incrementIp(lastBSubnet['broadcast']!, 1);
      }

      final mask = _prefixToMask(prefix);
      final broadcast = _calculateBroadcast(currentIP, mask);
      final range = _calculateValidRange(currentIP, broadcast);

      subnets.add({
        'type': 'router',
        'route': route,
        'network': '$currentIP/$prefix',
        'gateway': incrementIp(currentIP, 1),
        'first': range['first']!,
        'last': range['last']!,
        'broadcast': broadcast,
      });
    }

    // Si es el último router, agregar seriales
    if (isLastRouter) {
      final lastSubnet = subnets.last;
      _addSerialConnections(lastSubnet['broadcast']!, connections, subnets);
    }
  }

  static void _processClassC(
    Map<String, dynamic> req,
    String route,
    List<Map<String, String>> subnets,
    bool isLastRouter,
    List<Map<String, String>> connections,
  ) {
    final requiredSubnets = req['subnets'] as int?;
    final requiredHosts = req['hosts'] as int?;

    if (requiredSubnets != null) {
      // Nuevo procesamiento por subredes (similar a clase A)
      final bitsNeeded = _calculateBitsNeeded(requiredSubnets);
      final prefix = 24 + bitsNeeded;
      final increment = 256 >> bitsNeeded;
      String currentIP = '192.168.0.0';

      // Buscar la última subred clase C para continuar
      final lastCSubnet = subnets.lastWhere(
        (s) => s['network']!.startsWith('192.168'),
        orElse: () => {'network': '192.168.0.0/24'},
      );

      if (lastCSubnet['network'] != '192.168.0.0/24') {
        currentIP = incrementIp(lastCSubnet['broadcast']!, 1);
      }

      for (int i = 0; i < requiredSubnets; i++) {
        final mask = _prefixToMask(prefix);
        final broadcast = _calculateBroadcast(currentIP, mask);
        final range = _calculateValidRange(currentIP, broadcast);

        subnets.add({
          'type': 'router',
          'route': '$route.${i + 1}',
          'network': '$currentIP/$prefix',
          'gateway': incrementIp(currentIP, 1),
          'first': range['first']!,
          'last': range['last']!,
          'broadcast': broadcast,
        });

        final parts = currentIP.split('.').map(int.parse).toList();
        parts[3] += increment;
        if (parts[3] > 255) {
          parts[2] += parts[3] ~/ 256;
          parts[3] = parts[3] % 256;
        }
        currentIP = parts.join('.');
      }
    } else if (requiredHosts != null) {
      // Procesamiento por hosts (existente)
      final bitsHosts = _calculateBitsHosts(requiredHosts);
      final prefix = 32 - bitsHosts;
      String currentIP = '192.168.0.0';

      final lastCSubnet = subnets.lastWhere(
        (s) => s['network']!.startsWith('192.168'),
        orElse: () => {'network': '192.168.0.0/24'},
      );

      if (lastCSubnet['network'] != '192.168.0.0/24') {
        currentIP = incrementIp(lastCSubnet['broadcast']!, 1);
      }

      final mask = _prefixToMask(prefix);
      final broadcast = _calculateBroadcast(currentIP, mask);
      final range = _calculateValidRange(currentIP, broadcast);

      subnets.add({
        'type': 'router',
        'route': route,
        'network': '$currentIP/$prefix',
        'gateway': incrementIp(currentIP, 1),
        'first': range['first']!,
        'last': range['last']!,
        'broadcast': broadcast,
      });
    }

    // Si es el último router, agregar seriales
    if (isLastRouter) {
      final lastSubnet = subnets.last;
      _addSerialConnections(lastSubnet['broadcast']!, connections, subnets);
    }
  }

  static void _addSerialConnections(
    String lastBroadcast,
    List<Map<String, String>> connections,
    List<Map<String, String>> subnets,
  ) {
    String currentSerialIP = incrementIp(lastBroadcast, 1);

    for (int i = 0; i < connections.length; i++) {
      final conn = connections[i];
      final prefix = 30;
      final mask = _prefixToMask(prefix);
      final broadcast = _calculateBroadcast(currentSerialIP, mask);
      final range = _calculateValidRange(currentSerialIP, broadcast);

      subnets.add({
        'type': 'serial',
        'route': 'Serial${i + 1} (${conn['from']} ↔ ${conn['to']})',
        'network': '$currentSerialIP/$prefix',
        'gateway': incrementIp(currentSerialIP, 1),
        'first': range['first']!,
        'last': range['last']!,
        'broadcast': broadcast,
      });

      currentSerialIP = incrementIp(broadcast, 1);
    }
  }

  // Métodos auxiliares (igual que antes)
  static int _calculateBitsNeeded(int x) {
    int bits = 0;
    while ((1 << bits) < x) {
      bits++;
    }
    return bits;
  }

  static int _calculateBitsHosts(int x) {
    int bits = 0;
    while ((1 << bits) - 2 < x) {
      bits++;
    }
    return bits;
  }

  static String _prefixToMask(int prefix) {
    return SubnetCalculator.prefixToMask(prefix);
  }

  static String _calculateBroadcast(String network, String mask) {
    return SubnetCalculator.calculateBroadcast(network, mask);
  }

  static Map<String, String> _calculateValidRange(
    String network,
    String broadcast,
  ) {
    return SubnetCalculator.calculateValidRange(network, broadcast);
  }

  static String incrementIp(String ip, int increment) {
    final parts = ip.split('.').map((e) => int.parse(e)).toList();
    parts[3] += increment;

    for (int i = 3; i >= 0; i--) {
      if (parts[i] > 255) {
        parts[i] = 0;
        if (i > 0) parts[i - 1]++;
      }
    }
    return parts.join('.');
  }
}
