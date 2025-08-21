// // widgets/content_filter_bar.dart
// import 'dart:io';
// import 'package:evide_dashboard/infrastructure/models/contents_model.dart';
// import 'package:flutter/material.dart';

// class ContentFilterBar extends StatefulWidget {
//   final TextEditingController searchController;
//   final Function(String) onSearch;
//   final Function(MediaType?) onFilterByType;
//   final VoidCallback onClearFilters;

//   const ContentFilterBar({
//     super.key,
//     required this.searchController,
//     required this.onSearch,
//     required this.onFilterByType,
//     required this.onClearFilters,
//   });

//   @override
//   State<ContentFilterBar> createState() => _ContentFilterBarState();
// }

// class _ContentFilterBarState extends State<ContentFilterBar> {
//   MediaType? _selectedType;
//   bool _hasActiveFilters = false;

//   @override
//   void initState() {
//     super.initState();
//     widget.searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     widget.searchController.removeListener(_onSearchChanged);
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     setState(() {
//       _hasActiveFilters =
//           widget.searchController.text.isNotEmpty || _selectedType != null;
//     });
//     widget.onSearch(widget.searchController.text);
//   }

//   void _onTypeFilterChanged(MediaType? type) {
//     setState(() {
//       _selectedType = type;
//       _hasActiveFilters =
//           widget.searchController.text.isNotEmpty || _selectedType != null;
//     });
//     widget.onFilterByType(type);
//   }

//   void _clearAllFilters() {
//     setState(() {
//       _selectedType = null;
//       _hasActiveFilters = false;
//     });
//     widget.searchController.clear();
//     widget.onClearFilters();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             spreadRadius: 0,
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(flex: 3, child: _buildSearchField()),
//               const SizedBox(width: 16),
//               Expanded(flex: 2, child: _buildTypeFilter()),
//               const SizedBox(width: 16),
//               _buildClearButton(),
//             ],
//           ),
//           if (_hasActiveFilters) ...[
//             const SizedBox(height: 12),
//             _buildActiveFilters(),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.withOpacity(0.3)),
//       ),
//       child: TextField(
//         controller: widget.searchController,
//         decoration: const InputDecoration(
//           hintText: 'Search content...',
//           prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }

//   Widget _buildTypeFilter() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.withOpacity(0.3)),
//       ),
//       child: DropdownButtonFormField<MediaType?>(
//         value: _selectedType,
//         decoration: const InputDecoration(
//           prefixIcon: Icon(Icons.filter_list_rounded, color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         hint: const Text('Filter by type', style: TextStyle(fontSize: 14)),
//         items: [
//           const DropdownMenuItem<MediaType?>(
//             value: null,
//             child: Text('All Types'),
//           ),
//           DropdownMenuItem<MediaType?>(
//             value: MediaType.video,
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.video_library_rounded,
//                   size: 16,
//                   color: Colors.grey[600],
//                 ),
//                 const SizedBox(width: 8),
//                 const Text('Videos'),
//               ],
//             ),
//           ),
//           DropdownMenuItem<MediaType?>(
//             value: MediaType.image,
//             child: Row(
//               children: [
//                 Icon(Icons.image_rounded, size: 16, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 const Text('Images'),
//               ],
//             ),
//           ),
//         ],
//         onChanged: _onTypeFilterChanged,
//         style: const TextStyle(fontSize: 14, color: Colors.black87),
//         dropdownColor: Colors.white,
//       ),
//     );
//   }

//   Widget _buildClearButton() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       child: _hasActiveFilters
//           ? ElevatedButton.icon(
//               onPressed: _clearAllFilters,
//               icon: const Icon(Icons.clear_rounded, size: 16),
//               label: const Text('Clear'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red.withOpacity(0.1),
//                 foregroundColor: Colors.red,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   side: BorderSide(color: Colors.red.withOpacity(0.3)),
//                 ),
//               ),
//             )
//           : const SizedBox(width: 80),
//     );
//   }

//   Widget _buildActiveFilters() {
//     List<Widget> filterChips = [];

//     // Add search filter chip
//     if (widget.searchController.text.isNotEmpty) {
//       filterChips.add(
//         _buildFilterChip(
//           label: 'Search: "${widget.searchController.text}"',
//           onRemove: () {
//             widget.searchController.clear();
//             widget.onSearch('');
//           },
//           icon: Icons.search_rounded,
//         ),
//       );
//     }

//     // Add type filter chip
//     if (_selectedType != null) {
//       filterChips.add(
//         _buildFilterChip(
//           label: _selectedType == MediaType.video ? 'Videos' : 'Images',
//           onRemove: () => _onTypeFilterChanged(null),
//           icon: _selectedType == MediaType.video
//               ? Icons.video_library_rounded
//               : Icons.image_rounded,
//         ),
//       );
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 12),
//             child: Text(
//               'Active Filters:',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           ...filterChips,
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip({
//     required String label,
//     required VoidCallback onRemove,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFF667eea).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: const Color(0xFF667eea)),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Color(0xFF667eea),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(width: 4),
//           GestureDetector(
//             onTap: onRemove,
//             child: Container(
//               padding: const EdgeInsets.all(2),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF667eea),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.close, size: 10, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
