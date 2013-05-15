# -----------------------------------------------------------------------------

class TSType(object):
    # native
    EULER    = S_(TSEULER)
    BEULER   = S_(TSBEULER)
    PSEUDO   = S_(TSPSEUDO)
    CN       = S_(TSCN)
    SUNDIALS = S_(TSSUNDIALS)
    RK       = S_(TSRK)
    PYTHON   = S_(TSPYTHON)
    THETA    = S_(TSTHETA)
    ALPHA    = S_(TSALPHA)
    GL       = S_(TSGL)
    SSP      = S_(TSSSP)
    ARKIMEX  = S_(TSARKIMEX)
    ROSW     = S_(TSROSW)
    EIMEX    = S_(TSEIMEX)
    # aliases
    FE = EULER
    BE = BEULER
    CRANK_NICOLSON = CN
    RUNGE_KUTTA    = RK

class TSProblemType(object):
    LINEAR    = TS_LINEAR
    NONLINEAR = TS_NONLINEAR

class TSEquationType(object):
    UNSPECIFIED               = TS_EQ_UNSPECIFIED
    EXPLICIT                  = TS_EQ_EXPLICIT
    ODE_EXPLICIT              = TS_EQ_ODE_EXPLICIT
    DAE_SEMI_EXPLICIT_INDEX1  = TS_EQ_DAE_SEMI_EXPLICIT_INDEX1
    DAE_SEMI_EXPLICIT_INDEX2  = TS_EQ_DAE_SEMI_EXPLICIT_INDEX2
    DAE_SEMI_EXPLICIT_INDEX3  = TS_EQ_DAE_SEMI_EXPLICIT_INDEX3
    DAE_SEMI_EXPLICIT_INDEXHI = TS_EQ_DAE_SEMI_EXPLICIT_INDEXHI
    IMPLICIT                  = TS_EQ_IMPLICIT
    ODE_IMPLICIT              = TS_EQ_ODE_IMPLICIT
    DAE_IMPLICIT_INDEX1       = TS_EQ_DAE_IMPLICIT_INDEX1
    DAE_IMPLICIT_INDEX2       = TS_EQ_DAE_IMPLICIT_INDEX2
    DAE_IMPLICIT_INDEX3       = TS_EQ_DAE_IMPLICIT_INDEX3
    DAE_IMPLICIT_INDEXHI      = TS_EQ_DAE_IMPLICIT_INDEXHI

class TSConvergedReason(object):
    # iterating
    CONVERGED_ITERATING      = TS_CONVERGED_ITERATING
    ITERATING                = TS_CONVERGED_ITERATING
    # converged
    CONVERGED_TIME           = TS_CONVERGED_TIME
    CONVERGED_ITS            = TS_CONVERGED_ITS
    # diverged
    DIVERGED_NONLINEAR_SOLVE = TS_DIVERGED_NONLINEAR_SOLVE
    DIVERGED_STEP_REJECTED   = TS_DIVERGED_STEP_REJECTED

# -----------------------------------------------------------------------------

