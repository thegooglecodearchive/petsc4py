# --------------------------------------------------------------------

class DAPeriodicType(object):
    NONE = DA_PERIODIC_NONE
    #
    X    = DA_PERIODIC_X
    Y    = DA_PERIODIC_Y
    Z    = DA_PERIODIC_Z
    XY   = DA_PERIODIC_XY
    XZ   = DA_PERIODIC_XZ
    YZ   = DA_PERIODIC_YZ
    XYZ  = DA_PERIODIC_XYZ
    #
    PERIODIC_XYZ = DA_PERIODIC_XYZ
    GHOSTED_XYZ  = DA_GHOSTED_XYZ

class DAStencilType(object):
    STAR = DA_STENCIL_STAR
    BOX  = DA_STENCIL_BOX

class DAInterpolationType(object):
    Q0 = DA_INTERPOLATION_Q0
    Q1 = DA_INTERPOLATION_Q1

class DAElementType(object):
    P1 = DA_ELEMENT_P1
    Q1 = DA_ELEMENT_Q1

# --------------------------------------------------------------------

cdef class DA(Object):

    PeriodicType      = DAPeriodicType
    StencilType       = DAStencilType
    InterpolationType = DAInterpolationType
    ElementType       = DAElementType

    def __cinit__(self):
        self.obj = <PetscObject*> &self.da
        self.da = NULL

    def view(self, Viewer viewer=None):
        cdef PetscViewer cviewer = NULL
        if viewer is not None: cviewer = viewer.vwr
        CHKERR( DAView(self.da, cviewer) )

    def destroy(self):
        CHKERR( DADestroy(self.da) )
        self.da = NULL
        return self

    def create(self, dim=None, dof=1,
               sizes=None, proc_sizes=None, periodic_type=None,
               stencil_type=None, stencil_width=1, comm=None):
        #
        cdef object arg = None
        try: arg = tuple(dim)
        except TypeError: pass
        else: dim, sizes = None, arg
        #
        cdef PetscInt ndim = PETSC_DECIDE
        cdef PetscInt ndof = 1
        cdef PetscInt M = PETSC_DECIDE, m = PETSC_DECIDE, *lx = NULL
        cdef PetscInt N = PETSC_DECIDE, n = PETSC_DECIDE, *ly = NULL
        cdef PetscInt P = PETSC_DECIDE, p = PETSC_DECIDE, *lz = NULL
        cdef PetscDAPeriodicType ptype = DA_PERIODIC_NONE
        cdef PetscDAStencilType  stype = DA_STENCIL_BOX
        cdef PetscInt            swidth = 1
        # global grid sizes
        cdef object gsizes = sizes
        if gsizes is None: gsizes = ()
        else: gsizes = tuple(gsizes)
        cdef PetscInt gdim = asDims(gsizes, &M, &N, &P)
        assert gdim <= 3
        # processor sizes
        cdef object psizes = proc_sizes
        if psizes is None: psizes = ()
        else: psizes = tuple(psizes)
        cdef PetscInt pdim = asDims(psizes, &m, &n, &p)
        assert pdim <= 3
        # vertex distribution
        lx = NULL # XXX implement!
        ly = NULL # XXX implement!
        lz = NULL # XXX implement!
        # dim and dof, periodicity, stencil type & width
        if dim is not None: ndim = asInt(dim)
        if dof is not None: ndof = asInt(dof)
        if periodic_type is not None: ptype = periodic_type
        if stencil_type  is not None: stype = stencil_type
        if stencil_width is not None: swidth = asInt(stencil_width)
        if ndim==PETSC_DECIDE and gdim>0: ndim = gdim
        if ndof==PETSC_DECIDE: ndof = 1
        # create the DA object
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscDA newda = NULL
        CHKERR( DACreateND(ccomm, ndim, ndof,
                           M, N, P, m, n, p, lx, ly, lz,
                           ptype, stype, swidth, &newda) )
        PetscCLEAR(self.obj); self.da = newda
        return self

    def setOptionsPrefix(self, prefix):
        cdef const_char *cval = NULL
        prefix = str2bytes(prefix, &cval)
        CHKERR( DASetOptionsPrefix(self.da, cval) )

    def setFromOptions(self):
        CHKERR( DASetFromOptions(self.da) )

    #

    def getDim(self):
        cdef PetscInt dim = 0
        CHKERR( DAGetInfo(self.da,
                          &dim,
                          NULL, NULL, NULL,
                          NULL, NULL, NULL,
                          NULL, NULL,
                          NULL, NULL) )
        return toInt(dim)

    def getDof(self):
        cdef PetscInt dof = 0
        CHKERR( DAGetInfo(self.da,
                          NULL,
                          NULL, NULL, NULL,
                          NULL, NULL, NULL,
                          &dof, NULL,
                          NULL, NULL) )
        return toInt(dof)

    def getSizes(self):
        cdef PetscInt dim = 0
        cdef PetscInt M = PETSC_DECIDE
        cdef PetscInt N = PETSC_DECIDE
        cdef PetscInt P = PETSC_DECIDE
        CHKERR( DAGetInfo(self.da,
                          &dim,
                          &M, &N, &P,
                          NULL, NULL, NULL,
                          NULL, NULL,
                          NULL, NULL) )
        return (toInt(M), toInt(N), toInt(P))[:<Py_ssize_t>dim]

    def getProcSizes(self):
        cdef PetscInt dim = 0
        cdef PetscInt m = PETSC_DECIDE
        cdef PetscInt n = PETSC_DECIDE
        cdef PetscInt p = PETSC_DECIDE
        CHKERR( DAGetInfo(self.da,
                          &dim,
                          NULL, NULL, NULL,
                          &m, &n, &p,
                          NULL, NULL,
                          NULL, NULL) )
        return (toInt(m), toInt(n), toInt(p))[:<Py_ssize_t>dim]

    def getPeriodicType(self):
        cdef PetscDAPeriodicType ptype = DA_PERIODIC_NONE
        CHKERR( DAGetInfo(self.da,
                          NULL,
                          NULL, NULL, NULL,
                          NULL, NULL, NULL,
                          NULL, NULL,
                          &ptype, NULL) )
        return ptype

    def getStencilType(self):
        cdef PetscDAStencilType  stype = DA_STENCIL_BOX
        CHKERR( DAGetInfo(self.da,
                          NULL,
                          NULL, NULL, NULL,
                          NULL, NULL, NULL,
                          NULL, NULL,
                          NULL, &stype) )
        return stype

    def getStencilWidth(self):
        cdef PetscInt swidth = 0
        CHKERR( DAGetInfo(self.da,
                          NULL,
                          NULL, NULL, NULL,
                          NULL, NULL, NULL,
                          NULL, &swidth,
                          NULL, NULL) )
        return toInt(swidth)

    #

    def getRanges(self):
        cdef PetscInt dim=0, x=0, y=0, z=0, m=0, n=0, p=0
        CHKERR( DAGetDim(self.da, &dim) )
        CHKERR( DAGetCorners(self.da,
                             &x, &y, &z,
                             &m, &n, &p) )
        return ((toInt(x), toInt(x+m)),
                (toInt(y), toInt(y+n)),
                (toInt(z), toInt(z+p)))[:<Py_ssize_t>dim]

    def getGhostRanges(self):
        cdef PetscInt dim=0, x=0, y=0, z=0, m=0, n=0, p=0
        CHKERR( DAGetDim(self.da, &dim) )
        CHKERR( DAGetGhostCorners(self.da,
                                  &x, &y, &z,
                                  &m, &n, &p) )
        return ((toInt(x), toInt(x+m)),
                (toInt(y), toInt(y+n)),
                (toInt(z), toInt(z+p)))[:<Py_ssize_t>dim]

    def getCorners(self):
        cdef PetscInt dim=0, x=0, y=0, z=0, m=0, n=0, p=0
        CHKERR( DAGetDim(self.da, &dim) )
        CHKERR( DAGetCorners(self.da,
                             &x, &y, &z,
                             &m, &n, &p) )
        return ((toInt(x), toInt(y), toInt(z))[:<Py_ssize_t>dim],
                (toInt(m), toInt(n), toInt(p))[:<Py_ssize_t>dim])

    def getGhostCorners(self):
        cdef PetscInt dim=0, x=0, y=0, z=0, m=0, n=0, p=0
        CHKERR( DAGetDim(self.da, &dim) )
        CHKERR( DAGetGhostCorners(self.da,
                                  &x, &y, &z,
                                  &m, &n, &p) )
        return ((toInt(x), toInt(y), toInt(z))[:<Py_ssize_t>dim],
                (toInt(m), toInt(n), toInt(p))[:<Py_ssize_t>dim])

    #

    def setUniformCoordinates(self,
                              xmin=0, xmax=1,
                              ymin=0, ymax=1,
                              zmin=0, zmax=1):
        cdef PetscReal _xmin = asReal(xmin), _xmax = asReal(xmax)
        cdef PetscReal _ymin = asReal(ymin), _ymax = asReal(ymax)
        cdef PetscReal _zmin = asReal(zmin), _zmax = asReal(zmax)
        CHKERR( DASetUniformCoordinates(self.da,
                                        _xmin, _xmax,
                                        _ymin, _ymax,
                                        _zmin, _zmax) )

    def setCoordinates(self, Vec c not None):
        CHKERR( DASetCoordinates(self.da, c.vec) )

    def getCoordinates(self):
        cdef Vec c = Vec()
        CHKERR( DAGetCoordinates(self.da, &c.vec) )
        PetscIncref(<PetscObject>c.vec)
        return c

    def getCoordinateDA(self):
        cdef DA cda = DA()
        CHKERR( DAGetCoordinateDA(self.da, &cda.da) )
        PetscIncref(<PetscObject>cda.da)
        return cda

    def getGhostCoordinates(self):
        cdef Vec gc = Vec()
        CHKERR( DAGetGhostedCoordinates(self.da, &gc.vec) )
        PetscIncref(<PetscObject>gc.vec)
        return gc

    #

    def createNaturalVector(self):
        cdef Vec vn = Vec()
        CHKERR( DACreateNaturalVector(self.da, &vn.vec) )
        return vn

    def createGlobalVector(self):
        cdef Vec vg = Vec()
        CHKERR( DACreateGlobalVector(self.da, &vg.vec) )
        return vg

    def createLocalVector(self):
        cdef Vec vl = Vec()
        CHKERR( DACreateLocalVector(self.da, &vl.vec) )
        return vl

    def createMatrix(self, mat_type=None):
        cdef PetscMatType mtype = MATAIJ
        mat_type = str2bytes(mat_type, &mtype)
        if mtype == NULL: mtype = MATAIJ
        cdef Mat mat = Mat()
        CHKERR( DAGetMatrix(self.da, mtype, &mat.mat) )
        return mat

    getMatrix = createMatrix

    #

    def globalToNatural(self, Vec vg not None, Vec vn not None, addv=None):
        cdef PetscInsertMode im = insertmode(addv)
        CHKERR( DAGlobalToNaturalBegin(self.da, vg.vec, im, vn.vec) )
        CHKERR( DAGlobalToNaturalEnd  (self.da, vg.vec, im, vn.vec) )

    def naturalToGlobal(self, Vec vn not None, Vec vg not None, addv=None):
        cdef PetscInsertMode im = insertmode(addv)
        CHKERR( DANaturalToGlobalBegin(self.da, vn.vec, im, vg.vec) )
        CHKERR( DANaturalToGlobalEnd  (self.da, vn.vec, im, vg.vec) )

    def globalToLocal(self, Vec vg not None, Vec vl not None, addv=None):
        cdef PetscInsertMode im = insertmode(addv)
        CHKERR( DAGlobalToLocalBegin(self.da, vg.vec, im, vl.vec) )
        CHKERR( DAGlobalToLocalEnd  (self.da, vg.vec, im, vl.vec) )

    def localToGlobalAdd(self, Vec vl not None, Vec vg not None):
        CHKERR( DALocalToGlobalBegin(self.da, vl.vec, vg.vec) )
        CHKERR( DALocalToGlobalEnd  (self.da, vl.vec, vg.vec) )

    def localToGlobal(self, Vec vl not None, Vec vg not None, addv=None):
        cdef PetscInsertMode im = insertmode(addv)
        CHKERR( DALocalToGlobal(self.da, vl.vec, im, vg.vec) )

    def localToLocal(self, Vec vl not None, Vec vlg not None, addv=None):
        cdef PetscInsertMode im = insertmode(addv)
        CHKERR( DALocalToLocalBegin(self.da, vl.vec, im, vlg.vec) )
        CHKERR( DALocalToLocalEnd  (self.da, vl.vec, im, vlg.vec) )

    #

    def getAO(self):
        cdef AO ao = AO()
        CHKERR( DAGetAO(self.da, &ao.ao) )
        PetscIncref(<PetscObject>ao.ao)
        return ao

    def getLGMap(self):
        cdef LGMap lgm = LGMap()
        CHKERR( DAGetISLocalToGlobalMapping(self.da, &lgm.lgm) )
        PetscIncref(<PetscObject>lgm.lgm)
        return lgm

    def getLGMapBlock(self):
        cdef LGMap lgm = LGMap()
        CHKERR( DAGetISLocalToGlobalMappingBlck(self.da, &lgm.lgm) )
        PetscIncref(<PetscObject>lgm.lgm)
        return lgm

    def getScatter(self):
        cdef Scatter l2g = Scatter()
        cdef Scatter g2l = Scatter()
        cdef Scatter l2l = Scatter()
        CHKERR( DAGetScatter(self.da, &l2g.sct, &g2l.sct, &l2l.sct) )
        PetscIncref(<PetscObject>l2g.sct)
        PetscIncref(<PetscObject>g2l.sct)
        PetscIncref(<PetscObject>l2l.sct)
        return (l2g, g2l, l2l)

    #

    property dim:
        def __get__(self):
            return self.getDim()

    property dof:
        def __get__(self):
            return self.getDof()

    property sizes:
        def __get__(self):
            return self.getSizes()

    property proc_sizes:
        def __get__(self):
            return self.getProcSizes()

    property periodic_type:
        def __get__(self):
            return self.getPeriodicType()

    property stencil_type:
        def __get__(self):
            return self.getStencilType()

    property stencil_width:
        def __get__(self):
            return self.getStencilWidth()

    #

    property ranges:
        def __get__(self):
            return self.getRanges()

    property ghost_ranges:
        def __get__(self):
            return self.getGhostRanges()

    property corners:
        def __get__(self):
            return self.getCorners()

    property ghost_corners:
        def __get__(self):
            return self.getGhostCorners()

# --------------------------------------------------------------------

del DAPeriodicType
del DAStencilType
del DAInterpolationType
del DAElementType

# --------------------------------------------------------------------
