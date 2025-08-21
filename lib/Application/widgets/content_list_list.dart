// // widgets/content_list_item.dart
// import 'package:evide_dashboard/infrastructure/models/contents_model.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class ContentListItem extends StatefulWidget {
//   final ContentModel content;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final VoidCallback onLongPress;
//   final VoidCallback onDelete;

//   const ContentListItem({
//     super.key,
//     required this.content,
//     required this.isSelected,
//     required this.onTap,
//     required this.onLongPress,
//     required this.onDelete,
//   });

//   @override
//   State<ContentListItem> createState() => _ContentListItemState();
// }

// class _ContentListItemState extends State<ContentListItem>
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
//       end: 0.98,
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
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: GestureDetector(
//           onTap: widget.onTap,
//           onLongPress: widget.onLongPress,
//           onTapDown: (_) => _animationController.forward(),
//           onTapUp: (_) => _animationController.reverse(),
//           onTapCancel: () => _animationController.reverse(),
//           child: AnimatedBuilder(
//             animation: _scaleAnimation,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: _scaleAnimation.value,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: widget.isSelected 
//                       ? const Color(0xFF667eea).withOpacity(0.1)
//                       : Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: widget.isSelected 
//                         ? const Color(0xFF667eea)
//                         : Colors.transparent,
//                       width: 2,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: widget.isSelected
//                           ? const Color(0xFF667eea).withOpacity(0.2)
//                           : Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
//                         spreadRadius: 0,
//                         blurRadius: _isHovered ? 15 : 8,
//                         offset: Offset(0, _isHovered ? 4 : 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       // Thumbnail
//                       _buildThumbnail(),
//                       const SizedBox(width: 16),
//                       // Content info
//                       Expanded(
//                         child: _buildContentInfo(),
//                       ),
//                       // Actions
//                       _buildActions(),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildThumbnail() {
//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.grey.withOpacity(0.1),
//       ),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: widget.content.thumbnailUrl.isNotEmpty
//               ? CachedNetworkImage(
//                   imageUrl: widget.content.thumbnailUrl,
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                   placeholder: (context, url) => Container(
//                     width: 80,
//                     height: 80,
//                     color: Colors.grey.withOpacity(0.1),
//                     child: const Center(
//                       child: SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     ),
//                   ),
//                   errorWidget: (context, url, error) => _buildDefaultThumbnail(),
//                 )
//               : _buildDefaultThumbnail(),
//           ),
//           // Video play overlay
//           if (widget.content.isVideo)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
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
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ),
//           // Content type badge
//           Positioned(
//             top: 4,
//             left: 4,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 widget.content.fileExtension.toUpperCase(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 8,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDefaultThumbnail() {
//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Icon(
//         widget.content.isVideo 
//           ? Icons.video_file_rounded
//           : Icons.image_rounded,
//         size: 32,
//         color: Colors.grey,
//       ),
//     );
//   }

//   Widget _buildContentInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           widget.content.name,
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 4),
//         Row(
//           children: [
//             Icon(
//               widget.content.isVideo 
//                 ? Icons.videocam_rounded
//                 : Icons.image_rounded,
//               size: 16,
//               color: Colors.grey[600],
//             ),
//             const SizedBox(width: 4),
//             Text(
//               widget.content.isVideo ? 'Video' : 'Image',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Icon(
//               Icons.storage_rounded,
//               size: 16,
//               color: Colors.grey[600],
//             ),
//             const SizedBox(width: 4),
//             Text(
//               widget.content.formattedSize,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Icon(
//               Icons.access_time_rounded,
//               size: 14,
//               color: Colors.grey[500],
//             ),
//             const SizedBox(width: 4),
//             Text(
//               'Uploaded ${_formatDate(widget.content.uploadedAt)}',
//               style: TextStyle(
//                 color: Colors.grey[500],
//                 fontSize: 12,
//               ),
//             ),
//             const Spacer(),
//             if (widget.content.uploadedBy.isNotEmpty) ...[
//               Icon(
//                 Icons.person_rounded,
//                 size: 14,
//                 color: Colors.grey[500],
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 'by ${widget.content.uploadedBy}',
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActions() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Selection indicator
//         if (widget.isSelected)
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xFF667eea),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.check,
//               color: Colors.white,
//               size: 16,
//             ),
//           )
//         else if (_isHovered) ...[
//           // Action buttons on hover
//           _buildActionButton(
//             icon: Icons.visibility_rounded,
//             color: Colors.blue,
//             onTap: widget.onTap,
//             tooltip: 'Preview',
//           ),
//           const SizedBox(width: 8),
//           _buildActionButton(
//             icon: Icons.delete_rounded,
//             color: Colors.red,
//             onTap: widget.onDelete,
//             tooltip: 'Delete',
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//     required String tooltip,
//   }) {
//     return Tooltip(
//       message: tooltip,
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: color.withOpacity(0.3),
//             ),
//           ),
//           child: Icon(
//             icon,
//             color: color,
//             size: 16,
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays > 365) {
//       final years = (difference.inDays / 365).floor();
//       return '${years}y ago';
//     } else if (difference.inDays > 30) {
//       final months = (difference.inDays / 30).floor();
//       return '${months}mo ago';
//     } else if (difference.inDays > 0) {
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