module h_string
  implicit none


  private


  public :: heap_string


  !** A heap string is a string on the heap. Amazing, I know.
  type heap_string
    private
    character(len = :), allocatable :: data
  contains
    !? Assignment.
    generic :: assignment(=) => assign
    procedure :: assign
    !? Equality check.
    generic :: operator(==) => equal_heap_string, equal_raw_string
    procedure :: equal_heap_string
    procedure :: equal_raw_string
    !? Print formatting.
    generic :: write(formatted) => write_formatted
    procedure :: write_formatted
    !? Allocated check.
    procedure :: is_allocated
    !? Get internal data.
    procedure :: get
    !? Append another string to it.
    procedure :: append
    !? Prepend another string to it.
    procedure :: prepend
    !? Strip all leading and trailing white space off the string.
    procedure :: strip
  end type heap_string


  !** heap_string constructor.
  interface heap_string
    module procedure :: init
  end interface heap_string


contains


  !** heap_string constructor.
  function init(optional_string) result(new_str)
    implicit none

    character(len = *), intent(in), optional :: optional_string
    type(heap_string) :: new_str

    if (present(optional_string)) then
      new_str%data = optional_string
    end if
  end function init


  !** Very simple assignment operator.
  subroutine assign(this, new_data)
    implicit none

    class(heap_string), intent(inout) :: this
    character(len = *), intent(in) :: new_data

    this%data = new_data
  end subroutine assign


  !** Equality check with another heap string.
  logical function equal_heap_string(this, other) result(res)
    implicit none

    class(heap_string), intent(in) :: this
    type(heap_string), intent(in) :: other

    res = this%data == other%data .and. len(this%data) == len(other%data)
  end function equal_heap_string


  !** Equality check with a raw string.
  logical function equal_raw_string(this, other) result(res)
    implicit none

    class(heap_string), intent(in) :: this
    character(len = *), intent(in) :: other

    res = this%data == other .and. len(this%data) == len(other)
  end function equal_raw_string


  !** Simply allows you to use a heap string like a regular string.
  subroutine write_formatted(this, unit, iotype, v_list, iostat, iomsg)
    implicit none

    class(heap_string), intent(in) :: this
    integer, intent(in) :: unit         ! Internal unit to write to.
    character(*), intent(in) :: iotype  ! LISTDIRECTED or DTxxx
    integer, intent(in) :: v_list(:)    ! parameters from fmt spec.
    integer, intent(out) :: iostat      ! non zero on error, etc.
    character(*), intent(inout) :: iomsg  ! define if iostat non zero.

    if (.false.) then
      print*,iotype, v_list
    end if

    write (unit,"(A)", iostat = iostat, iomsg = iomsg) this%data
  end subroutine write_formatted



  !** Very simple check to see if the internal data is allocated.
  logical function is_allocated(this) result(res)
    implicit none

    class(heap_string), intent(inout) :: this

    res = allocated(this%data)
  end function is_allocated


  !** Get the internal data of the heap string.
  !? Aka, what it is pointing to on the heap basically.
  function get(this) result(data)
    implicit none

    class(heap_string), intent(inout) :: this
    character(len = :), allocatable :: data

    data = this%data
  end function get


  !** Append another string onto this string.
  subroutine append(this, other)
    implicit none

    class(heap_string), intent(inout) :: this
    character(len = *), intent(in) :: other

    ! Very simple operation. The ol' swap.
    this%data = this%data//other
  end subroutine append


  !** Prepend another string onto this string.
  subroutine prepend(this, other)
    implicit none

    class(heap_string), intent(inout) :: this
    character(len = *), intent(in) :: other

    ! Very simple operation. The ol' swap.
    this%data = other//this%data
  end subroutine prepend


  !** Strip leading and trailing white space off a string.
  subroutine strip(this)
    implicit none

    class(heap_string), intent(inout) :: this

    this%data = trim(adjustl(this%data))
  end subroutine strip


end module h_string
