package;

import djFlixel.D;
import openfl.display.BlendMode;

typedef SpaceBodyData = {
	?id:Int,
	centerX:Float,
	centerY:Float,
	radius:Float,
	?name:String,
	colorString:String,
	?hasBeenLandedOn:Bool,
	?isProbe:Bool,
}

class SpaceBody extends FlxSprite {
	public var midpoint(default, null):FlxPoint = FlxPoint.get();

	public var data(default, null):SpaceBodyData;
	public var radius(default, null):Float;

	var baseRadius = 140;

	var clouds:FlxSprite;
	var ringA:FlxSprite;

	override public function new(data:SpaceBodyData) {
		super(data.centerX - data.radius, data.centerY - data.radius);
		this.data = data;
		this.radius = data.radius;
		// planet.makeGraphic(Math.ceil(data.radius * 2), Math.ceil(data.radius * 2), FlxColor.TRANSPARENT);
		this.loadGraphic(Globals.random.getObject([AssetPaths.planet_cheese__png, AssetPaths.planet_gassy__png]));
		var scaleFactor = radius / baseRadius;
		this.scale.set(scaleFactor, scaleFactor);
		this.updateHitbox();
		this.angle = Globals.random.float(-180, 180);
		// FlxSpriteUtil.drawCircle(planet, -1, -1, data.radius, FlxColor.WHITE, null, {});
		this.getMidpoint(midpoint);
		this.color = FlxColor.fromString(data.colorString).getLightened(0.5);
		immovable = true;

		clouds = new FlxSprite();
		clouds.loadGraphic(AssetPaths.planet_cloud__png, true, 280, 280);
		clouds.animation.add("move", [
			for (i in 0...16)
				i
		], 4);
		clouds.animation.play("move");
		clouds.blend = BlendMode.OVERLAY;
		clouds.visible = Globals.random.bool(95);
		clouds.alpha = Globals.random.float(0.1, 0.5);
		clouds.angularVelocity = Globals.random.float(-7, 7);
		clouds.color = this.color.getAnalogousHarmony(40).warmer;
		// clouds.color.lightness = 0.85;
		clouds.scale.set(scaleFactor * 1, scaleFactor * 1);
		clouds.angle = Globals.random.float(-180, 180);
		D.align.XAxis(clouds, this);
		D.align.YAxis(clouds, this);

		ringA = new FlxSprite();
		ringA.visible = Globals.random.bool();
		ringA.loadGraphic(AssetPaths.planet_ring__png);
		ringA.alpha = Globals.random.float(0.75, 1.0);
		// clouds.angularVelocity = Globals.random.float(-10, 10);
		ringA.color = this.color.getComplementHarmony();
		ringA.scale.set(scaleFactor * 1, scaleFactor * 1);
		ringA.angle = Globals.random.float(-180, 180);
		D.align.XAxis(ringA, this);
		D.align.YAxis(ringA, this);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		clouds.update(elapsed);
		ringA.update(elapsed);
	}

	override function draw() {
		super.draw();
		if (clouds.visible) {
			clouds.draw();
		}
		if (ringA.visible) {
			ringA.draw();
		}
	}
}
