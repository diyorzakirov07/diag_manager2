module fms_diag_object_mod
!> \author Tom Robinson
!> \email thomas.robinson@noaa.gov
!! \brief Contains routines for the diag_objects
!!
!! \description The diag_manager passes an object back and forth between the diag routines and the users.
!! The procedures of this object and the types are all in this module.  The fms_dag_object is a type 
!! that contains all of the information of the variable.  It is extended by a type that holds the
!! appropriate buffer for the data for manipulation.
use fms_diag_data_mod,  only: diag_null, diag_error, fatal, note, warning
use fms_diag_data_mod,  only: r8, r4, i8, i4, string, null_type_int
use fms_diag_data_mod, only: diag_null, diag_not_found, diag_not_registered, diag_registered_id
use fms_diag_table_mod,  only: is_field_type_null
use fms_diag_table_mod, only: diag_fields_type, diag_files_type, get_diag_table_field

implicit none

interface operator (<)
     procedure obj_lt_int
     procedure int_lt_obj
end interface
interface operator (<=)
     procedure obj_le_int
     procedure int_le_obj
end interface
interface operator (>)
     procedure obj_gt_int
     procedure int_gt_obj
end interface
interface operator (>=)
     procedure obj_ge_int
     procedure int_ge_obj
end interface
interface operator (==)
     procedure obj_eq_int
     procedure int_eq_obj
end interface
interface operator (.ne.)
     procedure obj_ne_int
     procedure int_ne_obj
end interface


!> \brief Object that holds all variable information
type fms_diag_object
     type (diag_fields_type)                           :: diag_field         !< info from diag_table
     type (diag_files_type),allocatable, dimension(:)  :: diag_file          !< info from diag_table
     integer, allocatable, private                    :: diag_id           !< unique id for varable
!     class (fms_io_obj), allocatable, dimension(:)    :: fms_fileobj        !< fileobjs
     character(len=:), allocatable, dimension(:)      :: metadata          !< metedata for the variable
     logical, private                                 :: static         !< true is this is a static var
     logical, allocatable, private                    :: registered     !< true when registered
     integer, allocatable, dimension(:), private      :: frequency         !< specifies the frequency

     integer,          allocatable, private           :: vartype           !< the type of varaible
     character(len=:), allocatable, private           :: varname           !< the name of the variable     
     character(len=:), allocatable, private           :: longname          !< longname of the variable     
     character(len=:), allocatable, private           :: units             !< the units
     character(len=:), allocatable, private           :: modname           !< the module
     integer, private                                 :: missing_value     !< The missing fill value
     integer, allocatable, dimension(:), private      :: axis_ids          !< variable axis IDs
!     type (diag_axis), allocatable, dimension(:)      :: axis              !< The axis object 

     contains
!     procedure :: send_data => fms_send_data
     procedure :: init_ob => diag_obj_init
     procedure :: diag_id_inq => fms_diag_id_inq
     procedure :: copy => copy_diag_obj
     procedure :: register_meta => fms_register_diag_field_obj
     procedure :: setID => set_diag_id
     procedure :: is_registered => diag_ob_registered
     procedure :: set_type => set_vartype
     procedure :: vartype_inq => what_is_vartype
end type fms_diag_object
!> \brief Extends the variable object to work with multiple types of data
type, extends(fms_diag_object) :: fms_diag_object_scalar
     class(*), allocatable :: vardata
end type fms_diag_object_scalar
type, extends(fms_diag_object) :: fms_diag_object_1d
     class(*), allocatable, dimension(:) :: vardata
end type fms_diag_object_1d
type, extends(fms_diag_object) :: fms_diag_object_2d
     class(*), allocatable, dimension(:,:) :: vardata
end type fms_diag_object_2d
type, extends(fms_diag_object) :: fms_diag_object_3d
     class(*), allocatable, dimension(:,:,:) :: vardata
end type fms_diag_object_3d
type, extends(fms_diag_object) :: fms_diag_object_4d
     class(*), allocatable, dimension(:,:,:,:) :: vardata
end type fms_diag_object_4d
type, extends(fms_diag_object) :: fms_diag_object_5d
     class(*), allocatable, dimension(:,:,:,:,:) :: vardata
end type fms_diag_object_5d
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! variables !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
type(fms_diag_object) :: null_ob
type(fms_diag_object_scalar) :: null_sc
type(fms_diag_object_1d) :: null_1d
type(fms_diag_object_2d) :: null_2d
type(fms_diag_object_3d) :: null_3d
type(fms_diag_object_4d) :: null_4d
type(fms_diag_object_5d) :: null_5d

integer,private :: MAX_LEN_VARNAME
integer,private :: MAX_LEN_META
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
public :: fms_diag_object, fms_diag_object_scalar, fms_diag_object_1d
public :: fms_diag_object_2d, fms_diag_object_3d, fms_diag_object_4d, fms_diag_object_5d
public :: copy_diag_obj, fms_diag_id_inq
public :: operator (>),operator (<),operator (>=),operator (<=),operator (==),operator (.ne.)
public :: null_sc, null_1d, null_2d, null_3d, null_4d, null_5d
public :: fms_diag_object_init
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 CONTAINS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine fms_diag_object_init (mlv,mlm)
 integer, intent(in) :: mlv !< The maximum length of the varname
 integer, intent(in) :: mlm !< The maximum length of the metadata
