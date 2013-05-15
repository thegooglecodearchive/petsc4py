cdef extern from * nogil:

    ctypedef char* PetscTSType "const char*"
    PetscTSType TSEULER
    PetscTSType TSBEULER
    PetscTSType TSPSEUDO
    PetscTSType TSCN
    PetscTSType TSSUNDIALS
    PetscTSType TSRK
    #PetscTSType TSPYTHON
    PetscTSType TSTHETA
    PetscTSType TSALPHA
    PetscTSType TSGL
    PetscTSType TSSSP
    PetscTSType TSARKIMEX
    PetscTSType TSROSW
    PetscTSType TSEIMEX

    ctypedef enum PetscTSProblemType "TSProblemType":
      TS_LINEAR
      TS_NONLINEAR

    ctypedef enum PetscTSEquationType "TSEquationType":
      TS_EQ_UNSPECIFIED
      TS_EQ_EXPLICIT
      TS_EQ_ODE_EXPLICIT
      TS_EQ_DAE_SEMI_EXPLICIT_INDEX1
      TS_EQ_DAE_SEMI_EXPLICIT_INDEX2
      TS_EQ_DAE_SEMI_EXPLICIT_INDEX3
      TS_EQ_DAE_SEMI_EXPLICIT_INDEXHI
      TS_EQ_IMPLICIT
      TS_EQ_ODE_IMPLICIT
      TS_EQ_DAE_IMPLICIT_INDEX1
      TS_EQ_DAE_IMPLICIT_INDEX2
      TS_EQ_DAE_IMPLICIT_INDEX3
      TS_EQ_DAE_IMPLICIT_INDEXHI

    ctypedef enum PetscTSConvergedReason "TSConvergedReason":
      # iterating
      TS_CONVERGED_ITERATING
      # converged
      TS_CONVERGED_TIME
      TS_CONVERGED_ITS
      # diverged
      TS_DIVERGED_NONLINEAR_SOLVE
      TS_DIVERGED_STEP_REJECTED

    ctypedef int PetscTSCtxDel(void*)

    ctypedef int (*PetscTSFunctionFunction)(PetscTS,
                                            PetscReal,
                                            PetscVec,
                                            PetscVec,
                                            void*) except PETSC_ERR_PYTHON

    ctypedef int (*PetscTSJacobianFunction)(PetscTS,
                                            PetscReal,
                                            PetscVec,
                                            PetscMat*,
                                            PetscMat*,
                                            PetscMatStructure*,
                                            void*) except PETSC_ERR_PYTHON

    ctypedef int (*PetscTSIFunctionFunction)(PetscTS,
                                             PetscReal,
                                             PetscVec,
                                             PetscVec,
                                             PetscVec,
                                             void*) except PETSC_ERR_PYTHON
    ctypedef int (*PetscTSIJacobianFunction)(PetscTS,
                                             PetscReal,
                                             PetscVec,
                                             PetscVec,
                                             PetscReal,
                                             PetscMat*,
                                             PetscMat*,
                                             PetscMatStructure*,
                                             void*) except PETSC_ERR_PYTHON

    ctypedef int (*PetscTSMonitorFunction)(PetscTS,
                                           PetscInt,
                                           PetscReal,
                                           PetscVec,
                                           void*) except PETSC_ERR_PYTHON

    ctypedef int (*PetscTSPreStepFunction)  (PetscTS) except PETSC_ERR_PYTHON
    ctypedef int (*PetscTSPostStepFunction) (PetscTS) except PETSC_ERR_PYTHON

    int TSCreate(MPI_Comm comm,PetscTS*)
    int TSDestroy(PetscTS*)
    int TSView(PetscTS,PetscViewer)

    int TSSetProblemType(PetscTS,PetscTSProblemType)
    int TSGetProblemType(PetscTS,PetscTSProblemType*)
    int TSSetEquationType(PetscTS,PetscTSEquationType)
    int TSGetEquationType(PetscTS,PetscTSEquationType*)
    int TSSetType(PetscTS,PetscTSType)
    int TSGetType(PetscTS,PetscTSType*)

    int TSSetOptionsPrefix(PetscTS,char[])
    int TSAppendOptionsPrefix(PetscTS,char[])
    int TSGetOptionsPrefix(PetscTS,char*[])
    int TSSetFromOptions(PetscTS)

    int TSSetSolution(PetscTS,PetscVec)
    int TSGetSolution(PetscTS,PetscVec*)
    int TSGetSolveTime(PetscTS,PetscReal*)

    int TSGetRHSFunction(PetscTS,PetscVec*,PetscTSFunctionFunction*,void*)
    int TSGetRHSJacobian(PetscTS,PetscMat*,PetscMat*,PetscTSJacobianFunction*,void**)
    int TSSetRHSFunction(PetscTS,PetscVec,PetscTSFunctionFunction,void*)
    int TSSetRHSJacobian(PetscTS,PetscMat,PetscMat,PetscTSJacobianFunction,void*)
    int TSSetIFunction(PetscTS,PetscVec,PetscTSIFunctionFunction,void*)
    int TSSetIJacobian(PetscTS,PetscMat,PetscMat,PetscTSIJacobianFunction,void*)
    int TSGetIFunction(PetscTS,PetscVec*,PetscTSIFunctionFunction*,void*)
    int TSGetIJacobian(PetscTS,PetscMat*,PetscMat*,PetscTSIJacobianFunction*,void**)

    int TSGetKSP(PetscTS,PetscKSP*)
    int TSGetSNES(PetscTS,PetscSNES*)

    int TSGetDM(PetscTS,PetscDM*)
    int TSSetDM(PetscTS,PetscDM)

    int TSComputeRHSFunction(PetscTS,PetscReal,PetscVec,PetscVec)
    int TSComputeRHSFunctionLinear(PetscTS,PetscReal,PetscVec,PetscVec,void*)
    int TSComputeRHSJacobian(PetscTS,PetscReal,PetscVec,PetscMat*,PetscMat*,PetscMatStructure*)
    int TSComputeRHSJacobianConstant(PetscTS,PetscReal,PetscVec,PetscMat*,PetscMat*,PetscMatStructure*,void*)
    int TSComputeIFunction(PetscTS,PetscReal,PetscVec,PetscVec,PetscVec,PetscBool)
    int TSComputeIJacobian(PetscTS,PetscReal,PetscVec,PetscVec,PetscReal,PetscMat*,PetscMat*,PetscMatStructure*,PetscBool)

    int TSSetTime(PetscTS,PetscReal)
    int TSGetTime(PetscTS,PetscReal*)
    int TSSetInitialTimeStep(PetscTS,PetscReal,PetscReal)
    int TSSetTimeStep(PetscTS,PetscReal)
    int TSGetTimeStep(PetscTS,PetscReal*)
    int TSGetTimeStepNumber(PetscTS,PetscInt*)
    int TSSetDuration(PetscTS,PetscInt,PetscReal)
    int TSGetDuration(PetscTS,PetscInt*,PetscReal*)
    int TSSetExactFinalTime(PetscTS,PetscBool)
    int TSSetConvergedReason(PetscTS,PetscTSConvergedReason)
    int TSGetConvergedReason(PetscTS,PetscTSConvergedReason*)
    int TSGetSNESIterations(PetscTS,PetscInt*)
    int TSGetKSPIterations(PetscTS,PetscInt*)
    int TSGetStepRejections(PetscTS,PetscInt*)
    int TSSetMaxStepRejections(PetscTS,PetscInt)
    int TSGetSNESFailures(PetscTS,PetscInt*)
    int TSSetMaxSNESFailures(PetscTS,PetscInt)
    int TSSetErrorIfStepFails(PetscTS,PetscBool)
    int TSSetTolerances(PetscTS,PetscReal,PetscVec,PetscReal,PetscVec)
    int TSGetTolerances(PetscTS,PetscReal*,PetscVec*,PetscReal*,PetscVec*)

    int TSMonitorSet(PetscTS,PetscTSMonitorFunction,void*,PetscTSCtxDel*)
    int TSMonitorCancel(PetscTS)
    int TSMonitor(PetscTS,PetscInt,PetscReal,PetscVec)

    int TSSetPreStep(PetscTS, PetscTSPreStepFunction)
    int TSSetPostStep(PetscTS, PetscTSPostStepFunction)

    int TSSetUp(PetscTS)
    int TSReset(PetscTS)
    int TSStep(PetscTS)
    int TSSolve(PetscTS,PetscVec)

    int TSThetaSetTheta(PetscTS,PetscReal)
    int TSThetaGetTheta(PetscTS,PetscReal*)
    int TSThetaSetEndpoint(PetscTS,PetscBool)
    int TSThetaGetEndpoint(PetscTS,PetscBool*)

    int TSAlphaSetRadius(PetscTS,PetscReal)
    int TSAlphaSetParams(PetscTS,PetscReal,PetscReal,PetscReal)
    int TSAlphaGetParams(PetscTS,PetscReal*,PetscReal*,PetscReal*)

