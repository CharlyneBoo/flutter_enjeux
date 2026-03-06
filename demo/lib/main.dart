import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiled/tiled.dart';

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

    _loadCollisionsFromTiled(m);

   
    final sprite = await loadSprite('perso.png');

    player = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(96),
      position: m.size / 2,
      anchor: Anchor.center,
    )..priority = 9999;

    world.add(player);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position;
    camera.viewfinder.zoom = 2.5;
  }

  void _loadCollisionsFromTiled(TiledComponent m) {
    final tiledMap = m.tileMap.map;

    try {
      final layer = tiledMap.layerByName('collisions');

      if (layer is! ObjectGroup) return;

      for (final obj in layer.objects) {
        colliders.add(
          RectBox(
            x: obj.x,
            y: obj.y,
            w: obj.width,
            h: obj.height,
          ),
        );
      }
    } on ArgumentError {
      return;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final m = map;
    if (m == null) return;
    if (_dir.length2 == 0) return;

    const double speed = 300.0;
    final move = _dir.normalized() * speed * dt;

    _moveWithCollision(move, m.size);
    camera.viewfinder.position = player.position;
  }

  void _moveWithCollision(Vector2 move, Vector2 mapSize) {
    final half = player.size / 2;
    var newPos = player.position.clone();

    newPos.x += move.x;
    newPos.x = newPos.x.clamp(half.x, mapSize.x - half.x);
    if (!_isCollidingAt(newPos)) {
      player.position.x = newPos.x;
    }

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

    if (keys.contains(LogicalKeyboardKey.arrowUp)) dir.y -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowDown)) dir.y += 1;
    if (keys.contains(LogicalKeyboardKey.arrowLeft)) dir.x -= 1;
    if (keys.contains(LogicalKeyboardKey.arrowRight)) dir.x += 1;

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

class RectBox {
  double x, y, w, h;

  RectBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory RectBox.fromCenter({
    required double cx,
    required double cy,
    required double w,
    required double h,
  }) {
    return RectBox(
      x: cx - w / 2,
      y: cy - h / 2,
      w: w,
      h: h,
    );
  }

  bool intersects(RectBox other) {
    return x < other.x + other.w &&
        x + w > other.x &&
        y < other.y + other.h &&
        y + h > other.y;
  }
}