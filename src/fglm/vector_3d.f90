module vector_3d
  use :: iso_c_binding, only: c_double
  implicit none

  private

  public :: vec3d

  ! vec3f and Vec3d are transparent containers.
  ! You can use the methods, or you can use the raw data.
  !
  !* They do not mix. Can't add vec3f to vec3d, and so forth. This will cause weird problems that I don't feel like solving.

  type vec3d
    real(c_double), dimension(3) :: data = [0.0, 0.0, 0.0]
  contains
    generic :: assignment(=) => assign_scalar, assign_array, assign_vec3
    procedure :: assign_scalar
    procedure :: assign_array
    procedure :: assign_vec3
    !* Note: Float equality is very dumb.
    generic :: operator(==) => equal_scalar, equal_array, equal_vec3
    procedure :: equal_scalar
    procedure :: equal_array
    procedure :: equal_vec3
    generic :: operator(+) => add_scalar, add_array, add_vec3
    procedure :: add_scalar
    procedure :: add_array
    procedure :: add_vec3
    generic :: operator(-) => subtract_scalar, subtract_array, subtract_vec3
    procedure :: subtract_scalar
    procedure :: subtract_array
    procedure :: subtract_vec3
    generic :: operator(*) => multiply_scalar, multiply_array, multiply_vec3
    procedure :: multiply_scalar
    procedure :: multiply_array
    procedure :: multiply_vec3
    generic :: operator(/) => divide_scalar, divide_array, divide_vec3
    procedure :: divide_scalar
    procedure :: divide_array
    procedure :: divide_vec3
  end type vec3d


  interface vec3d
    module procedure :: constructor_scalar, constructor_scalar_real32, constructor_raw, constructor_raw_real32, constructor_array
  end interface


contains

  type(vec3d) function constructor_scalar(i) result(new_vec3)
    implicit none
    real(c_double), intent(in), value :: i

    new_vec3%data(1:3) = [i,i,i]
  end function constructor_scalar

  type(vec3d) function constructor_scalar_real32(i) result(new_vec3)
    use :: iso_fortran_env, only: real32
    implicit none
    real(real32), intent(in), value :: i

    new_vec3%data(1:3) = [i,i,i]
  end function constructor_scalar_real32

  type(vec3d) function constructor_raw(x,y,z) result(new_vec3)
    implicit none

    real(c_double), intent(in), value :: x,y,z

    new_vec3%data(1:3) = [x,y,z]
  end function constructor_raw

  type(vec3d) function constructor_raw_real32(x,y,z) result(new_vec3)
    use :: iso_fortran_env, only: real32
    implicit none

    real(real32), intent(in), value :: x,y,z

    new_vec3%data(1:3) = [x,y,z]
  end function constructor_raw_real32


  type(vec3d) function constructor_array(xyz_array) result(new_vec3)
    implicit none

    real(c_double), dimension(3), intent(in) :: xyz_array

    new_vec3%data(1:3) = xyz_array(1:3)
  end function constructor_array


  subroutine assign_scalar(this, i)
    implicit none

    class(vec3d), intent(inout) :: this
    real(c_double), intent(in), value :: i

    this%data(1:3) = [i, i, i]
  end subroutine assign_scalar


  subroutine assign_array(this, arr)
    implicit none

    class(vec3d), intent(inout) :: this
    real(c_double), dimension(3), intent(in) :: arr

    this%data(1:3) = arr(1:3)
  end subroutine assign_array


  subroutine assign_vec3(this, other)
    implicit none

    class(vec3d), intent(inout) :: this
    type(vec3d), intent(in), value :: other

    this%data(1:3) = other%data(1:3)
  end subroutine assign_vec3


  logical function equal_scalar(this, i) result(equality)
    use float_compare
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), intent(in), value :: i

    equality = f64_is_equal(this%data(1), i) .and. f64_is_equal(this%data(2), i) .and. f64_is_equal(this%data(3), i)
  end function equal_scalar


  logical function equal_array(this, arr) result(equality)
    use float_compare
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), dimension(3), intent(in) :: arr

    equality = f64_is_equal(this%data(1), arr(1)) .and. f64_is_equal(this%data(2), arr(2)) .and. f64_is_equal(this%data(3), arr(3))
  end function equal_array


  logical function equal_vec3(this, other) result(equality)
    use float_compare
    implicit none

    class(vec3d), intent(in) :: this
    type(vec3d), intent(in), value :: other

    equality = f64_is_equal(this%data(1), other%data(1)) .and. f64_is_equal(this%data(2), other%data(2)) .and. f64_is_equal(this%data(3), other%data(3))
  end function equal_vec3


  type(vec3d) function add_scalar(this, i) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), intent(in), value :: i

    new_vec3 = this%data(1:3) + i
  end function add_scalar


  type(vec3d) function add_array(this, arr) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), dimension(3), intent(in) :: arr

    new_vec3 = this%data(1:3) + arr(1:3)
  end function add_array


  type(vec3d) function add_vec3(this, other) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    type(vec3d), intent(in), value :: other

    new_vec3 = this%data(1:3) + other%data(1:3)
  end function add_vec3


  type(vec3d) function subtract_scalar(this, i) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), intent(in), value :: i

    new_vec3 = this%data(1:3) - i
  end function subtract_scalar


  type(vec3d) function subtract_array(this, arr) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), dimension(3), intent(in) :: arr

    new_vec3 = this%data(1:3) - arr(1:3)
  end function subtract_array


  type(vec3d) function subtract_vec3(this, other) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    type(vec3d), intent(in), value :: other

    new_vec3 = this%data(1:3) + other%data(1:3)
  end function subtract_vec3


  type(vec3d) function multiply_scalar(this, i) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), intent(in), value :: i

    new_vec3 = this%data(1:3) * i
  end function multiply_scalar


  type(vec3d) function multiply_array(this, arr) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), dimension(3), intent(in) :: arr

    new_vec3 = this%data(1:3) * arr(1:3)
  end function multiply_array


  type(vec3d) function multiply_vec3(this, other) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    type(vec3d), intent(in), value :: other

    new_vec3 = this%data(1:3) * other%data(1:3)
  end function multiply_vec3


  type(vec3d) function divide_scalar(this, i) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), intent(in), value :: i

    new_vec3 = this%data(1:3) / i
  end function divide_scalar


  type(vec3d) function divide_array(this, arr) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    real(c_double), dimension(3), intent(in) :: arr

    new_vec3 = this%data(1:3) / arr(1:3)
  end function divide_array


  type(vec3d) function divide_vec3(this, other) result(new_vec3)
    implicit none

    class(vec3d), intent(in) :: this
    type(vec3d), intent(in), value :: other

    new_vec3 = this%data(1:3) / other%data(1:3)
  end function divide_vec3



end module vector_3d
