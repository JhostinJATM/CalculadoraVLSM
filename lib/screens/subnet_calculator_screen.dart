import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/subnet_calculator.dart';
import '../utils/free_ip_calculator.dart';
import '../widgets/input_panel.dart';
import '../widgets/results_panel.dart';
import '../widgets/free_ip_input_panel.dart';
import '../widgets/free_ip_results_panel.dart';
import '../widgets/normal_diagram.dart';
import '../widgets/free_ip_diagram.dart';
import '../widgets/action_buttons.dart';
import '../dialogs/help_dialog.dart';
import '../dialogs/history_dialog.dart';
import '../dialogs/tools_modal.dart';
import '../dialogs/functioning_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/ip_binary_dialog.dart';
import '../dialogs/prefix_table_dialog.dart';
import '../utils/ip_converter.dart';

class SubnetCalculatorScreen extends StatefulWidget {
  const SubnetCalculatorScreen({super.key});

  @override
  State<SubnetCalculatorScreen> createState() => _SubnetCalculatorScreenState();
}

class _SubnetCalculatorScreenState extends State<SubnetCalculatorScreen> {
  // Estado para modo normal
  final TextEditingController _networkController = TextEditingController();
  final List<TextEditingController> _hostsControllers = [];
  final List<bool> _isBridgeList = [];
  List<Map<String, String>> _subnets = [];
  List<Map<String, dynamic>> _normalRequirements = [];
  List<Map<String, String>> _normalConnections = [];
  bool _isNormalCalculated = false;
  String _errorMessage = '';

  // Estado para modo IP libre
  List<Map<String, String>> _freeIpResults = [];
  List<Map<String, dynamic>> _freeIpRequirements = [];
  List<Map<String, String>> _freeIpConnections = [];
  bool _isFreeIpCalculated = false;

