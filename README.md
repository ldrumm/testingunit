TestingUnit
===========

Another unit testing library for Lua inspired by Python's `unittest`.

TestingUnit is a very simple but fairly featureful and useful unit test runner for Lua that does auto test descovery and fixtures and expected failures.

Quick Start
===========

    mytest = TestingUnit{
        --[[ The testing unit base is overridden with your test method.
            All test methods are functions accepting ``self`` as the first argument.
        ]]
        
        test_equals = function(self)
            --[[all callable members whose name begins with `test` are 
                autodiscovered by the test runner.
            ]]
            self:assert_equal(1, 2)
        end,
        
        test_in = function(self)
            --TestingUnit supports testing container membership
            self:assert_in('hello', 'world')            --(fails)
            self:assert_in(9, {1,2, hello='world', 9})   --(passes)
        end,
        
        test_a_calls_b = function(self)
            --[[TestingUnit has inbuilt support for checking that certain functions call others. 
            Allowing you to test your assumptions about lower abstraction levels/confirm certain conditions.
            ]]
            
            --first define some functions we want to check call other
            local function a() return("hello from a()") end
            local function b() print("Hello from b()") end
            local function c() print(a()) end
            
            self:assert_calls(c, a) --(passes)
            self:assert_calls(a, b) --(fails)
        end,
        test_stupidity_gets_handled = function(self)
            --Do something stupid to demonstrate that errors in your tests are also caught and notified
            return 2 / 'hello'
        end,
   }

Save that file as `tests.lua` and run the `testingunit` script from the same directory.  All the tests will be automatically discovered, loaded and run, and you will get output like the following:

    loading	tests.lua...
    hello from a()
    ================================
    FAILURE:
    err	assert_equal failed: 1 ~= 2
    args	table: 0x15af8f0
    --------------------------------
    ================================
    FAILURE:
    err	assert_calls failure:'[tests.lua]:26' not called by '[tests.lua]:25 with args()'
    info	table: 0x15b3330
    --------------------------------
    ================================
    FAILURE:
    err	'world' not found in 'hello'
    info	table: 0x15b3440
    --------------------------------
    ================================
    FAILURE:
    err	type('9') is not a container type
    info	table: 0x15b3f80
    args	table: 0x15b3fd0
    --------------------------------
    ================================
    ERROR:execution failure
    tests.lua:34: attempt to perform arithmetic on a string value
    --------------------------------
    Ran 4 tests in 0 seconds.
            4 failures, 0 expected failures, 1 errors

Fixtures and expected failures will be implemented soon.
