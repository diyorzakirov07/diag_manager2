module fms_diag_send_data_mod
use fms_diag_object_mod
!> \descrption The user API for diag_manager is send_data.  Users pass their variable object to
!! this routine, and magic happens.
!! - Check if the diagnostic object is allocated/registered.  If it isn't return.
!! - On the first call, the diag object is converted to the correct type to allow for bufferring.
!! - If the input data are static, they are written to the file(s) they are supposed to go to.  Subsequent
!! send data calls will be ignored (a quick return).
!! - The optional arguments are all handled and checked.
!! - Data is buffered in the diag object.  This object is carried by the model component sending the data.
!! - Averaging routines are called to preform the correct calculations if there is averaging.  
!! - Data is written to the appropriate file at the appropriate time.  The averaged data is not buffered.
!! - If no more averaging needs to be done on a given set of data, then the data buffer is deallocated. 
!! (example: a veriable is written out on a monthly basis, and the model has reached the end of the month)
interface send_data
     module procedure fms_send_datascalar
     module procedure fms_send_data1d
     module procedure fms_send_data2d
     module procedure fms_send_data3d
     module procedure fms_send_data4d
     module procedure fms_send_data5d
end interface send_data

type send_data_opts
     integer, allocatable :: is 
     integer, allocatable :: js
     integer, allocatable :: ks
     integer, allocatable :: ie
     integer, allocatable :: je
     integer, allocatable :: ke
     logical, allocatable :: mask
     real, allocatable ::    rmask
     real, allocatable ::    weight
end type send_data_opts

contains 
!> \descrption scalar wrapper for fms_send_data
subroutine fms_send_datascalar(diagobj, var)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*)                      , intent(in) ,   target      :: var !< The variable
 class(*)                      ,                pointer     :: vptr => NULL() !< A pointer to the data

!> If the diagnostic object is not allocated, then return withut doing anything
 if (.not.allocated( diagobj )) return
end subroutine fms_send_datascalar
subroutine fms_send_data1d(diagobj, var)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*), dimension(:)       , intent(in) , target         :: var !< The variable
 class(*), dimension(:)       ,              pointer        :: vptr => NULL() !< A pointer to the data

!> If the diagnostic object is not allocated, then return
 if (.not.allocated( diagobj )) return
!> If this is the first call in, set the type to be fms_diag_object_1d
 call switch_to_right_type(diagobj, null_1d, var(lbound(var,1)))

end subroutine fms_send_data1d
!> \descrption 4D wrapper for fms_send_data
subroutine fms_send_data4d(diagobj, var, time, is_in, js_in, ks_in, mask, &
                                   rmask, ie_in, je_in, ke_in, weight, err_msg)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*), dimension(:,:,:,:) , intent(in) , target         :: var !< The variable
 class(*), dimension(:,:,:,:) ,              pointer        :: vptr => NULL() !< A pointer to the data
 integer, optional            , intent(in)                  :: time !< A time place holder
 integer, optional            , intent(in)                  :: is_in !< Start of the first dimension
 integer, optional            , intent(in)                  :: js_in !< Start of the second dimension
 integer, optional            , intent(in)                  :: ks_in !< Start of the third dimension
 integer, optional            , intent(in)                  :: ie_in !< End of the first dimension
 integer, optional            , intent(in)                  :: je_in !< End of the second dimension
 integer, optional            , intent(in)                  :: ke_in !< End of the third dimension
 logical, optional            , intent(in)                  :: mask !< A lask for point to ignore
 real   , optional            , intent(in)                  :: rmask !< I DONT KNOW
 real   , optional            , intent(in)                  :: weight !< Something for averaging?
 CHARACTER(len=*)             , INTENT(out), OPTIONAL       :: err_msg
! local vars
 class (fms_diag_object)      , pointer                     :: dptr => NULL()

!> If the diagnostic object is not allocated, then return
 if (.not.allocated( diagobj )) return
!> If this is the first call in, set the type to be fms_diag_object_4d
 call switch_to_right_type(diagobj, null_4d, &
     var(lbound(var,1),lbound(var,2),lbound(var,3),lbound(var,4)) )

end subroutine fms_send_data4d
!> \descrption 5D wrapper for fms_send_data
subroutine fms_send_data5d(diagobj, var, time, is_in, js_in, ks_in, mask, &
                                   rmask, ie_in, je_in, ke_in, weight, err_msg)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*), dimension(:,:,:,:,:) , intent(in) , target       :: var !< The variable
 class(*), dimension(:,:,:,:,:) ,              pointer      :: vptr => NULL() !< A pointer to the data
 integer, optional            , intent(in)                  :: time !< A time place holder
 integer, optional            , intent(in)                  :: is_in !< Start of the first dimension
 integer, optional            , intent(in)                  :: js_in !< Start of the second dimension
 integer, optional            , intent(in)                  :: ks_in !< Start of the third dimension
 integer, optional            , intent(in)                  :: ie_in !< End of the first dimension
 integer, optional            , intent(in)                  :: je_in !< End of the second dimension
 integer, optional            , intent(in)                  :: ke_in !< End of the third dimension
 logical, optional            , intent(in)                  :: mask !< A lask for point to ignore
 real   , optional            , intent(in)                  :: rmask !< I DONT KNOW
 real   , optional            , intent(in)                  :: weight !< Something for averaging?
 CHARACTER(len=*)             , INTENT(out), OPTIONAL       :: err_msg
