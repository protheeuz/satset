--!native
--!optimize 2
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Batcher — handles frame-level batching, dynamic segmentation, and rate-limited flushing.

local RunService = game:GetService("RunService")

local Bridge = require(script.Parent.Bridge)

-- [ Constants ]

local IS_SERVER = RunService:IsServer()

-- UnreliableRemoteEvent has a limit around 1000 bytes.
-- We cap at 900 to stay safe.
local RELIABLE_SPLIT_THRESHOLD = 60000
local UNRELIABLE_SPLIT_THRESHOLD = 900
local MAX_PACKETS_PER_FRAME = 0 -- 0 means no limit (Latency Mode)
local INITIAL_WORKING_SIZE = 65536

type Stream = {
	b: buffer,
	cursor: number,
	count: number,
}

local serverReliableStream: Stream = { b = buffer.create(INITIAL_WORKING_SIZE), cursor = 2, count = 0 }
local serverUnreliableStream: Stream = { b = buffer.create(INITIAL_WORKING_SIZE), cursor = 4, count = 0 }
local serverReliableBatches: { buffer } = {}
local serverUnreliableBatches: { buffer } = {}

local clientReliableStreams: { [Player]: Stream } = {}
local clientUnreliableStreams: { [Player]: Stream } = {}
local clientReliableBatches: { [Player]: { buffer } } = {}
local clientUnreliableBatches: { [Player]: { buffer } } = {}

local broadcastReliableStream: Stream = { b = buffer.create(INITIAL_WORKING_SIZE), cursor = 2, count = 0 }
local broadcastReliableBatches: { buffer } = {}

local serverSeqCounters: { [Player]: number } = {}
local clientSeqCounter: number = 0

local lastReceivedSeq: { [Player]: number } = {}
local lastServerSeq: number = 0

local packetFixedSizes: { [number]: number } = {}

local Batcher = {}

function Batcher.registerFixedSize(id: number, size: number)
	packetFixedSizes[id] = size
end

export type BatchingConfig = {
	reliableThreshold: number?,
	unreliableThreshold: number?,
	maxPacketsPerFrame: number?,
}

function Batcher.configure(config: BatchingConfig)
	if config.reliableThreshold then
		RELIABLE_SPLIT_THRESHOLD = config.reliableThreshold
	end
	if config.unreliableThreshold then
		UNRELIABLE_SPLIT_THRESHOLD = config.unreliableThreshold
	end
	if config.maxPacketsPerFrame ~= nil then
		MAX_PACKETS_PER_FRAME = config.maxPacketsPerFrame
	end
end

local function commitStream(stream: Stream, reliable: boolean, seqCounter: number?): (buffer?, number?)
	if stream.count == 0 then
		return nil, seqCounter
	end

	local nextSeq = seqCounter
	if reliable then
		buffer.writeu16(stream.b, 0, stream.count)
	else
		local val = ((seqCounter or 0) + 1) % 65536
		buffer.writeu16(stream.b, 0, val)
		buffer.writeu16(stream.b, 2, stream.count)
		nextSeq = val
	end

	-- Always create an exact-sized buffer for sending. Roblox RemoteEvent
	-- transmits the entire buffer object, so we must right-size it.
	local exactBuffer = buffer.create(stream.cursor)
	buffer.copy(exactBuffer, 0, stream.b, 0, stream.cursor)

	-- Reset stream for next frame. Reuse the existing working buffer
	-- to avoid re-allocation when the load is stable across frames.
	stream.count = 0
	stream.cursor = reliable and 2 or 4

	return exactBuffer, nextSeq
end

local function allocateInStream(
	stream: Stream,
	packetId: number,
	size: number,
	splitThreshold: number,
	reliable: boolean,
	seqCounter: number?,
	queueTo: { buffer }
): (buffer, number, number?)
	local isFixed = packetFixedSizes[packetId] ~= nil
	local entrySize = 1 + (isFixed and 0 or 2) + size

	if stream.cursor + entrySize > splitThreshold and stream.count > 0 then
		local exactBuffer, newSeq = commitStream(stream, reliable, seqCounter)
		if exactBuffer then
			table.insert(queueTo, exactBuffer)
		end
		if newSeq then
			seqCounter = newSeq
		end
	end

	if stream.cursor + entrySize > buffer.len(stream.b) then
		local newB = buffer.create(math.max(buffer.len(stream.b) * 2, stream.cursor + entrySize))
		buffer.copy(newB, 0, stream.b, 0, stream.cursor)
		stream.b = newB
	end

	local offset = stream.cursor
	buffer.writeu8(stream.b, offset, packetId)

	if not isFixed then
		buffer.writeu16(stream.b, offset + 1, size)
		offset += 2
	end

	stream.cursor += entrySize
	stream.count += 1

	return stream.b, offset + 1, seqCounter
