local version = "1.0"

--[[

	
		db   dD  .d8b.  d888888b  .d8b.  d8888b. d888888b d8b   db  .d8b.  
		88 ,8P' d8' `8b `~~88~~' d8' `8b 88  `8D   `88'   888o  88 d8' `8b 
		88,8P   88ooo88    88    88ooo88 88oobY'    88    88V8o 88 88ooo88 
		88`8b   88~~~88    88    88~~~88 88`8b      88    88 V8o88 88~~~88 
		88 `88. 88   88    88    88   88 88 `88.   .88.   88  V888 88   88 
		YP   YD YP   YP    YP    YP   YP 88   YD Y888888P VP   V8P YP   YP 


	Script - Katarina - The Sinister Blade 2.1.0 by Skeem and Roach
	http://botoflegends.com/forum/topic/7129-script-katarina-the-sinister-blade-2118-apr-2nd/

	Changelog :
   1.0	 - Initial Release

  	]] --

-- / Hero Name Check / --
if myHero.charName ~= "Katarina" then return end
-- / Hero Name Check / --

-- / Auto-Update Function / --
local Kata_Autoupdate = true
local UPDATE_SCRIPT_NAME = "Katarlna"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/UglyOldGuy/BoL/master/Katarina%20-%20The%20Sinister%20Blade.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#FF0000\">"..UPDATE_SCRIPT_NAME..":</font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if Kata_Autoupdate then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
-- / Auto-Update Function / --

-- / Loading Function / --
function OnLoad()
	--->
		Variables()
		KatarinaMenu()
	---<
end
-- / Loading Function / --

-- / Tick Function / --
function OnTick()
	--->
		Checks()
		DamageCalculation()
		UseConsumables()

		if Target then
			if KatarinaMenu.harass.wharass and not SkillR.castingUlt then CastW(Target) end
			if KatarinaMenu.killsteal.Ignite then AutoIgnite(Target) end
		end
		
		if KatarinaMenu.combo.autoE then
			for _, enemy in pairs(enemyHeroes) do
				if ValidTarget(enemy) and enemy ~= nil and GetDistanceSqr(enemy) > SkillR.range*SkillR.range and GetDistanceSqr(enemy) <= SkillE.range*SkillE.range and SkillR.castingUlt then
					CastE(enemy)
				end
			end
		end
		
	---<
	-- Menu Variables --
	--->
		ComboKey =	 KatarinaMenu.combo.comboKey
		FarmingKey =   KatarinaMenu.farming.farmKey
		HarassKey =	KatarinaMenu.harass.harassKey
		ClearKey =	 KatarinaMenu.clear.clearKey
		WardJumpKey =  KatarinaMenu.misc.wardJumpKey
	---<
	-- Menu Variables --
	--->
		if ComboKey then
			FullCombo()
		end
		if HarassKey then
			HarassCombo()
		end
		if FarmingKey and not ComboKey then
			Farm()
		end
		if ClearKey then
			MixedClear()
		end	
		if WardJumpKey then
			moveToCursor()
			local WardPos = GetDistanceSqr(mousePos) <= SkillWard.range*SkillWard.range and mousePos or getMousePos()
			wardJump(WardPos.x, WardPos.z)
		end
		if KatarinaMenu.killsteal.smartKS then
			KillSteal()
		end
		if KatarinaMenu.misc.AutoLevelSkills == 1 then
			if myHero.level == 6 or myHero.level == 11 or myHero.level == 16 then
				LevelSpell(_R)
			end
		else
			autoLevelSetSequence(levelSequence[KatarinaMenu.misc.AutoLevelSkills-1])
		end
		if KatarinaMenu.misc.jumpAllies then
			DangerCheck()
		end
	---<
end
-- / Tick Function / --

