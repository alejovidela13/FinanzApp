import 'package:flutter/material.dart';
import 'savings_screen.dart';
import 'groups_screen.dart';
import 'household_screen.dart';
import 'month_screen.dart';
import 'notifications_screen.dart';
import 'add_expense_sheet.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../data/dbhelper.dart';
import '../data/meta_ahorro_repository.dart';
import '../data/servicio_hogar_repository.dart';
import '../data/usuario_repository.dart';
import '../model/model.dart';
import '../util/notificaciones.dart';
import '../util/utils.dart';

class MainNavScreen extends StatefulWidget {
  // Callback que vuelve la aplicacion a la pantalla de bienvenida.
  final VoidCallback onCerrarSesion;

  const MainNavScreen({super.key, required this.onCerrarSesion});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  static const Color _azul = Color(0xFF4C68FF);
  static const Color _azulOscuro = Color(0xFF1E3C72);

  int _selectedIndex = 0;

  // Cantidad de alertas pendientes de la cuenta (para el punto de la campana).
  int _pendientes = 0;

  // Inicial del nombre de la cuenta activa (para el avatar del header).
  String _inicial = '?';

  @override
  void initState() {
    super.initState();
    _actualizarCabecera();
  }

  // Recalcula las notificaciones reales de la cuenta y el avatar del header.
  // Se vuelve a llamar despues de cada accion que agrega, edita o elimina datos.
  Future<void> _actualizarCabecera() async {
    final List<ServicioHogar> servicios =
        await ServicioHogarRepository().getServicios();
    final List<MetaAhorro> metas = await MetaAhorroRepository().getMetas();
    final int cantidad = generarNotificaciones(
      servicios: servicios,
      metas: metas,
    ).length;
    final int? id = DbHelper().currentUserId;
    final Usuario? usuario =
        id == null ? null : await UsuarioRepository().getUsuario(id);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendientes = cantidad;
      _inicial = (usuario == null || usuario.nombre.trim().isEmpty)
          ? '?'
          : usuario.nombre.trim().substring(0, 1).toUpperCase();
    });
  }

  // Las vistas se construyen dinamicamente para permitir recargas de datos.
  List<Widget> get _views => [
    HomeScreen(onAbrirHogar: _openHousehold),
    MonthScreen(),
    GroupsScreen(),
    SavingsScreen(),
  ];

  // Servicios del hogar: se abren como pantalla propia desde el inicio.
  // Al volver se refresca la cabecera (alertas y avatar).
  Future<void> _openHousehold() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HouseholdScreen()),
    );
    if (mounted) {
      _actualizarCabecera();
    }
  }

  // Etiqueta del mes en curso (logica pura compartida en utils).
  String get _monthLabel => etiquetaMes(DateTime.now());

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  Future<void> _openAddExpense() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddExpenseSheet(),
    );
    // Tras cerrar el formulario, reconstruye las vistas para que las pantallas
    // que consumen el repositorio (ej. lista de gastos) muestren la informacion actualizada.
    if (mounted) {
      setState(() {});
      _actualizarCabecera();
    }
  }

  // Abre la pantalla de perfil (datos, cuentas y cierre de sesion).
  // Al volver se refrescan las vistas: la cuenta activa pudo cambiar.
  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(onCerrarSesion: widget.onCerrarSesion),
      ),
    );
    if (mounted) {
      setState(() {});
      _actualizarCabecera();
    }
  }

  // Boton de la campana con el punto rojo cuando hay alertas pendientes.
  Widget _botonNotificaciones() {
    return IconButton(
      tooltip: 'Notificaciones ($_pendientes)',
      onPressed: _openNotifications,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none, color: _azulOscuro, size: 26),
          if (_pendientes > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return IconButton(
      tooltip: 'Mi perfil',
      onPressed: _openProfile,
      padding: EdgeInsets.zero,
      icon: CircleAvatar(
        radius: 18,
        backgroundColor: _azul.withAlpha(30),
        child: Text(
          _inicial,
          style: const TextStyle(
            color: _azul,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Elemento de la barra inferior: icono y etiqueta, resaltado si esta activo.
  Widget _itemNavegacion(int indice, IconData icono, IconData iconoActivo, String etiqueta) {
    final bool activo = _selectedIndex == indice;
    final Color color = activo ? _azul : Colors.grey;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedIndex = indice),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activo ? iconoActivo : icono, color: color, size: 24),
              const SizedBox(height: 2),
              // Una sola linea: en pantallas angostas la etiqueta no puede
              // partirse y desbordar la altura de la barra.
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FinanzApp',
              style: TextStyle(
                color: _azulOscuro,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _monthLabel,
              style: const TextStyle(color: Colors.black45, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          _botonNotificaciones(),
          _buildAvatar(),
          const SizedBox(width: 12),
        ],
      ),
      body: _views[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: _azul,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          _openAddExpense();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Dos mitades de igual ancho: el hueco del boton "+" queda
            // exactamente en el centro de la barra.
            Expanded(
              child: Row(
                children: [
                  _itemNavegacion(0, Icons.home_outlined, Icons.home, 'Inicio'),
                  _itemNavegacion(1, Icons.bar_chart_outlined, Icons.bar_chart, 'Mes'),
                ],
              ),
            ),
            const SizedBox(width: 80),
            Expanded(
              child: Row(
                children: [
                  _itemNavegacion(2, Icons.group_outlined, Icons.group, 'Grupo'),
                  _itemNavegacion(3, Icons.track_changes_outlined, Icons.track_changes, 'Ahorro'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
