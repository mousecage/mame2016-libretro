-- license:BSD-3-Clause
-- copyright-holders:MAMEdev Team

---------------------------------------------------------------------------
--
--   main.lua
--
--   Rules for building main binary
--
---------------------------------------------------------------------------

function mainProject(_target, _subtarget)
if (_OPTIONS["SOURCES"] == nil) then 
	if (_target == _subtarget) then
		project (_target)
	else
		if (_subtarget=="mess") then
			project (_subtarget)
		else
			project (_target .. _subtarget)
		end
	end	
else
	project (_subtarget)
end	
	uuid (os.uuid(_target .."_" .. _subtarget))
	kind "ConsoleApp"
	
	configuration { "android*" }
		targetextension ".so"
		linkoptions {
			"-shared",
		}
		links {
			"EGL",
			"GLESv2",
		} 	
	configuration { "pnacl" }
		kind "ConsoleApp"
		targetextension ".pexe"
		links {
			"ppapi",
			"ppapi_gles2",
			"pthread",
		}
	configuration {  }

	addprojectflags()
	flags {
		"NoManifest",
		"Symbols", -- always include minimum symbols for executables 
	}

	if _OPTIONS["SYMBOLS"] then
		configuration { "mingw*" }
			postbuildcommands {
				"$(SILENT) echo Dumping symbols.",
				"$(SILENT) objdump --section=.text --line-numbers --syms --demangle $(TARGET) >$(subst .exe,.sym,$(TARGET))"
			}
	end
	
	configuration { "vs*" }
	flags {
		"Unicode",
	}

	configuration { "x64", "Release" }
		targetsuffix "64"
		if _OPTIONS["PROFILE"] then
			targetsuffix "64p"
		end

	configuration { "x64", "Debug" }
		targetsuffix "64d"
		if _OPTIONS["PROFILE"] then
			targetsuffix "64dp"
		end

	configuration { "x32", "Release" }
		targetsuffix ""
		if _OPTIONS["PROFILE"] then
			targetsuffix "p"
		end

	configuration { "x32", "Debug" }
		targetsuffix "d"
		if _OPTIONS["PROFILE"] then
			targetsuffix "dp"
		end

	configuration { "Native", "Release" }
		targetsuffix ""
		if _OPTIONS["PROFILE"] then
			targetsuffix "p"
		end

	configuration { "Native", "Debug" }
		targetsuffix "d"
		if _OPTIONS["PROFILE"] then
			targetsuffix "dp"
		end

	configuration { "mingw*" or "vs*" }
		targetextension ".exe"

	configuration { "asmjs" }
		targetextension ".bc"  
		if os.getenv("EMSCRIPTEN") then
			local emccopts = ""
			emccopts = emccopts .. " -O3"
			emccopts = emccopts .. " -s USE_SDL=2"
			emccopts = emccopts .. " --memory-init-file 0"
			emccopts = emccopts .. " -s ALLOW_MEMORY_GROWTH=0"
			emccopts = emccopts .. " -s TOTAL_MEMORY=268435456"
			emccopts = emccopts .. " -s DISABLE_EXCEPTION_CATCHING=2"
			emccopts = emccopts .. " -s EXCEPTION_CATCHING_WHITELIST='[\"__ZN15running_machine17start_all_devicesEv\"]'"
			emccopts = emccopts .. " -s EXPORTED_FUNCTIONS=\"['_main', '_malloc', '__Z14js_get_machinev', '__Z9js_get_uiv', '__Z12js_get_soundv', '__ZN10ui_manager12set_show_fpsEb', '__ZNK10ui_manager8show_fpsEv', '__ZN13sound_manager4muteEbh', '_SDL_PauseAudio']\""
			emccopts = emccopts .. " --pre-js " .. _MAKE.esc(MAME_DIR) .. "src/osd/modules/sound/js_sound.js"
			emccopts = emccopts .. " --post-js " .. _MAKE.esc(MAME_DIR) .. "src/osd/sdl/emscripten_post.js"
			emccopts = emccopts .. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "bgfx@bgfx"
			emccopts = emccopts .. " --embed-file " .. _MAKE.esc(MAME_DIR) .. "shaders/gles@shaders/gles"
			postbuildcommands {
				os.getenv("EMSCRIPTEN") .. "/emcc " .. emccopts .. " $(TARGET) -o " .. _MAKE.esc(MAME_DIR) .. _OPTIONS["target"] .. _OPTIONS["subtarget"] .. ".js",
			}
		end

	-- BEGIN libretro overrides to MAME's GENie build
	configuration { "libretro*" }
		kind "SharedLib"	
		targetsuffix "_libretro"
		if _OPTIONS["targetos"]=="android-arm" then
			targetsuffix "_libretro_android"
			defines {
 				"SDLMAME_ARM=1",
			}
		elseif _OPTIONS["targetos"]=="ios-arm" then
			targetsuffix "_libretro_ios"
			targetextension ".dylib"
		elseif _OPTIONS["targetos"]=="windows" then
			targetextension ".dll"
		elseif _OPTIONS["targetos"]=="osx" then
			targetextension ".dylib"
		else
			targetsuffix "_libretro"
		end

		targetprefix ""

		includedirs {
			MAME_DIR .. "src/osd/retro/libretro-common/include",
		}
		links { "libco" }

		-- Workaround: Compile the public libretro API into the shlib
		-- rather than the OSD to keep linkers from being "helpful"
		-- and stripping it out.
		files {
			MAME_DIR .. "src/osd/retro/libretro.cpp"
		}

		-- Ensure the public API is made public with GNU ld
		if _OPTIONS["targetos"]=="linux" then
			linkoptions {
				"-Wl,--version-script=" .. MAME_DIR .. "src/osd/retro/link.T",
			}
		end

	-- END libretro overrides to MAME's GENie build

	configuration { }

	if _OPTIONS["SEPARATE_BIN"]~="1" then 
		targetdir(MAME_DIR)
	end
	
	findfunction("linkProjects_" .. _OPTIONS["target"] .. "_" .. _OPTIONS["subtarget"])(_OPTIONS["target"], _OPTIONS["subtarget"])
	links {
		"osd_" .. _OPTIONS["osd"],
	}

	if _OPTIONS["osd"]=="retro" then

	else
		links {
			"qtdbg_" .. _OPTIONS["osd"],
		}
	end

	if (_OPTIONS["SOURCES"] == nil) then 
		links {
			"bus",
		}
	end
	links {
		"netlist",
		"optional",
		"emu",
		"formats",
	}