!> Get info from the namelist
 MAX_LEN_VARNAME = mlv
 MAX_LEN_META = mlm
!> Initialize the null_d variables
 null_ob%diag_id = DIAG_NULL
 null_sc%diag_id = DIAG_NULL
 null_1d%diag_id = DIAG_NULL
 null_2d%diag_id = DIAG_NULL
 null_3d%diag_id = DIAG_NULL
 null_4d%diag_id = DIAG_NULL
 null_5d%diag_id = DIAG_NULL
end subroutine fms_diag_object_init
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \Description Sets the diag_id to the not registered value.
subroutine diag_obj_init(ob)
 class (fms_diag_object)      , intent(inout)                :: ob
 select type (ob)
  class is (fms_diag_object)
     ob%diag_id = diag_not_registered !null_ob%diag_id
 end select
end subroutine diag_obj_init
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \description Fills in and allocates (when necessary) the values in the diagnostic object
subroutine fms_register_diag_field_obj (dobj, modname, varname, axes, time, longname, units, missing_value, metadata)
 class(fms_diag_object)     , intent(inout)            :: dobj
 character(*)               , intent(in)               :: modname!< The module name
 character(*)               , intent(in)               :: varname!< The variable name
 integer     , dimension(:) , intent(in), optional     :: axes   !< The axes 
 integer                    , intent(in), optional     :: time !< Time placeholder 
 character(*)               , intent(in), optional     :: longname!< The variable long name
 character(*)               , intent(in), optional     :: units  !< Units of the variable
 integer                    , intent(in), optional     :: missing_value !< A missing value to be used 
 character(*), dimension(:) , intent(in), optional     :: metadata
! class(*), pointer :: vptr


!> Fill in information from the register call
  allocate(character(len=MAX_LEN_VARNAME) :: dobj%varname)
  dobj%varname = trim(varname)
  allocate(character(len=len(modname)) :: dobj%modname)
  dobj%modname = trim(modname)
!> Grab the information from the diag_table
  dobj%diag_field = get_diag_table_field(trim(varname))
  if (is_field_type_null(dobj%diag_field)) then
     dobj%diag_id = diag_not_found
     dobj%vartype = diag_null
     return
  endif
!> get the optional arguments if included and the diagnostic is in the diag table
  if (present(longname)) then
     allocate(character(len=len(longname)) :: dobj%longname)
     dobj%longname = trim(longname)
  endif
  if (present(units)) then
     allocate(character(len=len(units)) :: dobj%units)
     dobj%units = trim(units)
  endif
  if (present(metadata)) then
     allocate(character(len=MAX_LEN_META) :: dobj%metadata(size(metadata)))
     dobj%metadata = metadata
  endif
  if (present(missing_value)) then
     dobj%missing_value = missing_value
  else   
      dobj%missing_value = DIAG_NULL
  endif

!     write(6,*)"IKIND for diag_fields(1) is",dobj%diag_fields(1)%ikind
!     write(6,*)"IKIND for "//trim(varname)//" is ",dobj%diag_field%ikind
end subroutine fms_register_diag_field_obj
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \brief Sets the diag_id.  This can only be done if a variable is unregistered
subroutine set_diag_id(objin , id)
 class (fms_diag_object) , intent(inout):: objin
 integer                                :: id
 if (allocated(objin%registered)) then
     if (objin%registered) then
          call diag_error("set_diag_id", "The variable"//objin%varname//" is already registered", FATAL)
     endif
 else
     objin%diag_id = id
 endif
end subroutine set_diag_id
!> \brief Find the type of the variable and store it in the object
subroutine set_vartype(objin , var)
 class (fms_diag_object) , intent(inout):: objin
 class(*)                               :: var
 select type (var)
     type is (real(kind=8))
          objin%vartype = r8
     type is (real(kind=4))
          objin%vartype = r4
     type is (integer(kind=8))
          objin%vartype = i8
     type is (integer(kind=4))
          objin%vartype = i4
     type is (character(*))
          objin%vartype = string
     class default
          objin%vartype = null_type_int
          call diag_error("set_vartype", "The variable"//objin%varname//" is not a supported type "// &
          " r8, r4, i8, i4, or string.", warning) 
 end select
end subroutine set_vartype
!> \brief Prints to the screen what type the diag variable is
subroutine what_is_vartype(objin)
 class (fms_diag_object) , intent(inout):: objin
 if (.not. allocated(objin%vartype)) then
     call diag_error("what_is_vartype", "The variable type has not been set prior to this call", warning)
     return
 endif
 select case (objin%vartype)
     case (r8)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is REAL(kind=8)", NOTE)
     case (r4)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is REAL(kind=4)", NOTE)
     case (i8)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is INTEGER(kind=8)", NOTE)
     case (i4)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is INTEGER(kind=4)", NOTE)
     case (string)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is CHARACTER(*)", NOTE)
     case (null_type_int)
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " was not set", WARNING)
     case default
          call diag_error("what_is_vartype", "The variable type of "//trim(objin%varname)//&
          " is not supported by diag_manager", FATAL)
 end select
