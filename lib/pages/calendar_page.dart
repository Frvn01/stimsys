import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/announcement_model.dart';

class CalendarPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const CalendarPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      if (provider.announcements.isEmpty) {
        provider.loadAnnouncements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final selectedEvents = provider.announcementsForDate(_selectedDay);
    final upcoming = provider.upcomingAnnouncements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildCalendar(isDark, provider),
          const SizedBox(height: 24),
          _buildSelectedDayEvents(isDark, selectedEvents),
          const SizedBox(height: 24),
          _buildUpcomingEvents(isDark, upcoming),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendar & Updates',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Course updates and important dates',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CALENDAR WITH EVENT MARKERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCalendar(bool isDark, StudentProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return provider.announcementsForDate(day);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                // Show color dots for each event category
                final announcements = events.cast<Announcement>();
                // Get unique category colors (max 3 dots)
                final colors = announcements
                    .map((a) => a.categoryColor)
                    .toSet()
                    .take(3)
                    .toList();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: colors.map((color) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SELECTED DAY EVENTS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSelectedDayEvents(bool isDark, List<Announcement> events) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.event_rounded,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            dateFormat.format(_selectedDay),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${events.length} event${events.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        if (events.isEmpty)
          _buildEmptyCard(isDark, 'No events on this day', 'Tap a date to check')
        else
          ...events.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAnnouncementCard(isDark, a),
              )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUpcomingEvents(bool isDark, List<Announcement> upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.upcoming_rounded,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            'Upcoming & Ongoing',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          _buildEmptyCard(isDark, 'No upcoming events', 'Check back later')
        else
          ...upcoming.take(8).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAnnouncementCard(isDark, a),
              )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANNOUNCEMENT CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAnnouncementCard(bool isDark, Announcement announcement) {
    final dateFormat = DateFormat('MMM d');
    final isSingleDay =
        announcement.startDate.year == announcement.endDate.year &&
            announcement.startDate.month == announcement.endDate.month &&
            announcement.startDate.day == announcement.endDate.day;
    final dateStr = isSingleDay
        ? dateFormat.format(announcement.startDate)
        : '${dateFormat.format(announcement.startDate)} — ${dateFormat.format(announcement.endDate)}';

    return GestureDetector(
      onTap: () => _showAnnouncementDetail(context, isDark, announcement),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: announcement.categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    announcement.categoryIcon,
                    size: 18,
                    color: announcement.categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: announcement.categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            announcement.categoryLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: announcement.categoryColor,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 11,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        if (announcement.isOngoing) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ]),
                      if (announcement.description != null &&
                          announcement.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          announcement.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.grey[600] : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(bool isDark, String title, String subtitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event,
                  size: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════
  void _showAnnouncementDetail(
      BuildContext ctx, bool isDark, Announcement announcement) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final isSingleDay =
        announcement.startDate.year == announcement.endDate.year &&
            announcement.startDate.month == announcement.endDate.month &&
            announcement.startDate.day == announcement.endDate.day;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Icon + Category
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: announcement.categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(announcement.categoryIcon,
                color: announcement.categoryColor, size: 28),
          ),
          const SizedBox(height: 16),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: announcement.categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              announcement.categoryLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: announcement.categoryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            announcement.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Date range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                isSingleDay
                    ? dateFormat.format(announcement.startDate)
                    : '${dateFormat.format(announcement.startDate)} — ${dateFormat.format(announcement.endDate)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ]),
          ),
          // Status
          if (announcement.isOngoing) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'Currently Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ]),
            ),
          ],
          // Description
          if (announcement.description != null &&
              announcement.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              announcement.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
