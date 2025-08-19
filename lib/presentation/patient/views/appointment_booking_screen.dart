// lib/presentation/patient/views/appointment_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';

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

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
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
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Agendar Cita',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AppointmentBloc, AppointmentState>(
        listener: (context, state) {
          if (state.isBooked) {
            _showSuccessDialog();
          } else if (state.isError) {
            _showErrorSnackBar(state.errorMessage!);
          }
        },
        child: Column(
          children: [
            // Indicador de pasos
            _buildStepsIndicator(),

            // Información del psicólogo
            _buildPsychologistInfo(),

            // Contenido del paso actual
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildDateSelectionStep(),
                  _buildTimeSelectionStep(),
                  _buildAppointmentDetailsStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),

            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsIndicator() {
    final steps = ['Fecha', 'Hora', 'Detalles', 'Confirmar'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isCompleted
                        ? AppConstants.primaryColor
                        : Colors.grey[300],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPsychologistInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
            backgroundImage: widget.psychologist.profilePictureUrl != null
                ? NetworkImage(widget.psychologist.profilePictureUrl!)
                : null,
            child: widget.psychologist.profilePictureUrl == null
                ? Text(
                    widget.psychologist.username.isNotEmpty
                        ? widget.psychologist.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppConstants.lightAccentColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.psychologist.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  widget.psychologist.specialty ?? 'Psicología General',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    Text(
                      '\$${(widget.psychologist.hourlyRate ?? 0.0).toInt()}/sesión',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona una fecha',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el día que prefieras para tu sesión',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),

          // Calendario personalizado
          Expanded(child: _buildCustomCalendar()),
        ],
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDate ?? today.add(const Duration(days: 1)),
        firstDate: today.add(
          const Duration(days: 1),
        ), // No permitir citas para hoy
        lastDate: today.add(const Duration(days: 60)), // Hasta 2 meses adelante
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
            _selectedTimeSlot = null; // Reset time selection
          });

          // Cargar slots de tiempo para la fecha seleccionada
          context.read<AppointmentBloc>().add(
            LoadAvailableTimeSlotsEvent(
              psychologistId: widget.psychologist.uid,
              date: date,
            ),
          );
        },
        selectableDayPredicate: (date) {
          // No permitir fines de semana
          return date.weekday != 6 && date.weekday != 7;
        },
      ),
    );
  }

  Widget _buildTimeSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona una hora',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDate != null
                ? 'Horarios disponibles para ${_formatSelectedDate()}'
                : 'Primero selecciona una fecha',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedDate != null) ...[
            Expanded(
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.hasAvailableTimeSlots) {
                    return _buildTimeSlotGrid(state.availableTimeSlots);
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay horarios disponibles',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
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
                    Icon(
                      Icons.date_range_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una fecha primero',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: 'Poppins',
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

  Widget _buildTimeSlotGrid(List<TimeSlot> timeSlots) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final isSelected = _selectedTimeSlot?.time == slot.time;

        return InkWell(
          onTap: slot.isAvailable
              ? () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: slot.isAvailable
                  ? isSelected
                        ? AppConstants.lightAccentColor
                        : Theme.of(context).cardColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppConstants.lightAccentColor
                    : slot.isAvailable
                    ? Colors.grey[300]!
                    : Colors.grey[400]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.time,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: slot.isAvailable
                        ? isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[500],
                  ),
                ),
                if (!slot.isAvailable && slot.reason != null)
                  Text(
                    slot.reason!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la cita',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura los detalles de tu sesión',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),

          // Tipo de cita
          Text(
            'Modalidad de la sesión',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAppointmentTypeCard(
                  type: AppointmentType.online,
                  icon: Icons.videocam,
                  title: 'En línea',
                  subtitle: 'Videoconferencia',
                ),
              ),
              // Por ahora solo modalidad en línea disponible
              // TODO: Implementar modalidad presencial en el futuro
              /* 
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppointmentTypeCard(
                  type: AppointmentType.inPerson,
                  icon: Icons.location_on,
                  title: 'Presencial',
                  subtitle: 'En consultorio',
                ),
              ),
              */
            ],
          ),

          const SizedBox(height: 24),

          // Notas adicionales
          Text(
            'Notas adicionales (opcional)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe brevemente el motivo de tu consulta o cualquier información relevante...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontFamily: 'Poppins',
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
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontFamily: 'Poppins'),
          ),

          // Espacio adicional para evitar que el contenido quede pegado al botón
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeCard({
    required AppointmentType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.lightAccentColor
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
                color: isSelected
                    ? AppConstants.lightAccentColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirma tu cita',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisa los detalles antes de confirmar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),

          // Resumen de la cita
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  icon: Icons.person,
                  label: 'Psicólogo',
                  value: widget.psychologist.username,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  value: _selectedDate != null
                      ? _formatSelectedDate()
                      : 'No seleccionada',
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  icon: Icons.schedule,
                  label: 'Hora',
                  value: _selectedTimeSlot?.time ?? 'No seleccionada',
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  icon: _selectedType == AppointmentType.online
                      ? Icons.videocam
                      : Icons.location_on,
                  label: 'Modalidad',
                  value: _selectedType.displayName,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  icon: Icons.attach_money,
                  label: 'Precio',
                  value: '\$${(widget.psychologist.hourlyRate ?? 0.0).toInt()}',
                ),
                if (_notesController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    icon: Icons.note,
                    label: 'Notas',
                    value: _notesController.text,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Información importante
          Container(
            padding: const EdgeInsets.all(16),
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Información importante',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppConstants.lightAccentColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tu cita quedará pendiente de confirmación\n'
                  '• El psicólogo confirmará en un máximo de 24 horas\n'
                  '• Recibirás una notificación cuando sea confirmada\n'
                  '• Podrás cancelar hasta 2 horas antes de la cita',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: AppConstants.lightAccentColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Espacio adicional para evitar que el contenido quede pegado al botón
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Anterior',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep == 3 ? 'Confirmar Cita' : 'Siguiente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
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
        return true; // Siempre se puede proceder desde detalles
      case 3:
        return _selectedDate != null && _selectedTimeSlot != null;
      default:
        return false;
    }
  }

  void _bookAppointment() {
    if (_selectedDate != null && _selectedTimeSlot != null) {
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
          type: _selectedType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Cita agendada!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu cita ha sido enviada al psicólogo. Recibirás una confirmación pronto.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.lightAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
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
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