-- / Variables Function / --
function Variables()
	--- Skills Vars --
	--->
		SkillQ =	{range = 675, name = "Bouncing Blades",	ready = false,	delay = 400,	projSpeed = 1400,	timeToHit = 0,	markDelay = 4000,	color = ARGB(255,178, 0 , 0 )	}
		SkillW =	{range = 375, name = "Sinister Steel",	ready = false,																			color = ARGB(255, 32,178,170)	}
		SkillE =	{range = 700, name = "Shunpo",			ready = false,																			color = ARGB(255,128, 0 ,128)	}
		SkillR =	{range = 550, name = "Death Lotus",		ready = false,					castingUlt = false,																		}
		SkillWard = {range = 600, lastJump = 0,				itemSlot = nil																											}
	---<
	--- Skills Vars ---
	--- Items Vars ---
	--->
		Items =
		{
					HealthPot		= {ready = false},
					FlaskPot		= {ready = false},
					TrinketWard		= {ready = false},
					RubySightStone	= {ready = false},
					SightStone		= {ready = false},
					SightWard		= {ready = false},
					VisionWard		= {ready = false}
		}
	---<
	--- Items Vars ---
	--- Orbwalking Vars ---
	--->
		lastAttack = 0
		lastAttackCD = 0
		lastWindUpTime = 0
	---<
	--- Orbwalking Vars ---
	--- TickManager Vars ---
	--->
		TManager =
		{
			onTick	= TickManager(20),
			onDraw	= TickManager(80),
			onSpell	= TickManager(15)
		}
	---<
	--- TickManager Vars ---
	if VIP_USER then
		--- LFC Vars ---
		--->
			_G.oldDrawCircle = rawget(_G, 'DrawCircle')
			_G.DrawCircle = DrawCircle2
		---<
		--- LFC Vars ---
	end
	--- Drawing Vars ---
	--->
		TextList = {"Harass him", "Q = Kill", "W = Kill", "E = Kill!", "Q+W = Kill", "Q+E = Kill", "E+W = Kill", "Q+E+W = Kill", "Q+E+W+Itm = Kill", "Q+W+E+R: ", "Need CDs"}
		KillText = {}
		colorText = ARGB(255,255,204,0)
		wardColor =
		{
					available	= ARGB(255,255,255,255),
					searching	= ARGB(255,250,123, 20),
					unavailable	= ARGB(255,255, 0 , 0 )
		}
	---<
	--- Drawing Vars ---
	--- Misc Vars ---
	--->
		levelSequence = {
			{ 1,3,2,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3 }, -- Prioritise Q
			{ 1,3,2,2,2,4,2,1,2,1,4,1,1,3,3,4,3,3 }  -- Prioritise W
		}
		UsingHPot = false
		gameState = GetGame()
		if gameState.map.shortName == "twistedTreeline" then
			TTMAP = true
		else
			TTMAP = false
		end
	---<
	--- Misc Vars ---
	--- Tables ---
	--->
		Wards = {}
		allyHeroes = GetAllyHeroes()
		enemyHeroes = GetEnemyHeroes()
		enemyMinions = minionManager(MINION_ENEMY, SkillE.range, player, MINION_SORT_HEALTH_ASC)
		allyMinions = minionManager(MINION_ALLY, SkillE.range, player, MINION_SORT_HEALTH_ASC)
		JungleMobs = {}
		JungleFocusMobs = {}
		priorityTable = {
			AP = {
				"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
				"Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
				"Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra"
			},
			Support = {
				"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean"
			},
			Tank = {
				"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Nautilus", "Shen", "Singed", "Skarner", "Volibear",
				"Warwick", "Yorick", "Zac"
			},
			AD_Carry = {
				"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "KogMaw", "Lucian", "MasterYi", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
				"Talon","Tryndamere", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Yasuo","Zed"
			},
			Bruiser = {
				"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy",
				"Renekton", "Rengar", "Riven", "Rumble", "Shyvana", "Trundle", "Udyr", "Vi", "MonkeyKing", "XinZhao"
			}
		}
		if TTMAP then --
			FocusJungleNames = {
				["TT_NWraith1.1.1"] = true,
				["TT_NGolem2.1.1"] = true,
				["TT_NWolf3.1.1"] = true,
				["TT_NWraith4.1.1"] = true,
				["TT_NGolem5.1.1"] = true,
				["TT_NWolf6.1.1"] = true,
				["TT_Spiderboss8.1.1"] = true
			}		
			JungleMobNames = {
				["TT_NWraith21.1.2"] = true,
				["TT_NWraith21.1.3"] = true,
				["TT_NGolem22.1.2"] = true,
				["TT_NWolf23.1.2"] = true,
				["TT_NWolf23.1.3"] = true,
				["TT_NWraith24.1.2"] = true,
				["TT_NWraith24.1.3"] = true,
				["TT_NGolem25.1.1"] = true,
				["TT_NWolf26.1.2"] = true,
				["TT_NWolf26.1.3"] = true
			}
		else 
			JungleMobNames = { 
				["Wolf8.1.2"] = true,
				["Wolf8.1.3"] = true,
				["YoungLizard7.1.2"] = true,
				["YoungLizard7.1.3"] = true,
				["LesserWraith9.1.3"] = true,
				["LesserWraith9.1.2"] = true,
				["LesserWraith9.1.4"] = true,
				["YoungLizard10.1.2"] = true,
				["YoungLizard10.1.3"] = true,
				["SmallGolem11.1.1"] = true,
				["Wolf2.1.2"] = true,
				["Wolf2.1.3"] = true,
				["YoungLizard1.1.2"] = true,
				["YoungLizard1.1.3"] = true,
				["LesserWraith3.1.3"] = true,
				["LesserWraith3.1.2"] = true,
				["LesserWraith3.1.4"] = true,
				["YoungLizard4.1.2"] = true,
				["YoungLizard4.1.3"] = true,
				["SmallGolem5.1.1"] = true
			}
			FocusJungleNames = {
				["Dragon6.1.1"] = true,
				["Worm12.1.1"] = true,
				["GiantWolf8.1.1"] = true,
				["AncientGolem7.1.1"] = true,
				["Wraith9.1.1"] = true,
				["LizardElder10.1.1"] = true,
				["Golem11.1.2"] = true,
				["GiantWolf2.1.1"] = true,
				["AncientGolem1.1.1"] = true,
 				["Wraith3.1.1"] = true,
				["LizardElder4.1.1"] = true,
				["Golem5.1.2"] = true,
				["GreatWraith13.1.1"] = true,
				["GreatWraith14.1.1"] = true
			}
		end
		for i = 0, objManager.maxObjects do
			local object = objManager:getObject(i)
			if object and object.valid and not object.dead then
				if FocusJungleNames[object.name] then
					JunglefocusMobs[#JungleFocusMobs+1] = object
				elseif JungleMobNames[object.name] then
					JungleMobs[#JungleMobs+1] = object
				end
			end
		end
	---<
	--- Tables ---
end
-- / Variables Function / --

-- / Menu Function / --
function KatarinaMenu()
	--- Main Menu ---
	--->
		KatarinaMenu = scriptConfig("Katarina - The Sinister Blade", "Katarina")
		---> Combo Menu
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
			KatarinaMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
			KatarinaMenu.combo:addParam("stopUlt", "Stop "..SkillR.name.." (R) If Target Can Die", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.combo:addParam("autoE", "Auto E if not in "..SkillR.name.." (R) Range while Ult", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.combo:addParam("detonateQ", "Try to Proc "..SkillQ.name.." (Q) Mark", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.combo:addParam("comboOrbwalk", "Orbwalk in Combo", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.combo:permaShow("comboKey")
		---<
		---> Harass Menu
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
			KatarinaMenu.harass:addParam("harassKey", "Harass Hotkey (T)", SCRIPT_PARAM_ONKEYDOWN, false, 84)
			KatarinaMenu.harass:addParam("hMode", "Harass Mode", SCRIPT_PARAM_LIST, 1, { "Q+E+W", "Q+W" })
			KatarinaMenu.harass:addParam("detonateQ", "Proc Q Mark", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.harass:addParam("wharass", "Always "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.harass:addParam("harassOrbwalk", "Orbwalk in Harass", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.harass:permaShow("harassKey")
		---<
		---> Farming Menu
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
			KatarinaMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, 90)
			KatarinaMenu.farming:addParam("qFarm", "Farm with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.farming:addParam("wFarm", "Farm with "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.farming:addParam("eFarm", "Farm with "..SkillE.name.." (E)", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.farming:permaShow("farmKey")
		---<
		---> Clear Menu		
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "clear")
			KatarinaMenu.clear:addParam("clearKey", "Jungle/Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
			KatarinaMenu.clear:addParam("JungleFarm", "Use Skills to Farm Jungle", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("ClearLane", "Use Skills to Clear Lane", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("clearQ", "Clear with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("clearW", "Clear with "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("clearE", "Clear with "..SkillE.name.." (E)", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("clearOrbM", "OrbWalk Minions", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.clear:addParam("clearOrbJ", "OrbWalk Jungle", SCRIPT_PARAM_ONOFF, true)
		---<
		---> KillSteal Menu
		KatarinaMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "killsteal")
			KatarinaMenu.killsteal:addParam("smartKS", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
			-- KatarinaMenu.killsteal:addParam("wardKS", "Use Wards to KS", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.killsteal:addParam("ultKS", "Use "..SkillR.name.." (R) to KS", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.killsteal:addParam("itemsKS", "Use Items to KS", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.killsteal:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.killsteal:permaShow("smartKS")
		---<
		---> Drawing Menu			
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")
			if VIP_USER then
				KatarinaMenu.drawing:addSubMenu("["..myHero.charName.." - LFC Settings]", "lfc")
					KatarinaMenu.drawing.lfc:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
					KatarinaMenu.drawing.lfc:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 300, 75, 2000, 0)
					KatarinaMenu.drawing.lfc:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
			end
			KatarinaMenu.drawing:addParam("disableAll", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.drawing:addParam("drawText", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.drawing:addParam("drawTargetText", "Draw Who I'm Targetting", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.drawing:addParam("drawQ", "Draw Bouncing Blades (Q) Range", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.drawing:addParam("drawW", "Draw Sinister Steel (W) Range", SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.drawing:addParam("drawE", "Draw Shunpo (E) Range", SCRIPT_PARAM_ONOFF, false)
		---<
		---> Misc Menu	
		KatarinaMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
			KatarinaMenu.misc:addParam("wardJumpKey", "Ward Jump Hotkey (G)", SCRIPT_PARAM_ONKEYDOWN, false, 71)
			KatarinaMenu.misc:addParam("jumpAllies", "Jump To Allies if In Danger", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.misc:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.misc:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
			KatarinaMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
			KatarinaMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			KatarinaMenu.misc:addParam("uTM", "Use Tick Manager/FPS Improver",SCRIPT_PARAM_ONOFF, false)
			KatarinaMenu.misc:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_LIST, 1, { "No", "Prioritise Q", "Prioritise W"  })
			KatarinaMenu.misc:permaShow("wardJumpKey")
		---<
		---> Target Selector		
			TargetSelector = TargetSelector(TARGET_LESS_CAST, SkillE.range, DAMAGE_MAGIC, true)
			TargetSelector.name = "Katarina"
			KatarinaMenu:addTS(TargetSelector)
		---<
		---> Arrange Priorities
			if heroManager.iCount < 10 then -- borrowed from Sidas Auto Carry, modified to 3v3
	   			PrintChat(" >> Too few champions to arrange priority")
			elseif heroManager.iCount == 6 and TTMAP then
				ArrangeTTPriorities()
			else
				ArrangePriorities()
			end
		---<
	---<
	--- Main Menu ---
end
-- / Menu Function / --

-- / Full Combo Function / --
function FullCombo()
	--- Combo While Not Channeling --
	--->
		if not SkillR.castingUlt then
			if ValidTarget(Target) and Target ~= nil then
				if KatarinaMenu.combo.comboOrbwalk then
					OrbWalking(Target)
				end
				if KatarinaMenu.combo.comboItems then
					UseItems(Target)
				end
				CastQ(Target)
				if KatarinaMenu.combo.detonateQ and GetTickCount() >= SkillQ.timeToHit then
					if not SkillQ.ready then CastE(Target) end
					if not SkillE.ready then CastW(Target) end
				elseif not KatarinaMenu.combo.detonateQ then
					CastE(Target)
					CastW(Target)
				end
				CastR()
			else
				if KatarinaMenu.combo.comboOrbwalk then
					moveToCursor()
				end
			end
		end
	---<
	--- Combo While Not Channeling --
end
-- / Full Combo Function / --

-- / Harass Combo Function / --
function HarassCombo()
	--- Smart Harass --
	--->
		if ValidTarget(Target) and Target ~= nil then
			if KatarinaMenu.harass.harassOrbwalk then
				OrbWalking(Target)
			end
			--- Harass Mode 1 Q+W+E ---
			if KatarinaMenu.harass.hMode == 1 then
				CastQ(Target)
				if KatarinaMenu.harass.detonateQ and GetTickCount() >= SkillQ.timeToHit then
					if not SkillQ.ready then CastE(Target) end
					if not SkillE.ready then CastW(Target) end
				elseif not KatarinaMenu.harass.detonateQ then
					CastE(Target)
					CastW(Target)
				end
			end
			--- Harass Mode 1 ---
			--- Harass Mode 2 Q+W ---
			if KatarinaMenu.harass.hMode == 2 then
				CastQ(Target)
				CastW(Target)
			end
			--- Harass Mode 2 ---
		else
			if KatarinaMenu.harass.harassOrbwalk then
				moveToCursor()
			end
		end
	---<
	--- Smart Harass ---
end
-- / Harass Combo Function / --

-- / Farm Function / --
function Farm()
	--->
		for _, minion in pairs(enemyMinions.objects) do
			--- Minion Damages ---
			local pMinionDmg = getDmg("Q", minion, myHero, 2)
			local qMinionDmg = getDmg("Q", minion, myHero)
			local wMinionDmg = getDmg("W", minion, myHero)
			local eMinionDmg = getDmg("E", minion, myHero)
			--- Minion Damages ---
			--- Minion Keys ---
			local qFarmKey = KatarinaMenu.farming.qFarm
			local wFarmKey = KatarinaMenu.farming.wFarm
			local eFarmKey = KatarinaMenu.farming.eFarm
			--- Minion Keys ---
			--- Farming Minions ---
			if ValidTarget(minion) and minion ~= nil then
				if GetDistanceSqr(minion) <= SkillW.range*SkillW.range then
					if qFarmKey and wFarmKey then
						if SkillQ.ready and SkillW.ready then
							if minion.health <= (pMinionDmg + qMinionDmg + wMinionDmg) and minion.health > wMinionDmg then
								CastQ(minion)
								CastSpell(_W)
							end
						elseif SkillW.ready then
							if minion.health <= (wMinionDmg) then
								CastSpell(_W)
							end
						elseif SkillQ.ready and not SkillW.ready then
							if minion.health <= (qMinionDmg) then
								CastQ(minion)
							end
						end
					elseif qFarmKey and not wFarmKey then
						if SkillQ.ready then
							if minion.health <= (qMinionDmg) then
								CastQ(minion)
							end
						end
					elseif not qFarmKey and wFarmKey then
						if SkillW.ready then
							if minion.health <= (wMinionDmg) then
								CastSpell(_W)
							end
						end
					end
				elseif (GetDistanceSqr(minion) > SkillW.range*SkillW.range) then
					if qFarmKey then
						if minion.health <= qMinionDmg and (GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range) then
							CastQ(minion)
						end
					end
					if eFarmKey then
						if minion.health <= eMinionDmg and (GetDistanceSqr(minion) <= SkillE.range*SkillE.range) then
							CastE(minion)
						end
					end
				end
			end
			break
		end
		--- Farming Minions ---
	---<
end
-- / Farm Function / --

-- / Clear Function / --
function MixedClear()
	--- Jungle Clear ---
	--->
		if KatarinaMenu.clear.JungleFarm then
			local JungleMob = GetJungleMob()
			if JungleMob ~= nil then
				if KatarinaMenu.clear.clearOrbJ then
					OrbWalking(JungleMob)
				end
				if KatarinaMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(JungleMob) <= SkillQ.range*SkillQ.range then
					CastQ(JungleMob)
				end
				if KatarinaMenu.clear.clearW and SkillW.ready and GetDistanceSqr(JungleMob) <= SkillW.range*SkillW.range then
					CastSpell(_W)
				end
				if KatarinaMenu.clear.clearE and SkillE.ready and GetDistanceSqr(JungleMob) <= SkillE.range*SkillE.range then
					CastE(JungleMob)
				end
			else
				if KatarinaMenu.clear.clearOrbJ then
					moveToCursor()
				end
			end
		end
	---<
	--- Jungle Clear ---
	--- Lane Clear ---
	--->
		if KatarinaMenu.clear.ClearLane then
			for _, minion in pairs(enemyMinions.objects) do
				if  ValidTarget(minion) and minion ~= nil then
					if KatarinaMenu.clear.clearOrbM then
						OrbWalking(minion)
					end
					if KatarinaMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range then
						CastQ(minion)
					end
					if KatarinaMenu.clear.clearW and SkillW.ready and GetDistanceSqr(minion) <= SkillW.range*SkillW.range then
						CastSpell(_W)
					end
					if KatarinaMenu.clear.clearE and SkillE.ready and GetDistanceSqr(minion) <= SkillE.range*SkillE.range then 
						CastE(minion)
					end
				else
					if KatarinaMenu.clear.clearOrbM then
						moveToCursor()
					end
				end
			end
		end
	---<
	--- Lane Clear ---
end
-- / Clear Function / --

-- / Casting Q Function / --
function CastQ(enemy)
	--- Dynamic Q Cast ---
	--->
		if not SkillQ.ready or (GetDistanceSqr(enemy) > SkillQ.range*SkillQ.range) then
			return false
		end
		if ValidTarget(enemy) and enemy ~= nil then 
			if VIP_USER then
				Packet("S_CAST", {spellId = _Q, targetNetworkId = enemy.networkID}):send()
				return true
			else
				CastSpell(_Q, enemy)
				return true
			end
			if SkillQ.timeToHit == 0 or GetTickCount() >= SkillQ.timeToHit then
				SkillQ.timeToHit = GetTickCount() + (SkillQ.delay + (GetDistance(myHero, enemy) / SkillQ.projSpeed))
				return true
			end
		end
		return false
	---<
	--- Dynamic Q Cast ---
end
-- / Casting Q Function / --

-- / Casting E Function / --
function CastE(enemy)
	--- Dynamic E Cast ---
	--->
		if not SkillE.ready or (GetDistanceSqr(enemy) > SkillE.range*SkillE.range) then
			return false
		end
		if ValidTarget(enemy) and enemy ~= nil then 
			if VIP_USER then
				Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
				return true
			else
				CastSpell(_E, enemy)
				return true
			end
		end
		return false
	---<
	--- Dynamic E Cast ---
end
-- / Casting E Function / --

-- / Casting W Function / --
function CastW(enemy)
	--- Dynamic W Cast ---
	--->
		if not SkillW.ready or (GetDistanceSqr(enemy) > SkillW.range*SkillW.range) then
			return false
		end
		if ValidTarget(enemy) and enemy ~= nil then
			CastSpell(_W)
			return true
		end
		return false
	---<
	--- Dynamic W Cast ---
end
-- / Casting W Function / --

-- / Casting R Function / --
function CastR()
	--- Dynamic R Cast ---
	--->
		if (SkillQ.ready or SkillW.ready or SkillE.ready or SkillR.castingUlt) or not SkillR.ready then
			return false
		end
		if CountEnemyHeroInRange(SkillR.range) >= 1 then
			CastSpell(_R)
			SkillR.castingUlt = true
		end
	---<
	--- Dymanic R Cast --
end
-- / Casting R Function / --

-- / Ward Jumping Function / --
function wardJump(x, y)
	--->
		if SkillE.ready then
			local Jumped = false
			local WardDistance = 300
			for _, ally in pairs(allyHeroes) do
				if ValidTarget(ally, SkillE.range, false) and ally ~= nil then
					if GetDistanceSqr(ally, mousePos) <= WardDistance*WardDistance then
						CastSpell(_E, ally)
						Jumped = true
						SkillWard.lastJump = GetTickCount() + 2000
					end
				end
			end
			for _, minion in pairs(allyMinions.objects) do
				if ValidTarget(minion, SkillE.range, false) and minion ~= nil then
					if GetDistanceSqr(minion, mousePos) <= WardDistance*WardDistance then
						CastSpell(_E, minion)
						Jumped = true
						SkillWard.lastJump = GetTickCount() + 2000
					end
				end
			end
			for _, minion in pairs(enemyMinions.objects) do
				if ValidTarget(minion, SkillE.range, false) and minion ~= nil then
					if GetDistanceSqr(minion, mousePos) <= WardDistance*WardDistance then
						CastSpell(_E, minion)
						Jumped = true
						SkillWard.lastJump = GetTickCount() + 2000
					end
				end
			end
			if next(Wards) ~= nil then
				for i, obj in pairs(Wards) do 
					if obj.valid then
						MousePos = getMousePos()
						if GetDistanceSqr(obj, MousePos) <= WardDistance*WardDistance then
							CastSpell(_E, obj)
							Jumped = true
							SkillWard.lastJump = GetTickCount() + 2000
						 end
					end
				end
			end
			
			if not Jumped and GetTickCount() >= SkillWard.lastJump then
				if Items.TrinketWard.ready then
					SkillWard.itemSlot = ITEM_7
				elseif Items.RubySightStone.ready then
					SkillWard.itemSlot = rstSlot
				elseif Items.SightStone.ready then 
					SkillWard.itemSlot = ssSlot
				elseif Items.SightWard.ready then
					SkillWard.itemSlot = swSlot
				elseif Items.VisionWard.ready then
					SkillWard.itemSlot = vwSlot
				end
				
				if SkillWard.itemSlot ~= nil then
					CastSpell(SkillWard.itemSlot, x, y)
					Jumped = true
					SkillWard.lastJump = GetTickCount() + 2000
					SkillWard.itemSlot = nil
				end
			end
		end
	---<
end
-- / Ward Jumping Function / --

-- / Use Items Function / --
function UseItems(enemy)
	--- Use Items (Will Improve Soon) ---
	--->
		if not enemy then
			enemy = Target
		end
		if ValidTarget(enemy) and enemy ~= nil then
			if dfgReady and GetDistanceSqr(enemy) <= 600*600 then CastSpell(dfgSlot, enemy) end
			if bftReady and GetDistanceSqr(enemy) <= 600*600 then CastSpell(bftSlot, enemy) end
			if hxgReady and GetDistanceSqr(enemy) <= 600*600 then CastSpell(hxgSlot, enemy) end
			if bwcReady and GetDistanceSqr(enemy) <= 450*450 then CastSpell(bwcSlot, enemy) end
			if brkReady and GetDistanceSqr(enemy) <= 450*450 then CastSpell(brkSlot, enemy) end
		end
	---<
	--- Use Items ---
end
-- / Use Items Function / --

function UseConsumables()
	--- Check if Zhonya/Wooglets Needed --
	--->
		if KatarinaMenu.misc.ZWItems and isLow('Zhonya') and Target and (znaReady or wgtReady) then
			CastSpell((wgtSlot or znaSlot))
		end
	---<
	--- Check if Zhonya/Wooglets Needed --
	--- Check if Potions Needed --
	--->
		if KatarinaMenu.misc.aHP and isLow('Health') and not (UsingHPot or UsingFlask) and (Items.HealthPot.ready or Items.FlaskPot.ready) then
			CastSpell((hpSlot or fskSlot))
		end
	---<
	--- Check if Potions Needed --
end	

-- / Auto Ignite Function / --
function AutoIgnite(enemy)
	--- Simple Auto Ignite ---
	--->
		if enemy.health <= iDmg and GetDistanceSqr(enemy) <= 600*600 then
			if iReady then CastSpell(ignite, enemy) end
		end
	---<
	--- Simple Auto Ignite ---
end
-- / Auto Ignite Function / --

-- / Damage Calculation Function / --
function DamageCalculation()
	--- Calculate our Damage On Enemies ---
	--->
 		for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and enemy ~= nil then
				dfgDmg, hxgDmg, bwcDmg, iDmg, bftDmg, liandrysDmg = 0, 0, 0, 0, 0, 0
				pDmg = ((SkillQ.ready and getDmg("Q", enemy, myHero, 2)) or 0)
				qDmg = ((SkillQ.ready and getDmg("Q",enemy,myHero)) or 0)
				wDmg = ((SkillW.ready and getDmg("W",enemy,myHero)) or 0)
				eDmg = ((SkillE.ready and getDmg("E",enemy,myHero)) or 0)
				rDmg = getDmg("R",enemy,myHero,3)
				dfgDmg = ((dfgReady and getDmg("DFG", enemy, myHero)) or 0)
				hxgDmg = ((hxgReady and getDmg("HXG", enemy, myHero)) or 0)
				bwcDmg = ((bwcReady and getDmg("BWC", enemy, myHero)) or 0)
				bftdmg = ((bftReady and getDmg("BLACKFIRE", enemy, myHero)) or 0)
				liandrysDmg = ((liandrysReady and getDmg("LIANDRYS", enemy, myHero)) or 0)
				iDmg = ((ignite and getDmg("IGNITE", enemy, myHero)) or 0)
				onspellDmg = liandrysDmg + bftDmg
				itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
	---<
	--- Calculate our Damage On Enemies ---
	--- Setting KillText Color & Text ---
	--->
				if enemy.health > (pDmg + qDmg + eDmg + wDmg + rDmg + itemsDmg) and itemsDmg ~= 0 then
					KillText[i] = 1
				elseif enemy.health <= qDmg then
					if SkillQ.ready then
						KillText[i] = 2
					else
						KillText[i] = 11
					end
				elseif enemy.health <= wDmg then
					if SkillW.ready then
						KillText[i] = 3
					else
						KillText[i] = 11
					end
				elseif enemy.health <= eDmg then
					if SkillE.ready then
						KillText[i] = 4
					else
						KillText[i] = 11
					end
				elseif enemy.health <= (qDmg + wDmg) and SkillQ.ready and SkillW.ready then
					if SkillQ.ready and SkillW.ready then
						KillText[i] = 5
					else
						KillText[i] = 11
					end
				elseif enemy.health <= (qDmg + eDmg) and SkillQ.ready and SkillE.ready then
					if SkillQ.ready and SkillE.ready then
						KillText[i] = 6
					else
						KillText[i] = 11
					end
				elseif enemy.health <= (wDmg + eDmg) and SkillW.ready and SkillE.ready then
					if SkillW.ready and SkillE.ready then
						KillText[i] = 7
					else
						KillText[i] = 11
					end
				elseif enemy.health <= (qDmg + wDmg + eDmg) and SkillQ.ready and SkillW.ready and SkillE.ready then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						KillText[i] = 8
					else
						KillText[i] = 11
					end
				elseif (enemy.health <= (qDmg + wDmg + eDmg + itemsDmg) or enemy.health <= (qDmg + pDmg + wDmg + eDmg + itemsDmg)) and SkillQ.ready and SkillW.ready and SkillE.ready then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						KillText[i] = 9
					else
						KillText[i] = 11
					end
				elseif enemy.health <= (qDmg + pDmg + wDmg + eDmg + rDmg + itemsDmg) then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						KillText[i] = 10
					else
						KillText[i] = 11
					end
				end
			end
		end
	---<
	--- Setting KillText Color & Text ---
end
-- / Damage Calculation Function / --

-- / KillSteal Function / --
function KillSteal()
	--- KillSteal No Wards ---
	--->
		for _, enemy in pairs(enemyHeroes) do
			if enemy ~= nil and ValidTarget(enemy) then
				local distance = GetDistanceSqr(enemy)
				local health = enemy.health
				if health <= qDmg and SkillQ.ready and (distance <= SkillQ.range*SkillQ.range) then
					CastQ(enemy)
				elseif health <= wDmg and SkillW.ready and (distance <= SkillW.range*SkillW.range) then
					CastW(enemy)
				elseif health <= eDmg and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
					CastE(enemy)
				elseif health <= (qDmg + wDmg) and SkillQ.ready and SkillW.ready and (distance <= SkillW.range*SkillW.range) then
					CastW(enemy)
				elseif health <= (qDmg + eDmg) and SkillQ.ready and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
					CastE(enemy)
				elseif health <= (wDmg + eDmg) and SkillW.ready and SkillE.ready and (distance <= SkillW.range*SkillW.range) then
					CastW(enemy)
				elseif health <= (qDmg + wDmg + eDmg) and SkillQ.ready and SkillW.ready and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
					CastE(enemy)
				elseif KatarinaMenu.killsteal.ultKS then
					if health <= (qDmg + pDmg + wDmg + eDmg + rDmg) and SkillQ.ready and SkillW.ready and SkillE.ready and SkillR.ready and (distance <= SkillE.range*SkillE.range) then
						CastE(enemy)
						CastQ(enemy)
						CastW(enemy)
						CastR()
					end
					if health <= rDmg and distance <= ((SkillR.range*SkillR.range) - 100) then
						CastR()
					end
				elseif KatarinaMenu.killsteal.itemsKS then
					if health <= (qDmg + pDmg + wDmg + eDmg + rDmg + itemsDmg) then
						if SkillQ.ready and SkillW.ready and SkillE.ready and SkillR.ready then
							UseItems(enemy)
						end
					elseif health <= (qDmg + wDmg + eDmg + itemsDmg) and health >= (qDmg + wDmg + eDmg) then
						if SkillQ.ready and SkillW.ready and SkillE.ready then
							UseItems(enemy)
						end
					end
				end
			end
		end
	---<
	--- KillSteal No Wards ---
end
-- / KillSteal Function / --

-- / Misc Functions / --
--- Danger Check ---
--->
	function DangerCheck()
		if isInDanger(myHero) and Target then
			for _, ally in pairs(allyHeroes) do
				if ValidTarget(Ally, SkillE.range, false) and Ally ~= nil then
					if GetDistance(Ally, Target) <= GetDistance(myHero, Target) then
						if SkillE.ready then CastSpell(_E, ally) end
					end
				end
			end
		end
	end
---<
--- Get Mouse Pos Function by Klokje ---
--->
	function getMousePos(range)
		local temprange = range or SkillWard.range
		local MyPos = Vector(myHero.x, myHero.y, myHero.z)
		local MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)

		return MyPos - (MyPos - MousePos):normalized() * SkillWard.range
	end
---<
--- Get Mouse Pos Function by Klokje ---
--- On Animation (Setting our last Animation) ---
--->
	function OnAnimation(unit, animationName)
		if unit == myHero then
			if animationName == "Spell4" then 
				SkillR.castingUlt = true
			else
				SkillR.castingUlt = false
			end
		end
	end
---<
--- On Animation (Setting our last Animation) ---
--- Checking if Hero in Danger ---
--->
	function isInDanger(hero)
		nEnemiesClose, nEnemiesFar = 0, 0
		hpPercent = hero.health / hero.maxHealth
		for _, enemy in pairs(enemyHeroes) do
				if not enemy.dead and hero:GetDistance(enemy) <= 200 then
						nEnemiesClose = nEnemiesClose + 1
						if hpPercent < 0.5 and hpPercent < enemy.health / enemy.maxHealth then return true end
				elseif not enemy.dead and hero:GetDistance(enemy) <= 1000 then
						nEnemiesFar = nEnemiesFar + 1
				end
		end
	   
		if nEnemiesClose > 1 then return true end
		if nEnemiesClose == 1 and nEnemiesFar > 1 then return true end
		return false
	end
---<
--- Checking if Hero in Danger ---
--- Get Jungle Mob Function by Apple ---
--->
	function GetJungleMob()
		for _, Mob in pairs(JungleFocusMobs) do
			if ValidTarget(Mob, SkillQ.range) then return Mob end
		end
		for _, Mob in pairs(JungleMobs) do
			if ValidTarget(Mob, SkillQ.range) then return Mob end
		end
	end
---<
--- Get Jungle Mob Function by Apple ---
--- Arrange Priorities 5v5 ---
--->
	function ArrangePriorities()
		for i, enemy in pairs(enemyHeroes) do
			SetPriority(priorityTable.AD_Carry, enemy, 1)
			SetPriority(priorityTable.AP, enemy, 2)
			SetPriority(priorityTable.Support, enemy, 3)
			SetPriority(priorityTable.Bruiser, enemy, 4)
			SetPriority(priorityTable.Tank, enemy, 5)
		end
	end
---<
--- Arrange Priorities 5v5 ---
--- Arrange Priorities 3v3 ---
--->
	function ArrangeTTPriorities()
		for i, enemy in pairs(enemyHeroes) do
			SetPriority(priorityTable.AD_Carry, enemy, 1)
			SetPriority(priorityTable.AP, enemy, 1)
			SetPriority(priorityTable.Support, enemy, 2)
			SetPriority(priorityTable.Bruiser, enemy, 2)
			SetPriority(priorityTable.Tank, enemy, 3)
		end
	end
---<
--- Arrange Priorities 3v3 ---
--- Set Priorities ---
--->
	function SetPriority(table, hero, priority)
		for i = 1, #table do
			if hero.charName:find(table[i]) ~= nil then
				TS_SetHeroPriority(priority, hero.charName)
			end
		end
	end
---<
--- Set Priorities ---
-- / Misc Functions / --

-- / On Send Packet Function / --
function OnSendPacket(p)
	-- Block Packets if Channeling --
	--->
		if SkillR.castingUlt and not WardJumpKey then
			if (p.header == Packet.headers.S_MOVE or p.header == Packet.headers.S_CAST) and (Packet(p):get('spellId') ~= SUMMONER_1 and Packet(p):get('spellId') ~= SUMMONER_2) then
				if KatarinaMenu.combo.stopUlt then
					if not SkillQ.ready and not SkillW.ready and not SkillE.ready and ValidTarget(Target) and Target ~= nil and Target.health > (qDmg + wDmg + eDmg) then
						-- PrintChat("Debug 1")
						Packet(p):Block()
					end
				end
				if KatarinaMenu.combo.autoE then
					if Packet(p):get('spellId') ~= SPELL_3 then
						-- PrintChat("Debug 2")
						Packet(p):Block()
					end
				end
				if not KatarinaMenu.combo.stopUlt and not KatarinaMenu.combo.autoE then
					-- PrintChat("Debug 3")
					Packet(p):Block()
				end
			end
		end
	---<
	--- Block Packets if Channeling --
end
-- / On Send Packet Function / --

-- / On Create Obj Function / --
function OnCreateObj(obj)
	--- All of Our Objects (CREATE) --
	-->
		if obj ~= nil then
			if (obj.name:find("katarina_deathLotus_mis.troy") or obj.name:find("katarina_deathLotus_tar.troy")) then
				if GetDistanceSqr(obj, myHero) <= 70*70 then
					SkillR.castingUlt = true
					--PrintChat("OnCreateObject: Casting Ult")
				end
			end
			if (obj.name:find("katarina_deathlotus_success.troy") or obj.name:find("Katarina_deathLotus_empty.troy")) then
				if GetDistanceSqr(obj, myHero) <= 70*70 then
					SkillR.castingUlt = true
					--PrintChat("OnCreateObject: Casting Ult")
				end
			end
			if obj.name:find("Global_Item_HealthPotion.troy") then
				if GetDistanceSqr(obj, myHero) <= 70*70 then
					UsingHPot = true
				end
			end
			if obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then 
				Wards[#Wards+1] = obj
			end
			if FocusJungleNames[obj.name] then
				JungleFocusMobs[#JungleFocusMobs+1] = obj
			elseif JungleMobNames[obj.name] then
				JungleMobs[#JungleMobs+1] = obj
			end
		end
	---<
	--- All of Our Objects (CREATE) --
end
-- / On Create Obj Function / --

-- / On Delete Obj Function / --
function OnDeleteObj(obj)
	--- All of Our Objects (CLEAR) --
	--->
		if obj ~= nil then
			if obj.name:find("TeleportHome.troy") then
				Recall = false
			end
			if obj.name:find("Global_Item_HealthPotion.troy") then
				UsingHPot = false
			end
			for i, Mob in pairs(JungleMobs) do
				if obj.name == Mob.name then
					table.remove(JungleMobs, i)
				end
			end
			for i, Mob in pairs(JungleFocusMobs) do
				if obj.name == Mob.name then
					table.remove(JungleFocusMobs, i)
				end
			end
			for i, ward in pairs(Wards) do
				if not ward.valid or (obj.name == ward.name and obj.x == ward.x and obj.z == ward.z) then
					table.remove(Wards, i)
				end
			end
		end
	--- All of Our Objects (CLEAR) --
	---<
end
--- All The Objects in The World Literally ---
-- / On Delete Obj Function / --

-- / On Draw Function / --
function OnDraw()
	--- Tick Manager Check ---
	--->
		if not TManager.onDraw:isReady() and KatarinaMenu.misc.uTM then return end
	---<
	--->
	--- Drawing Our Ranges ---
	--->
		if not myHero.dead then
			if not KatarinaMenu.drawing.disableAll then
				if SkillQ.ready and KatarinaMenu.drawing.drawQ then 
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, SkillQ.color)
				end
				if SkillW.ready and KatarinaMenu.drawing.drawW then
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, SkillW.color)
				end
				if SkillE.ready and KatarinaMenu.drawing.drawE then
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, SkillE.color)
				end
			end
		end
	---<
	--- Drawing Our Ranges ---
	--- Draw Enemy Damage Text ---
	--->
		if KatarinaMenu.drawing.drawText then
			for i = 1, heroManager.iCount do
				local enemy = heroManager:GetHero(i)
				if ValidTarget(enemy) and enemy ~= nil then
					local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z)) --(Credit to Zikkah)
					local PosX = barPos.x - 35
					local PosY = barPos.y - 10
					if KillText[i] ~= 10 then
						DrawText(TextList[KillText[i]], 16, PosX, PosY, colorText)
					else
						DrawText(TextList[KillText[i]] .. string.format("%4.1f", ((enemy.health - (qDmg + pDmg + wDmg + eDmg + itemsDmg)) * (1/rDmg)) * 2.5) .. "s = Kill", 16, PosX, PosY, colorText)
					end
				end
			end
		end
	---<
	--- Draw Enemy Damage Text ---
	--- Draw Enemy Target ---
	--->
		if Target then
			if KatarinaMenu.drawing.drawTargetText then
				DrawText("Targeting: " .. Target.charName, 12, 100, 100, colorText)
			end
		end
	---<
	--- Draw Enemy Target ---
	--- Draw Ward Jump Range and Mouse ---
	--->
		if WardJumpKey then
			if SkillE.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, SkillWard.range, 2, wardColor.available, 50)
				if GetDistanceSqr(mousePos) <= SkillWard.range*SkillWard.range then
					DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 50, 2, wardColor.available, 20)
				else
					DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 50, 2, wardColor.unavailable, 20)
				end
				if (GetDistanceSqr(mousePos) <= 700*700 and GetDistanceSqr(mousePos) > SkillWard.range*SkillWard.range) or not (Items.TrinketWard.ready or Items.RubySightStone.ready or Items.SightStone.ready or Items.VisionWard.ready) then
					DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 50, 2, wardColor.searching, 20)
				end
			else
				DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 50, 2, wardColor.unavailable, 20)
			end
		end
	---<
	--- Draw Ward Jump Range and Mouse ---
end
-- / On Draw Function / --

-- / OnWndMsg Function / --
function OnWndMsg(msg, key)
	if msg == WM_RBUTTONDOWN and SkillR.castingUlt then 
		SkillR.castingUlt = false
	end
end
-- / OnWndMsg Function / --

-- / OnGainBuff Function / --
function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == "katarinarsound" then
		SkillR.castingUlt = true
	end
end
-- / OnGainBuff Function / --

-- / OnLoseBuff Function / --
function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == "katarinarsound" then
		SkillR.castingUlt = false
	end
end
-- / OnLoseBuff Function / --

-- / OrbWalking Functions / --
--- Orbwalking Target ---
--->
	function OrbWalking(Target)
		if not SkillR.castingUlt then
			if TimeToAttack() and GetDistanceSqr(Target) <= (myHero.range + GetDistance(myHero.minBBox))*(myHero.range + GetDistance(myHero.minBBox)) then
				myHero:Attack(Target)
			elseif heroCanMove() then
				moveToCursor()
			end
		end
	end
---<
--- Orbwalking Target ---
--- Check When Its Time To Attack ---
--->
	function TimeToAttack()
		return (GetTickCount() + GetLatency() * .5 > lastAttack + lastAttackCD)
	end
---<
--- Check When Its Time To Attack ---
--- Prevent AA Canceling ---
--->
	function heroCanMove()
		return (GetTickCount() + GetLatency() * .5 > lastAttack + lastWindUpTime + 20)
	end
---<
--- Prevent AA Canceling ---
--- Move to Mouse ---
--->
	function moveToCursor()
		if GetDistance(mousePos) then
			local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
			if not VIP_USER then
				myHero:MoveTo(moveToPos.x, moveToPos.z)
			else
				Packet('S_MOVE', {x = moveToPos.x, y = moveToPos.z}):send()
			end
		end		
	end
---<
--- Move to Mouse ---
--- On Process Spell ---
--->
	function OnProcessSpell(object,spell)
		--- Tick Manager Check ---
		--->
			if not TManager.onSpell:isReady() and KatarinaMenu.misc.uTM then return end
		---<
		--->
			if object == myHero then
				if spell.name:lower():find("katarinar") then
					SkillR.castingUlt = true
				end

				if spell.name:lower():find("attack") then
					lastAttack = GetTickCount() - GetLatency()*0.5
					lastWindUpTime = spell.windUpTime*1000
					lastAttackCD = spell.animationTime*1000
				end
			end
		---<
	end
---<
--- On Process Spell ---
-- / OrbWalking Functions / --

-- / FPS Manager Functions / --
class 'TickManager'
--- TM Init Function ---
--->
	function TickManager:__init(ticksPerSecond)
		self.TPS = ticksPerSecond
		self.lastClock = 0
		self.currentClock = 0
	end
---<
--- TM Init Function ---
--- TM Type Function ---
--->
	function TickManager:__type()
		return "TickManager"
	end
---<
--- TM Init Function ---
--- Set TPS Function ---
--->
	function TickManager:setTPS(ticksPerSecond)
		self.TPS = ticksPerSecond
	end
---<
--- Set TPS Function ---
--- Get TPS Function ---
--->
	function TickManager:getTPS(ticksPerSecond)
		return self.TPS
	end
---<
--- Get TPS Function ---
--- TM Ready Function ---
--->
	function TickManager:isReady()
		self.currentClock = os.clock()
		if self.currentClock < self.lastClock + (1 / self.TPS) then return false end
		self.lastClock = self.currentClock
		return true
	end
---<
--- TM Ready Function ---
-- / FPS Manager Functions / --
if VIP_USER then
	-- / Lag Free Circles Functions / --
	--- Draw Circle Next Level Function ---
	--->
		function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
			radius = radius or 300
			quality = math.max(8, round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
			quality = 2 * math.pi / quality
			radius = radius * .92
			local points = {}
			
			for theta = 0, 2 * math.pi + quality, quality do
				local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
				points[#points + 1] = D3DXVECTOR2(c.x, c.y)
			end
			
			DrawLines2(points, width or 1, color or 4294967295)
		end
	---<
	--- Draw Cicle Next Level Function ---
	--- Round Function ---
	--->
		function round(num) 
			if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
		end
	---<
	--- Round Function ---
	--- Draw Cicle 2 Function ---
	--->
		function DrawCircle2(x, y, z, radius, color)
			local vPos1 = Vector(x, y, z)
			local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
			local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
			local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
			
			if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
				DrawCircleNextLvl(x, y, z, radius, 1, color, KatarinaMenu.drawing.lfc.CL) 
			end
		end
	---<
	--- Draw Cicle 2 Function ---
	-- / Lag Free Circles Functions / --
end

-- / Checks Function / --
function Checks()
	--- Tick Manager Check ---
	--->
		if not TManager.onTick:isReady() and KatarinaMenu.misc.uTM then return end
	---<
	--- Tick Manager Check ---
	if VIP_USER then
		--- LFC Checks ---
		--->
			if not KatarinaMenu.drawing.lfc.LagFree then 
				_G.DrawCircle = _G.oldDrawCircle 
			else
				_G.DrawCircle = DrawCircle2
			end
		---<
		--- LFC Checks ---
	end
	--- Updates & Checks if Target is Valid ---
	--->
		tsTarget = GetTarget()
		if tsTarget and tsTarget.type == "obj_AI_Hero" then
			Target = tsTarget
		else
			Target = nil
		end
	---<
	--- Updates & Checks if Target is Valid ---	
	--- Checks and finds Ignite ---
	--->
		if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
		elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
		end
	---<
	--- Checks and finds Ignite ---
	--- Slots for Items ---
	--->
		rstSlot, ssSlot, swSlot, vwSlot =			GetInventorySlotItem(2045),
													GetInventorySlotItem(2049),
													GetInventorySlotItem(2044),
													GetInventorySlotItem(2043)
		dfgSlot, hxgSlot, bwcSlot, brkSlot =		GetInventorySlotItem(3128),
													GetInventorySlotItem(3146),
													GetInventorySlotItem(3144),
													GetInventorySlotItem(3153)
		hpSlot, fskSlot =							GetInventorySlotItem(2003),
													GetInventorySlotItem(2041)
		znaSlot, wgtSlot, bftSlot, liandrysSlot =	GetInventorySlotItem(3157),
													GetInventorySlotItem(3090),
													GetInventorySlotItem(3188),
													GetInventorySlotItem(3151)
	---<
	--- Slots for Items ---
	--- Checks if Spells are Ready ---
	--->
		SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
		SkillW.ready = (myHero:CanUseSpell(_W) == READY)
		SkillE.ready = (myHero:CanUseSpell(_E) == READY)
		SkillR.ready = (myHero:CanUseSpell(_R) == READY)
		iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	---<
	--- Checks if Active Items are Ready ---
	--->
		dfgReady		= (dfgSlot		~= nil and myHero:CanUseSpell(dfgSlot)		== READY)
		hxgReady		= (hxgSlot		~= nil and myHero:CanUseSpell(hxgSlot)		== READY)
		bwcReady		= (bwcSlot		~= nil and myHero:CanUseSpell(bwcSlot)		== READY)
		brkReady		= (brkSlot		~= nil and myHero:CanUseSpell(brkSlot)		== READY)
		znaReady		= (znaSlot		~= nil and myHero:CanUseSpell(znaSlot)		== READY)
		wgtReady		= (wgtSlot		~= nil and myHero:CanUseSpell(wgtSlot)		== READY)
		bftReady		= (bftSlot		~= nil and myHero:CanUseSpell(bftSlot)		== READY)
		lyandrisReady	= (liandrysSlot ~= nil and myHero:CanUseSpell(liandrysSlot) == READY)
	---<
	--- Checks if Items are Ready ---
	--- Checks if Health Pots / Mana Pots are Ready ---
	--->
		Items.HealthPot.ready = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
		Items.FlaskPot.ready = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
	---<
	--- Checks if Health Pots / Mana Pots are Ready ---	
	--- Checks if Wards are Ready ---
	--->
		Items.TrinketWard.ready	  = (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3361) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3362)
		Items.RubySightStone.ready   = (rstSlot ~= nil and myHero:CanUseSpell(rstSlot) == READY)
		Items.SightStone.ready	   = (ssSlot ~= nil and myHero:CanUseSpell(ssSlot) == READY)
		Items.SightWard.ready		= (swSlot ~= nil and myHero:CanUseSpell(swSlot) == READY)
		Items.VisionWard.ready	   = (vwSlot ~= nil and myHero:CanUseSpell(vwSlot) == READY)
	---<
	--- Checks if Wards are Ready ---
	--- Updates Minions ---
	--->
		enemyMinions:update()
		allyMinions:update()
	---<
	--- Updates Minions ---
	--- Setting Cast of Ult ---
	--->
		if SkillR.castingUlt and not WardJumpKey then
			if _G.AutoCarry then
				if _G.AutoCarry.MainMenu ~= nil then
						if _G.AutoCarry.CanAttack ~= nil then
							_G.AutoCarry.CanAttack = false
							_G.AutoCarry.CanMove = false
						end
				elseif _G.AutoCarry.Keys ~= nil then
					if _G.AutoCarry.MyHero ~= nil then
						_G.AutoCarry.MyHero:MovementEnabled(false)
						_G.AutoCarry.MyHero:AttacksEnabled(false)
					end
				end
			end
			if _G.MMA_Loaded then
				_G.MMA_Orbwalker	= false
				_G.MMA_HybridMode	= false
				_G.MMA_LaneClear	= false
				_G.MMA_LastHit		= false
			end
		elseif not SkillR.castingUlt then
			if _G.AutoCarry then 
				if _G.AutoCarry.MainMenu ~= nil then
						if _G.AutoCarry.CanAttack ~= nil then
							_G.AutoCarry.CanAttack = true
							_G.AutoCarry.CanMove = true
						end
				elseif _G.AutoCarry.Keys ~= nil then
					if _G.AutoCarry.MyHero ~= nil then
						_G.AutoCarry.MyHero:MovementEnabled(true)
						_G.AutoCarry.MyHero:AttacksEnabled(true)
					end
				end
			end
		end
	---<
	--- Setting Cast of Ult ---
	--- Setting Proc Q Mark ---
	--->
		if GetTickCount() >= (SkillQ.timeToHit + SkillQ.markDelay) or SkillQ.ready == true then
			SkillQ.timeToHit = 0
		end
	---<
	--- Setting Proc Q Mark ---
end
-- / Checks Function / --

-- / isLow Function / --
function isLow(Name)
	--- Check Zhonya/Wooglets HP ---
	--->
		if Name == 'Zhonya' or Name == 'Wooglets' then
			if (myHero.health * (1/myHero.maxHealth)) <= (KatarinaMenu.misc.ZWHealth * 0.01) then
				return true
			else
				return false
			end
		end
	---<
	--- Check Zhonya/Wooglets HP ---
	--- Check Potions HP ---
	--->
		if Name == 'Health' then
			if (myHero.health * (1/myHero.maxHealth)) <= (KatarinaMenu.misc.HPHealth * 0.01) then
				return true
			else
				return false
			end
		end
	---<
	--- Check Potions HP ---
end
-- / isLow Function / --

-- / GetTarget Function / --
function GetTarget()
	TargetSelector:update()
    
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    
    return TargetSelector.target
end
-- / GetTarget Function / --