! local vars
 class (fms_diag_object)      , pointer                     :: dptr => NULL()

!> If the diagnostic object is not allocated, then return
 if (.not.allocated( diagobj )) return
!> If this is the first call in, set the type to be fms_diag_object_5d
 call switch_to_right_type(diagobj, null_5d, &
     var(lbound(var,1),lbound(var,2),lbound(var,3),lbound(var,4),lbound(var,5)) )

end subroutine fms_send_data5d

!> \descrption 2D wrapper for fms_send_data
subroutine fms_send_data2d (diagobj, var, time, is_in, js_in, ks_in, mask, &
                                   rmask, ie_in, je_in, ke_in, weight, err_msg)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*), dimension(:,:)   , intent(in) , target         :: var !< The variable
 class(*), dimension(:,:)   ,              pointer        :: vptr => NULL() !< A pointer to the data
 integer, optional            , intent(in)                  :: time !< A time place holder
 integer, optional            , intent(in)                  :: is_in !< Start of the first dimension
 integer, optional            , intent(in)                  :: js_in !< Start of the second dimension
 integer, optional            , intent(in)                  :: ks_in !< Start of the third dimension
 integer, optional            , intent(in)                  :: ie_in !< End of the first dimension
 integer, optional            , intent(in)                  :: je_in !< End of the second dimension
 integer, optional            , intent(in)                  :: ke_in !< End of the third dimension
 logical, optional            , intent(in)                  :: mask !< A lask for point to ignore
 real   , optional            , intent(in)                  :: rmask !< I DONT KNOW
 real   , optional            , intent(in)                  :: weight !< Something for averaging?
 CHARACTER(len=*)             , INTENT(out), OPTIONAL       :: err_msg
! local vars
 class (fms_diag_object)      , pointer                     :: dptr => NULL()
!> If this is the first call in, set the type to be fms_diag_object_2d
 call switch_to_right_type(diagobj, null_2d, var(lbound(var,1),lbound(var,2)) )

end subroutine fms_send_data2d

!> \descrption 3D wrapper for fms_send_data
subroutine fms_send_data3d (diagobj, var, time, is_in, js_in, ks_in, mask, &
                                   rmask, ie_in, je_in, ke_in, weight, err_msg)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class(*), dimension(:,:,:)   , intent(in) , target         :: var !< The variable
 class(*), dimension(:,:,:)   ,              pointer        :: vptr => NULL() !< A pointer to the data
 integer, optional            , intent(in)                  :: time !< A time place holder
 integer, optional            , intent(in)                  :: is_in !< Start of the first dimension
 integer, optional            , intent(in)                  :: js_in !< Start of the second dimension
 integer, optional            , intent(in)                  :: ks_in !< Start of the third dimension
 integer, optional            , intent(in)                  :: ie_in !< End of the first dimension
 integer, optional            , intent(in)                  :: je_in !< End of the second dimension
 integer, optional            , intent(in)                  :: ke_in !< End of the third dimension
 logical, optional            , intent(in)                  :: mask !< A lask for point to ignore
 real   , optional            , intent(in)                  :: rmask !< I DONT KNOW
 real   , optional            , intent(in)                  :: weight !< Something for averaging?
 CHARACTER(len=*)             , INTENT(out), OPTIONAL       :: err_msg
! local vars
 class (fms_diag_object)      , pointer                     :: dptr => NULL()
!
!> If the diagnostic object is not allocated, then return
 if (.not.allocated( diagobj )) return
!> If this is the first call in, set the type to be fms_diag_object_3d
 call switch_to_right_type(diagobj, null_3d, var(lbound(var,1),lbound(var,2),lbound(var,3)) )

end subroutine fms_send_data3d
!> \Description This routine is used to switch the diag object to the correct type based on the dimensions
!! of the input data.  It then determines the type of the data, and stores that within the object.  Only
!! one datum needs to be send in to determine the data type, so this routine is shared by all of the
!! send_data calls.
!! This only needs to be done one time. 
subroutine switch_to_right_type(diagobj, null_obj,var)
 class (fms_diag_object),target, intent(inout), allocatable :: diagobj !< The diag variable object
 class (fms_diag_object),intent(in)                         :: null_obj !< The null object that matches the diagnostic
 class (*)              ,intent (in)                        :: var
 class (fms_diag_object), allocatable                       :: dcopy
 class (fms_diag_object), pointer                           :: dptr => NULL()
 
 dptr => diagobj
 select type (dptr)
     type is (fms_diag_object)
!> Switch the diagobj to the correct type
          dcopy = null_obj !< Copy null into the temp object to set the type
          call dptr%copy(dcopy) !> Copy the values of the object into the temp dcopy
          deallocate(diagobj) !> Deallocate the object
          diagobj = null_obj !> Copy the null into the variable object to set the type
          call dcopy%copy(diagobj) !> Copy the original values in
!> Determne the type of var
          call diagobj%set_type(var)
 end select
 if (allocated(dcopy)) deallocate(dcopy)
 if (associated(dptr)) nullify(dptr) !> Dont leak memory
 
end subroutine switch_to_right_type
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine fms_send_data

end subroutine fms_send_data
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end module fms_diag_send_data_mod
