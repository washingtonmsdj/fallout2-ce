#!/usr/bin/env python3
"""
Verify audio volume application
This tests that volume settings are applied correctly to all audio channels
"""

import random

class MockAudioPlayer:
	"""Mock audio player"""
	def __init__(self, name):
		self.name = name
		self.volume_db = 0.0
		self.volume_linear = 1.0
	
	def set_volume(self, volume_linear):
		"""Set volume (0.0 to 1.0)"""
		self.volume_linear = max(0.0, min(1.0, volume_linear))
		# Convert to dB (simplified)
		self.volume_db = volume_linear * 100.0 - 100.0  # Rough approximation

class MockAudioManager:
	"""Mock audio manager"""
	def __init__(self):
		self.master_volume = 1.0
		self.music_volume = 1.0
		self.sfx_volume = 1.0
		self.voice_volume = 1.0
		
		self.music_player = MockAudioPlayer("music")
		self.sfx_players = [MockAudioPlayer("sfx_0"), MockAudioPlayer("sfx_1")]
		self.voice_player = MockAudioPlayer("voice")
	
	def set_master_volume(self, value):
		"""Set master volume"""
		self.master_volume = max(0.0, min(1.0, value))
		self._apply_volumes()
	
	def set_music_volume(self, value):
		"""Set music volume"""
		self.music_volume = max(0.0, min(1.0, value))
		self._apply_volumes()
	
	def set_sfx_volume(self, value):
		"""Set SFX volume"""
		self.sfx_volume = max(0.0, min(1.0, value))
		self._apply_volumes()
	
	def set_voice_volume(self, value):
		"""Set voice volume"""
		self.voice_volume = max(0.0, min(1.0, value))
		self._apply_volumes()
	
	def _apply_volumes(self):
		"""Apply volumes to all players"""
		# Music: music_volume * master_volume
		self.music_player.set_volume(self.music_volume * self.master_volume)
		
		# SFX: sfx_volume * master_volume
		for player in self.sfx_players:
			player.set_volume(self.sfx_volume * self.master_volume)
		
		# Voice: voice_volume * master_volume
		self.voice_player.set_volume(self.voice_volume * self.master_volume)

def test_audio_volume_application(num_iterations=100):
	"""Test the audio volume application property"""
	passed = 0
	failed = 0
	failures = []
	
	for i in range(num_iterations):
		audio_manager = MockAudioManager()
		
		# Test 1: Master volume affects all channels
		master_vol = random.uniform(0.0, 1.0)
		audio_manager.set_master_volume(master_vol)
		
		expected_music = audio_manager.music_volume * master_vol
		expected_sfx = audio_manager.sfx_volume * master_vol
		expected_voice = audio_manager.voice_volume * master_vol
		
		music_match = abs(audio_manager.music_player.volume_linear - expected_music) < 0.001
		sfx_match = all(abs(p.volume_linear - expected_sfx) < 0.001 for p in audio_manager.sfx_players)
		voice_match = abs(audio_manager.voice_player.volume_linear - expected_voice) < 0.001
		
		if music_match and sfx_match and voice_match:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'master_volume',
				'master_vol': master_vol,
				'music_match': music_match,
				'sfx_match': sfx_match,
				'voice_match': voice_match
			})
			continue
		
		# Test 2: Individual volume controls work
		music_vol = random.uniform(0.0, 1.0)
		sfx_vol = random.uniform(0.0, 1.0)
		voice_vol = random.uniform(0.0, 1.0)
		
		audio_manager.set_music_volume(music_vol)
		audio_manager.set_sfx_volume(sfx_vol)
		audio_manager.set_voice_volume(voice_vol)
		
		expected_music = music_vol * audio_manager.master_volume
		expected_sfx = sfx_vol * audio_manager.master_volume
		expected_voice = voice_vol * audio_manager.master_volume
		
		music_match = abs(audio_manager.music_player.volume_linear - expected_music) < 0.001
		sfx_match = all(abs(p.volume_linear - expected_sfx) < 0.001 for p in audio_manager.sfx_players)
		voice_match = abs(audio_manager.voice_player.volume_linear - expected_voice) < 0.001
		
		if music_match and sfx_match and voice_match:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'individual_volumes',
				'music_vol': music_vol,
				'sfx_vol': sfx_vol,
				'voice_vol': voice_vol,
				'music_match': music_match,
				'sfx_match': sfx_match,
				'voice_match': voice_match
			})
			continue
		
		# Test 3: Volume clamping (0.0 to 1.0)
		audio_manager.set_master_volume(2.0)  # Should clamp to 1.0
		if audio_manager.master_volume == 1.0:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'volume_clamping',
				'master_vol': audio_manager.master_volume,
				'expected': 1.0
			})
			continue
		
		audio_manager.set_master_volume(-1.0)  # Should clamp to 0.0
		if audio_manager.master_volume == 0.0:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'volume_clamping_negative',
				'master_vol': audio_manager.master_volume,
				'expected': 0.0
			})
			continue
		
		# Test 4: Volume changes apply immediately
		audio_manager.set_master_volume(0.5)
		audio_manager.set_music_volume(0.8)
		
		expected = 0.5 * 0.8
		actual = audio_manager.music_player.volume_linear
		
		if abs(actual - expected) < 0.001:
			passed += 1
		else:
			failed += 1
			failures.append({
				'iteration': i,
				'test': 'immediate_application',
				'expected': expected,
				'actual': actual
			})
	
	print(f"=== Property Test: Audio Volume Application ===")
	print(f"Passed: {passed} / {num_iterations * 5}")
	print(f"Failed: {failed} / {num_iterations * 5}")
	
	if failed > 0:
		print("\n=== Failed Cases (first 5) ===")
		for failure in failures[:5]:
			print(f"Iteration {failure['iteration']}:")
			print(f"  Test: {failure['test']}")
			if 'master_vol' in failure:
				print(f"  Master volume: {failure['master_vol']}")
			if 'music_match' in failure:
				print(f"  Music match: {failure['music_match']}")
			if 'sfx_match' in failure:
				print(f"  SFX match: {failure['sfx_match']}")
			if 'voice_match' in failure:
				print(f"  Voice match: {failure['voice_match']}")
			if 'expected' in failure:
				print(f"  Expected: {failure['expected']}")
			if 'actual' in failure:
				print(f"  Actual: {failure['actual']}")
		
		if len(failures) > 5:
			print(f"... and {len(failures) - 5} more failures")
		
		print("\nPROPERTY TEST FAILED")
		return False
	else:
		print("\nPROPERTY TEST PASSED")
		return True

if __name__ == "__main__":
	success = test_audio_volume_application(100)
	exit(0 if success else 1)

