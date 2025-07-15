import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cómo usar la calculadora'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. Ingresa la red principal (ej: 192.168.1.0)'),
          SizedBox(height: 8),
          Text('2. Agrega los hosts requeridos para cada subred'),
          SizedBox(height: 8),
          Text('3. Presiona "Calcular" para obtener los resultados'),
          SizedBox(height: 16),
          Text('La calculadora ordena automáticamente los hosts de mayor a menor para VLSM.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}