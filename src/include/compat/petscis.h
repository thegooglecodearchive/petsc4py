#ifndef _COMPAT_PETSC_IS_H
#define _COMPAT_PETSC_IS_H

#if PETSC_VERSION_(3,0,0)
#undef __FUNCT__
#define __FUNCT__ "ISCopy"
static PetscErrorCode ISCopy_Compat(IS isx, IS isy)
{
  PetscInt n,nx,ny;
  const PetscInt *ix,*iy;
  PetscTruth equal;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(isx,IS_COOKIE,1);
  PetscValidHeaderSpecific(isy,IS_COOKIE,1);
  ierr = ISGetLocalSize(isx,&nx);CHKERRQ(ierr);
  ierr = ISGetLocalSize(isy,&ny);CHKERRQ(ierr);
  ierr = ISGetIndices(isx,&ix);CHKERRQ(ierr);
  ierr = ISGetIndices(isy,&iy);CHKERRQ(ierr);
  n = PetscMin(nx,ny);
  ierr = PetscMemcmp(ix,iy,n*sizeof(PetscInt),&equal);CHKERRQ(ierr); 
  ierr = ISRestoreIndices(isx,&ix);CHKERRQ(ierr);
  ierr = ISRestoreIndices(isy,&iy);CHKERRQ(ierr);
  if (nx == ny && equal) PetscFunctionReturn(0);
  SETERRQ(PETSC_ERR_SUP, __FUNCT__"() not supported");
  PetscFunctionReturn(PETSC_ERR_SUP);
}
#define ISCopy ISCopy_Compat
#endif

#if (PETSC_VERSION_(2,3,3) || \
     PETSC_VERSION_(2,3,2))
#undef __FUNCT__
#define __FUNCT__ "ISGetIndices"
static PETSC_UNUSED
PetscErrorCode ISGetIndices_Compat(IS is, const PetscInt *ptr[])
{
  PetscInt *idx = 0;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidPointer(ptr,2);
  ierr = ISGetIndices(is,&idx);CHKERRQ(ierr);
  *ptr = idx;
  PetscFunctionReturn(0);

}
#define ISGetIndices ISGetIndices_Compat
#undef __FUNCT__
#define __FUNCT__ "ISRestoreIndices"
static PETSC_UNUSED
PetscErrorCode ISRestoreIndices_Compat(IS is, const PetscInt *ptr[])
{
  PetscInt *idx = 0;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidPointer(ptr,2);
  idx = (PetscInt *) (*ptr);
  ierr = ISRestoreIndices(is,&idx);CHKERRQ(ierr);
  *ptr = idx;
  PetscFunctionReturn(0);
}
#endif

#if (PETSC_VERSION_(2,3,3) || \
     PETSC_VERSION_(2,3,2))
#define ISRestoreIndices ISRestoreIndices_Compat
#undef __FUNCT__
#define __FUNCT__ "ISBlockGetIndices"
static PETSC_UNUSED
PetscErrorCode ISBlockGetIndices_Compat(IS is, const PetscInt *ptr[])
{
  PetscInt *idx = 0;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidPointer(ptr,2);
  ierr = ISBlockGetIndices(is,&idx);CHKERRQ(ierr);
  *ptr = idx;
  PetscFunctionReturn(0);

}
#define ISBlockGetIndices ISBlockGetIndices_Compat
#undef __FUNCT__
#define __FUNCT__ "ISBlockRestoreIndices"
static PETSC_UNUSED
PetscErrorCode ISBlockRestoreIndices_Compat(IS is, const PetscInt *ptr[])
{
  PetscInt *idx = 0;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidPointer(ptr,2);
  idx = (PetscInt *) (*ptr);
  ierr = ISBlockRestoreIndices(is,&idx);CHKERRQ(ierr);
  *ptr = idx;
  PetscFunctionReturn(0);
}
#define ISBlockRestoreIndices ISBlockRestoreIndices_Compat
#undef __FUNCT__
#define __FUNCT__ "ISBlockGetSize"
static PETSC_UNUSED
PetscErrorCode ISBlockGetSize_Compat(IS is, PetscInt *size)
{
  PetscInt N, bs=1;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidIntPointer(size,2);
  ierr = ISBlockGetBlockSize(is,&bs);CHKERRQ(ierr);
  ierr = ISGetSize(is,&N);CHKERRQ(ierr);
  *size = N/bs;
  PetscFunctionReturn(0);
}
#define ISBlockGetSize ISBlockGetSize_Compat
#undef __FUNCT__
#define __FUNCT__ "ISBlockGetLocalSize"
static PETSC_UNUSED
PetscErrorCode ISBlockGetLocalSize_Compat(IS is, PetscInt *size)
{
  PetscInt n, bs=1;
  PetscErrorCode ierr;
  PetscValidHeaderSpecific(is,IS_COOKIE,1);
  PetscValidIntPointer(size,2);
  PetscFunctionBegin;
  ierr = ISBlockGetBlockSize(is,&bs);CHKERRQ(ierr);
  ierr = ISGetLocalSize(is,&n);CHKERRQ(ierr);
  *size = n/bs;
  PetscFunctionReturn(0);
}
#define ISBlockGetLocalSize ISBlockGetLocalSize_Compat
#endif

#if (PETSC_VERSION_(2,3,3) || \
     PETSC_VERSION_(2,3,2))
#undef __FUNCT__
#define __FUNCT__ "ISLocalToGlobalMappingApply"
PETSC_STATIC_INLINE PetscErrorCode
ISLocalToGlobalMappingApply_Compat(ISLocalToGlobalMapping mapping,
				PetscInt N,const PetscInt in[],PetscInt out[])
{
  PetscInt i=0, *idx=0, Nmax=0;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(mapping,IS_LTOGM_COOKIE,1);
  if (N > 0) { PetscValidPointer(in,3);PetscValidPointer(out,3); }
  idx = mapping->indices, Nmax = mapping->n;
  for (i=0; i<N; i++) {
    if (in[i] < 0) {out[i] = in[i]; continue;}
    if (in[i] >= Nmax) SETERRQ3(PETSC_ERR_ARG_OUTOFRANGE,
				"Local index %D too large %D (max) at %D",
				in[i],Nmax,i);
    out[i] = idx[in[i]];
  }
  PetscFunctionReturn(0);
}
#undef  ISLocalToGlobalMappingApply
#define ISLocalToGlobalMappingApply ISLocalToGlobalMappingApply_Compat
#endif

#if (PETSC_VERSION_(2,3,2))
#undef __FUNCT__
#define __FUNCT__ "ISSum"
static PETSC_UNUSED
PetscErrorCode ISSum_Compat(IS is1,IS is2,IS *is3) {
  PetscTruth     f;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(is1,IS_COOKIE,1);
  PetscValidHeaderSpecific(is2,IS_COOKIE,2);
  PetscValidPointer(is3, 3);
  ierr = ISSorted(is1,&f); CHKERRQ(ierr);
  if (!f) SETERRQ(PETSC_ERR_ARG_INCOMP,"Arg 1 is not sorted");
  ierr = ISSorted(is2,&f); CHKERRQ(ierr);
  if (!f) SETERRQ(PETSC_ERR_ARG_INCOMP,"Arg 2 is not sorted");
  ierr = ISDuplicate(is1,is3); CHKERRQ(ierr);
  ierr = ISSum(is3,is2); CHKERRQ(ierr);
  PetscFunctionReturn(0);
}
#define ISSum ISSum_Compat
#endif

#endif /* _COMPAT_PETSC_IS_H */
