import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Main menu scene component for the puzzle game
/// Displays title, play button, level select, and settings with animated background
class MenuScene extends Component with HasGameRef, TapCallbacks {
  late TextComponent titleComponent;
  late RectangleComponent playButton;
  late TextComponent playButtonText;
  late RectangleComponent levelSelectButton;
  late TextComponent levelSelectButtonText;
  late RectangleComponent settingsButton;
  late TextComponent settingsButtonText;
  late List<CircleComponent> backgroundParticles;
  
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFF45B7D1);
  static const Color buttonColor = Color(0xFFFFA07A);
  static const Color backgroundColor = Color(0xFF98D8C8);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final size = gameRef.size;
    
    // Create animated background particles
    _createBackgroundParticles();
    
    // Create title
    titleComponent = TextComponent(
      text: 'Pattern Swap',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black26,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.25),
    );
    
    // Add title pulse animation
    titleComponent.add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 2.0,
          alternate: true,
          infinite: true,
        ),
      ),
    );
    
    // Create play button
    playButton = RectangleComponent(
      size: Vector2(200, 60),
      paint: Paint()..color = primaryColor,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.45),
    );
    
    playButton.add(
      RoundedRectangleComponent(
        size: Vector2(200, 60),
        radius: 15,
        paint: Paint()..color = primaryColor,
      ),
    );
    
    playButtonText = TextComponent(
      text: 'PLAY',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 30),
    );
    
    playButton.add(playButtonText);
    
    // Create level select button
    levelSelectButton = RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()..color = secondaryColor,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.58),
    );
    
    levelSelectButton.add(
      RoundedRectangleComponent(
        size: Vector2(200, 50),
        radius: 12,
        paint: Paint()..color = secondaryColor,
      ),
    );
    
    levelSelectButtonText = TextComponent(
      text: 'LEVEL SELECT',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 25),
    );
    
    levelSelectButton.add(levelSelectButtonText);
    
    // Create settings button
    settingsButton = RectangleComponent(
      size: Vector2(200, 50),
      paint: Paint()..color = accentColor,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.71),
    );
    
    settingsButton.add(
      RoundedRectangleComponent(
        size: Vector2(200, 50),
        radius: 12,
        paint: Paint()..color = accentColor,
      ),
    );
    
    settingsButtonText = TextComponent(
      text: 'SETTINGS',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(100, 25),
    );
    
    settingsButton.add(settingsButtonText);
    
    // Add components to scene
    addAll([
      titleComponent,
      playButton,
      levelSelectButton,
      settingsButton,
    ]);
    
    // Add button hover effects
    _addButtonEffects();
  }
  
  /// Creates animated background particles for visual appeal
  void _createBackgroundParticles() {
    backgroundParticles = [];
    final size = gameRef.size;
    final random = math.Random();
    
    for (int i = 0; i < 15; i++) {
      final particle = CircleComponent(
        radius: random.nextDouble() * 20 + 10,
        paint: Paint()..color = _getRandomParticleColor().withOpacity(0.3),
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * size.y,
        ),
      );
      
      // Add floating animation
      particle.add(
        MoveEffect.by(
          Vector2(0, -50),
          EffectController(
            duration: 3.0 + random.nextDouble() * 2.0,
            alternate: true,
            infinite: true,
          ),
        ),
      );
      
      // Add scale animation
      particle.add(
        ScaleEffect.by(
          Vector2.all(0.5),
          EffectController(
            duration: 2.0 + random.nextDouble(),
            alternate: true,
            infinite: true,
          ),
        ),
      );
      
      backgroundParticles.add(particle);
      add(particle);
    }
  }
  
  /// Returns a random color from the game's color palette
  Color _getRandomParticleColor() {
    final colors = [primaryColor, secondaryColor, accentColor, buttonColor];
    final random = math.Random();
    return colors[random.nextInt(colors.length)];
  }
  
  /// Adds hover and press effects to buttons
  void _addButtonEffects() {
    // Play button effect
    playButton.add(
      ScaleEffect.by(
        Vector2.all(0.95),
        EffectController(
          duration: 0.1,
          alternate: true,
          infinite: false,
        ),
      ),
    );
    
    // Level select button effect
    levelSelectButton.add(
      ScaleEffect.by(
        Vector2.all(0.95),
        EffectController(
          duration: 0.1,
          alternate: true,
          infinite: false,
        ),
      ),
    );
    
    // Settings button effect
    settingsButton.add(
      ScaleEffect.by(
        Vector2.all(0.95),
        EffectController(
          duration: 0.1,
          alternate: true,
          infinite: false,
        ),
      ),
    );
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    final tapPosition = event.localPosition;
    
    try {
      // Check play button tap
      if (_isPointInButton(tapPosition, playButton)) {
        _onPlayButtonPressed();
        return true;
      }
      
      // Check level select button tap
      if (_isPointInButton(tapPosition, levelSelectButton)) {
        _onLevelSelectPressed();
        return true;
      }
      
      // Check settings button tap
      if (_isPointInButton(tapPosition, settingsButton)) {
        _onSettingsPressed();
        return true;
      }
    } catch (e) {
      // Handle tap error gracefully
      print('Error handling menu tap: $e');
    }
    
    return false;
  }
  
  /// Checks if a point is within a button's bounds
  bool _isPointInButton(Vector2 point, RectangleComponent button) {
    final buttonRect = Rect.fromLTWH(
      button.position.x - button.size.x / 2,
      button.position.y - button.size.y / 2,
      button.size.x,
      button.size.y,
    );
    return buttonRect.contains(Offset(point.x, point.y));
  }
  
  /// Handles play button press
  void _onPlayButtonPressed() {
    // Add button press animation
    playButton.add(
      ScaleEffect.to(
        Vector2.all(0.9),
        EffectController(duration: 0.1),
      ),
    );
    
    // TODO: Navigate to game scene
    print('Play button pressed - starting game');
  }
  
  /// Handles level select button press
  void _onLevelSelectPressed() {
    // Add button press animation
    levelSelectButton.add(
      ScaleEffect.to(
        Vector2.all(0.9),
        EffectController(duration: 0.1),
      ),
    );
    
    // TODO: Navigate to level select scene
    print('Level select button pressed');
  }
  
  /// Handles settings button press
  void _onSettingsPressed() {
    // Add button press animation
    settingsButton.add(
      ScaleEffect.to(
        Vector2.all(0.9),
        EffectController(duration: 0.1),
      ),
    );
    
    // TODO: Navigate to settings scene
    print('Settings button pressed');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update background particles if needed
    for (final particle in backgroundParticles) {
      // Particles are automatically animated by their effects
      // Additional custom updates can be added here if needed
    }
  }
}