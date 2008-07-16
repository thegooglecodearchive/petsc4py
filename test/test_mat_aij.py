from petsc4py import PETSc
import unittest

import numpy as N

def mkgraph(comm, m, n):
    start = m*n * comm.rank
    end   = start + m*n
    idt = PETSc.IntType
    rows = []
    for I in xrange(start, end) :
        rows.append([])
        adj = rows[-1]
        i = I//n; j = I - i*n
        if i> 0  : J = I-n; adj.append(J)
        if j> 0  : J = I-1; adj.append(J)
        adj.append(I)
        if j< n-1: J = I+1; adj.append(J)
        if i< m-1: J = I+n; adj.append(J)
    nods = N.arange(start, end, dtype=idt)
    xadj = N.empty(len(rows)+1, dtype=idt)
    xadj[0] = 0
    xadj[1:] = N.cumsum([len(r) for r in rows], dtype=idt)
    if not rows: adjy = N.array([],dtype=idt)
    else:        adjy = N.concatenate(rows)
    return nods, xadj, adjy


class TestMatAnyAIJBase(object):

    COMM  = PETSc.COMM_NULL
    TYPE  = None
    GRID  = 0, 0
    BSIZE = None

    def setUp(self):
        COMM   = self.COMM
        GM, GN = self.GRID
        BS     = self.BSIZE or 1
        #
        sdt = dtype=PETSc.ScalarType
        self.rows, self.xadj, self.adjy = mkgraph(COMM, GM, GN)
        self.vals = N.arange(1, 1 + len(self.adjy)* BS**2)
        self.vals.shape = (-1, BS, BS)
        #
        self.A = A = PETSc.Mat().create(comm=COMM)
        bs = BS; m, n = GM, GN; cs = COMM.getSize()
        rowsz = colsz = (m*n*bs, None)
        A.setSizes([rowsz, colsz], bs)
        A.setType(self.TYPE)

    def tearDown(self):
        self.A.destroy()
        self.A = None

    def testSetPreallocNNZ(self):
        nnz = [5, 2]
        self.A.setPreallocationNNZ(nnz, self.BSIZE)
        self._chk_bs(self.A, self.BSIZE)
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def testSetPreallocNNZ_2(self):
        _, ai, _, _ =self._get_aijv()
        d_nnz = N.diff(ai)
        nnz = [d_nnz, 3]
        self.A.setPreallocationNNZ(nnz, self.BSIZE)
        self._chk_bs(self.A, self.BSIZE)
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av =self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def testSetPreallocCSR(self):
        _, ai, aj, _ =self._get_aijv()
        csr = [ai, aj]
        self.A.setPreallocationCSR(csr, self.BSIZE)
        self._chk_bs(self.A, self.BSIZE)
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def testSetPreallocCSR_2(self):
        _, ai, aj, av =self._get_aijv()
        csr = [ai, aj, av]
        self.A.setPreallocationCSR(csr, self.BSIZE)
        self._chk_bs(self.A, self.BSIZE)
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def testSetValues(self):
        self._preallocate()
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def testSetValuesCSR(self):
        self._preallocate()
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)

    def _get_aijv(self):
        return (self.rows, self.xadj, self.adjy, self.vals,)

    def _preallocate(self):
        self.A.setPreallocationNNZ([5, 2], self.BSIZE)

    def _set_values(self):
        row, ai, aj, av = self._get_aijv()
        if not self.BSIZE:
            setvalues = self.A.setValues
        else:
            setvalues = self.A.setValuesBlocked
        for i, r in enumerate(row):
            s, e = ai[i], ai[i+1]
            setvalues(r, aj[s:e], av[s:e])
        return ai, aj, av

    def _set_values_csr(self):
        row, ai, aj, av =self._get_aijv()
        if not self.BSIZE:
            setvalues = self.A.setValuesCSR
        else:
            setvalues = self.A.setValuesBlockedCSR
        setvalues(row, ai, aj, av)
        setvalues(None, ai, aj, av)
        return ai, aj, av

    def _chk_bs(self, A, bs):
        self.assertEqual(A.getBlockSize(), bs or 1)

    def _chk_aij(self, A, i, j):
        ai, aj = A.getRowIJ(compressed=bool(self.BSIZE))
        if None not in (ai, aj):
            self.assertTrue(N.all(i==ai))
            self.assertTrue(N.all(j==aj))
        ai, aj = A.getColumnIJ(compressed=bool(self.BSIZE))
        if None not in (ai, aj):
            self.assertTrue(N.all(i==ai))
            self.assertTrue(N.all(j==aj))
        return # XXX review
        version, patch = PETSc.Sys.getVersion(patch=True)
        #if version >= (2,3,3): #and patch >= 13:
        ai, aj = A.getRowIJ(compressed=False)
        print ai, aj


