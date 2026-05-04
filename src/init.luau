-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Satset — high-performance hybrid networking for Roblox.
-- "Sat set, sampai."

local Batcher = require(script.Core.Batcher)
local Bridge = require(script.Core.Bridge)
local Channel = require(script.Networking.Channel)
local Guard = require(script.Core.Guard)
local Packet = require(script.Networking.Packet)
local Types = require(script.Types)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- [ Constants ]

local VERSION = "0.1.3"
local IS_SERVER = RunService:IsServer()

local CHANNEL_RELIABLE_NAME = "__SatsetChannelReliable"
local CHANNEL_UNRELIABLE_NAME = "__SatsetChannelUnreliable"

-- [ State ]

local _initialized = false
local _guard: any = nil
local channelReliable: RemoteEvent
local channelUnreliable: UnreliableRemoteEvent

-- [ Public API ]

local Satset = {}
Satset.Version = VERSION

-- Export types and core definitions so you don't have to require multiple files.
Satset.Types = Types
Satset.definePacket = Packet.definePacket
Satset.defineChannel = Channel.defineChannel

export type SatsetConfig = {
	guard: Guard.GuardConfig?,
	batching: Batcher.BatchingConfig?,
}

--[[
	Start the networking engine. 
	
	This handles all the internal wiring, sets up batching, and prepares 
	dedicated remotes. You should call this once on both the server and 
	the client before using any packets or channels.
]]
function Satset.start(config: SatsetConfig?)
	if _initialized then
		warn("[Satset] Already initialized. Ignoring duplicate start() call.")
		return
	end
	_initialized = true

	local context = if IS_SERVER then "Server" else "Client"
	print(`[Satset v{VERSION}] Initializing on {context}`)

	local cfg: SatsetConfig = config or {} :: SatsetConfig

	-- Apply custom batching configuration if provided.
	if cfg.batching then
		Batcher.configure(cfg.batching)
	end

	-- We initialize the bridge first to ensure remotes are ready.
	Bridge.init()

	-- The batcher hooks into PostSimulation to flush outgoing data.
	Batcher.init()

	-- Dedicated channel folder for organization.
	local bridgeFolder = game:GetService("ReplicatedStorage"):FindFirstChild("__SatsetBridge")

	if IS_SERVER then
		-- DDoS protection is mandatory on the server.
		_guard = Guard.new(cfg.guard)

		-- We create dedicated channel remotes to separate stateful traffic.
		channelReliable = Instance.new("RemoteEvent")
		channelReliable.Name = CHANNEL_RELIABLE_NAME
		channelReliable.Parent = bridgeFolder

		channelUnreliable = Instance.new("UnreliableRemoteEvent")
		channelUnreliable.Name = CHANNEL_UNRELIABLE_NAME
		channelUnreliable.Parent = bridgeFolder

		-- Cleanup is handled automatically when someone leaves.
		Players.PlayerRemoving:Connect(function(player)
			_guard:removePlayer(player)
			Batcher.removePlayer(player)
		end)

		-- Reliable packet listener.
		Bridge.getReliable().OnServerEvent:Connect(function(player, payload)
			if not _guard:consume(player) then
				return -- Too many requests, dropping.
			end

			if typeof(payload) ~= "buffer" then
				return -- Malformed data.
			end

			Packet._dispatch(payload, player)
		end)

		-- Unreliable packet listener.
		Bridge.getUnreliable().OnServerEvent:Connect(function(player, payload)
			if not _guard:consume(player) then
				return
			end

			if typeof(payload) ~= "buffer" then
				return
			end

			Packet._dispatchUnreliable(payload, player)
		end)

		-- The channel flush runs after the normal packet batcher.
		RunService.PostSimulation:Connect(function()
			local channelPayloads = Channel._flush()
			for _, payload in channelPayloads do
				local channelId = buffer.readu8(payload, 0)
				local registry = Channel._getRegistry()
				local def = registry[channelId]

				if def then
					if def.unreliable then
						channelUnreliable:FireAllClients(payload)
					else
						channelReliable:FireAllClients(payload)
					end
				end
			end
		end)
	else
		-- On the client, we wait for the server to spawn these.
		channelReliable = bridgeFolder:WaitForChild(CHANNEL_RELIABLE_NAME) :: RemoteEvent
		channelUnreliable = bridgeFolder:WaitForChild(CHANNEL_UNRELIABLE_NAME) :: UnreliableRemoteEvent

		-- Standard reliable packet listener.
		Bridge.getReliable().OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "buffer" then
				return
			end

			Packet._dispatch(payload, nil)
		end)

		-- Standard unreliable packet listener.
		Bridge.getUnreliable().OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "buffer" then
				return
			end

			Packet._dispatchUnreliable(payload, nil)
		end)

		-- Dedicated channel update listeners.
		channelReliable.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "buffer" then
				return
			end
			Channel._applyUpdate(payload)
		end)

		channelUnreliable.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "buffer" then
				return
			end
			Channel._applyUpdate(payload)
		end)
	end
end

return Satset
