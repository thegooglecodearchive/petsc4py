# --------------------------------------------------------------------

class KSPType(object):
    RICHARDSON = KSPRICHARDSON
    CHEBYCHEV  = KSPCHEBYCHEV
    CG         = KSPCG
    CGNE       = KSPCGNE
    STCG       = KSPSTCG
    GLTR       = KSPGLTR
    GMRES      = KSPGMRES
    FGMRES     = KSPFGMRES
    LGMRES     = KSPLGMRES
    TCQMR      = KSPTCQMR
    BCGS       = KSPBCGS
    IBCGS      = KSPIBCGS
    BCGSL      = KSPBCGSL
    CGS        = KSPCGS
    TFQMR      = KSPTFQMR
    CR         = KSPCR
    LSQR       = KSPLSQR
    PREONLY    = KSPPREONLY
    QCG        = KSPQCG
    BICG       = KSPBICG
    MINRES     = KSPMINRES
    SYMMLQ     = KSPSYMMLQ
    LCD        = KSPLCD
    #
    PYTHON = KSPPYTHON

class KSPNormType(object):
    # native
    NORM_NO               = KSP_NORM_NO
    NORM_PRECONDITIONED   = KSP_NORM_PRECONDITIONED
    NORM_UNPRECONDITIONED = KSP_NORM_UNPRECONDITIONED
    NORM_NATURAL          = KSP_NORM_NATURAL
    # aliases
    NONE = NO        = NORM_NO
    PRECONDITIONED   = NORM_PRECONDITIONED
    UNPRECONDITIONED = NORM_UNPRECONDITIONED
    NATURAL          = NORM_NATURAL

class KSPConvergedReason(object):
    #iterating
    CONVERGED_ITERATING       = KSP_CONVERGED_ITERATING
    ITERATING                 = KSP_CONVERGED_ITERATING
    # converged
    CONVERGED_RTOL            = KSP_CONVERGED_RTOL
    CONVERGED_ATOL            = KSP_CONVERGED_ATOL
    CONVERGED_ITS             = KSP_CONVERGED_ITS
    CONVERGED_CG_NEG_CURVE    = KSP_CONVERGED_CG_NEG_CURVE
    CONVERGED_CG_CONSTRAINED  = KSP_CONVERGED_CG_CONSTRAINED
    CONVERGED_STEP_LENGTH     = KSP_CONVERGED_STEP_LENGTH
    # diverged
    DIVERGED_NULL             = KSP_DIVERGED_NULL
    DIVERGED_MAX_IT           = KSP_DIVERGED_MAX_IT
    DIVERGED_DTOL             = KSP_DIVERGED_DTOL
    DIVERGED_BREAKDOWN        = KSP_DIVERGED_BREAKDOWN
    DIVERGED_BREAKDOWN_BICG   = KSP_DIVERGED_BREAKDOWN_BICG
    DIVERGED_NONSYMMETRIC     = KSP_DIVERGED_NONSYMMETRIC
    DIVERGED_INDEFINITE_PC    = KSP_DIVERGED_INDEFINITE_PC
    DIVERGED_NAN              = KSP_DIVERGED_NAN
    DIVERGED_INDEFINITE_MAT   = KSP_DIVERGED_INDEFINITE_MAT

# --------------------------------------------------------------------

