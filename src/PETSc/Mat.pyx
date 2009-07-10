# --------------------------------------------------------------------

class MatType(object):
    SAME            = MATSAME
    SEQMAIJ         = MATSEQMAIJ
    MPIMAIJ         = MATMPIMAIJ
    MAIJ            = MATMAIJ
    IS              = MATIS
    MPIROWBS        = MATMPIROWBS
    SEQAIJ          = MATSEQAIJ
    MPIAIJ          = MATMPIAIJ
    AIJ             = MATAIJ
    SHELL           = MATSHELL
    SEQDENSE        = MATSEQDENSE
    MPIDENSE        = MATMPIDENSE
    DENSE           = MATDENSE
    SEQBAIJ         = MATSEQBAIJ
    MPIBAIJ         = MATMPIBAIJ
    BAIJ            = MATBAIJ
    MPIADJ          = MATMPIADJ
    SEQSBAIJ        = MATSEQSBAIJ
    MPISBAIJ        = MATMPISBAIJ
    SBAIJ           = MATSBAIJ
    DAAD            = MATDAAD
    MFFD            = MATMFFD
    NORMAL          = MATNORMAL
    LRC             = MATLRC
    SEQCSRPERM      = MATSEQCSRPERM
    MPICSRPERM      = MATMPICSRPERM
    CSRPERM         = MATCSRPERM
    SEQCRL          = MATSEQCRL
    MPICRL          = MATMPICRL
    CRL             = MATCRL
    SCATTER         = MATSCATTER
    BLOCKMAT        = MATBLOCKMAT
    COMPOSITE       = MATCOMPOSITE
    SEQFFTW         = MATSEQFFTW
    #
    PYTHON = MATPYTHON

class MatOption(object):
    ROW_ORIENTED               = MAT_ROW_ORIENTED
    NEW_NONZERO_LOCATIONS      = MAT_NEW_NONZERO_LOCATIONS
    SYMMETRIC                  = MAT_SYMMETRIC
    STRUCTURALLY_SYMMETRIC     = MAT_STRUCTURALLY_SYMMETRIC
    NEW_DIAGONALS              = MAT_NEW_DIAGONALS
    IGNORE_OFF_PROC_ENTRIES    = MAT_IGNORE_OFF_PROC_ENTRIES
    NEW_NONZERO_LOCATION_ERR   = MAT_NEW_NONZERO_LOCATION_ERR
    NEW_NONZERO_ALLOCATION_ERR = MAT_NEW_NONZERO_ALLOCATION_ERR
    USE_HASH_TABLE             = MAT_USE_HASH_TABLE
    KEEP_NONZERO_PATTERN       = MAT_KEEP_NONZERO_PATTERN
    IGNORE_ZERO_ENTRIES        = MAT_IGNORE_ZERO_ENTRIES
    USE_INODES                 = MAT_USE_INODES
    HERMITIAN                  = MAT_HERMITIAN
    SYMMETRY_ETERNAL           = MAT_SYMMETRY_ETERNAL
    USE_COMPRESSEDROW          = MAT_USE_COMPRESSEDROW
    IGNORE_LOWER_TRIANGULAR    = MAT_IGNORE_LOWER_TRIANGULAR
    ERROR_LOWER_TRIANGULAR     = MAT_ERROR_LOWER_TRIANGULAR
    GETROW_UPPERTRIANGULAR     = MAT_GETROW_UPPERTRIANGULAR

class MatAssemblyType(object):
    # native
    FINAL_ASSEMBLY = MAT_FINAL_ASSEMBLY
    FLUSH_ASSEMBLY = MAT_FLUSH_ASSEMBLY
    # aliases
    FINAL = FINAL_ASSEMBLY
    FLUSH = FLUSH_ASSEMBLY

class MatStructure(object):
    # native
    SAME_NONZERO_PATTERN      = MAT_SAME_NONZERO_PATTERN
    DIFFERENT_NONZERO_PATTERN = MAT_DIFFERENT_NONZERO_PATTERN
    SUBSET_NONZERO_PATTERN    = MAT_SUBSET_NONZERO_PATTERN
    SAME_PRECONDITIONER       = MAT_SAME_PRECONDITIONER
    # aliases
    SAME      = SAME_NZ      = SAME_NONZERO_PATTERN
    SUBSET    = SUBSET_NZ    = SUBSET_NONZERO_PATTERN
    DIFFERENT = DIFFERENT_NZ = DIFFERENT_NONZERO_PATTERN
    SAMEPC    = SAME_PC      = SAME_PRECONDITIONER

class MatOrderingType(object):
    NATURAL     = MAT_ORDERING_NATURAL
    ND          = MAT_ORDERING_ND
    OWD         = MAT_ORDERING_1WD
    RCM         = MAT_ORDERING_RCM
    QMD         = MAT_ORDERING_QMD
    ROWLENGTH   = MAT_ORDERING_ROWLENGTH
    DSC_ND      = MAT_ORDERING_DSC_ND
    DSC_MMD     = MAT_ORDERING_DSC_MMD
    DSC_MDF     = MAT_ORDERING_DSC_MDF
    CONSTRAINED = MAT_ORDERING_CONSTRAINED
    IDENTITY    = MAT_ORDERING_IDENTITY
    REVERSE     = MAT_ORDERING_REVERSE

