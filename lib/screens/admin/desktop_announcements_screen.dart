import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/announcement_model.dart';
import '../../providers/admin_provider.dart';

class DesktopAnnouncementsScreen extends StatefulWidget {
  const DesktopAnnouncementsScreen({super.key});

  @override
  State<DesktopAnnouncementsScreen> createState() =>
      _DesktopAnnouncementsScreenState();
}

class _DesktopAnnouncementsScreenState
    extends State<DesktopAnnouncementsScreen> {
  // ── Design tokens ─────────────────────────────────────────────────
  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border  = Color(0xFF232D3F);
  static const _accent  = Color(0xFF6366F1);
  static const _muted   = Color(0xFF4B5E78);

  String? _categoryFilter;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAnnouncements();
    });
  }

  List<Announcement> _filtered(List<Announcement> all) {
    var list = all;
    if (_categoryFilter != null) {
      list = list.where((a) => a.category == _categoryFilter).toList();
    }
    if (_activeFilter != null) {
      list = list.where((a) => a.isActive == _activeFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final items = _filtered(provider.announcements);
        return Container(
          color: _bg,
          child: Column(children: [
            _buildHeader(provider),
            _buildFilters(),
            Expanded(child: _buildList(items, provider)),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendar Announcements',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${provider.announcements.length} total · ${provider.announcements.where((a) => a.isActive).length} active',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12)),
              ]),
        ),
        _actionBtn(Icons.refresh_rounded, 'Refresh', () {
          provider.loadAnnouncements();
        }),
        const SizedBox(width: 10),
        _primaryBtn(Icons.add_rounded, 'New Announcement', () {
          _showCreateEditDialog(context, provider, null);
        }),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _muted, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _primaryBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: Row(children: [
        // Category chips
        _filterChip(null, 'All', _categoryFilter == null, () {
          setState(() => _categoryFilter = null);
        }),
        const SizedBox(width: 6),
        ...AnnouncementCategory.all.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _filterChip(
                AnnouncementCategory.icon(cat),
                AnnouncementCategory.label(cat),
                _categoryFilter == cat,
                () => setState(() =>
                    _categoryFilter = _categoryFilter == cat ? null : cat),
                color: AnnouncementCategory.color(cat),
              ),
            )),
        const Spacer(),
        // Active filter
        _filterChip(Icons.visibility_rounded, 'Active', _activeFilter == true,
            () {
          setState(() =>
              _activeFilter = _activeFilter == true ? null : true);
        }),
        const SizedBox(width: 6),
        _filterChip(
            Icons.visibility_off_rounded, 'Archived', _activeFilter == false,
            () {
          setState(() =>
              _activeFilter = _activeFilter == false ? null : false);
        }),
      ]),
    );
  }

  Widget _filterChip(IconData? icon, String label, bool selected,
      VoidCallback onTap,
      {Color? color}) {
    final chipColor = color ?? _accent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? chipColor.withValues(alpha: 0.15)
                : _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? chipColor.withValues(alpha: 0.4)
                  : _border,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? chipColor : _muted),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: GoogleFonts.inter(
                    color: selected ? chipColor : _muted,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildList(List<Announcement> items, AdminProvider provider) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.campaign_outlined, size: 48, color: _muted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No announcements yet',
              style: GoogleFonts.inter(color: _muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Create one to get started',
              style: GoogleFonts.inter(
                  color: _muted.withValues(alpha: 0.6), fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
      itemCount: items.length,
      itemBuilder: (_, idx) => _buildAnnouncementCard(items[idx], provider),
    );
  }

  Widget _buildAnnouncementCard(Announcement item, AdminProvider provider) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isSingleDay = item.startDate.year == item.endDate.year &&
        item.startDate.month == item.endDate.month &&
        item.startDate.day == item.endDate.day;
    final dateStr = isSingleDay
        ? dateFormat.format(item.startDate)
        : '${dateFormat.format(item.startDate)} — ${dateFormat.format(item.endDate)}';

    // Status badge
    String statusText;
    Color statusColor;
    if (!item.isActive) {
      statusText = 'Archived';
      statusColor = _muted;
    } else if (item.isOngoing) {
      statusText = 'Ongoing';
      statusColor = const Color(0xFF10B981);
    } else if (item.isUpcoming) {
      statusText = 'Upcoming';
      statusColor = const Color(0xFF3B82F6);
    } else {
      statusText = 'Past';
      statusColor = _muted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isActive ? _border : _border.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showCreateEditDialog(context, provider, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(item.categoryIcon, color: item.categoryColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(item.title,
                              style: GoogleFonts.inter(
                                  color: item.isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.categoryLabel,
                              style: GoogleFonts.inter(
                                  color: item.categoryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(statusText,
                              style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: _muted),
                        const SizedBox(width: 5),
                        Text(dateStr,
                            style: GoogleFonts.inter(
                                color: _muted, fontSize: 11)),
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.notes_rounded, size: 12, color: _muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(item.description!,
                                style: GoogleFonts.inter(
                                    color: _muted.withValues(alpha: 0.7),
                                    fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ]),
                    ]),
              ),
              const SizedBox(width: 12),
              // Toggle active
              Tooltip(
                message: item.isActive ? 'Archive' : 'Restore',
                child: Switch(
                  value: item.isActive,
                  activeThumbColor: _accent,
                  onChanged: (val) {
                    provider.toggleAnnouncementActive(item.id!, val);
                  },
                ),
              ),
              // Delete
              Tooltip(
                message: 'Delete',
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red[400]!.withValues(alpha: 0.6)),
                  onPressed: () =>
                      _confirmDelete(context, provider, item),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DELETE CONFIRMATION
  // ═══════════════════════════════════════════════════════════════════
  void _confirmDelete(
      BuildContext ctx, AdminProvider provider, Announcement item) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Announcement',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text('Delete "${item.title}"? This cannot be undone.',
            style: GoogleFonts.inter(color: _muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: _muted, fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              provider.removeAnnouncement(item.id!);
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red[400], fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE / EDIT DIALOG
  // ═══════════════════════════════════════════════════════════════════
  void _showCreateEditDialog(
      BuildContext ctx, AdminProvider provider, Announcement? existing) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _AnnouncementFormDialog(
        existing: existing,
        provider: provider,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FORM DIALOG
// ═══════════════════════════════════════════════════════════════════
class _AnnouncementFormDialog extends StatefulWidget {
  final Announcement? existing;
  final AdminProvider provider;

  const _AnnouncementFormDialog({this.existing, required this.provider});

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  static const _surface = Color(0xFF1A2235);
  static const _bg      = Color(0xFF0F172A);
  static const _border  = Color(0xFF232D3F);
  static const _accent  = Color(0xFF6366F1);
  static const _muted   = Color(0xFF4B5E78);

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _category;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? AnnouncementCategory.general;
    _startDate = e?.startDate ?? DateTime.now();
    _endDate = e?.endDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: _surface,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: _bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) _startDate = _endDate;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final announcement = Announcement(
        id: widget.existing?.id,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        startDate: _startDate,
        endDate: _endDate,
        isActive: widget.existing?.isActive ?? true,
        subjectId: widget.existing?.subjectId,
      );

      if (_isEdit) {
        await widget.provider.editAnnouncement(announcement);
      } else {
        await widget.provider.addAnnouncement(announcement);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: _accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isEdit ? 'Edit Announcement' : 'New Announcement',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: _muted, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ]),

          const SizedBox(height: 20),

          // Title
          _fieldLabel('Title'),
          const SizedBox(height: 6),
          _textField(_titleCtrl, 'e.g. Midterm Exams Week'),

          const SizedBox(height: 14),

          // Description
          _fieldLabel('Description (optional)'),
          const SizedBox(height: 6),
          _textField(_descCtrl, 'Additional details...', maxLines: 3),

          const SizedBox(height: 14),

          // Category
          _fieldLabel('Category'),
          const SizedBox(height: 6),
          _buildCategorySelector(),

          const SizedBox(height: 14),

          // Date range
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Start Date'),
                  const SizedBox(height: 6),
                  _dateButton(dateFormat.format(_startDate), () => _pickDate(true)),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('End Date'),
                  const SizedBox(height: 6),
                  _dateButton(dateFormat.format(_endDate), () => _pickDate(false)),
                ])),
          ]),

          const SizedBox(height: 24),

          // Actions
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: _border),
                  ),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Update' : 'Create',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          color: _muted, fontSize: 11, fontWeight: FontWeight.w600));

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _muted.withValues(alpha: 0.5), fontSize: 13),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: AnnouncementCategory.all.map((cat) {
        final selected = _category == cat;
        final color = AnnouncementCategory.color(cat);
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : _surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.5)
                      : _border,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(AnnouncementCategory.icon(cat),
                    size: 14, color: selected ? color : _muted),
                const SizedBox(width: 5),
                Text(AnnouncementCategory.label(cat),
                    style: GoogleFonts.inter(
                        color: selected ? color : _muted,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: _accent),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
