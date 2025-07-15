import 'package:flutter/material.dart';

class PrefixTableDialog extends StatelessWidget {
  final List<Map<String, String>> prefixData;

  const PrefixTableDialog({
    super.key,
    required this.prefixData,
  });

  @override
  Widget build(BuildContext context) {
    // Dividir los datos en dos listas para las columnas
    final middleIndex = (prefixData.length / 2).ceil();
    final firstColumn = prefixData.sublist(0, middleIndex);
    final secondColumn = prefixData.sublist(middleIndex);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600), // Ancho máximo ajustado
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tabla de Prefijos Comunes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera columna
                Expanded(
                  child: _buildDataTable(firstColumn),
                ),
                const SizedBox(width: 10),
                // Segunda columna
                Expanded(
                  child: _buildDataTable(secondColumn),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, String>> data) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 8,
        columns: const [
          DataColumn(label: Text('Prefijo', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Hosts', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Máscara', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: data.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['prefix']!)),
              DataCell(Text(item['hosts']!)),
              DataCell(Text(item['mask']!)),
            ],
          );
        }).toList(),
      ),
    );
  }
}