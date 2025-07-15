import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/free_ip_calculator.dart';

class FreeIpInputPanel extends StatefulWidget {
  final Function(
    List<Map<String, String>>,
    List<Map<String, dynamic>>,
    List<Map<String, String>>,
  )
  onCalculate;

  const FreeIpInputPanel({super.key, required this.onCalculate});

  @override
  State<FreeIpInputPanel> createState() => _FreeIpInputPanelState();
}

class _FreeIpInputPanelState extends State<FreeIpInputPanel> {
  final List<Map<String, dynamic>> _requirements = [];
  final List<Map<String, String>> _connections = [];
  final _routeController = TextEditingController();
  String _selectedClass = 'A';
  int? _hosts;
  int? _subnets;
  String? _connectionFrom;
  String? _connectionTo;
  final _hostsController = TextEditingController();
  final _subnetsController = TextEditingController();

  @override
  void dispose() {
    _routeController.dispose();
    _hostsController.dispose();
    _subnetsController.dispose();
    super.dispose();
  }

  bool _allRoutersConnected() {
    if (_requirements.length <= 1) return true;

    final connectedRouters = <String>{};
    for (final conn in _connections) {
      connectedRouters.add(conn['from']!);
      connectedRouters.add(conn['to']!);
    }

    final allRouters = _requirements.map((r) => r['route'] as String).toSet();
    return connectedRouters.containsAll(allRouters);
  }

  void _addRequirement() {
    if (_routeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el router')),
      );
      return;
    }

    if (_hosts == null && _subnets == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar Hosts o Subredes')),
      );
      return;
    }

    setState(() {
      _requirements.add({
        'route': _routeController.text,
        'class': _selectedClass,
        'hosts': _hosts,
        'subnets': _subnets,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _routeController.clear();
      _hosts = null;
      _subnets = null;
      _hostsController.clear();
      _subnetsController.clear();
    });
  }

  void _addConnection() {
    if (_connectionFrom == null || _connectionTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona ambos routers para conectar')),
      );
      return;
    }

    if (_connectionFrom == _connectionTo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes conectar un router consigo mismo'),
        ),
      );
      return;
    }

    setState(() {
      _connections.add({
        'from': _connectionFrom!,
        'to': _connectionTo!,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _connectionFrom = null;
      _connectionTo = null;
    });
  }

  void _removeRequirement(String id) {
    setState(() {
      _requirements.removeWhere((req) => req['id'] == id);
      _connections.removeWhere(
        (conn) => conn['from'] == id || conn['to'] == id,
      );
    });
  }

  void _removeConnection(int index) {
    setState(() {
      _connections.removeAt(index);
    });
  }

  void _calculate() {
    try {
      if (_requirements.isEmpty) {
        throw 'Agrega al menos un router';
      }

      if (_requirements.length > 1 && !_allRoutersConnected()) {
        throw 'Todos los routers deben estar conectados al menos una vez';
      }

      final results = FreeIpCalculator.calculateFreeSubnets(
        _requirements,
        _connections,
      );

      widget.onCalculate(results, _requirements, _connections);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo completado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Mostrar error detallado al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getUserFriendlyError(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Entendido',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('Clase A soporta máximo')) {
      return 'Error en Clase A:\n$error\n\nSolución: Reduce el número de subredes o usa otra clase';
    }

    if (error.contains('Clase B soporta máximo')) {
      return 'Error en Clase B:\n$error\n\nSolución: Reduce el número de hosts requeridos';
    }

    if (error.contains('Clase C soporta máximo')) {
      return 'Error en Clase C:\n$error\n\nSolución: El máximo para Clase C es 254 hosts por subred';
    }

    if (error.contains('Se excedió el rango')) {
      return 'Error de rango:\n$error\n\nSolución: Configura menos hosts/subredes o reinicia el cálculo';
    }

    if (error.contains('Todos los routers deben estar conectados')) {
      return 'Error de conexión:\n$error\n\nSolución: Conecta todos los routers con líneas seriales';
    }

    return 'Error:\n$error\n\nPor favor verifica tus datos y vuelve a intentar';
  }

  void _clearAll() {
    setState(() {
      _requirements.clear();
      _connections.clear();
      _routeController.clear();
      _hostsController.clear();
      _subnetsController.clear();
      _selectedClass = 'A';
      _hosts = null;
      _subnets = null;
      _connectionFrom = null;
      _connectionTo = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos los datos han sido limpiados'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routerNames = _requirements.map((r) => r['route'] as String).toList();

    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuración de Red',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Sección de routers
              const Text(
                'Agregar Router',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'Nombre (ej: R1)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.router),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Clase IP',
                        border: OutlineInputBorder(),
                      ),
                      items: ['A', 'B', 'C'].map((cls) {
                        return DropdownMenuItem(
                          value: cls,
                          child: Text('Clase $cls'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedClass = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hostsController,
                      decoration: const InputDecoration(
                        labelText: 'Hosts (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _hosts = int.tryParse(value);
                          _subnetsController.clear();
                          _subnets = null;
                        } else {
                          _hosts = null;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _subnetsController,
                      decoration: const InputDecoration(
                        labelText: 'Subredes (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _subnets = int.tryParse(value);
                          _hostsController.clear();
                          _hosts = null;
                        } else {
                          _subnets = null;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _addRequirement,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Agregar Router'),
              ),
              const SizedBox(height: 20),

              // Sección de conexiones
              const Divider(),
              const Text(
                'Conexiones Seriales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _connectionFrom,
                      decoration: const InputDecoration(
                        labelText: 'Desde',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.start),
                      ),
                      items: routerNames.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _connectionFrom = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _connectionTo,
                      decoration: const InputDecoration(
                        labelText: 'Hacia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: routerNames.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _connectionTo = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _addConnection,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Agregar Conexión'),
              ),
              const SizedBox(height: 12),
              if (_connections.isNotEmpty) ...[
                const Text(
                  'Conexiones definidas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._connections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final conn = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cable, color: Colors.blue),
                    title: Text('${conn['from']} ↔ ${conn['to']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeConnection(index),
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 20),

              // Lista de routers
              const Divider(),
              const Text(
                'Routers Configurados:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_requirements.isEmpty)
                const Text('No hay routers agregados')
              else
                ..._requirements.map((req) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.router,
                        color: _getClassColor(req['class']),
                      ),
                      title: Text(
                        req['route'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Clase ${req['class']}'
                        '${req['hosts'] != null ? ' • ${req['hosts']} hosts' : ''}'
                        '${req['subnets'] != null ? ' • ${req['subnets']} subredes' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeRequirement(req['id']),
                      ),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20),

              // Botón de cálculo
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calculate),
                      label: const Text('CALCULAR'),
                      onPressed: _requirements.isNotEmpty ? _calculate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('LIMPIAR TODO'),
                      onPressed: _requirements.isNotEmpty ? _clearAll : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
