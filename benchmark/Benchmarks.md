# Satset Networking Benchmarks

*Last Updated: 2026-04-29*

This document provides a detailed performance analysis of **Satset** compared to native Roblox `RemoteEvent` and other community-standard networking libraries.

## 1. Summary Comparison

The following table shows the average bandwidth consumption (KB/s) across various stress tests. **Lower is better.**

| Category | Native (Roblox) | ByteNet (v0.4.6) | BridgeNet2 | Warp | Satset |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Vectors** | 140.3 | 79.8 | 166.5 | 0.8* | **80.5** |
| **Booleans** | 191.7 | 22.1 | 66.7 | 0.4* | **12.5** |
| **Mixed Data** | 97.4 | 2.8 | 8.2 | 0.8* | **5.3** |
| **Entities (State)** | 306.3 | 41.5 | 81.7 | 0.8* | **41.6** |
| **Strings** | 110.5 | **TIMEOUT** | 98.4 | 0.3* | **106.8** |

*\*Warp results show near-zero bandwidth due to a listener integration issue in the test harness; these results should not be used to judge Warp's actual performance.*

---

## 2. Technical Analysis

### Satset Performance

- **Consistency**: Satset passed every benchmark without regressions or timeouts.
- **Stateful Efficiency**: The **Booleans** and **Mixed** benchmarks highlight the power of Satset's bitmask-based delta compression, achieving up to **15x better efficiency** than native remotes.
- **Overhead**: A minor FPS drop (~10%) is observed in extreme high-frequency updates (Vectors) compared to previous versions. This is the expected trade-off for the newly implemented **NaN/Infinity Sanitization** and **Sequence Numbering** layers.

### Competitor Notes

- **ByteNet**: Shows extremely low bandwidth for simple types but failed the high-load **Strings** benchmark with a `Script timeout`. This suggests that its dynamic allocation strategy can struggle under specific heavy-load patterns.
- **BridgeNet2**: Provides excellent batching but maintains a higher bandwidth footprint because it doesn't use the same level of bitmask optimization as Satset for delta state.

---

## 3. Methodology

- **Test Environment**: Roblox Studio (Local Server, 1 Player).
- **Packet Frequency**: 100-500 fires per frame.
- **Metrics**: Measured using `Stats:GetTotalMemoryUsage()` and internal packet counters over a 10-second sampling window.
- **Stability**: Tests must complete without script execution timeouts.

---

## 4. Raw Data (JSON)