cdef class TS(Object):

    Type = TSType
    ProblemType = TSProblemType
    EquationType = TSEquationType
    ConvergedReason = TSConvergedReason

    # --- xxx ---

    def __cinit__(self):
        self.obj = <PetscObject*> &self.ts
        self.ts = NULL

    # --- xxx ---

    def view(self, Viewer viewer=None):
        cdef PetscViewer cviewer = NULL
        if viewer is not None: cviewer = viewer.vwr
        CHKERR( TSView(self.ts, cviewer) )

    def destroy(self):
        CHKERR( TSDestroy(&self.ts) )
        return self

    def create(self, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscTS newts = NULL
        CHKERR( TSCreate(ccomm, &newts) )
        PetscCLEAR(self.obj); self.ts = newts
        return self

    def setType(self, ts_type):
        cdef const_char *cval = NULL
        ts_type = str2bytes(ts_type, &cval)
        CHKERR( TSSetType(self.ts, cval) )

    def getType(self):
        cdef PetscTSType cval = NULL
        CHKERR( TSGetType(self.ts, &cval) )
        return bytes2str(cval)

    def setProblemType(self, ptype):
        CHKERR( TSSetProblemType(self.ts, ptype) )

    def getProblemType(self):
        cdef PetscTSProblemType ptype = TS_NONLINEAR
        CHKERR( TSGetProblemType(self.ts, &ptype) )
        return ptype

    def setEquationType(self, eqtype):
        CHKERR( TSSetEquationType(self.ts, eqtype) )

    def getEquationType(self):
        cdef PetscTSEquationType eqtype = TS_EQ_UNSPECIFIED
        CHKERR( TSGetEquationType(self.ts, &eqtype) )
        return eqtype

    def setOptionsPrefix(self, prefix):
        cdef const_char *cval = NULL
        prefix = str2bytes(prefix, &cval)
        CHKERR( TSSetOptionsPrefix(self.ts, cval) )

    def getOptionsPrefix(self):
        cdef const_char *cval = NULL
        CHKERR( TSGetOptionsPrefix(self.ts, &cval) )
        return bytes2str(cval)

    def setFromOptions(self):
        CHKERR( TSSetFromOptions(self.ts) )

    # --- application context ---

    def setAppCtx(self, appctx):
        self.set_attr('__appctx__', appctx)

    def getAppCtx(self):
        return self.get_attr('__appctx__')

    # --- user RHS Function/Jacobian routines ---

    def setRHSFunction(self, function, Vec f not None, args=None, kargs=None):
        cdef PetscVec fvec=NULL
        if f is not None: fvec = f.vec
        if function is not None:
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__rhsfunction__', (function, args, kargs))
            CHKERR( TSSetRHSFunction(self.ts, fvec,
                                     TS_RHSFunction, NULL) )
        else:
            CHKERR( TSSetRHSFunction(self.ts, fvec, NULL, NULL) )

    def setRHSJacobian(self, jacobian, Mat J, Mat P=None, args=None, kargs=None):
        cdef PetscMat Jmat=NULL
        if J is not None: Jmat = J.mat
        cdef PetscMat Pmat=Jmat
        if P is not None: Pmat = P.mat
        if jacobian is not None:
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__rhsjacobian__', (jacobian, args, kargs))
            CHKERR( TSSetRHSJacobian(self.ts, Jmat, Pmat,
                                     TS_RHSJacobian, NULL) )
        else:
            CHKERR( TSSetRHSJacobian(self.ts, Jmat, Pmat, NULL, NULL) )

    def computeRHSFunction(self, t, Vec x not None, Vec f not None):
        cdef PetscReal time = asReal(t)
        CHKERR( TSComputeRHSFunction(self.ts, time, x.vec, f.vec) )

    def computeRHSFunctionLinear(self, t, Vec x not None, Vec f not None):
        cdef PetscReal time = asReal(t)
        CHKERR( TSComputeRHSFunctionLinear(self.ts, time, x.vec, f.vec, NULL) )

    def computeRHSJacobian(self, t, Vec x not None, Mat J not None, Mat P=None):
        cdef PetscReal time = asReal(t)
        cdef PetscMat *jmat = &J.mat, *pmat = &J.mat
        if P is not None: pmat = &P.mat
        cdef PetscMatStructure flag = MAT_DIFFERENT_NONZERO_PATTERN
        CHKERR( TSComputeRHSJacobian(self.ts, time, x.vec,
                                     jmat, pmat, &flag) )
        return flag

    def computeRHSJacobianConstant(self, t, Vec x not None, Mat J not None, Mat P=None):
        cdef PetscReal time = asReal(t)
        cdef PetscMat *jmat = &J.mat, *pmat = &J.mat
        if P is not None: pmat = &P.mat
        cdef PetscMatStructure flag = MAT_DIFFERENT_NONZERO_PATTERN
        CHKERR( TSComputeRHSJacobianConstant(self.ts, time, x.vec,
                                             jmat, pmat, &flag, NULL) )
        return flag

    def getRHSFunction(self):
        cdef Vec f = Vec()
        CHKERR( TSGetRHSFunction(self.ts, &f.vec, NULL, NULL) )
        PetscINCREF(f.obj)
        cdef object function = self.get_attr('__rhsfunction__')
        return (f, function)

    def getRHSJacobian(self):
        cdef Mat J = Mat(), P = Mat()
        CHKERR( TSGetRHSJacobian(self.ts, &J.mat, &P.mat, NULL, NULL) )
        PetscINCREF(J.obj)
        PetscINCREF(P.obj)
        cdef object jacobian = self.get_attr('__rhsjacobian__')
        return (J, P, jacobian)

    # --- user Implicit Function/Jacobian routines ---

    def setIFunction(self, function, Vec f, args=None, kargs=None):
        cdef PetscVec fvec=NULL
        if f is not None: fvec = f.vec
        if function is not None:
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__ifunction__', (function, args, kargs))
            CHKERR( TSSetIFunction(self.ts, fvec,
                                   TS_IFunction, NULL) )
        else:
            CHKERR( TSSetIFunction(self.ts, fvec, NULL, NULL) )

    def setIJacobian(self, jacobian, Mat J, Mat P=None, args=None, kargs=None):
        cdef PetscMat Jmat=NULL
        if J is not None: Jmat = J.mat
        cdef PetscMat Pmat=Jmat
        if P is not None: Pmat = P.mat
        if jacobian is not None:
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__ijacobian__', (jacobian, args, kargs))
            CHKERR( TSSetIJacobian(self.ts, Jmat, Pmat,
                                   TS_IJacobian, NULL) )
        else:
            CHKERR( TSSetIJacobian(self.ts, Jmat, Pmat, NULL, NULL) )

    def computeIFunction(self,
                         t, Vec x not None, Vec xdot not None,
                         Vec f not None, imex=False):
        cdef PetscReal rval = asReal(t)
        cdef PetscBool bval = imex
        CHKERR( TSComputeIFunction(self.ts, rval, x.vec, xdot.vec,
                                   f.vec, bval) )

    def computeIJacobian(self,
                         t, Vec x not None, Vec xdot not None, a,
                         Mat J not None, Mat P=None, imex=False):
        cdef PetscReal rval1 = asReal(t)
        cdef PetscReal rval2 = asReal(a)
        cdef PetscBool bval  = imex
        cdef PetscMat *jmat = &J.mat, *pmat = &J.mat
        if P is not None: pmat = &P.mat
        cdef PetscMatStructure flag = MAT_DIFFERENT_NONZERO_PATTERN
        CHKERR( TSComputeIJacobian(self.ts, rval1, x.vec, xdot.vec, rval2,
                                   jmat, pmat, &flag, bval) )
        return flag

    def getIFunction(self):
        cdef Vec f = Vec()
        CHKERR( TSGetIFunction(self.ts, &f.vec, NULL, NULL) )
        PetscINCREF(f.obj)
        cdef object function = self.get_attr('__ifunction__')
        return (f, function)

    def getIJacobian(self):
        cdef Mat J = Mat(), P = Mat()
        CHKERR( TSGetIJacobian(self.ts, &J.mat, &P.mat, NULL, NULL) )
        PetscINCREF(J.obj)
        PetscINCREF(P.obj)
        cdef object jacobian = self.get_attr('__ijacobian__')
        return (J, P, jacobian)

    # --- solution ---

    def setSolution(self, Vec u not None):
        CHKERR( TSSetSolution(self.ts, u.vec) )

    def getSolution(self):
        cdef Vec u = Vec()
        CHKERR( TSGetSolution(self.ts, &u.vec) )
        PetscINCREF(u.obj)
        return u

    def getSolveTime(self):
        cdef PetscReal rval = 0
        CHKERR( TSGetSolveTime(self.ts, &rval) )
        return toReal(rval)

    # --- inner solver ---

    def getSNES(self):
        cdef SNES snes = SNES()
        CHKERR( TSGetSNES(self.ts, &snes.snes) )
        PetscINCREF(snes.obj)
        return snes

    def getKSP(self):
        cdef KSP ksp = KSP()
        CHKERR( TSGetKSP(self.ts, &ksp.ksp) )
        PetscINCREF(ksp.obj)
        return ksp

    # --- discretization space ---

    def getDM(self):
        cdef PetscDM newdm = NULL
        CHKERR( TSGetDM(self.ts, &newdm) )
        cdef DM dm = subtype_DM(newdm)()
        dm.dm = newdm
        PetscINCREF(dm.obj)
        return dm

    def setDM(self, DM dm not None):
        CHKERR( TSSetDM(self.ts, dm.dm) )

    # --- customization ---

    def setTime(self, t):
        cdef PetscReal rval = asReal(t)
        CHKERR( TSSetTime(self.ts, rval) )

    def getTime(self):
        cdef PetscReal rval = 0
        CHKERR( TSGetTime(self.ts, &rval) )
        return toReal(rval)

    def setInitialTimeStep(self, initial_time, initial_time_step):
        cdef PetscReal rval1 = asReal(initial_time)
        cdef PetscReal rval2 = asReal(initial_time_step)
        CHKERR( TSSetInitialTimeStep(self.ts, rval1, rval2) )

    def setTimeStep(self, time_step):
        cdef PetscReal rval = asReal(time_step)
        CHKERR( TSSetTimeStep(self.ts, rval) )

    def getTimeStep(self):
        cdef PetscReal tstep = 0
        CHKERR( TSGetTimeStep(self.ts, &tstep) )
        return toReal(tstep)

    def setStepNumber(self, step_number):
        cdef PetscInt ival = asInt(step_number)
        CHKERR( TSSetTimeStepNumber(self.ts, ival) )

    def getStepNumber(self):
        cdef PetscInt ival = 0
        CHKERR( TSGetTimeStepNumber(self.ts, &ival) )
        return toInt(ival)

    def setMaxTime(self, max_time):
        cdef PetscInt  ival = 0
        cdef PetscReal rval = asReal(max_time)
        CHKERR( TSGetDuration(self.ts, &ival, NULL) )
        CHKERR( TSSetDuration(self.ts, ival, rval) )

    def getMaxTime(self):
        cdef PetscReal rval = 0
        CHKERR( TSGetDuration(self.ts, NULL, &rval) )
        return toReal(rval)

    def setMaxSteps(self, max_steps):
        cdef PetscInt  ival = asInt(max_steps)
        cdef PetscReal rval = 0
        CHKERR( TSGetDuration(self.ts, NULL, &rval) )
        CHKERR( TSSetDuration(self.ts, ival, rval) )

    def getMaxSteps(self):
        cdef PetscInt ival = 0
        CHKERR( TSGetDuration(self.ts, &ival, NULL) )
        return toInt(ival)

    def setDuration(self, max_time, max_steps=None):
        cdef PetscInt  ival = 0
        cdef PetscReal rval = 0
        CHKERR( TSGetDuration(self.ts, &ival, &rval) )
        if max_steps is not None: ival = asInt(max_steps)
        if max_time  is not None: rval = asReal(max_time)
        CHKERR( TSSetDuration(self.ts, ival, rval) )

    def getDuration(self):
        cdef PetscInt  ival = 0
        cdef PetscReal rval = 0
        CHKERR( TSGetDuration(self.ts, &ival, &rval) )
        return (toReal(rval), toInt(ival))

    def getSNESIterations(self):
        cdef PetscInt n = 0
        CHKERR( TSGetSNESIterations(self.ts, &n) )
        return toInt(n)

    def getKSPIterations(self):
        cdef PetscInt n = 0
        CHKERR( TSGetKSPIterations(self.ts, &n) )
        return toInt(n)

    def setMaxStepRejections(self, n):
        cdef PetscInt rej = asInt(n)
        CHKERR( TSSetMaxStepRejections(self.ts, rej))

    #def getMaxStepRejections(self):
    #    cdef PetscInt n = 0
    #    CHKERR( TSGetMaxStepRejections(self.ts, &n))
    #    return toInt(n)

    def getStepRejections(self):
        cdef PetscInt n = 0
        CHKERR( TSGetStepRejections(self.ts, &n) )
        return toInt(n)

    def setMaxSNESFailures(self, n):
        cdef PetscInt fails = asInt(n)
        CHKERR( TSSetMaxSNESFailures(self.ts, fails))

    #def getMaxSNESFailures(self, n):
    #    cdef PetscInt n = 0
    #    CHKERR( TSGetMaxSNESFailures(self.ts, &n))
    #    return toInt(n)

    def getSNESFailures(self):
        cdef PetscInt n = 0
        CHKERR( TSGetSNESFailures(self.ts, &n) )
        return toInt(n)

    def setErrorIfStepFails(self, flag=True):
        cdef PetscBool bval = flag
        CHKERR( TSSetErrorIfStepFails(self.ts, bval))

    def setTolerances(self, rtol=None, atol=None):
        cdef PetscReal rrtol = PETSC_DEFAULT
        cdef PetscReal ratol = PETSC_DEFAULT
        cdef PetscVec  vrtol = NULL
        cdef PetscVec  vatol = NULL
        if rtol is None:
            pass
        elif isinstance(rtol, Vec):
            vrtol = (<Vec>rtol).vec
        else:
            rrtol = asReal(rtol)
        if atol is None:
            pass
        elif isinstance(atol, Vec):
            vatol = (<Vec>atol).vec
        else:
            ratol = asReal(atol)
        CHKERR( TSSetTolerances(self.ts, ratol, vatol, rrtol, vrtol) )

    def getTolerances(self):
        cdef PetscReal rrtol = PETSC_DEFAULT
        cdef PetscReal ratol = PETSC_DEFAULT
        cdef PetscVec  vrtol = NULL
        cdef PetscVec  vatol = NULL
        CHKERR( TSGetTolerances(self.ts, &ratol, &vatol, &rrtol, &vrtol) )
        cdef object rtol = None
        if vrtol != NULL:
            rtol = ref_Vec(vrtol)
        else:
            rtol = toReal(rrtol)
        cdef object atol = None
        if vatol != NULL:
            atol = ref_Vec(vatol)
        else:
            atol = toReal(ratol)
        return (rtol, atol)

    #def setExactFinalTime(self, flag=True):
    #    cdef PetscBool bval = flag
    #    CHKERR( TSSetExactFinalTime(self.ts, bval) )

    def setConvergedReason(self, reason):
        cdef PetscTSConvergedReason cval = reason
        CHKERR( TSSetConvergedReason(self.ts, cval) )

    def getConvergedReason(self):
        cdef PetscTSConvergedReason reason = TS_CONVERGED_ITERATING
        CHKERR( TSGetConvergedReason(self.ts, &reason) )
        return reason

    # --- monitoring ---

    def setMonitor(self, monitor, args=None, kargs=None):
        if monitor is None: return
        cdef object monitorlist = self.get_attr('__monitor__')
        if monitorlist is None:
            monitorlist = []
            self.set_attr('__monitor__', monitorlist)
            CHKERR( TSMonitorSet(self.ts, TS_Monitor, NULL, NULL) )
        if args is None: args = ()
        if kargs is None: kargs = {}
        monitorlist.append((monitor, args, kargs))

    def getMonitor(self):
        return self.get_attr('__monitor__')

    def cancelMonitor(self):
        CHKERR( TSMonitorCancel(self.ts) )
        self.set_attr('__monitor__', None)

    def monitor(self, step, time, Vec u=None):
        cdef PetscInt  ival = asInt(step)
        cdef PetscReal rval = asReal(time)
        cdef PetscVec  uvec = NULL
        if u is not None: uvec = u.vec
        if uvec == NULL:
            CHKERR( TSGetSolution(self.ts, &uvec) )
        CHKERR( TSMonitor(self.ts, ival, rval, uvec) )

    # --- solving ---

    def setPreStep(self, prestep, args=None, kargs=None):
        if prestep is not None:
            CHKERR( TSSetPreStep(self.ts, TS_PreStep) )
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__prestep__', (prestep, args, kargs))
        else:
            CHKERR( TSSetPreStep(self.ts, NULL) )
            self.set_attr('__prestep__', None)

    def getPreStep(self):
        return self.get_attr('__prestep__')

    def setPostStep(self, poststep, args=None, kargs=None):
        if poststep is not None:
            CHKERR( TSSetPostStep(self.ts, TS_PostStep) )
            if args is None: args = ()
            if kargs is None: kargs = {}
            self.set_attr('__poststep__', (poststep, args, kargs))
        else:
            CHKERR( TSSetPostStep(self.ts, NULL) )
            self.set_attr('__poststep__', None)

    def getPostStep(self):
        return self.get_attr('__poststep__')

    def setUp(self):
        CHKERR( TSSetUp(self.ts) )

    def reset(self):
        CHKERR( TSReset(self.ts) )

    def solve(self, Vec u not None):
        CHKERR( TSSolve(self.ts, u.vec) )

    def step(self):
        CHKERR( TSStep(self.ts) )

    # --- Python ---

    def createPython(self, context=None, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscTS newts = NULL
        CHKERR( TSCreate(ccomm, &newts) )
        PetscCLEAR(self.obj); self.ts = newts
        CHKERR( TSSetType(self.ts, TSPYTHON) )
        CHKERR( TSPythonSetContext(self.ts, <void*>context) )
        return self

    def setPythonContext(self, context):
        CHKERR( TSPythonSetContext(self.ts, <void*>context) )

    def getPythonContext(self):
        cdef void *context = NULL
        CHKERR( TSPythonGetContext(self.ts, &context) )
        if context == NULL: return None
        else: return <object> context

    def setPythonType(self, py_type):
        cdef const_char *cval = NULL
        py_type = str2bytes(py_type, &cval)
        CHKERR( TSPythonSetType(self.ts, cval) )

    # --- Theta ---

    def setTheta(self, theta):
        cdef PetscReal rval = asReal(theta)
        CHKERR( TSThetaSetTheta(self.ts, rval) )

    def getTheta(self):
        cdef PetscReal rval = 0
        CHKERR( TSThetaGetTheta(self.ts, &rval) )
        return toReal(rval)

    def setThetaEndpoint(self, flag=True):
        cdef PetscBool bval = flag
        CHKERR( TSThetaSetEndpoint(self.ts, bval) )

    def getThetaEndpoint(self):
        cdef PetscBool bval = PETSC_FALSE
        CHKERR( TSThetaGetEndpoint(self.ts, &bval) )
        return <bint> bval

    # --- Alpha ---

    def setAlphaRadius(self, radius):
        cdef PetscReal rval = asReal(radius)
        CHKERR( TSAlphaSetRadius(self.ts, rval) )

    def setAlphaParams(self, alpha_m=None,alpha_f=None, gamma=None):
        cdef PetscReal rval1 = 0, rval2 = 0, rval3 = 0
        try: CHKERR( TSAlphaGetParams(self.ts, &rval1, &rval2, &rval3) )
        except PetscError: pass
        if alpha_m is not None: rval1 = asReal(alpha_m)
        if alpha_f is not None: rval2 = asReal(alpha_f)
        if gamma   is not None: rval3 = asReal(gamma)
        CHKERR( TSAlphaSetParams(self.ts,  rval1,  rval2,  rval3) )

    def getAlphaParams(self):
        cdef PetscReal rval1 = 0, rval2 = 0, rval3 = 0
        CHKERR( TSAlphaGetParams(self.ts, &rval1, &rval2, &rval3) )
        return (toReal(rval1), toReal(rval2), toReal(rval3))

    # --- application context ---

    property appctx:
        def __get__(self):
            return self.getAppCtx()
        def __set__(self, value):
            self.setAppCtx(value)

    # --- discretization space ---

    property dm:
        def __get__(self):
            return self.getDM()
        def __set__(self, value):
            self.setDM(value)

    # --- xxx ---

    property problem_type:
        def __get__(self):
            return self.getProblemType()
        def __set__(self, value):
            self.setProblemType(value)

    property equation_type:
        def __get__(self):
            return self.getEquationType()
        def __set__(self, value):
            self.setEquationType(value)

    property snes:
        def __get__(self):
            return self.getSNES()

    property ksp:
        def __get__(self):
            return self.getKSP()

    property vec_sol:
        def __get__(self):
            return self.getSolution()

    # --- xxx ---

    property time:
        def __get__(self):
            return self.getTime()
        def __set__(self, value):
            self.setTime(value)

    property time_step:
        def __get__(self):
            return self.getTimeStep()
        def __set__(self, value):
            self.setTimeStep(value)

    property step_number:
        def __get__(self):
            return self.getStepNumber()
        def __set__(self, value):
            self.setStepNumber(value)

    property max_time:
        def __get__(self):
            return self.getMaxTime()
        def __set__(self, value):
            self.setMaxTime(value)

    property max_steps:
        def __get__(self):
            return self.getMaxSteps()
        def __set__(self, value):
            self.setMaxSteps(value)

    # --- convergence ---

    property rtol:
        def __get__(self):
            return self.getTolerances()[0]
        def __set__(self, value):
            self.setTolerances(rtol=value)

    property atol:
        def __get__(self):
            return self.getTolerances()[1]
        def __set__(self, value):
            self.setTolerances(atol=value)

    property reason:
        def __get__(self):
            return self.getConvergedReason()
        def __set__(self, value):
            self.setConvergedReason(value)

    property iterating:
        def __get__(self):
            return self.reason == 0

    property converged:
        def __get__(self):
            return self.reason > 0

    property diverged:
        def __get__(self):
            return self.reason < 0

# -----------------------------------------------------------------------------

del TSType
del TSProblemType
del TSEquationType
del TSConvergedReason

# -----------------------------------------------------------------------------
