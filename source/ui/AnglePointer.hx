package ui;

import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUISprite;

class AnglePointer extends FlxUIGroup {
	var radius:Int;
	var outlineColor:FlxColor;
	var outlineThickness:Float;
	var pointerColor:FlxColor;
	var pointerThickness:Float;

	var pointer:FlxUISprite;
	var circleOutline:FlxUISprite;

	public var pointerAngle(default, set):Float;

	override public function new(radius:Int, outlineColor:FlxColor, outlineThickness:Float, pointerColor:FlxColor, pointerThickness:Float) {
		super();
		this.radius = radius;
		this.outlineColor = outlineColor;
		this.outlineThickness = outlineThickness;
		this.pointerColor = pointerColor;
		this.pointerThickness = pointerThickness;

		var size = radius * 2 + 4;

		circleOutline = new FlxUISprite();
		circleOutline.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		pointer = new FlxUISprite();
		pointer.makeGraphic(size, size, FlxColor.TRANSPARENT, true);

		FlxSpriteUtil.drawCircle(circleOutline, -1, -1, radius, FlxColor.TRANSPARENT, {thickness: outlineThickness, color: outlineColor}, {smoothing: true});
		FlxSpriteUtil.drawLine(pointer, pointer.width / 2, pointer.height / 2, pointer.width / 2 + radius, pointer.height / 2,
			{thickness: pointerThickness, color: pointerColor}, {smoothing: true});

		add(pointer);
		add(circleOutline);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	function set_pointerAngle(value:Float):Float {
		pointerAngle = value;
		pointer.angle = value;
		return pointerAngle;
	}
}