# -- AIJ ---------------------

class TestMatAIJBase(TestMatAnyAIJBase, unittest.TestCase):
    COMM  = PETSc.COMM_WORLD
    TYPE  = PETSc.Mat.Type.AIJ
    GRID  = 0, 0
    BSIZE = None

# -- Seq AIJ --

class TestMatSeqAIJ(TestMatAIJBase):
    COMM = PETSc.COMM_SELF
    TYPE = PETSc.Mat.Type.SEQAIJ
class TestMatSeqAIJ_G23(TestMatSeqAIJ):
    GRID  = 2, 3
class TestMatSeqAIJ_G45(TestMatSeqAIJ):
    GRID  = 4, 5
class TestMatSeqAIJ_G89(TestMatSeqAIJ):
    GRID  = 8, 9

# -- MPI AIJ --

class TestMatMPIAIJ(TestMatAIJBase):
    COMM = PETSc.COMM_WORLD
    TYPE = PETSc.Mat.Type.MPIAIJ
class TestMatMPIAIJ_G23(TestMatMPIAIJ):
    GRID  = 2, 3
class TestMatMPIAIJ_G45(TestMatMPIAIJ):
    GRID  = 4, 5
class TestMatMPIAIJ_G89(TestMatMPIAIJ):
    GRID  = 8, 9


# -- Block AIJ ---------------

class TestMatBAIJBase(TestMatAnyAIJBase, unittest.TestCase):
    COMM  = PETSc.COMM_WORLD
    TYPE  = PETSc.Mat.Type.BAIJ
    GRID  = 0, 0
    BSIZE = 1

# -- Seq Block AIJ --

class TestMatSeqBAIJ(TestMatBAIJBase):
    COMM = PETSc.COMM_SELF
    TYPE = PETSc.Mat.Type.SEQBAIJ
# bs = 1
class TestMatSeqBAIJ_G23(TestMatSeqBAIJ):
    GRID  = 2, 3
class TestMatSeqBAIJ_G45(TestMatSeqBAIJ):
    GRID  = 4, 5
class TestMatSeqBAIJ_G89(TestMatSeqBAIJ):
    GRID  = 8, 9
# bs = 2
class TestMatSeqBAIJ_G23_B2(TestMatSeqBAIJ_G23):
    BSIZE = 2
class TestMatSeqBAIJ_G45_B2(TestMatSeqBAIJ_G45):
    BSIZE = 2
class TestMatSeqBAIJ_G89_B2(TestMatSeqBAIJ_G89):
    BSIZE = 2
# bs = 3
class TestMatSeqBAIJ_G23_B3(TestMatSeqBAIJ_G23):
    BSIZE = 3
class TestMatSeqBAIJ_G45_B3(TestMatSeqBAIJ_G45):
    BSIZE = 3
class TestMatSeqBAIJ_G89_B3(TestMatSeqBAIJ_G89):
    BSIZE = 3
# bs = 4
class TestMatSeqBAIJ_G23_B4(TestMatSeqBAIJ_G23):
    BSIZE = 4
class TestMatSeqBAIJ_G45_B4(TestMatSeqBAIJ_G45):
    BSIZE = 4
class TestMatSeqBAIJ_G89_B4(TestMatSeqBAIJ_G89):
    BSIZE = 4
# bs = 5
class TestMatSeqBAIJ_G23_B5(TestMatSeqBAIJ_G23):
    BSIZE = 5
class TestMatSeqBAIJ_G45_B5(TestMatSeqBAIJ_G45):
    BSIZE = 5