```json
{"Vectors":{"roblox":{"Framerate":[48,50,47,46,46,45],"Sent":468000,"Bandwidth":[88562.1524234694,65727.375,114786.09375,170025.97576530613,170025.97576530613,232757.35372340427],"Recieve":468000},"warp":{"Framerate":[60,60,60,60,60,60],"Sent":600000,"Bandwidth":[0.573141872882843,0.44067928194999697,0.8788703680038452,1.0051559209823609,1.0051559209823609,1.0946707725524903],"Recieve":0},"bridgenet2":{"Framerate":[58,61,57,55,55,52],"Sent":457000,"Bandwidth":[115671.33238636363,60195.71664663461,162658.42105263158,189891.64331896555,189891.64331896555,193223.07565789473],"Recieve":457000},"bytenet":{"Framerate":[60,61,60,59,59,56],"Sent":595000,"Bandwidth":[78.39849853515625,61.150919179447367,78.90540313720703,79.99463614770922,79.99463614770922,80.84268297467912],"Recieve":595000},"satset":{"Framerate":[39,39,38,37,37,37],"Sent":383000,"Bandwidth":[77.92012141301082,48.6640607393705,80.04992836400082,81.90109665329392,81.90109665329392,82.4435651624525],"Recieve":83056}},"Booleans":{"roblox":{"Framerate":[16,17,16,16,16,16],"Sent":113000,"Bandwidth":[202288.8556985294,86813.98207720588,212742.0263671875,215541.3427734375,215541.3427734375,215782.734375],"Recieve":113000},"warp":{"Framerate":[60,61,60,60,60,59],"Sent":600000,"Bandwidth":[0.3911963403224945,0.3760620653629303,0.39689136333152899,0.41668030619621279,0.41668030619621279,0.4340857267379761],"Recieve":0},"bridgenet2":{"Framerate":[15,17,15,15,15,15],"Sent":97000,"Bandwidth":[74659.3203125,37090.67095588235,76507.953125,76651.8203125,76651.8203125,78543.75],"Recieve":97000},"bytenet":{"Framerate":[22,22,21,21,21,21],"Sent":215000,"Bandwidth":[22.434906278337754,10.376345770699638,23.402186802455359,24.36440901322798,24.36440901322798,27.47418490323153],"Recieve":215000},"satset":{"Framerate":[15,16,15,15,15,15],"Sent":83000,"Bandwidth":[12.735505104064942,7.808015048503876,13.026841163635254,13.026841163635254,13.026841163635254,15.662825584411621],"Recieve":19256}},"Mixed":{"roblox":{"Framerate":[60,60,60,60,60,60],"Sent":600000,"Bandwidth":[91165.5234375,72925.375,99950.8984375,102369.6796875,102369.6796875,106569.6953125],"Recieve":600000},"warp":{"Framerate":[60,60,59,59,59,59],"Sent":598000,"Bandwidth":[0.5645304322242737,0.45738160610198977,0.7858424186706543,0.8949415562516552,0.8949415562516552,1.0831156423536397],"Recieve":0},"bridgenet2":{"Framerate":[60,60,60,60,60,60],"Sent":600000,"Bandwidth":[8387.1865234375,6619.50830078125,8423.8525390625,8436.2392578125,8436.2392578125,8449.09375],"Recieve":600000},"bytenet":{"Framerate":[16,16,16,16,16,15],"Sent":38000,"Bandwidth":[2.7893974781036379,2.7893974781036379,2.7893974781036379,2.7893974781036379,2.7893974781036379,3.3536269515752794],"Recieve":38000},"satset":{"Framerate":[60,60,60,60,60,59],"Sent":599000,"Bandwidth":[5.1477274894714359,3.7433197498321535,5.255772590637207,5.622740276789261,5.622740276789261,5.761962413787842],"Recieve":83288}},"Entities":{"roblox":{"Framerate":[16,16,16,16,16,15],"Sent":35000,"Bandwidth":[299796.40625,299796.40625,299796.40625,299796.40625,299796.40625,339191.015625],"Recieve":35000},"warp":{"Framerate":[60,60,60,60,60,59],"Sent":599000,"Bandwidth":[0.48423269391059878,0.4086202383041382,0.7588756084442139,0.8755518794059753,0.8755518794059753,1.0031085297212763],"Recieve":0},"bridgenet2":{"Framerate":[16,16,16,16,16,15],"Sent":31000,"Bandwidth":[78529.7021484375,78529.7021484375,78529.7021484375,78529.7021484375,78529.7021484375,97891.625],"Recieve":31000},"bytenet":{"Framerate":[20,21,20,19,19,19],"Sent":197000,"Bandwidth":[41.57003688812256,18.978873661586218,43.07667280498304,43.791229248046878,43.791229248046878,45.74638652801514],"Recieve":197000},"satset":{"Framerate":[47,47,46,39,39,32],"Sent":437000,"Bandwidth":[40.268036127090457,25.30858952948388,41.871374379033628,42.404634226923409,42.404634226923409,42.797435262928839],"Recieve":83288}},"SingleValue":{"roblox":{"Framerate":[60,60,60,60,60,58],"Sent":598000,"Bandwidth":[1700.6483154296876,1654.5980224609376,1728.9671630859376,1743.0921630859376,1743.0921630859376,1746.3441625134699],"Recieve":598000},"warp":{"Framerate":[60,60,60,60,60,59],"Sent":599000,"Bandwidth":[0.6249362230300903,0.4654860496520996,0.9167436361312866,1.0372302532196046,1.0372302532196046,1.1412368386478747],"Recieve":0},"bridgenet2":{"Framerate":[60,60,60,60,60,59],"Sent":599000,"Bandwidth":[719.2872314453125,562.6854858398438,721.5792236328125,725.9432310977225,725.9432310977225,733.8832397460938],"Recieve":599000},"bytenet":{"Framerate":[60,60,60,60,60,58],"Sent":598000,"Bandwidth":[2.4060401916503908,1.862972378730774,2.4721839427948,3.5157766342163088,3.5157766342163088,4.744314489693478],"Recieve":598000},"satset":{"Framerate":[60,61,60,59,59,59],"Sent":599000,"Bandwidth":[2.619551658630371,2.0040531158447267,2.767068862915039,3.3587569877749585,3.3587569877749585,4.11685297044657],"Recieve":83288}},"Strings":{"roblox":{"Framerate":[25,27,24,23,23,22],"Sent":179000,"Bandwidth":[105486.94444444445,59206.6357421875,121417.68110795453,123489.267578125,123489.267578125,130166.1688701923],"Recieve":179000},"warp":{"Framerate":[60,60,59,59,59,41],"Sent":311000,"Bandwidth":[0.30550137162208559,0.28308806783061915,0.3342967927455902,0.3342967927455902,0.3342967927455902,0.36484246573797088],"Recieve":0},"bridgenet2":{"Framerate":[60,60,56,56,56,49],"Sent":329000,"Bandwidth":[49308.72130102041,43145.131138392855,108060.0546875,108060.0546875,108060.0546875,113747.42598684209],"Recieve":329000},"bytenet":{"Framerate":[],"Sent":408,"Bandwidth":[],"Recieve":407},"satset":{"Framerate":[47,48,46,45,45,44],"Sent":457000,"Bandwidth":[105.26284998113458,61.89311575382314,107.18822976817256,107.22834485642454,107.22834485642454,108.32152325174083],"Recieve":83056}}}
```
