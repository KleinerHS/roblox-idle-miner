--!strict
-- Maße und Drehpunkte der 3D-Drill-Modelle L01–L30 aus Felix' Paket Industrial_Drills
-- (Drill_Config.luau, D-075). Alle Werte im Quellraum des Modells: +X Bohrrichtung, +Y oben,
-- Ursprung = Boden unter der Maschine. Im Spiel werden die Modelle je Stufe vergrößert (scale).
-- size/center: Gesamtmaße und Mitte; groups: Drehpunkte (Rotor absolut, Roller relativ zum Rotor),
-- Quaternion {x, y, z, w}. Rotor und Roller drehen um ihre lokale X-Achse.

export type Group = { position: Vector3, quaternion: { number } }
export type Entry = { size: Vector3, center: Vector3, groups: { [string]: Group } }

local data: { [number]: Entry } = {
	[1] = {
		size = Vector3.new(2.900000019, 1.149036111, 1.389481544),
		center = Vector3.new(0.350898347, 0.574518056, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(0.911847277, 0.895564290, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[2] = {
		size = Vector3.new(3.075040176, 1.223359849, 1.468949914),
		center = Vector3.new(0.375557698, 0.611679925, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(0.963998392, 0.946784135, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[3] = {
		size = Vector3.new(3.291140138, 1.314619137, 1.567501187),
		center = Vector3.new(0.405652195, 0.657309568, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.028672634, 1.010303480, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[4] = {
		size = Vector3.new(3.526034484, 1.414076522, 1.674392223),
		center = Vector3.new(0.438546841, 0.707038261, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.098819861, 1.079198078, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[5] = {
		size = Vector3.new(3.774031598, 1.519524125, 1.786854267),
		center = Vector3.new(0.473586181, 0.759762063, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.172623117, 1.151683418, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[6] = {
		size = Vector3.new(4.032251229, 1.629853324, 1.903478384),
		center = Vector3.new(0.510444457, 0.814926662, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.249157657, 1.226851270, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[7] = {
		size = Vector3.new(4.298920504, 1.877171516, 2.023393393),
		center = Vector3.new(0.548924501, 0.938585758, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.327851883, 1.304140242, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[8] = {
		size = Vector3.new(4.572828102, 1.990919590, 2.146001816),
		center = Vector3.new(0.588893079, 0.995459795, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.408313679, 1.383165221, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[9] = {
		size = Vector3.new(4.853088728, 2.106760263, 2.270865917),
		center = Vector3.new(0.630253966, 1.053380132, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.490255705, 1.463643996, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[10] = {
		size = Vector3.new(5.139024793, 2.224381924, 2.481941938),
		center = Vector3.new(0.672934084, 1.112190962, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.573457538, 1.545360082, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[11] = {
		size = Vector3.new(5.430099384, 2.343537331, 2.614894390),
		center = Vector3.new(0.716875740, 1.171768665, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.657744305, 1.628141728, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[12] = {
		size = Vector3.new(5.725875816, 2.464025259, 2.749333382),
		center = Vector3.new(0.762032251, 1.232012630, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.742973647, 1.711849118, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[13] = {
		size = Vector3.new(6.025991674, 2.585678577, 3.211684942),
		center = Vector3.new(0.808364747, 1.292839289, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.829027291, 1.796366089, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[14] = {
		size = Vector3.new(6.330140113, 2.708355665, 3.364063025),
		center = Vector3.new(0.855840444, 1.354177833, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(1.915805339, 1.881594529, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[15] = {
		size = Vector3.new(6.638058456, 2.831936121, 3.517562866),
		center = Vector3.new(0.904431002, 1.415968060, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(2.003222260, 1.967450434, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[16] = {
		size = Vector3.new(6.949518974, 2.956315041, 3.672054529),
		center = Vector3.new(0.954111723, 1.478157520, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(2.091203983, 2.053861054, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[17] = {
		size = Vector3.new(7.264321711, 3.081400871, 3.827424288),
		center = Vector3.new(1.004861070, 1.540700436, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(2.179685738, 2.140762778, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[18] = {
		size = Vector3.new(7.582290348, 3.207113028, 3.983571768),
		center = Vector3.new(1.056659310, 1.603556514, 0.000000000),
		groups = {
			Rotor = {position = Vector3.new(2.268610415, 2.228099515, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[19] = {
		size = Vector3.new(7.903267115, 3.350818554, 4.880769253),
		center = Vector3.new(1.109489068, 1.675409277, 0.019298553),
		groups = {
			Rotor = {position = Vector3.new(2.357927293, 2.315821448, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
		},
	},
	[20] = {
		size = Vector3.new(8.227111004, 3.468881147, 4.859538078),
		center = Vector3.new(1.283774208, 1.734440573, 0.019214630),
		groups = {
			Rotor = {position = Vector3.new(2.347670465, 2.305747778, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(1.942417825, 0.629305938, 0.363329953), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(1.942417825, -0.629305938, 0.363329953), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(1.942417825, 0.000000000, -0.726659906), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[21] = {
		size = Vector3.new(8.553695082, 3.622447470, 5.042212963),
		center = Vector3.new(1.340691745, 1.811223735, 0.019936800),
		groups = {
			Rotor = {position = Vector3.new(2.435921757, 2.392423154, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.015435263, 0.665519146, 0.384237658), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.015435263, -0.665519146, 0.384237658), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.015435263, 0.000000000, -0.768475316), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[22] = {
		size = Vector3.new(8.882902848, 3.778274843, 5.225693464),
		center = Vector3.new(1.398452395, 1.889137421, 0.020662427),
		groups = {
			Rotor = {position = Vector3.new(2.524562209, 2.479480741, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.088774685, 0.702750538, 0.405733212), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.088774685, -0.702750538, 0.405733212), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.088774685, 0.000000000, -0.811466424), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[23] = {
		size = Vector3.new(9.214629608, 4.329170704, 5.409912825),
		center = Vector3.new(1.457042196, 2.164585352, 0.021390796),
		groups = {
			Rotor = {position = Vector3.new(2.613559557, 2.566888851, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.162409396, 0.740996985, 0.427814809), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.162409396, -0.740996985, 0.427814809), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.162409396, 0.000000000, -0.855629617), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[24] = {
		size = Vector3.new(9.548778608, 4.477130890, 5.594809771),
		center = Vector3.new(1.516448297, 2.238565445, 0.022121787),
		groups = {
			Rotor = {position = Vector3.new(2.702884308, 2.654618516, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.236314993, 0.780255491, 0.450480718), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.236314993, -0.780255491, 0.450480718), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.236314993, 0.000000000, -0.900961436), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[25] = {
		size = Vector3.new(9.885260616, 4.953379631, 5.780328274),
		center = Vector3.new(1.576659220, 2.476689816, 0.022855282),
		groups = {
			Rotor = {position = Vector3.new(2.792509394, 2.742643155, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.310469082, 0.820523169, 0.473729272), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.310469082, -0.820523169, 0.473729272), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.310469082, 0.000000000, -0.947458544), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[26] = {
		size = Vector3.new(10.223994020, 5.112845898, 5.966417074),
		center = Vector3.new(1.637663724, 2.556422949, 0.023591161),
		groups = {
			Rotor = {position = Vector3.new(2.882409897, 2.830938291, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.384851046, 0.861797210, 0.497558851), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.384851046, -0.861797210, 0.497558851), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.384851046, 0.000000000, -0.995117702), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[27] = {
		size = Vector3.new(10.564902826, 5.272760391, 6.153028011),
		center = Vector3.new(1.699451707, 2.636380196, 0.024328947),
		groups = {
			Rotor = {position = Vector3.new(2.972562799, 2.919481321, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.459441840, 0.904074875, 0.521967873), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.459441840, -0.904074875, 0.521967873), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.459441840, 0.000000000, -1.043935745), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[28] = {
		size = Vector3.new(10.907916646, 5.433084011, 6.340117455),
		center = Vector3.new(1.762013485, 2.716542006, 0.025068760),
		groups = {
			Rotor = {position = Vector3.new(3.062946785, 3.008251306, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.534223828, 0.947353474, 0.546954783), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.534223828, -0.947353474, 0.546954783), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.534223828, 0.000000000, -1.093909566), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[29] = {
		size = Vector3.new(11.252969305, 5.762722492, 6.527644157),
		center = Vector3.new(1.825340291, 2.881361246, 0.025810242),
		groups = {
			Rotor = {position = Vector3.new(3.153542057, 3.097228806, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.609180630, 0.991630354, 0.572518052), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.609180630, -0.991630354, 0.572518052), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.609180630, -0.000000000, -1.145036104), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
	[30] = {
		size = Vector3.new(11.599999986, 5.928627014, 6.715570211),
		center = Vector3.new(1.889423411, 2.964313507, 0.026553273),
		groups = {
			Rotor = {position = Vector3.new(3.244330189, 3.186395721, 0.000000000), quaternion = {0.000000000, 0.000000000, 0.000000000, 1.000000000}},
			Roller_01 = {position = Vector3.new(2.684297002, 1.036902896, 0.598656166), quaternion = {-0.706067404, 0.149395802, -0.038325199, 0.691144626}},
			Roller_02 = {position = Vector3.new(2.684297002, -1.036902896, 0.598656166), quaternion = {-0.691144626, -0.038325199, 0.149395802, 0.706067404}},
			Roller_03 = {position = Vector3.new(2.684297002, 0.000000000, -1.197312332), quaternion = {-0.698645859, -0.109059448, -0.109059448, 0.698645859}},
		},
	},
}

local DrillModels = {}

DrillModels.Data = data

-- Quell-CFrame einer Gruppe (Position + Drehung)
function DrillModels.groupFrame(g: Group): CFrame
	local q = g.quaternion
	return CFrame.new(g.position) * CFrame.new(0, 0, 0, q[1], q[2], q[3], q[4])
end

-- Größe im Spiel (Felix 2026-10-29, Richtwerte): MK1 so lang wie das gelieferte L15 (6,64),
-- MK20 so lang wie das alte mittlere Drill-Modell (MK2, 19,6), danach weiter wachsend bis MK30 = 30
-- Studs. Dazwischen gleichmäßiges (geometrisches) Wachstum der Länge. TODO_LAYOUT
local LENGTH_FIRST, LENGTH_MID, LENGTH_LAST = 6.64, 19.6, 30
local MID_TIER = 20

function DrillModels.targetLength(tier: number): number
	local t = math.clamp(tier, 1, #data)
	if t <= MID_TIER then
		return LENGTH_FIRST * (LENGTH_MID / LENGTH_FIRST) ^ ((t - 1) / (MID_TIER - 1))
	end
	return LENGTH_MID * (LENGTH_LAST / LENGTH_MID) ^ ((t - MID_TIER) / (#data - MID_TIER))
end

-- Vergrößerung der Vorlage je Stufe (gleichmäßig in alle Richtungen)
function DrillModels.scale(tier: number): number
	local e = data[math.clamp(tier, 1, #data)]
	return DrillModels.targetLength(tier) / e.size.X
end

-- Abstand Bohrspitze und Rückseite zum Ursprung entlang der Bohrrichtung (Studs, vergrößert)
function DrillModels.tipDistance(tier: number): number
	local e = data[math.clamp(tier, 1, #data)]
	return (e.center.X + e.size.X / 2) * DrillModels.scale(tier)
end

function DrillModels.rearDistance(tier: number): number
	local e = data[math.clamp(tier, 1, #data)]
	return (e.size.X / 2 - e.center.X) * DrillModels.scale(tier)
end

return table.freeze(DrillModels)
