#ifndef PETSC4PY_CUSTOM_H
#define PETSC4PY_CUSTOM_H

#undef  __FUNCT__
#define __FUNCT__ "<petsc4py.PETSc>"

#include "private/vecimpl.h"
#include "private/matimpl.h"
#include "private/kspimpl.h"
#include "private/pcimpl.h"
#include "private/snesimpl.h"
#include "private/tsimpl.h"

/* ---------------------------------------------------------------- */

#ifndef PETSC_ERR_PYTHON
#define PETSC_ERR_PYTHON ((PetscErrorCode)(-1))
#endif

#define SETERRQQ(comm,n,s) \
  return PetscError(comm,__LINE__,__FUNCT__,__FILE__,__SDIR__,\
                    n,PETSC_ERROR_INITIAL,s)
#define SETERRQQ1(comm,n,s,a1) \
  return PetscError(comm,__LINE__,__FUNCT__,__FILE__,__SDIR__,\
                    n,PETSC_ERROR_INITIAL,s,a1)
#define SETERRQQ2(comm,n,s,a1,a2) \
  return PetscError(comm,__LINE__,__FUNCT__,__FILE__,__SDIR__,\
                    n,PETSC_ERROR_INITIAL,s,a1,a2)

#if (PETSC_VERSION_(3,1,0) || \
     PETSC_VERSION_(3,0,0))
#undef SETERRQQ
#define SETERRQQ(comm,n,s) \
  return PetscError(__LINE__,__FUNCT__,__FILE__,__SDIR__,n,1,s)
#undef SETERRQQ1
#define SETERRQQ1(comm,n,s,a1) \
  return PetscError(__LINE__,__FUNCT__,__FILE__,__SDIR__,n,1,s,a1)
#undef SETERRQQ2
#define SETERRQQ2(comm,n,s,a1,a2) \
  return PetscError(__LINE__,__FUNCT__,__FILE__,__SDIR__,n,1,s,a1,a2)
#endif

/* ---------------------------------------------------------------- */

typedef PetscErrorCode (*PetscErrorHandlerFunction)
        (MPI_Comm,int,const char *,const char*,const char*,
         PetscErrorCode,PetscErrorType,const char*,void*);

static PetscErrorCode
PetscTBEH(MPI_Comm comm,
          int line,
          const char *fun,
          const char* file,
          const char *dir,
          PetscErrorCode n,
          PetscErrorType p,
          const char *mess,
          void *ctx)
{
#if (PETSC_VERSION_(3,1,0) || PETSC_VERSION_(3,0,0))
  return PetscTraceBackErrorHandler(line,fun,file,dir,n,p,mess,ctx);
#else
  return PetscTraceBackErrorHandler(comm,line,fun,file,dir,n,p,mess,ctx);
#endif
}

static PetscErrorHandlerFunction PetscPyEH = 0;

#if (PETSC_VERSION_(3,1,0) || PETSC_VERSION_(3,0,0))
static PetscErrorCode
PetscPythonErrorHandler(int line,
                        const char *fun,
                        const char* file,
                        const char *dir,
                        PetscErrorCode n,
                        int p,
                        const char *mess,
                        void *ctx)
{
  return PetscPyEH(PETSC_COMM_SELF,
                   line,fun,file,dir,
                   (PetscErrorCode)n,
                   (PetscErrorType)p,
                   mess,ctx);
}
#else
static PetscErrorCode
PetscPythonErrorHandler(MPI_Comm comm,
                        int line,
                        const char *fun,
                        const char* file,
                        const char *dir,
                        PetscErrorCode n,
                        PetscErrorType p,
                        const char *mess,
                        void *ctx)
{
  return PetscPyEH(comm,
                   line,fun,file,dir,
                   n,p,mess,ctx);
}
#endif

#undef __FUNCT__
#define __FUNCT__ "PetscPushErrorHandlerPython"
static PetscErrorCode
PetscPushErrorHandlerPython(void)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  ierr = PetscPushErrorHandler(PetscPythonErrorHandler,NULL);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscPopErrorHandlerPython"
static PetscErrorCode
PetscPopErrorHandlerPython(void)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  ierr = PetscPopErrorHandler();CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#if (PETSC_VERSION_(3,1,0) || \
     PETSC_VERSION_(3,0,0))
#define PetscStageLog StageLog
#define PetscCLASSID(stageLog,index) \
        ((stageLog)->classLog->classInfo[(index)].cookie)
#else
#define PetscCLASSID(stageLog,index) \
        ((stageLog)->classLog->classInfo[(index)].classid)
#endif

