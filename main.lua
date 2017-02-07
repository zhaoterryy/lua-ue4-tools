require "lfs"

local cppFilePath, hFilePath

-- function declarations
local dirItr, insertSnippets, mainLoop, parseFiles, entry, loadFile

-- insert functions
local insertConstructor, insertBeginPlay, insertTick

local function errorHandler(err) print ("Error: "..err) end

local cl = {
    name,
    parent,
    bConstructor = false,
    bBeginPlay = false,
    bTick = false,
    bPublic = false,
}

function entry()
    lfs.chdir(lfs.currentdir().."/Source")

    print("Input file is "..arg[1])
    if arg[2] then
        loadFile(arg[1], arg[2])
    else
        loadFile(arg[1], arg[1])
    end

    parseFiles()
end

function loadFile (str, path)
    if str:find(".h") then
        hFilePath = path
        cppFilePath = dirItr(".", str:match("^(.*).%w") .. ".cpp")
    elseif str:find(".cpp") then
        cppFilePath = path
        hFilePath = dirItr(".", str:match("^(.*).%w") .. ".h")
    end
    if hFilePath == nil or cppFilePath == nil then
        errorHandler("No header or cpp file found")
        os.exit(1)
    end
    if io.open(hFilePath) == nil or io.open(cppFilePath) == nil then
        errorHandler("Unable to open header or cpp file. They may be corrupt.")
        print('header:', select(2,io.open(hFilePath)))
        print('cpp:', select(2, io.open(cppFilePath)))
        os.exit(1)
    end
end

function dirItr (path, targetFileString)
    print("Looking for "..targetFileString.."\t-------------------------")
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path ..'/'..file
            print ("\t "..f)
            if file == targetFileString then
                print ("\t "..targetFileString.." found\t-------------------------\n")
--                return io.open(path.."/"..targetFileString, "r+")
                return path.."/"..targetFileString
            end

            local attr = lfs.attributes(f)

            if attr.mode == "directory" then
                dirItr (f, targetFileString)
            end
        end
    end
    return nil
end

function insertBeginPlay()
    print("inserting beginplay")
    local hTempPos
    local hFile = io.open(hFilePath, "r+")
    if hSuccess ~= true then
        errorHandler("Header file failed to load.")
        return
    end

    for line in hFile:lines() do
        if cl.bPublic and cl.bConstructor then
            if line:find(cl.name.."%s*%(%);") then
                hTempPos = hFile:seek()
                break
            end
        elseif cl.bPublic and not cl.bConstructor then
            if line:find("public:", 1, true) then
  --          should we be handling it this way??
              print("CAUTION: Constructor missing, inserting below 'public:'")
              hTempPos = hFile:seek()
              break
            end
        else
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end
    hFile:seek("set", hTempPos)
    local hTempStr = hFile:read("*a")
    hTempStr = "\n\tvirtual void BeginPlay() override;\n"..hTempStr
    hFile:seek("set", hTempPos)
    hFile:write(hTempStr); hFile:close()

    -- .cpp
--    local bIncludeFound, bConstructorFound, cTempPos, cInclPos
    local cppFile = io.open(cppFilePath, "a")
--    local cppFileStr = io.read("*a")
--    for line in cppFile:lines() do
--        if line:find("^#include%s\".-\"$") then
--            cInclPos = cppFile:seek()
--        end
--    end

--    local findConstrPos = cppFileStr:find(cl.name.."::"..cl.name.."()\n{.*}")
--    if findConstrPos then
--        cTempPos = findConstrPos
--        bConstructorFound = true
--    end
-- @todo : insert in proper position

--    if bConstructorFound ~= true then
        -- should we be handling it this way??
--        cppFile:seek("set", cInclPos)
--        local cTempStr = cppFile:read("*a")
--        cTempStr = "\nvoid "..cl.Name.."::".." BeginPlay()\n{\nSuper::BeginPlay();\n}\n"..cTempStr
--        cppFile:seek("set", cInclPos)
--        cppFile:write(cTempStr); cppFile:close()
--    else
--        cppFile:seek("set", cTempPos)
--        local cTempStr = cppFile:read("*a")
--        cTempStr = "\nvoid "..cl.Name.."::".." BeginPlay()\n{\nSuper::BeginPlay();\n}\n"..cTempStr
--        cppFile:seek("set", cTempPos)
--        cppFile:write(cTempStr); cppFile:close()
--    end

    cppFile:write("\nvoid "..cl.name.."::".."BeginPlay()\n{\n\tSuper::BeginPlay();\n}\n")
    cppFile:close()

    -- @todo : confirm write
    cl.bBeginPlay = true
end

function insertConstructor()
    print("inserting constructor")
    local hTempPos

    local hFile = io.open(hFilePath, "r+")
    -- header
    for line in hFile:lines() do
        if cl.bPublic then
          if line:find("public:", 1, true) then
              hTempPos = hFile:seek()
              break
          end
        else
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end

    hFile:seek("set", hTempPos)
    local hTempStr = hFile:read("*a")
    hTempStr = "\n\t"..cl.name.."();\n"..hTempStr
    hFile:seek("set", hTempPos)
    hFile:write(hTempStr); hFile:close()

    local bIncludeFound, cTempPos
    local cppFile = io.open(cppFilePath, "r+")
    -- .cpp
    for line in cppFile:lines() do
        if line:find("^#include%s\".-\"$") then
            cTempPos = cppFile:seek()
            bIncludeFound = true
        end
    end

    if bIncludeFound ~= true then
        -- should we be handling it this way??
        local tempIncl = hFilePath:match("([^\\]-[^%.]+)$")
        print("error: no includes found.. inserting\n#include \""..tempIncl.."\"")
        cppFile:seek("set")
        local cTempStr = cppFile:read("*a")
        cTempStr = "// auto generated stub from lua-ue4-tools\n#include \""..tempIncl.."\""
        cppFile:seek("set")
        cppFile:write(cTempStr); cppFile:close()
    else
        cppFile:seek("set", cTempPos)
        local cTempStr = cppFile:read("*a")
        cTempStr = "\n"..cl.name.."::"..cl.name.."()\n{\n\n}\n"..cTempStr
        cppFile:seek("set", cTempPos)
        cppFile:write(cTempStr); cppFile:close()
    end
    -- @todo : confirm write
    cl.bConstructor = true
