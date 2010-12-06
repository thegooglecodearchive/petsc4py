/* ---------------------------------------------------------------- */

#if !defined(EXTERN)
#define EXTERN extern
#endif

/* ---------------------------------------------------------------- */

#ifndef MATPYTHON
#define MATPYTHON "python"
#endif

EXTERN_C_BEGIN
EXTERN PetscErrorCode MatCreate_Python(Mat);
EXTERN_C_END

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode MatPythonSetContext(Mat,void*);
EXTERN PetscErrorCode MatPythonGetContext(Mat,void**);
PETSC_EXTERN_CXX_END

/* ---------------------------------------------------------------- */

#ifndef KSPPYTHON
#define KSPPYTHON "python"
#endif

EXTERN_C_BEGIN
EXTERN PetscErrorCode KSPCreate_Python(KSP);
EXTERN_C_END

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode KSPPythonSetContext(KSP,void*);
EXTERN PetscErrorCode KSPPythonGetContext(KSP,void**);
PETSC_EXTERN_CXX_END

/* ---------------------------------------------------------------- */

#ifndef PCPYTHON
#define PCPYTHON "python"
#endif

EXTERN_C_BEGIN
EXTERN PetscErrorCode PCCreate_Python(PC);
EXTERN_C_END

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode PCPythonSetContext(PC,void*);
EXTERN PetscErrorCode PCPythonGetContext(PC,void**);
PETSC_EXTERN_CXX_END

/* ---------------------------------------------------------------- */

#ifndef SNESPYTHON
#define SNESPYTHON "python"
#endif

EXTERN_C_BEGIN
EXTERN PetscErrorCode SNESCreate_Python(SNES);
EXTERN_C_END

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode SNESPythonSetContext(SNES,void*);
EXTERN PetscErrorCode SNESPythonGetContext(SNES,void**);
PETSC_EXTERN_CXX_END

/* ---------------------------------------------------------------- */

#ifndef TSPYTHON
#define TSPYTHON "python"
#endif

EXTERN_C_BEGIN
EXTERN PetscErrorCode TSCreate_Python(TS);
EXTERN_C_END

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode TSPythonSetContext(TS,void*);
EXTERN PetscErrorCode TSPythonGetContext(TS,void**);
PETSC_EXTERN_CXX_END

/* ---------------------------------------------------------------- */

/* XXX Up to now, this is the way it works */

#define MatRegisterStatic(a,b,c,d)  MatRegister(a,0,c,d)
#define PCRegisterStatic(a,b,c,d)   PCRegister(a,0,c,d)
#define KSPRegisterStatic(a,b,c,d)  KSPRegister(a,0,c,d)
#define SNESRegisterStatic(a,b,c,d) SNESRegister(a,0,c,d)
#define TSRegisterStatic(a,b,c,d)   TSRegister(a,0,c,d)

#undef  __FUNCT__
#define __FUNCT__ "PetscPythonRegisterAll"
static PetscErrorCode PetscPythonRegisterAll(const char path[])
{
  static PetscBool registered = PETSC_FALSE;
  PetscErrorCode ierr;
  if (registered) return 0;
  registered = PETSC_TRUE;

  PetscFunctionBegin;

  ierr = MatRegisterStatic  ( MATPYTHON,  path, "MatCreate_Python",  MatCreate_Python  ); CHKERRQ(ierr);
  ierr = KSPRegisterStatic  ( KSPPYTHON,  path, "KSPCreate_Python",  KSPCreate_Python  ); CHKERRQ(ierr);
  ierr = PCRegisterStatic   ( PCPYTHON,   path, "PCCreate_Python",   PCCreate_Python   ); CHKERRQ(ierr);
  ierr = SNESRegisterStatic ( SNESPYTHON, path, "SNESCreate_Python", SNESCreate_Python ); CHKERRQ(ierr);
  ierr = TSRegisterStatic   ( TSPYTHON,   path, "TSCreate_Python",   TSCreate_Python   ); CHKERRQ(ierr);

  PetscFunctionReturn(0);
}

/* ---------------------------------------------------------------- */
