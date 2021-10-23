package;

import djFlixel.D;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup;
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
	?gfx:SpaceBodyGfx,
}

typedef SpaceBodyGfx = {
	?cloudsAngularVelocity:Float,
	?cloundsColor:FlxColor,
	?cloundsAlpha:Float,
	?cloudsAngle:Float,
	?ringAVisible:Bool,
	?ringAAngle:Float,
	?ringAAlpha:Float,
	?ringAColor:FlxColor,
}

class SpaceBody extends FlxSprite {
	public var midpoint(default, null):FlxPoint = FlxPoint.get();

	public var data(default, null):SpaceBodyData;
	public var radius(default, null):Float;

	var baseRadius = 140;

	var clouds:FlxSprite;
	var ringA:FlxSprite;

	public var flags:FlxGroup = new FlxGroup();

	public var planetNameTooltip:FlxUIGroup;

	var planetNameText:FlxUIText;

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

		if (data.gfx == null) {
			data.gfx = {
				cloudsAngularVelocity: Globals.random.float(-7, 7),
				cloudsAngle: Globals.random.float(-180, 180),
				cloundsAlpha: Globals.random.float(0.1, 0.5),
				cloundsColor: this.color.getAnalogousHarmony(40).warmer,
				ringAVisible: Globals.random.bool(65),
				ringAAlpha: Globals.random.float(0.75, 1.0),
				ringAColor: this.color.getComplementHarmony().getLightened(0.4),
				ringAAngle: Globals.random.float(-180, 180)
			}
		}

		clouds.animation.play("move");
		clouds.alpha = data.gfx.cloundsAlpha;
		clouds.angularVelocity = data.gfx.cloudsAngularVelocity;
		clouds.color = data.gfx.cloundsColor;
		clouds.scale.set(scaleFactor * 1, scaleFactor * 1);
		clouds.angle = data.gfx.cloudsAngle;
		D.align.XAxis(clouds, this);
		D.align.YAxis(clouds, this);

		ringA = new FlxSprite();
		ringA.visible = data.gfx.ringAVisible;
		ringA.loadGraphic(AssetPaths.planet_ring__png);
		ringA.alpha = data.gfx.ringAAlpha;
		// clouds.angularVelocity = Globals.random.float(-10, 10);
		ringA.color = data.gfx.ringAColor;
		ringA.scale.set(scaleFactor * 1, scaleFactor * 1);
		ringA.angle = data.gfx.ringAAngle;
		D.align.XAxis(ringA, this);
		D.align.YAxis(ringA, this);

		planetNameTooltip = new FlxUIGroup();
		planetNameText = new FlxUIText(0, 0, 130, data.name == null ? "Unknown Planet" : data.name, 20);
		planetNameText.color = FlxColor.LIME;
		planetNameText.alignment = FlxTextAlign.CENTER;
		planetNameText.font = AssetPaths.Ubuntu_Bold__ttf;
		var bg = new FlxSprite();
		var padding = 4;
		bg.makeGraphic(planetNameText.frameWidth + padding * 2, Std.int(planetNameText.textField.textHeight + padding * 2), FlxColor.GRAY.getDarkened(0.88));
		FlxSpriteUtil.drawRect(bg, 1, 1, bg.frameWidth - 2, bg.frameHeight - 2, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.LIME});
		D.align.XAxis(bg, planetNameText);
		D.align.YAxis(bg, planetNameText);
		planetNameTooltip.add(bg);
		planetNameTooltip.add(planetNameText);

		planetNameTooltip.visible = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		clouds.update(elapsed);
		ringA.update(elapsed);
		flags.update(elapsed);
		planetNameTooltip.update(elapsed);
		planetNameTooltip.scale.set(1 / camera.zoom, 1 / camera.zoom);
		if (this.getScreenPosition(Globals.cameras.uiCam).y >= FlxG.height / 2) {
			D.align.up(planetNameTooltip, this, 0, -25 * (1 / camera.zoom));
		} else {
			D.align.down(planetNameTooltip, this, 0, 25 * (1 / camera.zoom));
		}
		D.align.XAxis(planetNameTooltip, this);
		getMidpoint(midpoint);
	}

	override function draw() {
		super.draw();
		if (clouds.visible) {
			clouds.draw();
		}
		if (ringA.visible) {
			ringA.draw();
		}
		if (flags.visible) {
			flags.draw();
		}
		if (planetNameTooltip.visible) {
			planetNameTooltip.draw();
		}
	}
}