class TestMatSeqBAIJ_G89_B5(TestMatSeqBAIJ_G89):
    BSIZE = 5


# -- MPI Block AIJ --

class TestMatMPIBAIJ(TestMatBAIJBase):
    COMM = PETSc.COMM_WORLD
    TYPE = PETSc.Mat.Type.MPIBAIJ
# bs = 1
class TestMatMPIBAIJ_G23(TestMatMPIBAIJ):
    GRID  = 2, 3
class TestMatMPIBAIJ_G45(TestMatMPIBAIJ):
    GRID  = 4, 5
class TestMatMPIBAIJ_G89(TestMatMPIBAIJ):
    GRID  = 8, 9
# bs = 2
class TestMatMPIBAIJ_G23_B2(TestMatMPIBAIJ_G23):
    BSIZE = 2
class TestMatMPIBAIJ_G45_B2(TestMatMPIBAIJ_G45):
    BSIZE = 2
class TestMatMPIBAIJ_G89_B2(TestMatMPIBAIJ_G89):
    BSIZE = 2
# bs = 3
class TestMatMPIBAIJ_G23_B3(TestMatMPIBAIJ_G23):
    BSIZE = 3
class TestMatMPIBAIJ_G45_B3(TestMatMPIBAIJ_G45):
    BSIZE = 3
class TestMatMPIBAIJ_G89_B3(TestMatMPIBAIJ_G89):
    BSIZE = 3
# bs = 4
class TestMatMPIBAIJ_G23_B4(TestMatMPIBAIJ_G23):
    BSIZE = 4
class TestMatMPIBAIJ_G45_B4(TestMatMPIBAIJ_G45):
    BSIZE = 4
class TestMatMPIBAIJ_G89_B4(TestMatMPIBAIJ_G89):
    BSIZE = 4
# bs = 5
class TestMatMPIBAIJ_G23_B5(TestMatMPIBAIJ_G23):
    BSIZE = 5
class TestMatMPIBAIJ_G45_B5(TestMatMPIBAIJ_G45):
    BSIZE = 5
class TestMatMPIBAIJ_G89_B5(TestMatMPIBAIJ_G89):
    BSIZE = 5


# -- AIJ + Block ---------------

class TestMatAIJ_B_Base(TestMatAnyAIJBase, unittest.TestCase):
    COMM  = PETSc.COMM_WORLD
    TYPE  = PETSc.Mat.Type.AIJ
    GRID  = 0, 0
    BSIZE = 1

    def testSetPreallocNNZ(self):pass
    def testSetPreallocNNZ_2(self):pass
    def testSetPreallocCSR(self):pass
    def testSetPreallocCSR_2(self):pass
    def testSetValues(self):
        self._preallocate()
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
    def testSetValuesCSR(self):
        self._preallocate()
        opt = PETSc.Mat.Option.NEW_NONZERO_ALLOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
        opt = PETSc.Mat.Option.NEW_NONZERO_LOCATION_ERR
        self.A.setOption(opt, True)
        ai, aj, av = self._set_values_csr()
        self.A.assemble()
        self._chk_aij(self.A, ai, aj)
    def _preallocate(self):
        self.A.setPreallocationNNZ([5*self.BSIZE, 3*self.BSIZE])
        self.A.setBlockSize(self.BSIZE)
        self._chk_bs(self.A, self.BSIZE)
    def _chk_aij(self, A, i, j):
        bs = self.BSIZE or 1
        ai, aj = A.getRowIJ()
        if None not in (ai, aj):  ## XXX map and check !!
            #self.assertTrue(N.all(i==ai))
            #self.assertTrue(N.all(j==aj))
            pass
        ai, aj = A.getColumnIJ(compressed=bool(self.BSIZE))
        if None not in (ai, aj): ## XXX map and check !!
            #self.assertTrue(N.all(i==ai))
            #self.assertTrue(N.all(j==aj))
            pass

# -- Seq AIJ + Block --

class TestMatSeqAIJ_B(TestMatAIJ_B_Base):
    COMM = PETSc.COMM_SELF
    TYPE = PETSc.Mat.Type.SEQAIJ
