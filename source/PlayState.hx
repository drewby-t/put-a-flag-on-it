package;

import djFlixel.D;
import flixel.FlxState;
import flixel.addons.ui.Anchor;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.addons.ui.FlxUITooltip;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import js.html.MouseEvent;
import ui.AnglePointer;
import ui.LaunchLog;
import ui.PlanetInfoBox;

class PlayState extends FlxState {
	var probe:Probe;

	var probeDust:FlxTypedGroup<FlxSprite>;
	var probeDustTimer:FlxTimer;

	var mousePos:FlxPoint = FlxPoint.get();

	var spaceBodies:FlxTypedGroup<SpaceBody>;
	var spaceBodiesById:Map<Int, SpaceBody>;

	var landingFlags:FlxTypedGroup<FlxSprite>;

	var launchLog:LaunchLog;
	var angleText:FlxText;

	var thrustTimer:FlxTimer;

	var launchBearing:AnglePointer;
	var currentBearing:AnglePointer;
	var accBearing:AnglePointer;

	var bgLower:FlxSprite;
	var bgUpper:FlxSprite;

	var planetInfoBox:PlanetInfoBox;

	var pingTime = 0.6;
	var pingTimer:FlxTimer;

	var infoTextGroup:FlxSpriteGroup;

	override public function create() {
		super.create();
		D.init();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			FlxG.sound.playMusic(AssetPaths.looperman_l_3792505_0268925_cloudscape_x_part_1_x_ramont1no__ogg, 0.2, true);
		}

		if (Globals.drone == null || !Globals.drone.playing) {
			Globals.drone = FlxG.sound.play(AssetPaths.assets_sounds_drone__ogg, 0.3, true);
			Globals.drone.persist = true;
		}

		Globals.cameras.mainCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		Globals.cameras.mainCam.bgColor = FlxColor.GRAY.getDarkened(0.9);
		Globals.cameras.mainCam.useBgAlphaBlending = true;
		// Globals.cameras.mainCam.pixelPerfectRender = true;
		Globals.cameras.mainCam.antialiasing = true;

		Globals.cameras.uiCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		// Globals.cameras.uiCam.pixelPerfectRender = true;
		Globals.cameras.uiCam.bgColor = FlxColor.TRANSPARENT;
		Globals.cameras.uiCam.useBgAlphaBlending = true;
		Globals.cameras.uiCam.antialiasing = true;

		FlxG.cameras.reset(Globals.cameras.mainCam);
		FlxG.cameras.add(Globals.cameras.uiCam, false);

		spaceBodies = new FlxTypedGroup<SpaceBody>();
		spaceBodiesById = new Map<Int, SpaceBody>();
		for (bodyData in Globals.allSpaceBodies) {
			var b = new SpaceBody(bodyData);
			spaceBodies.add(b);
			spaceBodiesById.set(b.data.id, b);
		}

		landingFlags = new FlxTypedGroup<FlxSprite>();
		for (spaceBodyId in Globals.launchDataBySpaceBodyId.keys()) {
			var launches:Array<LaunchData> = Globals.launchDataBySpaceBodyId.get(spaceBodyId);
			var body:SpaceBody = spaceBodiesById.get(spaceBodyId);
			if (launches == null || body == null) {
				continue; // happens when spaceBodyId is -1 because that's the marker for "recalled early"
			}
			for (launch in launches) {
				var flag = new FlxSprite();
				flag.width = flag.height;
				flag.loadGraphic(AssetPaths.flag__png, true, 32, 32);
				flag.animation.add("wave", [0, 1, 2, 3], 8, true);
				flag.animation.play("wave");
				var flagPlacer = FlxVector.get(1, 1);
				flagPlacer.degrees = launch.landSiteAngle + 180;
				flagPlacer.length = body.radius + flag.height * 0.25;
				flag.angle = flagPlacer.degrees + 90;
				flag.x = body.midpoint.x + flagPlacer.x - flag.width / 2;
				flag.y = body.midpoint.y + flagPlacer.y - flag.height / 2;
				// landingFlags.add(flag);
				body.flags.add(flag);
				flagPlacer.put();
			}
		}
		probe = new Probe();
		probe.screenCenter();

		makeBg();

		add(spaceBodies);
		add(landingFlags);