# --------------------------------------------------------------------

cdef class Mat(Object):

    Type         = MatType
    Option       = MatOption
    AssemblyType = MatAssemblyType
    Structure    = MatStructure
    OrderingType = MatOrderingType

    #

    def __cinit__(self):
        self.obj  = <PetscObject*> &self.mat
        self.mat = NULL

    # unary operations

    def __pos__(self):
        return mat_pos(self)

    def __neg__(self):
        return mat_neg(self)

    # inplace binary operations

    def __iadd__(self, other):
        return mat_iadd(self, other)

    def __isub__(self, other):
        return mat_isub(self, other)

    def __imul__(self, other):
        return mat_imul(self, other)

    def __idiv__(self, other):
        return mat_idiv(self, other)

    # binary operations

    def __add__(self, other):
        if isinstance(self, Mat):
            return mat_add(self, other)
        else:
            return mat_radd(other, self)

    def __sub__(self, other):
        if isinstance(self, Mat):
            return mat_sub(self, other)
        else:
            return mat_rsub(other, self)

    def __mul__(self, other):
        if isinstance(self, Mat):
            if isinstance(other, Vec):
                return mat_mul_vec(self, other)
            else:
                return mat_mul(self, other)
        else:
            return mat_rmul(other, self)

    def __div__(self, other):
        if isinstance(self, Mat):
            return mat_div(self, other)
        else:
            return mat_rdiv(other, self)

    #

    def __getitem__(self, ij):
        return mat_getitem(self, ij)

    def __setitem__(self, ij, v):
        mat_setitem(self, ij, v)

    def __call__(self, x, y=None):
        if y is None:
            y = self.getVecLeft()
        self.mult(x, y)
        return y
    #

    def view(self, Viewer viewer=None):
        cdef PetscViewer vwr = NULL
        if viewer is not None: vwr = viewer.vwr
        CHKERR( MatView(self.mat, vwr) )

    def destroy(self):
        CHKERR( MatDestroy(self.mat) )
        self.mat = NULL
        return self

    def create(self, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscMat newmat = NULL
        CHKERR( MatCreate(ccomm, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        return self

    def setSizes(self, size, bsize=None):
        cdef MPI_Comm ccomm = MPI_COMM_NULL
        CHKERR( PetscObjectGetComm(<PetscObject>self.mat, &ccomm) )
        cdef PetscInt bs=0, m=0, n=0, M=0, N=0
        CHKERR( Mat_SplitSizes(ccomm, size, bsize, &bs, &m, &n, &M, &N) )
        CHKERR( MatSetSizes(self.mat, m, n, M, N) )

    def setType(self, mat_type):
        CHKERR( MatSetType(self.mat, str2cp(mat_type)) )

    #

    def createAIJ(self, size, bsize=None, nnz=None, csr=None, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscInt bs=0, m=0, n=0, M=0, N=0
        CHKERR( Mat_SplitSizes(ccomm, size, bsize, &bs, &m, &n, &M, &N) )
        # create matrix
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateAnyAIJ(ccomm, bs, m, n, M, N, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        # preallocate matrix
        if csr is not None:   # with CSR preallocation
            CHKERR( Mat_AllocAIJ_CSR(self.mat, bs, csr) )
        elif nnz is not None: # with NNZ preallocation
            CHKERR( Mat_AllocAIJ_NNZ(self.mat, bs, nnz) )
        else:                 # default preallocation
            CHKERR( Mat_AllocAIJ_DEFAULT(self.mat, bs) )
        return self

    def setPreallocationNNZ(self, nnz, bsize=None):
        cdef PetscInt bs = PETSC_DECIDE
        CHKERR( Mat_BlockSize(bsize, &bs) )
        if nnz is not None:
            CHKERR( Mat_AllocAIJ_NNZ(self.mat, bs, nnz) )
        else:
            CHKERR( Mat_AllocAIJ_DEFAULT(self.mat, bs) )

    def setPreallocationCSR(self, csr, bsize=None):
        cdef PetscInt bs = PETSC_DECIDE
        CHKERR( Mat_BlockSize(bsize, &bs) )
        if csr is not None:
            CHKERR( Mat_AllocAIJ_CSR(self.mat, bs, csr) )
        else:
            CHKERR( Mat_AllocAIJ_DEFAULT(self.mat, bs) )
    #

    def createDense(self, size, bsize=None, array=None, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscInt bs=0, m=0, n=0, M=0, N=0
        CHKERR( Mat_SplitSizes(ccomm, size, bsize, &bs, &m, &n, &M, &N) )
        # create matrix
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateAnyDense(ccomm, bs, m, n, M, N, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        # preallocate matrix
        if array is not None:
            CHKERR( Mat_AllocDense_ARRAY(self.mat, bs, array) )
        else:
            CHKERR( Mat_AllocDense_DEFAULT(self.mat, bs) )
        return self

    def setPreallocationDense(self, array, bsize=None):
        cdef PetscInt bs = PETSC_DECIDE
        CHKERR( Mat_BlockSize(bsize, &bs) )
        if array is not None:
            CHKERR( Mat_AllocDense_ARRAY(self.mat, bs, array) )
        else:
            CHKERR( Mat_AllocDense_DEFAULT(self.mat, bs) )

    #

    def createIS(self, size, LGMap lgmap, comm=None):
        if comm is None: comm = lgmap.getComm()
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscInt bs=0, m=0, n=0, M=0, N=0
        CHKERR( Mat_SplitSizes(ccomm, size, None, &bs, &m, &n, &M, &N) )
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateIS(ccomm, m, n, M, N, lgmap.lgm, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        return self

    def createScatter(self, Scatter scatter, comm=None):
        if comm is None: comm = scatter.getComm()
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateScatter(ccomm, scatter.sct, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        return self

    def createNormal(self, Mat mat not None):
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateNormal(mat.mat, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        return self

    def createLRC(self, Mat A not None, Mat U not None, Mat V not None):
        cdef PetscMat newmat = NULL
        CHKERR( MatCreateLRC(A.mat, U.mat, V.mat, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        return self

    ## def createShell(self, size, context, comm=None):
    ##     raise NotImplementedError
    ##     cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
    ##     cdef PetscInt bs=0, m=0, n=0, M=0, N=0
    ##     CHKERR( Mat_SplitSizes(ccomm, size, None, &bs, &m, &n, &M, &N) )
    ##     cdef PetscMat newmat = NULL
    ##     CHKERR( MatCreateShell(ccomm, m, n, M, N, NULL, &newmat) )
    ##     PetscCLEAR(self.obj); self.mat = newmat
    ##     return self

    #

    def createPython(self, size, context=None, comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscInt bs=0, m=0, n=0, M=0, N=0
        CHKERR( Mat_SplitSizes(ccomm, size, None, &bs, &m, &n, &M, &N) )
        cdef PetscMat newmat = NULL
        CHKERR( MatCreate(ccomm, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat
        CHKERR( MatSetSizes(self.mat, m, n, M, N) )
        CHKERR( MatSetType(self.mat, MATPYTHON) )
        CHKERR( MatPythonSetContext(self.mat, <void*>context) )
        return self

    def setPythonContext(self, context):
        CHKERR( MatPythonSetContext(self.mat, <void*>context) )

    def getPythonContext(self):
        cdef void *context = NULL
        CHKERR( MatPythonGetContext(self.mat, &context) )
        if context == NULL: return None
        else: return <object> context

    def setPythonType(self, py_type):
        CHKERR( MatPythonSetType(self.mat, str2cp(py_type)) )

    #

    def setOptionsPrefix(self, prefix):
        CHKERR( MatSetOptionsPrefix(self.mat, str2cp(prefix)) )

    def getOptionsPrefix(self):
        cdef const_char_p prefix = NULL
        CHKERR( MatGetOptionsPrefix(self.mat, &prefix) )
        return cp2str(prefix)

    def setFromOptions(self):
        CHKERR( MatSetFromOptions(self.mat) )

    def setUp(self):
        CHKERR( MatSetUp(self.mat) )
        return self

    def setOption(self, option, flag):
        CHKERR( MatSetOption(self.mat, option, flag) )

    def getType(self):
        cdef PetscMatType mat_type = NULL
        CHKERR( MatGetType(self.mat, &mat_type) )
        return cp2str(mat_type)

    def getSize(self):
        cdef PetscInt M=0,N=0
        CHKERR( MatGetSize(self.mat, &M, &N) )
        return (M, N)

    def getLocalSize(self):
        cdef PetscInt m=0,n=0
        CHKERR( MatGetLocalSize(self.mat, &m, &n) )
        return (m, n)

    def getSizes(self):
        cdef PetscInt m=0,n=0
        cdef PetscInt M=0,N=0
        CHKERR( MatGetLocalSize(self.mat, &m, &n) )
        CHKERR( MatGetSize(self.mat, &M, &N) )
        return ((m, n), (M, N))

    def setBlockSize(self, bsize):
        cdef PetscInt bs = bsize
        CHKERR( MatSetBlockSize(self.mat, bs) )

    def getBlockSize(self):
        cdef PetscInt bs=0
        CHKERR( MatGetBlockSize(self.mat, &bs) )
        return bs

    def getOwnershipRange(self):
        cdef PetscInt rlow=0, rhigh=0
        CHKERR( MatGetOwnershipRange(self.mat, &rlow, &rhigh) )
        return (rlow, rhigh)

    def getOwnershipRanges(self):
        cdef const_PetscInt *rowrng = NULL
        CHKERR( MatGetOwnershipRanges(self.mat, &rowrng) )
        cdef MPI_Comm comm = MPI_COMM_NULL
        CHKERR( PetscObjectGetComm(<PetscObject>self.mat, &comm) )
        cdef int size = -1
        CHKERR( MPI_Comm_size(comm, &size) )
        return array_i(size+1, rowrng)

    def getOwnershipRangeColumn(self):
        cdef PetscInt clow=0, chigh=0
        CHKERR( MatGetOwnershipRangeColumn(self.mat, &clow, &chigh) )
        return (clow, chigh)

    def getOwnershipRangesColumn(self):
        cdef const_PetscInt *colrng = NULL
        CHKERR( MatGetOwnershipRangesColumn(self.mat, &colrng) )
        cdef MPI_Comm comm = MPI_COMM_NULL
        CHKERR( PetscObjectGetComm(<PetscObject>self.mat, &comm) )
        cdef int size = -1
        CHKERR( MPI_Comm_size(comm, &size) )
        return array_i(size+1, colrng)

    def duplicate(self, copy=False):
        cdef PetscMatDuplicateOption flag = MAT_DO_NOT_COPY_VALUES
        if copy: flag = MAT_COPY_VALUES
        cdef Mat mat = type(self)()
        CHKERR( MatDuplicate(self.mat, flag, &mat.mat) )
        return mat

    def copy(self, Mat result=None, structure=None):
        if result is None: return self.duplicate(True)
        cdef PetscMatStructure flag = matstructure(structure)
        CHKERR( MatCopy(self.mat, result.mat, flag) )
        return result

    def equal(self, Mat mat not None):
        cdef PetscTruth flag = PETSC_FALSE
        CHKERR( MatEqual(self.mat, mat.mat, &flag) )
        return <bint> mat

    def load(self, Viewer viewer not None, mat_type=None):
        cdef PetscMat newmat = NULL
        cdef PetscMatType mtype = NULL
        if mat_type is not None: mtype = str2cp(mat_type)
        CHKERR( MatLoad(viewer.vwr, mtype, &newmat) )
        PetscCLEAR(self.obj); self.mat = newmat

    def convert(self, mat_type=None, Mat out=None):
        cdef PetscMatType mtype = MATSAME
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        if mat_type is not None: mtype = str2cp(mat_type)
        if out is None: out = self
        if out.mat != NULL: reuse = MAT_REUSE_MATRIX
        CHKERR( MatConvert(self.mat, mtype, reuse, &out.mat) )
        return out

    def transpose(self, Mat out=None):
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        if out is None: out = self
        if out.mat != NULL: reuse = MAT_REUSE_MATRIX
        CHKERR( MatTranspose(self.mat, reuse, &out.mat) )
        return out

    def conjugate(self, Mat out=None):
        if out is None:
            out = self
        elif out.mat == NULL:
            CHKERR( MatDuplicate(self.mat, MAT_COPY_VALUES, &out.mat) )
        CHKERR( MatConjugate(out.mat) )
        return out

    def permute(self, IS row not None, IS col not None):
        cdef Mat mat = Mat()
        CHKERR( MatPermute(self.mat, row.iset, col.iset, &mat.mat) )
        return mat

    def isTranspose(self, Mat mat=None, tol=0):
        if mat is None: mat = self
        cdef PetscReal rval = asReal(tol)
        cdef PetscTruth flag = PETSC_FALSE
        CHKERR( MatIsTranspose(self.mat, mat.mat, rval, &flag) )
        return <bint>flag

    def isSymmetric(self, tol=0):
        cdef PetscReal rval = asReal(tol)
        cdef PetscTruth flag = PETSC_FALSE
        CHKERR( MatIsSymmetric(self.mat, rval, &flag) )
        return <bint>flag

    def isSymmetricKnown(self):
        cdef PetscTruth flag1 = PETSC_FALSE
        cdef PetscTruth flag2 = PETSC_FALSE
        CHKERR( MatIsSymmetricKnown(self.mat, &flag1, &flag2) )
        return (<bint>flag1, <bint>flag2)

    def isHermitian(self, tol=0):
        cdef PetscReal rval = asReal(tol)
        cdef PetscTruth flag = PETSC_FALSE
        CHKERR( MatIsHermitian(self.mat, rval, &flag) )
        return <bint>flag

    def isHermitianKnown(self):
        cdef PetscTruth flag1 = PETSC_FALSE
        cdef PetscTruth flag2 = PETSC_FALSE
        rslt = CHKERR( MatIsHermitianKnown(self.mat, &flag1, &flag2) )
        return (<bint>flag1, <bint>flag2)

    def isStructurallySymmetric(self):
        cdef PetscTruth flag = PETSC_FALSE
        CHKERR( MatIsStructurallySymmetric(self.mat, &flag) )
        return <bint>flag

    def zeroEntries(self):
        CHKERR( MatZeroEntries(self.mat) )

    def getValue(self, row, col):
        cdef PetscInt irow = row
        cdef PetscInt icol = col
        cdef PetscScalar sval = 0
        CHKERR( MatGetValues(self.mat, 1, &irow, 1, &icol, &sval) )
        return toScalar(sval)

    def getValues(self, rows, cols, values=None):
        return matgetvalues(self.mat, rows, cols, values)

    def getRow(self, row):
        cdef PetscInt irow = row
        cdef PetscInt ncols=0
        cdef const_PetscInt *icols=NULL
        cdef const_PetscScalar *svals=NULL
        CHKERR( MatGetRow(self.mat, irow, &ncols, &icols, &svals) )
        cdef object cols = array_i(ncols, icols)
        cdef object vals = array_s(ncols, svals)
        CHKERR( MatRestoreRow(self.mat, irow, &ncols, &icols, &svals) )
        return (cols, vals)

    def getRowIJ(self, symmetric=False, compressed=False):
        cdef PetscInt shift=0
        cdef PetscTruth symm=symmetric
        cdef PetscTruth bcmp=compressed
        cdef PetscInt n=0, *ia=NULL, *ja=NULL
        cdef PetscTruth done=PETSC_FALSE
        CHKERR( MatGetRowIJ(self.mat, shift, symm, bcmp, &n, &ia, &ja, &done) )
        cdef object ai=None, aj=None
        if done != PETSC_FALSE: ai = array_i(  n+1, ia)
        if done != PETSC_FALSE: aj = array_i(ia[n], ja)
        CHKERR( MatRestoreRowIJ(self.mat, shift, symm, bcmp, &n, &ia, &ja, &done) )
        return (ai, aj)

    def getColumnIJ(self, symmetric=False, compressed=False):
        cdef PetscInt shift=0
        cdef PetscTruth symm=symmetric, bcmp=compressed
        cdef PetscInt n=0, *ia=NULL, *ja=NULL
        cdef PetscTruth done=PETSC_FALSE
        CHKERR( MatGetColumnIJ(self.mat, shift, symm, bcmp, &n, &ia, &ja, &done) )
        cdef object ai=None, aj=None
        if done != PETSC_FALSE: ai = array_i(  n+1, ia)
        if done != PETSC_FALSE: aj = array_i(ia[n], ja)
        CHKERR( MatRestoreColumnIJ(self.mat, shift, symm, bcmp, &n, &ia, &ja, &done) )
        return (ai, aj)

    def setValue(self, row, col, value, addv=None):
        cdef PetscInt irow = row
        cdef PetscInt icol = col
        cdef PetscScalar sval = asScalar(value)
        cdef PetscInsertMode caddv = insertmode(addv)
        CHKERR( MatSetValues(self.mat, 1, &irow, 1, &icol, &sval, caddv) )

    def setValues(self, rows, cols, values, addv=None):
        matsetvalues(self.mat, rows, cols, values, addv, 0, 0)

    def setValuesRCV(self, R, C, V, addv=None):
        matsetvalues_rcv(self.mat, R, C, V, addv, 0, 0)

    def setValuesIJV(self, I, J, V, addv=None, rowmap=None):
        matsetvalues_ijv(self.mat, I, J, V, addv, rowmap, 0, 0)

    def setValuesCSR(self, I, J, V, addv=None):
        matsetvalues_csr(self.mat, I, J, V, addv, 0, 0)

    def setValuesBlocked(self, rows, cols, values, addv=None):
        matsetvalues(self.mat, rows, cols, values, addv, 1, 0)

    def setValuesBlockedRCV(self, R, C, V, addv=None):
        matsetvalues_rcv(self.mat, R, C, V, addv, 1, 0)

    def setValuesBlockedIJV(self, I, J, V, addv=None, rowmap=None):
        matsetvalues_ijv(self.mat, I, J, V, addv, rowmap, 1, 0)

    def setValuesBlockedCSR(self, I, J, V, addv=None):
        matsetvalues_csr(self.mat, I, J, V, addv, 1, 0)

    def setLGMap(self, LGMap lgmap not None):
        CHKERR( MatSetLocalToGlobalMapping(self.mat, lgmap.lgm) )

    def setValueLocal(self, row, col, value, addv=None):
        cdef PetscInt    irow = row
        cdef PetscInt    icol = col
        cdef PetscScalar sval = asScalar(value)
        cdef PetscInsertMode caddv = insertmode(addv)
        CHKERR( MatSetValuesLocal(self.mat, 1, &irow, 1, &icol, &sval, caddv) )

    def setValuesLocal(self, rows, cols, values, addv=None):
        matsetvalues(self.mat, rows, cols, values, addv, 0, 1)

    def setValuesLocalRCV(self, R, C, V, addv=None):
        matsetvalues_rcv(self.mat, R, C, V, addv, 0, 1)

    def setValuesLocalIJV(self, I, J, V, addv=None, rowmap=None):
        matsetvalues_ijv(self.mat, I, J, V, addv, rowmap, 0, 1)

    def setValuesLocalCSR(self, I, J, V, addv=None):
        matsetvalues_csr(self.mat, I, J, V, addv, 0, 1)

    def setLGMapBlock(self, LGMap lgmap not None):
        CHKERR( MatSetLocalToGlobalMappingBlock(self.mat, lgmap.lgm) )

    def setValuesBlockedLocal(self, rows, cols, values, addv=None):
        matsetvalues(self.mat, rows, cols, values, addv, 1, 1)

    def setValuesBlockedLocalRCV(self, R, C, V, addv=None):
        matsetvalues_rcv(self.mat, R, C, V, addv, 1, 1)

    def setValuesBlockedLocalIJV(self, I, J, V, addv=None, rowmap=None):
        matsetvalues_ijv(self.mat, I, J, V, addv, rowmap, 1, 1)

    def setValuesBlockedLocalCSR(self, I, J, V, addv=None):
        matsetvalues_csr(self.mat, I, J, V, addv, 1, 1)

    def zeroRows(self, rows, diag=1):
        cdef PetscScalar sval = asScalar(diag)
        cdef PetscInt ni=0, *i=NULL
        if isinstance(rows, IS):
            CHKERR( MatZeroRowsIS(self.mat, (<IS>rows).iset, sval) )
        else:
            rows = iarray_i(rows, &ni, &i)
            CHKERR( MatZeroRows(self.mat, ni, i, sval) )

    def zeroRowsLocal(self, rows, diag=1):
        cdef PetscInt ni=0, *i=NULL
        cdef PetscScalar sval = asScalar(diag)
        if isinstance(rows, IS):
            CHKERR( MatZeroRowsLocalIS(self.mat, (<IS>rows).iset, sval) )
        else:
            rows = iarray_i(rows, &ni, &i)
            CHKERR( MatZeroRowsLocal(self.mat, ni, i, sval) )

    def storeValues(self):
        CHKERR( MatStoreValues(self.mat) )

    def retrieveValues(self):
        CHKERR( MatRetrieveValues(self.mat) )

    def assemblyBegin(self, assembly=None):
        cdef PetscMatAssemblyType flag = assemblytype(assembly)
        CHKERR( MatAssemblyBegin(self.mat, flag) )

    def assemblyEnd(self, assembly=None):
        cdef PetscMatAssemblyType flag = assemblytype(assembly)
        CHKERR( MatAssemblyEnd(self.mat, flag) )

    def assemble(self, assembly=None):
        cdef PetscMatAssemblyType flag = assemblytype(assembly)
        CHKERR( MatAssemblyBegin(self.mat, flag) )
        CHKERR( MatAssemblyEnd(self.mat, flag) )

    def isAssembled(self):
        cdef PetscTruth assembled
        CHKERR( MatAssembled(self.mat, &assembled) )
        return <bint> assembled

    def getVecs(self, side=None):
        cdef Vec vecr, vecl
        if side is None:
            vecr = Vec(); vecl = Vec();
            CHKERR( MatGetVecs(self.mat, &vecr.vec, &vecl.vec) )
            return (vecr, vecl)
        elif side in ('r', 'R', 'right', 'Right', 'RIGHT'):
            vecr = Vec()
            CHKERR( MatGetVecs(self.mat, &vecr.vec, NULL) )
            return vecr
        elif side in ('l', 'L', 'left',  'Left', 'LEFT'):
            vecl = Vec()
            CHKERR( MatGetVecs(self.mat, NULL, &vecl.vec) )
            return vecl
        else:
            raise ValueError("side '%r' not understood" % side)

    def getVecRight(self):
        cdef Vec vecr = Vec()
        CHKERR( MatGetVecs(self.mat, &vecr.vec, NULL) )
        return vecr

    def getVecLeft(self):
        cdef Vec vecl = Vec()
        CHKERR( MatGetVecs(self.mat, NULL, &vecl.vec) )
        return vecl

    #

    def getColumnVector(self, column, Vec result=None):
        cdef PetscInt col = column
        if result is None:
            result = Vec()
        if result.vec == NULL:
            CHKERR( MatGetVecs(self.mat, NULL, &result.vec) )
        CHKERR( MatGetColumnVector(self.mat, result.vec, col) )
        return result

    def getDiagonal(self, Vec result=None):
        if result is None:
            result = Vec()
        if result.vec == NULL:
            CHKERR( MatGetVecs(self.mat, NULL, &result.vec) )
        CHKERR( MatGetDiagonal(self.mat, result.vec) )
        return result

    def setDiagonal(self, Vec diag not None, addv=None):
        cdef PetscInsertMode caddv = insertmode(addv)
        CHKERR( MatDiagonalSet(self.mat, diag.vec, caddv) )

    def diagonalScale(self, Vec L=None, Vec R=None):
        cdef PetscVec vecl=NULL, vecr=NULL
        if L is not None: vecl = L.vec
        if R is not None: vecr = R.vec
        CHKERR( MatDiagonalScale(self.mat, vecl, vecr) )

    # matrix-vector product

    def setNullSpace(self, NullSpace nsp not None):
        CHKERR( MatNullSpaceAttach(self.mat, nsp.nsp) )

    def mult(self, Vec x not None, Vec y not None):
        CHKERR( MatMult(self.mat, x.vec, y.vec) )

    def multAdd(self, Vec x not None, Vec v not None, Vec y not None):
        CHKERR( MatMultAdd(self.mat, x.vec, v.vec, y.vec) )

    def multTranspose(self, Vec x not None, Vec y not None):
        CHKERR( MatMultTranspose(self.mat, x.vec, y.vec) )

    def multTransposeAdd(self, Vec x not None, Vec v not None, Vec y not None):
        CHKERR( MatMultTransposeAdd(self.mat, x.vec, v.vec, y.vec) )

    #

    def getDiagonalBlock(self):
        cdef PetscTruth iscopy = PETSC_FALSE
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        cdef Mat mat = Mat()
        CHKERR( MatGetDiagonalBlock(self.mat, &iscopy, reuse, &mat.mat) )
        if iscopy == PETSC_FALSE: PetscIncref(<PetscObject>mat.mat)
        return mat

    def getSubMatrix(self, IS isrow not None, IS iscol=None, Mat submat=None):
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        cdef PetscIS ciscol = NULL
        if iscol is not None: ciscol = iscol.iset
        if submat is None: submat = Mat()
        if submat.mat != NULL: reuse = MAT_REUSE_MATRIX
        CHKERR( MatGetSubMatrix(self.mat, isrow.iset, ciscol,
                                reuse, &submat.mat) )
        return submat

    def increaseOverlap(self, IS iset not None, overlap=1):
        CHKERR( MatIncreaseOverlap(self.mat, 1, &iset.iset, overlap) )

    #

    def norm(self, norm_type=None):
        cdef PetscNormType norm_1_2 = PETSC_NORM_1_AND_2
        cdef PetscNormType ntype = PETSC_NORM_FROBENIUS
        if norm_type is not None: ntype = norm_type
        cdef PetscReal rval[2]
        CHKERR( MatNorm(self.mat, ntype, rval) )
        if ntype != norm_1_2: return toReal(rval[0])
        else: return (toReal(rval[0]), toReal(rval[1]))

    def scale(self, alpha):
        cdef PetscScalar sval = asScalar(alpha)
        CHKERR( MatScale(self.mat, sval) )

    def shift(self, alpha):
        cdef PetscScalar sval = asScalar(alpha)
        CHKERR( MatShift(self.mat, sval) )

    def axpy(self, alpha, Mat X not None, structure=None):
        cdef PetscScalar sval = asScalar(alpha)
        cdef PetscMatStructure flag = matstructure(structure)
        CHKERR( MatAXPY(self.mat, sval, X.mat, flag) )

    def aypx(self, alpha, Mat X not None, structure=None):
        cdef PetscScalar sval = asScalar(alpha)
        cdef PetscMatStructure flag = matstructure(structure)
        CHKERR( MatAYPX(self.mat, sval, X.mat, flag) )

    # matrix-matrix product

    def matMultSymbolic(self, Mat mat not None, fill=None):
        cdef Mat result = Mat()
        cdef PetscReal rval = 2
        if fill is not None: rval = asReal(fill)
        CHKERR( MatMatMultSymbolic(self.mat, mat.mat, rval, &result.mat) )
        return result

    def matMultNumeric(self, Mat mat not None, Mat result=None):
        if result is None:
            result = Mat()
        if result.mat == NULL:
            CHKERR( MatMatMultSymbolic(self.mat, mat.mat, 2.0, &result.mat) )
        CHKERR( MatMatMultNumeric(self.mat, mat.mat, result.mat) )
        return result

    def matMult(self, Mat mat not None, Mat result=None, fill=None):
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        cdef PetscReal rval = 2
        if result is None:
            result = Mat()
        elif result.mat != NULL:
            reuse = MAT_REUSE_MATRIX
        if fill is not None: rval = asReal(fill)
        CHKERR( MatMatMult(self.mat, mat.mat, reuse, rval, &result.mat) )
        return result

    def matMultTranspose(self, Mat mat not None, Mat result=None, fill=None):
        cdef PetscMatReuse reuse = MAT_INITIAL_MATRIX
        cdef PetscReal rval = 2
        if result is None:
            result = Mat()
        elif result.mat != NULL:
            reuse = MAT_REUSE_MATRIX
        if fill is not None: rval = asReal(fill)
        CHKERR( MatMatMultTranspose(self.mat, mat.mat, reuse, rval, &result.mat) )
        return result

    # XXX factorization

    def getOrdering(self, ord_type):
        cdef PetscMatOrderingType otype = str2cp(ord_type)
        cdef IS rp = IS(), cp = IS()
        CHKERR( MatGetOrdering(self.mat, otype, &rp.iset, &cp.iset) )
        return (rp, cp)

    def reorderForNonzeroDiagonal(self, IS isrow not None, IS iscol not None, atol=0):
        cdef PetscReal rval = asReal(atol)
        cdef PetscIS rp = isrow.iset, cp = iscol.iset
        CHKERR( MatReorderForNonzeroDiagonal(self.mat, rval, rp, cp) )

    def factorLU(self, IS isrow not None, IS iscol not None, options=None):
        cdef PetscMatFactorInfo info
        matfactorinfo(PETSC_FALSE, options, &info)
        CHKERR( MatLUFactor(self.mat, isrow.iset, iscol.iset, &info) )
    def factorSymbolicLU(self, Mat mat not None, IS isrow not None, IS iscol not None, options=None):
        raise NotImplementedError
    def factorNumericLU(self, Mat mat not None, options=None):
        raise NotImplementedError
    def factorILU(self, IS isrow not None, IS iscol not None, options=None):
        cdef PetscMatFactorInfo info
        matfactorinfo(PETSC_TRUE, options, &info)
        CHKERR( MatILUFactor(self.mat, isrow.iset, iscol.iset, &info) )
    def factorSymbolicILU(self, IS isrow not None, IS iscol not None, options=None):
        raise NotImplementedError

    def factorCholesky(self, IS isperm not None, options=None):
        cdef PetscMatFactorInfo info
        matfactorinfo(PETSC_FALSE, options, &info)
        CHKERR( MatCholeskyFactor(self.mat, isperm.iset, &info) )
    def factorSymbolicCholesky(self, IS isperm not None, options=None):
        raise NotImplementedError
    def factorNumericCholesky(self, Mat mat not None, options=None):
        raise NotImplementedError
    def factorICC(self, IS isperm not None, options=None):
        cdef PetscMatFactorInfo info
        matfactorinfo(PETSC_TRUE, options, &info)
        CHKERR( MatICCFactor(self.mat, isperm.iset, &info) )
    def factorSymbolicICC(self, IS isperm not None, options=None):
        raise NotImplementedError

    def factorILUDT(self, IS isrow not None, IS iscol not None, options=None):
        cdef PetscMatFactorInfo info
        matfactorinfo(PETSC_TRUE, options, &info)
        cdef Mat mat = Mat()
        CHKERR( MatILUDTFactor(self.mat, isrow.iset, iscol.iset, &info, &mat.mat) )
        return mat

    def getInertia(self):
        cdef PetscInt nneg=0, nzero=0, npos=0
        CHKERR( MatGetInertia(self.mat, &nneg, &nzero, &npos) )
        return (nneg, nzero, npos)

    def setUnfactored(self):
        CHKERR( MatSetUnfactored(self.mat) )

    # solve

    def solveForward(self, Vec b not None, Vec x not None):
        CHKERR( MatForwardSolve(self.mat, b.vec, x.vec) )

    def solveBackward(self, Vec b not None, Vec x not None):
        CHKERR( MatBackwardSolve(self.mat, b.vec, x.vec) )

    def solve(self, Vec b not None, Vec x not None):
        CHKERR( MatSolve(self.mat, b.vec, x.vec) )

    def solveTranspose(self, Vec b not None, Vec x not None):
        CHKERR( MatSolveTranspose(self.mat, b.vec, x.vec) )

    def solveAdd(self, Vec b not None, Vec y, Vec x not None):
        CHKERR( MatSolveAdd(self.mat, b.vec, y.vec, x.vec) )

    def solveTransposeAdd(self, Vec b not None, Vec y, Vec x not None):
        CHKERR( MatSolveTransposeAdd(self.mat, b.vec, y.vec, x.vec) )

    #

    property sizes:
        def __get__(self):
            return self.getSizes()
        def __set__(self, value):
            self.setSizes(value)

    property size:
        def __get__(self):
            return self.getSize()

    property local_size:
        def __get__(self):
            return self.getLocalSize()

    property block_size:
        def __get__(self):
            return self.getBlockSize()

    property owner_range:
        def __get__(self):
            return self.getOwnershipRange()

    property owner_ranges:
        def __get__(self):
            return self.getOwnershipRanges()

    #

    property assembled:
        def __get__(self):
            return self.isAssembled()
    property symmetric:
        def __get__(self):
            return self.isSymmetric()
    property hermitian:
        def __get__(self):
            return self.isHermitian()
    property structsymm:
        def __get__(self):
            return self.isStructurallySymmetric()

# --------------------------------------------------------------------

cdef class NullSpace(Object):

    #

    def __cinit__(self):
        self.obj  = <PetscObject*> &self.nsp
        self.nsp = NULL

    def __call__(self, vec, out=None):
        self.remove(vec, out)

    #

    def view(self, Viewer viewer=None):
        cdef PetscViewer vwr = NULL
        if viewer is not None: vwr = viewer.vwr
        return ## XXX I should do something here

    def destroy(self):
        CHKERR( MatNullSpaceDestroy(self.nsp) )
        self.nsp = NULL
        return self

    def create(self, constant=False, vectors=(),  comm=None):
        cdef MPI_Comm ccomm = def_Comm(comm, PETSC_COMM_DEFAULT)
        cdef PetscInt i = 0
        cdef PetscInt nv = 0
        cdef PetscVec *v = NULL
        cdef PetscNullSpace newnsp = NULL
        cdef PetscTruth has_const = PETSC_FALSE
        if constant: has_const = PETSC_TRUE
        nv = len(vectors)
        cdef object tmp = allocate(nv*sizeof(PetscVec),<void**>&v)
        for i from 0 <= i < nv:
            v[i] = (<Vec?>(vectors[i])).vec
        CHKERR( MatNullSpaceCreate(ccomm, has_const, nv, v, &newnsp) )
        PetscCLEAR(self.obj); self.nsp = newnsp
        return self

    def setFunction(self, function, *args, **kargs):
        if function is None: NullSpace_setFun(self.nsp, None)
        else: NullSpace_setFun(self.nsp, (function, args, kargs))

    def getFunction(self):
        return NullSpace_getFun(self.nsp)

    def remove(self, Vec vec not None, Vec out=None):
        cdef PetscVec v = NULL, *vp = NULL
        if out is not None: vp = &v
        CHKERR( MatNullSpaceRemove(self.nsp, vec.vec, vp) )
        if out is not None: CHKERR( VecCopy(v, out.vec) )

# --------------------------------------------------------------------

del MatType
del MatOption
del MatAssemblyType
del MatStructure
del MatOrderingType

# --------------------------------------------------------------------
