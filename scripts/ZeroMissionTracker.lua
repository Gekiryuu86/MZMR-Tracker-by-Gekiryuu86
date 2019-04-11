-- Path to the directory containing the sprites for the tracker.
local IMAGES_ROOT = "B:\\BizHawk 2.0 testing\\Lua\\GBA\\ZMTracker\\";
-- Should powerups display in world. Usually leave to 0.
local SHOW_POWERUPS_ON_WORLD = 0;
-- Should the tracker render in a new window.
local SHOW_POWERUPS_ON_CANVAS = 1;
-- Toggles debug output on screen.
local DEBUG = 0;
--  Frame interval at which samus's powerup state is polled
local UPDATE_INTERVAL = 10;

-- ------------------------------------------------------------- --
-- DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING --
-- ------------------------------------------------------------- --

-- TODO: Detect U, J, etc, and fix base accordingly (read program code in rom header?)
local SAMUS_BASE = 0x03001530; -- U

local MAX_HEALTH_OFFSET       = SAMUS_BASE + 0x00;
local MAX_MISSILES_OFFSET     = SAMUS_BASE + 0x02;
local MAX_SUPERS_OFFSET       = SAMUS_BASE + 0x04;
local MAX_POWER_BOMB_OFFSET   = SAMUS_BASE + 0x05;

local BEAM_BOMB_STATUS        = SAMUS_BASE + 0x0C;
local SUIT_STATUS             = SAMUS_BASE + 0x0E;

local DIFFICULTY_FLAG         = 0x0300002C;

local LONG_BEAM_COLLECTED     = 0x1;
local ICE_BEAM_COLLECTED      = 0x2;
local WAVE_BEAM_COLLECTED     = 0x4;
local PLASMA_BEAM_COLLECTED   = 0x8;
local CHARGE_BEAM_COLLECTED   = 0x10;
local UNKNOWN_0_COLLECTED     = 0x20;
local UNKNOWN_1_COLLECTED     = 0x40;
local BOMBS_COLLECTED         = 0x80;

local HI_JUMP_COLLECTED       = 0x1;
local SPEED_BOOSTER_COLLECTED = 0x2;
local SPACE_JUMP_COLLECTED    = 0x4;
local SCREW_ATTACK_COLLECTED  = 0x8;
local VARIA_COLLECTED         = 0x10;
local GRAVITY_COLLECTED       = 0x20;
local MORPH_BALL_COLLECTED    = 0x40;
local POWER_GRIP_COLLECTED    = 0x80;

local POWERUP_DATA = { };
    POWERUP_DATA["MB1.png"] = { flag = MORPH_BALL_COLLECTED,    test = 2, x = 3,   y = 41 };
    POWERUP_DATA["B1.png"]  = { flag = BOMBS_COLLECTED,         test = 1, x = 42,  y = 41 };

    POWERUP_DATA["LB1.png"] = { flag = LONG_BEAM_COLLECTED,     test = 1, x = 3,   y = 3 };
    POWERUP_DATA["CB1.png"] = { flag = CHARGE_BEAM_COLLECTED,   test = 1, x = 41,  y = 3 };
    POWERUP_DATA["IB1.png"] = { flag = ICE_BEAM_COLLECTED,      test = 1, x = 79,  y = 3 };
    POWERUP_DATA["WB1.png"] = { flag = WAVE_BEAM_COLLECTED,     test = 1, x = 117, y = 3 };
    POWERUP_DATA["PB1.png"] = { flag = PLASMA_BEAM_COLLECTED,   test = 1, x = 155, y = 3 };

    POWERUP_DATA["HJ1.png"] = { flag = HI_JUMP_COLLECTED,       test = 2, x = 155, y = 41 };
    POWERUP_DATA["SB1.png"] = { flag = SPEED_BOOSTER_COLLECTED, test = 2, x = 117, y = 41 };
    POWERUP_DATA["PG1.png"] = { flag = POWER_GRIP_COLLECTED,    test = 2, x = 83,  y = 41 };

    POWERUP_DATA["SJ1.png"] = { flag = SPACE_JUMP_COLLECTED,    test = 2, x = 55,  y = 79 };
    POWERUP_DATA["SA1.png"] = { flag = SCREW_ATTACK_COLLECTED,  test = 2, x = 16,  y = 79 };
    POWERUP_DATA["VS1.png"] = { flag = VARIA_COLLECTED,         test = 2, x = 103, y = 80 };
    POWERUP_DATA["GS1.png"] = { flag = GRAVITY_COLLECTED,       test = 2, x = 144, y = 80 };