#undef __FUNCT__
#define __FUNCT__ "PetscLogStageFindId"
static PetscErrorCode
PetscLogStageFindId(const char name[], PetscLogStage *stageid)
{
  int            s;
  PetscStageLog  stageLog = 0;
  PetscBool      match = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidCharPointer(name,1);
  PetscValidIntPointer(stageid,2);
  *stageid = -1;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  for(s = 0; s < stageLog->numStages; s++) {
    const char *sname = stageLog->stageInfo[s].name;
    ierr = PetscStrcasecmp(sname, name, &match);CHKERRQ(ierr);
    if (match) { *stageid = s; break; }
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscLogClassFindId"
static PetscErrorCode
PetscLogClassFindId(const char name[], PetscClassId *classid)
{
  int            c;
  PetscStageLog  stageLog = 0;
  PetscBool      match = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidCharPointer(name,1);
  PetscValidIntPointer(classid,2);
  *classid = -1;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  for(c = 0; c < stageLog->classLog->numClasses; c++) {
    const char *cname = stageLog->classLog->classInfo[c].name;
    PetscClassId id = PetscCLASSID(stageLog,c);
    ierr = PetscStrcasecmp(cname, name, &match);CHKERRQ(ierr);
    if (match) { *classid = id; break; }
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscLogEventFindId"
static PetscErrorCode
PetscLogEventFindId(const char name[], PetscLogEvent *eventid)
{
  int            e;
  PetscStageLog  stageLog = 0;
  PetscBool      match = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidCharPointer(name,1);
  PetscValidIntPointer(eventid,2);
  *eventid = -1;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  for(e = 0; e < stageLog->eventLog->numEvents; e++) {
    const char *ename = stageLog->eventLog->eventInfo[e].name;
    ierr = PetscStrcasecmp(ename, name, &match);CHKERRQ(ierr);
    if (match) { *eventid = e; break; }
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscLogStageFindName"
static PetscErrorCode
PetscLogStageFindName(PetscLogStage stageid,
                      const char *name[])
{
  PetscStageLog stageLog = 0;
  PetscFunctionBegin;
  PetscValidPointer(name,3);
  *name = 0;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  if (stageid >=0 && stageid < stageLog->numStages) {
    *name  = stageLog->stageInfo[stageid].name;
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscLogClassFindName"
static PetscErrorCode
PetscLogClassFindName(PetscClassId classid,
                      const char *name[])
{
  int           c;
  PetscStageLog stageLog = 0;
  PetscFunctionBegin;
  PetscValidPointer(name,3);
  *name = 0;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  for(c = 0; c < stageLog->classLog->numClasses; c++) {
    if (classid == PetscCLASSID(stageLog,c)) {
      *name  = stageLog->classLog->classInfo[c].name;
      break;
    }
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "PetscLogEventFindName"
static PetscErrorCode
PetscLogEventFindName(PetscLogEvent eventid,
                      const char *name[])
{
  PetscStageLog stageLog = 0;
  PetscFunctionBegin;
  PetscValidPointer(name,3);
  *name = 0;
  if (!(stageLog=_stageLog)) PetscFunctionReturn(0); /* logging is off ? */
  if (eventid >=0 && eventid < stageLog->eventLog->numEvents) {
    *name  = stageLog->eventLog->eventInfo[eventid].name;
  }
  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "VecGetArrayC"
PETSC_STATIC_INLINE PetscErrorCode
VecGetArrayC(Vec v, PetscScalar *a[])
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(v,VEC_CLASSID,1);
  PetscValidType(v,1);
  PetscValidPointer(a,2);
  ierr = VecGetArray(v,a);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "VecRestoreArrayC"
PETSC_STATIC_INLINE PetscErrorCode
VecRestoreArrayC(Vec v, PetscScalar *a[])
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(v,VEC_CLASSID,1);
  PetscValidType(v,1);
  PetscValidPointer(a,2);
  ierr = VecRestoreArray(v,a);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "VecStrideSum"
PETSC_STATIC_INLINE PetscErrorCode
VecStrideSum(Vec v, PetscInt start, PetscScalar *a)
{
  PetscInt       i,n,bs;
  PetscScalar    *x,sum;
  MPI_Comm       comm;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(v,VEC_CLASSID,1);
  PetscValidType(v,1);
  PetscValidScalarPointer(a,2);
  ierr = VecGetBlockSize(v,&bs);CHKERRQ(ierr);
  if (start <  0)  SETERRQQ1(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
                             "Negative start %D",start);
  if (start >= bs) SETERRQQ2(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONG,
                             "Start of stride subvector (%D) is too large for block size (%D)",start,bs);
  ierr = VecGetLocalSize(v,&n);CHKERRQ(ierr);
  ierr = VecGetArray(v,&x);CHKERRQ(ierr);
  sum = (PetscScalar)0.0;
  for (i=start; i<n; i+=bs) sum += x[i];
  ierr = VecRestoreArray(v,&x);CHKERRQ(ierr);
  ierr = PetscObjectGetComm((PetscObject)v,&comm);CHKERRQ(ierr);
  ierr = MPI_Allreduce(&sum,a,1,MPIU_SCALAR,MPIU_SUM,comm);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#if PETSC_VERSION_(3,0,0)
typedef PetscMap* PetscLayout;
#define PetscLayoutSetUp PetscMapSetUp
extern PetscErrorCode PetscMapSetBlockSize(PetscMap*,PetscInt);
#define PetscLayoutSetBlockSize PetscMapSetBlockSize
extern PetscErrorCode PetscMapGetBlockSize(PetscMap*,PetscInt*);
#define PetscLayoutGetBlockSize PetscMapGetBlockSize
#endif

#undef __FUNCT__
#define __FUNCT__ "MatBlockSize_Check"
static PetscErrorCode
MatBlockSize_Check(Mat mat,PetscInt bs)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(mat,MAT_CLASSID,1);
  if (bs < 1) {
    SETERRQQ1(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Invalid block size specified, must be positive but it is %D",bs);
  }
  if (mat->rmap->n != -1 && mat->rmap->n % bs) {
    SETERRQQ2(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Local row length %D not divisible by block size %D",
              mat->rmap->n,bs);
  }
  if (mat->rmap->N != -1 && mat->rmap->N % bs) {
    SETERRQQ2(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Global row length %D not divisible by block size %D",
              mat->rmap->N,bs);
  }
  if (mat->cmap->n != -1 && mat->cmap->n % bs) {
    SETERRQQ2(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Local column length %D not divisible by block size %D",
              mat->cmap->n,bs);
  }
  if (mat->cmap->N != -1 && mat->cmap->N % bs) {
    SETERRQQ2(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Global column length %D not divisible by block size %D",
              mat->cmap->N,bs);
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatBlockSize_SetUp"
static PetscErrorCode
MatBlockSize_SetUp(Mat mat,PetscInt bs)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(mat,MAT_CLASSID,1);
  ierr = PetscLayoutSetBlockSize(mat->rmap,bs);CHKERRQ(ierr);
  ierr = PetscLayoutSetBlockSize(mat->cmap,bs);CHKERRQ(ierr);
  ierr = PetscLayoutSetUp(mat->rmap);CHKERRQ(ierr);
  ierr = PetscLayoutSetUp(mat->cmap);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatSetBlockSize_Patch"
static PetscErrorCode
MatSetBlockSize_Patch(Mat mat,PetscInt bs)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(mat,MAT_CLASSID,1);
  PetscValidType(mat,1);
  if (bs < 1) {
    SETERRQQ1(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
              "Invalid block size specified, must be positive but it is %D",bs);
  }
  if (mat->ops->setblocksize) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = (*mat->ops->setblocksize)(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  } else if (mat->rmap->bs == -1 &&
             mat->cmap->bs == -1) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  } else if (mat->rmap->bs != bs ||
             mat->cmap->bs != bs) {
    SETERRQQ1(PETSC_COMM_SELF,PETSC_ERR_ARG_INCOMP,
              "Cannot set/change the block size for matrix type %s",
              ((PetscObject)mat)->type_name);
  }
  PetscFunctionReturn(0);
}
#undef  MatSetBlockSize
#define MatSetBlockSize MatSetBlockSize_Patch

#undef __FUNCT__
#define __FUNCT__ "MatIsPreallocated"
static PetscErrorCode
MatIsPreallocated(Mat A,PetscBool *flag)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(A,MAT_CLASSID,1);
  PetscValidPointer(flag,2);
  *flag = A->preallocated;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatCreateAnyAIJ"
static PetscErrorCode
MatCreateAnyAIJ(MPI_Comm comm, PetscInt bs,
                PetscInt m, PetscInt n,
                PetscInt M, PetscInt N,
                Mat *A)
{
  Mat            mat = PETSC_NULL;
  MatType        mtype = PETSC_NULL;
  PetscMPIInt    size = 0;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  PetscValidPointer(A,7);
  ierr = MatCreate(comm,&mat);CHKERRQ(ierr);
  ierr = MatSetSizes(mat,m,n,M,N);CHKERRQ(ierr);
  ierr = MPI_Comm_size(comm, &size);CHKERRQ(ierr);
  if (bs == PETSC_DECIDE) {
    if (size > 1) mtype = (MatType)MATMPIAIJ;
    else          mtype = (MatType)MATSEQAIJ;
  } else {
    if (size > 1) mtype = (MatType)MATMPIBAIJ;
    else          mtype = (MatType)MATSEQBAIJ;
  }
  ierr = MatSetType(mat,mtype);CHKERRQ(ierr);
  if (bs != PETSC_DECIDE) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  }
  *A = mat;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatCreateAnyAIJCRL"
static PetscErrorCode
MatCreateAnyAIJCRL(MPI_Comm comm, PetscInt bs,
                   PetscInt m, PetscInt n,
                   PetscInt M, PetscInt N,
                   Mat *A)
{
  Mat            mat = PETSC_NULL;
  MatType        mtype = PETSC_NULL;
  PetscMPIInt    size = 0;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  PetscValidPointer(A,7);
  ierr = MatCreate(comm,&mat);CHKERRQ(ierr);
  ierr = MatSetSizes(mat,m,n,M,N);CHKERRQ(ierr);
  ierr = MPI_Comm_size(comm, &size);CHKERRQ(ierr);
  if (size > 1) mtype = (MatType)MATMPIAIJCRL;
  else          mtype = (MatType)MATSEQAIJCRL;
  ierr = MatSetType(mat,mtype);CHKERRQ(ierr);
  if (bs != PETSC_DECIDE) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  }
  *A = mat;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatAnyAIJSetPreallocation"
static PetscErrorCode
MatAnyAIJSetPreallocation(Mat A,PetscInt bs,
                          PetscInt d_nz,const PetscInt d_nnz[],
                          PetscInt o_nz,const PetscInt o_nnz[])
{
  PetscBool      flag = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(A,MAT_CLASSID,1);
  PetscValidType(A,1);
  if (d_nnz) PetscValidIntPointer(d_nnz,3);
  if (o_nnz) PetscValidIntPointer(o_nnz,5);
  ierr = MatIsPreallocated(A,&flag);CHKERRQ(ierr);
  if (flag) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ORDER,
             "matrix is already preallocated");
  }
  if (bs == PETSC_DECIDE) {
    ierr = MatSeqAIJSetPreallocation(A,d_nz,d_nnz);CHKERRQ(ierr);
    ierr = MatMPIAIJSetPreallocation(A,d_nz,d_nnz,o_nz,o_nnz);CHKERRQ(ierr);
  } else {
    ierr = MatBlockSize_Check(A,bs);CHKERRQ(ierr);
    ierr = MatSeqBAIJSetPreallocation(A,bs,d_nz,d_nnz);CHKERRQ(ierr);
    ierr = MatMPIBAIJSetPreallocation(A,bs,d_nz,d_nnz,o_nz,o_nnz);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(A,bs);CHKERRQ(ierr);
  }
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatAnyAIJSetPreallocationCSR"
static PetscErrorCode
MatAnyAIJSetPreallocationCSR(Mat A,PetscInt bs, const PetscInt Ii[],
                             const PetscInt Jj[], const PetscScalar V[])
{
  PetscBool      flag = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(A,MAT_CLASSID,1);
  PetscValidType(A,1);
  PetscValidIntPointer(Ii,3);
  PetscValidIntPointer(Jj,4);
  if (V) PetscValidScalarPointer(V,5);
  ierr = MatIsPreallocated(A,&flag);CHKERRQ(ierr);
  if (flag) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ORDER,
            "matrix is already preallocated");
  }
  if (bs == PETSC_DECIDE) {
    ierr = MatSeqAIJSetPreallocationCSR(A,Ii,Jj,V);CHKERRQ(ierr);
    ierr = MatMPIAIJSetPreallocationCSR(A,Ii,Jj,V);CHKERRQ(ierr);
  } else {
    ierr = MatBlockSize_Check(A,bs);CHKERRQ(ierr);
    ierr = MatSeqBAIJSetPreallocationCSR(A,bs,Ii,Jj,V);CHKERRQ(ierr);
    ierr = MatMPIBAIJSetPreallocationCSR(A,bs,Ii,Jj,V);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(A,bs);CHKERRQ(ierr);
  }

  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatCreateAnyDense"
static PetscErrorCode
MatCreateAnyDense(MPI_Comm comm, PetscInt bs,
                  PetscInt m, PetscInt n,
                  PetscInt M, PetscInt N,
                  Mat *A)
{
  Mat            mat = PETSC_NULL;
  MatType        mtype = PETSC_NULL;
  PetscMPIInt    size = 0;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  PetscValidPointer(A,7);
  ierr = MatCreate(comm,&mat);CHKERRQ(ierr);
  ierr = MatSetSizes(mat,m,n,M,N);CHKERRQ(ierr);
  ierr = MPI_Comm_size(comm,&size);CHKERRQ(ierr);
  if (size > 1) mtype = (MatType)MATMPIDENSE;
  else          mtype = (MatType)MATSEQDENSE;
  ierr = MatSetType(mat,mtype);CHKERRQ(ierr);
  if (bs != PETSC_DECIDE) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  }
  *A = mat;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatAnyDenseSetPreallocation"
static PetscErrorCode
MatAnyDenseSetPreallocation(Mat mat, PetscInt bs, PetscScalar *data)
{
  PetscBool      flag = PETSC_FALSE;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(mat,MAT_CLASSID,1);
  PetscValidType(mat,1);
  if (data) PetscValidScalarPointer(data,3);
  ierr = MatIsPreallocated(mat, &flag);CHKERRQ(ierr);
  if (flag) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ORDER,
             "matrix is already preallocated");
  }
  ierr = MatSeqDenseSetPreallocation(mat,data);CHKERRQ(ierr);
  ierr = MatMPIDenseSetPreallocation(mat,data);CHKERRQ(ierr);
  if (bs != PETSC_DECIDE) {
    ierr = MatBlockSize_Check(mat,bs);CHKERRQ(ierr);
    ierr = MatBlockSize_SetUp(mat,bs);CHKERRQ(ierr);
  }
  PetscFunctionReturn(0);
}

#ifndef MatNullSpaceFunction
typedef PetscErrorCode MatNullSpaceFunction(MatNullSpace,Vec,void*);
#endif

/* ---------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "MatFactorInfoDefaults"
static PetscErrorCode
MatFactorInfoDefaults(PetscBool incomplete, MatFactorInfo *info)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidPointer(info,2);
  ierr = MatFactorInfoInitialize(info);CHKERRQ(ierr);

  if (incomplete) {
    info->dt             = PETSC_DEFAULT;
    info->dtcount        = PETSC_DEFAULT;
    info->dtcol          = PETSC_DEFAULT;
    info->fill           = PETSC_DEFAULT;
    info->zeropivot      = 1.e-12;
    info->pivotinblocks  = 1.0;
  } else {
    info->dtcol          = 1.e-6;
    info->fill           = 5.0;
    info->zeropivot      = 1.e-12;
    info->pivotinblocks  = 1.0;
  }

#if 0
  if (incomplete) {
    info->shiftnz        = 1.e-12;
    info->shiftpd        = 0.0;
  } else {
    info->shiftnz        = 0.0;
    info->shiftpd        = 0.0;
  }
#endif

  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "KSPSetIterationNumber"
static PetscErrorCode
KSPSetIterationNumber(KSP ksp, PetscInt its)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  if (its < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  ksp->its = its;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "KSPSetResidualNorm"
static PetscErrorCode
KSPSetResidualNorm(KSP ksp, PetscReal rnorm)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  if (rnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "residual norm must be nonnegative");
  }
  ksp->rnorm = rnorm;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "KSPLogConvergenceHistory"
static PetscErrorCode
KSPLogConvergenceHistory(KSP ksp, PetscInt its, PetscReal rnorm)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  if (its   < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  if (rnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "residual norm must be nonnegative");
  }
  KSPLogResidualHistory(ksp,rnorm);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "KSPConvergenceTestCall"
static PetscErrorCode
KSPConvergenceTestCall(KSP ksp, PetscInt its, PetscReal rnorm, KSPConvergedReason *reason)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  PetscValidPointer(reason,4);
  if (its < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  if (rnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "residual norm must be nonnegative");
  }
  ierr = (*ksp->converged)(ksp,its,rnorm,reason,ksp->cnvP);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "KSPSetConvergedReason"
static PetscErrorCode
KSPSetConvergedReason(KSP ksp, KSPConvergedReason reason)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  ksp->reason = reason;
  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "SNESSetIterationNumber"
static PetscErrorCode
SNESSetIterationNumber(SNES snes, PetscInt its)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  if (its < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  snes->iter = its;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESSetFunctionNorm"
static PetscErrorCode
SNESSetFunctionNorm(SNES snes, PetscReal fnorm)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  if (fnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "function norm must be nonnegative");
  }
  snes->norm = fnorm;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESLogResidualHistoryCall"
static PetscErrorCode
SNESLogConvergenceHistory(SNES snes, PetscInt its, PetscReal fnorm, PetscInt lits)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  if (its < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  if (fnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "function norm must be nonnegative");
  }
  SNESLogConvHistory(snes,fnorm,its);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESConvergenceTestCall"
static PetscErrorCode
SNESConvergenceTestCall(SNES snes, PetscInt its,
                        PetscReal xnorm, PetscReal ynorm, PetscReal fnorm,
                        SNESConvergedReason *reason)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  PetscValidPointer(reason,4);
  if (its < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "iteration number must be nonnegative");
  }
  if (xnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "solution norm must be nonnegative");
  }
  if (ynorm < 0)
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "step norm must be nonnegative");
  if (fnorm < 0) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_OUTOFRANGE,
             "function norm must be nonnegative");
  }
  ierr = (*snes->ops->converged)(snes,its,xnorm,ynorm,fnorm,reason,snes->cnvP);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESSetConvergedReason"
static PetscErrorCode
SNESSetConvergedReason(SNES snes, SNESConvergedReason reason)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  snes->reason = reason;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "MatFDColoringSetOptionsPrefix"
static PetscErrorCode
MatFDColoringSetOptionsPrefix(MatFDColoring fdc, const char prefix[]) {
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(fdc,MAT_FDCOLORING_CLASSID,1);
  ierr = PetscObjectSetOptionsPrefix((PetscObject)fdc,prefix);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESGetUseMFFD"
static PetscErrorCode
SNESGetUseMFFD(SNES snes,PetscBool *flag)
{
  PetscErrorCode (*jac)(SNES,Vec,Mat*,Mat*,MatStructure*,void*) = PETSC_NULL;
  Mat            J = PETSC_NULL;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  PetscValidPointer(flag,2);
  *flag = PETSC_FALSE;
  ierr = SNESGetJacobian(snes,&J,0,&jac,0);CHKERRQ(ierr);
  if (J) { ierr = PetscTypeCompare((PetscObject)J,MATMFFD,flag);CHKERRQ(ierr); }
  else if (jac == MatMFFDComputeJacobian) *flag = PETSC_TRUE;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESSetUseMFFD"
static PetscErrorCode
SNESSetUseMFFD(SNES snes,PetscBool flag)
{
  const char*    prefix = PETSC_NULL;
  PetscBool      flg = PETSC_FALSE;
  Vec            r = PETSC_NULL;
  Mat            A = PETSC_NULL,B = PETSC_NULL,J = PETSC_NULL;
  KSP            ksp = PETSC_NULL;
  PC             pc = PETSC_NULL;
  void*          funP = PETSC_NULL;
  void*          jacP = PETSC_NULL;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);

  ierr = SNESGetUseMFFD(snes,&flg);CHKERRQ(ierr);
  if ( flg &&  flag) PetscFunctionReturn(0);
  if (!flg && !flag) PetscFunctionReturn(0);
  if ( flg && !flag) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONGSTATE,
             "cannot change matrix-free once it is set");
    PetscFunctionReturn(PETSC_ERR_ARG_WRONGSTATE);
  }

  ierr = SNESGetFunction(snes,&r,0,&funP);CHKERRQ(ierr);
  ierr = SNESGetJacobian(snes,&A,&B,0,&jacP);CHKERRQ(ierr);
  if (r == PETSC_NULL) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONGSTATE,
             "SNESSetFunction() must be called first");
    PetscFunctionReturn(PETSC_ERR_ARG_WRONGSTATE);
  }
  ierr = MatCreateSNESMF(snes,&J);CHKERRQ(ierr);
  ierr = SNESGetOptionsPrefix(snes,&prefix);CHKERRQ(ierr);
#if (PETSC_VERSION_(3,1,0) || PETSC_VERSION_(3,0,0))
  ierr = MatMFFDSetOptionsPrefix(J,prefix);CHKERRQ(ierr);
  ierr = MatMFFDSetFromOptions(J);CHKERRQ(ierr);
#else
  ierr = MatSetOptionsPrefix(J,prefix);CHKERRQ(ierr);
  ierr = MatSetFromOptions(J);CHKERRQ(ierr);
#endif
  if (B == PETSC_NULL) {
    PetscBool shell,python;
    ierr = SNESSetJacobian(snes,J,J,MatMFFDComputeJacobian,jacP);CHKERRQ(ierr);
    ierr = SNESGetKSP(snes,&ksp);CHKERRQ(ierr);
    ierr = KSPGetPC(ksp,&pc);CHKERRQ(ierr);
    ierr = PetscTypeCompare((PetscObject)pc,PCSHELL,&shell);CHKERRQ(ierr);
    ierr = PetscTypeCompare((PetscObject)pc,PCPYTHON,&python);CHKERRQ(ierr);
    if (!shell && !python) { ierr = PCSetType(pc,PCNONE);CHKERRQ(ierr); }
  } else {
    ierr = SNESSetJacobian(snes,J,0,0,0);CHKERRQ(ierr);
  }
  ierr = MatDestroy(&J);CHKERRQ(ierr);

  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESGetUseFDColoring"
static PetscErrorCode
SNESGetUseFDColoring(SNES snes,PetscBool *flag)
{
  PetscErrorCode (*jac)(SNES,Vec,Mat*,Mat*,MatStructure*,void*) = PETSC_NULL;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  PetscValidPointer(flag,2);
  *flag = PETSC_FALSE;
  ierr = SNESGetJacobian(snes,0,0,&jac,0);CHKERRQ(ierr);
  if (jac == SNESDefaultComputeJacobianColor) *flag = PETSC_TRUE;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESSetUseFDColoring"
static PetscErrorCode
SNESSetUseFDColoring(SNES snes,PetscBool flag)
{
  const char*    prefix = PETSC_NULL;
  PetscBool      flg = PETSC_FALSE;
  Vec            f = PETSC_NULL;
  PetscErrorCode (*fun)(SNES,Vec,Vec,void*) = PETSC_NULL;
  void*          funP = PETSC_NULL;
  Mat            A = PETSC_NULL,B = PETSC_NULL,J = PETSC_NULL;
  void*          jacP = PETSC_NULL;
  ISColoring     iscoloring = PETSC_NULL;
  MatFDColoring  fdcoloring = PETSC_NULL;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);

  ierr = SNESGetUseFDColoring(snes,&flg);CHKERRQ(ierr);
  if ( flg &&  flag) PetscFunctionReturn(0);
  if (!flg && !flag) PetscFunctionReturn(0);
  if ( flg && !flag) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONGSTATE,
             "cannot change colored finite diferences once it is set");
    PetscFunctionReturn(PETSC_ERR_ARG_WRONGSTATE);
  }

  ierr = SNESGetFunction(snes,&f,&fun,&funP);CHKERRQ(ierr);
  ierr = SNESGetJacobian(snes,&A,&B,0,&jacP);CHKERRQ(ierr);
  if (!f) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONGSTATE,
             "SNESSetFunction() must be called first");
    PetscFunctionReturn(PETSC_ERR_ARG_WRONGSTATE);
  }
  if (!A && !B) {
    SETERRQQ(PETSC_COMM_SELF,PETSC_ERR_ARG_WRONGSTATE,
             "SNESSetJacobian() must be called first");
    PetscFunctionReturn(PETSC_ERR_ARG_WRONGSTATE);
  }

  J = B ? B : A;
  ierr = MatGetOptionsPrefix(J,&prefix);CHKERRQ(ierr);
  if (!prefix) {ierr = SNESGetOptionsPrefix(snes,&prefix);CHKERRQ(ierr);}
  ierr = MatGetColoring(J,MATCOLORINGSL,&iscoloring);CHKERRQ(ierr);
  ierr = MatFDColoringCreate(J,iscoloring,&fdcoloring);CHKERRQ(ierr);
  ierr = ISColoringDestroy(&iscoloring);CHKERRQ(ierr);
  ierr = MatFDColoringSetFunction(fdcoloring,(PetscErrorCode (*)(void))fun,funP);
  ierr = MatFDColoringSetOptionsPrefix(fdcoloring,prefix);CHKERRQ(ierr);
  ierr = MatFDColoringSetFromOptions(fdcoloring);CHKERRQ(ierr);
  ierr = SNESSetJacobian(snes,A,B,SNESDefaultComputeJacobianColor,fdcoloring);CHKERRQ(ierr);
  ierr = PetscObjectCompose((PetscObject)snes,"fdcoloring",(PetscObject)fdcoloring);CHKERRQ(ierr);
  ierr = MatFDColoringDestroy(&fdcoloring);CHKERRQ(ierr);

  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "TSSetTimeStepNumber"
static PetscErrorCode
TSSetTimeStepNumber(TS ts, PetscInt step)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ts,TS_CLASSID,1);
  ts->steps = step;
  PetscFunctionReturn(0);
}

#if !(PETSC_VERSION_(3,1,0) || PETSC_VERSION_(3,0,0))
#undef __FUNCT__
#define __FUNCT__ "TSSetConvergedReason"
static PetscErrorCode
TSSetConvergedReason(TS ts,TSConvergedReason reason)
{
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ts,TS_CLASSID,1);
  ts->reason = reason;
  PetscFunctionReturn(0);
}
#endif

/* ---------------------------------------------------------------- */

#if PETSC_VERSION_(3,1,0)

#undef __FUNCT__
#define __FUNCT__ "DACreateND"
static PetscErrorCode
DACreateND(MPI_Comm comm,PetscInt dim,PetscInt dof,
           PetscInt M,PetscInt N,PetscInt P,
           PetscInt m,PetscInt n,PetscInt p,
           const PetscInt lx[],const PetscInt ly[],const PetscInt lz[],
           DABoundaryType bx,DABoundaryType by,DABoundaryType bz,
           DAStencilType stencil_type,PetscInt stencil_width,
           DM *dm)
{
  DA             da;
  DAPeriodicType ptype = DA_NONPERIODIC;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidPointer(dm,18);
  ierr = DA_Boundary2Periodic(dim,bx,by,bz,&ptype);CHKERRQ(ierr);
  ierr = DACreate(comm,&da);CHKERRQ(ierr);
  ierr = DASetDim(da,dim);CHKERRQ(ierr);
  ierr = DASetDof(da,dof);CHKERRQ(ierr);
  ierr = DASetSizes(da,M,N,P);CHKERRQ(ierr);
  ierr = DASetNumProcs(da,m,n,p);CHKERRQ(ierr);
  ierr = DASetOwnershipRanges(da,lx,ly,lz);CHKERRQ(ierr);
  ierr = DASetPeriodicity(da,ptype);CHKERRQ(ierr);
  ierr = DASetStencilType(da,stencil_type);CHKERRQ(ierr);
  ierr = DASetStencilWidth(da,stencil_width);CHKERRQ(ierr);
  *dm = (DM)da;
  PetscFunctionReturn(0);
}

#elif PETSC_VERSION_(3,0,0)

#undef __FUNCT__
#define __FUNCT__ "DACreateND"
static PetscErrorCode
DACreateND(MPI_Comm comm,PetscInt dim,PetscInt dof,
           PetscInt M,PetscInt N,PetscInt P,
           PetscInt m,PetscInt n,PetscInt p,
           const PetscInt lx[],const PetscInt ly[],const PetscInt lz[],
           DABoundaryType bx,DABoundaryType by,DABoundaryType bz,
           DAStencilType stencil_type,PetscInt stencil_width,
           DM *dm)
{
  DA             da;
  DAPeriodicType ptype = DA_NONPERIODIC;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidPointer(dm,18);
  ierr = DA_Boundary2Periodic(dim,bx,by,bz,&ptype);CHKERRQ(ierr);
  ierr = DACreate(comm,dim,ptype,stencil_type,
                  M,N,P,m,n,p,dof,stencil_width,
                  lx,ly,lz,&da);CHKERRQ(ierr);
  *dm = (DM)da;
  PetscFunctionReturn(0);
}

#else

#undef __FUNCT__
#define __FUNCT__ "DACreateND"
static PetscErrorCode
DACreateND(MPI_Comm comm,
           PetscInt dim,PetscInt dof,
           PetscInt M,PetscInt N,PetscInt P,
           PetscInt m,PetscInt n,PetscInt p,
           const PetscInt lx[],const PetscInt ly[],const PetscInt lz[],
           DMDABoundaryType bx,DMDABoundaryType by,DMDABoundaryType bz,
           DMDAStencilType stencil_type,PetscInt stencil_width,
           DM *dm)
{
  DM             da;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidPointer(dm,18);
  ierr = DMDACreate(comm,&da);CHKERRQ(ierr);
  ierr = DMDASetDim(da,dim);CHKERRQ(ierr);
  ierr = DMDASetDof(da,dof);CHKERRQ(ierr);
  ierr = DMDASetSizes(da,M,N,P);CHKERRQ(ierr);
  ierr = DMDASetNumProcs(da,m,n,p);CHKERRQ(ierr);
  ierr = DMDASetOwnershipRanges(da,lx,ly,lz);CHKERRQ(ierr);
  ierr = DMDASetBoundaryType(da,bx,by,bz);CHKERRQ(ierr);
  ierr = DMDASetStencilType(da,stencil_type);CHKERRQ(ierr);
  ierr = DMDASetStencilWidth(da,stencil_width);CHKERRQ(ierr);
  *dm = (DM)da;
  PetscFunctionReturn(0);
}

#endif

/* ---------------------------------------------------------------- */

#undef  __FUNCT__
#define __FUNCT__ "<petsc4py.PETSc>"

#endif/* PETSC4PY_CUSTOM_H*/

/*
  Local variables:
  c-basic-offset: 2
  indent-tabs-mode: nil
  End:
*/