end subroutine what_is_vartype
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \brief Registers the object
subroutine diag_ob_registered(objin , reg)
 class (fms_diag_object)      , intent(inout):: objin 
 logical                      , intent(in)   :: reg !< If registering, this is true
 objin%registered = reg
end subroutine diag_ob_registered
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \brief Copies the calling object into the object that is the argument of the subroutine
subroutine copy_diag_obj(objin , objout)
 class (fms_diag_object)      , intent(in)                :: objin
 class (fms_diag_object)      , intent(inout) , allocatable :: objout !< The destination of the copy
select type (objout)
 class is (fms_diag_object)

  if (allocated(objin%registered)) then
     objout%registered = objin%registered
  else
     call diag_error("copy_diag_obj", "You can only copy objects that have been registered",warning)
  endif
!     type (diag_fields_type)                           :: diag_field         !< info from diag_table
!     type (diag_files_type),allocatable, dimension(:)  :: diag_file          !< info from diag_table

     objout%diag_id = objin%diag_id           

!     class (fms_io_obj), allocatable, dimension(:)    :: fms_fileobj        !< fileobjs
     if (allocated(objin%metadata)) objout%metadata = objin%metadata
     objout%static = objin%static         
     if (allocated(objin%frequency)) objout%frequency = objin%frequency
     if (allocated(objin%varname)) objout%varname = objin%varname
end select
end subroutine copy_diag_obj
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \brief Returns the diag_id
integer function fms_diag_id_inq (dobj) result(diag_id)
 class(fms_diag_object)     , intent(inout)            :: dobj
! character(*)               , intent(in)               :: varname
 
 if (.not.allocated(dobj%registered)) then
     call diag_error ("fms_what_is_my_id","The diag object was not registered", fatal)
 endif
     diag_id = dobj%diag_id
end function fms_diag_id_inq











!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Operator Overrides !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> \brief override for checking if object ID is greater than an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_gt_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i >= diag_not_registered) then
     ll = .false.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else
     ll = (obj%diag_id > i)
  endif
end function obj_gt_int
!> \brief override for checking if integer (ID) is greater than an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_gt_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i <= diag_not_registered) then
     ll = .false.
  elseif (.not.allocated(obj)) then
     ll = .true.
  else
     ll = (i > obj%diag_id)
  endif
end function int_gt_obj
!> \brief override for checking if object ID is less than an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_lt_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i > diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj)) then
     ll = .false.
  else
     ll = (obj%diag_id < i)
  endif
end function obj_lt_int
!> \brief override for checking if integer (ID) is less than an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_lt_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i >= diag_not_registered) then
     ll = .false.
  elseif (.not.allocated(obj)) then
     ll = .true.
  else
     ll = (i < obj%diag_id)
  endif
end function int_lt_obj
!> \brief override for checking if object ID is greater than or equal to an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_ge_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i <= diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else
     ll = (obj%diag_id >= i)
  endif
end function obj_ge_int
!> \brief override for checking if integer (ID) is greater than or equal to an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_ge_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i >= diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else
     ll = (i >= obj%diag_id)
  endif
end function int_ge_obj
!> \brief override for checking if object ID is less than or equal to an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_le_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i >= diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else
     ll = (obj%diag_id <= i)
  endif
end function obj_le_int
!> \brief override for checking if integer (ID) is less than or equal to an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_le_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i <= diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else
     ll = (i <= obj%diag_id)
  endif
end function int_le_obj
!> \brief override for checking if object ID is equal to an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_eq_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i == diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else 
     ll = (obj%diag_id == i)
  endif
end function obj_eq_int
!> \brief override for checking if integer (ID) is equal to an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_eq_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i == diag_not_registered) then
     ll = .true.
  elseif (.not.allocated(obj) ) then
     ll = .false.
  else 
     ll = (i == obj%diag_id)
  endif
end function int_eq_obj
!> \brief override for checking if object ID is not equal to an integer (IDs)
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function obj_ne_int (obj,i) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i == diag_not_registered) then
     ll = .false.
  elseif (.not.allocated(obj) ) then
     ll = .true.
  else
     ll = (obj%diag_id .ne. i)
  endif
end function obj_ne_int
!> \brief override for checking if integer (ID) is not equal to an object ID
!> @note unalloacted obj is assumed to equal diag_not_registered
pure logical function int_ne_obj (i,obj) result(ll)
 class (fms_diag_object), intent(in), allocatable :: obj
 integer,                 intent(in) :: i
  if (.not.allocated(obj) .and. i == diag_not_registered) then
     ll = .false.
  elseif (.not.allocated(obj) ) then
     ll = .true.
  else
     ll = (i .ne. obj%diag_id)
  endif
end function int_ne_obj


end module fms_diag_object_mod
