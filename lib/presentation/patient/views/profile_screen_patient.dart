import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreenPatient extends StatefulWidget {
  const ProfileScreenPatient({super.key});

  @override
  _ProfileScreenPatientState createState() => _ProfileScreenPatientState();
}

class _ProfileScreenPatientState extends State<ProfileScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  bool _popupNotifications = true;
  bool _emailNotifications = false;

  void _onLogoutPressed() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),

          // Información de usuario
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String userName = 'Cargando...';
              String userEmail = '';
              String profileImageUrl =
                  'https://picsum.photos/seed/768/600'; // placeholder

              if (authState.status == AuthStatus.authenticated &&
                  authState.patient != null) {
                userName = authState.patient!.username;
                userEmail = authState.patient!.email;
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(profileImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              12,
                              0,
                              0,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userEmail,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).hintColor,
                                        fontSize: 14,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onPressed: () {
                      // Aquí puedes navegar a la pantalla de info personal
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Cuenta',
            children: [
              ProfileListItem(
                icon: Icons.military_tech_outlined,
                text: 'Suscripción',
                secondaryText: 'Gestionar Premium',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.credit_card_outlined,
                text: 'Pagos',
                secondaryText: 'N/A',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Notificaciones',
            children: [
              _buildNotificationToggle(
                'Notificaciones Pop-up',
                Icons.notifications_none,
                _popupNotifications,
                (value) {
                  setState(() {
                    _popupNotifications = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Notificaciones Pop-up activadas'
                          : 'Notificaciones Pop-up desactivadas'),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              _buildNotificationToggle(
                'Notificaciones por Email',
                Icons.mail_outline,
                _emailNotifications,
                (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Notificaciones por Email activadas'
                          : 'Notificaciones por Email desactivadas'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Configuración y ayuda',
            children: [
              ProfileListItem(
                icon: Icons.settings_outlined,
                text: 'Configuración',
                onTap: () {
                  // Navegar a Settings
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.contact_support_outlined,
                text: 'Contáctanos',
                onTap: () {},
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.privacy_tip_outlined,
                text: 'Politicas de Privacidad',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 30),
          // Botón de cerrar sesión
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.unauthenticated &&
                  !Navigator.of(context).canPop()) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada exitosamente.')),
                );
              } else if (state.status == AuthStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : _onLogoutPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: state.status == AuthStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    String title,
    IconData icon,
    bool currentValue,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Switch(
            value: currentValue,
            onChanged: onChanged,
            activeColor: accentColor,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