if #disasm_files > 0 then
	links {
		"dasm",
	}
end
	links {
		"utils",
		"expat",
		"softfloat",
		"jpeg",
		"7z",
		"lua",
		"lualibs",
	}

	if _OPTIONS["USE_LIBUV"]=="1" then
		links {		
			"luv",
			"uv",
			"http-parser",
		}
	end
	if _OPTIONS["with-bundled-zlib"] then
		links {
			"zlib",
		}
	else
		links {
			"z",
		}
	end

	if _OPTIONS["with-bundled-flac"] then
		links {
			"flac",
		}
	else
		links {
			"FLAC",
		}
	end

	if _OPTIONS["with-bundled-sqlite3"] then
		links {
			"sqllite3",
		}
	else
		links {
			"sqlite3",
		}
	end

	if _OPTIONS["NO_USE_MIDI"]~="1" then
		links {
			"portmidi",
		}
	end
	links {
		"bgfx",
		"ocore_" .. _OPTIONS["osd"],
	}
	
	override_resources = false;
	
	maintargetosdoptions(_target,_subtarget)

	includedirs {
		MAME_DIR .. "src/osd",
		MAME_DIR .. "src/emu",
		MAME_DIR .. "src/devices",
		MAME_DIR .. "src/" .. _target,
		MAME_DIR .. "src/lib",
		MAME_DIR .. "src/lib/util",
		MAME_DIR .. "3rdparty",
		GEN_DIR  .. _target .. "/layout",
		GEN_DIR  .. "resource",
	}

	if _OPTIONS["with-bundled-zlib"] then
		includedirs {
			MAME_DIR .. "3rdparty/zlib",
		}
	end

   -- RETRO HACK
	if _OPTIONS["osd"]=="retro" then

		forcedincludes {
			MAME_DIR .. "src/osd/retro/retroprefix.h"
		}

		includedirs {
			MAME_DIR .. "src/emu",
			MAME_DIR .. "src/osd",
			MAME_DIR .. "src/lib",
			MAME_DIR .. "src/lib/util",
			MAME_DIR .. "src/osd/retro",
			MAME_DIR .. "src/osd/modules/render",
			MAME_DIR .. "3rdparty",
			MAME_DIR .. "3rdparty/winpcap/Include",
			MAME_DIR .. "3rdparty/bgfx/include",
			MAME_DIR .. "3rdparty/bx/include",
			MAME_DIR .. "src/osd/retro/libretro-common/include",
		}

		files {
			MAME_DIR .. "src/osd/retro/retromain.cpp",
			MAME_DIR .. "src/osd/retro/libretro.cpp",
		}
	end
