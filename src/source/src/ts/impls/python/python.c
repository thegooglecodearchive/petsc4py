#define PETSCTS_DLL

/*
  Code for general, user-defined timestepping with implicit schemes.
       
  F(t^{n+1},x^{n+1}) = G(t^{n-k},x^{n-k}), k>=0
                 t^0 = t_0
		 x^0 = x_0

*/

/* -------------------------------------------------------------------------- */

#include "src/inline/python.h"
#include "include/private/tsimpl.h"                      /*I   "petscts.h"   I*/

/* -------------------------------------------------------------------------- */

/* backward compatibility hacks */

#if (PETSC_VERSION_MAJOR    == 2 &&	\
     PETSC_VERSION_MINOR    == 3 &&	\
     PETSC_VERSION_SUBMINOR == 2 &&	\
     PETSC_VERSION_RELEASE  == 1)
#define SNESGetLinearSolveIterations SNESGetNumberLinearIterations
#endif

#if (PETSC_VERSION_MAJOR    == 2 &&	\
     PETSC_VERSION_MINOR    == 3 &&	\
     PETSC_VERSION_SUBMINOR == 3 &&	\
     PETSC_VERSION_RELEASE  == 1)
#endif

/* -------------------------------------------------------------------------- */

#define TS_PYTHON "python"
#define TSPYTHON  "python"

PETSC_EXTERN_CXX_BEGIN
EXTERN PetscErrorCode PETSCTS_DLLEXPORT TSCreatePython(MPI_Comm,const char *,const char *,TS*);
EXTERN PetscErrorCode PETSCTS_DLLEXPORT TSPythonSetContext(TS,void*);
EXTERN PetscErrorCode PETSCTS_DLLEXPORT TSPythonGetContext(TS,void**);
PETSC_EXTERN_CXX_END

/* -------------------------------------------------------------------------- */

typedef struct _TSPyOps *TSPyOps;

struct _TSPyOps {
  PetscErrorCode (*presolve)  (TS);
  PetscErrorCode (*postsolve) (TS);
  PetscErrorCode (*prestep)   (TS,PetscReal,Vec);
  PetscErrorCode (*poststep)  (TS,PetscReal,Vec);

  PetscErrorCode (*start)     (TS,PetscReal,Vec);
  PetscErrorCode (*step)      (TS,PetscReal,Vec);
  PetscErrorCode (*verify)    (TS,PetscReal,Vec,PetscTruth*,PetscReal*);

  PetscErrorCode (*monitor)(TS,PetscInt,PetscReal,Vec);

};

typedef struct {
  /**/
  PyObject   *self;
  char       *module;
  char       *factory;
  TSPyOps    ops;
  /**/
  PetscReal  utime;     /* time level t^{n+1} */
  Vec        update;    /* work vector where new solution x^{n+1} is formed */
  Vec        vec_func;  /* work vector where F(t^{n+1},x^{n+1}) is stored */
  Vec        vec_rhs;   /* work vector where G(t^{n-k},x^{n-k}) is stored */
  /**/
  struct _TSPyOps _ops;
} TS_Py;

/* -------------------------------------------------------------------------- */

#define TS_Py_Self(ts) (((TS_Py*)(ts)->data)->self)

#define TS_PYTHON_CALL_HEAD(ts, PyMethod)		\
  PETSC_PYTHON_CALL_HEAD(TS_Py_Self(ts), PyMethod)
#define TS_PYTHON_CALL_JUMP(ts, LABEL)			\
  PETSC_PYTHON_CALL_JUMP(LABEL)
#define TS_PYTHON_CALL_BODY(ts, ARGS)			\
  PETSC_PYTHON_CALL_BODY(ARGS)
#define TS_PYTHON_CALL_TAIL(ts, PyMethod)		\
  PETSC_PYTHON_CALL_TAIL()

#define TS_PYTHON_CALL(ts, PyMethod, ARGS)		\
  TS_PYTHON_CALL_HEAD(ts, PyMethod);			\
  TS_PYTHON_CALL_BODY(ts, ARGS);			\
  TS_PYTHON_CALL_TAIL(ts, PyMethod)			\
/**/  

#define TS_PYTHON_CALL_NOARGS(ts, PyMethod)		\
  TS_PYTHON_CALL_HEAD(ts, PyMethod);			\
  TS_PYTHON_CALL_BODY(ts, ("", NULL));			\
  TS_PYTHON_CALL_TAIL(ts, PyMethod)			\
