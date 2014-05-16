#!/usr/bin/env lua

TestingUnit = setmetatable({},
{
    __call = function(self, ...) 
        local test_table = {
            --this table value should be considered immutable as it is used for table discovery
            is_testing_unit = true,
            failures = {},
            errors = {},
            expected_failures = {},
            fixtures = {},
                
            assert_raises = function(self, func, args)
                success, result =  pcall(func, unpack(args))
                if success then
                    self.failures[#self.failures + 1] = {
                        err=result, 
                        func=func, 
                        args=args,
                        tb=debug.traceback(), 
                        info=debug.getinfo(2)
                    }
                end
            end,
            assert_equal = function(self, a, b)
                if a ~= b then
                    self.failures[#self.failures + 1] = {
                        err=string.format("assert_equal failed: %s ~= %s", a , b), 
                        func=func, 
                        args={a, b}
                    }
                end
            end,
            assert_truthy = function(self, x)
                if not x then
                    self.failures[#self.failures + 1] = {
                        err=string.format("assert_truthy failed: '%s' is not truthy", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end, 
            assert_true = function(self, x)
                if x ~= true then
                    self.failures[#self.failures + 1] = {
                        err=string.format("assert_true failed:'%s' ~= true", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end,
            assert_false = function(self, x)
                if x ~= false then
                    self.failures[#self.failures + 1] = {
                        err=string.format("assert_false failed: '%s' ~= false", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end,
            assert_match = function(self, s, exp)
                if not string.match(s, exp) then
                    self.failures[#self.failures + 1] = {
                        err=string.format("'%s' does not match '%s'", s, exp), 
                        info=debug.getinfo(2),
                        args={s, exp}
                    }
                end
            end,
            assert_in = function(self, haystack, needle)
                if type(haystack) ~= 'string' and type(haystack) ~= 'table' then
                    self.failures[#self.failures + 1] = {
                        err=string.format("type('%s') is not a container type",  haystack), 
                        info=debug.getinfo(2),
                        args={needle=needle, haystack=haystack}
                    }
                    return
                end
                if type(haystack) == 'string' then
                    if type(needle) ~= 'string' then
                        self.failures[#self.failures + 1] = {
                            err=string.format("'%s' cannot be a substring of '%s'", needle, haystack), 
                            info=debug.getinfo(2)
                        }
                        return 
                    end
                    local start, finish = string.find(haystack, needle)
                    if start == nil then
                        self.failures[#self.failures + 1] = {
                            err=string.format("'%s' not found in '%s'", needle, haystack),  
                            info=debug.getinfo(2)
                        }
                        return
                    end
                end
                if type(haystack) == 'table' then
                    local in_table = false
                    for k, v in pairs(haystack) do
                        if v == needle then
                            in_table = true
                        end
                    end
                    if not in_table then
                        self.failures[#self.failures + 1] = {
                            err=string.format("'%s' not found in '%s'", needle, haystack),  
                            info=debug.getinfo(2)
                        }
                    end
                end
            end,
            assert_nil = function(self, x)
                if x ~= nil then
                    self.failures[#self.failures + 1] = {
                        err=string.format("'%s' not nil", x),  
                        info=debug.getinfo(2)
                    }
                end
            end,
            assert_calls = function(self, caller, callee, args)
                if (type(caller) ~= 'function' or type(callee) ~= 'function') then 
                    error('callable arguments required for assert_calls()', 2) 
                end
                local was_called = false
                local function trace_hook()
                    if debug.getinfo(2, "f").func == callee then 
                        was_called = true
                    end
                end
                local function getname(func)
                    --PiL 'the debug library
                    local n = debug.getinfo(func)
                    if n.what == "C" then
                        return n.name
                    end
                    local lc = string.format("[%s]:%d", n.short_src, n.linedefined)
                    if n.what ~= "main" and n.namewhat ~= "" then
                        return string.format("%s, (%s)", lc, n.name)
                    else
                        return lc
                    end
                end
                debug.sethook(trace_hook, 'c')
                    pcall(caller,args)
                debug.sethook()
                if not was_called then
                    self.failures[#self.failures + 1] = {
                        err=string.format(
                            "assert_calls failure:'%s' not called by '%s with args(%s)'", 
                            getname(callee), 
                            getname(caller), 
                            table.concat(type(args) == 'table' and args or {args}, ', ')
                        ),  
                        info=debug.getinfo(2)
                    }
                end
            end
        }
        if ... ~= nil then
            for k, v in pairs(...) do 
                test_table[k] = v
            end
        end
        return test_table
    end,
     __tostring = function(self)
        return "TestingUnit dummy!"
    end
})

function enumerate_files(dirs)
    local dirs = dirs or {}
    local function scandir(directory)
        --http://stackoverflow.com/a/11130774
        local t = {}
        for filename in io.popen('ls -a "'..directory..'"'):lines() do
            t[#t + 1] = filename
        end
        return t
    end
    local all_files = {}
    for _, dir in pairs(dirs) do
        for _, v in pairs(scandir(dir)) do
--            print(v)
            all_files[#all_files + 1] = v
        end
    end
    return all_files
end

function load_test_files(dirs)
    local tests = {}
    for _, file in ipairs(enumerate_files(dirs)) do
        if string.match(file, '^test.*.lua$') then
            print("loading", file .. "...")
            local func, err = loadfile(file)
            tests[#tests + 1] = func
            --load the test into the global environment. warn on failure
            if not pcall(func) then print(string.format("ERROR:failed to load '%s'", file)) end
        end
    end
end

function runtests()
    local tests = {}
    local tests_run = 0
    local tests_failed = 0
    local tests_expected_failed = 0
    local test_errors = 0
    local start_time = 0
    local stop_time = 0
    --discover all lua test scripts in the current directory and protected load them
    
    
    --[[iterate the global registry for tables with key ``is_testing_unit == true `` 
    and add that table to the list of unit test tables.
    ]]
    for k, v in pairs(_G) do
        if type(v) == 'table' then
            if v['is_testing_unit'] == true then
                tests[#tests +1] = v
            end
        end
    end
    

    local function _runtests(t)
        --[[ Search each identified unit test table for member functions named ``test*``
        and execute each one within pcall, identifying and counting failures, 
        expected failures, and execution errors.
        ]]
        for k, v in pairs(t) do
            if type(v) == 'function' then
                if  string.match(k, '^test') then
                    if t.setup then t:setup() end
                        local success, ret = pcall(v,t)
                    if not success then 
                        t.errors[#t.errors +1] = ret
                    end
                    tests_run = tests_run + 1
                    if t.teardown then t:teardown() end
                end
            end
        end
    end
    
    start_time = os.time()
        --actually run all the tests
        for _, v in pairs(tests) do
            _runtests(v)
        end
    stop_time = os.time()
    
    local function _print_results(t) 
        for _, f in ipairs(t.failures) do
            tests_failed = tests_failed + 1
            print("================================")
            print("FAILURE:")
            for k, v in pairs(f) do
                print(k, v)
            end
            print("--------------------------------")
        end
        for _, e in ipairs(t.errors) do
            test_errors = test_errors + 1
            print("================================")
            print("ERROR:execution failure")
            print(e)
            print("--------------------------------")
        end
    end
    for _, v in pairs(tests) do
        _print_results(v)
    end
    
    print(string.format([[Ran %s tests in %s seconds.
        %s failures, %s expected failures, %s errors]],
        tests_run, 
        os.difftime(stop_time, start_time), 
        tests_failed, 
        tests_expected_failed, test_errors)
    )
end



--function main()
--    local dirs = parse_args()['dirs']
--    for k, v in pairs(args) do print (k, v) end
    load_test_files({'.'})
    runtests()
