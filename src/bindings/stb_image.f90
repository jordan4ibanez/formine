module stb_image
  use, intrinsic :: iso_c_binding
  implicit none


  private


  public :: stbi_enable_vertical_flipping
  public :: stbi_load


  ! Here I'm binding to the C stb_image shared library.
  interface


    function internal_stbi_load(file_name, x, y, channels_in_file, desired_channels) result(raw_data) bind(c, name = "stbi_load")
      use, intrinsic :: iso_c_binding
      implicit none

      character(len = 1, kind = c_char), intent(in) :: file_name
      integer(c_int), intent(inout) :: x, y, channels_in_file
      integer(c_int), intent(in), value :: desired_channels
      type(c_ptr) :: raw_data
    end function internal_stbi_load


    subroutine internal_stbi_image_free(retval_from_stbi_load) bind(c, name = "stbi_image_free")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: retval_from_stbi_load
    end subroutine internal_stbi_image_free


    subroutine stbi_set_flip_vertically_on_load(flag_true_if_should_flip) bind(c, name = "stbi_set_flip_vertically_on_load")
      use, intrinsic :: iso_c_binding

      logical(c_bool), intent(in), value :: flag_true_if_should_flip
    end subroutine stbi_set_flip_vertically_on_load


  end interface


contains


  subroutine stbi_enable_vertical_flipping()
    implicit none

    logical(c_bool) :: enable

    enable = .true.

    call stbi_set_flip_vertically_on_load(enable)
  end subroutine stbi_enable_vertical_flipping


  function stbi_load(file_name, x, y, channels_in_file, desired_channels) result(raw_image_data)
    use :: math_helpers, only: c_uchar_to_int_array
    implicit none

    character(len = 1, kind = c_char), intent(in) :: file_name
    integer(c_int), intent(inout) :: x, y, channels_in_file
    integer(c_int), intent(in), value :: desired_channels
    type(c_ptr) :: c_pointer
    integer(c_int) :: array_length
    integer(1), dimension(:), pointer :: passed_data_pointer
    integer(1), dimension(:), allocatable :: raw_image_data
    ! integer(c_int), dimension(:), allocatable :: output_data_int

    !! WARNING: All data in the output is assumed to be overflowed, do not modify it.
    !! It is designed to be passed straight into C.

    ! Get the raw C data.
    c_pointer = internal_stbi_load(file_name, x, y, channels_in_file, desired_channels)

    ! Calculate the length of the array.
    array_length = x * y * channels_in_file

    ! Pass it into fortran.
    call c_f_pointer(c_pointer, passed_data_pointer, shape = [array_length])

    ! Initialize the raw image data with the raw pointer.
    raw_image_data = passed_data_pointer

    !? Enable this if you want to read the raw data
    ! output_data_int = c_uchar_to_int_array(intermidiate_data_byte)
    ! print*,output_data_int

    ! Free the Fortran pointer. (Just in case.)
    ! deallocate(passed_data_pointer)

    ! Now we can finally free the C memory.
    call internal_stbi_image_free(c_pointer)

    ! The image data is now handled by Fortran.
  end function stbi_load


end module stb_image
