require "lfs"

local cppFile, hFile

-- function declarations
local dirItr, insertSnippets, mainLoop, parseFiles, entry, insertConstructor, loadFile

local cl = {}

loadFile = function (str, path)
    if string.find(str, ".h") then
        hFile = io.open(path, "r+")
        cppFile = dirItr(".",string.sub(str, 1, string.find(str, ".", 1, true) - 1) .. ".cpp")
    elseif string.find(str, ".cpp") then
        cppFile = io.open(path, "r+")
        hFile = dirItr(".",string.sub(str, 1, string.find(str, ".", 1, true) - 1) .. ".h")
    else
        print "No header or cpp file found"
        os.exit(1)
    end
end

dirItr = function (path, targetFileString)
    print("Input file is "..arg[1])
    print("Looking for "..targetFileString.."\t-------------------------")
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path ..'/'..file
            print ("\t "..f)
            if file == targetFileString then
                print ("\t "..targetFileString.." found\t-------------------------\n")
                return io.open(path.."/"..targetFileString, "r+")
            end

            local attr = lfs.attributes(f)

            if attr.mode == "directory" then
                dirItr (f, targetFileString)
            end
        end
    end
end

insertConstructor = function ()
    hFile:seek("set")
    for line in hFile:lines() do
        print(line)
        if line:find("public:", 1, true) ~= nil then
            print(line:find("public:", 1, true))
            hFile:write("hello")
        end
    end
end
insertSnippets = function ()
    mainLoop()
    if cl.bPublic == false then
        io.write ("Insert 'public:'?")
        io.flush()
        if io.read() ~= "n" or io.read() == "." then

        end
    end

    if cl.bConstructor == false then
        io.write ("Insert Constructor?\t")
        io.flush()
        if io.read() ~= "n" or io.read() == "." then

        end
    end

    if cl.bBeginPlay == false then
        io.write ("Insert BeginPlay()?\t")
        io.flush()
        if io.read() ~= "n" or io.read() == "." then

        end
    end

    if cl.bTick == false then
        io.write ("Insert Tick()?\t")
        io.flush()
        if io.read() ~= "n" or io.read() == "." then

        end
    end
end

mainLoop = function ()
    local input
    repeat
        io.write("UE4 Tools > "); io.flush()
        input = io.read()
        if string.find(input:lower(), "^ins%s%w+") ~= nil then
--            local insertString = string.lower(input:sub((select(2, input:find("^ins%s%w"))), (select(2, input:find("^ins%s.*")))))
            local inStr; _,_,inStr = input:find("^ins%s(.*)"); inStr:lower()
            print (inStr)
        end

--        if string.find(input:lower(), "fin%s%w+") ~= nil then
--            local funcToInsert = string.lower(input:sub((select(2,input:find("^fin%s%w"))), (select(2,input:find("^fin%s%w+")))))
--            print (funcToInsert)
--            print ("inserting beginplay")
--            if funcToInsert:find("begin") ~= nil then
--                print("inserting beginplay");
--            end
--            if funcToInsert:find("tick") ~= nil then
--                print("inserting tick")
--            end
--            if funcToInsert:find("cons") ~= nil then
--                print("inserting constructor")
--                insertConstructor()
--            end
--        end

    until input == "." or input == "exit"
end

parseFiles = function ()
    cl = {
        name,
        parent,
        bConstructor = false,
        bBeginPlay = false,
        bTick = false,
        bPublic = false,
    }


-- iterate through header file
    local foundClassLine = false
    for line in hFile:lines() do
        if foundClassLine then
            cl.name = string.match(line:match("%w+%s:"), "%w+")
            cl.parent = string.match(line:match(":%s.*"), "[^: a-z].*")
            foundClassLine = false
        end

        if line:find("public:", 1, true) ~= nil then
            cl.bPublic = true
        end

        if cl.name ~= nil and line:find(cl.name.."();", 1, true) ~= nil then
            cl.bConstructor = true
        end

        if line:find("virtual void BeginPlay()", 1, true) ~= nil then
            cl.bBeginPlay = true
        end

        if line:find("virtual void Tick(", 1, true) ~= nil then
            cl.bTick = true
        end

        if line:find("UCLASS", 1, true) ~= nil then
            foundClassLine = true
        end
    end

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
    insertSnippets()
end

entry = function ()
    local inFileString = arg[1]
    local targetFileString, targetExt

    lfs.chdir(lfs.currentdir().."/Source")


    if arg[2] then
        loadFile(arg[1], arg[2])
    else
        loadFile(arg[1], arg[1])
    end

    parseFiles()
end

entry()