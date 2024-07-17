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
    !? Allocated check.
    procedure :: is_allocated
    !? Get internal data.
    procedure :: get
    !? Append another string to it.
    procedure :: append
    !? Prepend another string to it.
    procedure :: prepend
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

    class(heap_string) :: this
    character(len = *), intent(in) :: other
    character(len = :), allocatable :: worker

    ! Very simple operation. The ol' swap.
    worker = this%data//other
    this%data = worker
  end subroutine append


  !** Prepend another string onto this string.
  subroutine prepend(this, other)
    implicit none

    class(heap_string) :: this
    character(len = *), intent(in) :: other
    character(len = :), allocatable :: worker

    ! Very simple operation. The ol' swap.
    worker = other//this%data
    this%data = worker
  end subroutine prepend


end module h_string
