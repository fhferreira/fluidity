!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.5 (r3931) - 24 May 2011 16:27
!
MODULE SIMPLE_ADVECTION_D
  IMPLICIT NONE

CONTAINS
!  Differentiation of advection_action in forward (tangent) mode:
!   variations   of useful results: ac
!   with respect to varying inputs: u
!   RW status of diff variables: ac:out u:in
  SUBROUTINE ADVECTION_ACTION_D(x, u, ud, c, ac, acd)
    IMPLICIT NONE
!$openad DEPENDENT(Ac)
    REAL, DIMENSION(:), INTENT(IN) :: x
    REAL, DIMENSION(:), INTENT(IN) :: u
    REAL, DIMENSION(:), INTENT(IN) :: ud
    REAL, DIMENSION(:), INTENT(IN) :: c
    REAL, DIMENSION(:), INTENT(OUT) :: ac
    REAL, DIMENSION(:), INTENT(OUT) :: acd
    INTEGER :: ele, ele_count, node_count
    INTEGER, DIMENSION(2) :: ele_nodes
    REAL, DIMENSION(2) :: ele_tmp
    INTEGER :: result1
    INTEGER :: result2
    INTRINSIC SIZE
!$openad INDEPENDENT(u)
    node_count = SIZE(x)
    result1 = SIZE(c)
    result2 = SIZE(u)
    IF (result1 .NE. node_count .OR. result2 .NE. node_count) THEN
      WRITE(0, *) 'Huh? Everything has to be consistent'
      STOP
    ELSE
! 1D only, baby
      ele_count = node_count - 1
      ac = 0.0
      acd = 0.0
      DO ele=1,ele_count
        ele_nodes = (/ele, ele+1/)
        CALL ELE_ADVECTION_ACTION_D(ele, ele_nodes, x, u, ud, c, ac, acd&
&                             )
      END DO
    END IF
  END SUBROUTINE ADVECTION_ACTION_D
  SUBROUTINE ADVECTION_ACTION(x, u, c, ac)
    IMPLICIT NONE
!$openad DEPENDENT(Ac)
    REAL, DIMENSION(:), INTENT(IN) :: x
    REAL, DIMENSION(:), INTENT(IN) :: u
    REAL, DIMENSION(:), INTENT(IN) :: c
    REAL, DIMENSION(:), INTENT(OUT) :: ac
    INTEGER :: ele, ele_count, node_count
    INTEGER, DIMENSION(2) :: ele_nodes
    REAL, DIMENSION(2) :: ele_tmp
    INTEGER :: result1
    INTEGER :: result2
    INTRINSIC SIZE
!$openad INDEPENDENT(u)
    node_count = SIZE(x)
    result1 = SIZE(c)
    result2 = SIZE(u)
    IF (result1 .NE. node_count .OR. result2 .NE. node_count) THEN
      WRITE(0, *) 'Huh? Everything has to be consistent'
      STOP
    ELSE
! 1D only, baby
      ele_count = node_count - 1
      ac = 0.0
      DO ele=1,ele_count
        ele_nodes = (/ele, ele+1/)
        CALL ELE_ADVECTION_ACTION(ele, ele_nodes, x, u, c, ac)
      END DO
    END IF
  END SUBROUTINE ADVECTION_ACTION
!  Differentiation of ele_advection_action in forward (tangent) mode:
!   variations   of useful results: ac
!   with respect to varying inputs: ac u
  SUBROUTINE ELE_ADVECTION_ACTION_D(ele, ele_nodes, x, u, ud, c, ac, acd&
&  )
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: ele
    INTEGER, DIMENSION(2), INTENT(IN) :: ele_nodes
    REAL, DIMENSION(:), INTENT(IN) :: x, u, c
    REAL, DIMENSION(:), INTENT(IN) :: ud
    REAL, DIMENSION(2), INTENT(OUT) :: ac
    REAL, DIMENSION(2), INTENT(OUT) :: acd
    REAL, DIMENSION(2, 2) :: a
    REAL, DIMENSION(2, 2) :: ad
! loc x ngi
    REAL, DIMENSION(2, 2) :: shape_n
    REAL, DIMENSION(2, 2) :: shape_nd
! log x ngi x dim
    REAL, DIMENSION(2, 2, 1) :: dshape_n
    REAL, DIMENSION(2, 2, 1) :: dshape_nd
    REAL :: h
    REAL, DIMENSION(2) :: detwei
    INTEGER :: i, j
    REAL, DIMENSION(2) :: u_at_quad
    REAL, DIMENSION(2) :: u_at_quadd
    REAL, DIMENSION(2) :: arg1
    REAL, DIMENSION(2) :: arg1d
    INTEGER :: result1
    INTRINSIC SIZE
    INTRINSIC SUM
