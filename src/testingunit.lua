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
            all_files[#all_files + 1] = v
        end
    end
    return all_files
end


function load_test_files(dirs)
    --discover all lua test scripts in the given directories and protected load them
    --TODO turn this into an iterator, so that variable name clashes don't matter.
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

function get_fixtures_for_member_name(t, member_name)
    if not t.fixtures[member_name] then return {{}} end
    return t.fixtures[member_name]
end

function runtests()
    local all_test_units = {}
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
    
    --[[
    Iterate the global registry for tables with key ``is_testing_unit == true `` 
    and add that table to the list of unit test tables.
    ]]
    for k, v in pairs(_G) do
        if type(v) == 'table' then
            if v['is_testing_unit'] == true then
                all_test_units[#all_test_units +1] = v
            end
        end
    end

    local function _run_test_unit(t)
        --[[ Search each identified table ``t`` for member functions named ``test*``
        and execute each one within pcall, identifying and counting failures, 
        expected failures, and execution errors.
        ]]
        local is_expected_failure
        local last_assertion
        
        --[[We inject the following function into the test table so we can reference 
        ``assertion_triggered`` as a nonlocal variable
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
    start_time = os.time()
        for _, v in pairs(all_test_units) do
            _run_test_unit(v)
        end
    stop_time = os.time()
    
    local function _print_results(t)
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
    for _, v in pairs(all_test_units) do
        _print_results(v)
    end
    
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



--function main()
--    local dirs = parse_args()['dirs']
--    for k, v in pairs(args) do print (k, v) end
load_test_files({'.'})
return runtests()
