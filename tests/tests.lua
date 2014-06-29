function mecall(...)end
function theycalled(...)end
function mycallee(a,b,c) return 'returnval'end
function mycaller(...) return mycallee(unpack(...))end
function myotherfunc()end

failing = TestingUnit{
    test_false_expected_failure = function(self) self:assert_false(0) end,
    test_equal_expected_failure = function(self) self:assert_equal(8, 'nope') end,
    test_another_equal_expected_failure = function(self) self:assert_equal(9, 7) end,
    test_in_string_expected_failure = function(self) self:assert_in('darkness ', 'morning sunshine!') end,
    test_in_table_expected_failure = function(self) self:assert_in('darkness', {'hello', 9, k=function()end}) end,
    test_calls_expected_failure = function(self) self:assert_calls(mycaller, myotherfunc, {4, 5, 6}) end,
    test_match_expected_failure = function(self) self:assert_match("This string isn't a substring", "of this one") end,
}

other_failing = TestingUnit{
    test_calls_expected_failure = function(self) self:assert_calls(mecall, mycallee, 4) end,
}

passing  = TestingUnit{
    fixtures = {
            test_table_call_with_args = {{1, 1}}
    },
    test_false = function(self) self:assert_false(false) end,
    test_true = function(self) self:assert_true(true) end,
    test_raises = function(self) self:assert_raises(function() return 0 / '' end) end,
    test_in_string = function(self) self:assert_in('Hello darkness my old friend', 'darkness ' ) end,
    test_in_table = function(self) self:assert_in({1,2,3,4,5,6,7,8,9, k=function()end},9 ) end,
    test_calls = function(self) self:assert_calls(mycaller, mycallee, {4, 5, 6}) end,
    test_truthy = function(self) self:assert_truthy(0) end,
    test_nil = function(self) self:assert_nil() end,
    test_match = function(self) self:assert_match("123", '[0-9]') end,
    test_match2 = function(self) self:assert_match("123", ".+") end,
    test_table_call_with_args = setmetatable({}, {__call=function(self, test_unit, a, b) test_unit:assert_equal(a,b) end})
}

expected = TestingUnit{
    fixtures = {
        test_fixtures_expected_failure={{1,2,3}, {4,5,6}, {7,8,9}},
    },
    test_false_expected_failure = function(self) self:assert_false(0) end,
    test_equal_expected_failure = function(self) self:assert_equal(8, 'nope') end,
    test_another_equal_expected_failure = function(self) self:assert_equal(9, 7) end,
    test_in_string_expected_failure = function(self) self:assert_in('darkness ', 'morning sunshine!') end,
    test_in_table_expected_failure = function(self) self:assert_in('darkness', {'hello', 9, k=function()end}) end,
    test_calls_expected_failure = function(self) self:assert_calls(mycaller, myotherfunc, {4, 5, 6}) end,
    test_match_expected_failure = function(self) self:assert_match("This string isn't a substring", "of this one") end,
    test_fixtures_expected_failure = function(self, a,b,c)self:assert_equal(a,b)end,
    
}
