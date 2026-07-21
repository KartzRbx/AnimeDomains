--!strict
-- Debi BufferWriter — layout fixo estilo Zap

const BufferWriter = {}
BufferWriter.__index = BufferWriter

export type BufferWriter = typeof(setmetatable(
	{} :: {
		buf: buffer,
		cursor: number,
		capacity: number,
	},
	BufferWriter
))

const INITIAL = 64

local function ensure(self: BufferWriter, extra: number)
	local needed = self.cursor + extra
	if needed <= self.capacity then
		return
	end

	local newCap = self.capacity
	while newCap < needed do
		newCap *= 2
	end

	const nextBuf = buffer.create(newCap)
	buffer.copy(nextBuf, 0, self.buf, 0, self.cursor)
	self.buf = nextBuf
	self.capacity = newCap
end

function BufferWriter.new(): BufferWriter
	return setmetatable({
		buf = buffer.create(INITIAL),
		cursor = 0,
		capacity = INITIAL,
	}, BufferWriter)
end

function BufferWriter.reset(self: BufferWriter)
	self.cursor = 0
end

function BufferWriter.writeu8(self: BufferWriter, value: number)
	ensure(self, 1)
	buffer.writeu8(self.buf, self.cursor, value)
	self.cursor += 1
end

function BufferWriter.writeu16(self: BufferWriter, value: number)
	ensure(self, 2)
	buffer.writeu16(self.buf, self.cursor, value)
	self.cursor += 2
end

function BufferWriter.writeu32(self: BufferWriter, value: number)
	ensure(self, 4)
	buffer.writeu32(self.buf, self.cursor, value)
	self.cursor += 4
end

function BufferWriter.writei8(self: BufferWriter, value: number)
	ensure(self, 1)
	buffer.writei8(self.buf, self.cursor, value)
	self.cursor += 1
end

function BufferWriter.writei16(self: BufferWriter, value: number)
	ensure(self, 2)
	buffer.writei16(self.buf, self.cursor, value)
	self.cursor += 2
end

function BufferWriter.writei32(self: BufferWriter, value: number)
	ensure(self, 4)
	buffer.writei32(self.buf, self.cursor, value)
	self.cursor += 4
end

function BufferWriter.writef32(self: BufferWriter, value: number)
	ensure(self, 4)
	buffer.writef32(self.buf, self.cursor, value)
	self.cursor += 4
end

function BufferWriter.writef64(self: BufferWriter, value: number)
	ensure(self, 8)
	buffer.writef64(self.buf, self.cursor, value)
	self.cursor += 8
end

function BufferWriter.writebool(self: BufferWriter, value: boolean)
	self:writeu8(if value then 1 else 0)
end

function BufferWriter.writestring(self: BufferWriter, value: string)
	const len = #value
	assert(len <= 65535, "[Debi] string too long")
	self:writeu16(len)
	ensure(self, len)
	buffer.writestring(self.buf, self.cursor, value)
	self.cursor += len
end

function BufferWriter.toBuffer(self: BufferWriter): buffer
	const out = buffer.create(self.cursor)
	buffer.copy(out, 0, self.buf, 0, self.cursor)
	return out
end

function BufferWriter.len(self: BufferWriter): number
	return self.cursor
end

return BufferWriter
