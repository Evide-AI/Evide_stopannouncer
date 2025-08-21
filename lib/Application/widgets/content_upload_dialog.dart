// // widgets/content_upload_dialog.dart
// import 'dart:io';
// // import 'package:evide_dashboard/Application/pages/Contents/bloc/contents_bloc.dart';
// // import 'package:evide_dashboard/Application/pages/Contents/bloc/contents_event.dart';
// import 'package:evide_dashboard/infrastructure/models/contents_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:dotted_border/dotted_border.dart';

// class ContentUploadDialog extends StatefulWidget {
//   const ContentUploadDialog({super.key});

//   @override
//   State<ContentUploadDialog> createState() => _ContentUploadDialogState();
// }

// class _ContentUploadDialogState extends State<ContentUploadDialog> {
//   File? _selectedFile;
//   String? _fileName;
//   MediaType? _mediaType;
//   bool _isDragOver = false;

//   final List<String> _supportedVideoFormats = [
//     '.mp4',
//     '.mov',
//     '.avi',
//     '.mkv',
//     '.webm',
//   ];
//   final List<String> _supportedImageFormats = [
//     '.jpg',
//     '.jpeg',
//     '.png',
//     '.gif',
//     '.webp',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: 500,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               spreadRadius: 0,
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(),
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   _buildDropZone(),
//                   if (_selectedFile != null) ...[
//                     const SizedBox(height: 20),
//                     _buildSelectedFile(),
//                   ],
//                   const SizedBox(height: 24),
//                   _buildSupportedFormats(),
//                   const SizedBox(height: 24),
//                   _buildActions(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF667eea), Color(0xFF764ba2)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.cloud_upload_rounded,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Upload Content',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Add videos and images to your library',
//                   style: TextStyle(color: Colors.white70, fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.of(context).pop(),
//             icon: const Icon(Icons.close, color: Colors.white),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropZone() {
//     return GestureDetector(
//       onTap: _pickFile,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: 200,
//         width: double.infinity,
//         child: DottedBorder(
//           options: CircularDottedBorderOptions(
//             dashPattern: const [8, 4],
//             color: _isDragOver
//                 ? const Color(0xFF667eea)
//                 : Colors.grey.withOpacity(0.5),
//             strokeWidth: 2,
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               color: _isDragOver
//                   ? const Color(0xFF667eea).withOpacity(0.1)
//                   : Colors.grey.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.cloud_upload_rounded,
//                   size: 48,
//                   color: _isDragOver ? const Color(0xFF667eea) : Colors.grey,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   _selectedFile == null
//                       ? 'Drop files here or click to browse'
//                       : 'Click to change file',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: _isDragOver
//                         ? const Color(0xFF667eea)
//                         : Colors.grey[700],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Supports videos and images up to 100MB',
//                   style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSelectedFile() {
//     if (_selectedFile == null || _fileName == null) return const SizedBox();

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF667eea).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: const Color(0xFF667eea),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               _mediaType == MediaType.video
//                   ? Icons.video_file_rounded
//                   : Icons.image_rounded,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _fileName!,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 FutureBuilder<int>(
//                   future: _selectedFile!.length(),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       return Text(
//                         _formatFileSize(snapshot.data!),
//                         style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       );
//                     }
//                     return Text(
//                       'Calculating size...',
//                       style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 _selectedFile = null;
//                 _fileName = null;
//                 _mediaType = null;
//               });
//             },
//             icon: const Icon(Icons.close, color: Colors.red),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSupportedFormats() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Supported Formats',
//             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.video_library_rounded,
//                           size: 18,
//                           color: Colors.grey[600],
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Videos:',
//                           style: TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _supportedVideoFormats.join(', ').toUpperCase(),
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.image_rounded,
//                           size: 18,
//                           color: Colors.grey[600],
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Images:',
//                           style: TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _supportedImageFormats.join(', ').toUpperCase(),
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActions() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton.icon(
//           onPressed: _selectedFile == null ? null : _uploadFile,
//           icon: const Icon(Icons.upload_rounded),
//           label: const Text('Upload'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF667eea),
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: [
//           ..._supportedVideoFormats.map((e) => e.substring(1)),
//           ..._supportedImageFormats.map((e) => e.substring(1)),
//         ],
//         allowMultiple: false,
//       );

//       if (result != null && result.files.isNotEmpty) {
//         final file = File(result.files.first.path!);
//         final fileName = result.files.first.name;
//         final fileExtension = '.${fileName.split('.').last.toLowerCase()}';

//         setState(() {
//           _selectedFile = file;
//           _fileName = fileName;

//           if (_supportedVideoFormats.contains(fileExtension)) {
//             _mediaType = MediaType.video;
//           } else if (_supportedImageFormats.contains(fileExtension)) {
//             _mediaType = MediaType.image;
//           }
//         });
//       }
//     } catch (e) {
//       _showError('Failed to pick file: $e');
//     }
//   }

//   void _uploadFile() {
//     if (_selectedFile == null || _fileName == null || _mediaType == null) {
//       return;
//     }

//     // context.read<ContentBloc>().add(
//     //   UploadContentEvent(
//     //     file: _selectedFile!,
//     //     fileName: _fileName!,
//     //     contentType: _mediaType!,
//     //   ),
//     // );

//     Navigator.of(context).pop();
//   }

//   String _formatFileSize(int bytes) {
//     if (bytes < 1024) return '${bytes}B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
//     if (bytes < 1024 * 1024 * 1024)
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
//     return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
// }
