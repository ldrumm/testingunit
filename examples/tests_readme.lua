    mytest = TestingUnit{
        --[[ The testing unit base is overridden with your test method.
            All test methods are unary functions accepting ``self`` by convention.
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
