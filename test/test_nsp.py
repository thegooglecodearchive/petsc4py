import unittest
from petsc4py import PETSc
from sys import getrefcount

# --------------------------------------------------------------------

def allclose(seq1, seq2):
    for v1, v2 in zip(seq1, seq2):
        if abs(v1-v2) > 1e-7:
            return False
    return True
        

class TestNullSpace(unittest.TestCase):

    def setUp(self):
        u1 = PETSc.Vec().createSeq(3) 
        u2 = PETSc.Vec().createSeq(3)
        u1[0], u1[1], u1[2] = [1,  2, 0]; u1.normalize()
        u2[0], u2[1], u2[2] = [2, -1, 0]; u2.normalize()
        basis = [u1, u2]
        nullsp = PETSc.NullSpace().create(False, basis, comm=PETSc.COMM_SELF)
        self.basis = basis
        self.nullsp = nullsp
        
    def tearDown(self):
        self.basis = None
        self.nsp   = None

    def _remove(self):
        v = PETSc.Vec().createSeq(3);
        v[0], v[1], v[2] = [7,  8, 9]
        w = v.duplicate()
        self.nullsp.remove(v, w)
        return (v, w)
        
    def testRemove(self):
        v, w = self._remove()
        self.assertTrue(allclose(v.array, [7,  8, 9]))
        self.assertTrue(allclose(w.array, [0,  0, 9]))
        del v, w

    def testRemoveInplace(self):
        v, w = self._remove()
        self.nullsp.remove(v)
        self.assertTrue(v.equal(w))
        del v, w

    ## def testRemoveWithFunction(self):
    ##     rem = lambda vec: vec.setArray([1,2,3])
    ##     self.nullsp.setFunction(rem)
    ##     v, w = self._remove()
    ##     self.assertTrue(allclose(v, [7,  8, 9]))
    ##     self.assertTrue(allclose(w, [1,  2, 3]))
    ##     self.nullsp.remove(v)
    ##     self.assertTrue(allclose(v, [1,  2, 3]))
    ##     self.nullsp.setFunction(None)
    ##     self.testRemove()

    ## def testGetSetFunction(self):
    ##     dct = self.nullsp.getDict(create=False)
    ##     self.assertTrue(dct is None)
    ##     rem = lambda v: v.set(0)
    ##     self.nullsp.setFunction(rem)
    ##     self.assertEqual(getrefcount(rem)-1, 2)
    ##     dct = self.nullsp.getDict(create=False)
    ##     self.assertTrue(dct is not None)
    ##     self.assertEqual(getrefcount(dct)-1, 2)
    ##     fun = dct['__function__']
    ##     self.assertTrue(fun is rem)
    ##     self.nullsp.setFunction(None)
    ##     fun = dct.get('__function__')
    ##     self.assertEqual(getrefcount(rem)-1, 1)
    ##     self.assertTrue(fun is None)
        
# --------------------------------------------------------------------

if __name__ == '__main__':
    unittest.main()

# --------------------------------------------------------------------
