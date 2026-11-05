import 'package:flutter/material.dart';

// Pantallas de introduccion que se muestran solo la primera vez que se abre
// la app. Al terminar (o al omitir) se llama a onTerminar.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onTerminar;

  const OnboardingScreen({super.key, required this.onTerminar});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Diapositiva {
  final String titulo;
  final String texto;
  final IconData principal;
  final List<IconData> secundarios;

  const _Diapositiva({
    required this.titulo,
    required this.texto,
    required this.principal,
    required this.secundarios,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _azul = Color(0xFF4C68FF);
  static const Color _azulOscuro = Color(0xFF1E3C72);

  static const List<_Diapositiva> _diapositivas = <_Diapositiva>[
    _Diapositiva(
      titulo: 'Bienvenido a FinanzApp',
      texto:
          'Tu plata en un solo lugar. Registrá gastos, ingresos y ahorros sin complicaciones.',
      principal: Icons.account_balance_wallet,
      secundarios: <IconData>[
        Icons.receipt_long,
        Icons.savings,
        Icons.trending_up,
      ],
    ),
    _Diapositiva(
      titulo: 'Todo conectado a tu saldo',
      texto:
          'Cada gasto, servicio pagado, ahorro o deuda de grupo se refleja en tu saldo total del inicio.',
      principal: Icons.sync_alt,
      secundarios: <IconData>[
        Icons.home_work_outlined,
        Icons.flag_outlined,
        Icons.groups_outlined,
      ],
    ),
    _Diapositiva(
      titulo: 'Grupos y metas',
      texto:
          'Dividí gastos con tus amigos, controlá quién te debe y alcanzá tus metas de ahorro.',
      principal: Icons.groups,
      secundarios: <IconData>[
        Icons.outdoor_grill_outlined,
        Icons.beach_access_outlined,
        Icons.emoji_events_outlined,
      ],
    ),
  ];

  final PageController _controlador = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  bool get _esUltima => _pagina == _diapositivas.length - 1;

  void _siguiente() {
    if (_esUltima) {
      widget.onTerminar();
      return;
    }
    _controlador.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onTerminar,
                child: const Text('Omitir', style: TextStyle(color: Colors.black54)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controlador,
                itemCount: _diapositivas.length,
                onPageChanged: (int pagina) => setState(() => _pagina = pagina),
                itemBuilder: (BuildContext context, int indice) {
                  return _buildDiapositiva(_diapositivas[indice]);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildIndicadores(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _siguiente,
                  child: Text(
                    _esUltima ? 'Comenzar' : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiapositiva(_Diapositiva diapositiva) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIlustracion(diapositiva),
          const SizedBox(height: 40),
          Text(
            diapositiva.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            diapositiva.texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Composicion con iconos: uno principal en el centro y tres secundarios
  // alrededor, sobre un degradado azul con formas suaves.
  Widget _buildIlustracion(_Diapositiva diapositiva) {
    return SizedBox(
      width: 280,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [_azulOscuro, _azul],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withAlpha(25),
            ),
          ),
          Positioned(
            left: -14,
            bottom: -14,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withAlpha(25),
            ),
          ),
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white.withAlpha(45),
            child: Icon(diapositiva.principal, size: 56, color: Colors.white),
          ),
          Positioned(
            left: 8,
            top: 30,
            child: _chip(diapositiva.secundarios[0]),
          ),
          Positioned(
            right: 8,
            top: 80,
            child: _chip(diapositiva.secundarios[1]),
          ),
          Positioned(
            left: 60,
            bottom: 18,
            child: _chip(diapositiva.secundarios[2]),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icono, color: _azul, size: 26),
    );
  }

  Widget _buildIndicadores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(_diapositivas.length, (int indice) {
        final bool activa = indice == _pagina;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activa ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activa ? _azul : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
