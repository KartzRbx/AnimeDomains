--!strict
-- Behavior: reads Front pixels via AssetService/EditableImage and classifies
-- Primary = dominant strong color | Secondary = darker tone | Tertiary = black/white

const AssetService = game:GetService("AssetService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)

const PaletteLib = {}

export type CardPalette = {
	Primary: Color3,
	Secondary: Color3,
	Tertiary: Color3,
	Accent: Color3,
	Sequence: ColorSequence,
	Colors: { Color3 },
}

export type ImageUri = string
export type PaletteCache = { [ImageUri]: CardPalette }

const FALLBACK_PRIMARY = Color3.fromRGB(255, 215, 120)
const FALLBACK_SECONDARY = Color3.fromRGB(180, 120, 40)
const FALLBACK_TERTIARY = Color3.fromRGB(20, 20, 24)

-- Strong palette anchors (typical card-art highlights)
const STRONG_ANCHORS: { Color3 } = {
	Color3.fromRGB(255, 48, 48), -- red
	Color3.fromRGB(255, 140, 32), -- orange
	Color3.fromRGB(255, 214, 48), -- yellow
	Color3.fromRGB(72, 220, 96), -- green
	Color3.fromRGB(48, 210, 255), -- cyan
	Color3.fromRGB(56, 112, 255), -- blue
	Color3.fromRGB(168, 72, 255), -- purple
	Color3.fromRGB(255, 72, 168), -- pink
}

const MAX_SAMPLE_PIXELS = 2800
const MIN_ALPHA = 40
const MIN_SATURATION = 0.28
const MIN_VALUE = 0.18
const NEAR_WHITE_V = 0.92
const NEAR_BLACK_V = 0.12
const NEAR_WHITE_S = 0.18

const cache: PaletteCache = {}

const function buildPalette(primary: Color3, secondary: Color3, tertiary: Color3): CardPalette
	return {
		Primary = primary,
		Secondary = secondary,
		Tertiary = tertiary,
		Accent = tertiary,
		Sequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary),
			ColorSequenceKeypoint.new(0.55, secondary),
			ColorSequenceKeypoint.new(1, tertiary),
		}),
		Colors = { primary, secondary, tertiary },
	}
end

const function fallbackPalette(): CardPalette
	return buildPalette(FALLBACK_PRIMARY, FALLBACK_SECONDARY, FALLBACK_TERTIARY)
end

const function colorDistanceSq(a: Color3, b: Color3): number
	local dr = a.R - b.R
	local dg = a.G - b.G
	local db = a.B - b.B
	return dr * dr + dg * dg + db * db
end

const function nearestAnchorIndex(color: Color3): (number, number)
	local bestIndex = 1
	local bestDist = math.huge
	for i, anchor in STRONG_ANCHORS do
		local dist = colorDistanceSq(color, anchor)
		if dist < bestDist then
			bestDist = dist
			bestIndex = i
		end
	end
	return bestIndex, bestDist
end

const function luminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