  int _currentIndex = 0;
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _addHostField();
  }

  @override
  void dispose() {
    _networkController.dispose();
    for (var controller in _hostsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addHostField() {
    setState(() {
      _hostsControllers.add(TextEditingController());
      _isBridgeList.add(false);
    });
  }

  void _removeHostField(int index) {
    if (_hostsControllers.length > 1) {
      setState(() {
        _hostsControllers.removeAt(index);
        _isBridgeList.removeAt(index);
      });
    }
  }

  void _toggleBridge(int index) {
    setState(() {
      _isBridgeList[index] = !_isBridgeList[index];
      if (_isBridgeList[index]) {
        _hostsControllers[index].clear();
      }
    });
  }

  void _calculateSubnets() {
    if (!SubnetCalculator.validateIP(_networkController.text)) {
      setState(() {
        _errorMessage = 'Dirección IP inválida';
        _isNormalCalculated = false;
      });
      return;
    }

    // Verificar routers puente
    for (int i = 0; i < _isBridgeList.length; i++) {
      if (_isBridgeList[i]) {
        final connectionsCount = _normalConnections.where((conn) {
          return conn['from'] == 'Subred ${i + 1}' ||
              conn['to'] == 'Subred ${i + 1}';
        }).length;

        if (connectionsCount < 2) {
          setState(() {
            _errorMessage =
                'El router puente Subred ${i + 1} debe tener al menos 2 conexiones';
            _isNormalCalculated = false;
          });
          return;
        }
      }
    }

    final hostsList = <int>[];
    for (int i = 0; i < _hostsControllers.length; i++) {
      if (!_isBridgeList[i]) {
        final hosts = int.tryParse(_hostsControllers[i].text) ?? 0;
        if (hosts <= 0) {
          setState(() {
            _errorMessage = 'Número de hosts inválido (debe ser > 0)';
            _isNormalCalculated = false;
          });
          return;
        }
        hostsList.add(hosts);
      }
    }

    // Convertir a formato de requirements para usar el mismo sistema
    _normalRequirements = [];
    for (int i = 0; i < _hostsControllers.length; i++) {
      if (!_isBridgeList[i]) {
        final hosts = int.tryParse(_hostsControllers[i].text) ?? 0;
        _normalRequirements.add({
          'route': 'Subred ${i + 1}',
          'class': 'C', // Asumimos clase C para el modo normal
          'hosts': hosts,
          'id': 'subred_${i}',
        });
      }
    }

    setState(() {
      _subnets = SubnetCalculator.calculateSubnets(
        _networkController.text,
        hostsList,
      );

      // Si hay conexiones, calcular las seriales
      if (_normalConnections.isNotEmpty) {
        final lastBroadcast = _subnets.isNotEmpty
            ? _subnets.last['broadcast']!
            : _networkController.text;
        _addSerialConnections(lastBroadcast);
      }

      _isNormalCalculated = true;
      _errorMessage = '';
    });
  }

  void _addSerialConnections(String lastBroadcast) {
    String currentSerialIP = FreeIpCalculator.incrementIp(lastBroadcast, 1);

    for (int i = 0; i < _normalConnections.length; i++) {
      final conn = _normalConnections[i];
      final prefix = 30;
      final mask = SubnetCalculator.prefixToMask(prefix);
      final broadcast = SubnetCalculator.calculateBroadcast(
        currentSerialIP,
        mask,
      );
      final range = SubnetCalculator.calculateValidRange(
        currentSerialIP,
        broadcast,
      );

      _subnets.add({
        'type': 'serial',
        'route': 'Serial${i + 1} (${conn['from']} ↔ ${conn['to']})',
        'subnet': currentSerialIP,
        'prefix': '/$prefix',
        'mask': mask,
        'broadcast': broadcast,
        'first': range['first']!,
        'last': range['last']!,
        'hosts': '2',
      });

      currentSerialIP = FreeIpCalculator.incrementIp(broadcast, 1);
    }
  }

  void _exportResults(BuildContext context) {
    if (_subnets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay resultados para exportar')),
      );
      return;
    }

    final resultText = StringBuffer()
      ..writeln('Red Principal: ${_networkController.text}')
      ..writeln('Subredes calculadas: ${_subnets.length}\n');

    for (final subnet in _subnets) {
      resultText.writeln(
        'Subred: ${subnet['subnet']}${subnet['prefix']} - Hosts: ${subnet['hosts']}',
      );
      resultText.writeln('Máscara: ${subnet['mask']}');
      resultText.writeln('Rango: ${subnet['first']} - ${subnet['last']}');
      resultText.writeln('Broadcast: ${subnet['broadcast']}\n');
    }

    Clipboard.setData(ClipboardData(text: resultText.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultados copiados al portapeles')),
    );
  }

  void _clearAll() {
    setState(() {
      _networkController.clear();
      for (var controller in _hostsControllers) {
        controller.clear();
      }
      _isBridgeList.clear();
      _subnets.clear();
      _normalRequirements.clear();
      _normalConnections.clear();
      _isNormalCalculated = false;
      _errorMessage = '';
      _addHostField(); // Agregar un campo inicial
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar( //!APP_BAR
          title: const Text('Calculadora VLSM'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Modo Normal'),
              Tab(text: 'IP Libre'),
            ],
          ),
          actions: [
            if (!isMobile)
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => HistoryDialog(
                    history: _history,
                    onDelete: (index) {
                      setState(() => _history.removeAt(index));
                    },
                  ),
                ),
                tooltip: 'Historial',
              ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const HelpDialog(),
              ),
              tooltip: 'Ayuda',
            ),
          ],
        ),
        drawer: Drawer( //!DRAWER
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.primary),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lan, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      'Menú Principal',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('Nuevo Cálculo'),
                onTap: () {
                  _clearAll();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Guardar Resultados'),
                onTap: () {
                  if (_subnets.isNotEmpty) {
                    setState(() {
                      _history.add(
                        'Red: ${_networkController.text} - ${_subnets.length} subredes',
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cálculo guardado en historial'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Funcionamiento'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const FunctioningDialog(),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  );
                },
              ),
            ],
          ),
        ),
        endDrawer: Drawer( //!END_DRAWER
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.secondary),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tune, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      'Herramientas',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Convertir IP a Binario'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => IPBinaryDialog(
                      ipToBinary: IPConverter.ipToBinary,
                      validateIP: SubnetCalculator.validateIP,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Tabla de Prefijos'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) =>
                        PrefixTableDialog(prefixData: IPConverter.prefixData),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Exportar Resultados'),
                onTap: () {
                  Navigator.pop(context);
                  _exportResults(context);
                },
              ),
            ],
          ),
        ),
        body: Container( //!BODY
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.blueGrey.shade900, Colors.blueGrey.shade800]
                  : [Colors.blue.shade50, Colors.blue.shade100],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: TabBarView(
            children: [
              // Modo Normal
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          InputPanel(
                            networkController: _networkController,
                            hostsControllers: _hostsControllers,
                            isBridgeList: _isBridgeList,
                            errorMessage: _errorMessage,
                            onAddHost: _addHostField,
                            onRemoveHost: _removeHostField,
                            onToggleBridge: _toggleBridge,
                            connections: _normalConnections,
                            onAddConnection: (from, to) {
                              setState(() {
                                _normalConnections.add({
                                  'from': from,
                                  'to': to,
                                  'id': DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                });
                              });
                            },
                            onRemoveConnection: (index) {
                              setState(() {
                                _normalConnections.removeAt(index);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_isNormalCalculated &&
                              _normalRequirements.isNotEmpty) ...[
                            NormalDiagram(
                              subnets: _subnets,
                              connections: _normalConnections,
                            ),
                            const SizedBox(height: 16),
                            ResultsPanel(
                              isCalculated: _isNormalCalculated,
                              subnets: _subnets,
                            ),
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calculate,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Presiona "Calcular" para ver resultados',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Añade los ActionButtons aquí para móvil
                          ActionButtons(
                            onCalculate: _calculateSubnets,
                            onClear: _clearAll,
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Espacio adicional al final
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: InputPanel(
                                  networkController: _networkController,
                                  hostsControllers: _hostsControllers,
                                  isBridgeList: _isBridgeList,
                                  errorMessage: _errorMessage,
                                  onAddHost: _addHostField,
                                  onRemoveHost: _removeHostField,
                                  onToggleBridge: _toggleBridge,
                                  connections: _normalConnections,
                                  onAddConnection: (from, to) {
                                    setState(() {
                                      _normalConnections.add({
                                        'from': from,
                                        'to': to,
                                        'id': DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                      });
                                    });
                                  },
                                  onRemoveConnection: (index) {
                                    setState(() {
                                      _normalConnections.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (_isNormalCalculated &&
                                          _normalRequirements.isNotEmpty) ...[
                                        NormalDiagram(
                                          subnets: _subnets,
                                          connections: _normalConnections,
                                        ),
                                        const SizedBox(height: 16),
                                        ResultsPanel(
                                          isCalculated: _isNormalCalculated,
                                          subnets: _subnets,
                                        ),
                                      ] else ...[
                                        const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.calculate,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Presiona "Calcular" para ver los resultados',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ActionButtons(
                          onCalculate: _calculateSubnets,
                          onClear: _clearAll,
                        ),
                      ],
                    );
                  }
                },
              ),
              // Modo IP Libre
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          FreeIpInputPanel(
                            onCalculate: (results, requirements, connections) {
                              setState(() {
                                _freeIpResults = results;
                                _freeIpRequirements = requirements;
                                _freeIpConnections = connections;
                                _isFreeIpCalculated = true;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_freeIpRequirements.isNotEmpty) ...[
                            FreeIpDiagram(
                              routers: _freeIpRequirements,
                              connections: _freeIpConnections,
                            ),
                            const SizedBox(height: 16),
                            FreeIpResultsPanel(
                              subnets: _freeIpResults,
                              requirements: _freeIpRequirements,
                              connections: _freeIpConnections,
                            ),
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.router,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Configura los routers y conexiones',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: FreeIpInputPanel(
                                  onCalculate:
                                      (results, requirements, connections) {
                                        setState(() {
                                          _freeIpResults = results;
                                          _freeIpRequirements = requirements;
                                          _freeIpConnections = connections;
                                          _isFreeIpCalculated = true;
                                        });
                                      },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: _freeIpRequirements.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.router,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Configura los routers y conexiones',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            FreeIpDiagram(
                                              routers: _freeIpRequirements,
                                              connections: _freeIpConnections,
                                            ),
                                            const SizedBox(height: 16),
                                            FreeIpResultsPanel(
                                              subnets: _freeIpResults,
                                              requirements: _freeIpRequirements,
                                              connections: _freeIpConnections,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: isMobile //!BOTTOM_NAVIGATION_BAR
            ? BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  switch (index) {
                    case 0:
                      break;
                    case 1:
                      showDialog(
                        context: context,
                        builder: (context) => HistoryDialog(
                          history: _history,
                          onDelete: (index) {
                            setState(() => _history.removeAt(index));
                          },
                        ),
                      );
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calculate),
                    label: 'Calculadora',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Historial',
                  ),
                ],
              )
            : null,
        floatingActionButton: isMobile //! FLOATING_ACTION_BUTTON
            ? FloatingActionButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ToolsModal(),
                ),
                tooltip: 'Herramientas',
                child: const Icon(Icons.tune),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              )
            : FloatingActionButton.extended(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ToolsModal(),
                ),
                icon: const Icon(Icons.tune),
                label: const Text('Herramientas'),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
      ),
    );
  }
}