cdef class KSP(Object):

    Type            = KSPType
    NormType        = KSPNormType
    ConvergedReason = KSPConvergedReason

    # --- xxx ---

    def __cinit__(self):
        self.obj = <PetscObject*> &self.ksp
        self.ksp = NULL

    def __call__(self, b, x=None):
        if x is None: # XXX do this better
            x = self.getOperators()[0].getVecLeft()
        self.solve(b, x)
        return x

    # --- xxx ---

    def view(self, Viewer viewer=None):
        cdef PetscViewer vwr = NULL
        if viewer is not None: vwr = viewer.vwr
        CHKERR( KSPView(self.ksp, vwr) )

    def destroy(self):
        CHKERR( KSPDestroy(self.ksp) )
        self.ksp = NULL
        return self

    def create(self, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscKSP newksp = NULL
        CHKERR( KSPCreate(ccomm, &newksp) )
        PetscCLEAR(self.obj); self.ksp = newksp
        return self

    def setType(self, ksp_type):
        CHKERR( KSPSetType(self.ksp, str2cp(ksp_type)) )

    def getType(self):
        cdef PetscKSPType ksp_type = NULL
        CHKERR( KSPGetType(self.ksp, &ksp_type) )
        return cp2str(ksp_type)

    def setOptionsPrefix(self, prefix):
        CHKERR( KSPSetOptionsPrefix(self.ksp, str2cp(prefix)) )

    def getOptionsPrefix(self):
        cdef const_char_p prefix = NULL
        CHKERR( KSPGetOptionsPrefix(self.ksp, &prefix) )
        return cp2str(prefix)

    def setFromOptions(self):
        CHKERR( KSPSetFromOptions(self.ksp) )

    # --- xxx ---

    def setAppCtx(self, appctx):
        Object_setAttr(<PetscObject>self.ksp, '__appctx__', appctx)

    def getAppCtx(self):
        return Object_getAttr(<PetscObject>self.ksp, '__appctx__')

    # --- xxx ---

    def setOperators(self, Mat A=None, Mat P=None, structure=None):
        cdef PetscMat amat=NULL
        if A is not None: amat = A.mat
        cdef PetscMat pmat=amat
        if P is not None: pmat = P.mat
        cdef PetscMatStructure flag = matstructure(structure)
        CHKERR( KSPSetOperators(self.ksp, amat, pmat, flag) )

    def getOperators(self):
        cdef Mat A = Mat(), P = Mat()
        cdef PetscMatStructure flag = MAT_DIFFERENT_NONZERO_PATTERN
        CHKERR( KSPGetOperators(self.ksp, &A.mat, &P.mat, &flag) )
        PetscIncref(<PetscObject>A.mat)
        PetscIncref(<PetscObject>P.mat)
        return (A, P, flag)

    def setNullSpace(self, NullSpace nsp not None):
        CHKERR( KSPSetNullSpace(self.ksp, nsp.nsp) )

    def getNullSpace(self):
        cdef NullSpace nsp = NullSpace()
        CHKERR( KSPGetNullSpace(self.ksp, &nsp.nsp) )
        PetscIncref(<PetscObject>nsp.nsp)
        return nsp

    def setPC(self, PC pc not None):
        CHKERR( KSPSetPC(self.ksp, pc.pc) )

    def getPC(self):
        cdef PC pc = PC()
        CHKERR( KSPGetPC(self.ksp, &pc.pc) )
        PetscIncref(<PetscObject>pc.pc)
        return pc

    def setPCSide(self, side):
        CHKERR( KSPSetPreconditionerSide(self.ksp, side) )

    def getPCSide(self):
        cdef PetscPCSide side = PC_LEFT
        CHKERR( KSPGetPreconditionerSide(self.ksp, &side) )
        return side

    def setNormType(self, normtype):
        CHKERR( KSPSetNormType(self.ksp, normtype) )

    def getNormType(self):
        cdef PetscKSPNormType normtype = KSP_NORM_NO
        CHKERR( KSPGetNormType(self.ksp, &normtype) )
        return normtype

    def getRhs(self):
        cdef Vec vec = Vec()
        CHKERR( KSPGetRhs(self.ksp, &vec.vec) )
        PetscIncref(<PetscObject>vec.vec)
        return vec

    def getSolution(self):
        cdef Vec vec = Vec()
        CHKERR( KSPGetSolution(self.ksp, &vec.vec) )
        PetscIncref(<PetscObject>vec.vec)
        return vec

    def getWorkVecs(self, right=None, left=None):
        cdef bint R = right is not None
        cdef bint L = left is not None
        cdef PetscInt i=0, nr=0, nl=0
        cdef PetscVec *vr=NULL, *vl=NULL
        if R: nr = right
        if L: nl = left
        cdef object vecsr = [] if R else None
        cdef object vecsl = [] if L else None
        CHKERR( KSPGetVecs(self.ksp, nr, &vr, nl, &vr) )
        try:
            for i from 0 <= i < nr:
                vecsr.append(ref_Vec(vr[i]))
            for i from 0 <= i < nl:
                vecsl.append(ref_Vec(vl[i]))
        finally:
            if nr > 0 and vr != NULL:
                VecDestroyVecs(vr, nr) # XXX errors?
            if nl > 0 and vl !=NULL:
                VecDestroyVecs(vl, nl) # XXX errors?
        #
        if R and L: return (vecsr, vecsl)
        elif R:     return vecsr
        elif L:     return vecsl
        else:       return None

    # --- xxx ---

    def setTolerances(self, rtol=None, atol=None, divtol=None, max_it=None):
        cdef PetscReal crtol, catol, cdivtol
        crtol = catol = cdivtol = PETSC_DEFAULT;
        if rtol   is not None: crtol   = asReal(rtol)
        if atol   is not None: catol   = asReal(atol)
        if divtol is not None: cdivtol = asReal(divtol)
        cdef PetscInt cmaxits = PETSC_DEFAULT
        if max_it is not None: cmaxits = max_it
        CHKERR( KSPSetTolerances(self.ksp, crtol, catol, cdivtol, cmaxits) )

    def getTolerances(self):
        cdef PetscReal crtol, catol, cdivtol
        cdef PetscInt cmaxits
        CHKERR( KSPGetTolerances(self.ksp, &crtol, &catol, &cdivtol, &cmaxits) )
        return (toReal(crtol), toReal(catol), toReal(cdivtol), cmaxits)

    def setConvergenceTest(self, converged, *args, **kargs):
        if converged is None: KSP_setConverged(self.ksp, None)
        else: KSP_setConverged(self.ksp, (converged, args, kargs))

    def getConvergenceTest(self):
        return KSP_getConverged(self.ksp)

    def callConvergenceTest(self, its, rnorm):
        cdef PetscInt  ival = its
        cdef PetscReal rval = asReal(rnorm)
        cdef PetscKSPConvergedReason reason = KSP_CONVERGED_ITERATING
        CHKERR( KSPConvergenceTestCall(self.ksp, ival, rval, &reason) )
        return reason

    def setConvergenceHistory(self, length=None, reset=False):
        cdef PetscReal *data = NULL
        cdef PetscInt   size = 10000
        cdef PetscTruth flag = PETSC_FALSE
        if   length is True:     pass
        elif length is not None: size = length
        if size < 0: size = 10000
        if reset: flag = PETSC_TRUE
        cdef ndarray hist = oarray_r(empty_r(size), NULL, &data)
        Object_setAttr(<PetscObject>self.ksp, '__history__', hist)
        CHKERR( KSPSetResidualHistory(self.ksp, data, size, flag) )

    def getConvergenceHistory(self):
        cdef PetscReal *data = NULL
        cdef PetscInt   size = 0
        CHKERR( KSPGetResidualHistory(self.ksp, &data, &size) )
        return array_r(size, data)

    def logConvergenceHistory(self, its, rnorm):
        cdef PetscInt  ival = its
        cdef PetscReal rval = asReal(rnorm)
        CHKERR( KSPLogConvergenceHistory(self.ksp, its, rval) )

    def setMonitor(self, monitor, *args, **kargs):
        if monitor is None: KSP_setMonitor(self.ksp, None)
        else: KSP_setMonitor(self.ksp, (monitor, args, kargs))

    def getMonitor(self):
        return KSP_getMonitor(self.ksp)

    def callMonitor(self, its, rnorm):
        cdef PetscInt  ival = its
        cdef PetscReal rval = asReal(rnorm)
        CHKERR( KSPMonitorCall(self.ksp, ival, rval) )

    def cancelMonitor(self):
        CHKERR( KSPMonitorCancel(self.ksp) )
        KSP_delMonitor(self.ksp)

    # --- xxx ---

    def setInitialGuessNonzero(self, bint flag):
        cdef PetscTruth guess_nonzero = PETSC_FALSE
        if flag: guess_nonzero = PETSC_TRUE
        CHKERR( KSPSetInitialGuessNonzero(self.ksp, guess_nonzero) )

    def getInitialGuessNonzero(self):
        cdef PetscTruth guess_nonzero = PETSC_FALSE
        CHKERR( KSPGetInitialGuessNonzero(self.ksp, &guess_nonzero) )
        return <bint>guess_nonzero

    def setInitialGuessKnoll(self, bint flag):
        cdef PetscTruth guess_knoll = PETSC_FALSE
        if flag: guess_knoll = PETSC_TRUE
        CHKERR( KSPSetInitialGuessKnoll(self.ksp, guess_knoll) )

    def getInitialGuessKnoll(self):
        cdef PetscTruth guess_knoll = PETSC_FALSE
        CHKERR( KSPGetInitialGuessKnoll(self.ksp, &guess_knoll) )
        return <bint>guess_knoll

    # --- xxx ---

    def setUp(self):
        CHKERR( KSPSetUp(self.ksp) )

    def setUpOnBlocks(self):
        CHKERR( KSPSetUpOnBlocks(self.ksp) )

    def solve(self, Vec b not None, Vec x not None):
        CHKERR( KSPSolve(self.ksp, b.vec, x.vec) )

    def solveTranspose(self, Vec b not None, Vec x not None):
        CHKERR( KSPSolveTranspose(self.ksp, b.vec, x.vec) )

    def setIterationNumber(self, its):
        cdef PetscInt ival = its
        CHKERR( KSPSetIterationNumber(self.ksp, ival) )

    def getIterationNumber(self):
        cdef PetscInt ival = 0
        CHKERR( KSPGetIterationNumber(self.ksp, &ival) )
        return ival

    def setResidualNorm(self, rnorm):
        cdef PetscReal rval = asReal(rnorm)
        CHKERR( KSPSetResidualNorm(self.ksp, rval) )

    def getResidualNorm(self):
        cdef PetscReal rval = 0
        CHKERR( KSPGetResidualNorm(self.ksp, &rval) )
        return toReal(rval)

    def setConvergedReason(self, reason):
        cdef PetscKSPConvergedReason val = reason
        CHKERR( KSPSetConvergedReason(self.ksp, reason) )

    def getConvergedReason(self):
        cdef PetscKSPConvergedReason reason = KSP_CONVERGED_ITERATING
        CHKERR( KSPGetConvergedReason(self.ksp, &reason) )
        return reason

    # --- xxx ---

    def createPython(self, context=None, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscKSP newksp = NULL
        CHKERR( KSPCreate(ccomm, &newksp) )
        PetscCLEAR(self.obj); self.ksp = newksp
        CHKERR( KSPSetType(self.ksp, KSPPYTHON) )
        CHKERR( KSPPythonSetContext(self.ksp, <void*>context) )
        return self

    def setPythonContext(self, context):
        CHKERR( KSPPythonSetContext(self.ksp, <void*>context) )

    def getPythonContext(self):
        cdef void *context = NULL
        CHKERR( KSPPythonGetContext(self.ksp, &context) )
        if context == NULL: return None
        else: return <object> context

    def setPythonType(self, py_type):
        CHKERR( KSPPythonSetType(self.ksp, str2cp(py_type)) )

    # --- application context ---

    property appctx:
        def __get__(self):
            return self.getAppCtx()
        def __set__(self, value):
            self.setAppCtx(value)

    # --- vectors ---

    property vec_sol:
        def __get__(self):
            return self.getSolution()

    property vec_rhs:
        def __get__(self):
            return self.getRhs()

    # --- operators ---

    property mat_op:
        def __get__(self):
            return self.getOperators()[0]

    property mat_pc:
        def __get__(self):
            return self.getOperators()[1]

    property nullsp:
        def __get__(self):
            return self.getNullSpace()
        def __set__(self, value):
            self.setNullSpace(value)

    # --- initial guess ---

    property guess_nonzero:
        def __get__(self):
            return self.getInitialGuessNonzero()
        def __set__(self, value):
            self.setInitialGuessNonzero(value)

    property guess_knoll:
        def __get__(self):
            return self.getInitialGuessKnoll()
        def __set__(self, value):
            self.setInitialGuessKnoll(value)

    # --- preconditioner ---

    property pc:
        def __get__(self):
            return self.getPC()

    property pc_side:
        def __get__(self):
            return self.getPCSide()
        def __set__(self, value):
            self.setPCSide(value)

    property norm_type:
        def __get__(self):
            return self.getNormType()
        def __set__(self, value):
            self.setNormType(value)

    # --- tolerances ---

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

    property divtol:
        def __get__(self):
            return self.getTolerances()[2]
        def __set__(self, value):
            self.setTolerances(divtol=value)

    property max_it:
        def __get__(self):
            return self.getTolerances()[3]
        def __set__(self, value):
            self.setTolerances(max_it=value)

    # --- iteration ---

    property its:
        def __get__(self):
            return self.getIterationNumber()
        def __set__(self, value):
            self.setIterationNumber(value)

    property norm:
        def __get__(self):
            return self.getResidualNorm()
        def __set__(self, value):
            self.setResidualNorm(value)

    property history:
        def __get__(self):
            return self.getConvergenceHistory()

    # --- convergence ---

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

# --------------------------------------------------------------------

del KSPType
del KSPNormType
del KSPConvergedReason

# --------------------------------------------------------------------