		FlxG.worldBounds.left = -10000;
		FlxG.worldBounds.top = -10000;
		FlxG.worldBounds.right = 10000;
		FlxG.worldBounds.bottom = 10000;

		probeDust = new FlxTypedGroup<FlxSprite>();
		add(probeDust);
		add(probe);

		FlxG.camera.follow(probe, FlxCameraFollowStyle.TOPDOWN_TIGHT);
		FlxG.camera.zoom = 1.0;

		FlxG.timeScale = 1.0;

		// UI
		var launchesDesc = Globals.launchDataOrdered.copy();
		launchesDesc.reverse();
		launchLog = new LaunchLog(launchesDesc);
		launchLog.cameras = [Globals.cameras.uiCam];
		launchLog.setPosition(10, 10);
		add(launchLog);

		launchBearing = new AnglePointer(40, FlxColor.LIME, 3, FlxColor.MAGENTA, 4);
		launchBearing.cameras = [Globals.cameras.uiCam];
		launchBearing.x = FlxG.width - launchBearing.width - 10;
		launchBearing.y = 10;
		add(launchBearing);

		currentBearing = new AnglePointer(40, FlxColor.LIME, 3, FlxColor.MAGENTA, 4);
		currentBearing.cameras = [Globals.cameras.uiCam];
		currentBearing.x = launchBearing.x - currentBearing.width - 10;
		currentBearing.y = 10;
		currentBearing.alpha = 0.4;
		add(currentBearing);

		accBearing = new AnglePointer(30, FlxColor.LIME, 3, FlxColor.MAGENTA, 4);
		accBearing.cameras = [Globals.cameras.uiCam];
		accBearing.x = currentBearing.x - accBearing.width - 10;
		accBearing.y = 10;
		accBearing.alpha = 0.4;
		add(accBearing);

		// DEBUG TEXT
		infoTextGroup = new FlxSpriteGroup();
		var tSize = 15;
		var numPlanetsText = new FlxText(10, FlxG.height - 30, 0, 'Planets Conquered:  ${getNumPlanetsConquered()}/${Globals.allSpaceBodies.length)}', 23);
		numPlanetsText.font = AssetPaths.Ubuntu_Bold__ttf;
		numPlanetsText.color = FlxColor.LIME.getLightened(0.75);
		var shootText = new FlxText(10, FlxG.height - 30, 0, "[Shift+Click] to fire probe", tSize);
		shootText.font = AssetPaths.Ubuntu_Bold__ttf;
		var shootText2 = new FlxText(10, FlxG.height - 30, 0, "[Ctrl+Shift+Click] for more powerful shot", tSize);
		shootText2.font = AssetPaths.Ubuntu_Bold__ttf;
		var zoomText = new FlxText(10, FlxG.height - 30, 0, "[Scroll] or [Z/X] to zoom", tSize);
		zoomText.font = AssetPaths.Ubuntu_Bold__ttf;
		var resetText = new FlxText(10, FlxG.height - 30, 0, "[R] to recall probe", tSize);
		resetText.font = AssetPaths.Ubuntu_Bold__ttf;
		var logText = new FlxText(10, resetText.y - 30, 0, "[L] show/hide launch log", tSize);
		logText.font = AssetPaths.Ubuntu_Bold__ttf;
		var logText2 = new FlxText(10, resetText.y - 30, 0, "[K] to show/hide this info", tSize);
		logText2.font = AssetPaths.Ubuntu_Bold__ttf;
		D.align.inVLine(0, 0, 200, [numPlanetsText, shootText, shootText2, zoomText, resetText, logText, logText2], "c", 4);
		infoTextGroup.cameras = [Globals.cameras.uiCam];