local paintCanvas = null;
if (SHOW_POWERUPS_ON_CANVAS ~= 0) then
    paintCanvas = gui.createcanvas(190, 192);
	paintCanvas.DrawImage(IMAGES_ROOT .. "CBG.png", 0, 0);
end

while true do

	-- Only update every 10 or so frame (not sure if rendering the tracker is causing lag, let's avoid it doing so best we can)
	if ((emu.framecount() % UPDATE_INTERVAL) ~= 0) then
		emu.frameadvance();
	end
	
	-- TODO: Clear if we are in the menu / dead screen

    -- Difficulty flag 0x2 is hard mode
    local difficultyFlag = memory.read_u8(DIFFICULTY_FLAG);

    local eTanks = (memory.read_u16_le(MAX_HEALTH_OFFSET) + 1) / (difficultyFlag == 2 and 50 or 100) - 1;
    local mTanks = memory.read_u16_le(MAX_MISSILES_OFFSET) / (difficultyFlag == 2 and 2 or 5);
    local sTanks = memory.read_u8(MAX_SUPERS_OFFSET) / (difficultyFlag == 2 and 1 or 2);
    local pbTanks = memory.read_u8(MAX_POWER_BOMB_OFFSET) / (difficultyFlag == 2 and 1 or 2);

	local status = {};
    status[1] = memory.read_u8(BEAM_BOMB_STATUS);
    status[2] = memory.read_u8(SUIT_STATUS);

    if (DEBUG ~= 0) then
        gui.text(0, 0, "Energy tanks: " .. eTanks, null, null);
        gui.text(0, 13, "Missile tanks: " .. mTanks, null, null);
        gui.text(0, 26, "Super tanks: " .. sTanks, null, null);
        gui.text(0, 39, "Power bomb tanks: " .. pbTanks, null, null);
        gui.text(0, 52, "Beam bomb status: ".. string.format("0x%x", status[1]), null, null);
        gui.text(0, 65, "Suit status: " .. string.format("0x%x", status[2]), null, null);
    end

    local itr = 0;
    local canvasCleared = false;
    for imageNameBase, flagValue in pairs(POWERUP_DATA)
    do
        local powerupObtained = bit.band(flagValue.flag, status[flagValue.test]);
        if (powerupObtained ~= 0) then

            local imageName = IMAGES_ROOT .. imageNameBase;

            if (SHOW_POWERUPS_ON_WORLD ~= 0) then
                gui.drawImage(imageName, 2 + itr * 16, client.bufferheight() - 16 - 2, 16, 16);
                itr = itr + 1;
            end

            if (SHOW_POWERUPS_ON_CANVAS ~= 0) then
                if (canvasCleared == false) then
                    paintCanvas.DrawImage(IMAGES_ROOT .. "CBG.png", 0, 0);
                    canvasCleared = true;
                end

                paintCanvas.DrawImage(imageName, flagValue.x, flagValue.y);
            end

        end
    end
	
	if (SHOW_POWERUPS_ON_CANVAS ~= 0) then
		if (eTanks > 0) then
			paintCanvas.DrawImage(IMAGES_ROOT .. "etank.png", 3, 119);
			paintCanvas.DrawText(40, 124, eTanks, "white", "clear", 20, "Consolas", "bold");
		end
		
		if (mTanks > 0) then
			paintCanvas.DrawImage(IMAGES_ROOT .. "missile.png", 98, 119);
			paintCanvas.DrawText(135, 124, mTanks, "white", "clear", 20, "Consolas", "bold");
		end

		if (sTanks > 0) then
			paintCanvas.DrawImage(IMAGES_ROOT .. "smissile.png", 98, 157);
			paintCanvas.DrawText(135, 162, sTanks, "white", "clear", 20, "Consolas", "bold");
		end
		
		if (pbTanks > 0) then
			paintCanvas.DrawImage(IMAGES_ROOT .. "pbomb.png", 3, 157);
			paintCanvas.DrawText(40, 162, pbTanks, "white", "clear", 20, "Consolas", "bold");
		end
	
		paintCanvas.Refresh();
	end

	emu.frameadvance();
end