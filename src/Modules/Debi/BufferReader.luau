--!strict
-- Debi BufferReader — layout fixo estilo Zap

const BufferReader = {}
BufferReader.__index = BufferReader

export type BufferReader = typeof(setmetatable(
	{} :: {
		buf: buffer,
		cursor: number,
		len: number,
	},
	BufferReader
))

local function remaining(self: BufferReader): number
	return self.len - self.cursor
end

local function need(self: BufferReader, n: number)
	assert(remaining(self) >= n, "[Debi] buffer underrun")
end

function BufferReader.new(buf: buffer): BufferReader
	return setmetatable({
		buf = buf,
		cursor = 0,
		len = buffer.len(buf),
	}, BufferReader)
end

function BufferReader.readu8(self: BufferReader): number
	need(self, 1)
	const v = buffer.readu8(self.buf, self.cursor)
	self.cursor += 1
	return v
end

function BufferReader.readu16(self: BufferReader): number
	need(self, 2)
	const v = buffer.readu16(self.buf, self.cursor)
	self.cursor += 2
	return v
end

function BufferReader.readu32(self: BufferReader): number
	need(self, 4)
	const v = buffer.readu32(self.buf, self.cursor)
	self.cursor += 4
	return v
end

function BufferReader.readi8(self: BufferReader): number
	need(self, 1)
	const v = buffer.readi8(self.buf, self.cursor)
	self.cursor += 1
	return v
end

function BufferReader.readi16(self: BufferReader): number
	need(self, 2)
	const v = buffer.readi16(self.buf, self.cursor)
	self.cursor += 2
	return v
end

function BufferReader.readi32(self: BufferReader): number
	need(self, 4)
	const v = buffer.readi32(self.buf, self.cursor)
	self.cursor += 4
	return v
end

function BufferReader.readf32(self: BufferReader): number
	need(self, 4)
	const v = buffer.readf32(self.buf, self.cursor)
	self.cursor += 4
	return v
end

function BufferReader.readf64(self: BufferReader): number
	need(self, 8)
	const v = buffer.readf64(self.buf, self.cursor)
	self.cursor += 8
	return v
end

function BufferReader.readbool(self: BufferReader): boolean
	return self:readu8() ~= 0
end

function BufferReader.readstring(self: BufferReader): string
	const len = self:readu16()
	need(self, len)
	const v = buffer.readstring(self.buf, self.cursor, len)
	self.cursor += len
	return v
end

function BufferReader.hasMore(self: BufferReader): boolean
	return self.cursor < self.len
end

return BufferReader
