import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';

/// Collectible item component that can be picked up by the player
/// Provides score value and visual/audio feedback when collected
class Collectible extends SpriteComponent with HasCollisionDetection, HasGameRef {
  /// The score value awarded when this collectible is picked up
  final int scoreValue;
  
  /// Whether this collectible has been collected
  bool _isCollected = false;
  
  /// The original Y position for floating animation
  late double _originalY;
  
  /// Random offset for animation variation
  late double _animationOffset;
  
  /// Sound effect to play when collected
  final String collectSoundPath;

  /// Creates a new collectible item
  /// 
  /// [scoreValue] - Points awarded when collected
  /// [collectSoundPath] - Path to the collection sound effect
  Collectible({
    required this.scoreValue,
    this.collectSoundPath = 'sounds/collect.wav',
    super.sprite,
    super.position,
    super.size,
  });

  @override
  Future<void> onLoad() async {
    try {
      // Store original position for floating animation
      _originalY = position.y;
      _animationOffset = Random().nextDouble() * 2 * pi;
      
      // Add floating animation
      _addFloatingAnimation();
      
      // Add spinning animation
      _addSpinningAnimation();
      
      // Add subtle scale pulse
      _addPulseAnimation();
      
    } catch (e) {
      // Handle any loading errors gracefully
      print('Error loading collectible: $e');
    }
  }

  /// Adds a floating up and down animation
  void _addFloatingAnimation() {
    final floatDistance = 10.0;
    final floatDuration = 2.0 + Random().nextDouble(); // Vary duration slightly
    
    add(
      MoveEffect.by(
        Vector2(0, -floatDistance),
        EffectController(
          duration: floatDuration,
          curve: Curves.easeInOut,
          infinite: true,
          alternate: true,
          startDelay: _animationOffset,
        ),
      ),
    );
  }

  /// Adds a continuous spinning animation
  void _addSpinningAnimation() {
    final spinDuration = 3.0 + Random().nextDouble() * 2; // Vary spin speed
    
    add(
      RotateEffect.by(
        2 * pi,
        EffectController(
          duration: spinDuration,
          infinite: true,
        ),
      ),
    );
  }

  /// Adds a subtle scale pulse animation
  void _addPulseAnimation() {
    final pulseDuration = 1.5 + Random().nextDouble();
    final pulseScale = 0.1;
    
    add(
      ScaleEffect.by(
        Vector2.all(pulseScale),
        EffectController(
          duration: pulseDuration,
          curve: Curves.easeInOut,
          infinite: true,
          alternate: true,
          startDelay: _animationOffset * 0.5,
        ),
      ),
    );
  }

  /// Handles collection of this item
  /// Returns true if successfully collected, false if already collected
  Future<bool> collect() async {
    if (_isCollected) {
      return false;
    }
    
    try {
      _isCollected = true;
      
      // Play collection sound effect
      await _playCollectSound();
      
      // Add collection animation
      await _playCollectionAnimation();
      
      // Remove from game
      removeFromParent();
      
      return true;
    } catch (e) {
      print('Error during collection: $e');
      return false;
    }
  }

  /// Plays the collection sound effect
  Future<void> _playCollectSound() async {
    try {
      await FlameAudio.play(collectSoundPath, volume: 0.7);
    } catch (e) {
      // Fail silently if sound cannot be played
      print('Could not play collect sound: $e');
    }
  }

  /// Plays the collection animation (scale up and fade out)
  Future<void> _playCollectionAnimation() async {
    // Remove existing effects to prevent conflicts
    removeAll(children.whereType<Effect>());
    
    // Scale up effect
    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.5),
      EffectController(duration: 0.2, curve: Curves.easeOut),
    );
    
    // Fade out effect
    final fadeEffect = OpacityEffect.to(
      0.0,
      EffectController(duration: 0.3, curve: Curves.easeIn),
    );
    
    // Move up slightly during collection
    final moveEffect = MoveEffect.by(
      Vector2(0, -20),
      EffectController(duration: 0.3, curve: Curves.easeOut),
    );
    
    add(scaleEffect);
    add(fadeEffect);
    add(moveEffect);
    
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Checks if this collectible has been collected
  bool get isCollected => _isCollected;

  /// Gets the current score value of this collectible
  int get currentScoreValue => _isCollected ? 0 : scoreValue;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Remove if collected and animations are done
    if (_isCollected && opacity <= 0) {
      removeFromParent();
    }
  }

  /// Creates a star-shaped collectible
  static Collectible createStar({
    required Vector2 position,
    int scoreValue = 10,
    Vector2? size,
  }) {
    return Collectible(
      scoreValue: scoreValue,
      position: position,
      size: size ?? Vector2.all(32),
      collectSoundPath: 'sounds/star_collect.wav',
    );
  }

  /// Creates a gem-shaped collectible with higher value
  static Collectible createGem({
    required Vector2 position,
    int scoreValue = 25,
    Vector2? size,
  }) {
    return Collectible(
      scoreValue: scoreValue,
      position: position,
      size: size ?? Vector2.all(40),
      collectSoundPath: 'sounds/gem_collect.wav',
    );
  }

  /// Creates a coin-shaped collectible
  static Collectible createCoin({
    required Vector2 position,
    int scoreValue = 5,
    Vector2? size,
  }) {
    return Collectible(
      scoreValue: scoreValue,
      position: position,
      size: size ?? Vector2.all(28),
      collectSoundPath: 'sounds/coin_collect.wav',
    );
  }
}