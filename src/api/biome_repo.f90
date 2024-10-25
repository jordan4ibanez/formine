module biome_repo
  use, intrinsic :: iso_c_binding
  use :: luajit
  use :: string
  use :: hashmap_str
  use :: vector
  implicit none


  private


  public :: initialize_biome_repo_module
  public :: biome_definition
  public :: biome_repo_deploy_lua_api
  public :: register_biome
  public :: biome_repo_destroy

  !* Bake the module name into the executable.

  character(len = 12, kind = c_char), parameter :: module_name = "[Biome Repo]"



  !* This is what lua will send into a queue to be processed after
  !* all biome definition have been processed into the engine.

  type :: biome_definition_from_lua
    character(len = :, kind = c_char), pointer :: name => null()
    character(len = :, kind = c_char), pointer :: grass_layer => null()
    character(len = :, kind = c_char), pointer :: dirt_layer => null()
    character(len = :, kind = c_char), pointer :: stone_layer => null()
  end type biome_definition_from_lua


  !* Biome definition container.

  type :: biome_definition
    character(len = :, kind = c_char), pointer :: name => null()
    integer(c_int) :: grass_layer = 0
    integer(c_int) :: dirt_layer = 0
    integer(c_int) :: stone_layer = 0
  end type biome_definition


  ! Random access oriented.
  !* Type: biome_definition.
  type(hashmap_string_key) :: definition_database


  ! Linear access oriented.
  !* Type: biome_definition
  !? NOTE: the definition_database is the one responsible for cleaning up the pointers.
  type(vec) :: definition_array


  ! Random access oriented.
  !* Type: biome_definition_from_lua
  type(hashmap_string_key) :: definition_database_from_lua


  ! Linear access oriented.
  !* Type: biome_definition_from_lua
  !? NOTE: the definition_database is the one responsible for cleaning up the pointers.
  type(vec) :: definition_array_from_lua


contains


  subroutine initialize_biome_repo_module()
    implicit none

    type(biome_definition) :: blank
    type(biome_definition_from_lua) :: blank_lua

    !* Type: biome_definition
    definition_database = new_hashmap_string_key(sizeof(blank), gc_definition_repo)

    !* Create the base smart pointer of the biome array.
    definition_array = new_vec(sizeof(blank), 0_8)

    !* Type: biome_definition_from_lua
    definition_database_from_lua = new_hashmap_string_key(sizeof(blank_lua), gc_definition_repo_from_lua)

    !* Create the base smart pointer of the biome array.
    definition_array_from_lua = new_vec(sizeof(blank_lua), 0_8)
  end subroutine initialize_biome_repo_module


  !* This hooks the required fortran functions into the LuaJIT "biome" table.
  subroutine biome_repo_deploy_lua_api(state)
    implicit none

    type(c_ptr), intent(in), value :: state

    ! Memory layout: (Stack grows down.)
    ! -1 - biome = {}
    ! then moves to:
    ! -3 - biome = {}
    ! -2 - table key string.
    ! -1 - function pointers.
    ! Then we pop -2 and -1 off the stack, shifting biome back to -1.


    call lua_getglobal(state, "biome")

    if (.not. lua_istable(state, -1)) then
      error stop "[Biome Repo] Error: Can't initialize function pointers. [biome] table is missing!"
    end if

    ! Swap the declaration with the actual fortran function.
    call luajit_swap_table_function(state, "register", register_biome)


    ! Now clear the stack. We're done with the biome LuaJIT table.
    call lua_pop(state, lua_gettop(state))
  end subroutine biome_repo_deploy_lua_api


  !* This allows you to register a biome into the engine from LuaJIT.
  !* See the LuaJIT API [./api/init.lua] for the layout of biome_definition.
  recursive function register_biome(state) result(status) bind(c)
    use :: string
    use :: array, only: string_array
    implicit none

    type(c_ptr), intent(in), value :: state
    ! We're going to be using the status quite a lot.
    integer(c_int) :: status
    ! biome_definition fields.
    type(heap_string) :: name, grass_layer, dirt_layer, stone_layer
    !* The smart pointer where we will store the biome definiton.
    !* We will only allocate this after a successful data query from LuaJIT.
    type(biome_definition_from_lua) :: new_definition

    status = LUAJIT_GET_OK

    ! Enforce the first and only argument to be a table.
    if (.not. lua_istable(state, -1)) then
      call luajit_error_stop(state, module_name//" Error: Cannot register biome. Not a table.")
    end if

    ! All components of the biome definition are required. (For now)
    call luajit_table_get_key_required(state, module_name, "Biome Definition", "name", name, "string")

    call luajit_table_get_key_required(state, module_name, "Biome Definition", "grass_layer", grass_layer, "string")

    call luajit_table_get_key_required(state, module_name, "Biome Definition", "dirt_layer", dirt_layer, "string")

    call luajit_table_get_key_required(state, module_name, "Biome Definition", "stone_layer", stone_layer, "string")



    !* todo: can add in more definition components here. :)


    ! Clean up the stack. We are done with the LuaJIT stack.
    !? The definition table has now disappeared.
    call lua_pop(state, lua_gettop(state))


    ! We have completed a successful query of the definition table from LuaJIT.
    ! Put all the data into the fortran database.

    call string_copy_pointer_to_pointer(name%get_pointer(), new_definition%name)

    call string_copy_pointer_to_pointer(grass_layer%get_pointer(), new_definition%grass_layer)

    call string_copy_pointer_to_pointer(dirt_layer%get_pointer(), new_definition%dirt_layer)

    call string_copy_pointer_to_pointer(stone_layer%get_pointer(), new_definition%stone_layer)

    ! print*,new_definition%name
    ! print*,new_definition%grass_layer
    ! print*,new_definition%dirt_layer
    ! print*,new_definition%stone_layer

    ! Copy the definition into the string based database.
    call definition_database_from_lua%set(name%string, new_definition)

    call definition_array_from_lua%push_back(new_definition)
  end function register_biome


  subroutine biome_repo_destroy()
    implicit none

    call definition_database%destroy()
    call definition_array%destroy()
  end subroutine biome_repo_destroy


  subroutine gc_definition_repo(raw_c_ptr)
    implicit none

    type(c_ptr), intent(in), value :: raw_c_ptr
    type(biome_definition), pointer :: definition_pointer

    call c_f_pointer(raw_c_ptr, definition_pointer)

    deallocate(definition_pointer%name)
  end subroutine gc_definition_repo


  subroutine gc_definition_repo_from_lua(raw_c_ptr)
    implicit none

    type(c_ptr), intent(in), value :: raw_c_ptr
    type(biome_definition_from_lua), pointer :: definition_pointer

    call c_f_pointer(raw_c_ptr, definition_pointer)

    deallocate(definition_pointer%name)
    deallocate(definition_pointer%grass_layer)
    deallocate(definition_pointer%dirt_layer)
    deallocate(definition_pointer%stone_layer)
  end subroutine gc_definition_repo_from_lua


end module biome_repo
