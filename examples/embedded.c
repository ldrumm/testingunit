#include <lua5.2/lauxlib.h>
#include <lua5.2/lualib.h>

int 
run_lua_tests(lua_State *L, char *test_file, const char *test_string)
{
    int err = 0;
    if(test_file){
        err = luaL_dofile(L, test_file);
        if(err){
            fprintf(stderr, "could not run tests:%s\n", lua_tostring(L, -1));
		    return -1;
        }
    }
    if(test_string){
	    err = luaL_loadstring(L, test_string);
	    if(err || lua_pcall(L, 0, 1, 0)){
	        fprintf(stderr, "could not run tests:%s\n", lua_tostring(L, -1));
		    return -1;
	    }
	    err = luaL_checkinteger(L, -1);
	    return err;
	}
}
int main(void)
{
    lua_State * L = luaL_newstate();
    luaL_openlibs(L);
    //... Do setup and junk for embedded lua.
    
    return run_lua_tests(L, 
        "../src/testingunit.lua", 
        "return runtests(find_test_files({'.'}, 1, \"*.lua\"))"
    );
}
