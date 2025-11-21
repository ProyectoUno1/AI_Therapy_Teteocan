// lib/presentation/patient/views/appointment_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/psychology_session_payment_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/psychology_payment_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychology_payment_repository.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final PsychologistModel psychologist;

  const AppointmentBookingScreen({super.key, required this.psychologist});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Datos del agendamiento
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  AppointmentType _selectedType = AppointmentType.online;
  final TextEditingController _notesController = TextEditingController();
  bool _isPremium = false;
  bool _isLoadingSubscription = true;
  Set<DateTime> _datesWithAvailability = {};
  bool _isLoadingAvailableDates = false;

  // Breakpoints responsivos
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double smallScreenBreakpoint = 360;
    @override
  void initState() {
    super.initState();
    _checkUserSubscription();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentMonth();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Métodos responsivos basados en MediaQuery
  bool _isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobileBreakpoint;

  bool _isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileBreakpoint && 
      MediaQuery.of(context).size.width < tabletBreakpoint;

  bool _isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  bool _isSmallScreen(BuildContext context) => 
      MediaQuery.of(context).size.width < smallScreenBreakpoint;

  // Métodos para dimensiones responsivas
  double _getHorizontalPadding(BuildContext context) {
    if (_isDesktop(context)) return 48.0;
    if (_isTablet(context)) return 32.0;
    return 16.0;
  }

  double _getVerticalPadding(BuildContext context) {
    if (_isDesktop(context)) return 32.0;
    if (_isTablet(context)) return 24.0;
    return 16.0;
  }

  double _getSpacing(BuildContext context, {double mobile = 8.0, double tablet = 12.0, double desktop = 16.0}) {
    if (_isDesktop(context)) return desktop;
    if (_isTablet(context)) return tablet;
    return mobile;
  }

  // Métodos para fuentes responsivas
  double _getTitleFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 18.0;
    if (_isDesktop(context)) return 24.0;
    if (_isTablet(context)) return 20.0;
    return 18.0;
  }

  double _getBodyFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 12.0;
    if (_isDesktop(context)) return 16.0;
    if (_isTablet(context)) return 14.0;
    return 13.0;
  }

  double _getSmallFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 10.0;
    if (_isDesktop(context)) return 14.0;
    if (_isTablet(context)) return 12.0;
    return 11.0;
  }

  double _getButtonFontSize(BuildContext context) {
    if (_isSmallScreen(context)) return 14.0;
    if (_isDesktop(context)) return 18.0;
    if (_isTablet(context)) return 16.0;
    return 15.0;
  }

  // Métodos para iconos responsivos
  double _getIconSize(BuildContext context, {double mobile = 16.0, double tablet = 20.0, double desktop = 24.0}) {
    if (_isDesktop(context)) return desktop;
    if (_isTablet(context)) return tablet;
    return mobile;
  }
    DateTime _getValidInitialDate(DateTime today) {
    if (_selectedDate != null) {
      final normalizedSelected = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      if (_datesWithAvailability.isNotEmpty) {
        if (_datesWithAvailability.contains(normalizedSelected)) {
          return _selectedDate!;
        }
      } else if (!normalizedSelected.isBefore(today)) {
        return _selectedDate!;
      }
    }

    if (_datesWithAvailability.isNotEmpty) {
      final sortedDates = _datesWithAvailability.toList()..sort();
      return sortedDates.first;
    }

    return today;
  }

  Future<void> _checkUserSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _isPremium = userDoc.data()?['isPremium'] == true;
            _isLoadingSubscription = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoadingSubscription = false;
        });
      }
    }
  }

  Future<void> _loadCurrentMonth() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAvailableDates = true;
    });

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 60));

      context.read<AppointmentBloc>().add(
        LoadAvailableTimeSlotsEvent(
          psychologistId: widget.psychologist.uid,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvailableDates = false;
        });
      }
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: _getIconSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AutoSizeText(
          'Agendar Cita',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          minFontSize: 16,
        ),
        centerTitle: true,
      ),
      body: BlocListener<AppointmentBloc, AppointmentState>(
        listener: (context, state) {
          if (state.isBooked) {
            if (_isPremium) {
              _showSuccessDialog();

              context.read<AppointmentBloc>().add(
                LoadAppointmentsEvent(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  isForPsychologist: false,
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 60)),
                ),
              );
            }
          } else if (state.isError) {
            _showErrorSnackBar(state.errorMessage!);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return OrientationBuilder(
              builder: (context, orientation) {
                return Column(
                  children: [
                    _buildStepsIndicator(context),
                    _buildPsychologistInfo(context),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildDateSelectionStep(context),
                          _buildTimeSelectionStep(context),
                          _buildAppointmentDetailsStep(context),
                          _buildConfirmationStep(context),
                        ],
                      ),
                    ),
                    _buildNavigationButtons(context),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
    void _navigateToPaymentScreen() {
    if (_selectedDate != null && _selectedTimeSlot != null) {
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTimeSlot!.dateTime.hour,
        _selectedTimeSlot!.dateTime.minute,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => PsychologyPaymentBloc(
              repository: PsychologyPaymentRepositoryImpl(),
            ),
            child: PsychologySessionPaymentScreen(
              psychologist: widget.psychologist,
              sessionDateTime: appointmentDateTime,
              appointmentType: _selectedType,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          ),
        ),
      ).then((paymentSuccess) {
        if (paymentSuccess == true) {
          _showSuccessDialog(isPaidSession: true);
        }
      });
    }
  }

  Widget _buildStepsIndicator(BuildContext context) {
    final steps = ['Fecha', 'Hora', 'Detalles', 'Confirmar'];
    final stepIconSize = _isDesktop(context) ? 40.0 : _isTablet(context) ? 36.0 : 32.0;

    return Container(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      color: Theme.of(context).cardColor,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: stepIconSize,
                  height: stepIconSize,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppConstants.primaryColor
                        : isActive
                        ? AppConstants.lightAccentColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: _getIconSize(context))
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: _getSmallFontSize(context),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: _getSpacing(context)),
                Expanded(
                  child: AutoSizeText(
                    steps[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    flex: _isMobile(context) ? 1 : 2,
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? AppConstants.primaryColor
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
    Widget _buildPsychologistInfo(BuildContext context) {
    final avatarSize = _isDesktop(context) ? 70.0 : _isTablet(context) ? 60.0 : 48.0;

    return Container(
      margin: EdgeInsets.all(_getHorizontalPadding(context)),
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                backgroundImage: widget.psychologist.profilePictureUrl != null
                    ? NetworkImage(widget.psychologist.profilePictureUrl!)
                    : null,
                child: widget.psychologist.profilePictureUrl == null
                    ? Text(
                        widget.psychologist.username.isNotEmpty
                            ? widget.psychologist.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _getTitleFontSize(context),
                          color: AppConstants.lightAccentColor,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      widget.psychologist.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _getBodyFontSize(context),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                    AutoSizeText(
                      widget.psychologist.specialty ?? 'Psicología General',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: _getSmallFontSize(context),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!_isLoadingSubscription) ...[
            SizedBox(height: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            Container(
              padding: EdgeInsets.all(_getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isPremium ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPremium ? Icons.star : Icons.payment,
                    color: _isPremium ? Colors.green[700] : Colors.orange[700],
                    size: _getIconSize(context),
                  ),
                  SizedBox(width: _getSpacing(context)),
                  Expanded(
                    child: AutoSizeText(
                      _isPremium
                          ? 'Tu suscripción Premium incluye esta sesión'
                          : 'Pago único de \$${(widget.psychologist.price ?? 100.0).toInt()} requerido',
                      style: TextStyle(
                        fontSize: _getSmallFontSize(context),
                        color: _isPremium
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      minFontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
    Widget _buildDateSelectionStep(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'Selecciona una fecha',
            style: TextStyle(
              fontSize: _getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 16,
          ),
          SizedBox(height: _getSpacing(context)),
          AutoSizeText(
            'Elige el día que prefieras para tu sesión',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getBodyFontSize(context),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            minFontSize: 12,
          ),
          SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 24.0, desktop: 32.0)),
          Expanded(child: _buildCustomCalendar(context)),
        ],
      ),
    );
  }

  Widget _buildCustomCalendar(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state.hasAvailableTimeSlots) {
          final availableDates = <DateTime>{};
          for (var slot in state.availableTimeSlots) {
            if (slot.isAvailable) {
              final date = DateTime(
                slot.dateTime.year,
                slot.dateTime.month,
                slot.dateTime.day,
              );
              availableDates.add(date);
            }
          }

          if (mounted) {
            setState(() {
              _datesWithAvailability = availableDates;
              _isLoadingAvailableDates = false;
            });
          }
        }
        if (state.isError) {
          if (mounted) {
            setState(() {
              _isLoadingAvailableDates = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudieron cargar las fechas disponibles'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (_isLoadingAvailableDates) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppConstants.lightAccentColor,
                ),
                SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                AutoSizeText(
                  'Cargando fechas disponibles...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey[600],
                    fontSize: _getBodyFontSize(context),
                  ),
                  maxLines: 1,
                  minFontSize: 12,
                ),
              ],
            ),
          );
        }

        if (_datesWithAvailability.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_getHorizontalPadding(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _isDesktop(context) ? 180.0 : _isTablet(context) ? 160.0 : 120.0,
                    height: _isDesktop(context) ? 180.0 : _isTablet(context) ? 160.0 : 120.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: _isDesktop(context) ? 90.0 : _isTablet(context) ? 80.0 : 64.0,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),
                  AutoSizeText(
                    'No hay fechas disponibles',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: _getTitleFontSize(context),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 16,
                  ),
                  SizedBox(height: _getSpacing(context)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop(context) ? 100.0 : _isTablet(context) ? 80.0 : 40.0,
                    ),
                    child: AutoSizeText(
                      'El psicólogo no tiene horarios disponibles en este momento. Por favor intenta más tarde.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: _getBodyFontSize(context),
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      minFontSize: 12,
                    ),
                  ),
                  SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoadingAvailableDates = true;
                      });
                      _loadCurrentMonth();
                    },
                    icon: Icon(Icons.refresh, size: _getIconSize(context)),
                    label: AutoSizeText(
                      'Reintentar',
                      style: TextStyle(fontSize: _getBodyFontSize(context)),
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.lightAccentColor,
                      side: BorderSide(color: AppConstants.lightAccentColor),
                      padding: EdgeInsets.symmetric(
                        horizontal: _getSpacing(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
                        vertical: _getSpacing(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(_getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
              decoration: BoxDecoration(
                color: AppConstants.lightAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.lightAccentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(context,
                    color: AppConstants.lightAccentColor,
                    label: 'Disponible',
                    icon: Icons.check_circle,
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                  _buildLegendItem(context,
                    color: Colors.grey[300]!,
                    label: 'No disponible',
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ),
            SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
            
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
                vertical: _getSpacing(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    size: _getIconSize(context),
                    color: Colors.green[700],
                  ),
                  SizedBox(width: _getSpacing(context)),
                  AutoSizeText(
                    '${_datesWithAvailability.length} fecha${_datesWithAvailability.length != 1 ? 's' : ''} con disponibilidad',
                    style: TextStyle(
                      fontSize: _getSmallFontSize(context),
                      color: Colors.green[700],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppConstants.lightAccentColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black87,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.lightAccentColor,
                        ),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _getValidInitialDate(today),
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 60)),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTimeSlot = null;
                        });

                        context.read<AppointmentBloc>().add(
                          LoadAvailableTimeSlotsEvent(
                            psychologistId: widget.psychologist.uid,
                            startDate: date,
                            endDate: date,
                          ),
                        );
                      },
                      selectableDayPredicate: (date) {
                        final normalizedDate = DateTime(date.year, date.month, date.day);
                        final normalizedNow = DateTime(now.year, now.month, now.day);

                        if (normalizedDate.isBefore(normalizedNow)) {
                          return false;
                        }

                        return _datesWithAvailability.contains(normalizedDate);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
    Widget _buildTimeSelectionStep(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'Selecciona una hora',
            style: TextStyle(
              fontSize: _getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 16,
          ),
          SizedBox(height: _getSpacing(context)),
          AutoSizeText(
            _selectedDate != null
                ? 'Horarios disponibles para ${_formatSelectedDate()}'
                : 'Primero selecciona una fecha',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getBodyFontSize(context),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            minFontSize: 12,
          ),
          SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),

          if (_selectedDate != null) ...[
            Expanded(
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppConstants.lightAccentColor,
                          ),
                          SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                          AutoSizeText(
                            'Cargando horarios...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                              fontSize: _getBodyFontSize(context),
                            ),
                            maxLines: 1,
                            minFontSize: 12,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.hasAvailableTimeSlots) {
                    return _buildTimeSlotGrid(context, state.availableTimeSlots);
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
                          height: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.schedule_outlined,
                            size: _isDesktop(context) ? 70.0 : _isTablet(context) ? 56.0 : 48.0,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                        AutoSizeText(
                          'No hay horarios disponibles',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: _getBodyFontSize(context),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          minFontSize: 14,
                        ),
                        SizedBox(height: _getSpacing(context)),
                        AutoSizeText(
                          'para esta fecha',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: _getSmallFontSize(context),
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
                      height: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.date_range_outlined,
                        size: _isDesktop(context) ? 70.0 : _isTablet(context) ? 56.0 : 48.0,
                        color: AppConstants.lightAccentColor,
                      ),
                    ),
                    SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                    AutoSizeText(
                      'Selecciona una fecha primero',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: _getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      minFontSize: 14,
                    ),
                    SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),
                    TextButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: Icon(Icons.arrow_back, size: _getIconSize(context)),
                      label: AutoSizeText(
                        'Ir a calendario',
                        style: TextStyle(fontSize: _getBodyFontSize(context)),
                        maxLines: 1,
                        minFontSize: 12,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.lightAccentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(BuildContext context, List<TimeSlot> timeSlots) {
    final availableSlots = timeSlots.where((slot) => slot.isAvailable).toList();

    if (availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
              height: _isDesktop(context) ? 140.0 : _isTablet(context) ? 120.0 : 100.0,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: _isDesktop(context) ? 70.0 : _isTablet(context) ? 56.0 : 48.0,
                color: Colors.orange[400],
              ),
            ),
            SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
            AutoSizeText(
              'No hay horarios disponibles',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: _getBodyFontSize(context),
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 14,
            ),
            SizedBox(height: _getSpacing(context)),
            AutoSizeText(
              'para esta fecha',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: _getSmallFontSize(context),
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              minFontSize: 12,
            ),
            SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentStep > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: Icon(Icons.arrow_back, size: _getIconSize(context)),
              label: AutoSizeText(
                'Elegir otra fecha',
                style: TextStyle(fontSize: _getBodyFontSize(context)),
                maxLines: 1,
                minFontSize: 12,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.lightAccentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: _getSpacing(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
                  vertical: _getSpacing(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                ),
              ),
            ),
          ],
        ),
      );
    }

    availableSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(_getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.green[700],
                size: _getIconSize(context),
              ),
              SizedBox(width: _getSpacing(context)),
              AutoSizeText(
                '${availableSlots.length} horario${availableSlots.length != 1 ? 's' : ''} disponible${availableSlots.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: _getBodyFontSize(context),
                  color: Colors.green[700],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                minFontSize: 12,
              ),
            ],
          ),
        ),
        SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _isDesktop(context) 
                  ? (constraints.maxWidth > 800 ? 5 : 4)
                  : _isTablet(context) 
                      ? (constraints.maxWidth > 700 ? 4 : 3)
                      : (constraints.maxWidth > 400 ? 3 : 2);
              
              return GridView.builder(
                padding: EdgeInsets.only(bottom: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: _isDesktop(context) ? 2.8 : _isTablet(context) ? 2.5 : 2.2,
                  crossAxisSpacing: _getSpacing(context),
                  mainAxisSpacing: _getSpacing(context),
                ),
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  final isSelected = _selectedTimeSlot?.time == slot.time;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                      HapticFeedback.lightImpact();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppConstants.lightAccentColor,
                                  AppConstants.lightAccentColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.lightAccentColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppConstants.lightAccentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: _getIconSize(context),
                                  color: isSelected
                                      ? Colors.white
                                      : AppConstants.lightAccentColor,
                                ),
                                SizedBox(height: 4),
                                AutoSizeText(
                                  slot.time,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getSmallFontSize(context),
                                    fontFamily: 'Poppins',
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 10,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppConstants.lightAccentColor,
                                  size: _getIconSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
    Widget _buildAppointmentDetailsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'Detalles de la cita',
            style: TextStyle(
              fontSize: _getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 16,
          ),
          SizedBox(height: _getSpacing(context)),
          AutoSizeText(
            'Configura los detalles de tu sesión',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getBodyFontSize(context),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            minFontSize: 12,
          ),
          SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),

          AutoSizeText(
            'Modalidad de la sesión',
            style: TextStyle(
              fontSize: _getBodyFontSize(context),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 14,
          ),
          SizedBox(height: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),

          Row(
            children: [
              Expanded(
                child: _buildAppointmentTypeCard(
                  context,
                  type: AppointmentType.online,
                  icon: Icons.videocam,
                  title: 'En línea',
                  subtitle: 'Videoconferencia',
                ),
              ),
            ],
          ),

          SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),

          AutoSizeText(
            'Notas adicionales (opcional)',
            style: TextStyle(
              fontSize: _getBodyFontSize(context),
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 14,
          ),
          SizedBox(height: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe brevemente el motivo de tu consulta o cualquier información relevante...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
                fontSize: _getSmallFontSize(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppConstants.lightAccentColor),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: EdgeInsets.all(_getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
            ),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: _getBodyFontSize(context),
            ),
          ),

          SizedBox(height: _getSpacing(context, mobile: 32.0, tablet: 48.0, desktop: 64.0)),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeCard(BuildContext context, {
    required AppointmentType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedType == type;
    final iconSize = _isDesktop(context) ? 32.0 : _isTablet(context) ? 28.0 : 24.0;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(_getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.lightAccentColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.lightAccentColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: _isDesktop(context) ? 60.0 : _isTablet(context) ? 56.0 : 48.0,
              height: _isDesktop(context) ? 60.0 : _isTablet(context) ? 56.0 : 48.0,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.lightAccentColor
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: iconSize,
              ),
            ),
            SizedBox(height: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            AutoSizeText(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: _getBodyFontSize(context),
                fontFamily: 'Poppins',
                color: isSelected
                    ? AppConstants.lightAccentColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              minFontSize: 14,
            ),
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: _getSmallFontSize(context),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              minFontSize: 12,
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildConfirmationStep(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'Confirma tu cita',
            style: TextStyle(
              fontSize: _getTitleFontSize(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            minFontSize: 16,
          ),
          SizedBox(height: _getSpacing(context)),
          AutoSizeText(
            'Revisa los detalles antes de confirmar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getBodyFontSize(context),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            minFontSize: 12,
          ),
          SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),

          Container(
            padding: EdgeInsets.all(_getSpacing(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  context,
                  icon: Icons.person,
                  label: 'Psicólogo',
                  value: widget.psychologist.username,
                ),
                SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                _buildSummaryRow(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  value: _selectedDate != null
                      ? _formatSelectedDate()
                      : 'No seleccionada',
                ),
                SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                _buildSummaryRow(
                  context,
                  icon: Icons.schedule,
                  label: 'Hora',
                  value: _selectedTimeSlot?.time ?? 'No seleccionada',
                ),
                SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                _buildSummaryRow(
                  context,
                  icon: _selectedType == AppointmentType.online
                      ? Icons.videocam
                      : Icons.location_on,
                  label: 'Modalidad',
                  value: _selectedType.displayName,
                ),
                SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                _buildSummaryRow(
                  context,
                  icon: Icons.attach_money,
                  label: 'Precio',
                  value: _isPremium
                      ? 'Incluido en Premium'
                      : '\$${(widget.psychologist.price ?? 0.0).toInt()}',
                ),
                if (_notesController.text.isNotEmpty) ...[
                  SizedBox(height: _getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                  _buildSummaryRow(
                    context,
                    icon: Icons.note,
                    label: 'Notas',
                    value: _notesController.text,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 32.0, desktop: 40.0)),

          // Información importante
          Container(
            padding: EdgeInsets.all(_getSpacing(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
            decoration: BoxDecoration(
              color: AppConstants.lightAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.lightAccentColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppConstants.lightAccentColor,
                      size: _getIconSize(context),
                    ),
                    SizedBox(width: _getSpacing(context)),
                    AutoSizeText(
                      'Información importante',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppConstants.lightAccentColor,
                        fontSize: _getBodyFontSize(context),
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ],
                ),
                SizedBox(height: _getSpacing(context)),
                AutoSizeText(
                  _isPremium
                      ? '• Tu cita quedará confirmada inmediatamente\n'
                            '• Recibirás una notificación de confirmación\n'
                            '• Esta sesión está incluida en tu plan Premium\n'
                            '• Podrás cancelar hasta 2 horas antes de la cita'
                      : '• Tu cita requiere pago antes de ser confirmada\n'
                            '• Serás dirigido al proceso de pago\n'
                            '• La cita se confirmará después del pago exitoso\n'
                            '• Podrás cancelar hasta 2 horas antes de la cita',
                  style: TextStyle(
                    fontSize: _getSmallFontSize(context),
                    fontFamily: 'Poppins',
                    color: AppConstants.lightAccentColor,
                    height: 1.4,
                  ),
                  maxLines: 8,
                  minFontSize: 10,
                ),
              ],
            ),
          ),

          SizedBox(height: _getSpacing(context, mobile: 32.0, tablet: 48.0, desktop: 64.0)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: _getIconSize(context), color: AppConstants.primaryColor),
        SizedBox(width: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                label,
                style: TextStyle(
                  fontSize: _getSmallFontSize(context),
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                minFontSize: 10,
              ),
              AutoSizeText(
                value,
                style: TextStyle(
                  fontSize: _getBodyFontSize(context),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                maxLines: maxLines,
                minFontSize: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
    Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: EdgeInsets.symmetric(vertical: _getSpacing(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AutoSizeText(
                  'Anterior',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: _getButtonFontSize(context),
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                ),
              ),
            ),
            SizedBox(width: _getSpacing(context)),
          ],
          Expanded(
            child: BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: _canProceed()
                      ? state.isLoading
                            ? null
                            : _handleNextStep
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.lightAccentColor,
                    padding: EdgeInsets.symmetric(vertical: _getSpacing(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? SizedBox(
                          width: _isDesktop(context) ? 24.0 : _isTablet(context) ? 22.0 : 20.0,
                          height: _isDesktop(context) ? 24.0 : _isTablet(context) ? 22.0 : 20.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : AutoSizeText(
                          _currentStep == 3
                              ? (_isPremium
                                    ? 'Confirmar Cita'
                                    : 'Continuar al Pago')
                              : 'Siguiente',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: _getButtonFontSize(context),
                          ),
                          maxLines: 1,
                          minFontSize: 14,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
    void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Confirmar cita
      _bookAppointment();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedDate != null;
      case 1:
        return _selectedTimeSlot != null;
      case 2:
        return true;
      case 3:
        return _selectedDate != null && _selectedTimeSlot != null;
      default:
        return false;
    }
  }

  void _bookAppointment() {
    if (_selectedDate != null && _selectedTimeSlot != null) {
      if (_isPremium) {
        // Si es premium, agendar normalmente
        final appointmentDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTimeSlot!.dateTime.hour,
          _selectedTimeSlot!.dateTime.minute,
        );

        context.read<AppointmentBloc>().add(
          BookAppointmentEvent(
            psychologistId: widget.psychologist.uid,
            scheduledDateTime: appointmentDateTime,
            patientId: FirebaseAuth.instance.currentUser!.uid,
            type: _selectedType,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
      } else {
        // Si no es premium, ir directamente al pago SIN agendar
        _navigateToPaymentScreen();
      }
    }
  }

  String _formatSelectedDate() {
    if (_selectedDate == null) return '';

    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final day = _selectedDate!.day;
    final month = months[_selectedDate!.month - 1];
    final year = _selectedDate!.year;
    final weekday = weekdays[_selectedDate!.weekday - 1];

    return '$weekday, $day de $month de $year';
  }
    void _showSuccessDialog({bool isPaidSession = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _isDesktop(context) ? 100.0 : _isTablet(context) ? 90.0 : 80.0,
              height: _isDesktop(context) ? 100.0 : _isTablet(context) ? 90.0 : 80.0,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check, 
                color: Colors.green, 
                size: _isDesktop(context) ? 48.0 : _isTablet(context) ? 44.0 : 40.0
              ),
            ),
            SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
            AutoSizeText(
              isPaidSession
                  ? '¡Sesión pagada, tu cita ha sido enviada al psicólogo. Recibirás una confirmación pronto!'
                  : '¡Cita agendada!',
              style: TextStyle(
                fontSize: _getTitleFontSize(context),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 16,
            ),
            SizedBox(height: _getSpacing(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            AutoSizeText(
              isPaidSession
                  ? 'Tu pago ha sido procesado y tu sesión está lista para ser confirmada.'
                  : _isPremium
                  ? 'Tu sesión Premium está confirmada. ¡Nos vemos pronto!'
                  : 'Tu cita ha sido enviada al psicólogo. Recibirás una confirmación pronto.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: _getBodyFontSize(context),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 12,
            ),
            SizedBox(height: _getSpacing(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PatientAppointmentsListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.lightAccentColor,
                  padding: EdgeInsets.symmetric(vertical: _getSpacing(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: AutoSizeText(
                  'Entendido',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: _getButtonFontSize(context),
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AutoSizeText(
          message,
          style: TextStyle(fontSize: _getBodyFontSize(context)),
          maxLines: 2,
          minFontSize: 12,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, {
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: _getIconSize(context),
          color: color,
        ),
        SizedBox(width: _getSpacing(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
        AutoSizeText(
          label,
          style: TextStyle(
            fontSize: _getSmallFontSize(context),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          minFontSize: 10,
        ),
      ],
    );
  }
}

// Widget adicional para el indicador de disponibilidad (fuera de la clase principal)
class ResponsiveAppointmentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ResponsiveAppointmentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && 
                    MediaQuery.of(context).size.width < 900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16.0 : isTablet ? 20.0 : 24.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: isMobile ? 48.0 : isTablet ? 56.0 : 60.0,
              height: isMobile ? 48.0 : isTablet ? 56.0 : 60.0,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: isMobile ? 24.0 : isTablet ? 28.0 : 32.0,
              ),
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            AutoSizeText(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14.0 : isTablet ? 16.0 : 18.0,
                fontFamily: 'Poppins',
                color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              minFontSize: 12,
            ),
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: isMobile ? 12.0 : isTablet ? 14.0 : 16.0,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
          ],
        ),
      ),
    );
  }
}