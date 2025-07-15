import 'package:flutter/material.dart';

class NormalDiagram extends StatelessWidget {
  final List<Map<String, dynamic>> subnets;
  final List<Map<String, String>> connections;

  const NormalDiagram({
    super.key,
    required this.subnets,
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
              'Diagrama de Subredes',
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
          // Fila de subredes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: subnets.map((subnet) {
              return _buildSubnetCard(subnet);
            }).toList(),
          ),
          
          // Conexiones seriales (solo líneas con texto)
          if (connections.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...connections.map((conn) => _buildConnectionLine(conn)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubnetCard(Map<String, dynamic> subnet) {
    // Solo mostrar tarjetas para subredes que no son seriales
    if (subnet['type'] == 'serial') {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue,
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
          const Icon(
            Icons.lan,
            size: 36,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            subnet['route'] ?? 'Subred',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${subnet['hosts']} hosts',
            style: const TextStyle(color: Colors.white70),
          ),
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
          const Text(
            '(Serial)',
            style: TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}