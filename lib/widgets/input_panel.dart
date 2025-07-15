import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputPanel extends StatelessWidget {
  final TextEditingController networkController;
  final List<TextEditingController> hostsControllers;
  final List<bool> isBridgeList;
  final String errorMessage;
  final VoidCallback onAddHost;
  final Function(int) onRemoveHost;
  final Function(int) onToggleBridge;
  final List<Map<String, String>> connections;
  final Function(String, String) onAddConnection;
  final Function(int) onRemoveConnection;

  InputPanel({
    super.key,
    required this.networkController,
    required this.hostsControllers,
    required this.isBridgeList,
    required this.errorMessage,
    required this.onAddHost,
    required this.onRemoveHost,
    required this.onToggleBridge,
    required this.connections,
    required this.onAddConnection,
    required this.onRemoveConnection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subredNames = hostsControllers.asMap().entries.map((entry) {
      return 'Subred ${entry.key + 1}';
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configuración de Red',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: networkController,
                decoration: InputDecoration(
                  labelText: 'Red Principal (ej: 192.168.1.0)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lan),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => networkController.clear(),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Hosts por Subred',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              ...hostsControllers.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: 'Subred ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.computer),
                            enabled: !isBridgeList[index],
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => onRemoveHost(index),
                      ),
                      IconButton(
                        icon: Icon(
                          isBridgeList[index] ? Icons.link : Icons.link_off,
                          color: isBridgeList[index] ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () => onToggleBridge(index),
                        tooltip: isBridgeList[index] ? 'Router puente' : 'Router normal',
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Agregar Subred'),
                onPressed: onAddHost,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Sección de conexiones seriales
              const Divider(),
              Text(
                'Conexiones Seriales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (subredNames.length >= 2) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.start),
                        ),
                        items: subredNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _selectedFrom = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Hacia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: subredNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _selectedTo = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedFrom != null && _selectedTo != null) {
                      onAddConnection(_selectedFrom!, _selectedTo!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona ambos routers para conectar')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Agregar Conexión'),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const Text(
                  'Necesitas al menos 2 subredes para crear conexiones',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
              
              if (connections.isNotEmpty) ...[
                const Text(
                  'Conexiones definidas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...connections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final conn = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cable, color: Colors.blue),
                    title: Text('${conn['from']} ↔ ${conn['to']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onRemoveConnection(index),
                    ),
                  );
                }).toList(),
              ],
              
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String? _selectedFrom;
  String? _selectedTo;
}