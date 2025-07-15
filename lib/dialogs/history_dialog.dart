import 'package:flutter/material.dart';

class HistoryDialog extends StatelessWidget {
  final List<String> history;
  final Function(int) onDelete;

  const HistoryDialog({
    super.key,
    required this.history,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historial de Cálculos'),
      content: SizedBox(
        width: double.maxFinite,
        child: history.isEmpty
            ? const Text('No hay cálculos guardados')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: history.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(history[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onDelete(index),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}