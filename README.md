TestingUnit
===========

Another unit testing library for Lua inspired by Python's `unittest`.

TestingUnit is a very simple but fairly featureful and useful unit test runner for Lua that does auto test descovery, fixtures, and expected failures.

Quick Start
===========
```lua
   mytest = TestingUnit{
    --[[ The testing unit base is overridden with your test method.
        All test methods are functions accepting ``self`` by convention.
    ]]
    
    --[[The fixtures table is queried for tables matching the test method name.
    
    ]]
    fixtures = {
        test_fixtures_equals={{1, 2}, {22, 22}, {'hello', 'hello'}},
        test_fixtures_raises={{1,2,3,function()end}, {'a', 'b', 'c', {}}, {{},{},{},{}}},
        test_fixtures_nan_equal_expected_failure=(function()
            --generate our fixtures dynamically
            local t = {} 
            for i= 1, 1000000 do 
                t[i] = {math.random()}
            end 
            return t 
        end)(),
    },
    
    setup = function(self, test_func, args)
        -- do your setup here.  Called before every test if defined.   
    end,
    
    teardown = function(self, test_func, args)
        --cleanup in aisle 2.  Called after every test if defined.
    end,
    
    test_equals = function(self)
        --[[all callable members whose name begins with `test` are 
            autodiscovered by the test runner.
        ]]
            self:assert_equal(1, 2) --(fails)
    end,
    
    test_in = function(self)
        --TestingUnit supports testing container membership
        self:assert_in('hello', 'world')            --(fails)
        self:assert_in({1,2, hello='world', 9})     --(passes)
    end,
    
    test_a_calls_b = function(self)
        --[[TestingUnit has inbuilt support for checking that certain 
        functions call others, allowing you to test your assumptions 
        about lower abstraction levels/confirm certain conditions.
        ]]
        
        --first define some functions we want to check call other
        local function a() return("hello from a()") end
        local function b() print("Hello from b()") end
        local function c() print(a()) end
        
        self:assert_calls(c, a)         --(passes)
        self:assert_calls(a, b, {7})    --(fails)
    end,
    
    test_fixtures_equals = function(self, x, y)
        --[[ Tests with valid fixture data will be called 
        once per fixture with those values as arguments.
        ]]
        self:assert_equal(x, y)
    end,
    
    test_fixtures_raises = function(self, w, x, y, z)
        --[[table concat does not convert non atomic types. This test assumes 
        that behaviour will not change.
        Our test fixtures have one non-atomic argument per fixture.
        
        self:assert_raises(function() return table.concat({w,x,y,z}, '|')end)
    
    end,
    
    
    --functions with variations of ``expected failure`` in their name 
    --will be treated as expected failures by the test runner
    test_fixtures_nan_equal_expected_failure = function(self, x)
        --[[(0/0) is guaranteed by ieee754 to never compare as equal to any value.
        Whatever the value of our fixture, this test will expected-fail 
        when the machine is ieee754
        ]]
        self:assert_equal(a, 0/0) 
    end,
```

Save that file as `tests.lua` and run the `testingunit` script from the same directory.  All the tests will be automatically discovered, loaded and run, and you will get output like the following:

    loading	tests.lua...
    loading	tests_readme.lua...
    hello from a()
    ================================
    FAILURE:
    info	table: 0x4714ccb8
    err	assert_calls failure:'[tests_readme.lua]:50' not called by '[tests_readme.lua]:49 with args(7)'
    --------------------------------
    ================================
    FAILURE:
    info	table: 0x4714d308
    err	'nil' not found in 'table: 0x4714d1b8'
    --------------------------------
    ================================
    FAILURE:
    args	table: 0x408db270
    err	assert_equal failed: 1 ~= 2
    --------------------------------
    ================================
    FAILURE:
    args	table: 0x4714d950
    err	assert_equal failed: 1 ~= 2
    --------------------------------
    ================================
    ERROR:execution failure
    args	table: 0x4714d538
    name	test_stupidity_gets_handled
    err	tests_readme.lua:83: attempt to perform arithmetic on a string value
    --------------------------------
    Ran 1000010 tests in 4 seconds.
            4 failures, 1000000 expected failures, 1 errors, 5 passed


