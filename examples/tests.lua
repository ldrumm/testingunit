function mecall(...)end
function theycalled(...)end
function mycallee(a,b,c) return 'returnval'end
function mycaller(...) return mycallee(unpack(...))end
function myotherfunc()end

other_failing = TestingUnit{
    test_false = function(self) self:assert_false(0) end,
    test_equal = function(self) self:assert_equal(8, 'nope') end,
    test_another_equal = function(self) self:assert_equal(9, 7) end,
    test_in_string = function(self) self:assert_in('darkness ', 'morning sunshine!') end,
    test_in_table = function(self) self:assert_in('darkness', {'hello', 9, k=function()end}) end,
    test_calls = function(self) self:assert_calls(nil, mycallee, 4) end,
    test_match = function(self) self:assert_match("This string isn't a substring", "of this one") end,
}

failing = TestingUnit{
    test_false = function(self) self:assert_false(0) end,
    test_equal = function(self) self:assert_equal(8, 'nope') end,
    test_another_equal = function(self) self:assert_equal(9, 7) end,
    test_in_string = function(self) self:assert_in('darkness ', 'morning sunshine!') end,
    test_in_table = function(self) self:assert_in('darkness', {'hello', 9, k=function()end}) end,
    test_calls = function(self) self:assert_calls(mycaller, myotherfunc, {4, 5, 6}) end,
    test_match = function(self) self:assert_match("This string isn't a substring", "of this one") end,
}

passing  = TestingUnit{
    test_false = function(self) self:assert_false(false) end,
    test_true = function(self) self:assert_true(true) end,
    test_raises = function(self) self:assert_raises(function() return 0 / '' end) end,
    test_in_string = function(self) self:assert_in('darkness ', 'Hello darkness my old friend') end,
    test_in_table = function(self) self:assert_in(9, {1,2,3,4,5,6,7,8,9, k=function()end}) end,
    test_calls = function(self) self:assert_calls(mycaller, mycallee, {4, 5, 6}) end,
    test_truthy = function(self) self:assert_truthy(0) end,
    test_nil = function(self) self:assert_nil() end,
    test_match = function(self) self:assert_match("123", '[0-9]') end
}

