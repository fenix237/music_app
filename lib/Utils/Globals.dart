import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

bool isShuffle = false;
int repeatMode = 0;
final AudioPlayer globalAudioPlayer = AudioPlayer();
ValueNotifier<SongModel?> currentPlayingSong = ValueNotifier(null);
List<SongModel> currentPlaylist = [];
int currentIndex = -1;
final AudioPlayer audioPlayer = AudioPlayer();
SongModel? currentSong;
bool isPlaying = false;
final OnAudioQuery audioQuery = OnAudioQuery();
StreamSubscription? playerStateSubscription;
bool isVisibleSearch = false;