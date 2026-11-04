import 'package:flutter/material.dart';
import 'savings_screen.dart';
import 'groups_screen.dart';
import 'household_screen.dart';
import 'month_screen.dart';
import 'notifications_screen.dart';
import 'add_expense_sheet.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'usuario_screen.dart';
import '../data/meta_ahorro_repository.dart';
import '../data/servicio_hogar_repository.dart';
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
  int _selectedIndex = 0;

  // Cantidad de alertas pendientes de la cuenta (para el punto de la campana).
  int _pendientes = 0;

  @override
  void initState() {
    super.initState();
    _actualizarPendientes();
  }

  // Recalcula las notificaciones reales de la cuenta y refresca el punto
  // rojo de la campana. Se vuelve a llamar despues de cada accion que
  // agrega, edita o elimina datos.
  Future<void> _actualizarPendientes() async {
    final List<ServicioHogar> servicios =
        await ServicioHogarRepository().getServicios();
    final List<MetaAhorro> metas = await MetaAhorroRepository().getMetas();
    final int cantidad = generarNotificaciones(
      servicios: servicios,
      metas: metas,
    ).length;
    if (!mounted) {
      return;
    }
    setState(() => _pendientes = cantidad);
  }

  // Las vistas se construyen dinamicamente para permitir recargas de datos.
  List<Widget> get _views => [
    HomeScreen(),
    MonthScreen(),
    HouseholdScreen(),
    GroupsScreen(),
    SavingsScreen(),
  ];

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
      _actualizarPendientes();
    }
  }

  Future<void> _openCreateUser() async {
    final int? userId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const UsuarioScreen()),
    );
    // Al crear una cuenta nueva, la app recarga las vistas con la base de
    // datos vacia del nuevo usuario.
    if (userId != null && mounted) {
      setState(() {});
      _actualizarPendientes();
    }
  }

  Future<void> _openLogin() async {
    final int? userId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    // Al iniciar sesion, la app recarga las vistas con la base de datos del usuario.
    if (userId != null && mounted) {
      setState(() {});
      _actualizarPendientes();
    }
  }

  // Abre la pantalla de perfil (datos, edicion y cierre de sesion).
  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(onCerrarSesion: widget.onCerrarSesion),
      ),
    );
    // Al volver del perfil se refrescan las vistas.
    if (mounted) {
      setState(() {});
      _actualizarPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FinanzApp',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(_monthLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.amber),
                if (_pendientes > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notificaciones ($_pendientes)',
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.purple),
            onPressed: _openCreateUser,
          ),
          IconButton(
            icon: const Icon(Icons.login_outlined, color: Colors.purple),
            onPressed: _openLogin,
          ),
          Tooltip(
            message: 'Mi perfil',
            child: IconButton(
              onPressed: _openProfile,
              icon: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                radius: 16,
                child: const Text('😊', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
      body: _views[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          _openAddExpense();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4C68FF),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Mes'),
          BottomNavigationBarItem(icon: Icon(Icons.cottage_outlined), activeIcon: Icon(Icons.cottage), label: 'Hogar'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Grupo'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Ahorro'),
        ],
      ),
    );
  }
}
