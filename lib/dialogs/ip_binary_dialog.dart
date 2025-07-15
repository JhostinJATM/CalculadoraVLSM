import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IPBinaryDialog extends StatelessWidget {
  final String Function(String) ipToBinary;
  final bool Function(String) validateIP;

  const IPBinaryDialog({
    super.key,
    required this.ipToBinary,
    required this.validateIP,
  });

  @override
  Widget build(BuildContext context) {
    final ipController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Conversor IP a Binario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ipController,
            decoration: const InputDecoration(
              labelText: 'Dirección IP',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (validateIP(ipController.text)) {
                final binary = ipToBinary(ipController.text);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Resultado'),
                    content: SelectableText('Binario: $binary'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dirección IP inválida')),
                );
              }
            },
            child: const Text('Convertir'),
          ),
        ],
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