--!strict
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Bridge — manages underlying RemoteEvent and UnreliableRemoteEvent instances.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- [ Constants ]

local IS_SERVER = RunService:IsServer()

local FOLDER_NAME = "__SatsetBridge"
local RELIABLE_NAME = "__SatsetReliable"
local UNRELIABLE_NAME = "__SatsetUnreliable"

-- [ State ]

local bridgeFolder: Folder
local reliableRemote: RemoteEvent
local unreliableRemote: UnreliableRemoteEvent

local Bridge = {}

-- [ Public API ]

--[[
	Initializes the bridge folder and remotes. 
	
	The server creates the folder and instances in ReplicatedStorage, 
	while the client waits for them to appear.
]]
function Bridge.init()
	if IS_SERVER then
		bridgeFolder = Instance.new("Folder")
		bridgeFolder.Name = FOLDER_NAME
		bridgeFolder.Parent = ReplicatedStorage

		reliableRemote = Instance.new("RemoteEvent")
		reliableRemote.Name = RELIABLE_NAME
		reliableRemote.Parent = bridgeFolder

		unreliableRemote = Instance.new("UnreliableRemoteEvent")
		unreliableRemote.Name = UNRELIABLE_NAME
		unreliableRemote.Parent = bridgeFolder
	else
		bridgeFolder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
		reliableRemote = bridgeFolder:WaitForChild(RELIABLE_NAME) :: RemoteEvent
		unreliableRemote = bridgeFolder:WaitForChild(UNRELIABLE_NAME) :: UnreliableRemoteEvent
	end
end

--[[
	Returns the shared reliable RemoteEvent.
]]
function Bridge.getReliable(): RemoteEvent
	return reliableRemote
end

--[[
	Returns the shared UnreliableRemoteEvent.
]]
function Bridge.getUnreliable(): UnreliableRemoteEvent
	return unreliableRemote
end

--[[
	Helper to check if we are currently executing on the server.
]]
function Bridge.isServer(): boolean
	return IS_SERVER
end

return Bridge
