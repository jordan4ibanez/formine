module rgba8_texture_mod
  use, intrinsic :: iso_c_binding
  implicit none


  private


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
    integer(c_int) :: width
    integer(c_int) :: height
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
  end function rgba8_texture_constructor


end module rgba8_texture_mod