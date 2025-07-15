import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';

class FreeIpResultsPanel extends StatelessWidget {
  final List<Map<String, String>> subnets;
  final List<Map<String, dynamic>> requirements;
  final List<Map<String, String>> connections;
  final bool isMobile;

  const FreeIpResultsPanel({
    super.key,
    required this.subnets,
    required this.requirements,
    required this.connections,
    this.isMobile = false,
  });

  Future<void> _exportToMarkdown(BuildContext context) async {
    final buffer = StringBuffer();

    // Encabezado del documento
    buffer.writeln('# Reporte de Configuración de Red\n');
    buffer.writeln('**Fecha:** ${DateTime.now().toString()}\n');

    // Tabla de IPs
    buffer.writeln('## Distribución de IPs\n');
    buffer.writeln('| Tipo | Route | Red | Gateway | Rango IP | Broadcast |');
    buffer.writeln('|------|-------|-----|---------|----------|-----------|');

    for (final subnet in subnets) {
      buffer.writeln(
        '| ${subnet['type'] == 'router' ? 'LAN' : 'WAN'} '
        '| ${subnet['route']} '
        '| ${subnet['network']} '
        '| ${subnet['gateway']} '
        '| ${subnet['first']} - ${subnet['last']} '
        '| ${subnet['broadcast']} |',
      );
    }

    // Conexiones seriales
    if (connections.isNotEmpty) {
      buffer.writeln('\n## Conexiones Seriales\n');
      buffer.writeln('| Desde | Hacia |');
      buffer.writeln('|-------|-------|');
      for (final conn in connections) {
        buffer.writeln('| ${conn['from']} | ${conn['to']} |');
      }
    }

    try {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'config_red_$timestamp.md';
      final fileData = Uint8List.fromList(buffer.toString().codeUnits);

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: fileData,
        mimeType: MimeType.other,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo descargado y copiado al portapapeles'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resultados de Red',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Tooltip(
                  message: 'Exportar a Markdown',
                  child: IconButton(
                    icon: Icon(Icons.download, color: colorScheme.primary),
                    onPressed: () => _exportToMarkdown(context),
                  ),
                ),
              ],
            ),
          ),

          // Contenedor principal con scroll horizontal
          SizedBox(
            height: isMobile ? 300 : null, // Altura fija para móvil
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(12),
                // Ancho mínimo basado en el contenido para móvil
                constraints: BoxConstraints(
                  minWidth: isMobile ? screenWidth * 1.5 : screenWidth - 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isMobile ? screenWidth * 1.5 : screenWidth - 32,
                  ),
                  child: DataTable(
                    columnSpacing: isMobile ? 8 : 12,
                    headingRowHeight: isMobile ? 40 : 50,
                    dataRowHeight: isMobile ? 36 : 48,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 12 : 14,
                    ),
                    dataTextStyle: TextStyle(fontSize: isMobile ? 11 : 13),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 50 : 60,
                          child: const Text('Tipo'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 100 : 150,
                          child: const Text('Route'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 100 : 150,
                          child: const Text('Red'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 100 : 150,
                          child: const Text('Gateway'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 180 : 250,
                          child: const Text('Rango IP'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: isMobile ? 100 : 150,
                          child: const Text('Broadcast'),
                        ),
                      ),
                    ],
                    rows: [
                      ...subnets.map((subnet) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subnet['type'] == 'router' ? 'LAN' : 'WAN',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: subnet['type'] == 'router'
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subnet['route'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subnet['network'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subnet['gateway'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${subnet['first']} - ${subnet['last']}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  subnet['broadcast'] ?? '',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      // Filas vacías para espacio adicional (solo en desktop)
                      if (!isMobile) ...[
                        DataRow(
                          cells: List<DataCell>.generate(
                            6,
                            (index) => DataCell(
                              Container(height: 48, child: const Text('')),
                            ),
                          ),
                        ),
                        DataRow(
                          cells: List<DataCell>.generate(
                            6,
                            (index) => DataCell(
                              Container(height: 48, child: const Text('')),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