end
type QueueEntry = { id: number, b: buffer, offset: number, len: number }

-- [ Internal API ]

--[[
	Splits a reliable batch back into individual packets without allocating new buffers.
]]
function Batcher.decodeBatch(b: buffer): { QueueEntry }
	local results = {}
	local cursor = 0
	local bufLen = buffer.len(b)

	if bufLen < 2 then
		return results
	end

	local count = buffer.readu16(b, cursor)
	cursor += 2
	-- print(`[Satset Debug] Batch size: {count}`)

	for _ = 1, count do
		if cursor + 1 > bufLen then
			break
		end

		local id = buffer.readu8(b, cursor)
		cursor += 1

		local payloadLen = packetFixedSizes[id]
		if not payloadLen then
			if cursor + 2 > bufLen then
				break
			end
			payloadLen = buffer.readu16(b, cursor)
			cursor += 2
		end

		if cursor + payloadLen > bufLen then
			break
		end

		table.insert(results, { id = id, b = b, offset = cursor, len = payloadLen })
		cursor += payloadLen
	end

	return results
end

--[[
	Decodes an unreliable batch and checks for staleness.
	If the packet is too old, it returns nil.
]]
function Batcher.decodeUnreliableBatch(b: buffer, sender: Player?): { QueueEntry }?
	local bufLen = buffer.len(b)
	if bufLen < 4 then
		return nil
	end

	local seq = buffer.readu16(b, 0)

	local lastSeq: number
	if IS_SERVER then
		lastSeq = lastReceivedSeq[sender :: Player] or 0
	else
		lastSeq = lastServerSeq
	end

	-- We use a half-window comparison to handle 16-bit wraparound correctly.
	local diff = (seq - lastSeq) % 65536
	if diff == 0 or diff > 32768 then
		return nil -- Stale or duplicate.
	end

	if IS_SERVER then
		lastReceivedSeq[sender :: Player] = seq
	else
		lastServerSeq = seq
	end

	local results = {}
	local cursor = 2

	local count = buffer.readu16(b, cursor)
	cursor += 2

	for _ = 1, count do
		if cursor + 1 > bufLen then
			break
		end

		local id = buffer.readu8(b, cursor)
		cursor += 1

		local payloadLen = packetFixedSizes[id]
		if not payloadLen then
			if cursor + 2 > bufLen then
				break
			end
			payloadLen = buffer.readu16(b, cursor)
			cursor += 2
		end

		if cursor + payloadLen > bufLen then
			break
		end

		table.insert(results, { id = id, b = b, offset = cursor, len = payloadLen })
		cursor += payloadLen
	end

	return results
end

-- [ Enqueue API ]

function Batcher.allocateForPlayer(player: Player, packetId: number, size: number, reliable: boolean): (buffer, number)
	if reliable then
		local stream = clientReliableStreams[player]
		if not stream then
			stream = { b = buffer.create(INITIAL_WORKING_SIZE), cursor = 2, count = 0 }
			clientReliableStreams[player] = stream
		end
		local batches = clientReliableBatches[player]
		if not batches then
			batches = {}
			clientReliableBatches[player] = batches
		end

		local b, offset = allocateInStream(stream, packetId, size, RELIABLE_SPLIT_THRESHOLD, true, nil, batches)
		return b, offset
	else
		local stream = clientUnreliableStreams[player]
		if not stream then
			stream = { b = buffer.create(INITIAL_WORKING_SIZE), cursor = 4, count = 0 }
			clientUnreliableStreams[player] = stream
		end
		local batches = clientUnreliableBatches[player]
		if not batches then
			batches = {}
			clientUnreliableBatches[player] = batches
		end

		local seq = serverSeqCounters[player] or 0
		local b, offset, newSeq =
			allocateInStream(stream, packetId, size, UNRELIABLE_SPLIT_THRESHOLD, false, seq, batches)
		serverSeqCounters[player] = newSeq :: number
		return b, offset
	end
end

function Batcher.allocateForAllPlayers(packetId: number, size: number): (buffer, number)
	local b, offset = allocateInStream(
		broadcastReliableStream,
		packetId,
		size,
		RELIABLE_SPLIT_THRESHOLD,
		true,
		nil,
		broadcastReliableBatches
	)
	return b, offset
