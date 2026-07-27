const Math = {}

const function evaluateCubicBezier(t: number, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3): Vector3
	return (1 - t)^3 * p0
		+ 3 * (1 - t)^2 * t * p1
		+ 3 * (1 - t) * t^2 * p2
		+ t^3 * p3
end

function Math.cubicBezier(t: number, start: Vector3, finish: Vector3): Vector3
	const delta = finish - start
	const distance = delta.Magnitude

	if distance < 1e-4 then
		return start
	end

	const direction = delta.Unit
	local flatDir = Vector3.new(direction.X, 0, direction.Z)
	if flatDir.Magnitude < 1e-4 then
		flatDir = Vector3.new(1, 0, 0)
	else
		flatDir = flatDir.Unit
	end

	const right = flatDir:Cross(Vector3.yAxis).Unit
	const up = Vector3.yAxis

	const arcHeight = math.max(distance * 0.55, 2.5)
	const swing = math.max(distance * 0.42, 2)
	const loop = math.max(distance * 0.32, 1.5)

	-- Faerie waypoint: rise, sweep wide, then dive toward the finish.
	const waypoint = start + delta * 0.38 + up * arcHeight + right * swing

	local segmentT: number
	local p0: Vector3
	local p3: Vector3

	if t <= 0.5 then
		segmentT = t * 2
		p0 = start
		p3 = waypoint
	else
		segmentT = (t - 0.5) * 2
		p0 = waypoint
		p3 = finish
	end

	const segDelta = p3 - p0
	const segDistance = segDelta.Magnitude
	if segDistance < 1e-4 then
		return p0
	end

	const segDir = segDelta.Unit
	local p1: Vector3
	local p2: Vector3

	if t <= 0.5 then
		p1 = p0 + segDir * (segDistance * 0.35) + up * (arcHeight * 0.65) + right * loop
		p2 = p3 - segDir * (segDistance * 0.18) + up * (arcHeight * 0.35) - right * (loop * 0.45)
	else
		p1 = p0 + segDir * (segDistance * 0.22) - right * (loop * 0.55) + up * (arcHeight * 0.2)
		p2 = p3 - segDir * (segDistance * 0.38) - right * (swing * 0.35) + up * (arcHeight * 0.12)
	end

	local position = evaluateCubicBezier(segmentT, p0, p1, p2, p3)

	-- Soft flutter while gliding; fades out near the landing.
	const flutter = math.sin(t * math.pi * 3) * loop * 0.18 * (1 - t)
	return position + right * flutter
end

function Math.spaceshipHover(elapsed: number, anchor: Vector3, lookTarget: Vector3): CFrame
	const phase = anchor.X * 0.17 + anchor.Z * 0.23

	const bobY = math.sin((elapsed + phase) * 1.6) * 0.22
	const driftX = math.sin((elapsed + phase) * 0.85) * 0.12
	const driftZ = math.cos((elapsed + phase) * 1.05) * 0.12
	const microBob = math.sin((elapsed + phase) * 2.4) * 0.05

	const hoverPos = anchor + Vector3.new(driftX, bobY + microBob, driftZ)

	local baseCF = CFrame.lookAt(hoverPos, lookTarget)
	const pitch = math.sin((elapsed + phase) * 1.25) * math.rad(5)
	const roll = math.cos((elapsed + phase) * 0.95) * math.rad(7)
	const yaw = math.sin((elapsed + phase) * 0.55) * math.rad(2.5)

	return baseCF * CFrame.Angles(pitch, yaw, roll)
end

function Math.float(elapsed: number, anchor: Vector3, lookTarget: Vector3): CFrame
	const phase = anchor.X * 0.11 + anchor.Y * 0.07 + anchor.Z * 0.19

	const bobY = math.sin((elapsed + phase) * 1.1) * 0.18
	const swayX = math.sin((elapsed + phase) * 0.65) * 0.06
	const swayZ = math.cos((elapsed + phase) * 0.75) * 0.06

	const floatPos = anchor + Vector3.new(swayX, bobY, swayZ)

	local baseCF = CFrame.lookAt(floatPos, lookTarget)
	const tilt = math.sin((elapsed + phase) * 0.8) * math.rad(2)

	return baseCF * CFrame.Angles(tilt * 0.35, 0, tilt)
end

return Math