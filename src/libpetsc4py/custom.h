#include <private/vecimpl.h>
#include <private/matimpl.h>
#include <private/pcimpl.h>
#include <private/kspimpl.h>
#include <private/snesimpl.h>
#include <private/tsimpl.h>

EXTERN_C_BEGIN
extern PetscErrorCode (*PetscPythonMonitorSet_C)(PetscObject,const char*);
EXTERN_C_END

#if PETSC_VERSION_(3,2,0)
#define PetscShell                  PetscFwk
#define PetscShellPythonCall        PetscFwkPythonCall
#define PetscShellPythonLoadVTable  PetscFwkPythonLoadVTable
#define PetscShellPythonClearVTable PetscFwkPythonClearVTable
#endif
EXTERN_C_BEGIN
#define PetscShellPythonCall_C        PetscShellPythonCall
#define PetscShellPythonLoadVTable_C  PetscShellPythonLoadVTable
#define PetscShellPythonClearVTable_C PetscShellPythonClearVTable
extern PetscErrorCode (*PetscShellPythonCall_C)(PetscShell,const char*,void*);
extern PetscErrorCode (*PetscShellPythonLoadVTable_C)(PetscShell,const char*,const char*,void**);
extern PetscErrorCode (*PetscShellPythonClearVTable_C)(PetscShell,void**);
EXTERN_C_END

#if PETSC_VERSION_(3,2,0)
#define _MatOps_setup setuppreallocation
#else
#define _MatOps_setup setup
#endif

#undef __FUNCT__
#define __FUNCT__ "KSPLogHistory"
PETSC_STATIC_INLINE
PetscErrorCode KSPLogHistory(KSP ksp,PetscInt iter,PetscReal rnorm)
{
  /*PetscErrorCode ierr;*/
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  KSPLogResidualHistory(ksp,rnorm);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESLogHistory"
PETSC_STATIC_INLINE
PetscErrorCode SNESLogHistory(SNES snes,PetscInt iter,PetscReal rnorm,PetscInt lits)
{
  /*PetscErrorCode ierr;*/
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  SNESLogConvHistory(snes,rnorm,lits);
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "KSPConverged"
PETSC_STATIC_INLINE
PetscErrorCode KSPConverged(KSP ksp, 
                            PetscInt iter,PetscReal rnorm,
                            KSPConvergedReason *reason)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ksp,KSP_CLASSID,1);
  if (reason) PetscValidPointer(reason,2);
  if (!iter) ksp->rnorm0 = rnorm;
  if (!iter) {
    ksp->reason = KSP_CONVERGED_ITERATING;
    ksp->ttol = PetscMax(rnorm*ksp->rtol,ksp->abstol);
  }
  if (ksp->converged) {
    ierr = (*ksp->converged)(ksp,iter,rnorm,&ksp->reason,ksp->cnvP);CHKERRQ(ierr);
  } else {
    ierr = KSPSkipConverged(ksp,iter,rnorm,&ksp->reason,NULL);CHKERRQ(ierr);
    /*ierr = KSPDefaultConverged(ksp,iter,rnorm,&ksp->reason,NULL);CHKERRQ(ierr);*/
  }
  ksp->rnorm = rnorm;
  if (reason) *reason = ksp->reason;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "SNESConverged"
PETSC_STATIC_INLINE
PetscErrorCode SNESConverged(SNES snes,
                             PetscInt iter,PetscReal xnorm,PetscReal ynorm,PetscReal fnorm,
                             SNESConvergedReason *reason)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(snes,SNES_CLASSID,1);
  if (reason) PetscValidPointer(reason,2);
  if (!iter) {
    snes->reason = SNES_CONVERGED_ITERATING;
    snes->ttol = fnorm*snes->rtol;
  }
  if (snes->ops->converged) {
    ierr = (*snes->ops->converged)(snes,iter,xnorm,ynorm,fnorm,&snes->reason,snes->cnvP);CHKERRQ(ierr);
  } else {
    ierr = SNESSkipConverged(snes,iter,xnorm,ynorm,fnorm,&snes->reason,0);CHKERRQ(ierr);
    /*ierr = SNESDefaultConverged(snes,iter,xnorm,ynorm,fnorm,&snes->reason,0);CHKERRQ(ierr);*/
  }
  snes->norm = fnorm;
  if (reason) *reason = snes->reason;
  PetscFunctionReturn(0);
}


#ifndef PETSC_ERR_PYTHON
#define PETSC_ERR_PYTHON ((PetscErrorCode)(-1))
#endif

#define PetscERROR(comm,FUNCT,n,t,msg,arg) \
  PetscError(comm,__LINE__,FUNCT,__FILE__,__SDIR__,n,t,msg,arg)

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initlibpetsc4py(void);
#else
PyMODINIT_FUNC PyInit_libpetsc4py(void);
static void initlibpetsc4py(void)
{
  PyObject *M, *m;
  M = PyImport_GetModuleDict();
  if (!M) return;
  m = PyInit_libpetsc4py();
  if (!m) return;
  PyDict_SetItemString(M, "libpetsc4py", m);
  Py_DECREF(m);
}
#endif

#undef  __FUNCT__
#define __FUNCT__ "<libpetsc4py>"