end

function insertTick()
    print("inserting tick")
    local hTempPos
    local hFile = io.open(hFilePath, "r+")
-- @todo : insert after beginplay instead of after public
    for line in hFile:lines() do
        if cl.bPublic and cl.bBeginPlay then
            if line:find("virtual void BeginPlay() override;", 1, true) then
              hTempPos = hFile:seek()
              break
            end
        elseif cl.bPublic and cl.bConstructor and not cl.BeginPlay then
            if line:find(cl.name.."%s*%(%);") then
  --          should we be handling it this way??
              print("CAUTION: BeginPlay missing, inserting below the constructor")
              hTempPos = hFile:seek()
              break
            end
        elseif cl.bPublic and not cl.bConstructor and not cl.BeginPlay then
          if line:find("public:", 1, true) then
              print("CAUTION: BeginPlay and Constructor missing, inserting below 'public:'")
              hTempPos = hFile:seek()
              break
          end
        elseif not cl.bPublic then
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end

    hFile:seek("set", hTempPos)
    local hTempStr = hFile:read("*a")
    hFile:seek("set", hTempPos)
    hTempStr = "\n\tvirtual void Tick(float DeltaSeconds) override;\n"..hTempStr
    hFile:write(hTempStr); hFile:close()

    -- .cpp
    local cppFile = io.open(cppFilePath, "a")
-- @todo : insert in proper position
--    local bIncludeFound, bConstructorFound, bBPFound, cInclPos, cConstrPos, cBPPos
--    local cppFile = io.open(cppFilePath, "r+")
--    for line in cppFile:lines() do
--        if line:find("^#include%s\".-\"$") then
--            cInclPos = cppFile:seek()
--            bIncludeFound = true
--        end
--        if line:find(cl.name.."::"..cl.name.."()\n{.*}") then
--            cConstrPos = cppFile:seek()
--            bConstructorFound = true
--        end
--        if line:find("void%s"..cl.name.."::".."BeginPlay()")
--    end

    cppFile:write("\nvoid "..cl.name.."::".."Tick(float DeltaSeconds)\n{\n\tSuper::Tick(DeltaSeconds);\n}")
    cppFile:close()
    -- @todo : confirm write
    cl.bTick = true
end

function mainLoop()
  -- @todo : handle cases where file conatains comments that may affect pattern searching
    local input
    repeat
        io.write("UE4 Tools > "); io.flush()
        input = io.read()

        if input:find("^fin%s%w+") then
            local arg = string.lower(input:match("^fin%s(%w+)"))
--            print(arg)
            if arg == "beginplay" or arg == "bp" and not cl.bBeginPlay then
                insertBeginPlay()
            elseif arg == "constructor" and not cl.bConstructor then
                insertConstructor()
            elseif arg == "tick" and not cl.bTick then
                insertTick()
            end
        end
    until input == "." or input == "exit"
end

function parseFiles()
-- iterate through header file
    local foundClassLine = false
    local hFile = io.open(hFilePath)

    for line in hFile:lines() do
        if foundClassLine then
            cl.name = string.match(line:match("%w+%s:"), "%w+")
            cl.parent = string.match(line:match(":%s.*"), "[^: a-z].*")
            foundClassLine = false
        end
        if line:find("public:", 1, true) then
            cl.bPublic = true
        end
        if cl.name ~= nil and line:find(cl.name.."%s*%(%);") then
            cl.bConstructor = true
        end
        if line:find("virtual void BeginPlay()", 1, true) then
            cl.bBeginPlay = true
        end
        if line:find("virtual void Tick(", 1, true) then
            cl.bTick = true
        end
        if line:find("UCLASS", 1, true) then
            foundClassLine = true
        end
    end

    hFile:close()

    if cl.name == nil then
        print("UCLASS not found!")
        os.exit(2)
    end

    print ("Class:\t\t"..cl.name)
    print ("Parent:\t\t"..cl.parent)
    io.write ("Constructor:\t")
    print (cl.bConstructor)
    io.write ("BeginPlay():\t")
    print (cl.bBeginPlay)
    io.write ("Tick():\t\t")
    print (cl.bTick)
    io.write ("\"public:\"\t")
    print (cl.bPublic)
    print (" ------------------------------------------------")
    mainLoop()
end

entry()

-- saving function for interactive mode
--function insertSnippets ()
--    mainLoop()
--    if cl.bPublic == false then
--        io.write ("Insert 'public:'?")
--        io.flush()
--        if io.read() ~= "n" or io.read() == "." then
--
--        end
--    end
--
--    if cl.bConstructor == false then
--        io.write ("Insert Constructor?\t")
--        io.flush()
--        if io.read() ~= "n" or io.read() == "." then
--
--        end
--    end
--
--    if cl.bBeginPlay == false then
--        io.write ("Insert BeginPlay()?\t")
--        io.flush()
--        if io.read() ~= "n" or io.read() == "." then
--
--        end
--    end
--
--    if cl.bTick == false then
--        io.write ("Insert Tick()?\t")
--        io.flush()
--        if io.read() ~= "n" or io.read() == "." then
--
--        end
--    end
--end