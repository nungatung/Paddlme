import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../core/theme/app_colors.dart';
import 'booking_summary_screen.dart';
import '../payment/payment_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const DateSelectionScreen({
    super.key,
    required this. equipment,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  // Mock unavailable dates
  final List<DateTime> _unavailableDates = [
    DateTime.now().add(const Duration(days: 3)),
    DateTime.now().add(const Duration(days: 7)),
    DateTime.now().add(const Duration(days: 14)),
  ];

  bool _isDateAvailable(DateTime day) {
    return !_unavailableDates.any((unavailable) =>
        isSameDay(unavailable, day));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (! _isDateAvailable(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This date is not available'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedDay. isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _focusedDay = focusedDay;
      
      if (_selectedStartDate == null || 
          (_selectedStartDate != null && _selectedEndDate != null)) {
        // Starting a new selection
        _selectedStartDate = selectedDay;
        _selectedEndDate = null;
      } else if (selectedDay.isBefore(_selectedStartDate!)) {
        // Selected date is before start, make it the new start
        _selectedStartDate = selectedDay;
      } else {
        // Complete the range
        _selectedEndDate = selectedDay;
      }
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay?  picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors. primary,
            ),
          ),
          child: child! ,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  double _calculateTotalHours() {
    if (_selectedStartDate == null) return 0;

    final start = DateTime(
      _selectedStartDate!. year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _startTime.hour,
      _startTime.minute,
    );

    final end = DateTime(
      (_selectedEndDate ?? _selectedStartDate!).year,
      (_selectedEndDate ?? _selectedStartDate!).month,
      (_selectedEndDate ?? _selectedStartDate!).day,
      _endTime.hour,
      _endTime.minute,
    );

    return end.difference(start).inMinutes / 60;
  }

  double _calculateTotalPrice() {
    return _calculateTotalHours() * widget.equipment.pricePerHour;
  }

  void _proceedToSummary() {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:  Text('Please select a date'),
          backgroundColor: AppColors. error,
        ),
      );
      return;
    }

    final totalHours = _calculateTotalHours();
    if (totalHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to Payment Screen instead
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          equipment: widget.equipment,
          startDate: _selectedStartDate!,
          endDate: _selectedEndDate ??  _selectedStartDate!,
          startTime: _startTime,
          endTime: _endTime,
          totalHours: totalHours,
          totalPrice: _calculateTotalPrice(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Dates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Info Card
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image. network(
                            widget.equipment. imageUrls. first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:  CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.equipment. title,
                                style: const TextStyle(
                                  fontSize:  16,
                                  fontWeight:  FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height:  4),
                              Text(
                                'NZ\$${widget.equipment.pricePerHour.toStringAsFixed(0)}/hour',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Calendar
                  Container(
                    color: Colors. white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Date(s)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime. now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) {
                            if (_selectedStartDate == null) return false;
                            if (_selectedEndDate == null) {
                              return isSameDay(_selectedStartDate, day);
                            }
                            return (day.isAfter(_selectedStartDate! . subtract(const Duration(days: 1))) &&
                                day.isBefore(_selectedEndDate!. add(const Duration(days: 1))));
                          },
                          onDaySelected: _onDaySelected,
                          calendarStyle: CalendarStyle(
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors. primary. withOpacity(0.3),
                              shape: BoxShape. circle,
                            ),
                            rangeHighlightColor: AppColors.primary. withOpacity(0.1),
                            disabledDecoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            disabledTextStyle: TextStyle(color: Colors.grey[400]),
                            outsideDaysVisible: false,
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          enabledDayPredicate: _isDateAvailable,
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        Row(
                          children: [
                            _buildLegendItem(AppColors.primary, 'Selected'),
                            const SizedBox(width: 16),
                            _buildLegendItem(Colors.grey[300]!, 'Unavailable'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Time Selection
                  Container(
                    color:  Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(
                                'Start Time',
                                _startTime,
                                () => _selectTime(context, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeSelector(
                                'End Time',
                                _endTime,
                                () => _selectTime(context, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price Summary
                  if (_selectedStartDate != null && _calculateTotalHours() > 0)
                    Container(
                      color: Colors. white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:  CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NZ\$${widget.equipment.pricePerHour.toStringAsFixed(0)} × ${_calculateTotalHours().toStringAsFixed(1)} hours',
                                style: TextStyle(
                                  fontSize:  15,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'NZ\$${_calculateTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:  FontWeight.bold,
                                ),
                              ),
                              Text(
                                'NZ\$${_calculateTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize:  22,
                                  fontWeight:  FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color:  Colors.black.withOpacity(0.1),
                  blurRadius:  10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:  _proceedToSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors. white,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize:  13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:  const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize:  16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}