const function darkerTone(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

const function getBackgroundCanvas(root: Instance): CanvasGroup?
	local named = root:FindFirstChild("Background_2")
	if named and named:IsA("CanvasGroup") then
		return named
	end

	for _, child in root:GetChildren() do
		if child:IsA("CanvasGroup") and child.Name == "Background" then
			return child
		end
	end

	return nil
end

function PaletteLib.GetBackgroundCanvas(card: CardsServiceType.TemplateCard): CanvasGroup?
	return getBackgroundCanvas(card.Card)
end

const function analyzePixels(pixels: buffer, width: number, height: number): CardPalette
	local total = width * height
	local step = math.max(1, math.floor(total / MAX_SAMPLE_PIXELS))

	local bucketWeight: { number } = table.create(#STRONG_ANCHORS, 0)
	local bucketR: { number } = table.create(#STRONG_ANCHORS, 0)
	local bucketG: { number } = table.create(#STRONG_ANCHORS, 0)
	local bucketB: { number } = table.create(#STRONG_ANCHORS, 0)

	local whiteWeight = 0
	local blackWeight = 0
	local sampled = 0

	for i = 0, total - 1, step do
		local offset = i * 4
		local a = buffer.readu8(pixels, offset + 3)
		if a < MIN_ALPHA then
			continue
		end

		local r = buffer.readu8(pixels, offset)
		local g = buffer.readu8(pixels, offset + 1)
		local b = buffer.readu8(pixels, offset + 2)
		local color = Color3.fromRGB(r, g, b)
		local h, s, v = color:ToHSV()
		sampled += 1

		-- Neutrals → tertiary candidates (black / white)
		if v >= NEAR_WHITE_V and s <= NEAR_WHITE_S then
			whiteWeight += 1 + v
			continue
		end
		if v <= NEAR_BLACK_V then
			blackWeight += 1 + (1 - v)
			continue
		end

		-- Only saturated / strong colors enter the primary race
		if s < MIN_SATURATION or v < MIN_VALUE then
			continue
		end

		local anchorIndex, distSq = nearestAnchorIndex(color)
		-- Closer to the anchor and more saturated → more weight
		local closeness = 1 / (1 + distSq * 8)
		local weight = closeness * s * v * (0.65 + 0.35 * math.abs(math.sin(h * math.pi * 2)))

		bucketWeight[anchorIndex] += weight
		bucketR[anchorIndex] += r * weight
		bucketG[anchorIndex] += g * weight
		bucketB[anchorIndex] += b * weight
	end

	local bestIndex = 1
	local bestWeight = -1
	for i = 1, #STRONG_ANCHORS do
		local w = bucketWeight[i]
		if w > bestWeight then
			bestWeight = w
			bestIndex = i
		end
	end

	local primary: Color3
	if bestWeight > 0 then
		primary = Color3.fromRGB(
			math.clamp(math.floor(bucketR[bestIndex] / bestWeight + 0.5), 0, 255),
			math.clamp(math.floor(bucketG[bestIndex] / bestWeight + 0.5), 0, 255),
			math.clamp(math.floor(bucketB[bestIndex] / bestWeight + 0.5), 0, 255)
		)
		-- Nudge toward the strong anchor (palette "pop")
		primary = primary:Lerp(STRONG_ANCHORS[bestIndex], 0.35)
	else
		primary = FALLBACK_PRIMARY
	end

	local secondary = darkerTone(primary, 0.42)

	-- Tertiary: black/white contrast based on which the image has more of
	local tertiary: Color3
	if whiteWeight >= blackWeight and whiteWeight > 0 then
		tertiary = Color3.fromRGB(245, 245, 250)
	elseif blackWeight > 0 then
		tertiary = Color3.fromRGB(18, 18, 22)
	else
		tertiary = if luminance(primary) > 0.55
			then Color3.fromRGB(18, 18, 22)
			else Color3.fromRGB(245, 245, 250)
	end

	if sampled == 0 then
		return fallbackPalette()
	end

	return buildPalette(primary, secondary, tertiary)
end

const function createEditableFromImageUri(imageUri: ImageUri): EditableImage?
	if imageUri == "" or imageUri == "rbxassetid://0" then
		return nil
	end

	local ok, editable = pcall(function()
		return AssetService:CreateEditableImageAsync(Content.fromUri(imageUri))
	end)

	if ok and editable then
		return editable
	end

	local ok2, editable2 = pcall(function()
		return AssetService:CreateEditableImageAsync(imageUri :: any)
	end)
	if ok2 and editable2 then
		return editable2
	end

	warn(`[PaletteLib] CreateEditableImageAsync failed for {imageUri}`)
	return nil
end

-- Extracts palette from the card Front image (yields)
function PaletteLib.ExtractFromFrontAsync(card: CardsServiceType.TemplateCard): CardPalette
	local front = card.Card.Front
	local imageUri = front.Image
	if imageUri == "" then
		return fallbackPalette()
	end

	local cached = cache[imageUri]
	if cached then
		return cached
	end

	local editable = createEditableFromImageUri(imageUri)
	if not editable then
		return fallbackPalette()
	end

	local size = editable.Size
	local palette = fallbackPalette()

	local ok, pixelsOrErr = pcall(function()
		return editable:ReadPixelsBuffer(Vector2.zero, size)
	end)

	editable:Destroy()

	if ok and typeof(pixelsOrErr) == "buffer" then
		palette = analyzePixels(pixelsOrErr, size.X, size.Y)
	else
		warn(`[PaletteLib] ReadPixelsBuffer failed: {pixelsOrErr}`)
	end

	cache[imageUri] = palette
	return palette
end

function PaletteLib.ExtractFromFront(card: CardsServiceType.TemplateCard): CardPalette
	return PaletteLib.ExtractFromFrontAsync(card)
end

-- Legacy: Background UIGradient (visual fallback without EditableImage)
function PaletteLib.ExtractFromBackground(card: CardsServiceType.TemplateCard): CardPalette
	local root = card.Card
	local colors: { Color3 } = {}
	local foil = getBackgroundCanvas(root)

	const function pushUnique(list: { Color3 }, color: Color3)
		for _, existing in list do
			if colorDistanceSq(existing, color) < 0.0025 then
				return
			end
		end
		table.insert(list, color)
	end

	const function collectFromGradient(gradient: UIGradient?)
		if not gradient then
			return
		end
		for _, keypoint in gradient.Color.Keypoints do
			pushUnique(colors, keypoint.Value)
		end
	end

	if foil then
		collectFromGradient(foil:FindFirstChildOfClass("UIGradient"))
	end

	if #colors == 0 then
		collectFromGradient(root.Background:FindFirstChildOfClass("UIGradient"))
		collectFromGradient(root.Stroke.UIStroke:FindFirstChildOfClass("UIGradient"))
	end

	if #colors == 0 then
		return fallbackPalette()
	end

	local primary = colors[1]
	local secondary = darkerTone(primary, 0.4)
	local tertiary = if luminance(primary) > 0.55
		then Color3.fromRGB(18, 18, 22)
		else Color3.fromRGB(245, 245, 250)

	return buildPalette(primary, secondary, tertiary)
end

function PaletteLib.Extract(card: CardsServiceType.TemplateCard): CardPalette
	local front = card.Card.Front
	if front.Image ~= "" then
		return PaletteLib.ExtractFromFrontAsync(card)
	end
	return PaletteLib.ExtractFromBackground(card)
end

function PaletteLib.ClearCache()
	table.clear(cache)
end

return PaletteLib