cdef extern from "custom.h" nogil:
    int TSSetTimeStepNumber(PetscTS,PetscInt)

cdef extern from "libpetsc4py.h":
    PetscTSType TSPYTHON
    int TSPythonSetContext(PetscTS,void*)
    int TSPythonGetContext(PetscTS,void**)
    int TSPythonSetType(PetscTS,char[])

# -----------------------------------------------------------------------------

cdef inline TS ref_TS(PetscTS ts):
    cdef TS ob = <TS> TS()
    ob.ts = ts
    PetscINCREF(ob.obj)
    return ob

# -----------------------------------------------------------------------------

cdef int TS_RHSFunction(
    PetscTS   ts,
    PetscReal t,
    PetscVec  x,
    PetscVec  f,
    void*     ctx,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS  Ts   = ref_TS(ts)
    cdef Vec Xvec = ref_Vec(x)
    cdef Vec Fvec = ref_Vec(f)
    (function, args, kargs) = Ts.get_attr('__rhsfunction__')
    function(Ts, toReal(t), Xvec, Fvec, *args, **kargs)
    return 0

cdef int TS_RHSJacobian(
    PetscTS   ts,
    PetscReal t,
    PetscVec  x,
    PetscMat* J,
    PetscMat* P,
    PetscMatStructure* s,
    void*     ctx,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS   Ts   = ref_TS(ts)
    cdef Vec  Xvec = ref_Vec(x)
    cdef Mat  Jmat = ref_Mat(J[0])
    cdef Mat  Pmat = ref_Mat(P[0])
    (jacobian, args, kargs) = Ts.get_attr('__rhsjacobian__')
    retv = jacobian(Ts, toReal(t), Xvec, Jmat, Pmat, *args, **kargs)
    s[0] = matstructure(retv)
    cdef PetscMat Jtmp = NULL, Ptmp = NULL
    Jtmp = J[0]; J[0] = Jmat.mat; Jmat.mat = Jtmp
    Ptmp = P[0]; P[0] = Pmat.mat; Pmat.mat = Ptmp
    return 0

# -----------------------------------------------------------------------------

cdef int TS_IFunction(
    PetscTS   ts,
    PetscReal t,
    PetscVec  x,
    PetscVec  xdot,
    PetscVec  f,
    void*     ctx,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS  Ts    = ref_TS(ts)
    cdef Vec Xvec  = ref_Vec(x)
    cdef Vec XDvec = ref_Vec(xdot)
    cdef Vec Fvec  = ref_Vec(f)
    (function, args, kargs) = Ts.get_attr('__ifunction__')
    function(Ts, toReal(t), Xvec, XDvec, Fvec, *args, **kargs)
    return 0

cdef int TS_IJacobian(
    PetscTS   ts,
    PetscReal t,
    PetscVec  x,
    PetscVec  xdot,
    PetscReal a,
    PetscMat* J,
    PetscMat* P,
    PetscMatStructure* s,
    void*     ctx,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS   Ts    = ref_TS(ts)
    cdef Vec  Xvec  = ref_Vec(x)
    cdef Vec  XDvec = ref_Vec(xdot)
    cdef Mat  Jmat  = ref_Mat(J[0])
    cdef Mat  Pmat  = ref_Mat(P[0])
    (jacobian, args, kargs) = Ts.get_attr('__ijacobian__')
    retv = jacobian(Ts, toReal(t), Xvec, XDvec, toReal(a),
                    Jmat, Pmat, *args, **kargs)
    s[0] = matstructure(retv)
    cdef PetscMat Jtmp = NULL, Ptmp = NULL
    Jtmp = J[0]; J[0] = Jmat.mat; Jmat.mat = Jtmp
    Ptmp = P[0]; P[0] = Pmat.mat; Pmat.mat = Ptmp
    return 0

# -----------------------------------------------------------------------------

cdef int TS_Monitor(
    PetscTS   ts,
    PetscInt  step,
    PetscReal time,
    PetscVec  u,
    void*     ctx,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS  Ts = ref_TS(ts)
    cdef Vec Vu = ref_Vec(u)
    cdef object monitorlist = Ts.get_attr('__monitor__')
    if monitorlist is None: return 0
    for (monitor, args, kargs) in monitorlist:
        monitor(Ts, toInt(step), toReal(time), Vu, *args, **kargs)
    return 0

# -----------------------------------------------------------------------------

cdef int TS_PreStep(
    PetscTS ts,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS Ts = ref_TS(ts)
    (prestep, args, kargs) = Ts.get_attr('__prestep__')
    prestep(Ts, *args, **kargs)
    return 0

cdef int TS_PostStep(
    PetscTS ts,
    ) except PETSC_ERR_PYTHON with gil:
    cdef TS Ts = ref_TS(ts)
    (poststep, args, kargs) = Ts.get_attr('__poststep__')
    poststep(Ts, *args, **kargs)
    return 0

# -----------------------------------------------------------------------------