-- RETRO HACK

	if _OPTIONS["targetos"]=="macosx" and (not override_resources) then
		linkoptions {
			"-sectcreate __TEXT __info_plist " .. _MAKE.esc(GEN_DIR) .. "resource/" .. _subtarget .. "-Info.plist"
		}
		custombuildtask {
			{ MAME_DIR .. "src/version.cpp" ,  GEN_DIR .. "resource/" .. _subtarget .. "-Info.plist",    {  MAME_DIR .. "scripts/build/verinfo.py" }, {"@echo Emitting " .. _subtarget .. "-Info.plist" .. "...",    PYTHON .. " $(1)  -p -b " .. _subtarget .. " $(<) > $(@)" }},
		}
		dependency {
			{ "$(TARGET)" ,  GEN_DIR  .. "resource/" .. _subtarget .. "-Info.plist", true  },
		}

	end
	local rctarget = _subtarget

	if _OPTIONS["targetos"]=="windows" and (not override_resources) then
		local rcfile = MAME_DIR .. "src/" .. _target .. "/osd/".._OPTIONS["osd"].."/"  .. _subtarget .. "/" .. rctarget ..".rc"
		if not os.isfile(rcfile) then
			rcfile = MAME_DIR .. "src/" .. _target .. "/osd/windows/" .. _subtarget .. "/" .. rctarget ..".rc"
		end
		if os.isfile(rcfile) then
			files {
				rcfile,
			}
			dependency {
				{ "$(OBJDIR)/".._subtarget ..".res" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", true  },
			}
		else
			rctarget = "mame"
			files {
				MAME_DIR .. "src/mame/osd/windows/mame/mame.rc",
			}
			dependency {
				{ "$(OBJDIR)/mame.res" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", true  },
			}
		end	
	end

	local mainfile = MAME_DIR .. "src/".._target .."/" .. _subtarget ..".cpp"
	if not os.isfile(mainfile) then
		mainfile = MAME_DIR .. "src/".._target .."/" .. _target ..".cpp"
	end
	files {
		mainfile,
		MAME_DIR .. "src/version.cpp",
		GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",
	}
	
if (_OPTIONS["SOURCES"] == nil) then 	
	dependency {
		{ "../../../../generated/mame/mame/drivlist.cpp",  MAME_DIR .. "src/mame/mess.lst", true },
		{ "../../../../generated/mame/mame/drivlist.cpp" , MAME_DIR .. "src/mame/arcade.lst", true},
	}
	custombuildtask {
		{ MAME_DIR .. "src/".._target .."/" .. _subtarget ..".lst" ,  GEN_DIR  .. _target .. "/" .. _subtarget .."/drivlist.cpp",    {  MAME_DIR .. "scripts/build/makelist.py" }, {"@echo Building driver list...",    PYTHON .. " $(1) $(<) > $(@)" }},
	}
end	

if _OPTIONS["FORCE_VERSION_COMPILE"]=="1" then
	configuration { "gmake" }
		dependency {
			{ ".PHONY", ".FORCE", true },
			{ "$(OBJDIR)/src/version.o", ".FORCE", true },
		}
end
	configuration { "mingw*" }
		custombuildtask {	
			{ MAME_DIR .. "src/version.cpp" ,  GEN_DIR  .. "resource/" .. rctarget .. "vers.rc",    {  MAME_DIR .. "scripts/build/verinfo.py" }, {"@echo Emitting " .. rctarget .. "vers.rc" .. "...",    PYTHON .. " $(1)  -r -b " .. rctarget .. " $(<) > $(@)" }},
		}	
	
	configuration { "vs*" }
		prebuildcommands {	
			"mkdir " .. path.translate(GEN_DIR  .. "resource/","\\") .. " 2>NUL",
			"@echo Emitting ".. rctarget .. "vers.rc...",
			PYTHON .. " " .. path.translate(MAME_DIR .. "scripts/build/verinfo.py","\\") .. " -r -b " .. rctarget .. " " .. path.translate(MAME_DIR .. "src/version.cpp","\\") .. " > " .. path.translate(GEN_DIR  .. "resource/" .. rctarget .. "vers.rc", "\\") ,
		}	
				
	if (_OPTIONS["osd"] == "sdl") then
		configuration { "x64","vs*" }
			prelinkcommands { "copy " .. path.translate(MAME_DIR .."3rdparty/sdl2/lib/x64/SDL2.dll", "\\") .. " " .. path.translate(MAME_DIR .."SDL2.dll","\\") .. " /Y" }
		configuration { "x32","vs*" }
			prelinkcommands { "copy " .. path.translate(MAME_DIR .."3rdparty/sdl2/lib/x86/SDL2.dll", "\\") .. " " .. path.translate(MAME_DIR .."SDL2.dll","\\") .. " /Y" }
	end
	
	configuration { }

	debugdir (MAME_DIR)
	debugargs ("-window")
end