# bs = 1
class TestMatSeqAIJ_B_G23(TestMatSeqAIJ_B):
    GRID  = 2, 3
class TestMatSeqAIJ_B_G45(TestMatSeqAIJ_B):
    GRID  = 4, 5
class TestMatSeqAIJ_B_G89(TestMatSeqAIJ_B):
    GRID  = 8, 9
# bs = 2
class TestMatSeqAIJ_B_G23_B2(TestMatSeqAIJ_B_G23):
    BSIZE = 2
class TestMatSeqAIJ_B_G45_B2(TestMatSeqAIJ_B_G45):
    BSIZE = 2
class TestMatSeqAIJ_B_G89_B2(TestMatSeqAIJ_B_G89):
    BSIZE = 2
# bs = 3
class TestMatSeqAIJ_B_G23_B3(TestMatSeqAIJ_B_G23):
    BSIZE = 3
class TestMatSeqAIJ_B_G45_B3(TestMatSeqAIJ_B_G45):
    BSIZE = 3
class TestMatSeqAIJ_B_G89_B3(TestMatSeqAIJ_B_G89):
    BSIZE = 3
# bs = 4
class TestMatSeqAIJ_B_G23_B4(TestMatSeqAIJ_B_G23):
    BSIZE = 4
class TestMatSeqAIJ_B_G45_B4(TestMatSeqAIJ_B_G45):
    BSIZE = 4
class TestMatSeqAIJ_B_G89_B4(TestMatSeqAIJ_B_G89):
    BSIZE = 4
# bs = 5
class TestMatSeqAIJ_B_G23_B5(TestMatSeqAIJ_B_G23):
    BSIZE = 5
class TestMatSeqAIJ_B_G45_B5(TestMatSeqAIJ_B_G45):
    BSIZE = 5
class TestMatSeqAIJ_B_G89_B5(TestMatSeqAIJ_B_G89):
    BSIZE = 5


# -- MPI AIJ + Block --

class TestMatMPIAIJ_B(TestMatAIJ_B_Base):
    COMM = PETSc.COMM_WORLD
    TYPE = PETSc.Mat.Type.MPIAIJ
# bs = 1
class TestMatMPIAIJ_B_G23(TestMatMPIAIJ_B):
    GRID  = 2, 3
class TestMatMPIAIJ_B_G45(TestMatMPIAIJ_B):
    GRID  = 4, 5
class TestMatMPIAIJ_B_G89(TestMatMPIAIJ_B):
    GRID  = 8, 9
# bs = 2
class TestMatMPIAIJ_B_G23_B2(TestMatMPIAIJ_B_G23):
    BSIZE = 2
class TestMatMPIAIJ_B_G45_B2(TestMatMPIAIJ_B_G45):
    BSIZE = 2
class TestMatMPIAIJ_B_G89_B2(TestMatMPIAIJ_B_G89):
    BSIZE = 2
# bs = 3
class TestMatMPIAIJ_B_G23_B3(TestMatMPIAIJ_B_G23):
    BSIZE = 3
class TestMatMPIAIJ_B_G45_B3(TestMatMPIAIJ_B_G45):
    BSIZE = 3
class TestMatMPIAIJ_B_G89_B3(TestMatMPIAIJ_B_G89):
    BSIZE = 3
# bs = 4
class TestMatMPIAIJ_B_G23_B4(TestMatMPIAIJ_B_G23):
    BSIZE = 4
class TestMatMPIAIJ_B_G45_B4(TestMatMPIAIJ_B_G45):
    BSIZE = 4
class TestMatMPIAIJ_B_G89_B4(TestMatMPIAIJ_B_G89):
    BSIZE = 4
# bs = 5
class TestMatMPIAIJ_B_G23_B5(TestMatMPIAIJ_B_G23):
    BSIZE = 5
class TestMatMPIAIJ_B_G45_B5(TestMatMPIAIJ_B_G45):
    BSIZE = 5
class TestMatMPIAIJ_B_G89_B5(TestMatMPIAIJ_B_G89):
    BSIZE = 5

# -----




if __name__ == '__main__':
    unittest.main()