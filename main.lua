require "lfs"

local targetFile, inFile, targetExt
local found = false

local function dirItr (path, targetFileString)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." and found ~= true then
            local f = path ..'/'..file
            print ("\t "..f)
            if file == targetFileString then
                print ("\t "..targetFileString.." found\t-------------------------")
                print(path.."/"..targetFileString)
                targetFile = io.open(path.."/"..targetFileString, "r")
                found = true
                break;
            end

            local attr = lfs.attributes(f)

            if attr.mode == "directory" then
                dirItr (f, targetFileString)
            end
        end
    end
end

local function main()
    local cppFileStream, hFileStream, className

    if targetExt == ".cpp" then
        cppFileStream = targetFile:read("*a")
        hFileStream = inFile:read("*a")
        inFile = io.open(arg[2], "r")
    else
        cppFileStream = inFile:read("*a")
        hFileStream = targetFile:read("*a")
    end

--    print(string.find(hFileStream, "UCLASS"))
--    inFile:seek()
--    inFile:seek("set", (select(2,string.find(hFileStream, "UCLASS"))))
--    print(inFile:read("*line"))
--    print(inFile:read("*line"))
--    print(inFile:read("*line"))
--    print(inFile:read("*line"))
--    print(inFile:read("*line"))
--    print(inFile:read("*line"))

--    for line in io.lines(arg[2]) do
--        print (line)
--    end

    local foundClassLine = false
    for line in inFile:lines() do
        if foundClassLine then
            print(line)
            local foundClassWord = false

            print(string.match(line:match("%w+%s:"), "%w+"))

            foundClassLine = false
        end
        if line:find("UCLASS") ~= nil then
            foundClassLine = true
        end
    end

end

local function entry()
    local inFileString = arg[1]
    local targetFileString

    lfs.chdir(lfs.currentdir().."/Source")

    if arg[2] then
        inFile = io.open(arg[2], "r")
    else
        inFile = io.open(inFileString, "r")
    end

    if string.find(inFileString, ".h") then
        targetExt = ".cpp"
    elseif string.find(inFileString, ".cpp") then
        targetExt = ".h"
    else
        targetExt = "its a lie"
        print (targetExt)
        os.exit(1)
    end

    targetFileString = string.sub(inFileString, 1, string.find(inFileString, ".", 1, true) - 1) .. targetExt
    print("Input file is "..inFileString)
    print("Looking for "..targetFileString.."\t-------------------------")

    dirItr(".", targetFileString)

    main()
end

entry()
