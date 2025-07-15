import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';

class ResultsPanel extends StatelessWidget {
  final bool isCalculated;
  final List<Map<String, String>> subnets;

  const ResultsPanel({
    super.key,
    required this.isCalculated,
    required this.subnets,
  });

  Future<void> _exportToMarkdown(BuildContext context) async {
    if (!isCalculated || subnets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para exportar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final buffer = StringBuffer();

    // Encabezado del documento
    buffer.writeln('# Reporte de Subredes\n');
    buffer.writeln('**Fecha:** ${DateTime.now().toString()}\n');

    // Tabla de subredes
    buffer.writeln('## Distribución de Subredes\n');
    buffer.writeln(
      '| Tipo | Hosts | Route | Red | Gateway | Rango IP | Broadcast | Máscara |',
    );
    buffer.writeln(
      '|------|-------|-------|-----|---------|----------|-----------|---------|',
    );

    for (final subnet in subnets) {
      buffer.writeln(
        '| ${subnet['type'] == 'serial' ? 'WAN' : 'LAN'} '
        '| ${subnet['hosts']} '
        '| ${subnet['route'] ?? subnet['subnet']} '
        '| ${subnet['subnet']}${subnet['prefix']} '
        '| ${subnet['gateway'] ?? subnet['first']} '
        '| ${subnet['first']} - ${subnet['last']} '
        '| ${subnet['broadcast']} '
        '| ${subnet['mask']} |',
      );
    }

    try {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'subredes_$timestamp.md';
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
                  'Resultados de Subredes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                if (isCalculated && subnets.isNotEmpty)
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 50,
                dataRowHeight: 48,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                dataTextStyle: const TextStyle(fontSize: 15),
                columns: const [
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Hosts')),
                  DataColumn(label: Text('Route')),
                  DataColumn(label: Text('Red')),
                  DataColumn(label: Text('Gateway')),
                  DataColumn(label: Text('Rango IP')),
                  DataColumn(label: Text('Broadcast')),
                  DataColumn(label: Text('Máscara')),
                ],
                rows: [
                  ...subnets.map((subnet) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['type'] == 'serial' ? 'WAN' : 'LAN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: subnet['type'] == 'serial'
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['hosts'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['route'] ?? subnet['subnet'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${subnet['subnet']}${subnet['prefix']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['gateway'] ?? subnet['first'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${subnet['first']} - ${subnet['last']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['broadcast'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              subnet['mask'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  // Filas vacías para espacio adicional
                  DataRow(
                    cells: List.generate(
                      8,
                      (_) => DataCell(
                        Container(height: 48, child: const Text('')),
                      ),
                    ),
                  ),
                  DataRow(
                    cells: List.generate(
                      8,
                      (_) => DataCell(
                        Container(height: 48, child: const Text('')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
