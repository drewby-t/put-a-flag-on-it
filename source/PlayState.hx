package;

import djFlixel.D;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import js.html.MouseEvent;
import ui.AnglePointer;
import ui.LaunchLog;

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

	override public function create() {
		super.create();
		D.init();

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
				flag.animation.add("wave", [0, 1, 2, 3], 5, true);
				flag.animation.play("wave");
				var flagPlacer = FlxVector.get(1, 1);
				flagPlacer.degrees = launch.landSiteAngle + 180;
				flagPlacer.length = body.radius + flag.height * 0.25;
				flag.angle = flagPlacer.degrees + 90;
				flag.x = body.midpoint.x + flagPlacer.x - flag.width / 2;
				flag.y = body.midpoint.y + flagPlacer.y - flag.height / 2;
				landingFlags.add(flag);
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
		var resetText = new FlxText(10, FlxG.height - 30, 0, "[R] to recall Probe", 17);
		add(resetText);
		resetText.cameras = [Globals.cameras.uiCam];

		var logText = new FlxText(10, resetText.y - 30, 0, "[L] to toggle launch log", 17);
		add(logText);
		logText.cameras = [Globals.cameras.uiCam];

		angleText = new FlxText(10, FlxG.height - 80, 0, "", 17);
		// add(angleText);
		angleText.cameras = [Globals.cameras.uiCam];
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

		if (FlxG.keys.justPressed.L) {
			launchLog.visible = !launchLog.visible;
		}
		if (FlxG.keys.justPressed.F) {
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (FlxG.keys.justPressed.R && probe.hasFired) {
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

		if (FlxG.mouse.justMoved && !probe.hasFired) {
			var shootDir = FlxVector.get(mousePos.x - probe.midpoint.x, mousePos.y - probe.midpoint.y);
			angleText.text = Std.string(Utils.normalizeAngle(-shootDir.degrees));
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
		var minZoom = 0.3;
		var maxZoom = 1.4;
		if (FlxG.mouse.wheel != 0) {
			Globals.cameras.mainCam.zoom += FlxMath.signOf(FlxG.mouse.wheel) * zoomStep;
			if (Globals.cameras.mainCam.zoom > maxZoom) {
				Globals.cameras.mainCam.zoom = maxZoom;
			}
			if (Globals.cameras.mainCam.zoom < minZoom) {
				Globals.cameras.mainCam.zoom = minZoom;
			}
		}

		FlxG.mouse.getWorldPosition(FlxG.camera, mousePos);

		if (FlxG.mouse.justPressed) {
			fireProbe();

			var s = new FlxSprite().makeGraphic(4, 4, FlxColor.RED);
			add(s);
			s.x = mousePos.x;
			s.y = mousePos.y;
			trace(s.x, s.y);
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
		Globals.addLaunchData({
			bodyId: body.data.id,
			landSiteAngle: normal.degrees,
			originalBearing: probe.originalBearing,
			launchNumber: Globals.numTotalLaunches
		});
	}

	function updateGravityOnProbe() {
		probe.acceleration.x += probe.thrust.x;
		probe.acceleration.y += probe.thrust.y;

		if (thrustTimer != null && thrustTimer.active && thrustTimer.timeLeft >= thrustTimer.time * 0.84) {
			return;
		}
		for (body in spaceBodies) {
			var probeToBody = FlxVector.get(body.midpoint.x - probe.midpoint.x, body.midpoint.y - probe.midpoint.y);
			if (probeToBody.length > body.radius * 8) {
				continue;
			}
			var gravityRatio = 1 / Math.pow(probeToBody.length / 1.1, 2);
			probeToBody.normalize();
			var multiplier = 9000 * 10.5;
			probe.acceleration.x += probeToBody.x * gravityRatio * body.radius * multiplier; // TODO: refactor radius to mass somehow?
			probe.acceleration.y += probeToBody.y * gravityRatio * body.radius * multiplier; // TODO: refactor radius to mass somehow?
		}
	}

	public function fireProbe() {
		if (probe.hasFired) {
			return;
		}
		Globals.numTotalLaunches++;
		var shootDir = FlxVector.get(mousePos.x - probe.midpoint.x, mousePos.y - probe.midpoint.y);
		shootDir.normalize();
		probe.originalBearing = shootDir.degrees;

		probe.thrust.x = shootDir.x * probe.speed;
		probe.thrust.y = shootDir.y * probe.speed;
		probe.hasFired = true;

		thrustTimer = new FlxTimer().start(1, (_) -> {
			probe.thrust.set(0, 0); // TODO: refactor the direct accelleration for launch to a thrust varible to include in frame-by frame accel checking
			trace("done accellerating, velocity at: ", probe.velocity);
		});

		shootDir.put();

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
}
