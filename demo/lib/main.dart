import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(game: MyGame()),
    ),
  );
}

class MyGame extends FlameGame with KeyboardEvents {
  TiledComponent? map;
  late final SpriteComponent player;

  // rectangles de collision (eau)
  final List<RectBox> colliders = [];

  Vector2 _dir = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final m = await TiledComponent.load(
      'map.tmx',
      Vector2.all(128),
      prefix: 'assets/maps/',
    );
    map = m;
    world.add(m);

    // --- Lire les collisions depuis Tiled (Object Layer "collisions")
    _loadCollisionsFromTiled(m);

    // --- Joueur sprite
    final sprite = await loadSprite('images/perso.png');
    player = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(96), // ajuste si besoin
      position: m.size / 2,
      anchor: Anchor.center,
    )..priority = 9999;
    world.add(player);

    // --- Caméra
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position;
    camera.viewfinder.zoom = 2.5; // zoom (change si tu veux)
  }

  void _loadCollisionsFromTiled(TiledComponent m) {
    final tiledMap = m.tileMap.map;

    // Récupère l'object layer "collisions"
    final objGroup = tiledMap.getLayer<ObjectGroup>('collisions');
    if (objGroup == null) {
      // Si tu as oublié de créer le layer, aucune collision
      return;
    }

    for (final obj in objGroup.objects) {
      // obj.x, obj.y, obj.width, obj.height sont en "pixels monde" (ici 128px par tile)
      final box = RectBox(
        x: obj.x,
        y: obj.y,
        w: obj.width,
        h: obj.height,
      );
      colliders.add(box);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final m = map;
    if (m == null) return;

    const double speed = 300.0;
    if (_dir.length2 == 0) return;

    final move = _dir.normalized() * speed * dt;

    // On tente le mouvement (axe X puis axe Y) pour un blocage propre
    _moveWithCollision(move, m.size);
    camera.viewfinder.position = player.position;
  }

  void _moveWithCollision(Vector2 move, Vector2 mapSize) {
    final half = player.size / 2;

    // position actuelle
    var newPos = player.position.clone();

    // ---- X
    newPos.x += move.x;
    newPos.x = newPos.x.clamp(half.x, mapSize.x - half.x);

    if (!_isCollidingAt(newPos)) {
      player.position.x = newPos.x;
    }

    // ---- Y
    newPos = player.position.clone();
    newPos.y += move.y;
    newPos.y = newPos.y.clamp(half.y, mapSize.y - half.y);

    if (!_isCollidingAt(newPos)) {
      player.position.y = newPos.y;
    }
  }

  bool _isCollidingAt(Vector2 pos) {
    final playerBox = RectBox.fromCenter(
      cx: pos.x,
      cy: pos.y,
      w: player.size.x,
      h: player.size.y,
    );

    for (final c in colliders) {
      if (playerBox.intersects(c)) return true;
    }
    return false;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    final dir = Vector2.zero();

    // Flèches
    if (keys.contains(LogicalKeyboardKey.arrowUp)) dir.y -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowDown)) dir.y += 1;
    if (keys.contains(LogicalKeyboardKey.arrowLeft)) dir.x -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowRight)) dir.x += 1;

    // ZQSD
    if (keys.contains(LogicalKeyboardKey.keyZ)) dir.y -= 1;
    if (keys.contains(LogicalKeyboardKey.keyS)) dir.y += 1;
    if (keys.contains(LogicalKeyboardKey.keyQ)) dir.x -= 1;
    if (keys.contains(LogicalKeyboardKey.keyD)) dir.x += 1;

    _dir = dir;
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);
}

/// Petit helper rectangle (AABB)
class RectBox {
  double x, y, w, h;

  RectBox({required this.x, required this.y, required this.w, required this.h});

  factory RectBox.fromCenter({
    required double cx,
    required double cy,
    required double w,
    required double h,
  }) {
    return RectBox(x: cx - w / 2, y: cy - h / 2, w: w, h: h);
  }

  bool intersects(RectBox other) {
    return x < other.x + other.w &&
        x + w > other.x &&
        y < other.y + other.h &&
        y + h > other.y;
  }
}