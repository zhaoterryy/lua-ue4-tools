require "lfs"

local cppFilePath, hFilePath

-- function declarations
local dirItr, insertSnippets, mainLoop, parseFiles, entry, loadFile

-- insert functions
local insertConstructor, insertBeginPlay, insertTick

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
    else
        print "No header or cpp file found"
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
end

function insertBeginPlay()
    print("inserting beginplay")
    local tempPos
    local hFile = io.open(hFilePath, "r+")

    for line in hFile:lines() do
        if cl.bPublic and cl.bConstructor then
            if line:find(cl.name.."%s*%(%);") then
              tempPos = hFile:seek()
              break
            end
        elseif cl.bPublic and not cl.bConstructor then
            if line:find("public:", 1, true) then
  --          should we be handling it this way??
              print("CAUTION: Constructor missing, inserting below 'public:'")
              tempPos = hFile:seek()
              break
            end
        else
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end
    hFile:seek("set", tempPos)
    local tempStr = hFile:read("*a")
    tempStr = "\n\tvirtual void BeginPlay() override;\n"..tempStr
    hFile:seek("set", tempPos)
    hFile:write(tempStr); hFile:close()
    -- @todo : confirm write
    cl.bBeginPlay = true
end

function insertConstructor ()
    print("inserting constructor")
    local tempPos
    local hFile = io.open(hFilePath, "r+")

    for line in hFile:lines() do
        if cl.bPublic then
          if line:find("public:", 1, true) then
              tempPos = hFile:seek()
              break
          end
        else
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end
    hFile:seek("set", tempPos)
    local tempStr = hFile:read("*a")
    tempStr = "\n\t"..cl.name.."();\n"..tempStr
    hFile:seek("set", tempPos)
    hFile:write(tempStr); hFile:close()
    -- @todo : confirm write
    cl.bConstructor = true
end

function insertTick()
    print("inserting tick")
    local tempPos
    local hFile = io.open(hFilePath, "r+")
-- @todo : insert after beginplay instead of after public
    for line in hFile:lines() do
        if cl.bPublic and cl.bBeginPlay then
            if line:find("virtual void BeginPlay() override;", 1, true) then
              tempPos = hFile:seek()
              break
            end
        elseif cl.bPublic and cl.bConstructor and not cl.BeginPlay then
            if line:find(cl.name.."%s*%(%);") then
  --          should we be handling it this way??
              print("CAUTION: BeginPlay missing, inserting below the constructor")
              tempPos = hFile:seek()
              break
            end
        elseif cl.bPublic and not cl.bConstructor and not cl.BeginPlay then
          if line:find("public:", 1, true) then
              print("CAUTION: BeginPlay and Constructor missing, inserting below 'public:'")
              tempPos = hFile:seek()
              break
          end
        elseif not cl.bPublic then
          print ("ERROR : No public area... What are you doing????")
          return
        end
    end
    hFile:seek("set", tempPos)
    local tempStr = hFile:read("*a")
    tempStr = "\n\tvirtual void Tick(float DeltaSeconds) override;\n"..tempStr
    hFile:seek("set", tempPos)
    hFile:write(tempStr); hFile:close()
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