! values of basis functions at quad points
    shape_nd(1, :) = 0.0
    shape_n(1, :) = (/0.78867513459481298, 0.21132486540518702/)
    shape_nd(2, :) = 0.0
    shape_n(2, :) = (/0.21132486540518702, 0.78867513459481298/)
! values of derivatives of basis functions at quad points
    dshape_nd(1, :, 1) = 0.0
    dshape_n(1, :, 1) = (/-1, -1/)
    dshape_nd(2, :, 1) = 0.0
    dshape_n(2, :, 1) = (/1, 1/)
! step size
    h = x(ele_nodes(2)) - x(ele_nodes(1))
! transform_to_physical
    dshape_n = 1.0/h*dshape_n
    detwei = (/0.5, 0.5/)*h
    u_at_quadd = 0.0
! Replacement matmul
    DO i=1,2
      u_at_quadd(i) = SUM(shape_n(:, i)*ud(ele_nodes))
      u_at_quad(i) = SUM(u(ele_nodes)*shape_n(:, i))
    END DO
    ad = 0.0
    DO i=1,2
      DO j=1,2
! Replacement dot_product
        arg1d(:) = shape_n(i, :)*dshape_n(j, :, 1)*detwei*u_at_quadd
        arg1(:) = shape_n(i, :)*(dshape_n(j, :, 1)*u_at_quad)*detwei
        ad(i, j) = SUM(arg1d(:))
        a(i, j) = SUM(arg1(:))
      END DO
    END DO
! Enforce dirichlet BCs
    IF (ele_nodes(1) .EQ. 1) THEN
      ad(1, :) = 0.0
      a(1, :) = (/1.0, 0.0/)
    END IF
    result1 = SIZE(x)
    IF (ele_nodes(2) .EQ. result1) THEN
      ad(2, :) = 0.0
      a(2, :) = (/0.0, 1.0/)
    END IF
! Replacement matmul
    DO i=1,2
      acd(ele_nodes(i)) = acd(ele_nodes(i)) + SUM(c(ele_nodes)*ad(i, :))
      ac(ele_nodes(i)) = ac(ele_nodes(i)) + SUM(a(i, :)*c(ele_nodes))
    END DO
  END SUBROUTINE ELE_ADVECTION_ACTION_D
  SUBROUTINE ELE_ADVECTION_ACTION(ele, ele_nodes, x, u, c, ac)
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: ele
    INTEGER, DIMENSION(2), INTENT(IN) :: ele_nodes
    REAL, DIMENSION(:), INTENT(IN) :: x, u, c
    REAL, DIMENSION(2), INTENT(OUT) :: ac
    REAL, DIMENSION(2, 2) :: a
! loc x ngi
    REAL, DIMENSION(2, 2) :: shape_n
! log x ngi x dim
    REAL, DIMENSION(2, 2, 1) :: dshape_n
    REAL :: h
    REAL, DIMENSION(2) :: detwei
    INTEGER :: i, j
    REAL, DIMENSION(2) :: u_at_quad
    REAL, DIMENSION(2) :: arg1
    INTEGER :: result1
    INTRINSIC SIZE
    INTRINSIC SUM
! values of basis functions at quad points
    shape_n(1, :) = (/0.78867513459481298, 0.21132486540518702/)
    shape_n(2, :) = (/0.21132486540518702, 0.78867513459481298/)
    dshape_n(1, :, 1) = (/-1, -1/)
! values of derivatives of basis functions at quad points
    dshape_n(2, :, 1) = (/1, 1/)
! step size
    h = x(ele_nodes(2)) - x(ele_nodes(1))
! transform_to_physical
    dshape_n = 1.0/h*dshape_n
    detwei = (/0.5, 0.5/)*h
! Replacement matmul
    DO i=1,2
      u_at_quad(i) = SUM(u(ele_nodes)*shape_n(:, i))
    END DO
    DO i=1,2
      DO j=1,2
! Replacement dot_product
        arg1(:) = shape_n(i, :)*(dshape_n(j, :, 1)*u_at_quad)*detwei
        a(i, j) = SUM(arg1(:))
      END DO
    END DO
! Enforce dirichlet BCs
    IF (ele_nodes(1) .EQ. 1) a(1, :) = (/1.0, 0.0/)
    result1 = SIZE(x)
    IF (ele_nodes(2) .EQ. result1) a(2, :) = (/0.0, 1.0/)
! Replacement matmul
    DO i=1,2
      ac(ele_nodes(i)) = ac(ele_nodes(i)) + SUM(a(i, :)*c(ele_nodes))
    END DO
  END SUBROUTINE ELE_ADVECTION_ACTION
END MODULE SIMPLE_ADVECTION_D
