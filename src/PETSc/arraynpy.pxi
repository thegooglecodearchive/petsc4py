# --------------------------------------------------------------------

cdef extern from "numpy/arrayobject.h":

    int import_array "_import_array" () except -1

    ctypedef long npy_intp

    ctypedef extern class numpy.dtype [object PyArray_Descr]:
        pass

    ctypedef extern class numpy.ndarray [object PyArrayObject]:
        cdef char*     c_data  "data"
        cdef int       c_ndim  "nd"
        cdef npy_intp* c_shape "dimensions"

    void*     PyArray_DATA(ndarray)
    npy_intp  PyArray_SIZE(ndarray)
    int       PyArray_NDIM(ndarray)
    npy_intp* PyArray_DIMS(ndarray)
    npy_intp  PyArray_DIM(ndarray, int)

    enum: NPY_C_CONTIGUOUS
    enum: NPY_F_CONTIGUOUS
    enum: NPY_ALIGNED
    enum: NPY_NOTSWAPPED
    enum: NPY_WRITEABLE

    enum: NPY_CARRAY
    enum: NPY_CARRAY_RO
    enum: NPY_FARRAY
    enum: NPY_FARRAY_RO

    ndarray PyArray_FROM_O(object)
    ndarray PyArray_FROM_OT(object,int)
    ndarray PyArray_FROM_OTF(object,int,int)

    dtype   PyArray_DescrFromType(int)
    object  PyArray_TypeObjectFromType(int)

    ndarray PyArray_Copy(ndarray)
    ndarray PyArray_ArangeObj(object,object,object,dtype)
    ndarray PyArray_EMPTY(int,npy_intp[],int,int)
    ndarray PyArray_ZEROS(int,npy_intp[],int,int)

    bint PyArray_ISCONTIGUOUS(ndarray)
    bint PyArray_ISFORTRAN(ndarray)
    ctypedef enum NPY_ORDER:
        NPY_ANYORDER
        NPY_CORDER
        NPY_FORTRANORDER
    ndarray PyArray_NewCopy(ndarray,NPY_ORDER)


cdef extern from "arraynpy.h":

    enum: NPY_PETSC_INT
    enum: NPY_PETSC_REAL
    enum: NPY_PETSC_SCALAR
    enum: NPY_PETSC_COMPLEX


# --------------------------------------------------------------------

cdef inline ndarray asarray(object ob):
    return PyArray_FROM_O(ob)

cdef inline ndarray arange(start, stop, stride):
    cdef dtype descr = <dtype> PyArray_DescrFromType(NPY_PETSC_INT)
    return PyArray_ArangeObj(start, stop, stride, descr)

# --------------------------------------------------------------------

cdef inline ndarray empty_i(PetscInt size):
    cdef npy_intp s = <npy_intp> size
    return PyArray_EMPTY(1, &s, NPY_PETSC_INT, 0)

cdef inline ndarray empty_r(PetscInt size):
    cdef npy_intp s = <npy_intp> size
    return PyArray_EMPTY(1, &s, NPY_PETSC_REAL, 0)

cdef inline ndarray empty_s(PetscInt size):
    cdef npy_intp s = <npy_intp> size
    return PyArray_EMPTY(1, &s, NPY_PETSC_SCALAR, 0)

# --------------------------------------------------------------------

cdef inline ndarray array_i(PetscInt size, const_PetscInt* data):
    cdef npy_intp s = <npy_intp> size
    cdef ndarray ary = PyArray_EMPTY(1, &s, NPY_PETSC_INT, 0)
    if data != NULL:
        memcpy(PyArray_DATA(ary), data, size*sizeof(PetscInt))
    return ary

cdef inline ndarray array_r(PetscInt size, const_PetscReal* data):
    cdef npy_intp s = <npy_intp> size
    cdef ndarray ary = PyArray_EMPTY(1, &s, NPY_PETSC_REAL, 0)
    if data != NULL:
        memcpy(PyArray_DATA(ary), data, size*sizeof(PetscReal))
    return ary

cdef inline ndarray array_s(PetscInt size, const_PetscScalar* data):
    cdef npy_intp s = <npy_intp> size
    cdef ndarray ary = PyArray_EMPTY(1, &s, NPY_PETSC_SCALAR, 0)
    if data != NULL:
        memcpy(PyArray_DATA(ary), data, size*sizeof(PetscScalar))
    return ary

# --------------------------------------------------------------------

cdef inline ndarray iarray(object ob, int typenum):
    cdef ndarray ary = PyArray_FROM_OTF(ob, typenum, NPY_ALIGNED)
    if PyArray_ISCONTIGUOUS(ary): return ary
    if PyArray_ISFORTRAN(ary):    return ary
    return PyArray_Copy(ary)

cdef inline ndarray iarray_i(object ob, PetscInt* size, PetscInt** data):
    cdef ndarray ary = iarray(ob, NPY_PETSC_INT)
    if size != NULL: size[0] = <PetscInt>  PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscInt*> PyArray_DATA(ary)
    return ary

cdef inline ndarray iarray_r(object ob, PetscInt* size, PetscReal** data):
    cdef ndarray ary = iarray(ob, NPY_PETSC_REAL)
    if size != NULL: size[0] = <PetscInt>     PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscScalar*> PyArray_DATA(ary)
    return ary

cdef inline ndarray iarray_s(object ob, PetscInt* size, PetscScalar** data):
    cdef ndarray ary = iarray(ob, NPY_PETSC_SCALAR)
    if size != NULL: size[0] = <PetscInt>     PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscScalar*> PyArray_DATA(ary)
    return ary

# --------------------------------------------------------------------

cdef inline ndarray oarray(object ob, int typenum):
    cdef ndarray ary = PyArray_FROM_OTF(ob, typenum, NPY_ALIGNED|NPY_WRITEABLE)
    if PyArray_ISCONTIGUOUS(ary): return ary
    if PyArray_ISFORTRAN(ary):    return ary
    return PyArray_Copy(ary)

cdef inline ndarray oarray_i(object ob, PetscInt* size, PetscInt** data):
    cdef ndarray ary = oarray(ob, NPY_PETSC_INT)
    if size != NULL: size[0] = <PetscInt>  PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscInt*> PyArray_DATA(ary)
    return ary

cdef inline ndarray oarray_r(object ob, PetscInt* size, PetscReal** data):
    cdef ndarray ary = oarray(ob, NPY_PETSC_REAL)
    if size != NULL: size[0] = <PetscInt>   PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscReal*> PyArray_DATA(ary)
    return ary

cdef inline ndarray oarray_s(object ob, PetscInt* size, PetscScalar** data):
    cdef ndarray ary = oarray(ob, NPY_PETSC_SCALAR)
    if size != NULL: size[0] = <PetscInt>     PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscScalar*> PyArray_DATA(ary)
    return ary

# --------------------------------------------------------------------

cdef inline ndarray ocarray_s(object ob, PetscInt* size, PetscScalar** data):
    cdef ndarray ary = PyArray_FROM_OTF(ob, NPY_PETSC_SCALAR, NPY_CARRAY)
    if size != NULL: size[0] = <PetscInt>     PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscScalar*> PyArray_DATA(ary)
    return ary

cdef inline ndarray ofarray_s(object ob, PetscInt* size, PetscScalar** data):
    cdef ndarray ary = PyArray_FROM_OTF(ob, NPY_PETSC_SCALAR, NPY_FARRAY)
    if size != NULL: size[0] = <PetscInt>     PyArray_SIZE(ary)
    if data != NULL: data[0] = <PetscScalar*> PyArray_DATA(ary)
    return ary

# --------------------------------------------------------------------
