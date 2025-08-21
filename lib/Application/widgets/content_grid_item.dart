// // widgets/content_grid_item.dart
// import 'package:evide_dashboard/infrastructure/models/contents_model.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class ContentGridItem extends StatefulWidget {
//   final ContentModel content;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final VoidCallback onLongPress;
//   final VoidCallback onDelete;

//   const ContentGridItem({
//     super.key,
//     required this.content,
//     required this.isSelected,
//     required this.onTap,
//     required this.onLongPress,
//     required this.onDelete,
//   });

//   @override
//   State<ContentGridItem> createState() => _ContentGridItemState();
// }

// class _ContentGridItemState extends State<ContentGridItem>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   bool _isHovered = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 150),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.95,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         onLongPress: widget.onLongPress,
//         onTapDown: (_) => _animationController.forward(),
//         onTapUp: (_) => _animationController.reverse(),
//         onTapCancel: () => _animationController.reverse(),
//         child: AnimatedBuilder(
//           animation: _scaleAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: _scaleAnimation.value,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: widget.isSelected 
//                       ? const Color(0xFF667eea)
//                       : Colors.transparent,
//                     width: 3,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: widget.isSelected
//                         ? const Color(0xFF667eea).withOpacity(0.3)
//                         : Colors.black.withOpacity(_isHovered ? 0.15 : 0.1),
//                       spreadRadius: 0,
//                       blurRadius: _isHovered ? 20 : 10,
//                       offset: Offset(0, _isHovered ? 8 : 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       child: _buildThumbnail(),
//                     ),
//                     _buildContentInfo(),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildThumbnail() {
//     return Container(
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(16),
//           topRight: Radius.circular(16),
//         ),
//       ),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16),
//             ),
//             child: widget.content.thumbnailUrl.isNotEmpty
//               ? CachedNetworkImage(
//                   imageUrl: widget.content.thumbnailUrl,
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.cover,
//                   placeholder: (context, url) => Container(
//                     color: Colors.grey.withOpacity(0.1),
//                     child: const Center(
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   ),
//                   errorWidget: (context, url, error) => _buildDefaultThumbnail(),
//                 )
//               : _buildDefaultThumbnail(),
//           ),
//           // Overlay for video content
//           if (widget.content.isVideo)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.center,
//                     end: Alignment.center,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withOpacity(0.3),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: const Center(
//                   child: Icon(
//                     Icons.play_circle_filled_rounded,
//                     color: Colors.white,
//                     size: 32,
//                   ),
//                 ),
//               ),
//             ),
//           // Selection indicator
//           if (widget.isSelected)
//             Positioned(
//               top: 8,
//               right: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF667eea),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.check,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
//             ),
//           // Action buttons on hover
//           if (_isHovered && !widget.isSelected)
//             Positioned(
//               top: 8,
//               right: 8,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildActionButton(
//                     icon: Icons.delete_rounded,
//                     color: Colors.red,
//                     onTap: widget.onDelete,
//                   ),
//                 ],
//               ),
//             ),
//           // Content type badge
//           Positioned(
//             top: 8,
//             left: 8,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     widget.content.isVideo 
//                       ? Icons.videocam_rounded
//                       : Icons.image_rounded,
//                     color: Colors.white,
//                     size: 12,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     widget.content.fileExtension.toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDefaultThumbnail() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: Colors.grey.withOpacity(0.1),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             widget.content.isVideo 
//               ? Icons.video_file_rounded
//               : Icons.image_rounded,
//             size: 48,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'No Preview',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(6),
//         margin: const EdgeInsets.only(left: 4),
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.3),
//               spreadRadius: 0,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Icon(
//           icon,
//           color: Colors.white,
//           size: 16,
//         ),
//       ),
//     );
//   }

//   Widget _buildContentInfo() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(16),
//           bottomRight: Radius.circular(16),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             widget.content.name,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   widget.content.formattedSize,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//               Text(
//                 _formatDate(widget.content.uploadedAt),
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }