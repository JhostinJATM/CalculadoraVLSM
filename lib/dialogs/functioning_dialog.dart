import 'package:flutter/material.dart';

class FunctioningDialog extends StatelessWidget {
  const FunctioningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 600;
    final primaryColor = Theme.of(context).primaryColor;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 40 : 20,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 580 : 400,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Guía de Funcionamiento',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección Modo Manual (VLSM)
              _buildSection(
                context,
                title: 'Modo Manual (VLSM)',
                icon: Icon(Icons.lan, color: primaryColor),
                items: [
                  '1. Ingresa la red principal (ej: 192.168.1.0/24)',
                  '2. Especifica los hosts requeridos para cada subred',
                  '',
                  '📝 Proceso Automático:',
                  '• Calcula el espacio necesario para cada subred',
                  '• Aplica fórmulas VLSM para asignación eficiente:',
                  '  - Hosts necesarios = 2ⁿ - 2',
                  '  - Saltos de red = 2^(32 - prefijo)',
                  '  - Máscara = 255.255.255.(256 - salto)',
                  '',
                  '🔍 Ejemplo: Para 50 hosts → 2⁶-2=62 → /26',
                  'Salto = 64 → Subredes: .0, .64, .128, .192',
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 16),

              // Sección Modo IP Libre (corregida)
              _buildSection(
                context,
                title: 'Modo IP Libre Completo',
                icon: Icon(Icons.router, color: primaryColor),
                items: [
                  '1. Configuración inicial:',
                  '   • Ingresa nombre del router',
                  '   • Selecciona clase de red (A, B, C)',
                  '   • Define número de redes o hosts requeridos',
                  '',
                  '2. Conexiones seriales:',
                  '   • Agrega interfaces seriales entre routers',
                  '   • Especifica cantidad necesaria',
                  '',
                  '⚙️ Proceso Automático:',
                  '• Calcula subredes principales para cada router',
                  '• Aplica algoritmo de saltos para asignación:',
                  '  - Usa fórmulas VLSM para división óptima',
                  '  - Reserva espacio para crecimiento',
                  '',
                  '• Conexiones seriales:',
                  '  - Toma una subred adicional del último router',
                  '  - Realiza subneteo a /30 para las interfaces',
                  '  - Asigna automáticamente las IPs seriales',
                ],
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('ENTENDIDO', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => item.isEmpty
            ? const SizedBox(height: 8)
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )).toList(),
      ],
    );
  }
}