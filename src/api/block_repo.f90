module block_repo
  use :: luajit
  use :: string
  use :: fhash, only: fhash_tbl_t, key => fhash_key
  use, intrinsic :: iso_c_binding
  implicit none


  private


  public :: block_definition
  public :: block_repo_get_definition_pointer_by_id
  public :: block_repo_deploy_lua_api
  public :: register_block


  !* Bake the module name into the executable.

  character(len = 12, kind = c_char), parameter :: module_name = "[Block Repo]"


  !* Block draw types.

  ! This is a simple range check that can be used to verify input draw_type.
  ! If new draw_types are added, syncronize the max.
  integer(c_int), parameter :: DRAW_TYPE_MIN = 0
  integer(c_int), parameter :: DRAW_TYPE_MAX = 1

  integer(c_int), parameter :: DRAW_TYPE_AIR = 0
  integer(c_int), parameter :: DRAW_TYPE_NORMAL = 1


  !* Block definition.
  !* 200 bytes in size. (at time of writing)
  !* 1_000_000 definitions would take up 200 mb.

  type :: block_definition
    character(len = :, kind = c_char), allocatable :: name
    character(len = :, kind = c_char), allocatable :: description
    type(heap_string), dimension(:), allocatable :: textures
    integer(c_int) :: draw_type = DRAW_TYPE_AIR
  end type block_definition


  !* Block database.
  !*
  !* Since this is attempted to utilize the CPU cache to the extreme,
  !* we will have some ground rules laid out.
  !*
  !* The idea is: We want the memory to be contiguous.
  !*
  !* It will be extremely unsafe if we do not follow these rules.
  !*
  !! Ground rules:
  !*
  !* The array will live in the heap as an allocated smart pointer.
  !*
  !* Block definitions will be created as the game starts up.
  !*
  !* Blocks will not be deleted during the game runtime.
  !*
  !* The string database will simply point to an index in the array via a raw pointer.
  !* This is here for when we need to access into the array.
  !*
  !* LuaJIT will never have access to the direct block_definition pointer.
  !*
  !* LuaJIT shall have it's own copy of the database which will be immutable with metatables.
  !*
  !* No block shall share an ID. The history of the block IDs will be held in the world database. (when that is created)
  !*
  !* As new blocks are added in, they will incremement the available ID.
  !*

  integer(c_int) :: current_id = 1
  integer(c_int) :: definition_array_length = 0

  ! Random access oriented.
  type(fhash_tbl_t) :: definition_database_string

  ! Object oriented.
  type(block_definition), dimension(:), allocatable, target :: definition_array

  ! Data oriented.
  integer(c_int) :: draw_type = DRAW_TYPE_AIR



contains


  !* Get a definition pointer by the ID.
  function block_repo_get_definition_pointer_by_id(id) result(definition_pointer)
    implicit none

    integer(c_int), intent(in), value :: id
    type(block_definition), pointer :: definition_pointer

    definition_pointer => definition_array(id)
  end function block_repo_get_definition_pointer_by_id


  !* This hooks the required fortran functions into the LuaJIT "blocks" table.
  subroutine block_repo_deploy_lua_api(state)
    implicit none

    type(c_ptr), intent(in), value :: state


    !* Create the base smart pointer of the block array.
    allocate(definition_array(0))


    ! Memory layout: (Stack grows down.)
    ! -1 - blocks = {}
    ! then moves to:
    ! -3 - blocks = {}
    ! -2 - table key string.
    ! -1 - function pointers.
    ! Then we pop -2 and -1 off the stack, shifting blocks back to -1.


    call lua_getglobal(state, "block")

    if (.not. lua_istable(state, -1)) then
      error stop "[Block Repo] Error: Can't initialize function pointers. [blocks] table is missing!"
    end if

    ! Swap the declaration with the actual fortran function.
    call luajit_swap_table_function(state, "register", c_funloc(register_block))


    ! Now clear the stack. We're done with the block LuaJIT table.
    call lua_pop(state, lua_gettop(state))
  end subroutine block_repo_deploy_lua_api


  !* This allows you to register a block into the engine from LuaJIT.
  !* See the LuaJIT API [./api/init.lua] for the layout of block_definition.
  recursive function register_block(state) result(status) bind(c)
    use :: string
    use :: array, only: string_array
    implicit none

    type(c_ptr), intent(in), value :: state
    ! We're going to be using the status quite a lot.
    integer(c_int) :: status
    ! block_definition fields.
    type(heap_string) :: name, description
    type(string_array) :: textures
    integer(c_int) :: draw_type
    !* The smart pointer where we will store the block definiton.
    !* We will only allocate this after a successful data query from LuaJIT.
    type(block_definition) :: new_definition

    status = LUAJIT_GET_OK

    ! Enforce the first and only argument to be a table.
    if (.not. lua_istable(state, -1)) then
      call luajit_error_stop(state, module_name//" Error: Cannot register block. Not a table.")
    end if

    ! Name is required.
    call luajit_table_get_key_required(state, module_name, "definition", "name", name, "string")

    !! If it is "air" silent abord.
    if (name%get() == "air") then
      print"(A)", module_name//" warning: Please do not try to register air."
      call lua_pop(state, lua_gettop(state))
      return
    end if

    ! Description is required.
    call luajit_table_get_key_required(state, module_name, "definition", "description", description, "string")

    ! Now we need to get the table which contains the textures.
    call luajit_put_table_in_table_on_stack_required(state, module_name, "definition", "textures", "Array<string>")

    status = luajit_copy_string_array_from_table(state, textures)

    if (status /= LUAJIT_GET_OK) then
      if (status == LUAJIT_GET_MISSING) then
        call luajit_error_stop(state, module_name//" error: Table [definition] key table [textures] is missing.")
      else
        call luajit_error_stop(state, module_name//" error: Table [definition] key table [textures] has a non-string element.")
      end if
    end if


    ! Now we get rid of the string table.
    call lua_pop(state, 1)

    ! We're back into the block_definition table.

    ! draw_type is required. This will auto push and pop the target table so
    ! we're still at the definition table being at -1.
    call luajit_table_get_key_required(state, module_name, "definition", "draw_type", draw_type, "draw_type")


    !* todo: can add in more definition components here. :)


    ! Clean up the stack. We are done with the LuaJIT stack.
    !? The definition table has now disappeared.
    call lua_pop(state, lua_gettop(state))



    ! We have completed a successful query of the definition table from LuaJIT.
    ! Put all the data into the fortran database.

    new_definition%name = name%get()
    new_definition%description = description%get()
    new_definition%textures = textures%data
    new_definition%draw_type = draw_type

    ! print"(A)", module_name//": Current Block definition:"
    ! print"(A)", "Name: "//definition_pointer%name
    ! print"(A)", "Description: "//definition_pointer%description
    ! print*, "Textures: [",definition_pointer%textures,"]"
    ! print"(A)", "draw_type: "//int_to_string(definition_pointer%draw_type)

    ! Copy the definition into the string based database.
    call definition_database_string%set(key(new_definition%name), new_definition)

    definition_array = [definition_array, new_definition]

    definition_array_length = definition_array_length + 1
    current_id = current_id + 1
  end function register_block


end module block_repo
