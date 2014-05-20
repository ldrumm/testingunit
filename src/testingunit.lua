#!/usr/bin/env lua

TestingUnit = setmetatable({},
{
    __call = function(self, ...) 
        local test_table = {
            --this table value should be considered immutable as it is used for table discovery
            is_testing_unit = true,
            
            fixtures = {},
            
            _assertion_failure = function(self, ...)
                error("override me", 4)
            end,
            
            assert_raises = function(self, func, args)
                --[[ given a callable ``func`` and table of arguments ``args``,
                assert that ``func(unpack(args))`` throws an error.
                    
                ]]
                local args = args or {}
                success, result = pcall(func, unpack(args))
                --we don't want success as this is assert_raises()
                if success then
                    self:_assertion_failure{
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
                    self:_assertion_failure{
                        err=string.format("assert_equal failed: %s ~= %s", a , b), 
                        func=func, 
                        args={a, b}
                    }
                end
            end,
            
            assert_truthy = function(self, x)
                if not x then
                    self:_assertion_failure{
                        err=string.format("assert_truthy failed: '%s' is not truthy", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end, 
            
            assert_true = function(self, x)
                if x ~= true then
                    self:_assertion_failure{
                        err=string.format("assert_true failed:'%s' ~= true", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end,
            
            assert_false = function(self, x)
                if x ~= false then
                    self:_assertion_failure{
                        err=string.format("assert_false failed: '%s' ~= false", x), 
                        info=debug.getinfo(2),
                        args={x}
                    }
                end
            end,
            
            assert_match = function(self, s, exp)
                if not string.match(s, exp) then
                    self:_assertion_failure{
                        err=string.format("'%s' does not match '%s'", s, exp), 
                        info=debug.getinfo(2),
                        args={s, exp}
                    }
                end
            end,
            
            assert_in = function(self, haystack, needle)
                if type(haystack) ~= 'string' and type(haystack) ~= 'table' then
                    self:_assertion_failure{
                        err=string.format("type('%s') is not a container type",  haystack), 
                        info=debug.getinfo(2),
                        args={needle=needle, haystack=haystack}
                    }
                    return
                end
                if type(haystack) == 'string' then
                    if type(needle) ~= 'string' then
                        self:_assertion_failure{
                            err=string.format("'%s' cannot be a substring of '%s'", needle, haystack), 
                            info=debug.getinfo(2)
                        }
                        return 
                    end
                    local start, finish = string.find(haystack, needle)
                    if start == nil then
                        self:_assertion_failure{
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
                        self:_assertion_failure{
                            err=string.format("'%s' not found in '%s'", needle, haystack),  
                            info=debug.getinfo(2)
                        }
                    end
                end
            end,
            
            assert_nil = function(self, x)
                if x ~= nil then
                    self:_assertion_failure{
                        err=string.format("'%s' not nil", x),  
                        info=debug.getinfo(2)
                    }
                end
            end,
            
            assert_calls = function(self, caller, callee, args)
                if (type(caller) ~= 'function') or (type(callee) ~= 'function') then 
                    error(string.format('callable arguments required for assert_calls().  Got %s, %s, %s', caller, callee, args), 2) 
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
                    --pcall is required because errors prevent reporting / cancelling the debug hook
                    
                    pcall(caller,args)
                debug.sethook()
                if not was_called then
                    self:_assertion_failure{
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
        --inherit called values before return.
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

function enumerate_files(dirs, depth, pattern)
--    generator function to enumerate all files within a given directory
    local dirs = dirs or {'.'}
    local depth = tonumber(depth) or 2
    local pattern = pattern or nil
    if pattern then
        pattern = string.format('-iname %q', pattern)
    else 
        pattern = ""
    end
    local function scandir(directory)
        local t = {}
        --This quoting is not security safe, but should prevent accidents
        for filename in io.popen(string.format("find %s -maxdepth %s  %s -type f", 
            string.format("%q", directory), 
            depth, 
            pattern)):lines() do
            
t[#t + 1] = filename
        end
        return t
    end
    local all_files = {}
    for _, dir in pairs(dirs) do
        for _, v in pairs(scandir(dir)) do
            all_files[#all_files + 1] = v
        end
    end
    local index = 0
    local function file_iter()
        index = index + 1
        return all_files[index]
    end
    return file_iter
end


function find_test_files(dirs, depth, pattern)
    --[[discover all lua test scripts in the given directories and put their 
    filenames in the returned array
    ]]
    local tests = {}
    local function basename(path)
        local index = string.find(path:reverse(), '/', 1, true)
        if not index then return path end
        return string.sub(path, #path-index+2)
    end
    
    for file in enumerate_files(dirs, depth, pattern) do
        if string.match(basename(file), '^test.*.lua$') then
--            print("loading", file .. "...")
            tests[#tests + 1] = file
        end
    end
    return tests
end



function runtests(all_test_files)
    --[[
        Given a table containing paths of testing scripts, load each one in turn
        and execute any TestingUnits instantiated into the global table by the script. 
        The global namespace is reset between each file load, so there are no 
        side-effects from other test files, it is not reset per suite in the case that
        multiple test suites exist in a single file.  
        This shouldn't present a problem in most cases.
    ]]

    local old_globals = {}  --we store a clean copy of _G for restoring a clean slate.
    local n_tests_run = 0
    local n_tests_failed = 0
    local n_tests_passed = 0
    local n_tests_expected_failed = 0
    local n_test_errors = 0
    local start_time = 0
    local stop_time = 0
    local failures = {}
    local errors = {}    
    local expected_failures = {}
    
    local function save_globals()
        --store the contents of the global table locally
        for k, v in pairs(_G) do
            old_globals[k] = v
        end
    end
    
    local function reset_globals()
        --set the global table back to the saved upvalue
        local pairs = pairs
        for k, v in pairs(_G) do
            if not old_globals[k] then
                _G[k] = nil
            end
        end
    end
    
    local function load_each_test_file_iter(files_list)
        --[[
        Given a list of files, load the test into the global environment and 
        return all discovered test tables. 
        warns on failure to load, but skips to the next test.
        ]]
        local index = 0
        local file_iter = ipairs(files_list)
        local function iter()
            local _, file = file_iter(files_list, index)
            
            index = index + 1
            if file == nil then return nil end
            local func, err = loadfile(file)
            if func then
                if not pcall(func)  then
                    print(string.format("ERROR:failed to exec '%s'", file))
                    return {}
                else
                    local all_test_units = {}
                    --[[
                    Iterate the global registry for tables with 
                    key ``is_testing_unit == true ``.
                    Add that table to the list of unit test tables.
                    ]]
                    for k, v in pairs(_G) do
                        if type(v) == 'table' then
                            if v['is_testing_unit'] == true then
                                all_test_units[#all_test_units +1] = v
                            end
                        end
                    end
                    return all_test_units
                end
            else
                print(string.format("ERROR:failed to load '%s'", file))
                return {}
            end
        end
        return iter
    end

    function get_fixtures_for_member_name(t, member_name)
        if not t.fixtures[member_name] then return {{}} end
        return t.fixtures[member_name]
    end

    local function run_test_unit(t)
        --[[ Search each identified table ``t`` for member functions named ``test*``
        and execute each one within pcall, identifying and counting failures, 
        expected failures, and execution errors.
        ]]
        local is_expected_failure
        local last_assertion
        
        --[[We inject the following function into the test table so we can reference 
        ``last_assertion`` as a nonlocal variable, and the test table can call self:_assertion_failure()
        ]]
        local function _assertion_failure(self, ...)
            last_assertion = {...}
        end
        t._assertion_failure = _assertion_failure
        
        --iterate all callables and iterate/call with any supplied fixtures
        for k, v in pairs(t) do
            if type(v) == 'function' or (type(v) == 'table' and getmetatable(v) ~= nil and type(getmetatable(v)['__call']) == 'function') then
                local func_name, callable = k, v
                if string.match(string.lower(func_name), '^test') then
                    for _, fixture in ipairs(get_fixtures_for_member_name(t, func_name)) do
                        --[[
                            Expected failures are indicated by naming convention 
                            rather than decorators or similar conventions used in other languges.
                            The following member functions will be treated as expected failures:
                                test_myfunction_expected_fail'
                                'TestExpectedFailure'
                                'test_myfunctionExpected_failREALLYUGLY'
                            Basically any sane name beginning with 'test' having the 
                            substrings, 'expected' and 'fail' following.
                            See pattern below for details.
                            
                        ]]
                        is_expected_failure = false
                        last_assertion = nil
                        if string.match(string.lower(func_name), '^test[%a%d_]*expected[%a%d_]*fail') then
                            --[[The expected failure handling is a hack relying on 
                            the nonlocal variable ``last_assertion`` as semi-global state,
                            but it significantly simplifies the assert_*  family of functions
                            and that's a good thing.
                            ]]
                            is_expected_failure = true
                        end
                        
                        
                        --execute the test with data
                        if t.setup then t:setup(callable, fixture) end
                            local success, ret
                            if #fixture > 0 then
                                success, ret = pcall(callable, t, unpack(fixture))
                            else
                                success, ret = pcall(callable, t)
                            end
                            n_tests_run = n_tests_run + 1
                            if not success then 
                                errors[#errors +1] = {name=func_name, err=ret, args=fixture}
                                break
                            end
                        if t.teardown then t:teardown(callable, fixture) end
                        
                        if is_expected_failure then
                            if not last_assertion then
                                n_tests_failed = n_tests_failed + 1
                                failures[#failures +1] = {
                                    err=string.format("%s: did not fail as expected", func_name), 
                                    info=debug.getinfo(callable),
                                    args=#fixture > 0 and fixture or nil
                                }
                            else
                                n_tests_expected_failed = n_tests_expected_failed +1
--                                n_tests_passed = n_tests_passed +1
                            end
                        else
                            if last_assertion then
                                n_tests_failed = n_tests_failed + 1
                                failures[#failures +1] = last_assertion
                            else
                                 n_tests_passed = n_tests_passed +1
                            end
                        end
                    end
                end
            end
        end
    end

    --actually run all the tests
    save_globals()
    start_time = os.time()
        for t in load_each_test_file_iter(all_test_files) do
            if t then
                for _, v in ipairs(t) do
                    run_test_unit(v)
                end
            end
            reset_globals()
        end
    stop_time = os.time()
    
    local function _print_results()
        for _, f in ipairs(failures) do
            print("================================")
            print("FAILURE:")
            for k, v in pairs(f[1]) do
                print(k, v)
            end
            print("--------------------------------")
        end
        for _, e in ipairs(errors) do
            n_test_errors = n_test_errors + 1
            print("================================")
            print("ERROR:execution failure")
            for k, v in pairs(e) do
                print(k, v)
            end
            print("--------------------------------")
        end
    end
    _print_results()
    print(string.format([[Ran %s tests in %s seconds.
        %s failures, %s expected failures, %s errors, %s passed]],
        n_tests_run, 
        os.difftime(stop_time, start_time), 
        n_tests_failed, 
        n_tests_expected_failed, 
        n_test_errors,
        n_tests_passed)
    )
    return n_tests_failed
end




return runtests(find_test_files({'../tests', }, 1, "*.lua"))
