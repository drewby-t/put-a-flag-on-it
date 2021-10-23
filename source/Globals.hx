package;

import SpaceBody.SpaceBodyData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRandom;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

class Globals {
	// Holds all the data for every space body you could land on (not the probe itself tho)
	public static var allSpaceBodies(get, null):Array<SpaceBodyData>;
	public static var numTotalLaunches(default, default):Int = 0;
	public static var random(default, default):FlxRandom = new FlxRandom();

	public static var bgLower:FlxGraphic;
	public static var bgUpper:FlxGraphic;

	public static var launchDataBySpaceBodyId(default, null):Map<Int, Array<LaunchData>> = new Map<Int, Array<LaunchData>>();
	public static var launchDataOrdered(default, null):Array<LaunchData> = new Array<LaunchData>();

	public static var cameras(default, null):Cameras = new Cameras();

	static function get_allSpaceBodies():Array<SpaceBodyData> {
		if (allSpaceBodies == null) {
			allSpaceBodies = Json.parse(Assets.getText(AssetPaths.sample_galaxy__json));
			for (i in 0...allSpaceBodies.length) {
				allSpaceBodies[i].id = i;
				allSpaceBodies[i].isProbe = false;
			}
		}
		return allSpaceBodies;
	}

	public static function addLaunchData(data:LaunchData) {
		var landingsForThisBody = launchDataBySpaceBodyId.get(data.bodyId);
		launchDataOrdered.push(data);
		if (landingsForThisBody == null) {
			launchDataBySpaceBodyId.set(data.bodyId, [data]);
			return;
		}
		landingsForThisBody.push(data);
	}
}

class Cameras {
	public var mainCam:FlxCamera;
	public var uiCam:FlxCamera;

	public function new() {}
}
