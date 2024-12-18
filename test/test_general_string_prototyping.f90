module test_suite_string_prototyping
  use :: string_f90
  use :: testament
  use, intrinsic :: iso_c_binding
  implicit none


contains

  subroutine starts_with()
    implicit none

    character(len = :, kind = c_char), allocatable :: unit_1, unit_2, unit_3

    ! print*, "BEGIN TESTING STRING STARTS WITH."

    unit_1 = "hi there"

    call assert_true(string_starts_with(unit_1, "hi"))
    call assert_false(string_starts_with(unit_1, "i"))
    call assert_true(string_starts_with(unit_1, "hi "))
    call assert_true(string_starts_with(unit_1, "hi t"))
    call assert_false(string_starts_with(unit_1, ""))
    call assert_false(string_starts_with(unit_1, " "))

    unit_2 = "[test = 1]"

    call assert_true(string_starts_with(unit_2, "["))
    call assert_false(string_starts_with(unit_2, "[t "))
    call assert_true(string_starts_with(unit_2, "[tes"))
    call assert_true(string_starts_with(unit_2, "[test"))
    call assert_false(string_starts_with(unit_2, ""))
    call assert_false(string_starts_with(unit_2, " "))

    unit_3 = ""

    call assert_false(string_starts_with(unit_3, "["))
    call assert_false(string_starts_with(unit_3, "[t "))
    call assert_false(string_starts_with(unit_3, "[tes"))
    call assert_false(string_starts_with(unit_3, "[test"))
    call assert_false(string_starts_with(unit_3, ""))
    call assert_false(string_starts_with(unit_3, " "))
  end subroutine starts_with


  subroutine ends_with()
    implicit none

    character(len = :, kind = c_char), allocatable :: unit_1, unit_2, unit_3

    ! print*, "BEGIN TESTING STRING ENDS WITH."

    unit_1 = "hi there"

    call assert_true(string_ends_with(unit_1, "there"))
    call assert_false(string_ends_with(unit_1, "er"))
    call assert_true(string_ends_with(unit_1, " there"))
    call assert_true(string_ends_with(unit_1, "here"))
    call assert_false(string_ends_with(unit_1, "1"))
    call assert_false(string_ends_with(unit_1, ""))
    call assert_false(string_ends_with(unit_1, " "))

    unit_2 = "[test = 1]"

    call assert_true(string_ends_with(unit_2, "]"))
    call assert_false(string_ends_with(unit_2, "1] "))
    call assert_true(string_ends_with(unit_2, " 1]"))
    call assert_true(string_ends_with(unit_2, " = 1]"))
    call assert_false(string_ends_with(unit_2, ""))
    call assert_false(string_ends_with(unit_2, " "))

    unit_3 = ""

    call assert_false(string_starts_with(unit_3, "["))
    call assert_false(string_starts_with(unit_3, "[t "))
    call assert_false(string_starts_with(unit_3, "[tes"))
    call assert_false(string_starts_with(unit_3, "[test"))
    call assert_false(string_starts_with(unit_3, ""))
    call assert_false(string_starts_with(unit_3, " "))
  end subroutine ends_with


  subroutine cut_first()
    implicit none

    character(len = :, kind = c_char), allocatable :: unit_1, unit_2, unit_3, unit_4, unit_5, unit_6

    unit_1 = "hi hi hi"

    call assert_str_equal(string_cut_first(unit_1, "hi "), "hi hi")

    ! This module is not allowed to cut blank data.
    unit_2 = " "

    call assert_str_equal(string_cut_first(unit_2, " "), " ")

    unit_3 = "cooltest"

    call assert_str_equal(string_cut_first(unit_3, "cool"), "test")
    call assert_str_equal(string_cut_first(unit_3, "test"), "cool")
    call assert_str_equal(string_cut_first(unit_3, "stco"), "cooltest")
    call assert_str_equal(string_cut_first(unit_3, "olte"), "cost")
    call assert_str_equal(string_cut_first(unit_3, "t"), "coolest")

    unit_4 = "the quick brown fox jumps over the lazy dog"

    call assert_str_equal(string_cut_first(unit_4, "the"), " quick brown fox jumps over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "quick"), "the  brown fox jumps over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "brown"), "the quick  fox jumps over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "fox"), "the quick brown  jumps over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "jumps"), "the quick brown fox  over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "over"), "the quick brown fox jumps  the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "the"), " quick brown fox jumps over the lazy dog")
    call assert_str_equal(string_cut_first(unit_4, "lazy"), "the quick brown fox jumps over the  dog")
    call assert_str_equal(string_cut_first(unit_4, "dog"), "the quick brown fox jumps over the lazy ")
    call assert_str_equal(string_cut_first(unit_4, " "), "thequick brown fox jumps over the lazy dog")

    unit_5 = "hello there"

    call assert_str_equal(string_cut_first(unit_5, " "), "hellothere")

    unit_6 = "a"

    call assert_str_equal(string_cut_first(unit_6, "a"), "")
  end subroutine cut_first


  subroutine cut_last()
    implicit none

    character(len = :, kind = c_char), allocatable :: unit_1, unit_2, unit_3, unit_4, unit_5, unit_6

    unit_1 = "hi hi hi"

    call assert_str_equal(string_cut_last(unit_1, " hi"), "hi hi")

    ! This module is not allowed to cut blank data.
    unit_2 = " "

    call assert_str_equal(string_cut_first(unit_2, " "), " ")

    unit_3 = "cooltest"

    call assert_str_equal(string_cut_last(unit_3, "cool"), "test")
    call assert_str_equal(string_cut_last(unit_3, "test"), "cool")
    call assert_str_equal(string_cut_last(unit_3, "stco"), "cooltest")
    call assert_str_equal(string_cut_last(unit_3, "olte"), "cost")
    call assert_str_equal(string_cut_last(unit_3, "t"), "cooltes")

    unit_4 = "the quick brown fox jumps over the lazy dog"

    call assert_str_equal(string_cut_last(unit_4, "the"), "the quick brown fox jumps over  lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "quick"), "the  brown fox jumps over the lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "brown"), "the quick  fox jumps over the lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "fox"), "the quick brown  jumps over the lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "jumps"), "the quick brown fox  over the lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "over"), "the quick brown fox jumps  the lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "the"), "the quick brown fox jumps over  lazy dog")
    call assert_str_equal(string_cut_last(unit_4, "lazy"), "the quick brown fox jumps over the  dog")
    call assert_str_equal(string_cut_last(unit_4, "dog"), "the quick brown fox jumps over the lazy ")
    call assert_str_equal(string_cut_last(unit_4, " "), "the quick brown fox jumps over the lazydog")

    unit_5 = "hello there"

    call assert_str_equal(string_cut_last(unit_5, " "), "hellothere")

    unit_6 = "a"

    call assert_str_equal(string_cut_last(unit_6, "a"), "")
  end subroutine cut_last


  subroutine cut_all()
    implicit none

    character(len = :, kind = c_char), allocatable :: unit_1, unit_2, unit_3, unit_4, unit_5, unit_6

    unit_1 = "hi hi hi"

    call assert_str_equal(string_cut_all(unit_1, "hi"), "  ")

    ! This module is not allowed to cut blank data.
    unit_2 = " "

    call assert_str_equal(string_cut_all(unit_2, " "), " ")

    unit_3 = "cooltest"

    call assert_str_equal(string_cut_all(unit_3, "cool"), "test")
    call assert_str_equal(string_cut_all(unit_3, "test"), "cool")
    call assert_str_equal(string_cut_all(unit_3, "stco"), "cooltest")
    call assert_str_equal(string_cut_all(unit_3, "olte"), "cost")
    call assert_str_equal(string_cut_all(unit_3, "t"), "cooles")

    unit_4 = "the quick brown fox jumps over the lazy dog"

    call assert_str_equal(string_cut_all(unit_4, "the"), " quick brown fox jumps over  lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "quick"), "the  brown fox jumps over the lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "brown"), "the quick  fox jumps over the lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "fox"), "the quick brown  jumps over the lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "jumps"), "the quick brown fox  over the lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "over"), "the quick brown fox jumps  the lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "the"), " quick brown fox jumps over  lazy dog")
    call assert_str_equal(string_cut_all(unit_4, "lazy"), "the quick brown fox jumps over the  dog")
    call assert_str_equal(string_cut_all(unit_4, "dog"), "the quick brown fox jumps over the lazy ")
    call assert_str_equal(string_cut_all(unit_4, " "), "thequickbrownfoxjumpsoverthelazydog")

    unit_5 = "hello there"

    call assert_str_equal(string_cut_all(unit_5, " "), "hellothere")

    unit_6 = "a"

    call assert_str_equal(string_cut_all(unit_6, "a"), "")
  end subroutine cut_all


end module test_suite_string_prototyping

program test_string_prototyping
  use :: test_suite_string_prototyping
  implicit none

  call starts_with()

  call ends_with()

  call cut_first()

  call cut_last()

  call cut_all()
end program test_string_prototyping
