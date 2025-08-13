import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/tickets/services/tickets_service.dart';
import 'package:noxxi/features/tickets/widgets/ticket_card.dart';
import 'package:noxxi/features/tickets/widgets/empty_tickets_state.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

enum TicketTab { active, used, transferred }

class _TicketsScreenState extends State<TicketsScreen> with SingleTickerProviderStateMixin {
  final _ticketsService = TicketsService();
  
  // Store all tickets to avoid reloading
  List<Ticket> _activeTickets = [];
  List<Ticket> _usedTickets = [];
  List<Ticket> _transferredTickets = [];
  
  bool _activeLoaded = false;
  bool _usedLoaded = false;
  bool _transferredLoaded = false;
  
  bool _isLoading = false;
  TicketTab _currentTab = TicketTab.active;
  
  @override
  void initState() {
    super.initState();
    _loadTickets(TicketTab.active);
  }
  
  Future<void> _loadTickets(TicketTab tab) async {
    // Don't reload if already loaded
    if (tab == TicketTab.active && _activeLoaded) {
      setState(() => _currentTab = tab);
      return;
    }
    if (tab == TicketTab.used && _usedLoaded) {
      setState(() => _currentTab = tab);
      return;
    }
    if (tab == TicketTab.transferred && _transferredLoaded) {
      setState(() => _currentTab = tab);
      return;
    }
    
    setState(() {
      _currentTab = tab;
      _isLoading = true;
    });
    
    try {
      switch (tab) {
        case TicketTab.active:
          final tickets = await _ticketsService.fetchActiveTickets();
          if (mounted) {
            setState(() {
              _activeTickets = tickets;
              _activeLoaded = true;
              _isLoading = false;
            });
          }
          break;
          
        case TicketTab.used:
          final tickets = await _ticketsService.fetchUsedTickets();
          if (mounted) {
            setState(() {
              _usedTickets = tickets;
              _usedLoaded = true;
              _isLoading = false;
            });
          }
          break;
          
        case TicketTab.transferred:
          final tickets = await _ticketsService.fetchTransferredTickets();
          if (mounted) {
            setState(() {
              _transferredTickets = tickets;
              _transferredLoaded = true;
              _isLoading = false;
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _refreshCurrentTab() async {
    // Force reload current tab
    switch (_currentTab) {
      case TicketTab.active:
        _activeLoaded = false;
        break;
      case TicketTab.used:
        _usedLoaded = false;
        break;
      case TicketTab.transferred:
        _transferredLoaded = false;
        break;
    }
    await _loadTickets(_currentTab);
  }
  
  void _navigateToTicketDetails(Ticket ticket) {
    Navigator.pushNamed(
      context,
      '/ticket-details',
      arguments: ticket,
    );
  }
  
  List<Ticket> get _currentTickets {
    switch (_currentTab) {
      case TicketTab.active:
        return _activeTickets;
      case TicketTab.used:
        return _usedTickets;
      case TicketTab.transferred:
        return _transferredTickets;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Override theme for this screen
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'My Tickets',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Tab buttons
            _buildTabBar(),
            
            // Divider
            Container(height: 0.5, color: AppColors.divider.withOpacity(1.0)),
            
            // Content with AnimatedSwitcher for smooth transitions
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Active Tab
          _buildTabButton(
            tab: TicketTab.active,
            icon: Icons.confirmation_number,
            label: 'Active',
            count: _activeTickets.length,
          ),
          
          const SizedBox(width: 8),
          
          // Used Tab
          _buildTabButton(
            tab: TicketTab.used,
            icon: Icons.history,
            label: 'Used',
            count: _usedTickets.length,
          ),
          
          const SizedBox(width: 8),
          
          // Transferred Tab
          _buildTabButton(
            tab: TicketTab.transferred,
            icon: Icons.swap_horiz,
            label: 'Transferred',
            count: _transferredTickets.length,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton({
    required TicketTab tab,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final isSelected = _currentTab == tab;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _loadTickets(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryAccent
                : const Color(0xFFFCF9F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryAccent
                  : AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : AppColors.darkText.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.darkText.withOpacity(0.6),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    // Use key to force rebuild for AnimatedSwitcher
    return Container(
      key: ValueKey(_currentTab),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTickets.isEmpty
              ? EmptyTicketsState(
                  isActiveTab: _currentTab == TicketTab.active,
                  onRefresh: _refreshCurrentTab,
                )
              : RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primaryAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentTickets.length,
                    itemBuilder: (context, index) {
                      return TicketCard(
                        ticket: _currentTickets[index],
                        onTap: () => _navigateToTicketDetails(_currentTickets[index]),
                      );
                    },
                  ),
                ),
    );
  }
}