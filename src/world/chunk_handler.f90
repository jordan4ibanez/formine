module chunk_handler
  use :: chunk_data
  use :: fhash, only: fhash_tbl_t, key => fhash_key, fhash_key_char_t
  implicit none


  private


  public :: chunk_handler_store_chunk_pointer
  public :: chunk_handler_get_chunk_pointer


  type(fhash_tbl_t) :: chunk_database



contains


  subroutine chunk_handler_store_chunk_pointer(chunk_to_store)
    use :: string
    implicit none

    type(memory_chunk), intent(in), pointer :: chunk_to_store
    type(fhash_key_char_t) :: chunk_key
    integer(c_int) :: status

    chunk_key = grab_chunk_key(chunk_to_store%world_position%x, chunk_to_store%world_position%y)

    call chunk_database%check_key(chunk_key, stat = status)

    if (status == 0) then
      error stop "[Chunk Handler] Error: Attempted to overwrite a memory chunk pointer."
    end if

    call chunk_database%set_ptr(chunk_key, chunk_to_store)
  end subroutine chunk_handler_store_chunk_pointer


  function chunk_handler_get_chunk_pointer(x, y) result(chunk_pointer)
    implicit none

    integer(c_int), intent(in), value :: x, y
    type(memory_chunk), pointer :: chunk_pointer
    class(*), pointer :: generic_pointer
    integer(c_int) :: status

    call chunk_database%get_raw_ptr(grab_chunk_key(x,y), generic_pointer, stat = status)

    if (status /= 0) then
      error stop "[Chunk Handler] Error: Attempted to retrieve null chunk."
    end if

    select type(generic_pointer)
     type is (memory_chunk)
      chunk_pointer => generic_pointer
     class default
      error stop "[Chunk Handler] Error: The wrong type was inserted into the database."
    end select
  end function chunk_handler_get_chunk_pointer


  subroutine draw_chunks()
    use :: fhash, only: fhash_iter_t, fhash_key_t
    implicit none

    class(fhash_key_t), allocatable :: generic_key
    class(*), allocatable :: generic_placeholder

  end subroutine draw_chunks


  function grab_chunk_key(x, y) result(key_new)
    implicit none

    integer(c_int), intent(in), value :: x, y
    type(fhash_key_char_t) :: key_new

    key_new = key("chunk_"//int_to_string(x)//"_"//int_to_string(y))
  end function grab_chunk_key


end module chunk_handler
