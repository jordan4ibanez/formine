module string
  use, intrinsic :: iso_c_binding
  use :: h_string
  implicit none


  private


  public :: string_from_c
  public :: int_to_string
  public :: into_c_string
  public :: bool_to_string
  public :: heap_string_array
  !? Pass through the type.
  public :: heap_string


contains


  !** Convert an optional variable length string into an integral representation of a boolean.
  !? Exi stands for exists.
  integer function exi(input) result(integer_representation)
    implicit none

    character(len = *), intent(in), optional :: input

    if (present(input)) then
      integer_representation = 1
    else
      integer_representation = 0
    end if
  end function exi


  !** Helper function for heap_string_array
  ! Basically a HUGE chain of if then statements simplified into call.
  subroutine assign_heap_array(arr, slot, data)
    implicit none

    type(heap_string), dimension(:), intent(inout), allocatable :: arr
    integer, intent(in) :: slot
    character(len = *), intent(in), optional :: data

    if (present(data)) then
      arr(slot) = data
    end if
  end subroutine assign_heap_array


  !** Create an array of dynamically sized strings.
  !** Can take upto 26 elements cause I ran out of letters.
  !! This is a substitute for not having varargs.
  function heap_string_array(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) result(heap_array)
    implicit none

    character(len = *), intent(in), optional :: a
    character(len = *), intent(in), optional :: b
    character(len = *), intent(in), optional :: c
    character(len = *), intent(in), optional :: d
    character(len = *), intent(in), optional :: e
    character(len = *), intent(in), optional :: f
    character(len = *), intent(in), optional :: g
    character(len = *), intent(in), optional :: h
    character(len = *), intent(in), optional :: i
    character(len = *), intent(in), optional :: j
    character(len = *), intent(in), optional :: k
    character(len = *), intent(in), optional :: l
    character(len = *), intent(in), optional :: m
    character(len = *), intent(in), optional :: n
    character(len = *), intent(in), optional :: o
    character(len = *), intent(in), optional :: p
    character(len = *), intent(in), optional :: q
    character(len = *), intent(in), optional :: r
    character(len = *), intent(in), optional :: s
    character(len = *), intent(in), optional :: t
    character(len = *), intent(in), optional :: u
    character(len = *), intent(in), optional :: v
    character(len = *), intent(in), optional :: w
    character(len = *), intent(in), optional :: x
    character(len = *), intent(in), optional :: y
    character(len = *), intent(in), optional :: z
    !? Because we need to allocate with unknown width, we must allow this to live in the heap.
    !? This also basically points to other objects in the heap as well.
    type(heap_string), dimension(:), allocatable :: heap_array
    ! integer :: int

    ! Now we only allocate how much we need.
    allocate(heap_array(exi(a)+exi(b)+exi(c)+exi(d)+exi(e)+exi(f)+exi(g)+exi(h)+exi(i)+exi(j)+exi(k)+exi(l)+exi(m)+exi(n)+exi(o)+exi(p)+exi(q)+exi(r)+exi(s)+exi(t)+exi(u)+exi(v)+exi(w)+exi(x)+exi(y)+exi(z)))

    call assign_heap_array(heap_array, 1, a)
    call assign_heap_array(heap_array, 2, b)
    call assign_heap_array(heap_array, 3, c)
    call assign_heap_array(heap_array, 4, d)
    call assign_heap_array(heap_array, 5, e)
    call assign_heap_array(heap_array, 6, f)
    call assign_heap_array(heap_array, 7, g)
    call assign_heap_array(heap_array, 8, h)
    call assign_heap_array(heap_array, 9, i)
    call assign_heap_array(heap_array, 10, j)
    call assign_heap_array(heap_array, 11, k)
    call assign_heap_array(heap_array, 12, l)
    call assign_heap_array(heap_array, 13, m)
    call assign_heap_array(heap_array, 14, n)
    call assign_heap_array(heap_array, 15, o)
    call assign_heap_array(heap_array, 16, p)
    call assign_heap_array(heap_array, 17, q)
    call assign_heap_array(heap_array, 18, r)
    call assign_heap_array(heap_array, 19, s)
    call assign_heap_array(heap_array, 20, t)
    call assign_heap_array(heap_array, 21, u)
    call assign_heap_array(heap_array, 22, v)
    call assign_heap_array(heap_array, 23, w)
    call assign_heap_array(heap_array, 24, x)
    call assign_heap_array(heap_array, 25, y)
    call assign_heap_array(heap_array, 26, z)

    ! do int = 1,size(heap_array)
    !   print*,heap_array(int)%get()
    ! end do
  end function heap_string_array


  ! Dump a raw Fortran string pointer into a string.
  subroutine copy_string_pointer(length, input_pointer, output_string)
    use, intrinsic :: iso_c_binding
    implicit none

    character(c_char), pointer :: input_pointer(:)
    character(:), allocatable :: output_string
    integer(4) :: i
    ! Start off with the pointer width.
    integer(4) :: length

    ! Now allocate what is needed into the output string.
    allocate(character(len=length) :: output_string)

    ! Now copy over each character.
    ! print"(A)",length
    do i = 1, length
      output_string(i:i) = input_pointer(i)
    end do
  end subroutine copy_string_pointer


  ! Use this to convert C strings stored in a (character, pointer) into Fortran strings.
  !** This is allocatable, remember to deallocate.
  function string_from_c(c_string, size) result(fortran_string)
    use, intrinsic :: iso_c_binding
    implicit none

    ! On the C side. The view is great.
    type(c_ptr), intent(in), value :: c_string
    ! On the Fortran side.
    character(c_char), pointer :: fortran_raw_string(:)
    character(:), allocatable :: fortran_string

    integer :: size
    ! 4 BYTES, aka, 32 bit.
    ! If there is a string bigger than this, we have a problem.
    integer(4) :: i
    integer(4) :: input_length
    ! Starts off as 0
    integer(4) :: length = 0

    ! We must ensure that we are not converting a null pointer
    ! as this can lead to SERIOUS UB.
    if (.not. c_associated(c_string)) then
      !? So we will choose to return a blank string instead of halting.
      !? This comment is left here as a backup and retroactive development documentation.
      ! error stop "string_from_c: NULL POINTER IN C STRING"
      fortran_string = ""
    else
      !? It seems that everything is okay, we will proceed.
      call c_f_pointer(c_string, fortran_raw_string, [size])

      ! Get the size of the character pointer.
      ! This is so we do not go out of bounds.
      ! Manually cast this to 32 bit.
      input_length = int(sizeof(fortran_raw_string))

      !! Force a null terminator to be applied.
      !? This prevents strange behavior when C misbehaves.
      fortran_raw_string(input_length) = achar(0)

      ! Let's find the null terminator.
      do i = 1, input_length
        if (fortran_raw_string(i) == achar(0)) then
          length = i - 1
          exit
        end if
      end do

      ! If the length is 0, we literally cannot do anything, so give up.
      if (length > 0) then
        call copy_string_pointer(length, fortran_raw_string, fortran_string)
      else
        fortran_string = ""
      end if
    end if
  end function string_from_c


  ! Convert a regular Fortran string into a null terminated C string.
  !** Allocated, remember to deallocate!
  function into_c_string(input) result(output)
    implicit none

    character(len = *, kind = c_char) :: input
    character(len = :, kind = c_char), allocatable :: output

    ! Simply shove that string into the allocated string and null terminate it.
    !? This seems to automatically allocate so don't allocate for no reason.
    output = input//achar(0)
  end function into_c_string

  ! Convert an integer into an allocated string.
  !** Allocatable will deallocate once the memory goes out of scope.
  function int_to_string(i) result(output)
    implicit none

    integer :: i
    character(:, kind = c_char), allocatable :: output

    ! If the number is any bigger than this, wat.
    allocate(character(128) :: output)
    write(output, "(i128)") i

    ! Now we shift the whole thing left and trim it to fit.
    output = trim(adjustl(output))

    !? This is simply debug.
    ! print"(A)","-----"
    ! print"(A)",output//"."
    ! print"(A)","len: ", len(output)
    ! print"(A)","-----"
  end function int_to_string


  ! Convert a logical into an allocated string.
  !** Allocatable will deallocate once the memory goes out of scope.
  function bool_to_string(bool) result(output)
    implicit none

    logical :: bool
    character(len = :), allocatable :: output

    allocate(character(5) :: output)

    ! Simply write true or false into the string.
    if (bool) then
      write(output, "(A)") "true"
    else
      write(output, "(A)") "false"
    end if

    ! Now we shift the whole thing left and trim it to fit.
    output = trim(adjustl(output))
  end function bool_to_string


end module string