end

function Batcher.allocateForServer(packetId: number, size: number, reliable: boolean): (buffer, number)
	if reliable then
		local b, offset = allocateInStream(
			serverReliableStream,
			packetId,
			size,
			RELIABLE_SPLIT_THRESHOLD,
			true,
			nil,
			serverReliableBatches
		)
		return b, offset
	else
		local b, offset, newSeq = allocateInStream(
			serverUnreliableStream,
			packetId,
			size,
			UNRELIABLE_SPLIT_THRESHOLD,
			false,
			clientSeqCounter,
			serverUnreliableBatches
		)
		clientSeqCounter = newSeq :: number
		return b, offset
	end
end

-- [ Flush ]

local function flush()
	if IS_SERVER then
		local reliableRemote = Bridge.getReliable()
		local unreliableRemote = Bridge.getUnreliable()

		for player, stream in clientReliableStreams do
			local exact, _ = commitStream(stream, true)
			local batches = clientReliableBatches[player]
			if batches then
				if exact then
					table.insert(batches, exact)
				end

				local sentThisFrame = 0
				local i = 1
				while i <= #batches do
					reliableRemote:FireClient(player, batches[i])
					sentThisFrame += 1
					table.remove(batches, i)

					if MAX_PACKETS_PER_FRAME > 0 and sentThisFrame >= MAX_PACKETS_PER_FRAME then
						break
					end
				end
			elseif exact then
				reliableRemote:FireClient(player, exact)
			end
		end

		for player, stream in clientUnreliableStreams do
			local seq = serverSeqCounters[player] or 0
			local exact, newSeq = commitStream(stream, false, seq)
			serverSeqCounters[player] = newSeq :: number

			local batches = clientUnreliableBatches[player]
			if batches then
				if exact then
					table.insert(batches, exact)
				end

				local sentThisFrame = 0
				local i = 1
				while i <= #batches do
					unreliableRemote:FireClient(player, batches[i])
					sentThisFrame += 1
					table.remove(batches, i)

					if MAX_PACKETS_PER_FRAME > 0 and sentThisFrame >= MAX_PACKETS_PER_FRAME then
						break
					end
				end
			elseif exact then
				unreliableRemote:FireClient(player, exact)
			end
		end

		local exact, _ = commitStream(broadcastReliableStream, true)
		if exact then
			table.insert(broadcastReliableBatches, exact)
		end

		local sentThisFrame = 0
		local i = 1
		while i <= #broadcastReliableBatches do
			reliableRemote:FireAllClients(broadcastReliableBatches[i])
			sentThisFrame += 1
			table.remove(broadcastReliableBatches, i)

			if MAX_PACKETS_PER_FRAME > 0 and sentThisFrame >= MAX_PACKETS_PER_FRAME then
				break
			end
		end
	else
		local exactR, _ = commitStream(serverReliableStream, true)
		if exactR then
			table.insert(serverReliableBatches, exactR)
		end

		local sentThisFrame = 0
		local i = 1
		while i <= #serverReliableBatches do
			Bridge.getReliable():FireServer(serverReliableBatches[i])
			sentThisFrame += 1
			table.remove(serverReliableBatches, i)

			if MAX_PACKETS_PER_FRAME > 0 and sentThisFrame >= MAX_PACKETS_PER_FRAME then
				break
			end
		end

		local exactU, newSeq = commitStream(serverUnreliableStream, false, clientSeqCounter)
		clientSeqCounter = newSeq :: number
		if exactU then
			table.insert(serverUnreliableBatches, exactU)
		end

		i = 1
		local sentThisFrameU = 0
		while i <= #serverUnreliableBatches do
			Bridge.getUnreliable():FireServer(serverUnreliableBatches[i])
			sentThisFrameU += 1
			table.remove(serverUnreliableBatches, i)

			if MAX_PACKETS_PER_FRAME > 0 and sentThisFrameU >= MAX_PACKETS_PER_FRAME then
				break
			end
		end
	end
end

--[[
	Connects the flush logic to the frame lifecycle.
]]
function Batcher.init()
	RunService.PostSimulation:Connect(flush)
end

--[[
	Purges a player's state when they disconnect.
]]
function Batcher.removePlayer(player: Player)
	clientReliableStreams[player] = nil
	clientUnreliableStreams[player] = nil
	clientReliableBatches[player] = nil
	clientUnreliableBatches[player] = nil
	serverSeqCounters[player] = nil
	lastReceivedSeq[player] = nil
end

return Batcher
