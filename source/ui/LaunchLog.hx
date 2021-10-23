package ui;

import djFlixel.D;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUISprite;
import flixel.addons.ui.FlxUIText;

class LaunchLog extends FlxUIGroup {
	var launchData:Array<LaunchData>;

	var lineList:FlxUIList;
	var lines:Array<LogLine> = [];

	override public function new(launchData:Array<LaunchData>) {
		super();
		this.launchData = launchData;

		var header = new LogLine(["Launch No.", "Bearing"], 14, FlxColor.GRAY.getDarkened(0.76), null);
		add(header);

		for (d in 0...launchData.length) {
			var data = launchData[d];
			var line = new LogLine([
				Utils.intStringWithMinLength(data.launchNumber, 3),
				Utils.intStringWithMinLength(Math.round(Utils.normalizeAngle(-data.originalBearing)), 3) + "°"
			], 12, FlxColor.GRAY.getDarkened(0.35), header);
			lines.push(line);
		}

		lineList = new FlxUIList(0, header.height + 8, cast lines, FlxG.width, 200, "", FlxUIList.STACK_VERTICAL, 5);
		lineList.prevButtonOffset.y = lineList.height;
		// lineList.nextButtonOffset.x += 40;
		lineList.scrollIndex = 0; // refeshingList() required
		add(lineList);
	}
}

class LogLine extends FlxUIGroup {
	var messages:Array<String>;
	var bgColor:FlxColor = FlxColor.GRAY;

	public var items:Array<FlxSprite>;

	override public function new(messages:Array<String>, textSize:Int, bgColor:FlxColor, headerLine:LogLine) {
		super();
		this.messages = messages;
		this.bgColor = bgColor;

		items = [];
		for (m in 0...messages.length) {
			var message = messages[m];
			var d = new DataItemBox(message, FlxColor.WHITE, bgColor, textSize, headerLine != null ? Std.int(headerLine.items[m].width) : 0);
			items.push(d);
		}

		D.align.inLine(0, 0, 0, items, "l", 8);

		for (i in items) {
			add(i);
		}
	}
}

class DataItemBox extends FlxUIGroup {
	var message:String;
	var bgColor:FlxColor;
	var textColor:FlxColor;

	var bg:FlxUISprite;

	var text:FlxUIText;

	var textSize:Int = 16;
	var xPadding = 4;
	var yPadding = 4;

	override public function new(message:String, textColor:FlxColor, bgColor:FlxColor, textSize:Int, fieldWidth:Int) {
		super();
		this.message = message;
		this.textColor = textColor;
		this.bgColor = bgColor;
		this.textSize = textSize;

		text = new FlxUIText(0, 0, fieldWidth - xPadding * 2, message, textSize);
		text.font = AssetPaths.Ubuntu_Bold__ttf;
		text.alignment = FlxTextAlign.CENTER;
		text.color = textColor;

		bg = new FlxUISprite();

		bg.makeGraphic(Std.int(text.width) + xPadding * 2, Std.int(text.height) + yPadding * 2, bgColor);

		D.align.XAxis(text, bg);
		D.align.YAxis(text, bg);
		add(bg);
		add(text);
	}
}
