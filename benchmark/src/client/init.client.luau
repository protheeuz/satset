-- Benchmark client. Fires 1000 events per frame for 10 seconds per tool per bench.
-- Measures FPS and bandwidth (Kbps) at percentile intervals.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

local Satset = require(ReplicatedStorage.DevPackages.Satset)
Satset.start()

local MAXIMUM_FRAMERATE = 60

local Benches, Modes

-- Minimize rendering overhead to isolate network performance.
local Camera = workspace.CurrentCamera
Camera.FieldOfView = 1
Camera.CFrame = CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
Players.LocalPlayer.PlayerGui:ClearAllChildren()
for _, child in Players.LocalPlayer.PlayerScripts:GetChildren() do
	if child ~= script then
		child:Destroy()
	end
end

for _, item in Enum.CoreGuiType:GetEnumItems() do
	while true do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(item, false)
		end)
		if ok then
			break
		end
	end
end

type Benchmark = {
	Sent: number,
	Recieve: number,
	Bandwidth: { number },
	Framerate: { number },
}

type Results = {
	[string]: {
		[string]: Benchmark,
	},
}

local function percentile(samples: { number }, pct: number)
	assert((pct // 1) == pct and pct >= 0 and pct <= 100, "Percentile must be an integer between 0 and 100")
	local index = ((#samples * (pct / 100)) // 1)
	index = math.max(index, 1)
	return samples[index]
end

local function waitForDrain()
	print("Waiting for packets to drain.")
	while Stats.DataSendKbps > 0.5 do
		RunService.Heartbeat:Wait()
	end
	task.wait(5)
end

local function runBenchmark(tool: string, bench: string): Benchmark
	local total = 0
	local frames = 0
	local bandwidth = {}
	local framerates = {}

	local sent = 0
	local data = Benches[bench]
	local events = Modes[tool]
	local event = events[bench]
	local method

	if tool == "roblox" then
		method = function(d)
			event:FireServer(d)
		end
	elseif tool == "bridgenet2" then
		-- BridgeNet2 client: bridge:Fire(data)
		method = function(d)
			event:Fire(d)
		end
	elseif tool == "warp" then
		-- Warp client: client:Fire(reliable, ...)
		method = function(d)
			event:Fire(true, d)
		end
	else
		-- Satset uses .fire(), ByteNet uses .send()
		method = event.fire or event.Fire or event.send
	end

	local connection = RunService.PostSimulation:Connect(function(dt: number)
		total += dt
		frames += 1

		if total >= 1 then
			total -= 1
			local scale = MAXIMUM_FRAMERATE / frames
			table.insert(bandwidth, Stats.DataSendKbps * scale)
			table.insert(framerates, frames)
			frames = 0
		end

		for _ = 1, 1000 do
			sent += 1
			method(data)
		end
	end)

	task.wait(10)
	connection:Disconnect()
	print("> Finished running with " .. tool)

	-- Sort for percentile calculation.
	table.sort(bandwidth)
	table.sort(framerates, function(a, b)
		return a > b
	end)

	local frameratePercentiles = {}
	local bandwidthPercentiles = {}

	for _, pct in { 50, 0, 80, 90, 95, 100 } do
		table.insert(bandwidthPercentiles, percentile(bandwidth, pct))
		table.insert(frameratePercentiles, percentile(framerates, pct))
	end

	return {
		Sent = sent,
		Recieve = 0,
		Bandwidth = bandwidthPercentiles,
		Framerate = frameratePercentiles,
	}
end

local function runAll()
	Benches = require(ReplicatedStorage.Shared.benches)
	Modes = require(ReplicatedStorage.Shared.modes)
	local results: Results = {}

	for bench in Benches do
		warn("Running " .. bench .. " benchmark")
		results[bench] = {}

		for tool in Modes do
			print("> Running with " .. tool)
			results[bench][tool] = runBenchmark(tool, bench)
			waitForDrain()
		end

		waitForDrain()
	end

	-- Pull server-side receive counts for loss calculation.
	local serverReceived = ReplicatedStorage.Shared.GetRecieved:InvokeServer()
	for bench, tools in serverReceived do
		for tool, count in tools do
			if results[bench] and results[bench][tool] then
				results[bench][tool].Recieve = count
			end
		end
	end

	print("Finished running benchmarks, generating results...")
	ReplicatedStorage.Shared.Generate:FireServer(HttpService:JSONEncode(results))
end

task.wait(2)
runAll()
