import 'package:flutter/material.dart';

class FreeIpDiagram extends StatelessWidget {
  final List<Map<String, dynamic>> routers;
  final List<Map<String, String>> connections;

  const FreeIpDiagram({
    super.key,
    required this.routers,
    required this.connections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagrama de Red IP Libre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNetworkTopology(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkTopology() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Fila de routers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: routers.map((router) {
              return _buildRouterCard(router);
            }).toList(),
          ),
          
          // Conexiones
          if (connections.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...connections.map((conn) => _buildConnectionLine(conn)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRouterCard(Map<String, dynamic> router) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getClassColor(router['class']),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.router, size: 36, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            router['route'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clase ${router['class']}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (router['hosts'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${router['hosts']} hosts',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (router['subnets'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${router['subnets']} subredes',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionLine(Map<String, String> connection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            connection['from']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward, color: Colors.blue),
          const SizedBox(width: 16),
          Text(
            connection['to']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Serial',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String? routerClass) {
    switch (routerClass) {
      case 'A':
        return Colors.blue.shade700;
      case 'B':
        return Colors.green.shade700;
      case 'C':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}