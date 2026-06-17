// ignore_for_file: dead_code, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/menu_item.dart';
import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_dialogs.dart';
import '../home/customer_profile_screen.dart';
import '../cart/cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String searchQuery = '';
  String selectedCategory = "All";
  final CartService cart = CartService();
  String currentLocation = "Fetching location...";

  final List<String> _categories = ["All", "Platters", "Meats", "Sides", "Drinks", "Spices", "Other"];

  @override
  void initState() {
    super.initState();
    cart.addListener(_onCartUpdate);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final address = await LocationService.getCurrentAddress();
    if (mounted) {
      setState(() => currentLocation = address);
    }
  }

  @override
  void dispose() {
    cart.removeListener(_onCartUpdate);
    super.dispose();
  }

  void _onCartUpdate() {
    if (mounted) setState(() {});
  }


  void _showCart() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CartScreen(deliveryAddress: currentLocation),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Cart Badge
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.braaiCoalSurface,
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.fire,
                    color: AppTheme.braaiFireOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _loadLocation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivering to",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.whitePure,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentLocation,
                            style: const TextStyle(
                              color: AppTheme.softAshGray,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Basket icon
                  Stack(
                    children: [
                      IconButton(
                        onPressed: _showCart,
                        icon: FaIcon(
                          FontAwesomeIcons.basketShopping,
                          color: AppTheme.braaiFireOrange,
                          size: 28,
                        ),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              '${cart.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerProfileScreen(),
                        ),
                      );
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.circleUser,
                      color: AppTheme.braaiFireOrange,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(color: AppTheme.whitePure),
                decoration: InputDecoration(
                  hintText: "Search grilled beef, ribs, wings...",
                  hintStyle: const TextStyle(color: AppTheme.softAshGray),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: AppTheme.braaiFireOrange,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.braaiCoalSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Categories
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((cat) {
                  final isSelected = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat == "All")...[
                            FaIcon(FontAwesomeIcons.check, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(cat),
                        ],
                      ),
                      onSelected: (selected) => setState(() => selectedCategory = cat),
                      backgroundColor: AppTheme.braaiCoalSurface,
                      selectedColor: AppTheme.braaiFireOrange,
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected? Colors.black : AppTheme.whitePure,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected? Colors.transparent : AppTheme.softAshGray,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Firebase Menu Items
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                 .collection('menu_items')
                 .where('quantity', isGreaterThan: 0)
                 .orderBy('quantity', descending: false)
                 .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase()?? '';
                    final desc = data['description']?.toString().toLowerCase()?? '';
                    final category = data['category']?.toString()?? '';

                    final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
                        desc.contains(searchQuery.toLowerCase());
                    final matchesCategory = selectedCategory == "All" || category == selectedCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.fire,
                            color: AppTheme.softAshGray,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No menu items available',
                            style: TextStyle(color: AppTheme.softAshGray, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final item = MenuItem(
                        id: doc.id,
                        name: data['name']?? 'No name',
                        description: data['description']?? '',
                        price: (data['price']?? 0).toDouble(),
                        category: data['category']?? 'Other',
                        imageUrl: data['imageUrl'],
                      );

                      final qty = data['quantity']?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.braaiCoalSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => showSpiceCustomizerDialog(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.braaiCharcoalDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.braaiFireOrange.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    image: data['imageUrl']!= null && data['imageUrl'].toString().isNotEmpty
                                     ? DecorationImage(
                                            image: NetworkImage(data['imageUrl']),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: data['imageUrl'] == null || data['imageUrl'].toString().isEmpty
                                   ? FaIcon(
                                          FontAwesomeIcons.fire,
                                          color: AppTheme.braaiFireOrange,
                                          size: 40,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.whitePure,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.softAshGray,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (qty <= 5)
                                        Text(
                                          'Only $qty left!',
                                          style: const TextStyle(
                                            color: AppTheme.braaiBasteGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "R${item.price.toInt()}",
                                      style: const TextStyle(
                                        color: AppTheme.braaiBasteGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => showSpiceCustomizerDialog(context, item),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: FaIcon(
                                          FontAwesomeIcons.circlePlus,
                                          color: AppTheme.braaiFireOrange,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}