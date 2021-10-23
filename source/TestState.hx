package;

import djFlixel.D;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUISprite;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import ui.LaunchLog;
import ui.PlanetInfoBox;

class TestState extends FlxState {
	var s:FlxUIList;

	override function create() {
		super.create();
		D.init();

		var box = new PlanetInfoBox();
		add(box);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}