/**/

#define TS_PYTHON_CALL_TSARG(ts, PyMethod)		\
  TS_PYTHON_CALL_HEAD(ts, PyMethod);			\
  TS_PYTHON_CALL_BODY(ts, ("O&",PyPetscTS_New,ts));	\
  TS_PYTHON_CALL_TAIL(ts, PyMethod)			\
/**/


/* -------------------------------------------------------------------------- */

#undef __FUNCT__  
#define __FUNCT__ "TSDestroy_Python"
static PetscErrorCode TSDestroy_Python(TS ts)
{
  TS_Py          *py   = (TS_Py *)ts->data;
  PyObject       *self = py->self;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  if (Py_IsInitialized()) {
    TS_PYTHON_CALL_NOARGS(ts, "destroy");
    py->self = NULL; Py_DecRef(self);
  }
  if (py->update)   {ierr = VecDestroy(py->update);CHKERRQ(ierr);}
  if (py->vec_func) {ierr = VecDestroy(py->vec_func);CHKERRQ(ierr);}
  if (py->vec_rhs)  {ierr = VecDestroy(py->vec_rhs);CHKERRQ(ierr);}
  ierr = PetscStrfree(py->module);CHKERRQ(ierr);
  ierr = PetscStrfree(py->factory);CHKERRQ(ierr);
  ierr = PetscFree(ts->data);CHKERRQ(ierr);
  ts->data = PETSC_NULL;
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSSetFromOptions_Python"
static PetscErrorCode TSSetFromOptions_Python(TS ts)
{
  char           *modcls[2] = { 0, 0};
  PetscInt       nmax = 2;
  PetscTruth     flg;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  ierr = PetscOptionsHead("Python options");CHKERRQ(ierr);
  ierr = PetscOptionsStringArray("-ts_python","Python module and class/factory",
				 "TSCreatePython", modcls,&nmax,&flg);CHKERRQ(ierr);
  ierr = PetscOptionsTail();CHKERRQ(ierr);
  if (flg) {
    if (nmax == 2) {
      PyObject *self = NULL;
      ierr = PetscCreatePythonObject(modcls[0],modcls[1],&self);CHKERRQ(ierr);
      ierr = TSPythonSetContext(ts,self);Py_DecRef(self);CHKERRQ(ierr);
    }
    ierr = PetscStrfree(modcls[0]); CHKERRQ(ierr);
    ierr = PetscStrfree(modcls[1]); CHKERRQ(ierr);
  }
  TS_PYTHON_CALL_TSARG(ts, "setFromOptions");
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSView_Python"
static PetscErrorCode TSView_Python(TS ts,PetscViewer viewer)
{
  TS_Py          *py = (TS_Py *)ts->data;
  PetscTruth     isascii,isstring;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  ierr = PetscTypeCompare((PetscObject)viewer,PETSC_VIEWER_ASCII,&isascii);CHKERRQ(ierr);
  ierr = PetscTypeCompare((PetscObject)viewer,PETSC_VIEWER_STRING,&isstring);CHKERRQ(ierr);
  if (isascii || isstring) {
    ierr = PetscStrfree(py->module);CHKERRQ(ierr); 
    ierr = PetscStrfree(py->factory);CHKERRQ(ierr);
    ierr = PetscPythonGetModuleAndClass(py->self,&py->module,&py->factory);CHKERRQ(ierr);
  }
  if (isascii) {
    const char* module  = py->module  ? py->module  : "no yet set";
    const char* factory = py->factory ? py->factory : "no yet set";
    ierr = PetscViewerASCIIPrintf(viewer,"  module:  %s\n",module);CHKERRQ(ierr);
    ierr = PetscViewerASCIIPrintf(viewer,"  factory: %s\n",factory);CHKERRQ(ierr);
  } 
  if (isstring) {
    const char* module  = py->module  ? py->module  : "<module>";
    const char* factory = py->factory ? py->factory : "<factory>";
    ierr = PetscViewerStringSPrintf(viewer,"%s.%s",module,factory);CHKERRQ(ierr);
  }
  TS_PYTHON_CALL_TSARG(ts, "view");
  PetscFunctionReturn(0);
}

/* -------------------------------------------------------------------------- */


/* The nonlinear equation that is to be solved with SNES */
#undef __FUNCT__  
#define __FUNCT__ "TSPyFunction"
static PetscErrorCode TSPyFunction(SNES snes,Vec x,Vec f,void *ctx)
{
  TS             ts   = (TS) ctx;
  TS_Py          *py  = (TS_Py*) ts->data;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  /* apply user-provided function */
  ierr = TSComputeRHSFunction(ts,py->utime,x,f);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

/*  The Jacobian needed for SNES */
#undef __FUNCT__  
#define __FUNCT__ "TSPyJacobian"
static PetscErrorCode TSPyJacobian(SNES snes,Vec x,Mat *AA,Mat *BB,MatStructure *str,void *ctx)
{
  TS             ts   = (TS) ctx;
  TS_Py          *py  = (TS_Py*) ts->data;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  /* apply user-provided Jacobian */
  ierr = TSComputeRHSJacobian(ts,py->utime,x,AA,BB,str);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

/* -------------------------------------------------------------------------- */

#undef __FUNCT__  
#define __FUNCT__ "TSPreSolve_Python"
static PetscErrorCode TSPreSolve_Python(TS ts)
{
  PetscFunctionBegin;
  TS_PYTHON_CALL(ts, "preSolve", ("O&",
				  PyPetscTS_New, ts ));
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSPostSolve_Python"
static PetscErrorCode TSPostSolve_Python(TS ts)
{
  PetscFunctionBegin;
  TS_PYTHON_CALL(ts, "postSolve", ("O&",
				   PyPetscTS_New, ts ));
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSPreStep_Python"
static PetscErrorCode TSPreStep_Python(TS ts, PetscReal t, Vec x)
{
  PetscFunctionBegin;
  TS_PYTHON_CALL(ts, "preStep", ("O&dO&",
				 PyPetscTS_New,  ts ,
				 (double)        t  ,
				 PyPetscVec_New, x  ));
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSPostStep_Python"
static PetscErrorCode TSPostStep_Python(TS ts, PetscReal t, Vec x)
{
  PetscFunctionBegin;
  TS_PYTHON_CALL(ts, "postStep", ("O&dO&",
				  PyPetscTS_New,  ts ,
				  (double)        t  ,
				  PyPetscVec_New, x  ));
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSStartStep_Python"
static PetscErrorCode TSStartStep_Python(TS ts,PetscReal t,Vec u)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  ierr = 0;CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSStep_Python"
static PetscErrorCode TSStep_Python(TS ts,PetscReal t,Vec u)
{
  TS_Py          *py = (TS_Py*)ts->data;
  PetscInt       its=0,lits=0;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  TS_PYTHON_CALL_HEAD(ts, "step");
  TS_PYTHON_CALL_JUMP(ts, default_step);
  TS_PYTHON_CALL_BODY(ts, ("O&dO&O&",
			   PyPetscTS_New,  ts ,
			   (double)        t  ,
			   PyPetscVec_New, u  ));
  TS_PYTHON_CALL_TAIL(ts, "step");
  goto finally;
 default_step:
  if (ts->problem_type == TS_NONLINEAR) {
#if (PETSC_VERSION_MAJOR    == 2  && \
     PETSC_VERSION_MINOR    == 3  && \
    (PETSC_VERSION_SUBMINOR == 3  || \
     PETSC_VERSION_SUBMINOR == 2) && \
     PETSC_VERSION_RELEASE  == 1)
    if (!((PetscObject)ts->snes)->type_name) {
      ierr = SNESSetType(ts->snes,SNESLS);CHKERRQ(ierr);
    }
#endif
    ierr = SNESSolve(ts->snes,py->vec_rhs,u);CHKERRQ(ierr);
  } if (ts->problem_type == TS_LINEAR) {
    MatStructure str = DIFFERENT_NONZERO_PATTERN;
    SETERRQ(1, "not yet implemented"); PetscFunctionReturn(1);
    ierr = KSPSetOperators(ts->ksp,ts->A,ts->B,str);CHKERRQ(ierr);
    ierr = KSPSolve(ts->ksp,py->vec_rhs,u);CHKERRQ(ierr);
  }
 finally:
  if (ts->problem_type == TS_NONLINEAR) {
    ierr = SNESGetIterationNumber(ts->snes,&its);CHKERRQ(ierr);
    ierr = SNESGetLinearSolveIterations(ts->snes,&lits);CHKERRQ(ierr);
  } 
  if (ts->problem_type == TS_LINEAR) {
    ierr = KSPGetIterationNumber(ts->ksp,&lits);CHKERRQ(ierr);
  }  
  ts->nonlinear_its += its; ts->linear_its += lits;
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSVerifyStep_Python"
static PetscErrorCode TSVerifyStep_Python(TS ts,PetscReal t,Vec u,PetscTruth *ok,PetscReal *dt)
{
  PetscErrorCode ierr;
  PetscFunctionBegin;
  *ok = PETSC_TRUE;
  *dt = ts->time_step;
  ierr = 0;CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

#undef __FUNCT__  
#define __FUNCT__ "TSMonitor_Python"
static PetscErrorCode TSMonitor_Python(TS ts,PetscInt i,PetscReal t,Vec x)
{
  PetscFunctionBegin;
  TS_PYTHON_CALL(ts, "monitor", ("O&ldO&",
				 PyPetscTS_New,  ts ,
				 (long)          i  ,
				 (double)        t  ,
				 PyPetscVec_New, x  ));
  /* call registered monitors */
  TSMonitor(ts,i,t,x);
  PetscFunctionReturn(0);
}


#undef __FUNCT__  
#define __FUNCT__ "TSSetUp_Python"
static PetscErrorCode TSSetUp_Python(TS ts)
{
  TS_Py          *py = (TS_Py*)ts->data;
  PetscErrorCode ierr;

  PetscFunctionBegin;
  /* check problem type, currently only for nonlinear */
  if (ts->problem_type == TS_NONLINEAR) { /* setup nonlinear problem */
    /* nothing to do at this point yet */
  } else if (ts->problem_type == TS_LINEAR) { /* setup linear problem */
    SETERRQ(PETSC_ERR_SUP,"Only for nonlinear problems");
  } else {
    SETERRQ(PETSC_ERR_ARG_OUTOFRANGE,"No such problem type");
  }
  /* create work vector for solution */
  if (py->update == PETSC_NULL) {
    ierr = VecDuplicate(ts->vec_sol,&py->update);CHKERRQ(ierr);
    ierr = PetscLogObjectParent(ts,py->update);CHKERRQ(ierr);
  }
  /* create work vector for function evaluation  */
  if (py->vec_func == PETSC_NULL) {
    ierr = PetscObjectQuery((PetscObject)ts,"__rhs_funcvec__",(PetscObject *)&py->vec_func);CHKERRQ(ierr);
    if (py->vec_func) { ierr = PetscObjectReference((PetscObject)py->vec_func);CHKERRQ(ierr); }
  }
  if (py->vec_func == PETSC_NULL) {
    ierr = VecDuplicate(ts->vec_sol,&py->vec_func);CHKERRQ(ierr);
    ierr = PetscLogObjectParent(ts,py->vec_func);CHKERRQ(ierr);
  }
  /* setup inner solvers */
  if (ts->problem_type == TS_NONLINEAR) { /* setup nonlinear problem */
    ierr = SNESSetFunction(ts->snes,py->vec_func,TSPyFunction,ts);CHKERRQ(ierr);
    ierr = SNESSetJacobian(ts->snes,ts->A,ts->B,TSPyJacobian,ts);CHKERRQ(ierr);
  } else if (ts->problem_type == TS_LINEAR) {  /* setup linear problem */
    SETERRQ(PETSC_ERR_SUP,"Only for nonlinear problems");
  }
  /* call user-provided setup function */
  TS_PYTHON_CALL_TSARG(ts, "setUp");
  PetscFunctionReturn(0);
}

#define TSPyPreSolve   (*py->ops->presolve)
#define TSPyPostSolve  (*py->ops->postsolve)
#define TSPyPreStep    (*py->ops->prestep)
#define TSPyPostStep   (*py->ops->poststep)
#define TSPyStartStep  (*py->ops->start)
#define TSPyStep       (*py->ops->step)
#define TSPyVerifyStep (*py->ops->verify)
#define TSPyMonitor    (*py->ops->monitor)
  

#undef __FUNCT__  
#define __FUNCT__ "TSSolve_Python"
static PetscErrorCode TSSolve_Python(TS ts,PetscInt *steps,PetscReal *ptime)
{
  TS_Py          *py = (TS_Py*)ts->data;
  PetscInt       i,j;
  PetscErrorCode ierr;
  
  PetscFunctionBegin;

  ts->steps         = 0;
  ts->nonlinear_its = 0;
  ts->linear_its    = 0;

  *steps = -ts->steps;
  *ptime = ts->ptime;

  /* call presolve routine */
  ierr = TSPyPreSolve(ts);CHKERRQ(ierr);
  ierr = VecCopy(ts->vec_sol,py->update);CHKERRQ(ierr);
  /* monitor solution, only if step counter is zero*/
  if (ts->steps == 0) {
    ierr = TSPyMonitor(ts,ts->steps,ts->ptime,py->update);CHKERRQ(ierr);
  }
  for (i=0; i<ts->max_steps && ts->ptime<ts->max_time; i++) {
    PetscTruth stepok = PETSC_TRUE;
    PetscReal  nextdt = ts->time_step;
    /* call prestep routine, only once per time step */
    /* update vector already have the previous solution */
    ierr = TSPyPreStep(ts,ts->ptime,py->update);CHKERRQ(ierr); 
    for (j=0; j<10; j++) { /* XXX "10" should be setteable */
      /* for j>0 update vector lost the previous solution, restore it */
      if (j > 0) { ierr = VecCopy(ts->vec_sol,py->update);CHKERRQ(ierr); }
      /* initialize time and time step */
      py->utime = ts->ptime + nextdt;
      ts->time_step = nextdt;
      /* compute rhs an initial guess for step problem */
      ierr = TSPyStartStep(ts,py->utime,py->update);CHKERRQ(ierr);
      /* solve step problem */
      ierr = TSPyStep(ts,py->utime,py->update);CHKERRQ(ierr);
      /* verify step, it can be accepted/rejected, new time step is computed  */
      ierr = TSPyVerifyStep(ts,py->utime,py->update,&stepok,&nextdt);CHKERRQ(ierr);
      if (stepok) break;
    } 
    /* XXX should generate error if step is not OK */
    /* call poststep routine */
    ts->time_step = py->utime - ts->ptime;
    ierr = TSPyPostStep(ts,py->utime,py->update);CHKERRQ(ierr);
    /* monitor solution */
    ierr = TSPyMonitor(ts,ts->steps+1,py->utime,py->update);CHKERRQ(ierr);
    /* update solution, time, time step, and step counter */
    ierr = VecCopy(py->update,ts->vec_sol);CHKERRQ(ierr);
    ts->ptime     = py->utime;
    ts->time_step = nextdt;
    ts->steps++;
  }
  /* call postsolve routine */
  ierr = TSPyPostSolve(ts);CHKERRQ(ierr);

  *steps += ts->steps;
  *ptime  = ts->ptime;

  PetscFunctionReturn(0);
}

/* -------------------------------------------------------------------------- */

/*MC
      TS_PYTHON - 

  Level: beginner

.seealso:  TS, TSCreate(), TSSetType(), TS_BEULER, TS_PSEUDO

M*/
EXTERN_C_BEGIN
#undef __FUNCT__  
#define __FUNCT__ "TSCreate_Python"
PetscErrorCode PETSCTS_DLLEXPORT TSCreate_Python(TS ts)
{
  TS_Py          *py;
  PetscErrorCode ierr;

  PetscFunctionBegin;

  ierr = PetscInitializePython();CHKERRQ(ierr);
  
  ierr = PetscNew(TS_Py,&py);CHKERRQ(ierr);
  ierr = PetscLogObjectMemory(ts,sizeof(TS_Py));CHKERRQ(ierr);
  ts->data = (void*)py;

  /* Python */
  py->self    = NULL;
  py->module  = NULL;
  py->factory = NULL;
  py->ops = &py->_ops;

  py->ops->presolve  = TSPreSolve_Python;
  py->ops->postsolve = TSPostSolve_Python;

  py->ops->prestep   = TSPreStep_Python;;
  py->ops->poststep  = TSPostStep_Python;

  py->ops->start     = TSStartStep_Python;
  py->ops->step      = TSStep_Python;
  py->ops->verify    = TSVerifyStep_Python;

  py->ops->monitor   = TSMonitor_Python;

  /* PETSc */
  ts->ops->destroy         = TSDestroy_Python;
  ts->ops->setfromoptions  = TSSetFromOptions_Python;
  ts->ops->view            = TSView_Python;
  ts->ops->setup           = TSSetUp_Python;
  ts->ops->step            = TSSolve_Python;

  py->update   = PETSC_NULL;
  py->vec_func = PETSC_NULL;
  py->vec_rhs  = PETSC_NULL;
  
  ts->problem_type = TS_NONLINEAR;

  if (ts->problem_type == TS_NONLINEAR) {
    ierr = SNESCreate(((PetscObject)ts)->comm,&ts->snes);CHKERRQ(ierr);
    ierr = PetscLogObjectParent(ts,ts->snes);CHKERRQ(ierr);
  } else if (ts->problem_type == TS_LINEAR) {
    ierr = KSPCreate(((PetscObject)ts)->comm,&ts->ksp);CHKERRQ(ierr);
    ierr = PetscLogObjectParent(ts,ts->ksp);CHKERRQ(ierr);
  }
  
  PetscFunctionReturn(0);
}
EXTERN_C_END

/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */

#undef __FUNCT__
#define __FUNCT__ "TSPythonGetContext"
/*@
   TSPythonGetContext - .

   Input Parameter:
.  ts - TS context

   Output Parameter:
.  ctx - Python context

   Level: beginner

.keywords: TS, preconditioner, create

.seealso: TS, TSCreate(), TSSetType(), TSPYTHON
@*/
PetscErrorCode PETSCTS_DLLEXPORT TSPythonGetContext(TS ts,void **ctx)
{
  TS_Py        *py;
  PetscTruth     ispython;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ts,TS_COOKIE,1);
  PetscValidPointer(ctx,2);
  *ctx = NULL;
  ierr = PetscTypeCompare((PetscObject)ts,TSPYTHON,&ispython);CHKERRQ(ierr);
  if (!ispython) PetscFunctionReturn(0);
  py = (TS_Py *) ts->data;
  *ctx = (void *) py->self;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "TSPythonSetContext"
/*@
   TSPythonSetContext - .

   Collective on TS

   Input Parameters:
.  ts - TS context
.  ctx - Python context

   Level: beginner

.keywords: TS, create

.seealso: TS, TSCreate(), TSSetType(), TSPYTHON
@*/
PetscErrorCode PETSCTS_DLLEXPORT TSPythonSetContext(TS ts,void *ctx)
{
  TS_Py        *py;
  PyObject       *old, *self = (PyObject *) ctx;
  PetscTruth     ispython;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ts,TS_COOKIE,1);
  if (ctx) PetscValidPointer(ctx,2);
  ierr = PetscTypeCompare((PetscObject)ts,TSPYTHON,&ispython);CHKERRQ(ierr);
  if (!ispython) PetscFunctionReturn(0);
  py = (TS_Py *) ts->data;
  /* do nothing if contexts are the same */
  if (self == Py_None) self = NULL;
  if (py->self == self) PetscFunctionReturn(0);
  /* del previous Python context in the TS object */
  TS_PYTHON_CALL_NOARGS(ts, "destroy");
  old = py->self; py->self = NULL; Py_DecRef(old);
  /* set current Python context in the TS object  */
  py->self = (PyObject *) self; Py_IncRef(py->self);
  TS_PYTHON_CALL_TSARG(ts, "create");
  if (ts->setupcalled) ts->setupcalled = 0;
  PetscFunctionReturn(0);
}

#undef __FUNCT__
#define __FUNCT__ "TSCreatePython"
/*@
   TSCreatePython - Creates a Python timestepper solver context.

   Collective on MPI_Comm

   Input Parameters:
.  comm - MPI communicator 
.  modname - module name
.  clsname - factory/class name

   Output Parameter:
.  ts - location to put the timestepper solver context

   Level: beginner

.keywords: TS,  create

.seealso: TS, TSCreate(), TSSetType(), TSPYTHON
@*/
PetscErrorCode PETSCTS_DLLEXPORT TSCreatePython(MPI_Comm comm,
						const char *modname,
						const char *clsname,
						TS *ts)
{
  PyObject       *self = NULL;
  PetscErrorCode ierr;
  PetscFunctionBegin;
  PetscValidHeaderSpecific(ts,TS_COOKIE,1);
  if (modname) PetscValidCharPointer(modname,2);
  if (clsname) PetscValidCharPointer(clsname,3);
  /* create the TS context and set its type */
  ierr = TSCreate(comm,ts);CHKERRQ(ierr);
  ierr = TSSetType(*ts,TSPYTHON);CHKERRQ(ierr);
  if (modname == PETSC_NULL) PetscFunctionReturn(0);
  if (clsname == PETSC_NULL) PetscFunctionReturn(0);
  /* create the Python object from module and class/factory  */
  ierr = PetscCreatePythonObject(modname,clsname,&self);CHKERRQ(ierr);
  /* set the created Python object in TS context */
  ierr = TSPythonSetContext(*ts,self);Py_DecRef(self);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

/* -------------------------------------------------------------------------- */