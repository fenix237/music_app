// import 'package:flutter/material.dart';

// class PlayListBottomSheet extends StatefulWidget {
//   const PlayListBottomSheet({super.key});

//   @override
//   State<PlayListBottomSheet> createState() => _PlayListBottomSheetState();
// }

// class _PlayListBottomSheetState extends State<PlayListBottomSheet> {
//   @override
//   Widget build(BuildContext context) {
//    return showModalBottomSheet<String>(
//     context: context,
//     isScrollControlled: true,
//     shape:  RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(
//         top: Radius.circular(30),
//       ),
//     ),
//     backgroundColor: const Color(0xFF120E2B),
//     builder: (ctx) {
//       return Padding(
//         padding:
//             EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//         child: StatefulBuilder(
//           builder: (ctx, setState) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Ajouter à une playlist",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Divider(color: Colors.white24),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: controller,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                             ),
//                             decoration: InputDecoration(
//                               contentPadding:
//                                   const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                               hintText: "Créer une nouvelle playlist",
//                               hintStyle: TextStyle(
//                                 color: Colors.white.withOpacity(0.5),
//                               ),
//                               filled: true,
//                               fillColor: const Color(0xFF2A273A),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: BorderSide.none,
//                               ),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   Icons.add,
//                                   color: Colors.white,
//                                   size: 18,
//                                 ),
//                                 onPressed: null, // on gère dans le bouton en dessous
//                               ),
//                             ),
//                             validator: (v) {
//                               if (v == null || v.trim().isEmpty) {
//                                 return "Veuillez saisir un nom";
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         TextButton(
//                           onPressed: () async {
//                             if (formKey.currentState!.validate()) {
//                               final name = controller.text.trim();
//                               final bool success =
//                                   await manager.createPlaylist(name);
//                               if (success) {
//                                 controller.clear();
//                                 setState(() {});
//                               }
//                             }
//                           },
//                           style: TextButton.styleFrom(
//                             backgroundColor: const Color(0xFFA838FF),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 10),
//                           ),
//                           child: const Text(
//                             "Créer",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Sélectionner une playlist",
//                       style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Expanded(
//                       child: FutureBuilder<List<String>>(
//                         future: manager.getPlaylistNames(),
//                         builder: (ctx, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return const Center(
//                               child: CircularProgressIndicator(
//                                 color: Color(0xFFA838FF),
//                               ),
//                             );
//                           }

//                           final playlists =
//                               snapshot.data ?? <String>[];

//                           if (playlists.isEmpty) {
//                             return Center(
//                               child: Text(
//                                 "Aucune playlist",
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.5),
//                                 ),
//                               ),
//                             );
//                           }

//                           return ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: playlists.length,
//                             itemBuilder: (ctx, i) {
//                               final name = playlists[i];
//                               return ListTile(
//                                 contentPadding: EdgeInsets.zero,
//                                 leading: Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.05),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: const Icon(
//                                     Icons.queue_music,
//                                     color: Color(0xFFA838FF),
//                                     size: 20,
//                                   ),
//                                 ),
//                                 title: Text(
//                                   name,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 onTap: () {
//                                   Navigator.pop(ctx, name);
//                                 },
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       );
//     },
//   );
//   }
// }