import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Obstacle component that blocks tile swapping and adds challenge to puzzle gameplay
class Obstacle extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  /// Type of obstacle affecting behavior and appearance
  final ObstacleType type;
  
  /// Whether this obstacle is currently active
  bool isActive = true;
  
  /// Remaining health for destructible obstacles
  int health;
  
  /// Movement speed for moving obstacles
  final double moveSpeed;
  
  /// Direction vector for moving obstacles
  Vector2 _direction = Vector2.zero();
  
  /// Visual representation of the obstacle
  late RectangleComponent _visual;
  
  /// Collision hitbox
  late RectangleHitbox _hitbox;
  
  /// Random number generator for movement patterns
  static final Random _random = Random();

  Obstacle({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    this.health = 1,
    this.moveSpeed = 50.0,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create visual representation
    _visual = RectangleComponent(
      size: size,
      paint: Paint()..color = _getObstacleColor(),
    );
    add(_visual);
    
    // Add collision hitbox
    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
    
    // Initialize movement direction for moving obstacles
    if (type == ObstacleType.moving) {
      _initializeMovement();
    }
    
    // Add spawn animation
    _playSpawnAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    // Handle movement for moving obstacles
    if (type == ObstacleType.moving) {
      _updateMovement(dt);
    }
    
    // Handle pulsing animation for energy barriers
    if (type == ObstacleType.energyBarrier) {
      _updatePulseEffect(dt);
    }
  }

  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isActive) return false;
    
    // Handle collision with player tiles or swappable elements
    if (other.hasCollisionDetection) {
      _handleCollision(other);
      return true;
    }
    
    return false;
  }

  /// Handles collision with other components
  void _handleCollision(PositionComponent other) {
    switch (type) {
      case ObstacleType.solid:
        // Block movement/swapping
        _blockInteraction(other);
        break;
        
      case ObstacleType.destructible:
        // Take damage and potentially break
        _takeDamage();
        break;
        
      case ObstacleType.moving:
        // Bounce off or change direction
        _bounceOffCollision();
        break;
        
      case ObstacleType.energyBarrier:
        // Disable temporarily on contact
        _temporaryDisable();
        break;
    }
  }

  /// Blocks interaction with tiles
  void _blockInteraction(PositionComponent other) {
    // Add visual feedback for blocked interaction
    add(ScaleEffect.by(
      Vector2.all(1.1),
      EffectController(duration: 0.1, reverseDuration: 0.1),
    ));
    
    // Change color briefly to indicate blocking
    final originalColor = _visual.paint.color;
    _visual.paint.color = Colors.red.withOpacity(0.8);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isMounted) {
        _visual.paint.color = originalColor;
      }
    });
  }

  /// Handles damage to destructible obstacles
  void _takeDamage() {
    health--;
    
    if (health <= 0) {
      _destroyObstacle();
    } else {
      // Visual damage feedback
      add(ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ));
    }
  }

  /// Destroys the obstacle with animation
  void _destroyObstacle() {
    isActive = false;
    
    // Destruction animation
    add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.3),
      onComplete: () => removeFromParent(),
    ));
    
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.3),
    ));
  }

  /// Handles bouncing for moving obstacles
  void _bounceOffCollision() {
    // Reverse direction
    _direction = -_direction;
    
    // Add slight randomization to prevent predictable patterns
    final randomAngle = (_random.nextDouble() - 0.5) * 0.5;
    _direction.rotate(randomAngle);
    _direction.normalize();
  }

  /// Temporarily disables energy barriers
  void _temporaryDisable() {
    isActive = false;
    _visual.paint.color = _visual.paint.color.withOpacity(0.3);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (isMounted) {
        isActive = true;
        _visual.paint.color = _getObstacleColor();
      }
    });
  }

  /// Initializes movement for moving obstacles
  void _initializeMovement() {
    final angle = _random.nextDouble() * 2 * pi;
    _direction = Vector2(cos(angle), sin(angle));
  }

  /// Updates movement for moving obstacles
  void _updateMovement(double dt) {
    final movement = _direction * moveSpeed * dt;
    position.add(movement);
    
    // Bounce off screen boundaries
    if (position.x <= 0 || position.x >= parent!.size.x - size.x) {
      _direction.x = -_direction.x;
      position.x = position.x.clamp(0, parent!.size.x - size.x);
    }
    
    if (position.y <= 0 || position.y >= parent!.size.y - size.y) {
      _direction.y = -_direction.y;
      position.y = position.y.clamp(0, parent!.size.y - size.y);
    }
  }

  /// Updates pulsing effect for energy barriers
  void _updatePulseEffect(double dt) {
    final pulseIntensity = (sin(DateTime.now().millisecondsSinceEpoch * 0.005) + 1) * 0.5;
    _visual.paint.color = _getObstacleColor().withOpacity(0.5 + pulseIntensity * 0.5);
  }

  /// Plays spawn animation
  void _playSpawnAnimation() {
    scale = Vector2.zero();
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.5, curve: Curves.elasticOut),
    ));
  }

  /// Returns color based on obstacle type
  Color _getObstacleColor() {
    switch (type) {
      case ObstacleType.solid:
        return const Color(0xFF8B4513); // Brown
      case ObstacleType.destructible:
        return health > 1 ? const Color(0xFF696969) : const Color(0xFFA0A0A0); // Gray variants
      case ObstacleType.moving:
        return const Color(0xFF4169E1); // Royal blue
      case ObstacleType.energyBarrier:
        return const Color(0xFF00FFFF); // Cyan
    }
  }

  /// Spawns an obstacle at the specified position
  static Obstacle spawn({
    required ObstacleType type,
    required Vector2 position,
    required Vector2 size,
    int health = 1,
    double moveSpeed = 50.0,
  }) {
    return Obstacle(
      type: type,
      position: position,
      size: size,
      health: health,
      moveSpeed: moveSpeed,
    );
  }
}

/// Types of obstacles with different behaviors
enum ObstacleType {
  /// Solid obstacle that blocks all interactions
  solid,
  
  /// Destructible obstacle that can be broken
  destructible,
  
  /// Moving obstacle that changes position
  moving,
  
  /// Energy barrier that can be temporarily disabled
  energyBarrier,
}