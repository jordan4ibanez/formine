module luajit
  use, intrinsic :: iso_c_binding
  implicit none


  private

  !* Why yes, I did have to read the way too much documentation to do this.
  ! References:
  ! https://lucasklassmann.com/blog/2019-02-02-embedding-lua-in-c/
  ! https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lua.h#L43
  ! https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/luajit.c
  ! https://www.lua.org/manual/2.4/node18.html
  ! And I pretty much have to search through the LuaJIT source code for anything else.
  !
  !! For Fortran function see: https://www.lua.org/pil/26.1.html
  ! Lua Fortran functions:
  ! typedef int (*lua_CFunction) (lua_State *L);

  public :: luajit_initialize
  public :: luajit_destroy
  public :: luajit_run_string
  public :: luajit_run_file


  integer(c_int), parameter :: LUA_OK = 0
  integer(c_int), parameter :: LUA_YIELD = 1
  integer(c_int), parameter :: LUA_ERRRUN = 2
  integer(c_int), parameter :: LUA_ERRSYNTAX = 3
  integer(c_int), parameter :: LUA_ERRMEM = 4
  integer(c_int), parameter :: LUA_ERRERR = 5


  type(c_ptr) :: lua_state


  interface


    function lual_newstate() result(new_state) bind(c, name = "luaL_newstate")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr) :: new_state
    end function lual_newstate


    !* This makes the LuaJIT standard library available.
    subroutine lual_openlibs(state) bind(c, name = "luaL_openlibs")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
    end subroutine lual_openlibs


    subroutine lua_close(state) bind(c, name = "lua_close")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
    end subroutine lua_close


    function lual_loadstring(state, string) result(status) bind(c, name = "luaL_loadstring")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      character(kind = c_char), intent(in) :: string
      integer(c_int) :: status
    end function lual_loadstring


    function lua_call(state, number_of_args, number_of_results) result(status) bind(c, name = "lua_call")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      integer(c_int), intent(in), value :: number_of_args, number_of_results
      integer(c_int) :: status
    end function lua_call


    function lua_pcall(state, number_of_args, number_of_results, error_function) result(status) bind(c, name = "lua_pcall")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      integer(c_int), intent(in), value :: number_of_args, number_of_results, error_function
      integer(c_int) :: status
    end function lua_pcall


    function lua_cpcall(state, func, unknown_data) result(status) bind(c, name = "lua_cpcall")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      type(c_funptr), intent(in), value :: func
      type(c_ptr), intent(inout) :: unknown_data
      integer(c_int) :: status
    end function lua_cpcall


    function lua_gettop(state) result(index) bind(c, name = "lua_gettop")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      integer(c_int) :: index
    end function lua_gettop


    subroutine lua_settop(state, index) bind(c, name = "lua_settop")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      integer(c_int), intent(in), value :: index
    end subroutine lua_settop


  end interface


contains


  !* Create the actual LuaJIT state that we will use.
  subroutine luajit_initialize()
    implicit none

    if (c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Tried to initialize LuaJIT when already initialized."
    end if

    lua_state = lual_newstate()

    if (.not. c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Failed to initialize."
    end if

    ! Make the entire standard library available.
    !! Is this safe for the end user when using external mods? HELL NO.
    call lual_openlibs(lua_state)
  end subroutine luajit_initialize


  !* Clean up the memory used by LuaJIT and destroy it.
  subroutine luajit_destroy()
    implicit none

    if (.not. c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Tried to destroy LuaJIT when not initialized."
    end if

    call lua_close(lua_state)

    ! Nullify. Allows re-initialization.
    lua_state = c_null_ptr
  end subroutine luajit_destroy


  !* Pop the stack. This was a macro in LuaJIT.
  subroutine lua_pop(index)
    implicit none

    integer(c_int), intent(in), value :: index

    call lua_settop(lua_State, -(index) - 1)
  end subroutine lua_pop



  !* Run a LuaJIT string.
  subroutine luajit_run_string(string_to_run)
    use :: string
    implicit none

    character(len = *), intent(in) :: string_to_run
    character(len = :, kind = c_char), allocatable :: c_string

    c_string = into_c_string(string_to_run)

    if (lual_loadstring(lua_state, c_string) == LUA_OK) then
      if (lua_pcall(lua_state, 0, 0, 0) == LUA_OK) then
        ! If code was executed successfully, we remove the code from the stack.
        call lua_pop(lua_gettop(lua_state))
      end if
    end if
  end subroutine luajit_run_string


  !* Run a LuaJIT file.
  subroutine luajit_run_file(file_path)
    use :: string
    use :: files
    implicit none

    character(len = *, kind = c_char), intent(in) :: file_path
    type(file_reader) :: reader
    character(len = :, kind = c_char), allocatable :: c_string

    call reader%read_file(file_path)

    if (.not. reader%exists) then
      error stop "[LuaJIT] Error: Could not load file path ["//file_path//"]. Does not exist."
    end if

    c_string = into_c_string(reader%file_string)

    if (lual_loadstring(lua_state, c_string) == LUA_OK) then
      if (lua_pcall(lua_state, 0, 0, 0) == LUA_OK) then
        ! If code was executed successfully, we remove the code from the stack.
        call lua_pop(lua_gettop(lua_state))
      end if
    else
      error stop "[LuaJIT] Error: Failed to load file path ["//file_path//"] into the VM."
    end if
  end subroutine luajit_run_file


end module luajit
