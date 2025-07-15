import 'package:flutter/material.dart';
import '../utils/ip_converter.dart';
import '../utils/subnet_calculator.dart';
import 'ip_binary_dialog.dart';
import 'prefix_table_dialog.dart';

class ToolsModal extends StatelessWidget {
  const ToolsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24), // Margen horizontal reducido
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300), // Ancho máximo del modal
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Herramientas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              // Botones compactos
              _ToolButton(
                icon: Icons.code,
                label: 'IP a Binario',
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
              _ToolButton(
                icon: Icons.table_chart,
                label: 'Tabla de Prefijos',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => PrefixTableDialog(
                      prefixData: IPConverter.prefixData,
                    ),
                  );
                },
              ),
              _ToolButton(
                icon: Icons.share,
                label: 'Exportar',
                onTap: () {
                  Navigator.pop(context);
                  // Lógica de exportación aquí
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: onTap,
      minLeadingWidth: 20, // Espacio reducido entre ícono y texto
      dense: true, // Modo compacto
    );
  }
}