		infoTextGroup.add(numPlanetsText);
		infoTextGroup.add(resetText);
		infoTextGroup.add(logText);
		infoTextGroup.add(logText2);
		infoTextGroup.add(zoomText);
		infoTextGroup.add(shootText);
		infoTextGroup.add(shootText2);
		infoTextGroup.y = FlxG.height - 198;
		infoTextGroup.x = 10;
		add(infoTextGroup);
	}

	function getNumPlanetsConquered():Int {
		var num = 0;
		for (k in Globals.launchDataBySpaceBodyId.keys()) {
			if (k < 0) {
				continue;
			}
			num++;
		}
		return num;
	}

	function makeBg() {
		bgLower = new FlxSprite();
		bgUpper = new FlxSprite();
		if (Globals.bgLower == null || Globals.bgLower == null) {
			var base = new FlxSprite().loadGraphic(AssetPaths.backdrop__png);
			var baseUpper = new FlxSprite().loadGraphic(AssetPaths.backdrop_dust_parallax__png);
			var tiles = 5;
			bgLower.makeGraphic(base.frameWidth * tiles, base.frameHeight * tiles, FlxColor.TRANSPARENT, true);
			bgUpper.makeGraphic(baseUpper.frameWidth * tiles, baseUpper.frameHeight * tiles, FlxColor.TRANSPARENT, true);

			for (row in 0...tiles) {
				for (col in 0...tiles) {
					bgLower.stamp(base, row * base.frameHeight, col * base.frameWidth);
					bgUpper.stamp(baseUpper, row * baseUpper.frameHeight, col * baseUpper.frameWidth);
				}
			}
			Globals.bgLower = FlxGraphic.fromBitmapData(bgLower.pixels.clone(), true);
			Globals.bgUpper = FlxGraphic.fromBitmapData(bgUpper.pixels.clone(), true);
			Globals.bgLower.persist = true;
			Globals.bgUpper.persist = true;
		} else {
			bgLower.loadGraphic(Globals.bgLower);
			bgUpper.loadGraphic(Globals.bgUpper);
		}

		add(bgLower);
		D.align.XAxis(bgLower, probe);
		D.align.YAxis(bgLower, probe);
		bgLower.scale.set(0.9, 0.9);
		bgLower.angularVelocity = 0.12;
		bgLower.scrollFactor.set(0.4, 0.4);

		add(bgUpper);
		D.align.XAxis(bgUpper, probe);
		D.align.YAxis(bgUpper, probe);
		bgUpper.scale.set(1, 1);
		bgUpper.angularVelocity = -0.25;
		bgUpper.alpha = 0.9;
		bgUpper.scrollFactor.set(0.75, 0.75);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		FlxG.mouse.getWorldPosition(FlxG.camera, mousePos);

		if (FlxG.keys.justPressed.L && planetInfoBox == null) {
			launchLog.visible = !launchLog.visible;
		}
		if (FlxG.keys.justPressed.K && planetInfoBox == null) {
			infoTextGroup.visible = !infoTextGroup.visible;
		}
		if (FlxG.keys.justPressed.F) {
			// FlxG.fullscreen = !FlxG.fullscreen;
		}
		if (pingTimer != null && pingTimer.active) {
			var currentAccel = FlxVector.get(probe.velocity.x, probe.velocity.y);
			pingTimer.time = pingTime * (1 / (currentAccel.length / (probe.speed * 0.75)));
			currentAccel.put();
		}

		if (FlxG.keys.justPressed.R && probe.hasFired && planetInfoBox == null) {
			if (!probe.hasLanded) {
				Globals.addLaunchData({
					bodyId: -1,
					landSiteAngle: -1,
					originalBearing: probe.originalBearing,
					launchNumber: Globals.numTotalLaunches
				});
			}
			FlxG.resetState();
		}

		// tooltip with name
		if (FlxG.mouse.justMoved && !probe.hasLanded) {
			for (body in spaceBodies) {
				var dir = FlxVector.get(mousePos.x - body.midpoint.x, mousePos.y - body.midpoint.y);
				if (dir.length <= body.radius) {
					body.planetNameTooltip.visible = true;
				} else {
					body.planetNameTooltip.visible = false;
				}
			}
		}

		if (FlxG.mouse.justMoved && !probe.hasFired) {
			var shootDir = FlxVector.get(mousePos.x - probe.midpoint.x, mousePos.y - probe.midpoint.y);
			launchBearing.pointerAngle = shootDir.degrees;
			probe.currentBearing.set(shootDir.x, shootDir.y);
			shootDir.put();
		}
		if (probe.hasFired && !probe.hasLanded) {
			launchBearing.alpha = 0.7;
			currentBearing.alpha = 1.0;
			accBearing.alpha = 1.0;
			var currentDir = FlxVector.get(probe.velocity.x, probe.velocity.y);
			probe.currentBearing.set(currentDir.x, currentDir.y);
			// var currentAccel = FlxVector.get(probe.acceleration.x - probe.thrust.x, probe.acceleration.y - probe.thrust.y); //use this version to only show gravity, instea of gravity+thrust
			var currentAccel = FlxVector.get(probe.acceleration.x, probe.acceleration.y);
			currentBearing.pointerAngle = FlxMath.lerp(currentBearing.pointerAngle, currentDir.degrees, 0.2);
			accBearing.pointerAngle = FlxMath.lerp(accBearing.pointerAngle, currentAccel.degrees, 0.2);
			currentDir.put();
			currentAccel.put();
		}

		var zoomStep = 0.04;
		var minZoom = 0.3 + zoomStep * 1;
		var maxZoom = 1.4;
		if (FlxG.mouse.wheel != 0 && planetInfoBox == null) {
			Globals.cameras.mainCam.zoom += FlxMath.signOf(FlxG.mouse.wheel) * zoomStep;
			if (Globals.cameras.mainCam.zoom > maxZoom) {
				Globals.cameras.mainCam.zoom = maxZoom;
			}
			if (Globals.cameras.mainCam.zoom < minZoom) {
				Globals.cameras.mainCam.zoom = minZoom;
			}
		}
		if (FlxG.keys.pressed.Z && planetInfoBox == null) {
			Globals.cameras.mainCam.zoom += FlxMath.signOf(-1) * zoomStep;
			if (Globals.cameras.mainCam.zoom > maxZoom) {
				Globals.cameras.mainCam.zoom = maxZoom;
			}
			if (Globals.cameras.mainCam.zoom < minZoom) {
				Globals.cameras.mainCam.zoom = minZoom;
			}
		}
		if (FlxG.keys.pressed.X && planetInfoBox == null) {
			Globals.cameras.mainCam.zoom += FlxMath.signOf(1) * zoomStep;
			if (Globals.cameras.mainCam.zoom > maxZoom) {
				Globals.cameras.mainCam.zoom = maxZoom;
			}
			if (Globals.cameras.mainCam.zoom < minZoom) {
				Globals.cameras.mainCam.zoom = minZoom;
			}
		}

		if (FlxG.mouse.justPressed && FlxG.keys.pressed.SHIFT) {
			fireProbe(FlxG.keys.pressed.CONTROL);
		}

		if (probe.hasFired && !probe.hasLanded) {
			probe.acceleration.set(0, 0); // reset accelleration (gravity)
			updateGravityOnProbe();
			FlxG.overlap(probe, spaceBodies, null, checkRealOverlap);
		}
	}

	inline static function sqr(num:Float)
		return num * num;

	function checkRealOverlap(p:SpaceBody, b:SpaceBody):Bool {
		trace(p.midpoint, b.midpoint);
		var bodyToProbe = FlxVector.get(p.midpoint.x - b.midpoint.x, p.midpoint.y - b.midpoint.y);
		var haveCollided = bodyToProbe.length <= p.radius + b.radius;

		if (haveCollided) {
			FlxG.sound.play(Random.fromArray([AssetPaths.hit1__ogg, AssetPaths.hit2__ogg]), 0.9);
			probe.mostRecentlyCollidedBody = b;
			var probeVelocity = FlxVector.get(p.velocity.x, p.velocity.y);
			var normal = bodyToProbe.clone().normalize();
			// v2 := v - 2 * dot(v, n) * n
			normal.length *= 2 * probeVelocity.dotProduct(normal);
			probeVelocity.subtractPoint(normal);
			bodyToProbe.length = p.radius + b.radius;
			p.x = b.midpoint.x + bodyToProbe.x - probe.width / 2;
			p.y = b.midpoint.y + bodyToProbe.y - probe.height / 2;

			probeVelocity.length *= 0.45;
			p.velocity.x = probeVelocity.x;
			p.velocity.y = probeVelocity.y;

			probe.hasCollided = true;
			pingTimer.cancel();

			if (Math.abs(p.x - p.last.x) < 0.1 && Math.abs(p.x - p.last.x) < 0.1) {
				landOn(b, normal);
			}

			probeVelocity.put();
			normal.put();
		}

		bodyToProbe.put();
		return haveCollided;
	}

	private function landOn(body:SpaceBody, normal:FlxVector) {
		FlxG.camera.flash();
		probe.hasLanded = true;
		probe.acceleration.set(0, 0);
		probe.velocity.set(0, 0);
		var isFirstLanding = !Globals.launchDataBySpaceBodyId.exists(body.data.id);
		Globals.addLaunchData({
			bodyId: body.data.id,
			landSiteAngle: normal.degrees,
			originalBearing: probe.originalBearing,
			launchNumber: Globals.numTotalLaunches
		});
		if (isFirstLanding) {
			FlxTween.tween(Globals.cameras.mainCam.targetOffset, {y: -285}, 1, {ease: FlxEase.quadInOut});
			FlxTween.tween(Globals.cameras.mainCam, {zoom: 1.2}, 1, {ease: FlxEase.quadInOut});
			planetInfoBox = new PlanetInfoBox();
			planetInfoBox.cameras = [Globals.cameras.uiCam];
			D.align.screen(planetInfoBox);
			planetInfoBox.y -= 50;
			add(planetInfoBox);
			planetInfoBox.onSubmit = (name:String) -> {
				body.data.name = name;
				FlxTween.tween(planetInfoBox, {alpha: 0, y: planetInfoBox.y - 60}, 1, {
					ease: FlxEase.backIn,
					onComplete: (_) -> {
						new FlxTimer().start(0.6, (_) -> {
							FlxG.resetState();
						});
					}
				});
				FlxG.camera.flash();
			}
		}
	}

	function updateGravityOnProbe() {
		probe.acceleration.x += probe.thrust.x;
		probe.acceleration.y += probe.thrust.y;

		if (thrustTimer != null && thrustTimer.active && thrustTimer.timeLeft >= thrustTimer.time * 0.84) {
			return;
		}
		for (body in spaceBodies) {
			var probeToBody = FlxVector.get(body.midpoint.x - probe.midpoint.x, body.midpoint.y - probe.midpoint.y);
			if (probeToBody.length > body.radius * 9) {
				continue;
			}
			var gravityRatio = 1 / Math.pow(probeToBody.length / 1.1, 2);
			probeToBody.normalize();
			var multiplier = 9000 * 10;
			probe.acceleration.x += probeToBody.x * gravityRatio * body.radius * multiplier; // TODO: refactor radius to mass somehow?
			probe.acceleration.y += probeToBody.y * gravityRatio * body.radius * multiplier; // TODO: refactor radius to mass somehow?
		}
	}

	public function fireProbe(powerShot:Bool = false) {
		if (probe.hasFired) {
			return;
		}
		Globals.numTotalLaunches++;
		FlxG.sound.play(AssetPaths.launch__ogg);
		var shootDir = FlxVector.get(mousePos.x - probe.midpoint.x, mousePos.y - probe.midpoint.y);
		shootDir.normalize();
		probe.originalBearing = shootDir.degrees;

		probe.thrust.x = shootDir.x * probe.speed * (powerShot ? 1.33 : 1);
		probe.thrust.y = shootDir.y * probe.speed * (powerShot ? 1.33 : 1);
		probe.hasFired = true;

		thrustTimer = new FlxTimer().start(1, (_) -> {
			probe.thrust.set(0, 0); // TODO: refactor the direct accelleration for launch to a thrust varible to include in frame-by frame accel checking
			trace("done accellerating, velocity at: ", probe.velocity);
		});

		shootDir.put();

		startProbeNoise(pingTime);

		probeDustTimer = new FlxTimer().start(0.1, (_) -> {
			var d = new FlxSprite();
			d.makeGraphic(8, 8, FlxColor.GRAY);
			d.angularVelocity = Random.float(-6, 6);
			probeDust.add(d);
			D.align.XAxis(d, probe);
			D.align.YAxis(d, probe);
			FlxTween.tween(d, {alpha: 0.5, 'scale.x': 0, 'scale.y': 0}, 6);
		}, 0);
	}

	function startProbeNoise(waitTime:Float) {
		pingTimer = new FlxTimer().start(waitTime, (_) -> {
			FlxG.sound.play(AssetPaths.ping__ogg);
			var currentAccel = FlxVector.get(probe.velocity.x, probe.velocity.y);
			startProbeNoise(pingTime * (1 / (currentAccel.length / probe.speed)));
			currentAccel.put();
		});
	}
}
