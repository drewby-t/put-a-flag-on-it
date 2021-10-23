package;

class Probe extends SpaceBody {
	public var speed(default, null):Float = 270;
	public var hasFired(default, default):Bool = false;
	public var hasLanded(default, default):Bool = false;
	public var hasCollided(default, default):Bool = false;
	public var originalBearing(default, default):Float = 0;
	public var currentBearing(default, default):FlxVector = FlxVector.get();
	public var thrust(default, default):FlxPoint = FlxPoint.get();

	public var mostRecentlyCollidedBody:SpaceBody = null;

	override public function new() {
		super({
			id: -99,
			isProbe: true,
			radius: 7,
			colorString: "MAGENTA",
			centerX: 0,
			centerY: 0,
		});
		immovable = false;
		clouds.visible = ringA.visible = false;

		loadGraphic(AssetPaths.probe__png, true, 32, 32);
		animation.add("blink", [0, 1, 2, 3], 8, true);
		animation.play("blink");
		this.scale.set(1, 1);
		this.updateHitbox();
		this.color = FlxColor.WHITE;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		getMidpoint(midpoint);
		planetNameTooltip.visible = false;
		if (!hasCollided) {
			angle = Utils.normalizeAngle(currentBearing.degrees + 90);
		} else {
			// var bodyToProbe = FlxVector.get(midpoint.x - mostRecentlyCollidedBody.midpoint.x, midpoint.y - most.midpoint.y);
			// angle =
		}
	}
}
