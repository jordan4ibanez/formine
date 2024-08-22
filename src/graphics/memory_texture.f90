module rgba8_texture_module
  use, intrinsic :: iso_c_binding
  implicit none


  private

  ! todo: color -> pixel

  public :: rgba8_pixel
  public :: rgba8_texture


  !* This is a single pixel.
  !* This is commonly called: RGBA_8
  !* In the range of 0-255.
  type :: rgba8_pixel
    integer(c_int) :: r = 0
    integer(c_int) :: g = 0
    integer(c_int) :: b = 0
    integer(c_int) :: a = 0
  end type rgba8_pixel


  interface rgba8_pixel
    module procedure :: rgba8_pixel_constructor
  end interface rgba8_pixel


  !* This is an actual texture
  !* It contains pixels in the pixels component.
  !* In the standard of: RGBA_8
  type :: rgba8_texture
    type(rgba8_pixel), dimension(:), allocatable :: pixels
    integer(c_int) :: pixel_array_length
    integer(c_int) :: width
    integer(c_int) :: height
  contains
    procedure :: index_get_color => rgba8_texture_index_get_color
    procedure :: index_get_color_optional => rgba8_texture_index_get_color_optional
    procedure :: get_color => rgba8_texture_get_color
    procedure :: get_color_optional => rgba8_texture_get_color_optional
    procedure :: set_pixel => rgba_texture_set_pixel
    procedure :: position_to_index => rgba8_texture_internal_position_to_index
  end type rgba8_texture


  interface rgba8_texture
    module procedure :: rgba8_texture_constructor
  end interface rgba8_texture


contains


  !* Constructor for a pixel.
  function rgba8_pixel_constructor(r, g, b, a) result(new_pixel)
    use :: string
    implicit none

    integer(c_int), intent(in), value :: r, g, b, a
    type(rgba8_pixel) :: new_pixel

    ! Range checks for RGBA.
    if (r < 0 .or. r > 255) then
      error stop "[RGBA Texture] Error: Red is out of range. Range: [0-255]. Received: ["//int_to_string(r)//"]"
    end if
    if (g < 0 .or. g > 255) then
      error stop "[RGBA Texture] Error: Green is out of range. Range: [0-255]. Received: ["//int_to_string(g)//"]"
    end if
    if (b < 0 .or. b > 255) then
      error stop "[RGBA Texture] Error: Blue is out of range. Range: [0-255]. Received: ["//int_to_string(b)//"]"
    end if
    if (a < 0 .or. a > 255) then
      error stop "[RGBA Texture] Error: Alpha is out of range. Range: [0-255]. Received: ["//int_to_string(a)//"]"
    end if

    new_pixel%r = r
    new_pixel%g = g
    new_pixel%b = b
    new_pixel%a = a
  end function rgba8_pixel_constructor


  function rgba8_texture_constructor(raw_texture_memory_u8, width, height) result(new_rgba_texture)
    use :: string
    use :: math_helpers
    implicit none

    integer(1), dimension(:) :: raw_texture_memory_u8
    integer(c_int), intent(in), value :: width, height
    type(rgba8_texture) :: new_rgba_texture
    integer(c_int) :: array_length, pixel_array_length, i, current_index
    integer(c_int), dimension(:), allocatable :: raw_texture_memory_i32

    array_length = size(raw_texture_memory_u8)
    ! 4 channels per pixel.
    pixel_array_length = array_length / 4

    if (width * height /= pixel_array_length) then
      error stop "[RGBA Texture] Error: Received raw texture memory with assumed width ["//int_to_string(width)//"] | height ["//int_to_string(height)//"]. Assumed size is wrong."
    end if

    new_rgba_texture%width = width
    new_rgba_texture%height = height

    ! Shift this into a format we can use.
    raw_texture_memory_i32 = c_uchar_to_int_array(raw_texture_memory_u8)

    ! Allocate the array.
    allocate(new_rgba_texture%pixels(pixel_array_length))

    do i = 1,pixel_array_length

      ! Shift into offset then back into index because math.
      current_index = ((i - 1) * 4) + 1

      ! Now we create the pixel.
      new_rgba_texture%pixels(i) = rgba8_pixel( &
        raw_texture_memory_i32(current_index), &
        raw_texture_memory_i32(current_index + 1), &
        raw_texture_memory_i32(current_index + 2), &
        raw_texture_memory_i32(current_index + 3) &
        )
    end do

    new_rgba_texture%pixel_array_length = pixel_array_length
  end function rgba8_texture_constructor


  !* Get the RGBA of an index. Returns success.
  function rgba8_texture_index_get_color_optional(this, index, optional_pixel) result(success)
    implicit none

    class(rgba8_texture), intent(in) :: this
    integer(c_int), intent(in), value :: index
    type(rgba8_pixel), intent(inout) :: optional_pixel
    logical :: success

    success = .false.

    if (index <= 0 .or. index > this%pixel_array_length) then
      return
    end if

    success = .true.
    optional_pixel = this%pixels(index)
  end function rgba8_texture_index_get_color_optional


  !* Get the RGBA of an index.
  function rgba8_texture_index_get_color(this, index) result(color)
    implicit none

    class(rgba8_texture), intent(in) :: this
    integer(c_int), intent(in), value :: index
    type(rgba8_pixel) :: color

    color = this%pixels(index)
  end function rgba8_texture_index_get_color


  !* This wraps a chain of functions to just get the data we need, which is RGBA of a pixel.
  function rgba8_texture_get_color(this, x,y) result(color)
    use :: string
    implicit none

    class(rgba8_texture), intent(in) :: this
    integer(c_int), intent(in), value :: x, y
    type(rgba8_pixel) :: color

    ! This is calculated via offsets.
    if (x < 0 .or. x >= this%width) then
      error stop "[RGBA Texture] Error: X is out of bounds ["//int_to_string(x)//"]"
    end if
    if (y < 0 .or. y >= this%height) then
      error stop "[RGBA Texture] Error: Y is out of bounds ["//int_to_string(y)//"]"
    end if

    color = this%index_get_color(this%position_to_index(x,y))
  end function rgba8_texture_get_color


  !* Get a pixel that might be out of bounds.
  function rgba8_texture_get_color_optional(this, x, y, optional_pixel) result(success)
    implicit none

    class(rgba8_texture), intent(in) :: this
    integer(c_int), intent(in), value :: x, y
    type(rgba8_pixel), intent(inout) :: optional_pixel
    logical :: success

    success = this%index_get_color_optional(this%position_to_index(x,y), optional_pixel)
  end function rgba8_texture_get_color_optional


  !* Set the pixel of a texture.
  subroutine rgba_texture_set_pixel(this, x, y, new_pixel)
    implicit none

    class(rgba8_texture), intent(inout) :: this
    integer(c_int), intent(in), value :: x, y
    type(rgba8_pixel), intent(in) :: new_pixel
    integer(c_int) :: i

    i = this%position_to_index(x, y)

    this%pixels(i) = new_pixel
  end subroutine rgba_texture_set_pixel


  !* Position (in pixels) to the index in the texture array.
  function rgba8_texture_internal_position_to_index(this, x, y) result(i)
    implicit none

    class(rgba8_texture), intent(in) :: this
    integer(c_int), intent(in), value :: x, y
    integer(c_int) :: a, b
    integer(c_int) :: i

    ! -1 because: We're shifting from indices into offsets.
    a = x - 1
    b = y - 1

    ! +1 because: We're shifting from offsets into indices.
    i = ((b * this%width) + a) + 1
  end function rgba8_texture_internal_position_to_index


end module rgba8_texture_module