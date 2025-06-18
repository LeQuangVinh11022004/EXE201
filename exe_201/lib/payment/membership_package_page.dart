import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '/nav/bottom_nav_bar.dart';
import '../api/service_package_api.dart';

class MembershipPackagePage extends StatefulWidget {
  const MembershipPackagePage({super.key});

  @override
  State<MembershipPackagePage> createState() => _MembershipPackagePageState(); // Consistent state class name
}

class _MembershipPackagePageState extends State<MembershipPackagePage> {
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> uniqueDeals = [];
  bool isLoading = true; // Ensure this is declared
  bool isClaiming = false;
  Map<String, int> selectedDurations = {};

  @override
  void initState() {
    super.initState();
    _fetchPackagesAndDeals();
  }

  Future<void> _fetchPackagesAndDeals() async {
    setState(() => isLoading = true);
    try {
      final fetchedPackages = await ServicePackageApi.fetchServicePackages();
      final updatedPackages = <Map<String, dynamic>>[];

      final allDeals = await ServicePackageApi.fetchDeals(''); // Fetch deals once

      for (var package in fetchedPackages) {
        updatedPackages.add({
          ...package,
          'deals': allDeals,
        });
      }

      final uniqueDealsSet = allDeals.toSet().toList();

      setState(() {
        packages = updatedPackages;
        uniqueDeals = uniqueDealsSet;
        isLoading = false;
        selectedDurations = {for (var package in packages) package['id'] as String: 1};
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching packages or deals: ${e.toString().replaceFirst('Exception: ', '')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _claimPackage(String packageId, int monthNumber) async {
    setState(() => isLoading = true); // Update to isLoading for consistency
    try {
      final package = packages.firstWhere(
            (pkg) => pkg['id'] == packageId,
        orElse: () => throw Exception('Invalid package ID. Please try another package.'),
      );

      final deals = package['deals'] is List
          ? (package['deals'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      Map<String, dynamic>? selectedDeal;

      final applicableDeals = deals.where((deal) {
        final dealDuration = deal['offerConditions'] as int?;
        final dealStatus = deal['status'] as String?;
        final dealEndDate = deal['endDate'] != null ? DateTime.parse(deal['endDate']).toLocal() : null;
        final isValid = dealDuration == monthNumber &&
            dealStatus == 'Active' &&
            (dealEndDate == null || dealEndDate.isAfter(DateTime.now()));
        return isValid;
      }).toList();

      if (applicableDeals.isNotEmpty && monthNumber != 1) {
        selectedDeal = applicableDeals.reduce((best, current) {
          final bestRate = best['discountRate'] as double? ?? 0.0;
          final currentRate = current['discountRate'] as double? ?? 0.0;
          return bestRate > currentRate ? best : current;
        });
      } else if (monthNumber != 1 && applicableDeals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid deals available for the selected duration.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final dealId = selectedDeal?['id'];

      final paymentUrl = await ServicePackageApi.claimPackage(packageId, dealId, monthNumber);
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _fetchPackagesAndDeals();
      } else {
        throw Exception('Could not launch $paymentUrl');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('Deals not found for package ID')) {
        errorMessage = 'No deals available for this package. Please try another package or contact support.';
      } else if (errorMessage.contains('Deal not found') || errorMessage.contains('not valid')) {
        errorMessage = 'Selected deal is not valid. Please contact support.';
        final fallbackUrl = await ServicePackageApi.claimPackage(packageId, null, monthNumber);
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          await _fetchPackagesAndDeals();
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Membership Packages', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.comment, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading // Use isLoading here
          ? Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 200, height: 20, color: Colors.white),
              const SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 150,
                color: Colors.white,
              ),
            ],
          ),
        ),
      )
          : packages.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.boxOpen, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No packages available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPackagesAndDeals,
              style: Theme.of(context).elevatedButtonTheme.style,
              child: Text('Retry', style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchPackagesAndDeals,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Your Perfect Plan',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowsRotate, color: Colors.black87),
                      onPressed: _fetchPackagesAndDeals,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...packages.map((package) => _buildPackageCard(
                  title: package['name'] ?? 'Unknown Package',
                  price: (package['price'] as double?)?.toStringAsFixed(2) ?? 'N/A',
                  features: List<String>.from(package['description']?.split(';') ?? []),
                  borderColor: _parseColor(package['borderColor'] ?? '#E0E0E0'),
                  buttonColor: _parseColor(package['buttonColor'] ?? '#757575'),
                  packageId: package['id'] as String?,
                  deals: package['deals'] is List
                      ? (package['deals'] as List).whereType<Map<String, dynamic>>().toList()
                      : <Map<String, dynamic>>[],
                  onClaim: (package['price'] as double? ?? 0) > 0
                      ? () async {
                    final packageId = package['id'] as String?;
                    final duration = selectedDurations[packageId] ?? 1;
                    if (packageId != null) {
                      await _claimPackage(packageId, duration);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Package ID is missing')),
                      );
                    }
                  }
                      : null,
                  isClaiming: isClaiming,
                )),
                const SizedBox(height: 24),
                Text(
                  'Special Offers',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                ...uniqueDeals.map((deal) => _buildDealCard(deal)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String price,
    required List<String> features,
    required Color borderColor,
    required Color buttonColor,
    required String? packageId,
    required List<Map<String, dynamic>> deals,
    required VoidCallback? onClaim,
    required bool isClaiming,
  }) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Theme.of(context).colorScheme.surface.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '$price VND',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Duration: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                DropdownButton<int>(
                  value: selectedDurations[packageId] ?? 1,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Month')),
                    DropdownMenuItem(value: 6, child: Text('6 Months')),
                    DropdownMenuItem(value: 12, child: Text('12 Months')),
                  ],
                  onChanged: (value) {
                    if (value != null && packageId != null) {
                      setState(() {
                        selectedDurations[packageId] = value;
                      });
                    }
                  },
                  style: Theme.of(context).textTheme.bodyMedium,
                  underline: Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features
                .map((feature) => _buildFeatureRow(feature.trim()))
                .where((widget) => (widget as Padding).child != null),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: isClaiming ? null : onClaim,
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.grey[400];
                    }
                    return buttonColor;
                  }),
                  overlayColor: WidgetStateProperty.all(Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
                ),
                child: isClaiming
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Claim Offer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    if (feature.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.checkCircle, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(feature, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.star,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${deal['name'] ?? 'Unnamed Deal'} - ${(deal['discountRate'] * 100).toStringAsFixed(0)}% off, '
                    'Duration: ${deal['offerConditions']} months, '
                    'Ends: ${deal['endDate'] != null ? DateTime.parse(deal['endDate']).toLocal().toString().split(' ')[0] : 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
    } catch (e) {
      return Theme.of(context).colorScheme.error;
    }
  }
}