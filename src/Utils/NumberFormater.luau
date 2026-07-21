--!strict
-- Behavior: facade over Packages.formatnumber + time/date for UI
-- Docs: https://devforum.roblox.com/t/311-formatnumber-a-module-for-formatting-numbers/527979

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatNumber = require(ReplicatedStorage.Packages.formatnumber).Main

local COMPACT_SUFFIXES = { "K", "M", "B", "T", "Q", "Qd", "Qui" }

local NumberFormater = {}

-- Cached formatters (NumberFormatter is immutable)
local integerFormatter = FormatNumber.NumberFormatter.with()
	:Precision(FormatNumber.Precision.integer())
	:Grouping(FormatNumber.GroupingStrategy.ON_ALIGNED)

local exactFormatter = FormatNumber.NumberFormatter.with()
	:Precision(FormatNumber.Precision.maxFraction(6))
	:Grouping(FormatNumber.GroupingStrategy.ON_ALIGNED)

local compactFormatter = FormatNumber.NumberFormatter.with()
	:Notation(FormatNumber.Notation.compactWithSuffixThousands(COMPACT_SUFFIXES))
	:Precision(FormatNumber.Precision.integer():WithMinDigits(3))

local signedFormatter = FormatNumber.NumberFormatter.with()
	:Precision(FormatNumber.Precision.integer())
	:Grouping(FormatNumber.GroupingStrategy.ON_ALIGNED)
	:Sign(FormatNumber.SignDisplay.EXCEPT_ZERO)

local dotsSymbols = FormatNumber.DecimalFormatSymbols.createWithLastResortData()
dotsSymbols:SetSymbol(FormatNumber.ENumberFormatSymbols.kGroupingSeparatorSymbol, ".")
dotsSymbols:SetSymbol(FormatNumber.ENumberFormatSymbols.kDecimalSeparatorSymbol, ",")

local dotsFormatter = FormatNumber.NumberFormatter.with()
	:Precision(FormatNumber.Precision.integer())
	:Grouping(FormatNumber.GroupingStrategy.ON_ALIGNED)
	:Symbols(dotsSymbols)

local function pad2(n: number): string
	return string.format("%02d", math.floor(n))
end

local function toNonNegativeInt(value: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.max(0, math.floor(value))
end

local function splitSeconds(totalSeconds: number): (number, number, number, number)
	local seconds = toNonNegativeInt(totalSeconds)
	local days = math.floor(seconds / 86400)
	seconds %= 86400
	local hours = math.floor(seconds / 3600)
	seconds %= 3600
	local minutes = math.floor(seconds / 60)
	seconds %= 60
	return days, hours, minutes, seconds
end

local function resolveDateTime(input: number | DateTime): DateTime
	if typeof(input) == "DateTime" then
		return input
	end
	return DateTime.fromUnixTimestamp(input)
end

-- Numbers (FormatNumber) ------------------------------------------------

-- 1234 → "1,234"
function NumberFormater.formatInteger(value: number): string
	return integerFormatter:Format(value)
end

-- 1234.56789 → "1,234.56789" (up to 6 places)
function NumberFormater.formatExact(value: number): string
	return exactFormatter:Format(value)
end

-- 1234 → "1.23K", 12345 → "12.3K"
function NumberFormater.formatCompact(value: number): string
	return compactFormatter:Format(value)
end

-- +12 / -12 / 0
function NumberFormater.formatSigned(value: number): string
	return signedFormatter:Format(value)
end

-- Signed delta: +1,234 / -500
function NumberFormater.formatDelta(value: number): string
	return signedFormatter:Format(value)
end

-- 0.75 → "75%"
function NumberFormater.formatPercent(value: number, decimals: number?): string
	local places = decimals or 0
	local percent = value * 100
	if places <= 0 then
		return `{NumberFormater.formatInteger(percent)}%`
	end

	local percentFormatter = FormatNumber.NumberFormatter.with()
		:Precision(FormatNumber.Precision.fixedFraction(places))
		:Grouping(FormatNumber.GroupingStrategy.ON_ALIGNED)

	return `{percentFormatter:Format(percent)}%`
end

-- 1234567 → "1.234.567"
function NumberFormater.WithDots(value: number): string
	return dotsFormatter:Format(value)
end

-- Aliases
NumberFormater.WithCommas = NumberFormater.formatInteger
NumberFormater.Abbreviate = NumberFormater.formatCompact
NumberFormater.Percent = NumberFormater.formatPercent

-- Access to Main API for advanced cases
NumberFormater.FormatNumber = FormatNumber

-- Time -------------------------------------------------------------------

-- 3661 → "01:01:01"
function NumberFormater.formatTime(totalSeconds: number): string
	local _, _, minutes, seconds = splitSeconds(totalSeconds)
	local totalHours = math.floor(toNonNegativeInt(totalSeconds) / 3600)
	return `{pad2(totalHours)}:{pad2(minutes)}:{pad2(seconds)}`
end

-- 125 → "02:05"
function NumberFormater.TimeMS(totalSeconds: number): string
	local seconds = toNonNegativeInt(totalSeconds)
	local minutes = math.floor(seconds / 60)
	seconds %= 60
	return `{pad2(minutes)}:{pad2(seconds)}`
end

-- 45 → "45s", 125 → "2m 5s", 3725 → "1h 2m"
function NumberFormater.TimeCompact(totalSeconds: number): string
	local days, hours, minutes, seconds = splitSeconds(totalSeconds)

	if days > 0 then
		return if hours > 0 then `{days}d {hours}h` else `{days}d`
	end
	if hours > 0 then
		return if minutes > 0 then `{hours}h {minutes}m` else `{hours}h`
	end
	if minutes > 0 then
		return if seconds > 0 then `{minutes}m {seconds}s` else `{minutes}m`
	end
	return `{seconds}s`
end

-- Cooldown UI: < 1h → MM:SS, else HH:MM:SS
function NumberFormater.formatCooldown(totalSeconds: number): string
	if toNonNegativeInt(totalSeconds) < 3600 then
		return NumberFormater.TimeMS(totalSeconds)
	end
	return NumberFormater.formatTime(totalSeconds)
end

NumberFormater.TimeHMS = NumberFormater.formatTime
NumberFormater.TimeAuto = NumberFormater.formatCooldown

-- Date -------------------------------------------------------------------

-- 17/07/2026
function NumberFormater.Date(input: number | DateTime): string
	local values = resolveDateTime(input):ToUniversalTime()
	return `{pad2(values.Day)}/{pad2(values.Month)}/{values.Year}`
end

-- 17/07/2026 14:05
function NumberFormater.DateTime(input: number | DateTime): string
	local values = resolveDateTime(input):ToUniversalTime()
	return `{pad2(values.Day)}/{pad2(values.Month)}/{values.Year} {pad2(values.Hour)}:{pad2(values.Minute)}`
end

-- 17/07/2026 14:05:09
function NumberFormater.DateTimeFull(input: number | DateTime): string
	local values = resolveDateTime(input):ToUniversalTime()
	return `{pad2(values.Day)}/{pad2(values.Month)}/{values.Year} {pad2(values.Hour)}:{pad2(values.Minute)}:{pad2(values.Second)}`
end

return NumberFormater
