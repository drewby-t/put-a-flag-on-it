package ui;

import djFlixel.D;
import flixel.addons.ui.FlxClickArea;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUISprite;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxStringUtil;

class PlanetInfoBox extends FlxUIGroup {
	var bg:FlxUISprite;

	var titleText:FlxUIText;
	var messageText:FlxUIText;

	var planetNameInput:SimpleTextInput;

	var submitText:FlxUIText;

	var isSumbitted:Bool = false;

	public var onSubmit:String->Void;

	var lastText = "";

	override public function new() {
		super();
		bg = new FlxUISprite();
		bg.makeGraphic(400, 230, FlxColor.GRAY.getDarkened(0.88));
		FlxSpriteUtil.drawRect(bg, 1, 1, bg.frameWidth - 2, bg.frameHeight - 2, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.LIME});

		var t = new FlxText(0, 0, Std.int(bg.width * 0.7), "", 24);
		t.font = AssetPaths.Ubuntu_Medium__ttf;
		t.color = FlxColor.LIME;
		t.alignment = FlxTextAlign.CENTER;

		titleText = new FlxUIText(0, 0, bg.width * 0.9, "NEW PLANET CONQUERED!", 23);
		titleText.alignment = FlxTextAlign.CENTER;
		titleText.font = AssetPaths.Ubuntu_Bold__ttf;
		titleText.color = FlxColor.CYAN;
		D.align.XAxis(titleText, bg);
		D.align.YAxis(titleText, bg, "t", 16);

		messageText = new FlxUIText(0, 0, bg.width * 0.8, "Choose a name for your new planet:", 16);
		messageText.font = AssetPaths.Ubuntu_Bold__ttf;
		messageText.alignment = FlxTextAlign.CENTER;
		messageText.color = FlxColor.LIME;
		D.align.downCenter(messageText, titleText, 8);

		planetNameInput = new SimpleTextInput(t, FlxColor.GRAY.getDarkened(0.6), 5, 5);
		planetNameInput.maxLength = 18;

		D.align.XAxis(planetNameInput, bg);
		D.align.YAxis(planetNameInput, bg, 10);

		submitText = new FlxUIText(0, 0, bg.width * 0.9, "[ENTER] TO SUBMIT", 20);
		submitText.alignment = FlxTextAlign.CENTER;
		submitText.font = AssetPaths.Ubuntu_Bold__ttf;

		D.align.downCenter(submitText, planetNameInput, 10);

		add(bg);
		add(planetNameInput);
		add(messageText);
		add(submitText);
		add(titleText);
	}

	function trySubmit() {
		if (planetNameInput.textBox.text.length >= 0) {
			isSumbitted = true;
			if (onSubmit != null) {
				onSubmit(planetNameInput.textBox.text);
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.keys.justPressed.ENTER) {
			trySubmit();
		}
		if (planetNameInput.textBox.text.length <= 0) {
			submitText.alpha = 0.5;
		} else if (lastText == "") {
			submitText.alpha = 1.0;
		}

		lastText = planetNameInput.textBox.text;
	}
}
